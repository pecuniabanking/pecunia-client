/**
 * Copyright (c) 2008, 2016, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "MessageLog.h"

#import "BankingController+Tabs.h" // Includes BankingController.h

#import "NewBankUserController.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "PreferenceController.h"
#import "LocalSettingsController.h"
#import "MOAssistant.h"

#import "ExportController.h"
#import "AccountDefController.h"
#import "TimeSliceManager.h"
#import "MCEMTreeController.h"
#import "WorkerThread.h"
#import "BSSelectWindowController.h"
#import "StatusBarController.h"
#import "DonationMessageController.h"
#import "CategoryView.h"
#import "StatCatAssignment.h"
#import "PecuniaError.h"
#import "ShortDate.h"

#import "StatSplitController.h"
#import "BankStatementController.h"
#import "AccountMaintenanceController.h"
#import "PurposeSplitController.h"

#import "HomeScreenController.h"
#import "StatementsOverviewController.h"
#import "CategoryAnalysisWindowController.h"
#import "CategoryRepWindowController.h"
#import "CategoryDefWindowController.h"
#import "CategoryPeriodsWindowController.h"
#import "CategoryMaintenanceController.h"
#import "CategoryHeatMapController.h"
#import "StandingOrderController.h"
#import "DebitsController.h"

#import "TransfersController.h"

#import "DockIconController.h"
#import "GenerateDataController.h"
#import "CreditCardSettlementController.h"

#import "ImportController.h"
#import "ImageAndTextCell.h"
#import "ColorPopup.h"
#import "PecuniaSplitView.h"
#import "SynchronousScrollView.h"
#import "ComTraceHelper.h"

#import "NSColor+PecuniaAdditions.h"
#import "NSDictionary+PecuniaAdditions.h"
#import "NSOutlineView+PecuniaAdditions.h"
#import "NSImage+PecuniaAdditions.h"

#import "BWGradientBox.h"
#import "EDSideBar.h"
#import "JMModalOverlay.h"
#import "WaitViewController.h"

#import "Tag.h"
#import "AssignmentController.h"
#import "AboutWindowController.h"
#import "AccountStatementsController.h"

// Pasteboard data types.
NSString *const BankStatementDataType = @"pecunia.BankStatementDataType";
NSString *const CategoryDataType = @"pecunia.CategoryDataType";

// Notification and dictionary key for category color change notifications.
extern NSString *const HomeScreenCardClickedNotification;

NSString *const CategoryColorNotification = @"CategoryColorNotification";
NSString *const CategoryKey = @"CategoryKey";

// KVO contexts.
void *UserDefaultsBindingContext = (void *)@"UserDefaultsContext";

static BankingController *bankinControllerInstance;

//----------------------------------------------------------------------------------------------------------------------

@interface BankingController () <EDSideBarDelegate>
{
    NSManagedObjectModel  *model;
    NewBankUserController *bankUserController;
    DockIconController    *dockIconController;

    BOOL restart;
    BOOL requestRunning;
    BOOL statementsBound;
    BOOL autoSyncRunning;
    BOOL autoCasingUpdateRunning;

    NSCursor *splitCursor;
    NSImage  *moneyImage;
    NSImage  *moneySyncImage;
    NSImage  *bankImage;

    NSMutableArray *bankAccountItemsExpandState;
    BankingCategory       *lastSelection;

    NSInteger currentPage; // Current main page.
    NSInteger currentSectionIndex; // Current page on the accounts main page.

    id<PecuniaSectionItem> currentSection;

    NSArray *defaultIcons; // Associations between categories and their default icons.
}

@end

@implementation BankingController

@synthesize dockIconController;
@synthesize shuttingDown;
@synthesize accountsView;

#pragma mark - Initialization

- (id)init {
    LogEnter; // Will implicitly set up the message log and the used loggers.

    self = [super init];
    if (self != nil) {
        bankinControllerInstance = self;
        restart = NO;
        requestRunning = NO;
        mainTabItems = [NSMutableDictionary dictionaryWithCapacity: 10];
        currentPage = -1;
        currentSectionIndex = -1;
    }

    LogLeave;

    return self;
}

- (void)dealloc {
    LogEnter;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"showHiddenCategories"];
    [userDefaults removeObserver: self forKeyPath: @"colors"];
    [userDefaults removeObserver: self forKeyPath: @"showPreliminaryStatements"];

    LogLeave;
}

- (void)setNumberFormatForCell: (NSCell *)cell positive: (NSDictionary *)positive
                      negative: (NSDictionary *)negative {
    LogEnter;
    if (cell == nil) {
        return;
    }

    NSNumberFormatter *formatter;
    if ([cell isKindOfClass: [ImageAndTextCell class]]) {
        formatter =  ((ImageAndTextCell *)cell).amountFormatter;
    } else {
        formatter =  [cell formatter];
    }

    if (formatter) {
        [formatter setTextAttributesForPositiveValues: positive];
        [formatter setTextAttributesForNegativeValues: negative];
    }

    LogLeave;
}

- (void)awakeFromNib {
    LogEnter;

    [mainWindow.contentView setHidden: YES]; // Show content not before anything is done (especially if data is encrypted).

    [MessageLog.log addObserver: self forKeyPath: @"isComTraceActive" options: 0 context: nil];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults addObserver: self forKeyPath: @"showHiddenCategories" options: 0 context: UserDefaultsBindingContext];
    [userDefaults addObserver: self forKeyPath: @"fontScale" options: 0 context: UserDefaultsBindingContext];
    [userDefaults addObserver: self forKeyPath: @"showPreliminaryStatements" options: 0 context: UserDefaultsBindingContext];
    [userDefaults addObserver: self forKeyPath: @"autoCasing" options: 0 context: UserDefaultsBindingContext];

    NSFont *font = [PreferenceController mainFontOfSize: 13 bold: NO];
    accountsView.rowHeight = floor(font.pointSize) + 7;

    [self setupSidebar];

    // Edit accounts/categories when double clicking on a node.
    [accountsView setDoubleAction: @selector(showProperties:)];
    [accountsView setTarget: self];

    NSTableColumn *tableColumn = [accountsView tableColumnWithIdentifier: @"name"];
    if (tableColumn) {
        ImageAndTextCell *cell = (ImageAndTextCell *)[tableColumn dataCell];
        if (cell) {
            NSFont *font = [PreferenceController mainFontOfSize: 13 bold: NO];
            [cell setFont: font];

            accountsView.rowHeight = floor(font.pointSize) + 8;
            [cell setMaxUnread: [BankAccount maxUnread]];
        }
    }

    // Status bar.
    [mainWindow setAutorecalculatesContentBorderThickness: NO forEdge: NSMinYEdge];
    [mainWindow setContentBorderThickness: 30.0f forEdge: NSMinYEdge];

    // Register drag'n drop types.
    [accountsView registerForDraggedTypes: @[BankStatementDataType, CategoryDataType]];

    lockImage.image = [NSImage imageNamed: @"icon72-1" fromCollection: 1];

    // Update encryption image.
    [self encryptionChanged];

    splitCursor = [[NSCursor alloc] initWithImage: [NSImage imageNamed: @"split-cursor"] hotSpot: NSMakePoint(0, 0)];
    [WorkerThread init];

    [categoryController addObserver: self forKeyPath: @"arrangedObjects.catSum" options: 0 context: nil];

    MOAssistant.sharedAssistant.mainWindow = mainWindow;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(contextChanged)
                                                 name: @"contextDataChanged"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(encryptionChanged)
                                                 name: @"dataFileEncryptionChanged"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(homeScreenCardClicked:)
                                                 name: HomeScreenCardClickedNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(resourceUpdated:)
                                                 name: RemoteResourceManager.pecuniaResourcesUpdatedNotification
                                               object: nil];

#ifdef DEBUG
    [developerMenu setHidden: NO];
#endif

    comTraceMenuItem.title = NSLocalizedString(@"AP222", nil);
    RemoteResourceManager *resourceManager = RemoteResourceManager.sharedManager; // Creates singleton.
    if ([userDefaults boolForKey: @"autoCasing"]) {
        [resourceManager addManagedFile: @"words.zip"];
    }

    [PluginRegistry startup];
    
    LogLeave;
}

/**
 * Sets a number of settings to useful defaults.
 */
- (void)setDefaultUserSettings {
    LogEnter;

    // Home screen settings.
    LocalSettingsController *settings = LocalSettingsController.sharedSettings;

    // We need an additional flag as the user can nullify each symbol and we would
    // re-add the default then.
    BOOL stocksDefaultsSet = [settings boolForKey: @"stocksDefaultsSet"];
    if (settings[@"stocksSymbol1"] == nil && !stocksDefaultsSet) {
        settings[@"stocksSymbol1"] = @"^GDAXI";
    }
    if (settings[@"stocksSymbolColor1"] == nil) {
        settings[@"stocksSymbolColor1"] = [NSColor nextDefaultStockGraphColor];
    }

    if (settings[@"stocksSymbol2"] == nil && !stocksDefaultsSet) {
        settings[@"stocksSymbol2"] = @"AAPL";
    }
    if (settings[@"stocksSymbolColor2"] == nil) {
        settings[@"stocksSymbolColor2"] = [NSColor nextDefaultStockGraphColor];
    }

    if (settings[@"stocksSymbol3"] == nil && !stocksDefaultsSet) {
        settings[@"stocksSymbol3"] = @"ORCL";
    }
    if (settings[@"stocksSymbolColor3"] == nil) {
        settings[@"stocksSymbolColor3"] = [NSColor nextDefaultStockGraphColor];
    }

    [settings setBool: YES forKey: @"stocksDefaultsSet"];

    if (settings[@"assetGraph1"] == nil || settings[@"assetGraph2"] == nil) {
        // Find the accounts with highest and lowest balance as default for the home screen asset graphs.
        BankingCategory *strongest;
        BankingCategory *weakest;
        for (BankingCategory *bank in BankingCategory.bankRoot.children) {
            for (BankingCategory *account in bank.allCategories) {
                if (strongest == nil) {
                    strongest = account;
                    weakest = account;
                    continue;
                }

                switch ([strongest.catSum compare: account.catSum]) {
                    case NSOrderedSame:
                        // Use the one with the most assignments, as that is probably more relevant.
                        if ([strongest assignmentCountRecursive: YES] < [account assignmentCountRecursive: YES]) {
                            strongest = account;
                        }
                        break;

                    case NSOrderedAscending:
                        strongest = account;
                        break;

                    case NSOrderedDescending:
                        break;
                }

                switch ([weakest.catSum compare: account.catSum]) {
                    case NSOrderedSame:
                        // Use the one with the most assignments, as that is probably more relevant.
                        if ([weakest assignmentCountRecursive: YES] < [account assignmentCountRecursive: YES]) {
                            weakest = account;
                        }
                        break;

                    case NSOrderedDescending:
                        weakest = account;
                        break;

                    case NSOrderedAscending:
                        break;
                }
            }
        }
        if (strongest != nil) {
            settings[@"assetGraph1"] = strongest.localName;
        }
        if (weakest != nil) {
            settings[@"assetGraph2"] = strongest.localName;
        }
    }
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults objectForKey: @"autoCasing"] == nil) {
        [defaults setBool: NO forKey: @"autoCasing"];
    }

    if ([defaults objectForKey: @"restoreActivePage"] == nil) {
        [defaults setBool: YES forKey: @"restoreActivePage"];
    }

    if ([defaults objectForKey: @"fontScale"] == nil) {
        [defaults setDouble: 1 forKey: @"fontScale"];
    }

    if ([defaults objectForKey: @"autoResetNew"] == nil) {
        [defaults setBool: YES forKey: @"autoResetNew"];
    }

    if ([defaults objectForKey: @"showBalances"] == nil) {
        [defaults setBool: YES forKey: @"showBalances"];
    }

    if ([defaults objectForKey: @"showHeadersInLists"] == nil) {
        [defaults setBool: YES forKey: @"showHeadersInLists"];
    }

    if ([defaults objectForKey: @"printUserInfo"] == nil) {
        [defaults setBool: YES forKey: @"printUserInfo"];
    }

    if ([defaults objectForKey: @"printCategories"] == nil) {
        [defaults setBool: YES forKey: @"printCategories"];
    }

    if ([defaults objectForKey: @"printTags"] == nil) {
        [defaults setBool: YES forKey: @"printTags"];
    }

    if ([defaults objectForKey: @"showPreliminaryStatements"] == nil) {
        [defaults setBool: YES forKey: @"showPreliminaryStatements"];
    }

    if ([defaults objectForKey: @"logLevel"] == nil) {
        [defaults setInteger: 2 forKey: @"logLevel"]; // 0 - errors, 1 - warnings, 2 - info, 3 - debug, 4 - verbose
    }

    // Migrate the migration flags to the local settings if a migration was done.
    // This must be a per-datafile setting, not a default setting.
    if (settings[@"Migrated10"] == nil) {
        BOOL migrated10 = [defaults boolForKey: @"Migrated10"];
        if (migrated10) {
            settings[@"Migrated10"] = @YES;
            [defaults removeObjectForKey: @"Migrated10"];
        }
    }
    if (settings[@"Migrated109"] == nil) {
        BOOL migrated109 = [defaults boolForKey: @"Migrated109"];
        if (migrated109) {
            settings[@"Migrated109"] = @YES;
            [defaults removeObjectForKey: @"Migrated109"];
        }
    }

    LogLeave;
}

- (void)logSummary: (NSString *)entity withMessage: (NSString *)message {
    NSError *error = nil;

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName: entity inManagedObjectContext: managedObjectContext];
    NSUInteger count = [managedObjectContext countForFetchRequest: request error: &error];
    if (error == nil) {
        LogInfo(@"    %i %@", count, message);
    } else {
        LogError(@"Couldn't determine summary for %@. Got error: %@", message, error.localizedDescription);
    }
}

