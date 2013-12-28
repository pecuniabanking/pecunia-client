/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

#import "BankingController+Tabs.h" // Includes BankingController.h

#import "NewBankUserController.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "PreferenceController.h"
#import "LocalSettingsController.h"
#import "MOAssistant.h"

#import "LogController.h"
#import "ExportController.h"
#import "AccountDefController.h"
#import "TimeSliceManager.h"
#import "MCEMTreeController.h"
#import "MCEMDecimalNumberAdditions.h" // TODO: Removal candidate
#import "WorkerThread.h"
#import "BSSelectWindowController.h"
#import "StatusBarController.h"
#import "DonationMessageController.h"
#import "BankQueryResult.h"
#import "CategoryView.h"
#import "HBCIClient.h"
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
#include "ColorPopup.h"
#import "PecuniaSplitView.h"
#import "SynchronousScrollView.h"

#import "NSColor+PecuniaAdditions.h"
#import "NSDictionary+PecuniaAdditions.h"
#import "NSOutlineView+PecuniaAdditions.h"
#import "BWGradientBox.h"
#import "EDSideBar.h"
#import "INAppStoreWindow.h"

#import "Tag.h"
#import "User.h"
#import "AssignmentController.h"

// Pasteboard data types.
NSString *const BankStatementDataType = @"BankStatementDataType";
NSString *const CategoryDataType = @"CategoryDataType";

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
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectModel   *model;
    NewBankUserController  *bankUserController;
    LogController          *logController;
    DockIconController     *dockIconController;

    BOOL restart;
    BOOL requestRunning;
    BOOL statementsBound;
    BOOL autoSyncRunning;

    NSCursor *splitCursor;
    NSImage  *moneyImage;
    NSImage  *moneySyncImage;
    NSImage  *bankImage;

    NSMutableArray *bankAccountItemsExpandState;
    Category       *lastSelection;

    NSInteger currentPage; // Current main page.
    NSInteger currentSectionIndex; // Current page on the accounts main page.

    id<PecuniaSectionItem> currentSection;

    NSArray *defaultIcons; // Associations between categories and their default icons.
}
@end

@implementation BankingController

@synthesize managedObjectContext;
@synthesize dockIconController;
@synthesize shuttingDown;
@synthesize accountsView;

#pragma mark - Initialization

- (id)init
{
    LOG_ENTER;

    self = [super init];
    if (self != nil) {

        bankinControllerInstance = self;
        restart = NO;
        requestRunning = NO;
        mainTabItems = [NSMutableDictionary dictionaryWithCapacity: 10];
        currentPage = -1;
        currentSectionIndex = -1;

        @try {
            HBCIClient *client = [HBCIClient hbciClient];
            PecuniaError *error = [client initalizeHBCI];
            if (error != nil) {
                [error alertPanel];
                [NSApp terminate: self];
            }
        }
        @catch (NSError *error) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            [NSApp terminate: self];
        }
        logController = [LogController logController];
    }

    LOG_LEAVE;

    return self;
}

- (void)dealloc
{
    LOG_ENTER;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"showHiddenCategories"];
    [userDefaults removeObserver: self forKeyPath: @"colors"];

    LOG_LEAVE;
}

- (void)setNumberFormatForCell: (NSCell *)cell positive: (NSDictionary *)positive
                      negative: (NSDictionary *)negative
{
    LOG_ENTER;
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

    LOG_LEAVE;
}

- (void)awakeFromNib
{
#ifdef DEBUG
    MessageLog.log.forceConsole = YES;
    MessageLog.log.currentLevel = LogLevel_Debug;
#else
    MessageLog.log.currentLevel = LogLevel_Info;
#endif

    LOG_ENTER;

    mainWindow.centerFullScreenButton = NO;
    mainWindow.titleBarHeight = 40.0;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults addObserver: self forKeyPath: @"showHiddenCategories" options: 0 context: UserDefaultsBindingContext];

    int lastSplitterPosition = [[userDefaults objectForKey: @"rightSplitterPosition"] intValue];
    if (lastSplitterPosition > 0) {
        [toggleDetailsButton setImage: [NSImage imageNamed: @"show"]];
    }
    self.toggleDetailsPaneItem.state = lastSplitterPosition > 0 ? NSOffState : NSOnState;

    [self setupSidebar];

    // Edit accounts/categories when double clicking on a node.
    [accountsView setDoubleAction: @selector(changeAccount:)];
    [accountsView setTarget: self];

    NSTableColumn *tableColumn = [accountsView tableColumnWithIdentifier: @"name"];
    if (tableColumn) {
        ImageAndTextCell *cell = (ImageAndTextCell *)[tableColumn dataCell];
        if (cell) {
            [cell setFont: [NSFont fontWithName: PreferenceController.mainFontName size: 13]];

            // update unread information
            NSInteger maxUnread = [BankAccount maxUnread];
            [cell setMaxUnread: maxUnread];
        }
    }

    // Status bar.
    [mainWindow setAutorecalculatesContentBorderThickness: NO forEdge: NSMinYEdge];
    [mainWindow setContentBorderThickness: 30.0f forEdge: NSMinYEdge];

    // Register drag'n drop types.
    [accountsView registerForDraggedTypes: @[BankStatementDataType, CategoryDataType]];

    // Set a number of images that use a collection (and hence are are not automatically found).
    NSString *path = [[NSBundle mainBundle] pathForResource: @"icon72-1"
                                                     ofType: @"icns"
                                                inDirectory: @"Collections/1"];
    if ([NSFileManager.defaultManager fileExistsAtPath: path]) {
        lockImage.image = [[NSImage alloc] initWithContentsOfFile: path];
    }

    // Update encryption image.
    [self encryptionChanged];

    splitCursor = [[NSCursor alloc] initWithImage: [NSImage imageNamed: @"split-cursor"] hotSpot: NSMakePoint(0, 0)];
    [WorkerThread init];

    [categoryController addObserver: self forKeyPath: @"arrangedObjects.catSum" options: 0 context: nil];

    MOAssistant.assistant.mainContentView = [mainWindow contentView];

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

#ifdef DEBUG
    [developerMenu setHidden: NO];
#endif

    // TODO: without this short start the animation is not correct when used during enqeueRequest.
    //       Investigate why the button image is shifted then until reloaded (e.g. for backing store changes).
    [self startRefreshAnimation];
    [self stopRefreshAnimation];

    LOG_LEAVE;
}

/**
 * Sets a number of settings to useful defaults.
 */