- (void)logDatabaseInfo {
    // Log a few important data details.
    LogInfo(@"Database summary:");

    [self logSummary: @"BankAccount" withMessage: @"bank accounts"];
    [self logSummary: @"BankMessage" withMessage: @"bank messages"];
    [self logSummary: @"BankStatement" withMessage: @"bank statements"];
    [self logSummary: @"BankUser" withMessage: @"bank users"];
    [self logSummary: @"Category" withMessage: @"categories"];
    [self logSummary: @"CreditCardSettlement" withMessage: @"credit card settlements"];
    [self logSummary: @"CustomerMessage" withMessage: @"customer messages"];
    [self logSummary: @"StandingOrder" withMessage: @"standing orders"];
    [self logSummary: @"StatCatAssignment" withMessage: @"category assignments"];
    [self logSummary: @"SupportedTransactionInfo" withMessage: @"transaction infos"];
    [self logSummary: @"Tag" withMessage: @"tags"];
    [self logSummary: @"TanMedium" withMessage: @"signing media"];
    [self logSummary: @"TanMethod" withMessage: @"signing methods"];
    [self logSummary: @"TransactionLimits" withMessage: @"transaction limits"];
    [self logSummary: @"Transfer" withMessage: @"transfers"];
    [self logSummary: @"TransferTemplate" withMessage: @"transfer templates"];

}

- (void)publishContext {
    LogEnter;

    NSError *error = nil;

    categoryController.managedObjectContext = managedObjectContext;
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES];
    [categoryController setSortDescriptors: @[sd]];

    // repair Category Root
    [self repairCategories];

    [self updateBalances];

    // update unread information
    [self updateUnread];

    [timeSlicer updateDelegate];
    [categoryController fetchWithRequest: nil merge: NO error: &error];
    [accountsView restoreState];
    dockIconController = [[DockIconController alloc] initWithManagedObjectContext: managedObjectContext];

    [self logDatabaseInfo];
    
    RemoteResourceManager *resourceManager = RemoteResourceManager.sharedManager; // Creates singleton.
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"autoCasing"]) {
        [resourceManager addManagedFile: @"words.zip"];
    }

    LogLeave;
}

- (void)contextChanged {
    LogEnter;

    managedObjectContext = MOAssistant.sharedAssistant.context;
    [self publishContext];

    LogLeave;
}

- (void)encryptionChanged {
    LogEnter;

    [lockImage setHidden: !MOAssistant.sharedAssistant.isEncrypted];

    LogLeave;
}

- (void)resourceUpdated: (NSNotification *)notification {
    NSArray *files = notification.object;
    if ([files containsObject: @"words.zip"]) {
        self.updatingWordList = YES;
        [WordMapping updateWordMappings];
        self.updatingWordList = NO;
    }
}

#pragma mark - User actions

- (void)homeScreenCardClicked: (NSNotification *)notification {
    LogEnter;

    id object = notification.object;
    if ([object isKindOfClass: BankingCategory.class]) {
        [categoryController setSelectedObject: object];
        sidebar.selectedIndex = 2;
    }

    LogLeave;
}

- (NSIndexPath *)indexPathForCategory: (BankingCategory *)cat inArray: (NSArray *)nodes {
    LogEnter;

    NSUInteger idx = 0;
    for (NSTreeNode *node in nodes) {
        BankingCategory *obj = [node representedObject];
        if (obj == cat) {
            return [NSIndexPath indexPathWithIndex: idx];
        } else {
            NSArray *children = [node childNodes];
            if (children == nil) {
                continue;
            }
            NSIndexPath *p = [self indexPathForCategory: cat inArray: children];
            if (p) {
                return [p indexPathByAddingIndex: idx];
            }
        }
        idx++;
    }
    LogLeave;

    return nil;
}

- (void)removeBankAccount: (BankAccount *)bankAccount keepAssignedStatements: (BOOL)keepAssignedStats {
    LogEnter;

    BOOL removeParent = NO;

    [bankAccount invalidateCacheIncludeParents: YES recursive: YES];

    //  Delete bank statements which are not assigned first
    NSSet *statements = [[bankAccount valueForKey: @"statements"] copy];
    if (!keepAssignedStats) {
        for (BankStatement *statement in statements) {
            [managedObjectContext deleteObject: statement];
        }
    } else {
        for (BankStatement *statement in statements) {
            NSSet *assignments = [[statement mutableSetValueForKey: @"assignments"] copy];
            if ([assignments count] < 2) {
                [managedObjectContext deleteObject: statement];
            } else if ([assignments count] == 2) {
                // delete statement if not assigned yet
                if ([statement hasAssignment] == NO) {
                    [managedObjectContext deleteObject: statement];
                }
            } else {
                statement.account = nil;
            }
        }
    }

    [managedObjectContext processPendingChanges];
    [[BankingCategory nassRoot] invalidateBalance];
    [BankingCategory updateBalancesAndSums];

    // remove parent?
    BankAccount *parent = [bankAccount valueForKey: @"parent"];
    if (parent != nil) {
        NSSet *childs = [parent mutableSetValueForKey: @"children"];
        if ([childs count] == 1) {
            removeParent = YES;
        }
    }

    // calculate index path of current object
    NSArray     *nodes = [[categoryController arrangedObjects] childNodes];
    NSIndexPath *path = [self indexPathForCategory: bankAccount inArray: nodes];
    // IndexPath umdrehen
    NSIndexPath *newPath = [[NSIndexPath alloc] init];
    for (NSInteger i = path.length - 1; i >= 0; i--) {
        newPath = [newPath indexPathByAddingIndex: [path indexAtPosition: i]];
    }
    [categoryController removeObjectAtArrangedObjectIndexPath: newPath];
    if (removeParent) {
        newPath = [newPath indexPathByRemovingLastIndex];
        [categoryController removeObjectAtArrangedObjectIndexPath: newPath];
    }
    [[BankingCategory bankRoot] updateCategorySums];

    LogLeave;
}

- (BOOL)cleanupBankNodes {
    LogEnter;

    BOOL flg_changed = NO;
    // remove empty bank nodes
    BankingCategory *root = [BankingCategory bankRoot];
    if (root != nil) {
        NSArray *bankNodes = [[root mutableSetValueForKey: @"children"] allObjects];
        for (BankAccount *node in bankNodes) {
            NSMutableSet *childs = [node mutableSetValueForKey: @"children"];
            if (childs == nil || [childs count] == 0) {
                [managedObjectContext deleteObject: node];
                flg_changed = YES;
            }
        }
    }

    LogLeave;

    return flg_changed;
}

- (BankingCategory *)getBankingRoot {
    LogEnter;

    NSError        *error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getBankingRoot"];
    NSArray        *cats = [managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }
    if ([cats count] > 0) {
        return cats[0];
    }

    // create Root object
    BankingCategory *obj = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                  inManagedObjectContext: managedObjectContext];
    [obj setValue: @"++bankroot" forKey: @"name"];
    [obj setValue: @YES forKey: @"isBankAcc"];

    LogLeave;

    return obj;
}

// XXX: is this still required? Looks like a fix for a previous bug.
- (void)repairCategories {
    LogEnter;

    NSError  *error = nil;
    BankingCategory *catRoot;
    BOOL     found = NO;

    // repair bank root
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getBankingRoot"];
    NSArray        *cats = [managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    for (BankingCategory *cat in cats) {
        NSString *n = [cat primitiveValueForKey: @"name"];
        if (![n isEqualToString: @"++bankroot"]) {
            [cat setValue: @"++bankroot" forKey: @"name"];
            break;
        }
    }
    // repair categories
    request = [model fetchRequestTemplateForName: @"getCategoryRoot"];
    cats = [managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    for (BankingCategory *cat in cats) {
        NSString *n = [cat primitiveValueForKey: @"name"];
        if ([n isEqualToString: @"++catroot"] ||
            [n isEqualToString: @"Umsatzkategorien"] ||
            [n isEqualToString: @"Transaction categories"]) {
            [cat setValue: @"++catroot" forKey: @"name"];
            catRoot = cat;
            found = YES;
            break;
        }
    }
    if (found == NO) {
        // create Category Root object
        BankingCategory *obj = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                      inManagedObjectContext: managedObjectContext];
        [obj setValue: @"++catroot" forKey: @"name"];
        [obj setValue: @NO forKey: @"isBankAcc"];
        catRoot = obj;
    }

    // reassign categories
    for (BankingCategory *cat in cats) {
        if (cat == catRoot) {
            continue;
        }
        if ([cat valueForKey: @"parent"] == nil) {
            [cat setValue: catRoot forKey: @"parent"];
        }
    }
    // insert not assigned node
    request = [model fetchRequestTemplateForName: @"getNassRoot"];
    cats = [managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    if ([cats count] == 0) {
        BankingCategory *obj = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                      inManagedObjectContext: managedObjectContext];
        [obj setPrimitiveValue: @"++nassroot" forKey: @"name"];
        [obj setValue: @NO forKey: @"isBankAcc"];
        [obj setValue: catRoot forKey: @"parent"];

        [self updateNotAssignedCategory];
    }

    [self save];

    LogLeave;
}

- (void)updateBalances {
    LogEnter;

    NSError *error = nil;

    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getRootNodes"];
    NSArray        *cats = [managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    for (BankingCategory *cat in cats) {
        if (!cat.isBankingRoot) {
            [cat recomputeInvalidBalances];
        }
        [cat updateCategorySums];
    }
    [self save];

    LogLeave;
}

- (IBAction)enqueueRequest: (id)sender {
    if ((NSEvent.modifierFlags & NSAlternateKeyMask) != 0) {
        if ([self.currentSelection isBankAccount]) {
            [self synchronizeAccount: self.currentSelection];
        }
    } else {
        [self synchronizeAccount: BankingCategory.bankRoot];
    }
}

- (void)synchronizeAccount: (BankingCategory *)category {
    LogEnter;

    NSMutableArray *selectedAccounts = [NSMutableArray arrayWithCapacity: 10];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray        *selectedNodes = nil;
    NSError        *error = nil;

    if (category == nil) {
        return;
    }

    [self startRefreshAnimation];

    selectWindowController = nil;

    if (category.accountNumber != nil) {
        // A bank account.
        [selectedAccounts addObject: category];
    } else {
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: managedObjectContext];
        NSFetchRequest      *request = [[NSFetchRequest alloc] init];
        [request setEntity: entityDescription];
        if (category.parent == nil) {
            // Bank root. Retrieve all bank accounts under it.
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@", category];
            [request setPredicate: predicate];
            selectedNodes = [managedObjectContext executeFetchRequest: request error: &error];
            if (error) {
                [self stopRefreshAnimation];
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }
        } else {
            // One of the bank nodes.
            selectedNodes = @[category];
        }

        // Get the accounts from each node.
        for (BankAccount *account in selectedNodes) {
            NSArray     *result;
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@ AND noAutomaticQuery == 0", account];
            [request setPredicate: predicate];
            result = [managedObjectContext executeFetchRequest: request error: &error];
            if (error) {
                [self stopRefreshAnimation];
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }
            [selectedAccounts addObjectsFromArray: result];
        }
    }

    if ([selectedAccounts count] == 0) {
        LogWarning(@"No accounts selected, or all selected accounts have noAutomaticQuery == true");
        [self stopRefreshAnimation];
        return;
    }

    // Check that at least one account is assigned to a user.
    NSUInteger nInactive = 0;
    for (BankAccount *account in selectedAccounts) {
        if (account.userId == nil && (!account.isManual.boolValue)) {
            nInactive++;
        }
    }
    if (nInactive == selectedAccounts.count) {
        [self stopRefreshAnimation];
        NSRunAlertPanel(NSLocalizedString(@"AP220", nil),
                        NSLocalizedString(@"AP215", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil, nil
                        );
        return;
    }

    if (nInactive > 0) {
        NSRunAlertPanel(NSLocalizedString(@"AP216", nil),
                        NSLocalizedString(@"AP217", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil, nil,
                        nInactive,
                        [selectedAccounts count]
                        );
    }
    
    // We need to filter userId == nil accounts out (the manual ones)
    NSMutableArray *accountsToKeep = [NSMutableArray arrayWithCapacity:[selectedAccounts count]];
    for (BankAccount *account in selectedAccounts) {
        if (account.userId != nil) {
            [accountsToKeep addObject:account];
        }
    }
    [selectedAccounts setArray:accountsToKeep];


    // Prepare UI.
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: NO];
    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP219", nil) removeAfter: 0];
    newStatementsCount = 0;

    if ([defaults boolForKey: @"manualTransactionCheck"] && selectWindowController == nil) {
        selectWindowController = [[BSSelectWindowController alloc] init];
    }

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(statementsNotification:)
                                                 name: PecuniaStatementsNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(statementsFinalizeNotification:)
                                                 name: PecuniaStatementsFinalizeNotification
                                               object: nil];
    [[HBCIBackend backend] getStatements: selectedAccounts];

    LogLeave;
}

- (void)statementsNotification: (NSNotification *)notification {
    LogEnter;

    BankQueryResult *result;
    NSUserDefaults  *defaults = [NSUserDefaults standardUserDefaults];
    BOOL            noStatements = YES;
    BOOL            isImport = NO;

    NSArray *resultList = [notification object];
    if (resultList == nil) {
        return;
    }

    // get Proposals
    for (result in resultList) {
        if (result.isImport) {
            NSArray *stats = result.statements;
            if ([stats count] > 0) {
                noStatements = NO;
                [result.account evaluateQueryResult: result];
            }
            isImport = YES;
        }
        [result.account updateStandingOrders: result.standingOrders];
    }
    if ([defaults boolForKey: @"manualTransactionCheck"] && !noStatements && resultList.count > 0) {
        [selectWindowController addResults: resultList];
    } else {
        @try {
            for (result in resultList) {
                newStatementsCount += [result.account updateFromQueryResult: result];
            }
        }
        @catch (NSException *error) {
            LogError(@"%@", error.debugDescription);
        }
        if (autoSyncRunning) {
            [self checkBalances: resultList];
        }
        [self requestFinished: resultList];
    }

    // check for updated login data
    for (result in resultList) {
        BankUser *user = [BankUser findUserWithId: result.account.userId bankCode: result.account.bankCode];
        if (user != nil) {
            [user checkForUpdatedLoginData];
        }
    }
    [self save];

    LogLeave;
}

- (void)statementsFinalizeNotification: (NSNotification *)notification {
    StatusBarController *sc = [StatusBarController controller];
    NSUserDefaults      *defaults = [NSUserDefaults standardUserDefaults];

    [sc stopSpinning];
    [sc clearMessage];
    requestRunning = NO;

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: PecuniaStatementsNotification
                                                  object: nil];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: PecuniaStatementsFinalizeNotification
                                                  object: nil];

    if ([defaults boolForKey: @"manualTransactionCheck"]) {
        // todo: don't show window if there are no statements
        [NSApp runModalForWindow: [selectWindowController window]];
    } else {
        [sc setMessage: [NSString stringWithFormat: NSLocalizedString(@"AP218", nil), newStatementsCount] removeAfter: 120];
    }

    autoSyncRunning = NO;
    [self.currentSelection updateAssignmentsForReportRange];

    [self stopRefreshAnimation];
    [self updateUnread];

    BOOL suppressSound = [NSUserDefaults.standardUserDefaults boolForKey: @"noSoundAfterSync"];
    if (!suppressSound) {
        NSSound *doneSound = [NSSound soundNamed: @"done.mp3"];
        if (doneSound != nil) {
            [doneSound play];
        }
    }
}