- (void)setDefaultUserSettings
{
    LOG_ENTER;

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
        Category *strongest;
        Category *weakest;
        for (Category *bank in Category.bankRoot.children) {
            for (Category *account in bank.allCategories) {
                if (strongest == nil) {
                    strongest = account;
                    weakest = account;
                    continue;
                }

                switch ([strongest.catSum compare: account.catSum])
                {
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

                switch ([weakest.catSum compare: account.catSum])
                {
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
        [defaults setBool: YES forKey: @"autoCasing"];
    }

    // Migrate the migration flag to the local settings if a migration was done.
    // This must be a per-datafile setting, not a default setting.
    if (settings[@"Migrated10"] == nil) {
        BOOL migrated10 = [defaults boolForKey: @"Migrated10"];
        if (migrated10) {
            settings[@"Migrated10"] = @YES;
        }
    }
    LOG_LEAVE;
}

- (void)publishContext
{
    LOG_ENTER;

    NSError *error = nil;

    categoryController.managedObjectContext = self.managedObjectContext;
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES];
    [categoryController setSortDescriptors: @[sd]];

    // repair Category Root
    [self repairCategories];

    [self setHBCIAccounts];

    [self updateBalances];

    // update unread information
    [self updateUnread];

    [timeSlicer updateDelegate];
    [categoryController fetchWithRequest: nil merge: NO error: &error];
    [accountsView restoreState];
    dockIconController = [[DockIconController alloc] initWithManagedObjectContext: self.managedObjectContext];

    LOG_LEAVE;
}

- (void)contextChanged
{
    LOG_ENTER;

    self.managedObjectContext = [[MOAssistant assistant] context];
    [self publishContext];

    LOG_LEAVE;
}

- (void)encryptionChanged
{
    LOG_ENTER;

    [lockImage setHidden: !MOAssistant.assistant.encrypted];

    LOG_LEAVE;
}

#pragma mark - User actions

- (void)homeScreenCardClicked: (NSNotification *)notification
{
    LOG_ENTER;

    id object = notification.object;
    if ([object isKindOfClass: Category.class]) {
        [categoryController setSelectedObject: object];
        [self switchMainPage: 1];
        [self switchToAccountPage: 1];
    }

    LOG_LEAVE;
}

- (void)setHBCIAccounts
{
    LOG_ENTER;

    NSError             *error = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"accountNumber != nil AND userId != nil"];
    [request setPredicate: predicate];
    NSArray *accounts = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || accounts == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];

        LOG_LEAVE;
        return;
    }
    PecuniaError *pecError = [[HBCIClient hbciClient] setAccounts: accounts];
    if (pecError) {
        [pecError alertPanel];
    }

    LOG_LEAVE;
}

- (NSIndexPath *)indexPathForCategory: (Category *)cat inArray: (NSArray *)nodes
{
    LOG_ENTER;

    NSUInteger idx = 0;
    for (NSTreeNode *node in nodes) {
        Category *obj = [node representedObject];
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

    LOG_LEAVE;

    return nil;
}

- (void)removeBankAccount: (BankAccount *)bankAccount keepAssignedStatements: (BOOL)keepAssignedStats
{
    LOG_ENTER;

    NSSet         *stats = [bankAccount mutableSetValueForKey: @"statements"];
    NSEnumerator  *enumerator = [stats objectEnumerator];
    BankStatement *statement;
    int           i;
    BOOL          removeParent = NO;

    //  Delete bank statements which are not assigned first
    while ((statement = [enumerator nextObject])) {
        if (keepAssignedStats == NO) {
            [self.managedObjectContext deleteObject: statement];
        } else {
            NSSet *assignments = [statement mutableSetValueForKey: @"assignments"];
            if ([assignments count] < 2) {
                [self.managedObjectContext deleteObject: statement];
            } else if ([assignments count] == 2) {
                // delete statement if not assigned yet
                if ([statement hasAssignment] == NO) {
                    [self.managedObjectContext deleteObject: statement];
                }
            } else {
                statement.account = nil;
            }
        }
    }

    [self.managedObjectContext processPendingChanges];
    [[Category nassRoot] invalidateBalance];
    [Category updateBalancesAndSums];

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
    for (i = [path length] - 1; i >= 0; i--) {
        newPath = [newPath indexPathByAddingIndex: [path indexAtPosition: i]];
    }
    [categoryController removeObjectAtArrangedObjectIndexPath: newPath];
    if (removeParent) {
        newPath = [newPath indexPathByRemovingLastIndex];
        [categoryController removeObjectAtArrangedObjectIndexPath: newPath];
    }
    [[Category bankRoot] updateCategorySums];

    LOG_LEAVE;
}

- (BOOL)cleanupBankNodes
{
    LOG_ENTER;

    BOOL flg_changed = NO;
    // remove empty bank nodes
    Category *root = [Category bankRoot];
    if (root != nil) {
        NSArray *bankNodes = [[root mutableSetValueForKey: @"children"] allObjects];
        for (BankAccount *node in bankNodes) {
            NSMutableSet *childs = [node mutableSetValueForKey: @"children"];
            if (childs == nil || [childs count] == 0) {
                [self.managedObjectContext deleteObject: node];
                flg_changed = YES;
            }
        }
    }

    LOG_LEAVE;

    return flg_changed;
}

- (Category *)getBankingRoot
{
    LOG_ENTER;

    NSError        *error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getBankingRoot"];
    NSArray        *cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }
    if ([cats count] > 0) {
        return cats[0];
    }

    // create Root object
    Category *obj = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                  inManagedObjectContext: self.managedObjectContext];
    [obj setValue: @"++bankroot" forKey: @"name"];
    [obj setValue: @YES forKey: @"isBankAcc"];

    LOG_LEAVE;

    return obj;
}

// XXX: is this still required? Looks like a fix for a previous bug.
- (void)repairCategories
{
    LOG_ENTER;

    NSError  *error = nil;
    Category *catRoot;
    BOOL     found = NO;

    // repair bank root
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getBankingRoot"];
    NSArray        *cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    for (Category *cat in cats) {
        NSString *n = [cat primitiveValueForKey: @"name"];
        if (![n isEqualToString: @"++bankroot"]) {
            [cat setValue: @"++bankroot" forKey: @"name"];
            break;
        }
    }
    // repair categories
    request = [model fetchRequestTemplateForName: @"getCategoryRoot"];
    cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    for (Category *cat in cats) {
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
        Category *obj = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                      inManagedObjectContext: self.managedObjectContext];
        [obj setValue: @"++catroot" forKey: @"name"];
        [obj setValue: @NO forKey: @"isBankAcc"];
        catRoot = obj;
    }

    // reassign categories
    for (Category *cat in cats) {
        if (cat == catRoot) {
            continue;
        }
        if ([cat valueForKey: @"parent"] == nil) {
            [cat setValue: catRoot forKey: @"parent"];
        }
    }
    // insert not assigned node
    request = [model fetchRequestTemplateForName: @"getNassRoot"];
    cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    if ([cats count] == 0) {
        Category *obj = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                      inManagedObjectContext: self.managedObjectContext];
        [obj setPrimitiveValue: @"++nassroot" forKey: @"name"];
        [obj setValue: @NO forKey: @"isBankAcc"];
        [obj setValue: catRoot forKey: @"parent"];

        [self updateNotAssignedCategory];
    }

    [self save];

    LOG_LEAVE;
}

- (void)updateBalances
{
    LOG_ENTER;

    NSError *error = nil;

    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getRootNodes"];
    NSArray        *cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    for (Category *cat in cats) {
        if (!cat.isBankingRoot) {
            [cat recomputeInvalidBalances];
        }
        [cat updateCategorySums];
    }

    [self save];

    LOG_LEAVE;
}

- (IBAction)enqueueRequest: (id)sender
{
    LOG_ENTER;

    NSMutableArray *selectedAccounts = [NSMutableArray arrayWithCapacity: 10];
    NSArray        *selectedNodes = nil;
    Category       *cat;
    NSError        *error = nil;

    cat = [self currentSelection];
    if (cat == nil) {
        return;
    }

    [self startRefreshAnimation];

    // one bank account selected
    if (cat.accountNumber != nil) {
        [selectedAccounts addObject: cat];
    } else {
        // a node was selected
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: self.managedObjectContext];
        NSFetchRequest      *request = [[NSFetchRequest alloc] init];
        [request setEntity: entityDescription];
        if (cat.parent == nil) {
            // root was selected
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@", cat];
            [request setPredicate: predicate];
            selectedNodes = [self.managedObjectContext executeFetchRequest: request error: &error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }
        } else {
            // a node was selected
            selectedNodes = @[cat];
        }
        // now select accounts from nodes
        BankAccount *account;
        for (account in selectedNodes) {
            NSArray     *result;
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@ AND noAutomaticQuery == 0", account];
            [request setPredicate: predicate];
            result = [self.managedObjectContext executeFetchRequest: request error: &error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }
            [selectedAccounts addObjectsFromArray: result];
        }
    }
    if ([selectedAccounts count] == 0) {
        return;
    }

    // check if at least one Account is assigned to a user
    NSUInteger  nInactive = 0;
    BankAccount *account;
    for (account in selectedAccounts) {
        if (account.userId == nil && ([account.isManual boolValue] == NO)) {
            nInactive++;
        }
    }
    if (nInactive == [selectedAccounts count]) {
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

    // now selectedAccounts has all selected Bank Accounts
    NSMutableArray *resultList = [NSMutableArray arrayWithCapacity: [selectedAccounts count]];
    for (account in selectedAccounts) {
        if (account.userId) {
            BankQueryResult *result = [[BankQueryResult alloc] init];
            result.accountNumber = account.accountNumber;
            result.accountSubnumber = account.accountSuffix;
            result.bankCode = account.bankCode;
            result.userId = account.userId;
            result.account = account;
            [resultList addObject: result];
        }
    }
    // show log if wanted
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           showLog = [defaults boolForKey: @"logForBankQuery"];
    if (showLog) {
        [logController showWindow: self];
        [[logController window] orderFront: self];
    }

    // prepare UI
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: NO];
    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP219", nil) removeAfter: 0];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(statementsNotification:)
                                                 name: PecuniaStatementsNotification
                                               object: nil];
    [[HBCIClient hbciClient] getStatements: resultList];

    LOG_LEAVE;
}

- (void)statementsNotification: (NSNotification *)notification
{
    LOG_ENTER;

    BankQueryResult     *result;
    StatusBarController *sc = [StatusBarController controller];
    BOOL                noStatements = YES;
    BOOL                isImport = NO;
    int                 count = 0;

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: PecuniaStatementsNotification
                                                  object: nil];

    NSArray *resultList = [notification object];
    if (resultList == nil) {
        [sc stopSpinning];
        [sc clearMessage];
        requestRunning = NO;
        return;
    }

    // get Proposals
    for (result in resultList) {
        NSArray *stats = result.statements;
        if ([stats count] > 0) {
            noStatements = NO;
            [result.account evaluateQueryResult: result];
        }
        if (result.isImport) {
            isImport = YES;
        }
        [result.account updateStandingOrders: result.standingOrders];
    }
    [sc stopSpinning];
    [sc clearMessage];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           check = [defaults boolForKey: @"manualTransactionCheck"];

    if (check && !noStatements) {
        BSSelectWindowController *selectWindowController = [[BSSelectWindowController alloc] initWithResults: resultList];
        [NSApp runModalForWindow: [selectWindowController window]];
    } else {
        @try {
            for (result in resultList) {
                count += [result.account updateFromQueryResult: result];
            }
        }
        @catch (NSException *e) {
            [[MessageLog log] addMessage: e.reason withLevel: LogLevel_Error];
        }
        if (autoSyncRunning) {
            [self checkBalances: resultList];
        }
        [self requestFinished: resultList];

        [sc setMessage: [NSString stringWithFormat: NSLocalizedString(@"AP218", nil), count] removeAfter: 120];
    }
    autoSyncRunning = NO;
    [self.currentSelection updateAssignmentsForReportRange];
    
    // check for updated login data
    for (result in resultList) {
        BankUser *user = [BankUser userWithId:result.userId bankCode:result.bankCode];
        if (user != nil) {
            [user checkForUpdatedLoginData];
        }
    }

    [self save];

    [self stopRefreshAnimation];

    BOOL suppressSound = [NSUserDefaults.standardUserDefaults boolForKey: @"noSoundAfterSync"];
    if (!suppressSound) {
        NSSound *doneSound = [NSSound soundNamed: @"done.mp3"];
        if (doneSound != nil) {
            [doneSound play];
        }
    }

    LOG_LEAVE;
}

- (void)requestFinished: (NSArray *)resultList
{
    LOG_ENTER;

    [self.managedObjectContext processPendingChanges];
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

    LOG_LEAVE;
}

- (void)checkBalances: (NSArray *)resultList
{
    LOG_ENTER;

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

    LOG_LEAVE;
}

- (BOOL)requestRunning
{
    return requestRunning;
}

- (IBAction)editBankUsers: (id)sender
{
    LOG_ENTER;

    if (bankUserController == nil) {
        bankUserController = [[NewBankUserController alloc] initForController: self];
    }

    [[bankUserController window] makeKeyAndOrderFront: self];

    LOG_LEAVE;
}

- (IBAction)editPreferences: (id)sender
{
    [PreferenceController showPreferencesWithOwner: self section: nil];
}

- (IBAction)showLicense: (id)sender
{
    LOG_ENTER;

    NSURL *url = [NSURL URLWithString: @"http://opensource.org/licenses/GPL-2.0"];
    [[NSWorkspace sharedWorkspace] openURL: url];

    LOG_LEAVE;
}

- (IBAction)showConsole:(id)sender
{
    LOG_ENTER;

    [[NSWorkspace sharedWorkspace] launchApplication: @"Console"];

    LOG_LEAVE;
}

- (IBAction)printDocument: (id)sender
{
    LOG_ENTER;

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

    LOG_LEAVE;
}

- (IBAction)accountMaintenance: (id)sender
{
    LOG_ENTER;

    BankAccount *account = nil;
    Category    *cat = [self currentSelection];
    if (cat == nil || cat.accountNumber == nil) {
        return;
    }
    account = (BankAccount *)cat;

    [account doMaintenance];
    [self save];

    LOG_LEAVE;
}

- (IBAction)getAccountBalance: (id)sender
{
    LOG_ENTER;

    PecuniaError *pec_err = nil;
    BankAccount  *account = nil;
    Category     *cat = [self currentSelection];
    if (cat == nil || cat.accountNumber == nil) {
        return;
    }
    account = (BankAccount *)cat;

    pec_err = [[HBCIClient hbciClient] getBalanceForAccount: account];
    if (pec_err) {
        return;
    }

    [self save];

    LOG_LEAVE;
}

- (IBAction)resetIsNewStatements: (id)sender
{
    LOG_ENTER;

    NSError                *error = nil;
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isNew = 1"];
    [request setPredicate: predicate];
    NSArray *statements = [context executeFetchRequest: request error: &error];
    for (BankStatement *stat in statements) {
        stat.isNew = @NO;
    }
    [self save];

    [self updateUnread];
    [accountsView setNeedsDisplay: YES];

    LOG_LEAVE;
}