- (void)requestFinished: (NSArray *)resultList {
    LogEnter;

    [managedObjectContext processPendingChanges];
    [self updateBalances];
    requestRunning = NO;
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: YES];

    if (resultList != nil) {
        BankQueryResult *result;
        NSDate          *maxDate = nil;
        for (result in resultList) {
            NSDate *lDate = result.account.latestTransferDate;
            if (((maxDate != nil) && ([maxDate compare: lDate] == NSOrderedAscending)) || (maxDate == nil)) {
                maxDate = lDate;
            }
        }
        if (maxDate) {
            [timeSlicer stepIn: [ShortDate dateWithDate: maxDate]];
        }

        // update unread information
        NSInteger maxUnread = [BankAccount maxUnread];

        // update data cell
        NSTableColumn *tc = [accountsView tableColumnWithIdentifier: @"name"];
        if (tc) {
            ImageAndTextCell *cell = (ImageAndTextCell *)[tc dataCell];
            [cell setMaxUnread: maxUnread];
        }

        // redraw accounts view
        [accountsView setNeedsDisplay: YES];
        [rightPane setNeedsDisplay: YES];
    }

    LogLeave;
}

- (void)checkBalances: (NSArray *)resultList {
    LogEnter;

    NSNumber *threshold;
    BOOL     alert = NO;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           accWarning = [defaults boolForKey: @"accWarning"];
    if (accWarning == NO) {
        return;
    }

    threshold = [defaults objectForKey: @"accWarningThreshold"];
    if (threshold == nil) {
        threshold = [NSDecimalNumber zero];
    }

    // check if account balances change below threshold
    for (BankQueryResult *result in resultList) {
        if ([result.oldBalance compare: threshold] == NSOrderedDescending && [result.balance compare: threshold] == NSOrderedAscending) {
            alert = YES;
        }
    }
    if (alert == YES) {
        NSRunAlertPanel(NSLocalizedString(@"AP814", nil),
                        NSLocalizedString(@"AP815", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil, nil
                        );
    }

    LogLeave;
}

- (BOOL)requestRunning {
    return requestRunning;
}

- (IBAction)editBankUsers: (id)sender {
    LogEnter;

    NewBankUserController * controller = [[NewBankUserController alloc] initForController: self];
    [NSApp runModalForWindow: controller.window];

    LogLeave;
}

- (IBAction)editPreferences: (id)sender {
    [PreferenceController showPreferencesWithOwner: self section: nil];
}

- (IBAction)showLicense: (id)sender {
    LogEnter;

    NSURL *url = [NSURL URLWithString: @"http://opensource.org/licenses/GPL-2.0"];
    [[NSWorkspace sharedWorkspace] openURL: url];

    LogLeave;
}

- (IBAction)showConsole: (id)sender {
    LogEnter;

    [[NSWorkspace sharedWorkspace] launchApplication: @"Console"];

    LogLeave;
}

- (IBAction)printDocument: (id)sender // Bound via first responder to print menu item.
{
    LogEnter;

    switch ([mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]]) {
        case 0:
            [currentSection print];
            break;

        case 1: {
            [transfersController print];
            break;
        }

        default: {
            id <PecuniaSectionItem> item = mainTabItems[[[mainTabView selectedTabViewItem] identifier]];
            [item print];
        }
    }

    LogLeave;
}

- (IBAction)accountMaintenance: (id)sender {
    LogEnter;

    BankingCategory *category = self.currentSelection;
    if (category == nil || category.accountNumber == nil) {
        return;
    }
    BankAccount  *account = (BankAccount *)category;
    NSDictionary *details = @{
        @"title": account.name,
        @"message": NSLocalizedString(@"AP818", nil),
        @"details": NSLocalizedString(@"AP819", nil)
    };
    [waitViewController startWaiting: details];

    // Run maintenance in a background block.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *details = [NSMutableDictionary new];
        details[@"title"] = account.name;
        details[@"message"] = NSLocalizedString(@"AP816", nil);
        @try {
            [account doMaintenance];
            details[@"details"] = NSLocalizedString(@"AP817", nil);
        }
        @catch (NSException *exception) {
            LogError(@"Error while doing account maintenance:\n%@", exception.debugDescription);

            details[@"details"] = NSLocalizedString(@"AP824", nil);
            details[@"failed"] = @YES;
        }
        @finally {
            // Run clean up on main thread.
            [self performSelectorOnMainThread: @selector(cleanupAfterMaintenance:) withObject: details waitUntilDone: NO modes: @[NSModalPanelRunLoopMode]];
        }


    });

    waitOverlay.animationDirection = JMModalOverlayDirectionBottom;
    [waitOverlay showInWindow: mainWindow];

    LogLeave;
}

- (IBAction)updateStatementBalances: (id)sender {
    LogEnter;

    BankingCategory *category = self.currentSelection;
    if (category == nil || category.accountNumber == nil) {
        return;
    }
    BankAccount *account = (BankAccount *)category;

    NSDictionary *details = @{
        @"title": account.name,
        @"message": NSLocalizedString(@"AP818", nil),
        @"details": NSLocalizedString(@"AP821", nil)
    };
    [waitViewController startWaiting: details];

    // Run maintenance in a background block.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *details = [NSMutableDictionary new];
        details[@"title"] = account.name;
        details[@"message"] = NSLocalizedString(@"AP822", nil);
        @try {
            [account updateStatementBalances];
            details[@"details"] = NSLocalizedString(@"AP817", nil);
        }
        @catch (NSException *exception) {
            LogError(@"Error while updating statement balances:\n%@", exception.debugDescription);

            details[@"details"] = NSLocalizedString(@"AP824", nil);
            details[@"failed"] = @YES;
        }
        @finally {
            // Run clean up on main thread.
            [self performSelectorOnMainThread: @selector(cleanupAfterMaintenance:) withObject: details waitUntilDone: NO modes: @[NSModalPanelRunLoopMode]];
        }
    });

    waitOverlay.animationDirection = JMModalOverlayDirectionBottom;
    [waitOverlay showInWindow: mainWindow];

    LogLeave;
}

- (void)cleanupAfterMaintenance: (NSDictionary *)details {
    [self save];
    [overviewController reload];
    [waitViewController markDone: details];
    [waitOverlay performSelector: @selector(performClose:) withObject: nil afterDelay: 5 inModes: @[NSModalPanelRunLoopMode]];
}


- (IBAction)getAccountBalance: (id)sender {
    LogEnter;

    BankAccount  *account = nil;
    BankingCategory     *cat = [self currentSelection];
    if (cat == nil || cat.accountNumber == nil) {
        return;
    }
    account = (BankAccount *)cat;

    NSError *error = [[HBCIBackend backend] getBalanceForAccount: account];
    if (error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }

    [self save];

    LogLeave;
}

- (IBAction)resetIsNewStatements: (id)sender {
    LogEnter;

    NSError             *error = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement"
                                                         inManagedObjectContext: managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isNew = 1"];
    [request setPredicate: predicate];
    NSArray *statements = [managedObjectContext executeFetchRequest: request error: &error];
    for (BankStatement *stat in statements) {
        stat.isNew = @NO;
    }
    [self save];

    [self updateUnread];
    [rightPane setNeedsDisplay: YES];

    LogLeave;
}

- (IBAction)markSelectedUnread: (id)sender {
    [overviewController markSelectedStatementsUnread];
}

- (IBAction)showAboutPanel: (id)sender {
    LogEnter;

    [AboutWindowController showAboutBox];

    LogLeave;
}

- (void)reapplyDefaultIconsForCategory: (BankingCategory *)category {
    LogEnter;

    for (BankingCategory *child in category.children) {
        if ([child.name hasPrefix: @"++"]) {
            continue;
        }
        [self determineDefaultIconForCategory: child];
        [self reapplyDefaultIconsForCategory: child];
    }
    LogLeave;
}

- (IBAction)resetCategoryIcons: (id)sender {
    LogEnter;

    int res = NSRunAlertPanel(NSLocalizedString(@"AP301", nil),
                              NSLocalizedString(@"AP302", nil),
                              NSLocalizedString(@"AP4", nil),
                              NSLocalizedString(@"AP3", nil),
                              nil
                              );
    if (res != NSAlertAlternateReturn) {
        return;
    }
    [self reapplyDefaultIconsForCategory: BankingCategory.catRoot];
    [accountsView setNeedsDisplay: YES];

    LogLeave;
}

- (IBAction)openHomepage: (id)sender {
    [NSWorkspace.sharedWorkspace openURL: [NSURL URLWithString: @"http://www.pecuniabanking.de"]];
}

- (IBAction)openForum: (id)sender {
    [NSWorkspace.sharedWorkspace openURL: [NSURL URLWithString: @"http://www.onlinebanking-forum.de/phpBB2/viewforum.php?f=56"]];
}

- (IBAction)sendErrorReport: (id)sender {
    NSMutableString *text = [NSMutableString string];

    for (BankUser *user in [BankUser allUsers]) {
        [text appendFormat: @"%@\n", [user descriptionWithIndent: @"    "]];
    }
    LogInfo(@"Bank users: {\n%@}", text);

    [MessageLog.log sendLog];
}

- (IBAction)openLogFolder: (id)sender {
    [MessageLog.log openLogFolder];
}

- (IBAction)showLog: (id)sender {
    [MessageLog.log showLog];
}

- (IBAction)comTraceToggle: (id)sender {
    [comTracePanel toggleComTrace: sender];
}

- (IBAction)openBugTracker: (id)sender {
	[NSWorkspace.sharedWorkspace openURL: [NSURL URLWithString: @"https://github.com/pecuniabanking/pecunia-client/issues"]];
}

- (IBAction)changeFontSize: (id)sender {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    double         scale = [defaults doubleForKey: @"fontScale"];
    if (sender == decreaseFontButton) {
        scale = ((int)(scale * 10) - 1) / 10.0;
    } else {
        scale = ((int)(scale * 10) + 1) / 10.0;
    }
    if (scale < 0.75) {
        scale = 0.75;
    }
    if (scale > 1.5) {
        scale = 1.5;
    }
    [defaults setDouble: scale forKey: @"fontScale"];
}

#pragma mark - Account management

- (IBAction)addAccount: (id)sender {
    LogEnter;

    NSString *bankCode = nil;
    BankingCategory *cat = [self currentSelection];
    if (cat != nil) {
        if ([cat isBankAccount] && ![cat isRoot]) {
            bankCode = [cat valueForKey: @"bankCode"];
        }
    }

    AccountDefController *defController = [[AccountDefController alloc] init];
    if (bankCode) {
        [defController setBankCode: bankCode name: [cat valueForKey: @"bankName"]];
    }

    int res = [NSApp runModalForWindow: [defController window]];
    if (res) {
        // account was created
        [self save];

        [categoryController rearrangeObjects];
        [BankingCategory.bankRoot updateCategorySums];
    }

    LogLeave;
}

- (IBAction)showProperties: (id)sender {
    // In order to let KVO selection changes work properly when double clicking a node other than
    // the current one we have to run the modal dialogs after the runloop has finished its round.
    [self performSelector: @selector(doShowProperties) withObject: nil afterDelay: 0];
}

- (void)doShowProperties {
    LogEnter;

    BankingCategory *cat = [self currentSelection];
    if (cat == nil) {
        return;
    }

    if (!cat.isBankAccount && cat != BankingCategory.nassRoot && cat != BankingCategory.catRoot) {
        CategoryMaintenanceController *changeController = [[CategoryMaintenanceController alloc] initWithCategory: cat];
        [NSApp runModalForWindow: [changeController window]];
        [categoryController prepareContent]; // Visibility of a category could have changed.
        [BankingCategory.catRoot updateCategorySums]; // Category could have switched its noCatRep property.
        return;
    }

    if (cat.accountNumber != nil) {
        AccountMaintenanceController *changeController = [[AccountMaintenanceController alloc] initWithAccount: (BankAccount *)cat];
        [NSApp runModalForWindow: [changeController window]];
        [categoryController prepareContent];
        [BankingCategory.bankRoot updateCategorySums];
    } else {
        [self editBankUsers: nil];
    }
    // Changes are stored in the controllers.

    LogLeave;
}

- (IBAction)deleteAccount: (id)sender {
    LogEnter;

    BankingCategory *cat = [self currentSelection];
    if (cat == nil) {
        return;
    }
    if ([cat isBankAccount] == NO) {
        return;
    }
    if ([cat accountNumber] == nil) {
        return;
    }

    BankAccount *account = (BankAccount *)cat;

    // issue a confirmation
    int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP802", nil),
                                      NSLocalizedString(@"AP812", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      nil,
                                      account.accountNumber
                                      );
    if (res != NSAlertDefaultReturn) {
        return;
    }

    // check for transactions
    BOOL         keepAssignedStatements = NO;
    NSMutableSet *stats = [cat mutableSetValueForKey: @"statements"];
    if (stats && [stats count] > 0) {
        BOOL hasAssignment = NO;

        // check if transactions are assigned
        for (BankStatement *stat in stats) {
            if ([stat hasAssignment]) {
                hasAssignment = YES;
                break;
            }
        }
        if (hasAssignment) {
            int alertResult = NSRunCriticalAlertPanel(NSLocalizedString(@"AP802", nil),
                                                      NSLocalizedString(@"AP801", nil),
                                                      NSLocalizedString(@"AP3", nil),
                                                      NSLocalizedString(@"AP4", nil),
                                                      NSLocalizedString(@"AP2", nil),
                                                      account.accountNumber
                                                      );
            if (alertResult == NSAlertDefaultReturn) {
                keepAssignedStatements = YES;
            } else {
                if (alertResult == NSAlertOtherReturn) {
                    return;
                } else {
                    keepAssignedStatements = NO;
                }
            }
        }
    }
    // delete account
    [self removeBankAccount: account keepAssignedStatements: keepAssignedStatements];

    [self save];

    LogLeave;
}

#pragma mark - Page switching

- (void)updateStatusbar {
    LogEnter;

    BankingCategory  *cat = [self currentSelection];
    ShortDate *fromDate = [timeSlicer lowerBounds];
    ShortDate *toDate = [timeSlicer upperBounds];

    if (currentPage == 1) {
        NSDecimalNumber *spendingsValue = [cat valuesOfType: cat_spendings from: fromDate to: toDate];
        NSDecimalNumber *earningsValue = [cat valuesOfType: cat_earnings from: fromDate to: toDate];

        spendingsField.objectValue = spendingsValue;
        earningsField.objectValue = earningsValue;
    }

    spendingsField.hidden = currentPage != 1;
    earningsField.hidden = currentPage != 1;
    spendingsFieldLabel.hidden = currentPage != 1;
    earningsFieldLabel.hidden = currentPage != 1;

    LogLeave;
}

- (void)switchMainPage: (NSInteger)page {
    LogEnter;

    if (currentPage != page) {
        currentPage = page;
        switch (currentPage) {
            case 0: {
                [currentSection deactivate];
                [transfersController deactivate];
                [self activateHomeScreenTab];

                break;
            }

            case 1: {
                [transfersController deactivate];
                if (currentSection == nil) {
                    [self switchToAccountPage: 0];
                }

                [mainTabView selectTabViewItemAtIndex: 0];
                [currentSection activate];

                break;
            }

            case 2: {
                [currentSection deactivate];
                [self activateTransfersTab];

                break;
            }

            case 3: {
                [currentSection deactivate];
                [transfersController deactivate];
                [self activateStandingOrdersTab];

                break;
            }

            case 4: {
                [currentSection deactivate];
                [transfersController deactivate];
                [self activateDebitsTab];

                break;
            }
        }

        [self updateStatusbar];
    }
    LogLeave;
}