- (IBAction)showAboutPanel: (id)sender
{
    LOG_ENTER;

    if (aboutWindow == nil) {
        [NSBundle loadNibNamed: @"About" owner: self];

        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *path = [mainBundle pathForResource: @"Credits" ofType: @"rtf"];
        [aboutText readRTFDFromFile: path];
        [versionText setStringValue: [NSString stringWithFormat: @"Version %@ (%@)",
                                      [mainBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                      [mainBundle objectForInfoDictionaryKey: @"CFBundleVersion"]
                                      ]];
        [copyrightText setStringValue: [mainBundle objectForInfoDictionaryKey: @"NSHumanReadableCopyright"]];

        gradient.fillColor = [NSColor whiteColor];
    }
    
    [aboutWindow orderFront: self];
    
    LOG_LEAVE;
}

- (IBAction)toggleFullscreenIfSupported: (id)sender
{
    LOG_ENTER;

    [mainWindow toggleFullScreen: mainWindow];

    LOG_LEAVE;
}

- (IBAction)toggleDetailsPane: (id)sender
{
    LOG_ENTER;

    // Can only be triggered if the overview pane is visible (otherwise the toggle button is hidden).
    if (![(id)currentSection toggleDetailsPane]) {
        [toggleDetailsButton setImage: [NSImage imageNamed: @"show"]];
        self.toggleDetailsPaneItem.state = NSOffState;
    } else {
        [toggleDetailsButton setImage: [NSImage imageNamed: @"hide"]];
        self.toggleDetailsPaneItem.state = NSOnState;
    }

    LOG_LEAVE;
}

- (IBAction)toggleFeature: (id)sender
{
    if (sender == self.toggleDetailsPaneItem) {
        [self toggleDetailsPane: sender];
    }
}

- (void)reapplyDefaultIconsForCategory: (Category *)category
{
    LOG_ENTER;

    for (Category *child in category.children) {
        if ([child.name hasPrefix: @"++"]) {
            continue;
        }
        [self determineDefaultIconForCategory: child];
        [self reapplyDefaultIconsForCategory: child];
    }

    LOG_LEAVE;
}

- (IBAction)resetCategoryIcons: (id)sender
{
    LOG_ENTER;

    int res = NSRunAlertPanel(NSLocalizedString(@"AP301", nil),
                              NSLocalizedString(@"AP302", nil),
                              NSLocalizedString(@"AP4", nil),
                              NSLocalizedString(@"AP3", nil),
                              nil
                              );
    if (res != NSAlertAlternateReturn) {
        return;
    }
    [self reapplyDefaultIconsForCategory: Category.catRoot];
    [accountsView setNeedsDisplay: YES];
    
    LOG_LEAVE;
}

#pragma mark - Account management

- (IBAction)addAccount: (id)sender
{
    LOG_ENTER;

    NSString *bankCode = nil;
    Category *cat = [self currentSelection];
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
        [Category.bankRoot updateCategorySums];
    }

    LOG_LEAVE;
}

- (IBAction)changeAccount: (id)sender
{
    // In order to let KVO selection changes work properly when double clicking a node other than
    // the current one we have to run the modal dialogs after the runloop has finished its round.
    [self performSelector: @selector(doChangeAccount) withObject: nil afterDelay: 0];
}

- (void)doChangeAccount
{
    LOG_ENTER;

    Category *cat = [self currentSelection];
    if (cat == nil) {
        return;
    }

    if (!cat.isBankAccount && cat != Category.nassRoot && cat != Category.catRoot) {
        CategoryMaintenanceController *changeController = [[CategoryMaintenanceController alloc] initWithCategory: cat];
        [NSApp runModalForWindow: [changeController window]];
        [categoryController prepareContent]; // Visibility of a category could have changed.
        [Category.catRoot updateCategorySums]; // Category could have switched its noCatRep property.
        return;
    }

    if (cat.accountNumber != nil) {
        AccountMaintenanceController *changeController = [[AccountMaintenanceController alloc] initWithAccount: (BankAccount *)cat];
        [NSApp runModalForWindow: [changeController window]];
        [categoryController prepareContent];
        [Category.bankRoot updateCategorySums];
    }
    // Changes are stored in the controllers.

    LOG_LEAVE;
}

- (IBAction)deleteAccount: (id)sender
{
    LOG_ENTER;

    Category *cat = [self currentSelection];
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
                } else {keepAssignedStatements = NO; }
            }
        }
    }
    // delete account
    [self removeBankAccount: account keepAssignedStatements: keepAssignedStatements];

    [self save];

    LOG_LEAVE;
}

#pragma mark - Page switching

- (void)updateStatusbar
{
    LOG_ENTER;

    Category  *cat = [self currentSelection];
    ShortDate *fromDate = [timeSlicer lowerBounds];
    ShortDate *toDate = [timeSlicer upperBounds];

    NSInteger turnovers = 0;
    if (currentPage == 1) {
        NSDecimalNumber *turnoversValue = [cat valuesOfType: cat_turnovers from: fromDate to: toDate];
        turnovers = [turnoversValue integerValue];
    }

    if (turnovers > 0) {
        NSDecimalNumber *spendingsValue = [cat valuesOfType: cat_spendings from: fromDate to: toDate];
        NSDecimalNumber *earningsValue = [cat valuesOfType: cat_earnings from: fromDate to: toDate];

        [spendingsField setValue: spendingsValue forKey: @"objectValue"];
        [earningsField setValue: earningsValue forKey: @"objectValue"];
    } else {
        [spendingsField setStringValue: @""];
        [earningsField setStringValue: @""];
    }

    LOG_LEAVE;
}

- (void)updateDetailsPaneButton
{
    toggleDetailsButton.hidden = (currentPage != 1) || (currentSectionIndex != 0);
}

- (IBAction)activateMainPage: (id)sender
{
    [self switchMainPage: [sender selectedSegment]];
}

- (void)switchMainPage: (NSInteger)page
{
    LOG_ENTER;

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
        [self updateDetailsPaneButton];
    }
    LOG_LEAVE;
}

- (void)switchToAccountPage: (NSInteger)sectionIndex
{
    LOG_ENTER;

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
            catActions.hidden = NO;
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
                    if ([NSBundle loadNibNamed: @"StatementsOverview" owner: overviewController]) {
                        NSView *view = [overviewController mainView];
                        view.frame = frame;
                    }
                    [overviewController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
                }

                if (currentSection != overviewController) {
                    [currentSection deactivate];
                    [[overviewController mainView] setFrame: frame];
                    [rightPane replaceSubview: currentView with: [overviewController mainView]];
                    overviewController.toggleDetailsButton = toggleDetailsButton;
                    currentSection = overviewController;

                    pageHasChanged = YES;
                }

                // Update values in category tree to reflect time slicer interval again.
                [timeSlicer updateDelegate];
                break;

            case 1:
                if (categoryAnalysisController == nil) {
                    categoryAnalysisController = [[CategoryAnalysisWindowController alloc] init];
                    if ([NSBundle loadNibNamed: @"CategoryAnalysis" owner: categoryAnalysisController]) {
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
                    if ([NSBundle loadNibNamed: @"CategoryReporting" owner: categoryReportingController]) {
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
                    Category *category = [self currentSelection];
                    if ([[category children] count] < 1) {
                        [categoryController setSelectedObject: category.parent];
                    }
                    pageHasChanged = YES;
                }

                [timeSlicer updateDelegate];
                break;

            case 3:
                [timeSlicer showControls: NO];
                catActions.hidden = YES;

                if (categoryPeriodsController == nil) {
                    categoryPeriodsController = [[CategoryPeriodsWindowController alloc] init];
                    if ([NSBundle loadNibNamed: @"CategoryPeriods" owner: categoryPeriodsController]) {
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
                    if ([NSBundle loadNibNamed: @"CategoryDefinition" owner: categoryDefinitionController]) {
                        NSView *view = [categoryDefinitionController mainView];
                        view.frame = frame;
                    }
                    [categoryDefinitionController setManagedObjectContext: self.managedObjectContext];
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
                    Category *category = [self currentSelection];
                    if ([category isBankAccount]) {
                        [categoryController setSelectedObject: Category.nassRoot];
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
                    if ([NSBundle loadNibNamed: @"CategoryHeatMap" owner: heatMapController]) {
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
        [self updateDetailsPaneButton];
    }

    LOG_LEAVE;
}

#pragma mark - File actions

- (IBAction)export: (id)sender
{
    LOG_ENTER;

    Category *cat;

    cat = [self currentSelection];
    ExportController *controller = [ExportController controller];
    [controller startExport: cat fromDate: [timeSlicer lowerBounds] toDate: [timeSlicer upperBounds]];

    LOG_LEAVE;
}

- (IBAction)import: (id)sender
{
    LOG_ENTER;

    ImportController *controller = [[ImportController alloc] init];
    int              res = [NSApp runModalForWindow: [controller window]];
    if (res == 0) {
        NSArray        *results = @[controller.importResult];
        NSNotification *notification = [NSNotification notificationWithName: PecuniaStatementsNotification object: results];
        [self statementsNotification: notification];
    }

    LOG_LEAVE;
}

- (BOOL)applicationShouldHandleReopen: (NSApplication *)theApplication hasVisibleWindows: (BOOL)flag
{
    LOG_ENTER;

    if (!flag) {
        [mainWindow makeKeyAndOrderFront: self];
    }

    LOG_LEAVE;

    return YES;
}

- (BOOL)canTerminate
{
    LOG_ENTER;

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

    LOG_LEAVE;

    return YES;
}

- (IBAction)showLog: (id)sender
{
    LOG_ENTER;

    [logController showWindow: self];

    LOG_LEAVE;
}

- (BankAccount *)selectedBankAccount
{
    LOG_ENTER;

    Category *cat = [self currentSelection];
    if (cat == nil) {
        return nil;
    }
    if ([cat isMemberOfClass: [Category class]]) {
        return nil;
    }

    NSString *accNumber = [cat valueForKey: @"accountNumber"];
    if (accNumber == nil || [accNumber isEqual: @""]) {
        return nil;
    }

    LOG_LEAVE;

    return (BankAccount *)cat;
}

- (IBAction)transfer_local: (id)sender
{
    LOG_ENTER;

    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeStandard withAccount: account];

    LOG_LEAVE;
}

- (IBAction)donate: (id)sender
{
    LOG_ENTER;

    // check if there are any bank users
    NSArray *users = [BankUser allUsers];
    if (users == nil || users.count == 0) {
        NSRunAlertPanel(NSLocalizedString(@"AP105", nil),
                        NSLocalizedString(@"AP803", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return;
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start transfer editing process.
    [transfersController startDonationTransfer];
}

- (IBAction)transfer_internal: (id)sender
{
    LOG_ENTER;

    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeInternal withAccount: account];

    LOG_LEAVE;
}

- (IBAction)transfer_dated: (id)sender
{
    LOG_ENTER;

    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeDated withAccount: account];

    LOG_LEAVE;
}

- (IBAction)transfer_eu: (id)sender
{
    LOG_ENTER;

    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // check if bic and iban is defined
    if (account != nil) {
        if (account.iban == nil || account.bic == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP101", nil),
                            [NSString stringWithFormat: NSLocalizedString(@"AP77", nil), account.accountNumber],
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return;
        }
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeEU withAccount: account];

    LOG_LEAVE;
}

- (IBAction)transfer_sepa: (id)sender
{
    LOG_ENTER;

    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // check if bic and iban is defined
    if (account != nil) {
        if (account.iban == nil || account.bic == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP101", nil),
                            [NSString stringWithFormat: NSLocalizedString(@"AP77", nil), account.accountNumber],
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return;
        }
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeSEPA withAccount: account];

    LOG_LEAVE;
}

- (Category *)currentSelection
{
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
- (BOOL)outlineView: (NSOutlineView *)outlineView shouldSelectItem: (id)item
{
    if (currentSection != nil) {
        if (currentSection == categoryReportingController) {
            // If category reporting is active then don't allow selecting entries without children.
            return [outlineView isExpandable: item];
        }

        if (currentSection == categoryDefinitionController) {
            Category *category = [item representedObject];
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

- (BOOL)outlineView: (NSOutlineView *)ov writeItems: (NSArray *)items toPasteboard: (NSPasteboard *)pboard
{
    Category *cat;

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
    if (cat == [Category nassRoot]) {
        return NO;
    }
    NSURL  *uri = [[cat objectID] URIRepresentation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uri];
    [pboard declareTypes: @[CategoryDataType] owner: self];
    [pboard setData: data forType: CategoryDataType];
    return YES;
}

- (NSDragOperation)outlineView: (NSOutlineView *)ov validateDrop: (id <NSDraggingInfo>)info proposedItem: (id)item proposedChildIndex: (NSInteger)childIndex
{
    NSPasteboard *pboard = [info draggingPasteboard];

    // This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
    if (childIndex >= 0) {
        return NSDragOperationNone;
    }
    if (item == nil) {
        return NSDragOperationNone;
    }
    Category *cat = (Category *)[item representedObject];
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
        Category        *scat = [self currentSelection];
        if ([cat isRoot]) {
            return NSDragOperationNone;
        }
        // if not yet assigned: move
        if (scat == [Category nassRoot]) {
            return NSDragOperationMove;
        }
        if (mask == NSDragOperationCopy && cat != [Category nassRoot]) {
            return NSDragOperationCopy;
        }
        if (mask == NSDragOperationGeneric && cat != [Category nassRoot]) {
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
        NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
        Category          *scat = (Category *)[self.managedObjectContext objectWithID: moID];
        if ([scat checkMoveToCategory: cat] == NO) {
            return NSDragOperationNone;
        }
        return NSDragOperationMove;
    }
}

- (BOOL)outlineView: (NSOutlineView *)outlineView acceptDrop: (id <NSDraggingInfo>)info item: (id)item childIndex: (NSInteger)childIndex
{
    Category     *targetCategory = (Category *)[item representedObject];
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
            NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
            if (moID == nil) {
                continue;
            }
            StatCatAssignment *assignment = (StatCatAssignment *)[self.managedObjectContext objectWithID: moID];

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
                        
                        AssignmentController *controller = [[AssignmentController alloc] initWithAmount:residual];
                        int res = [NSApp runModalForWindow:controller.window];
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
                    
                    AssignmentController *controller = [[AssignmentController alloc] initWithAmount:amount];
                    int res = [NSApp runModalForWindow:controller.window];
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
        [Category updateBalancesAndSums];

        [self.currentSelection updateAssignmentsForReportRange]; // Update displayed assignments.

        if (needBankRootUpdate) {
            [[Category bankRoot] updateCategorySums];
        }
    } else {
        NSURL             *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
        if (moID == nil) {
            return NO;
        }
        Category *scat = (Category *)[self.managedObjectContext objectWithID: moID];
        [scat setValue: targetCategory forKey: @"parent"];

        [[Category catRoot] updateCategorySums];
    }

    [self save];

    return YES;
}

- (void)outlineViewSelectionDidChange: (NSNotification *)aNotification
{
    if (shuttingDown) {
        return;
    }

    Category *cat = [self currentSelection];

    // set states of categorie Actions Control
    [catActions setEnabled: [cat isRemoveable] forSegment: 2];
    [catActions setEnabled: [cat isInsertable] forSegment: 1];

    // Update current section if the default is not active.
    if (currentSection != nil) {
        currentSection.selectedCategory = cat;
    }
    [self updateStatusbar];
}

- (void)outlineView: (NSOutlineView *)outlineView willDisplayCell: (ImageAndTextCell *)cell
     forTableColumn: (NSTableColumn *)tableColumn item: (id)item
{
    if (![[tableColumn identifier] isEqualToString: @"name"]) {
        return;
    }

    Category *cat = [item representedObject];
    if (cat == nil) {
        return;
    }

    cell.swatchColor = cat.categoryColor;

    if (moneyImage == nil) {
        moneyImage = [NSImage imageNamed: @"money_18.png"];
        moneySyncImage = [NSImage imageNamed: @"money_sync_18.png"];

        NSString *path = [[NSBundle mainBundle] pathForResource: @"icon95-1"
                                                         ofType: @"icns"
                                                    inDirectory: @"Collections/1/"];
        bankImage = [[NSImage alloc] initWithContentsOfFile: path];
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
                    NSDictionary *parameters = [NSDictionary dictionaryForUrlParameters: url];
                    NSString *subfolder = [@"Collections/" stringByAppendingString: parameters[@"c"]];
                    path = [[NSBundle mainBundle] pathForResource: [url.host stringByDeletingPathExtension]
                                                           ofType: url.host.pathExtension
                                                      inDirectory: subfolder];

                } else {
                    if ([url.scheme isEqualToString: @"image"]) { // An image from our data bundle.
                        NSString *targetFolder = [MOAssistant.assistant.pecuniaFileURL.path stringByAppendingString: @"/Images/"];
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

- (CGFloat)outlineView: (NSOutlineView *)outlineView heightOfRowByItem: (id)item
{
    return 22;
}

#pragma mark - Splitview delegate methods

- (CGFloat)splitView: (NSSplitView *)splitView constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainVSplit) {
        return 370;
    }
    return proposedMin;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainVSplit) {
        return NSWidth([mainWindow frame]) - 800;
    }
    return proposedMax;
}

#pragma mark - Sidebar delegate methods

- (void)sideBar: (EDSideBar*)tabBar didSelectButton: (NSInteger)index
{
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

- (BOOL)validateMenuItem: (NSMenuItem *)item
{
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];

    if (idx != 0) {
        if ([item action] == @selector(export:)) {
            return NO;
        }
        if ([item action] == @selector(addAccount:)) {
            return NO;
        }
        if ([item action] == @selector(changeAccount:)) {
            return NO;
        }
        if ([item action] == @selector(deleteAccount:)) {
            return NO;
        }
        if ([item action] == @selector(enqueueRequest:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_local:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_eu:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_sepa:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_dated:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_internal:)) {
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
    }

    if (idx == 0) {
        Category *cat = [self currentSelection];
        if (cat == nil || [cat accountNumber] == nil) {
            if ([item action] == @selector(enqueueRequest:)) {
                return NO;
            }
            if ([item action] == @selector(changeAccount:)) {
                return NO;
            }
            if ([item action] == @selector(deleteAccount:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_local:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_eu:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_sepa:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_dated:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_internal:)) {
                return NO;
            }
            if ([item action] == @selector(addStatement:)) {
                return NO;
            }
            if ([item action] == @selector(creditCardSettlements:)) {
                return NO;
            }
        }
        if ([cat isKindOfClass: [BankAccount class]]) {
            BankAccount *account = (BankAccount *)cat;
            if ([[account isManual] boolValue] == YES) {
                if ([item action] == @selector(transfer_local:)) {
                    return NO;
                }
                if ([item action] == @selector(transfer_eu:)) {
                    return NO;
                }
                if ([item action] == @selector(transfer_sepa:)) {
                    return NO;
                }
                if ([item action] == @selector(transfer_dated:)) {
                    return NO;
                }
                if ([item action] == @selector(transfer_internal:)) {
                    return NO;
                }
                if ([item action] == @selector(creditCardSettlements:)) {
                    return NO;
                }
            } else {
                if ([item action] == @selector(addStatement:)) {
                    return NO;
                }
                if ([item action] == @selector(creditCardSettlements:)) {
                    if ([[HBCIClient hbciClient] isTransactionSupported: TransactionType_CCSettlement forAccount: account] == NO) {
                        return NO;
                    }
                }
            }
        }

        if (requestRunning && [item action] == @selector(enqueueRequest:)) {
            return NO;
        }

        if ([(id)currentSection respondsToSelector: @selector(validateMenuItem:)]) {
            BOOL result = [(id)currentSection validateMenuItem: item];
            if (!result) {
                return NO;
            }
        }
    }
    return YES;
}

#pragma mark - Category management

- (void)updateNotAssignedCategory
{
    LOG_ENTER;

    NSError *error = nil;

    // fetch all bank statements
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: self.managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSArray *stats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    for (BankStatement *stat in stats) {
        [stat updateAssigned];
    }

    [self save];

    LOG_LEAVE;
}

- (void)deleteCategory: (id)sender
{
    LOG_ENTER;

    Category *cat = [self currentSelection];
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
    [Category updateBalancesAndSums];

    // workaround: NSTreeController issue: when an item is removed and the NSOutlineViewSelectionDidChange notification is sent,
    // the selectedObjects: message returns the wrong (the old) selection
    [self performSelector: @selector(outlineViewSelectionDidChange:) withObject: nil afterDelay: 0];

    // Save changes to avoid losing category changes in case of failures/crashs.

    LOG_LEAVE;
    [self save];
}

- (void)addCategory: (id)sender
{
    LOG_ENTER;

    Category *cat = [self currentSelection];
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

    LOG_LEAVE;
}

- (void)insertCategory: (id)sender
{
    LOG_ENTER;

    Category *cat = [self currentSelection];
    if ([cat isInsertable] == NO) {
        return;
    }
    [categoryController addChild: sender];
    [accountsView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];

    [self save];

    LOG_LEAVE;
}

- (IBAction)manageCategories: (id)sender
{
    LOG_ENTER;

    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment: clickedSegment];
    switch (clickedSegmentTag) {
        case 0:[self addCategory: sender]; break;

        case 1:[self insertCategory: sender]; break;

        case 2:[self deleteCategory: sender]; break;

        default: return;
    }
    [currentSection activate]; // Notifies the current section to updates values if necessary.

    LOG_LEAVE;
}

- (NSString *)autosaveNameForTimeSlicer: (TimeSliceManager *)tsm
{
    return @"AccMainTimeSlice";
}

- (void)timeSliceManager: (TimeSliceManager *)tsm changedIntervalFrom: (ShortDate *)from to: (ShortDate *)to
{
    if (self.managedObjectContext == nil) {
        return;
    }
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];
    if (idx) {
        return;
    }
    [Category setCatReportFrom: from to: to];

    // Update current section if the default is not active.
    if (currentSection != nil) {
        [currentSection setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
    }

    [self updateStatusbar];
}

- (void)controlTextDidBeginEditing: (NSNotification *)aNotification
{
    if ([aNotification object] == accountsView) {
        Category *cat = [self currentSelection];
        accountsView.saveCatName = [cat name];
    }
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    // Category name changed
    if ([aNotification object] == accountsView) {
        Category *cat = [self currentSelection];
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

- (void)setRestart
{
    restart = YES;
}

- (IBAction)deleteStatement: (id)sender
{
    LOG_ENTER;

    // This function is only called if the associated menu item is enabled, which is only the case
    // if (amongst other) the current section is the statements overview.
    if (!self.currentSelection.isBankAcc.boolValue) {
        return;
    }

    [(id)currentSection deleteSelectedStatements];

    [self save];

    LOG_LEAVE;
}

- (void)splitStatement: (id)sender
{
    LOG_ENTER;

    // This function is only called if the associated menu item is enabled, which is only the case
    // if (amongst others) the current section is the statements overview.
    [(id)currentSection splitSelectedStatement];

    LOG_LEAVE;
}

- (IBAction)addStatement: (id)sender
{
    LOG_ENTER;

    Category *cat = [self currentSelection];
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

    LOG_LEAVE;
}

- (IBAction)splitPurpose: (id)sender
{
    LOG_ENTER;

    Category *cat = [self currentSelection];

    PurposeSplitController *splitController = [[PurposeSplitController alloc] initWithAccount: (BankAccount *)cat];
    [NSApp runModalForWindow: [splitController window]];

    LOG_LEAVE;
}

/**
 * Takes the (localized) title of the given category and determines an icon for it from the default collection.
 */
- (void)determineDefaultIconForCategory: (Category *)category
{
    if (defaultIcons == nil) {
        NSMutableArray *entries = [NSMutableArray arrayWithCapacity: 100];

        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *path = [mainBundle pathForResource: @"category-icon-defaults" ofType: @"txt"];
        NSError  *error = nil;
        NSString *s = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
        if (error) {
            NSLog(@"Error reading default category icon assignments file at %@\n%@", path, [error localizedFailureReason]);
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
                NSDictionary *entry = @{@"icon": icon, @"keywords": keywords};
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
- (void)saveBankAccountItemsStates
{
    LOG_ENTER;

    Category *category = [self currentSelection];
    if ([category isBankAccount]) {
        lastSelection = category;
        [categoryController setSelectedObject: Category.nassRoot];
    }
    bankAccountItemsExpandState = [NSMutableArray array];
    NSUInteger row, numberOfRows = [accountsView numberOfRows];

    for (row = 0; row < numberOfRows; row++) {
        id       item = [accountsView itemAtRow: row];
        Category *category = [item representedObject];
        if (![category isBankAccount]) {
            break;
        }
        if ([accountsView isItemExpanded: item]) {
            [bankAccountItemsExpandState addObject: category];
        }
    }

    LOG_LEAVE;
}

/**
 * Restores the previously saved expand states of all bank account nodes and sets the
 * last selection if it was on a bank account node.
 */
- (void)restoreBankAccountItemsStates
{
    LOG_ENTER;

    NSUInteger row, numberOfRows = [accountsView numberOfRows];
    for (Category *savedItem in bankAccountItemsExpandState) {
        for (row = 0; row < numberOfRows; row++) {
            id       item = [accountsView itemAtRow: row];
            Category *object = [item representedObject];
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

    LOG_LEAVE;
}

- (void)syncAllAccounts
{
    LOG_ENTER;

    NSError        *error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"allBankAccounts"];
    NSArray        *selectedAccounts = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error) {
        NSLog(@"Read bank accounts error on automatic sync");
        return;
    }

    [self startRefreshAnimation];

    // Now selectedAccounts has all selected Bank Accounts.
    BankAccount    *account;
    NSMutableArray *resultList = [NSMutableArray arrayWithCapacity: [selectedAccounts count]];
    for (account in selectedAccounts) {
        if ([account.noAutomaticQuery boolValue] == YES) {
            continue;
        }

        BankQueryResult *result = [[BankQueryResult alloc] init];
        result.accountNumber = account.accountNumber;
        result.accountSubnumber = account.accountSuffix;
        result.bankCode = account.bankCode;
        result.userId = account.userId;
        result.account = account;
        [resultList addObject: result];
    }
    // prepare UI
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: NO];
    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP219", nil) removeAfter: 0];

    // get statements in separate thread
    autoSyncRunning = YES;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(statementsNotification:)
                                                 name: PecuniaStatementsNotification
                                               object: nil];
    [[HBCIClient hbciClient] getStatements: resultList];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: [NSDate date] forKey: @"lastSyncDate"];

    // if autosync, setup next timer event
    BOOL autoSync = [defaults boolForKey: @"autoSync"];
    if (autoSync) {
        NSDate *syncTime = [defaults objectForKey: @"autoSyncTime"];
        if (syncTime == nil) {
            NSLog(@"No autosync time defined");
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

    LOG_LEAVE;
}

- (void)checkForAutoSync
{
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
            NSLog(@"No autosync time defined");
            autoSync = NO;
        }
    }
    NSDate    *lastSyncDate = [defaults objectForKey: @"lastSyncDate"];
    ShortDate *d1 = [ShortDate dateWithDate: lastSyncDate];
    ShortDate *d2 = [ShortDate dateWithDate: [NSDate date]];
    if ((d1 == nil || [d1 compare: d2] != NSOrderedSame) && syncAtStartup) {
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

- (void)applicationWillFinishLaunching: (NSNotification *)notification
{
    LOG_ENTER;

    // Display main window
    [mainWindow display];
    [mainWindow makeKeyAndOrderFront: self];

    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP108", nil) removeAfter: 0];

    mainVSplit.fixedIndex = 0;

    LOG_LEAVE;
}

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
    LOG_ENTER;

    StatusBarController *sc = [StatusBarController controller];
    MOAssistant         *assistant = [MOAssistant assistant];

    // Load context & model.
    @try {
        model = [assistant model];
        [assistant initDatafile: nil]; // use default data file
        self.managedObjectContext = [assistant context];
    }
    @catch (NSError *error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        [NSApp terminate: self];
    }

    // Open encrypted database
    if ([assistant encrypted]) {
        StatusBarController *sc = [StatusBarController controller];
        [sc startSpinning];
        [sc setMessage: NSLocalizedString(@"AP108", nil) removeAfter: 0];

        @try {
            [assistant decrypt];
            self.managedObjectContext = [assistant context];
        }
        @catch (NSError *error) {
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

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey: @"restoreActivePage"]) {
        NSInteger index = [LocalSettingsController.sharedSettings integerForKey: @"activePage"];
        sidebar.selectedIndex = index;
    } else {
        [self switchMainPage: 0];
    }

    // Display main window.
    [mainWindow display];
    [mainWindow makeKeyAndOrderFront: self];

    [self checkForAutoSync];

    // Add default tags if there are none yet.
    NSError        *error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"allTags"];
    NSUInteger     count = [self.managedObjectContext countForFetchRequest: request error: &error];
    if (error != nil) {
        NSLog(@"Error reading tags: %@", error.localizedDescription);
    }
    if (count == 0) {
        [Tag createDefaultTags];
    }

    // Add default categories if there aren't any but the predefined ones.
    if ([Category.catRoot.children count] == 1) {
        [Category createDefaultCategories];
    }

    // Check if there are any bank users or at least manual accounts.
    if (BankUser.allUsers.count == 0 && [Category.bankRoot.children count] == 0) {
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

    LOG_LEAVE;
}

- (NSApplicationTerminateReply)applicationShouldTerminate: (NSApplication *)sender
{
    LOG_ENTER;

    if ([self canTerminate] == NO) {
        return NSTerminateCancel;
    }
    return NSTerminateNow;
}

- (void)applicationWillTerminate: (NSNotification *)aNotification
{
    LOG_ENTER;

    shuttingDown = YES;

    [LocalSettingsController.sharedSettings setInteger: sidebar.selectedIndex forKey: @"activePage"];

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

    if (self.managedObjectContext && [MOAssistant assistant].isMaxIdleTimeExceeded == NO) {
        if (![self save]) {
            return;
        }
    }

    [[MOAssistant assistant] shutdown];
    [WorkerThread finish];

	// if application shall restart, launch new task
	if(restart) {
		NSProcessInfo *pi = [NSProcessInfo processInfo ];
		NSArray *args = [pi arguments ];
		NSString *path = [args objectAtIndex:0 ];
		if(path) {
            NSError *error = nil;
            NSURL *url = [NSURL fileURLWithPath:path];
            [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url options: (NSWorkspaceLaunchNewInstance) configuration:nil error:&error];
            if (error != nil) {
                [[NSAlert alertWithError:error] runModal];
            }
		}
	}

    LOG_LEAVE;
}

- (void)autoSyncTimerEvent: (NSTimer *)theTimer
{
    [self syncAllAccounts];
}

- (BOOL)checkForUnhandledTransfersAndSend
{
    LOG_ENTER;

    // Check for a new transfer not yet finished.
    if ([transfersController editingInProgress]) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP109", nil),
                                  NSLocalizedString(@"AP431", nil),
                                  NSLocalizedString(@"AP411", nil),
                                  NSLocalizedString(@"AP412", nil),
                                  nil
                                  );
        if (res == NSAlertAlternateReturn) {
            [self switchMainPage: 2];
            return NO;
        }
        [transfersController cancelEditing];
    }

    // Check for unsent transfers.
    NSError             *error = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"Transfer" inManagedObjectContext: self.managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isSent = NO"];
    [request setPredicate: predicate];
    NSArray *transfers = [self.managedObjectContext executeFetchRequest: request error: &error];
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
        [self switchMainPage: 2];
        return NO;
    }

    // send transfers
    BOOL sent = [[HBCIClient hbciClient] sendTransfers: transfers];
    if (sent) {
        [self save];
    }

    LOG_LEAVE;

    return NO;
}

- (void)updateUnread
{
    LOG_ENTER;

    NSTableColumn *tc = [accountsView tableColumnWithIdentifier: @"name"];
    if (tc) {
        ImageAndTextCell *cell = (ImageAndTextCell *)[tc dataCell];
        // update unread information
        NSInteger maxUnread = [BankAccount maxUnread];
        [cell setMaxUnread: maxUnread];
    }

    LOG_LEAVE;
}

- (BOOL)application: (NSApplication *)theApplication openFile: (NSString *)filename
{
    LOG_ENTER;

    [[MOAssistant assistant] initDatafile: filename];

    LOG_LEAVE;

    return YES;
}

- (void)startRefreshAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath: @"transform.rotation"];
    animation.fromValue = @0;
    animation.toValue = @M_PI;
    [animation setDuration: 0.5];
    [animation setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear]];
    [animation setRepeatCount: 20000];

    refreshButton.layer.anchorPoint = CGPointMake(0.52, 0.475);
    [refreshButton.layer addAnimation: animation forKey: @"transform.rotation"];
    [CATransaction flush];
}

- (void)stopRefreshAnimation
{
    [refreshButton.layer removeAllAnimations];
}

/**
 * Creates the selection image for the side bar and adds buttons for different actions.
 */
- (void)setupSidebar
{
    // First create selection image.
	NSInteger imageWidth = 12;
    NSInteger imageHeight = 22;
	NSImage* selectionImage = [[NSImage alloc] initWithSize: NSMakeSize(imageWidth, imageHeight)];

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
                          image: [NSImage imageNamed:@"overview-active"]
                 alternateImage: [NSImage imageNamed:@"overview"]];
    [sidebar addButtonWithTitle: NSLocalizedString(@"AP27", nil)
                          image: [NSImage imageNamed:@"graph3-active"]
                 alternateImage: [NSImage imageNamed:@"graph3"]];
	[sidebar addButtonWithTitle: NSLocalizedString(@"AP28", nil)
                          image: [NSImage imageNamed:@"distribution-active"]
                 alternateImage: [NSImage imageNamed:@"distribution"]];
	[sidebar addButtonWithTitle: NSLocalizedString(@"AP29", nil)
                          image: [NSImage imageNamed:@"graph4-active"]
                 alternateImage: [NSImage imageNamed:@"graph4"]];
    [sidebar addButtonWithTitle: NSLocalizedString(@"AP30", nil)
                          image: [NSImage imageNamed:@"table-active"]
                 alternateImage: [NSImage imageNamed:@"table"]];
	[sidebar addButtonWithTitle: NSLocalizedString(@"AP31", nil)
                          image: [NSImage imageNamed:@"assign-active"]
                 alternateImage: [NSImage imageNamed:@"assign"]];

	[sidebar addButtonWithTitle: NSLocalizedString(@"AP32", nil)
                          image: [NSImage imageNamed:@"send2-active"]
                 alternateImage: [NSImage imageNamed:@"send2"]];
	[sidebar addButtonWithTitle: NSLocalizedString(@"AP33", nil)
                          image: [NSImage imageNamed:@"send3-active"]
                 alternateImage: [NSImage imageNamed:@"send3"]];
}

#pragma mark - KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"showHiddenCategories"]) {
            [categoryController prepareContent];
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

- (IBAction)deleteAllData: (id)sender
{
    LOG_ENTER;

    int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP114", nil),
                                      NSLocalizedString(@"AP115", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      nil
                                      );
    if (res != NSAlertAlternateReturn) {
        return;
    }

    [MOAssistant.assistant clearAllData];
    [Category recreateRoots];

    LOG_LEAVE;
}

- (IBAction)generateData: (id)sender
{
    LOG_ENTER;

    GenerateDataController *generator = [[GenerateDataController alloc] init];
    [NSApp runModalForWindow: generator.window];

    LOG_LEAVE;
}

#pragma mark - Other stuff

- (IBAction)creditCardSettlements: (id)sender
{
    LOG_ENTER;

    BankAccount *account = [self selectedBankAccount];
    if (account == nil) {
        return;
    }

    CreditCardSettlementController *controller = [[CreditCardSettlementController alloc] init];
    controller.account = account;

    [NSApp runModalForWindow: [controller window]];

    LOG_LEAVE;
}

- (void)migrate
{
    LOG_ENTER;

    LocalSettingsController *settings = LocalSettingsController.sharedSettings;

    BOOL migrated10 = [settings boolForKey: @"Migrated10"];
    if (!migrated10) {
        NSManagedObjectContext *context = MOAssistant.assistant.context;

        NSError *error = nil;
        NSArray *bankUsers = BankUser.allUsers;
        NSArray *users = [HBCIClient.hbciClient getOldBankUsers];

        for (User *user in users) {
            BOOL found = NO;
            for (BankUser *bankUser in bankUsers) {
                if ([user.userId isEqualToString: bankUser.userId] &&
                    [user.bankCode isEqualToString: bankUser.bankCode] &&
                    (user.customerId == nil || [user.customerId isEqualToString: bankUser.customerId])) {
                    found = YES;
                }
            }
            if (!found) {
                // Create new bank user.
                BankUser *bankUser = [NSEntityDescription insertNewObjectForEntityForName: @"BankUser"
                                                                   inManagedObjectContext: context];
                bankUser.name = user.name;
                bankUser.bankCode = user.bankCode;
                bankUser.bankName = user.bankName;
                bankUser.bankURL = user.bankURL;
                bankUser.port = user.port;
                bankUser.hbciVersion = user.hbciVersion;
                bankUser.checkCert = @(user.checkCert);
                bankUser.country = user.country;
                bankUser.userId = user.userId;
                bankUser.customerId = user.customerId;
                bankUser.secMethod = @(SecMethod_PinTan);
            }
        }
        // BankUser assign accounts
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount"
                                                             inManagedObjectContext: context];
        NSFetchRequest      *request = [[NSFetchRequest alloc] init];

        [request setEntity: entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"userId != nil", self];
        [request setPredicate: predicate];
        NSArray *accounts = [context executeFetchRequest: request error: &error];

        // assign users to accounts and issue a message if an assigned user is not found
        NSMutableSet *invalidUsers = [NSMutableSet setWithCapacity: 10];
        for (BankAccount *account in accounts) {
            if ([invalidUsers containsObject: account.userId]) {
                continue;
            }
            BankUser *user = [BankUser userWithId: account.userId bankCode: account.bankCode];
            if (user) {
                NSMutableSet *users = [account mutableSetValueForKey: @"users"];
                [users addObject: user];
            } else {
                [invalidUsers addObject: account.userId];
            }
        }
        
        if (![self save]) {
            return;
        }

        // BankUser update BPD.
        bankUsers = [BankUser allUsers];
        if ([bankUsers count] > 0) {
            NSRunAlertPanel(NSLocalizedString(@"AP150", nil),
                            NSLocalizedString(@"AP203", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil, nil
                            );
            for (BankUser *user in [BankUser allUsers]) {
                [[HBCIClient hbciClient] updateBankDataForUser: user];
            }
        }

        settings[@"Migrated10"] = @YES;

        // success message
        if ([users count] > 0 && [bankUsers count] > 0) {
            NSRunAlertPanel(NSLocalizedString(@"AP150", nil),
                            NSLocalizedString(@"AP156", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil, nil
                            );
        }
    }

    LOG_LEAVE;
}

- (BOOL)save
{
    LOG_ENTER;

    NSError *error = nil;
    
    // save updates
    if (![self.managedObjectContext save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return NO;
    }

    LOG_LEAVE;

    return YES;
}

+ (BankingController *)controller
{
    return bankinControllerInstance;
}

@end