- (void)switchToAccountPage: (NSInteger)sectionIndex {
    LogEnter;

    if (currentSectionIndex != sectionIndex) {
        BOOL   pageHasChanged = NO;
        NSView *currentView;
        if (currentSection != nil) {
            currentView = [currentSection mainView];
        } else {
            currentView = sectionPlaceholder;
        }

        // Reset fetch predicate for the tree controller if we are switching away from
        // the category periods or rules definition view.
        BOOL oldSectionHidesAccounts = currentSectionIndex == 3 || currentSectionIndex == 4;
        BOOL newSectionHidesAccounts = sectionIndex == 3 || sectionIndex == 4;
        if (oldSectionHidesAccounts && !newSectionHidesAccounts) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == nil"];
            [categoryController setFetchPredicate: predicate];

            // Restore the previous expand state and selection (after a delay, to let the controller
            // propagate the changed content to the outline.
            [self performSelector: @selector(restoreBankAccountItemsStates) withObject: nil afterDelay: 0.1];

            [timeSlicer showControls: YES];
        }

        if (currentSection != nil && currentSection == heatMapController && sectionIndex != 6) {
            [timeSlicer setYearOnlyMode: NO];
        }

        currentSectionIndex = sectionIndex;
        NSRect frame = [currentView frame];
        switch (sectionIndex) {
            case 0:
                if (overviewController == nil) {
                    overviewController = [[StatementsOverviewController alloc] init];
                    if ([NSBundle.mainBundle loadNibNamed: @"StatementsOverview" owner: overviewController topLevelObjects: nil]) {
                        NSView *view = [overviewController mainView];
                        view.frame = frame;
                    }
                    [overviewController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
                }

                if (currentSection != overviewController) {
                    [currentSection deactivate];
                    [[overviewController mainView] setFrame: frame];
                    [rightPane replaceSubview: currentView with: [overviewController mainView]];
                    currentSection = overviewController;

                    pageHasChanged = YES;
                }

                // Update values in category tree to reflect time slicer interval again.
                [timeSlicer updateDelegate];
                break;

            case 1:
                if (categoryAnalysisController == nil) {
                    categoryAnalysisController = [[CategoryAnalysisWindowController alloc] init];
                    if ([NSBundle.mainBundle loadNibNamed: @"CategoryAnalysis" owner: categoryAnalysisController topLevelObjects: nil]) {
                        NSView *view = [categoryAnalysisController mainView];
                        view.frame = frame;
                    }
                    [categoryAnalysisController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
                }

                if (currentSection != categoryAnalysisController) {
                    [currentSection deactivate];
                    [[categoryAnalysisController mainView] setFrame: frame];
                    [rightPane replaceSubview: currentView with: [categoryAnalysisController mainView]];
                    currentSection = categoryAnalysisController;
                    [categoryAnalysisController updateTrackingAreas];
                    pageHasChanged = YES;
                }

                [timeSlicer updateDelegate];
                break;

            case 2:
                if (categoryReportingController == nil) {
                    categoryReportingController = [[CategoryRepWindowController alloc] init];
                    if ([NSBundle.mainBundle loadNibNamed: @"CategoryReporting" owner: categoryReportingController topLevelObjects: nil]) {
                        NSView *view = [categoryReportingController mainView];
                        view.frame = frame;
                    }
                    [categoryReportingController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
                }

                if (currentSection != categoryReportingController) {
                    [currentSection deactivate];
                    [[categoryReportingController mainView] setFrame: frame];
                    [rightPane replaceSubview: currentView with: [categoryReportingController mainView]];
                    currentSection = categoryReportingController;

                    // If a category is selected currently which has no child categories then move the
                    // selection to its parent instead.
                    BankingCategory *category = [self currentSelection];
                    if ([[category children] count] < 1) {
                        [categoryController setSelectedObject: category.parent];
                    }
                    pageHasChanged = YES;
                }

                [timeSlicer updateDelegate];
                break;

            case 3:
                [timeSlicer showControls: NO];

                if (categoryPeriodsController == nil) {
                    categoryPeriodsController = [[CategoryPeriodsWindowController alloc] init];
                    if ([NSBundle.mainBundle loadNibNamed: @"CategoryPeriods" owner: categoryPeriodsController topLevelObjects: nil]) {
                        NSView *view = [categoryPeriodsController mainView];
                        view.frame = frame;
                        [categoryPeriodsController connectScrollViews: accountsScrollView];
                    }
                    [categoryPeriodsController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
                    categoryPeriodsController.outline = accountsView;
                }

                if (currentSection != categoryPeriodsController) {
                    [currentSection deactivate];
                    [[categoryPeriodsController mainView] setFrame: frame];
                    [rightPane replaceSubview: currentView with: [categoryPeriodsController mainView]];
                    currentSection = categoryPeriodsController;

                    // In order to be able to line up the category entries with the grid we hide the bank
                    // accounts (if they weren't hidden already by the last section).
                    if (!oldSectionHidesAccounts) {
                        [self saveBankAccountItemsStates];

                        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == nil && isBankAcc == NO"];
                        [categoryController setFetchPredicate: predicate];
                        [categoryController prepareContent];
                    }
                    pageHasChanged = YES;
                }

                break;

            case 4:
                if (categoryDefinitionController == nil) {
                    categoryDefinitionController = [[CategoryDefWindowController alloc] init];
                    if ([NSBundle.mainBundle loadNibNamed: @"CategoryDefinition" owner: categoryDefinitionController topLevelObjects: nil]) {
                        NSView *view = [categoryDefinitionController mainView];
                        view.frame = frame;
                    }
                    [categoryDefinitionController setManagedObjectContext: managedObjectContext];
                    categoryDefinitionController.timeSliceManager = timeSlicer;
                    [categoryDefinitionController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
                }
                if (currentSection != categoryDefinitionController) {
                    [currentSection deactivate];
                    [[categoryDefinitionController mainView] setFrame: frame];
                    [rightPane replaceSubview: currentView with: [categoryDefinitionController mainView]];
                    currentSection = categoryDefinitionController;

                    // If a bank account is currently selected then switch to the not-assigned category.
                    // Bankaccounts don't use rules for assigning transfers to them.
                    BankingCategory *category = [self currentSelection];
                    if ([category isBankAccount]) {
                        [categoryController setSelectedObject: BankingCategory.nassRoot];
                    }

                    // Accounts cannot have rules for assignments in this view so hide them.
                    if (!oldSectionHidesAccounts) {
                        [self saveBankAccountItemsStates];

                        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == nil && isBankAcc == NO"];
                        [categoryController setFetchPredicate: predicate];
                        [categoryController prepareContent];
                    }
                    pageHasChanged = YES;
                }

                [timeSlicer updateDelegate];

                break;

            case 6:
                if (heatMapController == nil) {
                    heatMapController = [[CategoryHeatMapController alloc] init];
                    if ([NSBundle.mainBundle loadNibNamed: @"CategoryHeatMap" owner: heatMapController topLevelObjects: nil]) {
                        heatMapController.mainView.frame = frame;
                    }
                    [heatMapController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
                }
                if (currentSection != heatMapController) {
                    [currentSection deactivate];
                    heatMapController.mainView.frame = frame;
                    [rightPane replaceSubview: currentView with: heatMapController.mainView];
                    currentSection = heatMapController;
                    pageHasChanged = YES;
                }
                [timeSlicer setYearOnlyMode: YES];
                break;

        }

        if (pageHasChanged) {
            currentSection.selectedCategory = [self currentSelection];
            [currentSection activate];
            [accountsView setNeedsDisplay];
        }
    }

    LogLeave;
}

#pragma mark - File actions

- (IBAction)export: (id)sender {
    LogEnter;

    BankingCategory *cat;

    cat = [self currentSelection];
    ExportController *controller = [ExportController controller];
    [controller startExport: cat fromDate: [timeSlicer lowerBounds] toDate: [timeSlicer upperBounds]];

    LogLeave;
}

- (IBAction)import: (id)sender {
    LogEnter;

    ImportController *controller = [[ImportController alloc] init];
    int              res = [NSApp runModalForWindow: [controller window]];
    if (res == 0) {
        NSArray        *results = @[controller.importResult];
        NSNotification *notification = [NSNotification notificationWithName: PecuniaStatementsNotification object: results];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        newStatementsCount = 0;

        if ([defaults boolForKey: @"manualTransactionCheck"]) {
            selectWindowController = [[BSSelectWindowController alloc] init];
        }

        [self statementsNotification: notification];
        [self statementsFinalizeNotification: nil];
    }

    LogLeave;
}

- (BOOL)applicationShouldHandleReopen: (NSApplication *)theApplication hasVisibleWindows: (BOOL)flag {
    LogEnter;

    if (!flag) {
        [mainWindow makeKeyAndOrderFront: self];
    }

    LogLeave;

    return YES;
}

- (BOOL)canTerminate {
    LogEnter;

    // Check if word list is currently loaded. If so and update is still running, application cannot be terminated.
    if (self.updatingWordList) {
        NSRunAlertPanel(NSLocalizedString(@"AP34", nil),
                        NSLocalizedString(@"AP1707", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }
    
    // Check if there are unsent or unfinished transfers. Send unsent transfers if the users says so.
    BOOL canClose = [self checkForUnhandledTransfersAndSend];
    if (!canClose) {
        return NO;
    }
    
    // check if there are BankUsers. If not, don't show the donation popup
    NSArray *users = [BankUser allUsers];
    if ([users count] == 0) {
        return YES;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           hideDonationMessage = [defaults boolForKey: @"DonationPopup100"];

    if (!hideDonationMessage) {
        DonationMessageController *controller = [[DonationMessageController alloc] init];
        BOOL                      donate = [controller run];
        if (donate) {
            [self performSelector: @selector(donate:) withObject: self afterDelay: 0.0];
            return NO;
        }
    }

    LogLeave;

    return YES;
}

- (BankAccount *)selectedBankAccount {
    LogEnter;

    BankingCategory *cat = [self currentSelection];
    if (cat == nil) {
        return nil;
    }
    if ([cat isMemberOfClass: [BankingCategory class]]) {
        return nil;
    }

    NSString *accNumber = [cat valueForKey: @"accountNumber"];
    if (accNumber == nil || [accNumber isEqual: @""]) {
        return nil;
    }

    LogLeave;

    return (BankAccount *)cat;
}

- (IBAction)donate: (id)sender {
    LogEnter;

    // Check if there are any bank users.
    NSArray *users = [BankUser allUsers];
    if (users == nil || users.count == 0) {
        NSRunAlertPanel(NSLocalizedString(@"AP105", nil),
                        NSLocalizedString(@"AP803", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return;
    }

    // Switch to the transfers page.
    sidebar.selectedIndex = 7;

    // Start transfer editing process.
    [transfersController startDonationTransfer];
}

- (IBAction)startInternalTransfer: (id)sender {
    [self startTransferOfType: TransferTypeInternalSEPA fromAccount: self.selectedBankAccount statement: nil];
}

- (IBAction)startSepaTransfer: (id)sender {
    [self startTransferOfType: TransferTypeSEPA fromAccount: self.selectedBankAccount statement: nil];
}

- (void)startTransferOfType: (TransferType)type fromAccount: (BankAccount *)account statement: (BankStatement *)statement {
    LogEnter;

    if (account == nil || account.isManual.boolValue) {
        return;
    }

    // Check if BIC and IBAN are defined.
    if (type == TransferTypeSEPA || type == TransferTypeEU) {
        if (account.iban == nil || account.bic == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP101", nil),
                            NSLocalizedString(@"AP77", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil,
                            account.accountNumber);
            return;
        }
    }
    
    // Switch to the transfers page.
    sidebar.selectedIndex = 7;

    [transfersController startTransferOfType: type withAccount: account statement: statement];

    LogLeave;
}

- (void)createTemplateOfType: (TransferType)type fromStatement: (BankStatement *)statement {
    LogEnter;

    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // check if bic and iban is defined
    if (account != nil) {
        if (account.iban == nil || account.bic == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP101", nil),
                            NSLocalizedString(@"AP77", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil,
                            account.accountNumber);
            return;
        }
    }

    // Switch to the transfers page.
    sidebar.selectedIndex = 7;

    [transfersController createTemplateOfType: type fromStatement: statement];

    LogLeave;
}

- (BankingCategory *)currentSelection {
    NSArray *sel = [categoryController selectedObjects];
    if (sel == nil || [sel count] != 1) {
        return nil;
    }
    return sel[0];
}

#pragma mark - Outline delegate methods

/**
 * Prevent the outline from selecting entries under certain conditions.
 */
- (BOOL)outlineView: (NSOutlineView *)outlineView shouldSelectItem: (id)item {
    if (currentSection != nil) {
        if (currentSection == categoryReportingController) {
            // If category reporting is active then don't allow selecting entries without children.
            return [outlineView isExpandable: item];
        }

        if (currentSection == categoryDefinitionController) {
            BankingCategory *category = [item representedObject];
            if ([category isBankAccount]) {
                return NO;
            }
            if ([categoryDefinitionController categoryShouldChange] == NO) {
                return NO;
            }
        }
    }

    return YES;
}

- (BOOL)outlineView: (NSOutlineView *)ov writeItems: (NSArray *)items toPasteboard: (NSPasteboard *)pboard {
    BankingCategory *cat;

    cat = [items[0] representedObject];
    if (cat == nil) {
        return NO;
    }
    if ([cat isBankAccount]) {
        return NO;
    }
    if ([cat isRoot]) {
        return NO;
    }
    if (cat == [BankingCategory nassRoot]) {
        return NO;
    }
    NSURL  *uri = [[cat objectID] URIRepresentation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uri];
    [pboard declareTypes: @[CategoryDataType] owner: self];
    [pboard setData: data forType: CategoryDataType];
    return YES;
}

- (NSDragOperation)outlineView: (NSOutlineView *)ov validateDrop: (id <NSDraggingInfo>)info proposedItem: (id)item proposedChildIndex: (NSInteger)childIndex {
    NSPasteboard *pboard = [info draggingPasteboard];

    // This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
    if (childIndex >= 0) {
        return NSDragOperationNone;
    }
    if (item == nil) {
        return NSDragOperationNone;
    }
    BankingCategory *cat = (BankingCategory *)[item representedObject];
    if (cat == nil) {
        return NSDragOperationNone;
    }

    [[NSCursor arrowCursor] set];

    NSString *type = [pboard availableTypeFromArray: @[BankStatementDataType, CategoryDataType]];
    if (type == nil) {
        return NO;
    }
    if ([type isEqual: BankStatementDataType]) {
        if ([cat isBankAccount]) {
            // only allow for manual accounts
            BankAccount *account = (BankAccount *)cat;
            if ([account.isManual boolValue] == YES) {
                return NSDragOperationCopy;
            }
            return NSDragOperationNone;
        }

        NSDragOperation mask = [info draggingSourceOperationMask];
        BankingCategory        *scat = [self currentSelection];
        if ([cat isRoot]) {
            return NSDragOperationNone;
        }
        
        // if not yet assigned: move
        if (scat == [BankingCategory nassRoot]) {
            return NSDragOperationMove;
        }
        if (mask == NSDragOperationCopy && cat != [BankingCategory nassRoot]) {
            return NSDragOperationCopy;
        }
        if (mask == NSDragOperationGeneric && cat != [BankingCategory nassRoot]) {
            [splitCursor set];
            return NSDragOperationGeneric;
        }
        return NSDragOperationMove;
    } else {
        if ([cat isBankAccount]) {
            return NSDragOperationNone;
        }
        NSData            *data = [pboard dataForType: type];
        NSURL             *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        NSManagedObjectID *moID = [[managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
        BankingCategory          *scat = (BankingCategory *)[managedObjectContext objectWithID: moID];
        if ([scat checkMoveToCategory: cat] == NO) {
            return NSDragOperationNone;
        }
        return NSDragOperationMove;
    }
}

- (BOOL)outlineView: (NSOutlineView *)outlineView acceptDrop: (id <NSDraggingInfo>)info item: (id)item childIndex: (NSInteger)childIndex {
    BankingCategory     *targetCategory = (BankingCategory *)[item representedObject];
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString     *type = [pboard availableTypeFromArray: @[BankStatementDataType, CategoryDataType]];
    if (type == nil) {
        return NO;
    }
    NSData *data = [pboard dataForType: type];

    if ([type isEqual: BankStatementDataType]) {
        NSDragOperation mask = [info draggingSourceOperationMask];
        NSArray         *uris = [NSKeyedUnarchiver unarchiveObjectWithData: data];

        BOOL needBankRootUpdate = NO;
        for (NSURL *uri in uris) {
            NSManagedObjectID *moID = [[managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
            if (moID == nil) {
                continue;
            }
            StatCatAssignment *assignment = (StatCatAssignment *)[managedObjectContext objectWithID: moID];

            if ([[self currentSelection] isBankAccount]) {
                // if already assigned or copy modifier is pressed, copy the complete bank statement amount - else assign residual amount (move)
                if ([targetCategory isBankAccount]) {
                    // drop on a manual account
                    BankAccount *account = (BankAccount *)targetCategory;
                    [account copyStatement: assignment.statement];
                    needBankRootUpdate = YES;
                } else {
                    if (mask == NSDragOperationCopy || [assignment.statement.isAssigned boolValue]) {
                        [assignment.statement assignToCategory: targetCategory];
                    } else if (mask == NSDragOperationGeneric) {
                        BOOL            negate = NO;
                        NSDecimalNumber *residual = assignment.statement.nassValue;
                        if ([residual compare: [NSDecimalNumber zero]] == NSOrderedAscending) {
                            negate = YES;
                        }
                        if (negate) {
                            residual = [[NSDecimalNumber zero] decimalNumberBySubtracting: residual];
                        }

                        AssignmentController *controller = [[AssignmentController alloc] initWithAmount: residual];
                        int                  res = [NSApp runModalForWindow: controller.window];
                        if (res) {
                            return NO;
                        }
                        residual = controller.amount;

                        if (negate) {
                            residual = [[NSDecimalNumber zero] decimalNumberBySubtracting: residual];
                        }
                        [assignment.statement assignAmount: residual toCategory: targetCategory withInfo: controller.info];
                    } else {
                        [assignment.statement assignAmount: assignment.statement.nassValue toCategory: targetCategory withInfo: nil];
                    }
                }
            } else {
                if (mask == NSDragOperationCopy) {
                    [assignment.statement assignAmount: assignment.value toCategory: targetCategory withInfo: nil];
                } else if (mask == NSDragOperationGeneric) {
                    // split
                    BOOL            negate = NO;
                    NSDecimalNumber *amount = assignment.value;
                    if ([amount compare: [NSDecimalNumber zero]] == NSOrderedAscending) {
                        negate = YES;
                    }
                    if (negate) {
                        amount = [[NSDecimalNumber zero] decimalNumberBySubtracting: amount];
                    }

                    AssignmentController *controller = [[AssignmentController alloc] initWithAmount: amount];
                    int                  res = [NSApp runModalForWindow: controller.window];
                    if (res) {
                        return NO;
                    }
                    amount = controller.amount;

                    if (negate) {
                        amount = [[NSDecimalNumber zero] decimalNumberBySubtracting: amount];
                    }
                    // now we have the amount that should be assigned to the target category
                    if ([[amount abs] compare: [assignment.value abs]] != NSOrderedDescending) {
                        [assignment moveAmount: amount toCategory: targetCategory withInfo: controller.info];
                    }
                } else {
                    [assignment moveToCategory: targetCategory];
                }
            }
        }
        // Update category values including rollup for all categories.
        [BankingCategory updateBalancesAndSums];
        
        [overviewController reload];

        if (needBankRootUpdate) {
            [[BankingCategory bankRoot] updateCategorySums];
        }
    } else {
        NSURL             *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        NSManagedObjectID *moID = [[managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
        if (moID == nil) {
            return NO;
        }
        BankingCategory *scat = (BankingCategory *)[managedObjectContext objectWithID: moID];
        [scat setValue: targetCategory forKey: @"parent"];

        [[BankingCategory catRoot] updateCategorySums];
    }

    [self save];

    return YES;
}

- (void)outlineViewSelectionDidChange: (NSNotification *)aNotification {
    if (shuttingDown) {
        return;
    }

    BankingCategory *cat = [self currentSelection];

    // Update current section if the default is not active.
    if (currentSection != nil) {
        currentSection.selectedCategory = cat;
    }
    [self updateStatusbar];
}

- (void)outlineView: (NSOutlineView *)outlineView willDisplayCell: (ImageAndTextCell *)cell
     forTableColumn: (NSTableColumn *)tableColumn item: (id)item {
    if (![[tableColumn identifier] isEqualToString: @"name"]) {
        return;
    }

    BankingCategory *cat = [item representedObject];
    if (cat == nil) {
        return;
    }

    cell.swatchColor = cat.categoryColor;

    if (moneyImage == nil) {
        moneyImage = [NSImage imageNamed: @"money_18.png"];
        moneySyncImage = [NSImage imageNamed: @"money_sync_18.png"];

        bankImage = [NSImage imageNamed: @"icon95-1" fromCollection: 1];
    }

    if (cat.iconName == nil) {
        [self determineDefaultIconForCategory: cat];
    }

    if (cat.iconName.length > 0) {
        NSString *path;
        if ([cat.iconName isAbsolutePath]) {
            path = cat.iconName;
        } else {
            NSURL *url = [NSURL URLWithString: cat.iconName];
            if (url.scheme == nil) { // Old style collection item.
                NSString *subfolder = [cat.iconName stringByDeletingLastPathComponent];
                path = [[NSBundle mainBundle] pathForResource: [cat.iconName lastPathComponent]
                                                       ofType: @"icns"
                                                  inDirectory: subfolder];
            } else {
                if ([url.scheme isEqualToString: @"collection"]) { // An image from one of our collections.
                    NSDictionary *parameters = [NSDictionary dictForUrlParameters: url];
                    NSString     *subfolder = [@"Collections/" stringByAppendingString : parameters[@"c"]];
                    path = [[NSBundle mainBundle] pathForResource: [url.host stringByDeletingPathExtension]
                                                           ofType: url.host.pathExtension
                                                      inDirectory: subfolder];

                } else {
                    if ([url.scheme isEqualToString: @"image"]) { // An image from our data bundle.
                        NSString *targetFolder = [MOAssistant.sharedAssistant.pecuniaFileURL.path stringByAppendingString: @"/Images/"];
                        path = [targetFolder stringByAppendingString: url.host];
                    }
                }
            }
        }
        if (path != nil) {
            // Also assigns nil if the path doesn't exist or the referenced file cannot be used as image.
            [cell setImage: [[NSImage alloc] initWithContentsOfFile: path]];
        } else {
            [cell setImage: nil];
        }
    } else {
        [cell setImage: nil];
    }

    NSInteger numberUnread = 0;

    if ([cat isBankAccount] && cat.accountNumber == nil) {
        [cell setImage: bankImage];
    }

    if ([cat isBankAccount] && cat.accountNumber != nil) {
        BankAccount *account = (BankAccount *)cat;
        if ([account.isManual boolValue] || [account.noAutomaticQuery boolValue]) {
            [cell setImage: moneyImage];
        } else {
            [cell setImage: moneySyncImage];
        }
    }

    if (![cat isBankAccount] || [cat isRoot]) {
        numberUnread = 0;
    } else {
        numberUnread = [(BankAccount *)cat unread];
    }

    BOOL itemIsDisabled = NO;
    if (currentSection != nil) {
        if (currentSection == categoryReportingController && [[cat children] count] == 0) {
            itemIsDisabled = YES;
        }
        if (currentSection == categoryDefinitionController && [cat isBankAccount]) {
            itemIsDisabled = YES;
        }
    }

    BOOL itemIsRoot = [cat isRoot];
    if (itemIsRoot) {
        [cell setImage: nil];
    }

    [cell setValues: cat.catSum
           currency: cat.currency
             unread: numberUnread
           disabled: itemIsDisabled
             isRoot: itemIsRoot
           isHidden: cat.isHidden.boolValue
          isIgnored: cat.noCatRep.boolValue];
}

#pragma mark - Splitview delegate methods

- (CGFloat)splitView: (NSSplitView *)splitView constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)dividerIndex {
    if (splitView == mainVSplit) {
        return 370;
    }
    return proposedMin;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)dividerIndex {
    if (splitView == mainVSplit) {
        return NSWidth([mainWindow frame]) - 800;
    }
    return proposedMax;
}

#pragma mark - Sidebar delegate methods

- (void)sideBar: (EDSideBar *)tabBar didSelectButton: (NSInteger)index {
    switch (index) {
        case 0: // Home screen.
            [self switchMainPage: 0];
            break;

        case 1: // Accounts + categories, overview section.
            [self switchMainPage: 1];
            [self switchToAccountPage: 0];
            break;

        case 2:
            [self switchMainPage: 1];
            [self switchToAccountPage: 1];
            break;

        case 3:
            [self switchMainPage: 1];
            [self switchToAccountPage: 6];
            break;

        case 4:
            [self switchMainPage: 1];
            [self switchToAccountPage: 2];
            break;

        case 5:
            [self switchMainPage: 1];
            [self switchToAccountPage: 3];
            break;

        case 6:
            [self switchMainPage: 1];
            [self switchToAccountPage: 4];
            break;

        case 7: // Transfers.
            [self switchMainPage: 2];
            break;

        case 8: // Standing orders.
            [self switchMainPage: 3];
            break;

        case 9: // Direct debits.
            [self switchMainPage: 4];
            break;
    }
}

#pragma mark - Menu handling

- (BOOL)validateMenuItem: (NSMenuItem *)item {
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];

    if (idx != 0 || currentSectionIndex != 0) {
        if ([item action] == @selector(export:)) {
            return NO;
        }
        if ([item action] == @selector(addAccount:)) {
            return NO;
        }
        if ([item action] == @selector(showProperties:)) {
            return NO;
        }
        if ([item action] == @selector(deleteAccount:)) {
            return NO;
        }
        if ([item action] == @selector(enqueueRequest:)) {
            return NO;
        }
        if ([item action] == @selector(startLocalTransfer:)) {
            return NO;
        }
        if ([item action] == @selector(startEuTransfer:)) {
            return NO;
        }
        if ([item action] == @selector(startSepaTransfer:)) {
            return NO;
        }
        if ([item action] == @selector(startInternalTransfer:)) {
            return NO;
        }
        if ([item action] == @selector(splitStatement:)) {
            return NO;
        }
        if ([item action] == @selector(deleteStatement:)) {
            return NO;
        }
        if ([item action] == @selector(addStatement:)) {
            return NO;
        }
        if ([item action] == @selector(creditCardSettlements:)) {
            return NO;
        }
        if ([item action] == @selector(accountStatements:)) {
            return NO;
        }
        if ([item action] == @selector(updateSupportedTransactions:)) {
            return NO;
        }
        if ([item action] == @selector(updateStatementBalances:)) {
            return NO;
        }
        if ([item action] == @selector(accountMaintenance:)) {
            return NO;
        }
    }

    if (idx == 0 && currentSectionIndex == 0) {
        BankingCategory *cat = [self currentSelection];
        if (cat == nil || [cat accountNumber] == nil) {
            if ([item action] == @selector(showProperties:)) {
                return NO;
            }
            if ([item action] == @selector(deleteAccount:)) {
                return NO;
            }
            if ([item action] == @selector(startLocalTransfer:)) {
                return NO;
            }
            if ([item action] == @selector(startEuTransfer:)) {
                return NO;
            }
            if ([item action] == @selector(startSepaTransfer:)) {
                return NO;
            }
            if ([item action] == @selector(startInternalTransfer:)) {
                return NO;
            }
            if ([item action] == @selector(addStatement:)) {
                return NO;
            }
            if ([item action] == @selector(creditCardSettlements:)) {
                return NO;
            }
            if ([item action] == @selector(accountStatements:)) {
                return NO;
            }
            if ([item action] == @selector(updateSupportedTransactions:)) {
                return NO;
            }
            if ([item action] == @selector(updateStatementBalances:)) {
                return NO;
            }
            if ([item action] == @selector(accountMaintenance:)) {
                return NO;
            }
        }
        if ([cat isKindOfClass: [BankAccount class]]) {
            BankAccount *account = (BankAccount *)cat;
            if ([[account isManual] boolValue] == YES) {
                if ([item action] == @selector(startLocalTransfer:)) {
                    return NO;
                }
                if ([item action] == @selector(startEuTransfer:)) {
                    return NO;
                }
                if ([item action] == @selector(startSepaTransfer:)) {
                    return NO;
                }
                if ([item action] == @selector(startInternalTransfer:)) {
                    return NO;
                }
                if ([item action] == @selector(creditCardSettlements:)) {
                    return NO;
                }
                if ([item action] == @selector(accountStatements:)) {
                    return NO;
                }
            } else {
                if ([item action] == @selector(addStatement:)) {
                    return NO;
                }
                if ([item action] == @selector(creditCardSettlements:)) {
                    /* todo:
                    if ([SupportedTransactionInfo isTransactionSupported: TransactionType_CCSettlement forAccount: account] == NO) {
                        return NO;
                    }
                    */
                }
                if ([item action] == @selector(accountStatements:)) {
                    return [HBCIBackend.backend isTransactionSupportedForAccount:TransactionType_AccountStatements account:account];
                }
            }
        }

        if (requestRunning && [item action] == @selector(enqueueRequest:)) {
            return NO;
        }

        if ([(id)currentSection respondsToSelector : @selector(validateMenuItem:)]) {
            BOOL result = [(id)currentSection validateMenuItem : item];
            if (!result) {
                return NO;
            }
        }
    }
    return YES;
}

#pragma mark - Category management

- (void)updateNotAssignedCategory {
    LogEnter;

    NSError *error = nil;

    // fetch all bank statements
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSArray *stats = [managedObjectContext executeFetchRequest: request error: &error];
    if (error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    for (BankStatement *stat in stats) {
        [stat updateAssigned];
    }
    [self save];

    LogLeave;
}

- (void)deleteCategory: (id)sender {
    LogEnter;

    BankingCategory *cat = [self currentSelection];
    if (cat == nil) {
        return;
    }

    if ([cat isRemoveable] == NO) {
        return;
    }
    NSArray           *stats = [[cat mutableSetValueForKey: @"assignments"] allObjects];
    StatCatAssignment *stat;

    if ([stats count] > 0) {
        int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP303", nil),
                                          NSLocalizedString(@"AP304", nil),
                                          NSLocalizedString(@"AP4", nil),
                                          NSLocalizedString(@"AP3", nil),
                                          nil,
                                          [cat localName],
                                          [stats count],
                                          nil
                                          );
        if (res != NSAlertAlternateReturn) {
            return;
        }
    }

    //  Delete bank statements from category first.
    for (stat in stats) {
        [stat remove];
    }
    [categoryController remove: cat];
    [BankingCategory updateBalancesAndSums];

    // workaround: NSTreeController issue: when an item is removed and the NSOutlineViewSelectionDidChange notification is sent,
    // the selectedObjects: message returns the wrong (the old) selection
    [self performSelector: @selector(outlineViewSelectionDidChange:) withObject: nil afterDelay: 0];

    // Save changes to avoid losing category changes in case of failures/crashs.

    LogLeave;
    [self save];
}

- (void)addCategory: (id)sender {
    LogEnter;

    BankingCategory *cat = [self currentSelection];
    if (cat.isBankAccount) {
        return;
    }
    if (cat.isRoot) {
        [categoryController addChild: sender];
    } else {
        [categoryController add: sender];
    }
    [accountsView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];

    [self save];

    LogLeave;
}

- (void)insertCategory: (id)sender {
    LogEnter;

    BankingCategory *cat = [self currentSelection];
    if ([cat isInsertable] == NO) {
        return;
    }
    [categoryController addChild: sender];
    [accountsView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];

    [self save];

    LogLeave;
}

- (IBAction)manageCategories: (id)sender {
    LogEnter;

    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment: clickedSegment];
    switch (clickedSegmentTag) {
        case 0:[self addCategory: sender]; break;

        case 1:[self insertCategory: sender]; break;

        case 2:[self deleteCategory: sender]; break;

        default: return;
    }
    [currentSection activate]; // Notifies the current section to updates values if necessary.

    LogLeave;
}

- (NSString *)autosaveNameForTimeSlicer: (TimeSliceManager *)tsm {
    return @"AccMainTimeSlice";
}

- (void)timeSliceManager: (TimeSliceManager *)tsm changedIntervalFrom: (ShortDate *)from to: (ShortDate *)to {
    if (managedObjectContext == nil) {
        return;
    }
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];
    if (idx) {
        return;
    }
    [BankingCategory setCatReportFrom: from to: to];

    // Update current section if the default is not active.
    if (currentSection != nil) {
        [currentSection setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
    }

    [self updateStatusbar];
}

- (void)controlTextDidBeginEditing: (NSNotification *)aNotification {
    if ([aNotification object] == accountsView) {
        BankingCategory *cat = [self currentSelection];
        accountsView.saveCatName = [cat name];
    }
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification {
    // Category name changed
    if ([aNotification object] == accountsView) {
        BankingCategory *cat = [self currentSelection];
        if ([cat name] == nil) {
            [cat setValue: accountsView.saveCatName forKey: @"name"];
        }
        [categoryController resort];
        if (cat) {
            [categoryController setSelectedObject: cat];
        }

        // Category was created or changed. Save changes.
        [self save];
    }
}

- (void)setRestart {
    restart = YES;
}

- (IBAction)deleteStatement: (id)sender {
    LogEnter;

    // This function is only called if the associated menu item is enabled, which is only the case
    // if (amongst other) the current section is the statements overview.
    if (!self.currentSelection.isBankAcc.boolValue) {
        return;
    }

    [(id)currentSection deleteSelectedStatements];
    [overviewController clearStatementFilter];

    [self save];

    LogLeave;
}

- (void)splitStatement: (id)sender {
    LogEnter;

    // This function is only called if the associated menu item is enabled, which is only the case
    // if (amongst others) the current section is the statements overview.
    [(id)currentSection splitSelectedStatement];

    LogLeave;
}

- (IBAction)addStatement: (id)sender {
    LogEnter;

    BankingCategory *cat = [self currentSelection];
    if (cat == nil) {
        return;
    }
    if (cat.accountNumber == nil) {
        return;
    }

    BankStatementController *statementController = [[BankStatementController alloc] initWithAccount: (BankAccount *)cat statement: nil];

    int res = [NSApp runModalForWindow: [statementController window]];
    if (res) {
        [self save];
        [self.currentSelection updateAssignmentsForReportRange];
    }

    LogLeave;
}

- (IBAction)splitPurpose: (id)sender {
    LogEnter;

    BankingCategory *cat = [self currentSelection];

    PurposeSplitController *splitController = [[PurposeSplitController alloc] initWithAccount: (BankAccount *)cat];
    [NSApp runModalForWindow: [splitController window]];

    LogLeave;
}

/**
 * Takes the (localized) title of the given category and determines an icon for it from the default collection.
 */
- (void)determineDefaultIconForCategory: (BankingCategory *)category {
    if (defaultIcons == nil) {
        NSMutableArray *entries = [NSMutableArray arrayWithCapacity: 100];

        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *path = [mainBundle pathForResource: @"category-icon-defaults" ofType: @"txt"];
        NSError  *error = nil;
        NSString *s = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
        if (error) {
            LogError(@"Error reading default category icon assignments file at %@\n%@", path, [error localizedFailureReason]);
        } else {
            NSArray *lines = [s componentsSeparatedByString: @"\n"];
            for (__strong NSString *line in lines) {
                NSRange hashPosition = [line rangeOfString: @"#"];
                if (hashPosition.length > 0) {
                    line = [line substringToIndex: hashPosition.location];
                }
                line = [line stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                if (line.length == 0) {
                    continue;
                }

                NSArray *components = [line componentsSeparatedByString: @"="];
                if (components.count < 2) {
                    continue;
                }
                NSString *icon = [components[0] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                NSArray  *keywordArray = [components[1] componentsSeparatedByString: @","];

                NSMutableArray *keywords = [NSMutableArray arrayWithCapacity: keywordArray.count];
                for (__strong NSString *keyword in keywordArray) {
                    keyword = [keyword stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                    if (keyword.length == 0) {
                        continue;
                    }
                    [keywords addObject: keyword];
                }
                NSDictionary *entry = @{
                    @"icon": icon, @"keywords": keywords
                };
                [entries addObject: entry];
            }
        }

        defaultIcons = entries;
    }

    // Finding a default icon means to compare the category title with all the keywords we have in our defaultIcons
    // list. For flexibility we also compare substrings. Exact matches get priority though. If there's more than one hit
    // of the same priority then that wins which has fewer keywords assigned (so is likely more specialized).
    NSString *name = category.name;
    if ([name hasPrefix: @"++"]) {
        // One of the predefined root notes. They don't have an image.
        category.iconName = @"";
        return;
    }

    NSString   *bestMatch = @"";
    BOOL       exactMatch = NO;
    NSUInteger currentCount = 1000; // Number of keywords assigned to the best match so far.
    for (NSDictionary *entry in defaultIcons) {
        NSArray *keywords = entry[@"keywords"];
        for (NSString *keyword in keywords) {
            if ([keyword caseInsensitiveCompare: @"Default"] == NSOrderedSame && bestMatch.length == 0) {
                // No match so far, but we found the default entry. Keep this as first best match.
                bestMatch = entry[@"icon"];
                continue;
            }
            NSRange range = [name rangeOfString: keyword options: NSCaseInsensitiveSearch];
            if (range.length == 0) {
                continue; // No match at all.
            }

            if (range.length == name.length) {
                // Exact match. If there wasn't any exact match before then use this one as the current
                // best match, ignoring any previous partial matches.
                if (!exactMatch || keywords.count < currentCount) {
                    exactMatch = YES;
                    bestMatch = entry[@"icon"];
                    currentCount = keywords.count;
                }

                // If the current keyword count is 1 then we can't get any better. So stop here with what we have.
                if (currentCount == 1) {
                    category.iconName = bestMatch;
                    return;
                }
            } else {
                // Only consider this partial match if we haven't had any exact match so far.
                if (!exactMatch && keywords.count < currentCount) {
                    bestMatch = entry[@"icon"];
                    currentCount = keywords.count;
                }
            }
        }
    }
    // The icon determined is one of the default collection.
    category.iconName = [@"Collections/1/" stringByAppendingString : bestMatch];
}

#pragma mark - Miscellaneous code

/**
 * Saves the expand states of the top bank account node and all its children.
 * Also saves the current selection if it is on a bank account.
 */
- (void)saveBankAccountItemsStates {
    LogEnter;

    BankingCategory *category = [self currentSelection];
    if ([category isBankAccount]) {
        lastSelection = category;
        [categoryController setSelectedObject: BankingCategory.nassRoot];
    }
    bankAccountItemsExpandState = [NSMutableArray array];
    NSUInteger row, numberOfRows = [accountsView numberOfRows];

    for (row = 0; row < numberOfRows; row++) {
        id       item = [accountsView itemAtRow: row];
        BankingCategory *category = [item representedObject];
        if (![category isBankAccount]) {
            break;
        }
        if ([accountsView isItemExpanded: item]) {
            [bankAccountItemsExpandState addObject: category];
        }
    }
    LogLeave;
}

/**
 * Restores the previously saved expand states of all bank account nodes and sets the
 * last selection if it was on a bank account node.
 */
- (void)restoreBankAccountItemsStates {
    LogEnter;

    NSUInteger row, numberOfRows = [accountsView numberOfRows];
    for (BankingCategory *savedItem in bankAccountItemsExpandState) {
        for (row = 0; row < numberOfRows; row++) {
            id       item = [accountsView itemAtRow: row];
            BankingCategory *object = [item representedObject];
            if ([object.name isEqualToString: savedItem.name]) {
                [accountsView expandItem: item];
                numberOfRows = [accountsView numberOfRows];
                break;
            }
        }
    }
    bankAccountItemsExpandState = nil;

    // Restore the last selection, but only when selecting the item is allowed.
    if (lastSelection != nil && currentSection != categoryReportingController && currentSection != categoryDefinitionController) {
        [categoryController setSelectedObject: lastSelection];
    }
    lastSelection = nil;

    LogLeave;
}

- (void)syncAllAccounts {
    LogEnter;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    autoSyncRunning = YES;
    [self synchronizeAccount: BankingCategory.bankRoot];

    [defaults setObject: [NSDate date] forKey: @"lastSyncDate"];

    // if autosync, setup next timer event
    BOOL autoSync = [defaults boolForKey: @"autoSync"];
    if (autoSync) {
        NSDate *syncTime = [defaults objectForKey: @"autoSyncTime"];
        if (syncTime == nil) {
            LogWarning(@"Auto synching enabled, but no autosync time defined.");
            return;
        }
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        // set date +24Hr
        NSDateComponents *comps1 = [calendar components: NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay fromDate: [NSDate dateWithTimeIntervalSinceNow: 86400]];
        NSDateComponents *comps2 = [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: syncTime];
        [comps1 setHour: [comps2 hour]];
        [comps1 setMinute: [comps2 minute]];
        NSDate *syncDate = [calendar dateFromComponents: comps1];
        // syncTime in future: setup Timer
        NSTimer *timer = [[NSTimer alloc] initWithFireDate: syncDate
                                                  interval: 0.0
                                                    target: self
                                                  selector: @selector(autoSyncTimerEvent:)
                                                  userInfo: nil
                                                   repeats: NO];
        [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
    }

    LogLeave;
}

- (void)checkForAutoSync {
    BOOL           syncDone = NO;
    NSDate         *syncTime;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           syncAtStartup = [defaults boolForKey: @"syncAtStartup"];
    BOOL           autoSync = [defaults boolForKey: @"autoSync"];
    if (!(autoSync || syncAtStartup)) {
        return;
    }
    if (autoSync) {
        syncTime = [defaults objectForKey: @"autoSyncTime"];
        if (syncTime == nil) {
            LogWarning(@"Auto synching enabled, but no autosync time defined.");
            autoSync = NO;
        }
    }
    NSDate    *lastSyncDate = [defaults objectForKey: @"lastSyncDate"];
    ShortDate *d1 = [ShortDate dateWithDate: lastSyncDate];
    ShortDate *d2 = [ShortDate dateWithDate: [NSDate date]];
    if ((lastSyncDate == nil || [d1 compare: d2] != NSOrderedSame) && syncAtStartup) {
        // no sync done today. If in startup, do immediate sync
        [self performSelector: @selector(syncAllAccounts) withObject: nil afterDelay: 5.0];
        syncDone = YES;
    }

    if (!autoSync) {
        return;
    }
    // get today's sync time.
    NSCalendar       *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    NSDateComponents *comps1 = [calendar components: NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay fromDate: [NSDate date]];
    NSDateComponents *comps2 = [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: syncTime];

    [comps1 setHour: [comps2 hour]];
    [comps1 setMinute: [comps2 minute]];
    NSDate *syncDate = [calendar dateFromComponents: comps1];
    // if syncTime has passed, do immediate sync
    if ([syncDate compare: [NSDate date]] == NSOrderedAscending) {
        if (!syncDone) {
            [self performSelector: @selector(syncAllAccounts) withObject: nil afterDelay: 5.0];
        }
    } else {
        // syncTime in future: setup Timer
        NSTimer *timer = [[NSTimer alloc] initWithFireDate: syncDate
                                                  interval: 0.0
                                                    target: self
                                                  selector: @selector(autoSyncTimerEvent:)
                                                  userInfo: nil
                                                   repeats: NO];
        [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
    }
}

- (void)applicationWillFinishLaunching: (NSNotification *)notification {
    LogEnter;

    // Display main window after restoring its size.
    // Need to manually handle storing the size and position because of problems
    // with the increased title bar.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *s = [userDefaults stringForKey: @"mcmain"];
    if (s != nil) {
        [mainWindow setFrame: NSRectFromString(s) display: NO];
    }

    [mainWindow display];
    [mainWindow makeKeyAndOrderFront: self];

    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP108", nil) removeAfter: 0];

    mainVSplit.fixedIndex = 0;

    LogLeave;
}

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification {
    LogEnter;

    StatusBarController *sc = [StatusBarController controller];
    MOAssistant         *assistant = [MOAssistant sharedAssistant];

    // Load context & model.
    @try {
        model = [assistant model];
        [assistant initDatafile: nil]; // use default data file
        managedObjectContext = [assistant context];
    }
    @catch (NSError *error) {
        LogError(@"%@", error.debugDescription);
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        [NSApp terminate: self];
    }

    // Open encrypted database
    if (assistant.isEncrypted) {
        StatusBarController *sc = [StatusBarController controller];
        [sc startSpinning];
        [sc setMessage: NSLocalizedString(@"AP108", nil) removeAfter: 0];

        @try {
            [assistant decrypt];
            managedObjectContext = [assistant context];
        }
        @catch (NSError *error) {
            LogError(@"%@", error.debugDescription);
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            [NSApp terminate: self];
        }
    }

    [self setDefaultUserSettings];
    [self migrate];

    [self publishContext];

    [sc stopSpinning];
    [sc clearMessage];

    [mainWindow.contentView setHidden: NO];

    //sidebar.hidden = YES;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey: @"restoreActivePage"]) {
        NSInteger index = [LocalSettingsController.sharedSettings integerForKey: @"activePage"];
        sidebar.selectedIndex = index;
    } else {
        [self switchMainPage: 0];
    }

    [mainVSplit restorePosition];

    [self checkForAutoSync];

    // Add default tags if there are none yet.
    NSError        *error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"allTags"];
    NSUInteger     count = [managedObjectContext countForFetchRequest: request error: &error];
    if (error != nil) {
        LogError(@"Error reading tags: %@", error.localizedDescription);
    }
    if (count == 0) {
        [Tag createDefaultTags];
    }

    // Add default categories if there aren't any but the predefined ones.
    if ([BankingCategory.catRoot.children count] == 1) {
        [BankingCategory createDefaultCategories];
    }

    // Check if there are any bank users or at least manual accounts.
    if (BankUser.allUsers.count == 0 && [BankingCategory.bankRoot.children count] == 0) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP804", nil),
                                  NSLocalizedString(@"AP151", nil),
                                  NSLocalizedString(@"AP3", nil),
                                  NSLocalizedString(@"AP800", nil),
                                  nil
                                  );
        if (res == NSAlertDefaultReturn) {
            [self editBankUsers: self];
        }
    }

    LogLeave;
}

- (NSApplicationTerminateReply)applicationShouldTerminate: (NSApplication *)sender {
    LogEnter;

    if ([self canTerminate] == NO) {
        return NSTerminateCancel;
    }
    return NSTerminateNow;
}

- (void)applicationWillTerminate: (NSNotification *)aNotification {
    LogEnter;

    shuttingDown = YES;

    [mainVSplit savePosition];
    MessageLog.log.isComTraceActive = NO; // If that was active it will delete the trace log file.

    [LocalSettingsController.sharedSettings setInteger: sidebar.selectedIndex forKey: @"activePage"];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject: NSStringFromRect(mainWindow.frame) forKey: @"mcmain"];

    [currentSection deactivate];
    [accountsView saveState];

    // Remove explicit bindings and observers to speed up shutdown.
    [categoryController removeObserver: self forKeyPath: @"arrangedObjects.catSum"];

    if ([homeScreenController respondsToSelector: @selector(terminate)]) {
        [homeScreenController terminate];
    }
    if ([overviewController respondsToSelector: @selector(terminate)]) {
        [overviewController terminate];
    }
    if ([categoryAnalysisController respondsToSelector: @selector(terminate)]) {
        [categoryAnalysisController terminate];
    }
    if ([categoryReportingController respondsToSelector: @selector(terminate)]) {
        [categoryReportingController terminate];
    }
    if ([categoryDefinitionController respondsToSelector: @selector(terminate)]) {
        [categoryDefinitionController terminate];
    }
    if ([categoryPeriodsController respondsToSelector: @selector(terminate)]) {
        [categoryPeriodsController terminate];
    }
    if ([transfersController respondsToSelector: @selector(terminate)]) {
        [transfersController terminate];
    }
    if ([standingOrderController respondsToSelector: @selector(terminate)]) {
        [standingOrderController terminate];
    }
    if ([debitsController respondsToSelector: @selector(terminate)]) {
        [debitsController terminate];
    }
    if ([heatMapController respondsToSelector: @selector(terminate)]) {
        [heatMapController terminate];
    }

    dockIconController = nil;

    if (managedObjectContext && [MOAssistant sharedAssistant].isMaxIdleTimeExceeded == NO) {
        if (![self save]) {
            return;
        }
    }

    [[MOAssistant sharedAssistant] shutdown];
    [WorkerThread finish];

    // if application shall restart, launch new task
    if (restart) {
        NSProcessInfo *pi = [NSProcessInfo processInfo];
        NSArray       *args = [pi arguments];
        NSString      *path = [args objectAtIndex: 0];
        if (path) {
            NSError *error = nil;
            NSURL   *url = [NSURL fileURLWithPath: path];
            [[NSWorkspace sharedWorkspace] launchApplicationAtURL: url
                                                          options: (NSWorkspaceLaunchNewInstance)
                                                    configuration: [NSDictionary new]
                                                            error: &error];
            if (error != nil) {
                [[NSAlert alertWithError: error] runModal];
            }
        }
    }

    [MessageLog.log cleanUp];
    LogLeave;
}

- (void)autoSyncTimerEvent: (NSTimer *)theTimer {
    [self syncAllAccounts];
}

- (BOOL)checkForUnhandledTransfersAndSend {
    LogEnter;

    // Check for a new transfer not yet finished.
    if ([transfersController editingInProgress]) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP109", nil),
                                  NSLocalizedString(@"AP431", nil),
                                  NSLocalizedString(@"AP411", nil),
                                  NSLocalizedString(@"AP412", nil),
                                  nil
                                  );
        if (res == NSAlertAlternateReturn) {
            sidebar.selectedIndex = 7;
            return NO;
        }
        [transfersController cancelEditing];
    }

    // Check for unsent transfers.
    NSError             *error = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"Transfer" inManagedObjectContext: managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isSent = NO"];
    [request setPredicate: predicate];
    NSArray *transfers = [managedObjectContext executeFetchRequest: request error: &error];
    if (error || [transfers count] == 0) {
        return YES;
    }

    int res = NSRunAlertPanel(NSLocalizedString(@"AP109", nil),
                              NSLocalizedString(@"AP430", nil),
                              NSLocalizedString(@"AP7", nil),
                              NSLocalizedString(@"AP412", nil),
                              NSLocalizedString(@"AP432", nil),
                              nil
                              );
    if (res == NSAlertDefaultReturn) {
        return YES;
    }
    if (res == NSAlertAlternateReturn) {
        sidebar.selectedIndex = 7;
        return NO;
    }

    // send transfers
    [[HBCIBackend backend] sendTransfers: transfers];
    [self save];

    LogLeave;

    return NO;
}

- (void)updateUnread {
    LogEnter;

    NSTableColumn *tc = [accountsView tableColumnWithIdentifier: @"name"];
    if (tc) {
        ImageAndTextCell *cell = (ImageAndTextCell *)[tc dataCell];
        [cell setMaxUnread: BankAccount.maxUnread];
    }

    [dockIconController updateBadge];
    [accountsView setNeedsDisplay: YES];

    LogLeave;
}

- (BOOL)application: (NSApplication *)theApplication openFile: (NSString *)filename {
    LogEnter;

    [[MOAssistant sharedAssistant] initDatafile: filename];

    LogLeave;

    return YES;
}

- (void)startRefreshAnimation {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath: @"transform.rotation"];
    animation.fromValue = @0;
    animation.toValue = @M_PI;
    [animation setDuration: 0.5];
    [animation setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear]];
    [animation setRepeatCount: 20000];

    CGRect layerFrame = refreshButton.layer.frame;
    CGPoint center = CGPointMake(CGRectGetMidX(layerFrame), CGRectGetMidY(layerFrame));
    refreshButton.layer.position = center;
    refreshButton.layer.anchorPoint = CGPointMake(0.50, 0.48);
    [refreshButton.layer addAnimation: animation forKey: @"transform.rotation"];
    [CATransaction flush];
}

- (void)stopRefreshAnimation {
    [refreshButton.layer removeAllAnimations];
}

/**
 * Creates the selection image for the side bar and adds buttons for different actions.
 */
- (void)setupSidebar {
    // First create selection image.
    NSInteger imageWidth = 12;
    NSInteger imageHeight = 22;
    NSImage   *selectionImage = [[NSImage alloc] initWithSize: NSMakeSize(imageWidth, imageHeight)];

    [selectionImage lockFocus];

    NSBezierPath *triangle = [NSBezierPath bezierPath];
    [triangle setLineWidth: 1.0];
    [triangle moveToPoint: NSMakePoint(imageWidth + 1, 0.0)];
    [triangle lineToPoint: NSMakePoint(0, imageHeight / 2.0)];
    [triangle lineToPoint: NSMakePoint(imageWidth + 1, imageHeight)];
    [triangle closePath];
    [[NSColor colorWithCalibratedWhite: 0.5 alpha: 1.000] setFill];
    [[NSColor darkGrayColor] setStroke];
    [triangle fill];
    [triangle stroke];

    [selectionImage unlockFocus];

    sidebar.layoutMode = ECSideBarLayoutCenter;
    sidebar.animateSelection = YES;
    sidebar.sidebarDelegate = self;
    sidebar.selectionImage = selectionImage;

    [sidebar addButtonWithTitle: NSLocalizedString(@"AP25", nil)
                          image: [NSImage imageNamed: @"home-active"]
                 alternateImage: [NSImage imageNamed: @"home"]];

    [sidebar addButtonWithTitle: NSLocalizedString(@"AP26", nil)
                          image: [NSImage imageNamed: @"overview-active"]
                 alternateImage: [NSImage imageNamed: @"overview"]];
    [sidebar addButtonWithTitle: NSLocalizedString(@"AP27", nil)
                          image: [NSImage imageNamed: @"graph3-active"]
                 alternateImage: [NSImage imageNamed: @"graph3"]];
    [sidebar addButtonWithTitle: NSLocalizedString(@"AP28", nil)
                          image: [NSImage imageNamed: @"distribution-active"]
                 alternateImage: [NSImage imageNamed: @"distribution"]];
    [sidebar addButtonWithTitle: NSLocalizedString(@"AP29", nil)
                          image: [NSImage imageNamed: @"graph4-active"]
                 alternateImage: [NSImage imageNamed: @"graph4"]];
    [sidebar addButtonWithTitle: NSLocalizedString(@"AP30", nil)
                          image: [NSImage imageNamed: @"table-active"]
                 alternateImage: [NSImage imageNamed: @"table"]];
    [sidebar addButtonWithTitle: NSLocalizedString(@"AP31", nil)
                          image: [NSImage imageNamed: @"assign-active"]
                 alternateImage: [NSImage imageNamed: @"assign"]];

    [sidebar addButtonWithTitle: NSLocalizedString(@"AP32", nil)
                          image: [NSImage imageNamed: @"send2-active"]
                 alternateImage: [NSImage imageNamed: @"send2"]];
    [sidebar addButtonWithTitle: NSLocalizedString(@"AP33", nil)
                          image: [NSImage imageNamed: @"send3-active"]
                 alternateImage: [NSImage imageNamed: @"send3"]];

    NSFont *font = [PreferenceController mainFontOfSize: 11 bold: NO];
    if (font != nil) {
        for (NSUInteger i = 0; i < sidebar.buttonCount; ++i) {
            id                        cell = [sidebar cellForItem: i];
            NSMutableAttributedString *title = [[cell attributedTitle] mutableCopy];
            [title addAttribute: NSFontAttributeName value: font range: NSMakeRange(0, title.length)];
            [cell setAttributedTitle: title];
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context {
    if ([keyPath isEqualToString: @"isComTraceActive"]) {
        if (MessageLog.log.isComTraceActive) {
            comTraceMenuItem.title = NSLocalizedString(@"AP223", nil);
        } else {
            comTraceMenuItem.title = NSLocalizedString(@"AP222", nil);
        }
        return;
    }

    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"showHiddenCategories"]) {
            [categoryController prepareContent];
            return;
        }

        if ([keyPath isEqualToString: @"showPreliminaryStatements"]) {
            if (currentSection != nil) {
                // Update the reported assignments list.
                BankingCategory *category = self.currentSelection;
                [category invalidateCacheIncludeParents: YES recursive: YES];
                [category updateAssignmentsForReportRange];
                currentSection.selectedCategory = category;

                // The not-assigned category can also include preliminary statements (other categories can not, because
                // we don't allow assigning preliminary statements to them). This requires to update the nass root
                // and it's parent, the category root.
                [BankingCategory.nassRoot invalidateCacheIncludeParents: NO recursive: NO];
                [BankingCategory.nassRoot updateAssignmentsForReportRange];
                [BankingCategory.catRoot invalidateCacheIncludeParents: NO recursive: NO];
                [BankingCategory.catRoot updateAssignmentsForReportRange];

                return;
            }
        }

        if ([keyPath isEqualToString: @"fontScale"]) {
            [accountsScrollView setNeedsDisplay: YES];
            NSFont *font = [PreferenceController mainFontOfSize: 13 bold: NO];

            NSTableColumn *tableColumn = [accountsView tableColumnWithIdentifier: @"name"];
            if (tableColumn) {
                [tableColumn.dataCell setFont: font];
            }
            accountsView.rowHeight = floor(font.pointSize) + 8;

            font = [PreferenceController mainFontOfSize: 11 bold: NO];
            for (NSUInteger i = 0; i < sidebar.buttonCount; ++i) {
                id                        cell = [sidebar cellForItem: i];
                NSMutableAttributedString *title = [[cell attributedTitle] mutableCopy];
                [title addAttribute: NSFontAttributeName value: font range: NSMakeRange(0, title.length)];
                [cell setAttributedTitle: title];
            }
            return;
        }

        if ([keyPath isEqualToString: @"autoCasing"] && !autoCasingUpdateRunning) {
            autoCasingUpdateRunning = YES;
            if ([NSUserDefaults.standardUserDefaults boolForKey: @"autoCasing"]) {
                // User switched auto casing on. Start downloading the word data file
                // if it needs to be updated.
                if ([RemoteResourceManager.sharedManager fileNeedsUpdate: @"words.zip"]) {
                    NSAlert *alert = [NSAlert new];
                    alert.alertStyle = NSWarningAlertStyle;
                    alert.messageText = NSLocalizedString(@"AP1700", nil);
                    alert.informativeText = NSLocalizedString(@"AP1704", nil);
                    [alert addButtonWithTitle: NSLocalizedString(@"AP1705", nil)];
                    [alert addButtonWithTitle: NSLocalizedString(@"AP1706", nil)];
                    [alert beginSheetModalForWindow: mainWindow completionHandler: ^(NSModalResponse returnCode) {
                        if (returnCode == NSAlertFirstButtonReturn) {
                            [RemoteResourceManager.sharedManager addManagedFile: @"words.zip"];
                        } else {
                            [NSUserDefaults.standardUserDefaults setBool: NO forKey: @"autoCasing"];
                        }
                    }];
                } else {
                    [RemoteResourceManager.sharedManager addManagedFile: @"words.zip"];
                }
            } else {
                // User switched off auto casing. Ask for deleting data.
                if ([WordMapping wordMappingsAvailable]) {
                    NSAlert *alert = [NSAlert new];
                    alert.alertStyle = NSWarningAlertStyle;
                    alert.messageText = NSLocalizedString(@"AP1700", nil);
                    alert.informativeText = NSLocalizedString(@"AP1701", nil);
                    [alert addButtonWithTitle: NSLocalizedString(@"AP1703", nil)];
                    [alert addButtonWithTitle: NSLocalizedString(@"AP1702", nil)];
                    [alert beginSheetModalForWindow: mainWindow completionHandler: ^(NSModalResponse returnCode) {
                        if (returnCode == NSAlertSecondButtonReturn) {
                            [RemoteResourceManager.sharedManager removeManagedFile: @"words.zip"];
                            [WordMapping removeWordMappings];
                        }
                    }];
                }
            }
            autoCasingUpdateRunning = NO;
            return;
        }

        return;
    }

    if (object == categoryController) {
        [accountsView setNeedsDisplay: YES];
        return;
    }

    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

#pragma mark - Developer tools

- (IBAction)deleteAllData: (id)sender {
    LogEnter;

    int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP114", nil),
                                      NSLocalizedString(@"AP115", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      nil
                                      );
    if (res != NSAlertAlternateReturn) {
        return;
    }

    [MOAssistant.sharedAssistant clearAllData];
    [BankingCategory recreateRoots];

    LogLeave;
}

- (IBAction)generateData: (id)sender {
    LogEnter;

    GenerateDataController *generator = [[GenerateDataController alloc] init];
    [NSApp runModalForWindow: generator.window];

    LogLeave;
}

#pragma mark - Other stuff

- (IBAction)creditCardSettlements: (id)sender {
    LogEnter;

    BankAccount *account = [self selectedBankAccount];
    if (account == nil) {
        return;
    }

    CreditCardSettlementController *controller = [[CreditCardSettlementController alloc] init];
    controller.account = account;

    [NSApp runModalForWindow: [controller window]];

    LogLeave;
}

- (IBAction)accountStatements: (id)sender {
    LogEnter;

    BankAccount *account = [self selectedBankAccount];
    if (account == nil) {
        return;
    }

    AccountStatementsController *controller = [[AccountStatementsController alloc] init];
    controller.account = account;

    [NSApp runModalForWindow: [controller window]];

    LogLeave;
}

- (void)migrate {
    LogEnter;

    LocalSettingsController *settings = LocalSettingsController.sharedSettings;
    NSManagedObjectContext  *context = MOAssistant.sharedAssistant.context;

    BOOL migrated112 = [settings boolForKey: @"Migrated112"];
    if (!migrated112) {
        NSError *error = nil;

        NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement"
                                                             inManagedObjectContext: context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity: entityDescription];
        NSArray *statements = [context executeFetchRequest: request error: &error];
        if (statements.count > 0) {
            NSRunAlertPanel(NSLocalizedString(@"AP150", nil),
                            NSLocalizedString(@"AP178", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil, nil
                            );

            for (BankStatement *stat in statements) {
                @try {
                    [stat extractSEPADataUsingContext: context];
                }
                @catch (NSException *exception) {
                    NSLog(@"Exception inside SEPA data extract for purpose %@", stat.purpose);
                }
            }
        }
        settings[@"Migrated112"] = @YES;
    }

    if (![settings boolForKey: @"Migrated121"]) {

        // Update plugin settings accounts.
        for (BankUser *user in BankUser.allUsers) {
            for (BankAccount *account in user.accounts) {
                if (account.plugin.length == 0) {
                    account.plugin = [PluginRegistry pluginForAccount: account.accountNumber bankCode: account.bankCode];
                    if (account.plugin.length == 0) {
                        account.plugin = @"hbci";
                    }
                }
            }
        }

        settings[@"Migrated121"] = @YES;
    }
    
    // check for users that are not converted to HBCI4Swift yet
    BOOL migrationMessageSent = false;
    for (BankUser *user in BankUser.allUsers) {
        if (user.sysId == nil || user.hbciParameters == nil) {
            if (!migrationMessageSent) {
                NSRunAlertPanel(NSLocalizedString(@"AP150", nil),
                                NSLocalizedString(@"AP203", nil),
                                NSLocalizedString(@"AP1", nil),
                                nil, nil
                                );
                migrationMessageSent = true;
            }
            
            // Synchronize user
            NSError *error = [HBCIBackend.backend syncBankUser:user];
            if (error != nil) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
            }
        }
    }
    
    LogLeave;
}

- (BOOL)save {
    LogEnter;

    NSError *error = nil;

    // save updates
    if (![managedObjectContext save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return NO;
    }

    LogLeave;

    return YES;
}

+ (BankingController *)controller {
    return bankinControllerInstance;
}

@end
