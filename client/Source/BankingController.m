/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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

#import "Account.h"
#import "NewBankUserController.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "Category.h"
#import "PreferenceController.h"
#import "MOAssistant.h"
#import "TransactionController.h"
#import "LogController.h"
#import "CatAssignClassification.h"
#import "ExportController.h"
#import "MCEMOutlineViewLayout.h"
#import "AccountDefController.h"
#import "TimeSliceManager.h"
#import "MCEMTreeController.h"
#import "WorkerThread.h"
#import "BSSelectWindowController.h"
#import "StatusBarController.h"
#import "DonationMessageController.h"
#import "BankQueryResult.h"
#import "CategoryView.h"
#import "HBCIClient.h"
#import "StatCatAssignment.h"
#import "PecuniaError.h"
#import	"StatSplitController.h"
#import "ShortDate.h"
#import "BankStatementController.h"
#import "AccountChangeController.h"
#import "PurposeSplitController.h"
#import "TransferTemplateController.h"

#import "CategoryAnalysisWindowController.h"
#import "CategoryRepWindowController.h"
#import "CategoryDefWindowController.h"
#import "CategoryPeriodsWindowController.h"
#import "TransfersController.h"

#import "BankStatementPrintView.h"
#import "DockIconController.h"

#import "ImportController.h"
#import "ImageAndTextCell.h"
#import "StatementsListview.h"
#import "StatementDetails.h"
#import "RoundedOuterShadowView.h"
#import "SideToolbarView.h"

#import "AnimationHelper.h"
#import "GraphicsAdditions.h"
#import "BWGradientBox.h"

#import "User.h"
#import "BankUser.h"

// Pasteboard data types.
NSString* const BankStatementDataType = @"BankStatementDataType";
NSString* const CategoryDataType = @"CategoryDataType";

static BankingController *bankinControllerInstance;

static BOOL runningOnLionOrLater = NO;

@interface BankingController (Private)

- (void)saveBankAccountItemsStates;
- (void)restoreBankAccountItemsStates;
- (void)updateSorting;

@end

@implementation BankingController

@synthesize saveValue;
@synthesize managedObjectContext;
@synthesize dockIconController;

#pragma mark -
#pragma mark Initialization

-(id)init
{
    self = [super init];
    if (self != nil) {
        HBCIClient *client = nil;
        
        [bankinControllerInstance release];
        bankinControllerInstance = self;
        restart = NO;
        requestRunning = NO;
        statementsBound = YES;
        mainTabItems = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
        
        // TODO: make lower limit configurable?
        [Category setCatReportFrom: [ShortDate dateWithYear: 2009 month:1 day:1] to: [ShortDate distantFuture]];
        
        // Load context & model.
        @try {
            model = [[MOAssistant assistant] model];
            self.managedObjectContext = [[MOAssistant assistant] context];
        }
        @catch (NSError* error) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            [NSApp terminate: self];
        }
        
        @try {
            client = [HBCIClient hbciClient];
            PecuniaError *error = [client initHBCI];
            if (error != nil) {
                [error alertPanel ];
                [NSApp terminate: self];
                
            }
        }
        @catch (NSError *error) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            [NSApp terminate: self];
        }
        
        logController = [LogController logController];
        
        int macVersion;
        if (Gestalt(gestaltSystemVersion, &macVersion) == noErr) {
            runningOnLionOrLater = macVersion > MAC_OS_X_VERSION_10_6;
        }
    }    
    return self;
}

//--------------------------------------------------------------------------------------------------

- (void)setNumberFormatForCell: (NSCell*) cell positive: (NSDictionary*) positive
                      negative: (NSDictionary*) negative
{
    if (cell == nil)
        return;
    
    NSNumberFormatter* formatter;
    if ([cell isKindOfClass: [ImageAndTextCell class]])
        formatter =  ((ImageAndTextCell*) cell).amountFormatter;
    else
        formatter =  [cell formatter];
    
    if (formatter)
    {
        [formatter setTextAttributesForPositiveValues: positive];
        [formatter setTextAttributesForNegativeValues: negative];
    }
    
}

-(void)awakeFromNib
{
    sortAscending = NO;
    sortIndex = 0;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey: @"mainSortIndex" ]) {
        sortControl.selectedSegment = [[userDefaults objectForKey: @"mainSortIndex"] intValue];
    }
    if ([userDefaults objectForKey: @"mainSortAscending" ]) {
        sortAscending = [[userDefaults objectForKey: @"mainSortAscending"] boolValue];
    }

    [self updateSorting];
    
    NSDictionary* positiveAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Positive Cash"], NSForegroundColorAttributeName,
                                        nil
                                       ];
    NSDictionary* negativeAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Negative Cash"], NSForegroundColorAttributeName,
                                        nil
                                       ];
    
    NSTableColumn* tableColumn;
    
    [self setNumberFormatForCell: [valueField cell] positive: positiveAttributes negative: negativeAttributes];
    [self setNumberFormatForCell: [headerValueField cell] positive: positiveAttributes negative: negativeAttributes];
    [self setNumberFormatForCell: [nassValueField cell] positive: positiveAttributes negative: negativeAttributes];
    
    // Edit an account by double clicking it.
    [accountsView setDoubleAction: @selector(changeAccount:)];
    [accountsView setTarget: self];
    
    tableColumn = [accountsView tableColumnWithIdentifier: @"name"];
    if(tableColumn)
    {
        ImageAndTextCell *cell = (ImageAndTextCell*)[tableColumn dataCell];
        if (cell)
        {
            [cell setFont: [NSFont fontWithName: @"Lucida Grande" size: 13]];
            [self setNumberFormatForCell: cell positive: positiveAttributes negative: negativeAttributes];
            
            // update unread information
            NSInteger maxUnread = [BankAccount maxUnread];
            [cell setMaxUnread:maxUnread];
        }
    }
    
    // sort descriptor for accounts view
    NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
    NSArray *sds = [NSArray arrayWithObject:sd];
    [categoryController setSortDescriptors: sds];
    
    // status (content) bar
    [mainWindow setAutorecalculatesContentBorderThickness: NO forEdge: NSMinYEdge];
    [mainWindow setContentBorderThickness: 30.0f forEdge: NSMinYEdge];
    
    // register Drag'n Drop
    [accountsView registerForDraggedTypes: [NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil]];
    
    // set lock image
    [self setEncrypted: [[MOAssistant assistant] encrypted]];
    [mainWindow setContentMinSize:NSMakeSize(800, 450)];
    splitCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed: @"cursor.png"] hotSpot:NSMakePoint(0, 0)];
    [WorkerThread init];
    
    // todo [self migrate];
    [categoryController addObserver: self forKeyPath: @"arrangedObjects.catSum" options: 0 context: nil];
    [categoryAssignments addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: nil];
    
    // Setup statements listview.
    [statementsListView bind: @"dataSource" toObject: categoryAssignments withKeyPath: @"arrangedObjects" options: nil];
    [statementsListView bind: @"valueArray" toObject: categoryAssignments withKeyPath: @"arrangedObjects.value" options: nil];
    
    // Bind controller to selectedRow property and the listview to the controller's selectedIndex property to get notified about selection changes.
    [categoryAssignments bind: @"selectionIndexes" toObject: statementsListView withKeyPath: @"selectedRows" options: nil];
    [statementsListView bind: @"selectedRows" toObject: categoryAssignments withKeyPath: @"selectionIndexes" options: nil];
    
    [statementsListView setCellSpacing: 0];
    [statementsListView setAllowsEmptySelection: YES];
    [statementsListView setAllowsMultipleSelection: YES];
    NSNumberFormatter* formatter = [statementsListView numberFormatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];

    [rightSplitter retain]; // Content views are dynamically exchanged with proper retain/release.
                            // The right splitter is the initial control and needs an own retain to avoid losing it
                            // on the next switch.
    
    currentSection = nil; // The right splitter, which is by default active is not a regular section.

    if (self.managedObjectContext) {
        [self publishContext];
    }
    
    // Setup full screen mode support on Lion+.
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_6
    if (runningOnLionOrLater) {
        [mainWindow setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
        [toggleFullscreenItem setHidden: NO];
    }
#endif
}

- (void)dealloc
{
    [categoryAnalysisController release];
    [categoryReportingController release];
    [categoryDefinitionController release];
    [categoryPeriodsController release];
    
    [rightSplitter release];
    [bankAccountItemsExpandState release];
    
    [super dealloc];
}

-(void)publishContext
{
    NSError *error=nil;
    
    [categoryController setManagedObjectContext: self.managedObjectContext];
    [categoryAssignments setManagedObjectContext: self.managedObjectContext];
    
    // repair Category Root
    [self repairCategories];
    
    [self setHBCIAccounts];
    
    [self updateBalances];
    
    // update unread information
    [self updateUnread];
    
    [categoryController fetchWithRequest: nil merge: NO error: &error];
    [transactionController setManagedObjectContext: managedObjectContext];
    [timeSlicer updateDelegate];
    [self performSelector: @selector(restoreAccountsView) withObject: nil afterDelay: 0.0];
    dockIconController = [[DockIconController alloc] initWithManagedObjectContext:self.managedObjectContext];
    
    [self migrate];
}

#pragma mark -
#pragma mark User actions

-(void)setHBCIAccounts
{
    NSError *error = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:managedObjectContext];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"accountNumber != nil AND userId != nil"];
    [request setPredicate:predicate];
    NSArray *accounts = [self.managedObjectContext executeFetchRequest:request error:&error];
    if( error != nil || accounts == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    PecuniaError *pecError = [[HBCIClient hbciClient] setAccounts:accounts];
    if (pecError) {
        [pecError alertPanel];
    }
}

-(void)updateBankAccounts:(NSArray *)hbciAccounts forUser:(BankUser*)user
{
    NSError *error=nil;
    BOOL found;
    
    if (hbciAccounts == nil) {
        hbciAccounts = [[HBCIClient hbciClient] getAccountsForUser:user];
    }
    
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"allBankAccounts"];
    NSArray *tmpAccounts = [self.managedObjectContext executeFetchRequest:request error:&error];
    if( error != nil || tmpAccounts == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    NSMutableArray*	bankAccounts = [NSMutableArray arrayWithArray: tmpAccounts];

    for (Account *acc in hbciAccounts) {
        BankAccount *account;
        
        //lookup
        found = NO;
        for (account in bankAccounts) {
			if ([account.bankCode isEqual: acc.bankCode ] && [account.accountNumber isEqual: acc.accountNumber ] && 
                ((account.accountSuffix == nil && acc.subNumber == nil) || [account.accountSuffix isEqual: acc.subNumber ])) {
                found = YES;
                break;
            }
        }
        if (found) {
            // Update the user id if there is none assigned yet or if it differs.
            if (account.userId == nil || ![account.userId isEqualToString: acc.userId]) {
                account.userId = acc.userId;
                account.customerId = acc.customerId;
                NSMutableSet *users = [account mutableSetValueForKey: @"users"];
                [users addObject: user];
            }
            if (acc.bic != nil) {
                account.bic = acc.bic;
            }
            if (acc.iban != nil) {
                account.iban = acc.iban;
            }
            
        } else {
            // Account was not found: create it.
            BankAccount* bankRoot = [self getBankNodeWithAccount: acc inAccounts: bankAccounts];
            if(bankRoot == nil) return;
            BankAccount	*bankAccount = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount"
                                                                     inManagedObjectContext:self.managedObjectContext];
            
            bankAccount.accountNumber = acc.accountNumber;
            bankAccount.name = acc.name;
            bankAccount.bankCode = acc.bankCode;
            bankAccount.bankName = acc.bankName;
            bankAccount.currency = acc.currency;
            bankAccount.country = acc.country;
            bankAccount.owner = acc.ownerName;
            bankAccount.userId = acc.userId;
            bankAccount.customerId = acc.customerId;
            bankAccount.isBankAcc = [NSNumber numberWithBool: YES];
            bankAccount.accountSuffix = acc.subNumber;
            bankAccount.bic = acc.bic;
            bankAccount.iban = acc.iban;
            bankAccount.type = acc.type;
            //			bankAccount.uid = [NSNumber numberWithUnsignedInt: [acc uid]];
            //			bankAccount.type = [NSNumber numberWithUnsignedInt: [acc type]];
            
            // links
            bankAccount.parent = bankRoot;
            NSMutableSet *users = [bankAccount mutableSetValueForKey:@"users" ];
            [users addObject:user ];
        } 
    }
    // save updates
    if([self.managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
}

/*
-(void)updateBankAccounts:(NSArray*)hbciAccounts
{
    NSError	*error = nil;
    BOOL found;
    
    if (hbciAccounts == nil) {
        // collect all accounts of all users
        NSArray *users = [BankUser allUsers];
        hbciAccounts = [NSArray array];
        for(BankUser *user in users) {
            NSArray *userAccounts = [[HBCIClient hbciClient] getAccountsForUser:user];
            hbciAccounts = [hbciAccounts arrayByAddingObjectsFromArray:userAccounts];
        }
    }
    
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"allBankAccounts"];
    NSArray *tmpAccounts = [self.managedObjectContext executeFetchRequest:request error:&error];
    if( error != nil || tmpAccounts == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    NSMutableArray*	bankAccounts = [NSMutableArray arrayWithArray: tmpAccounts];
    
    for (Account *acc in hbciAccounts) {
        BankAccount *account;
        
        //lookup
        found = NO;
        for (account in bankAccounts) {
			if ([account.bankCode isEqual: acc.bankCode ] && [account.accountNumber isEqual: acc.accountNumber ] && 
                ((account.accountSuffix == nil && acc.subNumber == nil) || [account.accountSuffix isEqual: acc.subNumber ])) {
                found = YES;
                break;
            }
        }
        if (found == YES) {
            // Account was found: update user- and customer-id
            account.userId = acc.userId;
            account.customerId = acc.customerId;
            account.collTransfer = [NSNumber numberWithBool:acc.collTransfer];
        } else {
            // Account was not found: create it
            BankAccount* bankRoot = [self getBankNodeWithAccount: acc inAccounts: bankAccounts];
            if(bankRoot == nil) return;
            BankAccount	*bankAccount = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount"
                                                                     inManagedObjectContext:self.managedObjectContext];
            
            bankAccount.accountNumber = acc.accountNumber;
            bankAccount.name = acc.name;
            bankAccount.bankCode = acc.bankCode;
            bankAccount.bankName = acc.bankName;
            bankAccount.currency = acc.currency;
            bankAccount.country = acc.country;
            bankAccount.owner = acc.ownerName;
            bankAccount.userId = acc.userId;
            bankAccount.customerId = acc.customerId;
            bankAccount.isBankAcc = [NSNumber numberWithBool: YES];
            bankAccount.accountSuffix = acc.subNumber;
            bankAccount.type = acc.type;
            //			bankAccount.uid = [NSNumber numberWithUnsignedInt: [acc uid]];
            //			bankAccount.type = [NSNumber numberWithUnsignedInt: [acc type]];
            
            // link
            bankAccount.parent = bankRoot;
        } 
        
    }
    // save updates
    if([self.managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
}
 */

-(NSIndexPath*)indexPathForCategory: (Category*)cat inArray: (NSArray*)nodes
{
    NSUInteger idx=0;
    for (NSTreeNode *node in nodes) {
        Category *obj = [node representedObject];
        if(obj == cat) return [NSIndexPath indexPathWithIndex: idx];
        else {
            NSArray *children = [node childNodes];
            if(children == nil) continue;
            NSIndexPath *p = [self indexPathForCategory: cat inArray: children];
            if(p) return [p indexPathByAddingIndex: idx];
        }
        idx++;
    }
    return nil;
}


-(void)removeBankAccount: (BankAccount*)bankAccount keepAssignedStatements:(BOOL)keepAssignedStats
{
    NSSet* stats = [bankAccount mutableSetValueForKey: @"statements"];
    NSEnumerator *enumerator = [stats objectEnumerator];
    BankStatement*	statement;
    int		i;
    BOOL	removeParent = NO;
    
    //  Delete bank statements which are not assigned first
    while ((statement = [enumerator nextObject])) {
        if (keepAssignedStats == NO) {
            [self.managedObjectContext deleteObject:statement];
        } else {
            NSSet *assignments = [statement mutableSetValueForKey:@"assignments"];
            if ([assignments count] < 2) {
                [self.managedObjectContext deleteObject:statement];
            } else if ([assignments count] == 2) {
                // delete statement if not assigned yet
                if ([statement hasAssignment] == NO) {
                    [self.managedObjectContext deleteObject:statement];
                }
            } else {
                statement.account = nil;
            }
        }
    }
    
    [self.managedObjectContext processPendingChanges];
    [[Category nassRoot] invalidateBalance];
    [Category updateCatValues];
    
    // remove parent?
    BankAccount *parent = [bankAccount valueForKey: @"parent"];
    if(parent != nil) {
        NSSet *childs = [parent mutableSetValueForKey: @"children"];
        if([childs count] == 1 ) removeParent = YES;
    }
    
    // calculate index path of current object
    NSArray *nodes = [[categoryController arrangedObjects] childNodes];
    NSIndexPath *path = [self indexPathForCategory: bankAccount inArray: nodes];
    // IndexPath umdrehen
    NSIndexPath *newPath = [[[NSIndexPath alloc] init] autorelease];
    for(i=[path length]-1; i>=0; i--) newPath = [newPath indexPathByAddingIndex: [path indexAtPosition:i]]; 
    
    [categoryController removeObjectAtArrangedObjectIndexPath: newPath];
    if(removeParent) {
        newPath = [newPath indexPathByRemovingLastIndex];
        [categoryController removeObjectAtArrangedObjectIndexPath: newPath];
    }
    //	[categoryController remove: self];
    [[Category bankRoot] rollup];
    
    //	[accountsView setNeedsDisplay: YES];
}

-(BOOL)cleanupBankNodes
{
    BOOL flg_changed = NO;
    // remove empty bank nodes
    Category *root = [Category bankRoot];
    if(root != nil) {
        NSArray *bankNodes = [[root mutableSetValueForKey: @"children"] allObjects];
        for (BankAccount *node in bankNodes) {
            NSMutableSet *childs = [node mutableSetValueForKey: @"children"];
            if(childs == nil || [childs count] == 0) {
                [self.managedObjectContext deleteObject: node];
                flg_changed = YES;
            }
        }
    }
    return flg_changed;
}

-(Category*)getBankingRoot
{
    NSError	*error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"getBankingRoot"];
    NSArray *cats = [self.managedObjectContext executeFetchRequest:request error:&error];
    if( error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return nil;
    }
    if([cats count] > 0) return [cats objectAtIndex: 0];
    
    // create Root object
    Category *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
                                                  inManagedObjectContext:self.managedObjectContext];
    [obj setValue: @"++bankroot" forKey: @"name"];
    [obj setValue: [NSNumber numberWithBool: YES] forKey: @"isBankAcc"];
    return obj;
}


-(void)repairCategories
{
    NSError		*error = nil;
    Category	*catRoot;
    BOOL		found = NO;
    
    // repair bank root
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"getBankingRoot"];
    NSArray *cats = [self.managedObjectContext executeFetchRequest:request error:&error];
    if( error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    
    for (Category *cat in cats) {
        NSString *n = [cat primitiveValueForKey:@"name"];
        if(![n isEqualToString: @"++bankroot"]) {
            [cat setValue: @"++bankroot" forKey: @"name"];
            break;
        }
    }
    
    // repair categories
    request = [model fetchRequestTemplateForName:@"getCategoryRoot"];
    cats = [self.managedObjectContext executeFetchRequest:request error:&error];
    if( error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    
    for (Category *cat in cats) {
        NSString *n = [cat primitiveValueForKey:@"name"];
        if([n isEqualToString: @"++catroot"] ||
           [n isEqualToString: @"Umsatzkategorien"] ||
           [n isEqualToString: @"Transaction categories"]) {
            [cat setValue: @"++catroot" forKey: @"name"];
            catRoot = cat;
            found = YES;
            break;
        }
    }
    
    if(found == NO) {
        // create Category Root object
        Category *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
                                                      inManagedObjectContext:self.managedObjectContext];
        [obj setValue: @"++catroot" forKey: @"name"];
        [obj setValue: [NSNumber numberWithBool: NO] forKey: @"isBankAcc"];
        catRoot = obj;
    }
    
    // reassign categories
    for (Category *cat in cats) {
        if(cat == catRoot) continue;
        if([cat valueForKey: @"parent"] == nil) [cat setValue: catRoot forKey: @"parent"];
    }
    
    // insert not assigned node
    request = [model fetchRequestTemplateForName:@"getNassRoot"];
    cats = [self.managedObjectContext executeFetchRequest:request error:&error];
    if( error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    if([cats count] == 0) {
        Category *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
                                                      inManagedObjectContext:self.managedObjectContext];
        [obj setPrimitiveValue: @"++nassroot" forKey: @"name"];
        [obj setValue: [NSNumber numberWithBool: NO] forKey: @"isBankAcc"];
        [obj setValue: catRoot forKey: @"parent"];
        
        [self updateNotAssignedCategory];
    }
    
    // save updates
    if([self.managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
}

-(BankAccount*)getBankNodeWithAccount: (Account*)acc inAccounts: (NSMutableArray*)bankAccounts
{
    BankAccount *bankNode = [BankAccount bankRootForCode: acc.bankCode];
    
    if(bankNode == nil) {
        Category *root = [Category bankRoot];
        if(root == nil) return nil;
        // create bank node
        bankNode = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:self.managedObjectContext];
        bankNode.name = acc.bankName;
        bankNode.bankCode = acc.bankCode;
        bankNode.currency = acc.currency;
        bankNode.bic = acc.bic;
        bankNode.isBankAcc = [NSNumber numberWithBool: YES];
        bankNode.parent = root;
        if(bankAccounts) [bankAccounts addObject: bankNode];
    }
    return bankNode;
}

-(void)updateBalances
{
    NSError *error = nil;
    
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"getRootNodes"];
    NSArray *cats = [self.managedObjectContext executeFetchRequest:request error:&error];
    if( error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    for (Category* cat in cats) {
        if([cat isBankingRoot] == NO) [cat updateInvalidBalances];
        [cat rollup];
    }
    
    // save updates
    if([self.managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
}

-(IBAction)updateAllAccounts:(id)sender
{
    NSArray *users = [BankUser allUsers];
    for (BankUser *user in users) {
        [self updateBankAccounts: nil forUser: user];
    }
}

-(IBAction)enqueueRequest: (id)sender
{
    NSMutableArray	*selectedAccounts = [NSMutableArray arrayWithCapacity: 10];
    NSArray			*selectedNodes = nil;
    Category		*cat;
    NSError			*error = nil;
    
    cat = [self currentSelection];
    if(cat == nil) return;
    
    // one bank account selected
    if(cat.accountNumber != nil) [selectedAccounts addObject: cat];
    else {
        // a node was selected
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:self.managedObjectContext];
        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        [request setEntity:entityDescription];
        if(cat.parent == nil) {
            // root was selected
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@", cat];
            [request setPredicate:predicate];
            selectedNodes = [self.managedObjectContext executeFetchRequest:request error:&error];
            if(error) {
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
                return;
            }
        } else {
            // a node was selected
            selectedNodes = [NSArray arrayWithObjects: cat, nil];
        }
        // now select accounts from nodes
        BankAccount *account;
        for(account in selectedNodes) {
            NSArray *result;
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@ AND noAutomaticQuery == 0", account];
            [request setPredicate:predicate];
            result = [self.managedObjectContext executeFetchRequest:request error:&error];
            if(error) {
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
                return;
            }
            [selectedAccounts addObjectsFromArray: result];
        }
    }
    if([selectedAccounts count] == 0) return;
    
    // check if at least one Account is assigned to a user
    NSUInteger nInactive = 0;
    BankAccount *account;
    for (account in selectedAccounts) if(account.userId == nil) nInactive++;
    if (nInactive == [selectedAccounts count]) {
        NSRunAlertPanel(NSLocalizedString(@"AP87", @""), 
                        NSLocalizedString(@"AP88", @""), 
                        NSLocalizedString(@"ok", @"Ok"),
                        nil, nil
                        );
        return;
    }
    if(nInactive > 0) {
        NSRunAlertPanel(NSLocalizedString(@"AP89", @""), 
                        NSLocalizedString(@"AP90", @""), 
                        NSLocalizedString(@"ok", @"Ok"),
                        nil, nil,
                        nInactive,
                        [selectedAccounts count]
                        );
    }
    
    // now selectedAccounts has all selected Bank Accounts
    NSMutableArray *resultList = [NSMutableArray arrayWithCapacity: [selectedAccounts count]];
    for(account in selectedAccounts) {
        if (account.userId) {
            BankQueryResult *result = [[BankQueryResult alloc] init];
            result.accountNumber = account.accountNumber;
            result.accountSubnumber = account.accountSuffix;
            result.bankCode = account.bankCode;
            result.userId = account.userId;
            result.account = account;
            [resultList addObject: [result autorelease]];
        }
    }
    
    // show log if wanted
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL showLog = [defaults boolForKey: @"logForBankQuery"];
    if (showLog) {
        [logController showWindow:self];
        [[logController window] orderFront:self];
    }
    
    // prepare UI
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: NO];
    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP41", @"Load statements...") removeAfter:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statementsNotification:) name:PecuniaStatementsNotification object:nil];
    [[HBCIClient hbciClient] getStatements: resultList];
}

-(void)statementsNotification: (NSNotification*)notification
{
    BankQueryResult *result;
    StatusBarController *sc = [StatusBarController controller];
    BOOL			noStatements = YES;
    BOOL			isImport = NO;
    int				count = 0;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PecuniaStatementsNotification object:nil];
    
    NSArray *resultList = [notification object];
    if(resultList == nil) {
        [sc stopSpinning];
        [sc clearMessage];
        requestRunning = NO;
        return;
    }
    
    // get Proposals
    for(result in resultList) {
        NSArray *stats = result.statements;
        if([stats count] > 0) {
            noStatements = FALSE;
            [result.account evaluateQueryResult: result];
        }
        if (result.isImport) isImport = YES;
        [result.account updateStandingOrders: result.standingOrders];
    }
    
    [BankStatement initCategoriesCache];
    
    [sc stopSpinning];
    [sc clearMessage];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL check = [defaults boolForKey: @"manualTransactionCheck"];
    
    if((check || isImport) && noStatements == FALSE) {
        BSSelectWindowController *selectWindowController = [[[BSSelectWindowController alloc] initWithResults: resultList] autorelease];
        [selectWindowController showWindow: self];
    } else {
        @try {
            for(result in resultList) {
                    count += [result.account updateFromQueryResult: result];
                }
        }
        @catch (NSException * e) {
            [[MessageLog log ] addMessage:e.reason withLevel:LogLevel_Error];
        }
        if (autoSyncRunning == YES) [self checkBalances:resultList];
        [self requestFinished: resultList];
        
        // status message
        [sc setMessage: [NSString stringWithFormat: NSLocalizedString(@"AP80", @""), count] removeAfter:120 ];
    }
    autoSyncRunning = NO;
    
    NSSound* doneSound = [NSSound soundNamed: @"done.mp3"];
    if (doneSound != nil)
        [doneSound play];
}


-(void)requestFinished: (NSArray*)resultList
{
    [self.managedObjectContext processPendingChanges];
    [self updateBalances];
    requestRunning = NO;
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: YES];
    
    if(resultList != nil) {
        Category *cat = [self currentSelection];
        if(cat && [cat isBankAccount] && cat.accountNumber == nil) [categoryAssignments setContent: [cat combinedStatements]];
        
        BankQueryResult *result;
        NSDate *maxDate = nil;
        for(result in resultList) {
            NSDate *lDate = result.account.latestTransferDate;
            if (((maxDate != nil) && ([maxDate compare: lDate] == NSOrderedAscending)) || (maxDate == nil)) maxDate = lDate;
        }
        if(maxDate) [timeSlicer stepIn: [ShortDate dateWithDate: maxDate]];
        
        // update unread information
        NSInteger maxUnread = [BankAccount maxUnread];
        
        // update data cell
        NSTableColumn *tc = [accountsView tableColumnWithIdentifier: @"name"];
        if(tc) {
            ImageAndTextCell *cell = (ImageAndTextCell*)[tc dataCell];
            [cell setMaxUnread:maxUnread];
        }
        
        // redraw accounts view
        [accountsView setNeedsDisplay:YES];
        
        [categoryAssignments rearrangeObjects];
    }
}

-(void)checkBalances:(NSArray*)resultList
{
    NSNumber *threshold;
    BOOL alert = NO;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL accWarning = [defaults boolForKey:@"accWarning"];
    if (accWarning == NO) return;
    
    threshold = [defaults objectForKey:@"accWarningThreshold"];
    if (threshold == nil) {
        threshold = [NSDecimalNumber zero];
    }
    
    // check if account balances change below threshold
    for(BankQueryResult *result in resultList) {
        if ([result.oldBalance compare:threshold] == NSOrderedDescending && [result.balance compare:threshold] == NSOrderedAscending) {
            alert = YES;
        }
    }
    if (alert == YES) {
        NSRunAlertPanel(NSLocalizedString(@"AP119", @""), 
                        NSLocalizedString(@"AP120", @""), 
                        NSLocalizedString(@"ok", @"Ok"),
                        nil, nil
                        );
    }
}

-(BOOL)requestRunning
{
    return requestRunning;
}

-(BankAccount*)selectBankAccountWithNumber:(NSString*)accNum bankCode:(NSString*)code
{
    NSError *error = nil;
    NSDictionary *subst = [NSDictionary dictionaryWithObjectsAndKeys:
                           accNum, @"ACCNT", code, @"BCODE", nil];
    NSFetchRequest *fetchRequest =
    [model fetchRequestFromTemplateWithName:@"bankAccountByID" substitutionVariables:subst];
    NSArray *results =
    [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if( error != nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return nil;
    }
    if(results == nil || [results count] != 1) return nil;
    return [results objectAtIndex: 0];
}


-(NSArray*)selectedNodes
{
    return [categoryController selectedObjects];
}

-(IBAction)editBankUsers:(id)sender
{	
    if (!bankUserController) {
        bankUserController = [[NewBankUserController alloc] initForController: self];
    }

    NSRect frame = [[bankUserController window] frame];
    frame = NSInsetRect(frame, 0.5 * frame.size.width, 0.5 * frame.size.height);
    [[bankUserController window] zoomInFromRect: frame withFade: NO makeKey: YES];
}

-(IBAction)editPreferences:(id)sender
{
    if(!prefController) { 
        prefController = [[PreferenceController alloc] init];
        [prefController setMainWindow: mainWindow];
    }
    [prefController showWindow: self];
}

-(void)windowWillClose:(NSNotification *)aNotification
{
    id window = [aNotification object ];
    if (window == assignValueWindow) {
        [NSApp stopModalWithCode:0 ];
    }
    if (window == mainWindow) {
        [NSApp terminate:self ];
    }
}

#pragma mark -
#pragma mark Account management

-(IBAction)addAccount: (id)sender
{
    NSString *bankCode = nil;
    Category* cat = [self currentSelection];
    if(cat != nil) {
        if([cat isBankAccount] == YES && [cat isRoot] == NO) bankCode = [cat valueForKey: @"bankCode"];
    }
    
    // check if there is any User
    if([[BankUser allUsers ] count] == 0) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP37", @"Account cannot be created"), 
                                  NSLocalizedString(@"AP38", @"Please setup Bank ID first"), 
                                  NSLocalizedString(@"ok", @"Ok"), 
                                  NSLocalizedString(@"AP39", @"Setup Bank ID") , nil);
        if(res == NSAlertAlternateReturn) [self editBankUsers: self];
        return;
    }
    
    AccountDefController *defController = [[[AccountDefController alloc] init] autorelease];
    if (bankCode) [defController setBankCode: bankCode name: [cat valueForKey: @"bankName"]];
    
    int res = [NSApp runModalForWindow: [defController window]];
    if(res) {
        // account was created
        NSError *error = nil;
        
        // save updates
        if([self.managedObjectContext save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return;
        }
    }
    [categoryController rearrangeObjects];
    [self updateBalances];
}

-(IBAction)changeAccount: (id)sender
{
    Category* cat = [self currentSelection];
    if (cat == nil || ![cat isBankAccount] || [cat accountNumber] == nil) {
        return;
    }
    
    AccountChangeController *changeController = [[[AccountChangeController alloc] initWithAccount: (BankAccount*)cat] autorelease];
    int res = [NSApp runModalForWindow: [changeController window]];
    if(res) {
        statementsListViewHost.indicatorColor = [cat categoryColor];
        
        // account was changed
        NSError *error = nil;
        // save updates
        if([self.managedObjectContext save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return;
        }
    }
    [categoryController rearrangeObjects];
}

-(IBAction)deleteAccount:(id)sender
{
    NSError	*error = nil;
    Category* cat = [self currentSelection];
    if(cat == nil) return;
    if([cat isBankAccount] == NO) return;
    if([cat accountNumber] == nil) return;
    
    BankAccount *account = (BankAccount*)cat;
    
    // issue a confirmation
    int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP30", @""),
                                      NSLocalizedString(@"AP100", @""),
                                      NSLocalizedString(@"no", @""),
                                      NSLocalizedString(@"yes", @""),
                                      nil,
                                      account.accountNumber
                                      );
    if(res != NSAlertAlternateReturn) return;	
    
    // check for transactions
    BOOL keepAssignedStatements = NO;
    NSMutableSet *stats = [cat mutableSetValueForKey: @"statements"];
    if(stats && [stats count] > 0) {
        BOOL hasAssignment = NO;
        
        // check if transactions are assigned
        for(BankStatement* stat in stats) {
            if ([stat hasAssignment]) {
                hasAssignment = YES;
                break;
            }
        }
        
        if (hasAssignment) {
            int alertResult = NSRunCriticalAlertPanel(NSLocalizedString(@"AP30", @""),
                                                      NSLocalizedString(@"AP29", @""),
                                                      NSLocalizedString(@"yes", @""),
                                                      NSLocalizedString(@"no", @""),
                                                      NSLocalizedString(@"cancel", @""),
                                                      account.accountNumber
                                                      );
            if (alertResult == NSAlertDefaultReturn) {
                keepAssignedStatements = YES;
            } else {
                if (alertResult == NSAlertOtherReturn) return;
                else keepAssignedStatements = NO;
            }
        }
    }
    // delete account
    [self removeBankAccount: account keepAssignedStatements: keepAssignedStatements];
    
    // save updates
    if([self.managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
}

/*
-(void)removeDeletedAccounts
{
    NSError	*error = nil;
    BOOL	flg_update=NO;
    
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"allBankAccounts"];
    NSArray *bankAccounts = [self.managedObjectContext executeFetchRequest:request error:&error];
    if( error != nil || bankAccounts == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    NSArray *hbciAccounts = [[HBCIClient hbciClient] accounts];
    for(BankAccount *account in bankAccounts) {
        BOOL found = NO;
        for(Account *acc in hbciAccounts) {
            if ([acc.accountNumber isEqualToString: account.accountNumber] && [acc.bankCode isEqualToString:account.bankCode]) {
                found = YES;
                break;
            }
        }
        if (found == NO) {
            // Accounts will be deleted - keep Statements ?
            BOOL keepAssignedStatements = NO;
            NSMutableSet *stats = [account mutableSetValueForKey: @"statements"];
            if(stats && [stats count] > 0) {
                BOOL hasAssignment;
                
                // check if transactions are assigned
                for(BankStatement* stat in stats) {
                    if ([stat hasAssignment]) {
                        hasAssignment = YES;
                        break;
                    }
                }
                
                if (hasAssignment) {
                    int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP30", @""),
                                                      NSLocalizedString(@"AP29", @""),
                                                      NSLocalizedString(@"yes", @""),
                                                      NSLocalizedString(@"no", @""),
                                                      nil,
                                                      account.accountNumber
                                                      );
                    if (res == NSAlertDefaultReturn) {
                        keepAssignedStatements = YES;
                    } else keepAssignedStatements = NO;
                }
            }
            [self removeBankAccount:account keepAssignedStatements:keepAssignedStatements];
            flg_update = YES;
        }
    }
    
    // save updates
    if(flg_update == YES) {
        if([self.managedObjectContext save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return;
        }
    }
}
*/

#pragma mark -
#pragma mark Page switching

- (void)updateStatusbar
{
    Category *cat = [self currentSelection];
    ShortDate* fromDate = [timeSlicer lowerBounds];
    ShortDate* toDate = [timeSlicer upperBounds];
    
    NSInteger turnovers = 0;
    int currentPage = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];
    if (currentPage == 0)
    {
        NSDecimalNumber* turnoversValue = [cat valuesOfType: cat_turnovers from: fromDate to: toDate];
        turnovers = [turnoversValue integerValue];
    }
    
    if (turnovers > 0)
    {
        NSDecimalNumber* spendingsValue = [cat valuesOfType: cat_spendings from: fromDate to: toDate];
        NSDecimalNumber* earningsValue = [cat valuesOfType: cat_earnings from: fromDate to: toDate];
        
        [spendingsField setValue: spendingsValue forKey: @"objectValue"];
        [earningsField setValue: earningsValue forKey: @"objectValue"];
        if (turnovers != 1)
            [turnoversField setStringValue: [NSString stringWithFormat: NSLocalizedString(@"AP133", @"%u turnovers"), turnovers]];
        else
            [turnoversField setStringValue: NSLocalizedString(@"AP132", @"1 turnover")];
    }
    else
    {
        [spendingsField setStringValue: @""];
        [earningsField setStringValue: @""];
        [turnoversField setStringValue: @""];
    }
}

- (IBAction)activateMainPage: (id)sender
{
    [accountsToolbarItem setImage: [NSImage imageNamed: @"accounts"]];
    [transfersToolbarItem setImage: [NSImage imageNamed: @"transfers"]];
    [standingOrdersToolbarItem setImage: [NSImage imageNamed: @"standing-order"]];
    switch ([sender tag])
    {
        case 0: {
            [currentSection deactivate];
            [transfersController deactivate];
            [mainTabView selectTabViewItemAtIndex: 0];
            [accountsToolbarItem setImage: [NSImage imageNamed: @"accounts-active"]];
            break;
        }
        case 1: {
            [currentSection deactivate];
            [self activateTransfersTab];
            [transfersToolbarItem setImage: [NSImage imageNamed: @"transfers-active"]];
            break;
        }
        case 2: {
            [transfersController deactivate];
            [self activateStandingOrdersTab];
            [standingOrdersToolbarItem setImage: [NSImage imageNamed: @"standing-order-active"]];
            break;
        }
    }
    
    [self updateStatusbar];
}

- (IBAction)activateAccountPage: (id)sender
{
    BOOL pageHasChanged = NO;
    NSView* currentView;
    if (currentSection != nil) {
        currentView = [currentSection mainView];
    } else {
        currentView = rightSplitter;
    }
    
    [statementsButton setImage: [NSImage imageNamed: @"statementlist"]];
    [graph1Button setImage: [NSImage imageNamed: @"graph1"]];
    [graph2Button setImage: [NSImage imageNamed: @"graph2"]];
    [computingButton setImage: [NSImage imageNamed: @"computing"]];
    [rulesButton setImage: [NSImage imageNamed: @"rules"]];
    
    // Reset fetch predicate for the tree controller if we are switching away from
    // the category periods view.
    if (currentSection != nil && currentSection == categoryPeriodsController && [sender tag] != 3) {
        NSPredicate* predicate = [NSPredicate predicateWithFormat: @"parent == nil"];
        [categoryController setFetchPredicate: predicate];
        
        // Restore the previous expand state and selection (after a delay, to let the controller
        // propagate the changed content to the outline.
        [self performSelector: @selector(restoreBankAccountItemsStates) withObject: nil afterDelay: 0.1];
        
        [timeSlicer showControls: YES];
    }

    NSRect frame = [currentView frame];
    switch ([sender tag]) {
        case 0:
            // Cross-fade between the active view and the right splitter.
            if (currentSection != nil) {
                [currentSection deactivate];
                [rightSplitter setFrame: frame];
                [[rightPane animator] replaceSubview: currentView with: rightSplitter];
                currentSection = nil;
                pageHasChanged = YES;
            }
            
            [statementsButton setImage: [NSImage imageNamed: @"statementlist-active"]];
            break;
        case 1:
            if (categoryAnalysisController == nil) {
                categoryAnalysisController = [[CategoryAnalysisWindowController alloc] init];
                if ([NSBundle loadNibNamed: @"CategoryAnalysis" owner: categoryAnalysisController]) {
                    NSView* view = [categoryAnalysisController mainView];
                    view.frame = frame;
                }
                [categoryAnalysisController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
            }

            if (currentSection != categoryAnalysisController) {
                [currentSection deactivate];
                [[categoryAnalysisController mainView] setFrame: frame];
                [[rightPane animator] replaceSubview: currentView with: [categoryAnalysisController mainView]];
                currentSection = categoryAnalysisController;
                [categoryAnalysisController updateTrackingAreas];
                pageHasChanged = YES;
            }

            [graph1Button setImage: [NSImage imageNamed: @"graph1-active"]];
            break;
        case 2:
            if (categoryReportingController == nil) {
                categoryReportingController = [[CategoryRepWindowController alloc] init];
                if ([NSBundle loadNibNamed: @"CategoryReporting" owner: categoryReportingController]) {
                    NSView* view = [categoryReportingController mainView];
                    view.frame = frame;
                }
                [categoryReportingController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
            }
            
            if (currentSection != categoryReportingController) {
                [currentSection deactivate];
                [[categoryReportingController mainView] setFrame: frame];
                [[rightPane animator] replaceSubview: currentView with: [categoryReportingController mainView]];
                currentSection = categoryReportingController;
                
                // If a category is selected currently which has no child categories then move the
                // selection to its parent instead.
                Category* category = [self currentSelection];
                if ([[category children] count] < 1) {
                    [categoryController setSelectedObject: category.parent];
                }
                pageHasChanged = YES;
            }
            
            [graph2Button setImage: [NSImage imageNamed: @"graph2-active"]];
            break;
        case 3:
            if (categoryPeriodsController == nil) {
                categoryPeriodsController = [[CategoryPeriodsWindowController alloc] init];
                if ([NSBundle loadNibNamed: @"CategoryPeriods" owner: categoryPeriodsController]) {
                    NSView* view = [categoryPeriodsController mainView];
                    view.frame = frame;
                    [categoryPeriodsController connectScrollViews: accountsScrollView];
                }
                [categoryPeriodsController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
                categoryPeriodsController.outline = accountsView;
            }
            
            if (currentSection != categoryPeriodsController) {
                [currentSection deactivate];
                [[categoryPeriodsController mainView] setFrame: frame];
                [[rightPane animator] replaceSubview: currentView with: [categoryPeriodsController mainView]];
                currentSection = categoryPeriodsController;
                
                // In order to be able to line up the category entries with the grid we hide the bank
                // accounts.
                [self saveBankAccountItemsStates];

                NSPredicate* predicate = [NSPredicate predicateWithFormat: @"parent == nil && isBankAcc == NO"];
                [categoryController setFetchPredicate: predicate];
                [categoryController prepareContent];
                [timeSlicer showControls: NO];

                pageHasChanged = YES;
            }
            
            [computingButton setImage: [NSImage imageNamed: @"computing-active"]];
            break;
        case 4:
            if (categoryDefinitionController == nil) {
                categoryDefinitionController = [[CategoryDefWindowController alloc] init];
                if ([NSBundle loadNibNamed: @"CategoryDefinition" owner: categoryDefinitionController]) {
                    NSView* view = [categoryDefinitionController mainView];
                    view.frame = frame;
                }
                [categoryDefinitionController setManagedObjectContext: self.managedObjectContext];
                categoryDefinitionController.timeSliceManager = timeSlicer;
                [categoryDefinitionController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
            }
            if (currentSection != categoryDefinitionController) {
                [currentSection deactivate];
                [[categoryDefinitionController mainView] setFrame: frame];
                [[rightPane animator] replaceSubview: currentView with: [categoryDefinitionController mainView]];
                currentSection = categoryDefinitionController;
                
                // If a bank account is currently selected then switch to the not-assigned category.
                // Bankaccounts don't use rules.
                Category* category = [self currentSelection];
                if ([category isBankAccount]) {
                    [categoryController setSelectedObject: Category.nassRoot];
                }
                pageHasChanged = YES;
            }
            
            [rulesButton setImage: [NSImage imageNamed: @"rules-active"]];
            break;
    }

    if (pageHasChanged) {
        if (currentSection != nil) {
            currentSection.category = [self currentSelection];
            [currentSection setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
            [currentSection activate];
        }
        [accountsView setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark File actions

-(IBAction)export: (id)sender
{
    Category			*cat;
    
    cat = [self currentSelection];
    ExportController *controller = [ExportController controller];
    [controller startExport:cat fromDate:[timeSlicer lowerBounds] toDate:[timeSlicer upperBounds]];
}

-(IBAction)import: (id)sender
{
    ImportController *controller = [[ImportController alloc] init];
    int res = [NSApp runModalForWindow:[controller window]];
    if (res == 0) {
        NSArray *results = [NSArray arrayWithObject: controller.importResult];
        NSNotification *notif = [NSNotification notificationWithName:PecuniaStatementsNotification object: results ];
        [self statementsNotification:notif];
    }
    [controller release];
    
#ifdef AQBANKING	
    NSError *error=nil;
    
    GenericImportController *con = [[GenericImportController alloc] init];
    
    int res = [NSApp runModalForWindow: [con window]];
    if(res) {
        // save updates
        if([self.managedObjectContext save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return;
        }
    }
    [self updateBalances];
#endif	
    
}


-(BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if(flag == NO) [mainWindow makeKeyAndOrderFront: self];
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Check if there are unsent or unfinished transfers. Send unsent transfers if the users says so.
    BOOL canClose = [self checkForUnhandledTransfersAndSend];
    if (!canClose) {
        return NSTerminateCancel;
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL hideDonationMessage = [defaults boolForKey: @"DonationPopup030"];
    
    if(!hideDonationMessage) {
        DonationMessageController *controller = [[DonationMessageController alloc] init];
        BOOL donate = [controller run];
        [controller release];
        if(donate) {
            [self performSelector: @selector(donate:) withObject: self afterDelay: 0.0];
            return NSTerminateCancel;
        }
    }
    //	[[MOAssistant assistant] shutdown];
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    NSError	*error = nil;
    
    [currentSection deactivate];
    [accountsView saveLayout];
    
    // Remove explicit bindings and observers to speed up shutdown.
    [categoryController removeObserver: self forKeyPath: @"arrangedObjects.catSum"];
    [categoryAssignments removeObserver: self forKeyPath: @"selectionIndexes"];
    [statementsListView unbind: @"dataSource"];
    [statementsListView unbind: @"valueArray"];
    [categoryAssignments unbind: @"selectionIndexes"];
    [statementsListView unbind: @"selectedRows"];

    for(id<PecuniaSectionItem> item in [mainTabItems allValues]) {
        [item terminate];
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
    
    if (self.managedObjectContext) {
        if([self.managedObjectContext save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return;
        }
    }
    
    // if application shall restart, launch new task
    if(restart) {
        NSProcessInfo *info = [NSProcessInfo processInfo];
        NSArray *args = [info arguments];
        NSString *path = [args objectAtIndex:0];
        if(path) {
            int pid = [info processIdentifier];
            [NSTask launchedTaskWithLaunchPath:path arguments:[NSArray arrayWithObjects:path, [NSString stringWithFormat:@"%d", pid], nil]];
        }
    }
    
    [[MOAssistant assistant] shutdown];
    [WorkerThread finish];
}

// workaround for strange outlineView collapsing...
-(void)restoreAccountsView
{
    [accountsView restoreAll];
}

-(int)AccSize
{
    return 20;
}

-(IBAction)showLog:(id)sender
{
    //	[logController performSelector:@selector(showWindow:) onThread:[WorkerThread thread] withObject:nil waitUntilDone:NO];
    [logController setLogLevel:LogLevel_Verbous];
    [logController showWindow: self];
}

-(BankAccount*)selectedBankAccount
{
    Category	*cat = [self currentSelection];
    if(cat == nil) return nil;
    if([cat isMemberOfClass: [Category class]]) return nil;
    
    NSString *accNumber = [cat valueForKey: @"accountNumber"];
    if(accNumber == nil || [accNumber isEqual: @""]) return nil;
    return (BankAccount*)cat;
}

-(IBAction)transfer_local: (id)sender
{
    BankAccount* account = [self selectedBankAccount];
    if(account == nil) return;
    if ([[account isManual] boolValue] == YES) return;
    [transactionController transferOfType: TransferTypeStandard forAccount: account];
}

-(IBAction)donate: (id)sender
{
    BankAccount* account = [self selectedBankAccount];
    if(account == nil || [[account isManual] boolValue] == YES) {
        NSRunAlertPanel(NSLocalizedString(@"AP91", @""), 
                        NSLocalizedString(@"AP92", @""), 
                        NSLocalizedString(@"ok", @"Ok"), nil, nil);
        return;
    }
    [transactionController donateWithAccount: account];
}


-(IBAction)transfer_internal: (id)sender
{
    BankAccount* account = [self selectedBankAccount];
    if(account == nil) return;
    if ([[account isManual] boolValue] == YES) return;
    [transactionController transferOfType: TransferTypeInternal forAccount: account];
}

-(IBAction)transfer_dated: (id)sender
{
    BankAccount* account = [self selectedBankAccount];
    if(account == nil) return;
    if ([[account isManual] boolValue] == YES) return;
    [transactionController transferOfType: TransferTypeDated forAccount: account];
}

-(IBAction)transfer_eu: (id)sender
{
    BankAccount* account = [self selectedBankAccount];
    if(account == nil) return;
    if ([[account isManual] boolValue] == YES) return;
    // check if bic and iban is defined
    /*
     if([[account iban] isEqual: @""] || [[ isEqual: @""]) {
     NSRunAlertPanel(NSLocalizedString(@"AP35", @"Incomplete data"), 
     [NSString stringWithFormat: NSLocalizedString(@"AP36", @"Missing IBAN or BIC for account %@"), [account accountNumber]], 
     NSLocalizedString(@"ok", @"Ok"), nil, nil);
     return;
     }
     */ 
    
    [transactionController transferOfType: TransferTypeEU forAccount: account];
}

-(IBAction)transfer_sepa: (id)sender
{
    BankAccount* account = [self selectedBankAccount ];
    if(account == nil) return;
    if ([[account isManual ] boolValue] == YES) return;
    
    // check if bic and iban is defined
    if(account.iban == nil || account.bic == nil) {
        NSRunAlertPanel(NSLocalizedString(@"AP35", @"Incomplete data"), 
        [NSString stringWithFormat: NSLocalizedString(@"AP36", @"Missing IBAN or BIC for account %@"), account.accountNumber ], 
        NSLocalizedString(@"ok", @"Ok"), nil, nil);
        return;
    }
    
    [transactionController transferOfType: TransferTypeSEPA forAccount: account ];
}


-(Category*)currentSelection
{
    NSArray* sel = [categoryController selectedObjects];
    if (sel == nil || [sel count] != 1) {
        return nil;
    }
    return [sel objectAtIndex: 0];
}

#pragma mark -
#pragma mark Outline delegate methods

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item 
{
    return [outlineView persistentObjectForItem: item];
}

-(id)outlineView: (NSOutlineView *)outlineView itemForPersistentObject: (id)object
{
    return nil;
}

/**
 * Prevent the outline from selecting entries under certain conditions.
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if (currentSection != nil) {
        if (currentSection == categoryReportingController) {
            // If category reporting is active then don't allow selecting entries without children.
            return [outlineView isExpandable: item];
        }
        
        if (currentSection == categoryDefinitionController) {
            Category* category = [item representedObject];
            if ([category isBankAccount]) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (BOOL)outlineView:(NSOutlineView*)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard 
{
    Category		*cat;
    
    cat = [[items objectAtIndex:0] representedObject];
    if(cat == nil) return NO;
    if([cat isBankAccount]) return NO;
    if([cat isRoot]) return NO;
    if(cat == [Category nassRoot]) return NO;
    NSURL *uri = [[cat objectID] URIRepresentation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uri];
    [pboard declareTypes:[NSArray arrayWithObject: CategoryDataType] owner:self];
    [pboard setData:data forType: CategoryDataType];
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex
{
    NSPasteboard *pboard = [info draggingPasteboard];
    
    // This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
    if(childIndex >= 0) return NSDragOperationNone;
    if(item == nil) return NSDragOperationNone;
    Category* cat = (Category*)[item representedObject];
    if(cat == nil) return NSDragOperationNone;
    [[NSCursor arrowCursor] set];
    
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil]];
    if(type == nil) return NO;
    if([type isEqual: BankStatementDataType]) {
        if([cat isBankAccount]) {
            // only allow for manual accounts
            BankAccount *account = (BankAccount*)cat;
            if ([account.isManual boolValue] == YES) return NSDragOperationCopy;
            return NSDragOperationNone;
        }
        
        NSDragOperation mask = [info draggingSourceOperationMask];
        Category *scat = [self currentSelection];
        if([cat isRoot]) return NSDragOperationNone;
        // if not yet assigned: move
        if(scat == [Category nassRoot]) return NSDragOperationMove;
        if(mask == NSDragOperationCopy && cat != [Category nassRoot]) return NSDragOperationCopy;
        if(mask == NSDragOperationGeneric && cat != [Category nassRoot]) {
            [splitCursor set];
            return NSDragOperationGeneric;
        }
        return NSDragOperationMove;
    } else {
        if([cat isBankAccount]) return NSDragOperationNone;
        NSData *data = [pboard dataForType: type];
        NSURL *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
        Category *scat = (Category*)[self.managedObjectContext objectWithID: moID];
        if ([scat checkMoveToCategory:cat] == NO) return NSDragOperationNone;
        return NSDragOperationMove;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex 
{
    NSError *error;
    Category *cat = (Category*)[item representedObject];
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil]];
    if(type == nil) return NO;
    NSData *data = [pboard dataForType: type];
    
    if([type isEqual: BankStatementDataType]) {
        NSDragOperation mask = [info draggingSourceOperationMask];
        NSArray *uris = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        
        for(NSURL *uri in uris) {
            NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
            if(moID == nil) continue;
            StatCatAssignment *stat = (StatCatAssignment*)[self.managedObjectContext objectWithID: moID];
            
            if([[self currentSelection] isBankAccount]) {
                // if already assigned or copy modifier is pressed, copy the complete bank statement amount - else assign residual amount (move)
                if ([cat isBankAccount]) {
                    // drop on a manual account
                    BankAccount *account = (BankAccount*)cat;
                    [account copyStatement:stat.statement];
                    [[Category bankRoot] rollup];
                    
                } else {
                    if(mask == NSDragOperationCopy || [stat.statement.isAssigned boolValue]) [stat.statement assignToCategory: cat];
                    else if(mask == NSDragOperationGeneric) {
                        BOOL negate = NO;
                        NSDecimalNumber *residual = stat.statement.nassValue;
                        if ([residual compare:[NSDecimalNumber zero]] == NSOrderedAscending) negate = YES;
                        if (negate) residual = [[NSDecimalNumber zero] decimalNumberBySubtracting:residual];				
                        [assignValueField setObjectValue:residual];
                        [NSApp runModalForWindow: assignValueWindow];
                        residual = [NSDecimalNumber decimalNumberWithDecimal: [[assignValueField objectValue] decimalValue]];
                        if (negate) residual = [[NSDecimalNumber zero] decimalNumberBySubtracting:residual];				
                        [stat.statement assignAmount:residual toCategory:cat];
                    } else [stat.statement assignAmount: stat.statement.nassValue toCategory: cat];
                }
            } else {
                if(mask == NSDragOperationCopy) [stat.statement assignAmount: stat.value toCategory: cat];
                else [stat moveToCategory: cat];
            }
        }
        
        // update values including rollup
        [Category updateCatValues];
        
        [statementsListView updateDraggedCells];
    } else {
        NSURL *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data];        
        NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
        if (moID == nil) return NO;
        Category *scat = (Category*)[self.managedObjectContext objectWithID: moID];
        [scat setValue: cat forKey: @"parent"];
        [[Category catRoot] rollup];
    }
    //	[accountsView setNeedsDisplay: YES];
    
    // save updates
    if([self.managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return NO;
    }
    return YES;
}


-(void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
    Category *cat = [self currentSelection];
    
    if ((cat == nil) || (self.managedObjectContext == nil))
        return;
    
    if ([cat isBankAccount] && cat.accountNumber == nil) {
        if (statementsBound) {
            [categoryAssignments unbind:@"contentSet"];
            statementsBound = NO;
        }
        [categoryAssignments setContent: [cat combinedStatements]];
    } else {
        if (statementsBound == NO) {
            [categoryAssignments bind:@"contentSet" toObject:categoryController withKeyPath:@"selection.assignments" options:nil];
            statementsBound = YES;
        }
    }
    
    // set states of categorie Actions Control
    [catActions setEnabled: [cat isRemoveable] forSegment: 2];
    [catActions setEnabled: [cat isInsertable] forSegment: 1];
    
    BOOL editable = NO;
    if(![cat isBankAccount] && cat != [Category nassRoot] && cat != [Category catRoot]) {
        editable = YES;
        NSArray *sel = [categoryAssignments selectedObjects];
        if(sel && [sel count] > 0) editable = YES;
    }
    
    // value field
    [valueField setEditable: editable];
    if (editable)
    {
        [valueField setDrawsBackground: YES];
        [valueField setBackgroundColor:[NSColor whiteColor]];
    } else {
        [valueField setDrawsBackground: NO];
    }
    
    statementsListViewHost.indicatorColor = [cat categoryColor];
    
    // Update current section if the default is not active.
    if (currentSection != nil) {
        currentSection.category = cat;
    }

    [rightPane setNeedsDisplay:YES ];
    [self updateStatusbar];
}

- (void)outlineView: (NSOutlineView *)outlineView willDisplayCell: (ImageAndTextCell*)cell
     forTableColumn: (NSTableColumn *)tableColumn item: (id)item
{
    if (![[tableColumn identifier] isEqualToString: @"name"])
        return;
    
    Category *cat = [item representedObject];
    if (cat == nil) {
        return;
    }
    
    cell.swatchColor = cat.categoryColor;
    
    if (categoryImage == nil) {
        categoryImage = [NSImage imageNamed: @"catdef5_16.png"];
        moneyImage = [NSImage imageNamed: @"money_18.png"];
        moneySyncImage = [NSImage imageNamed: @"money_sync_18.png"];
        folderImage = [NSImage imageNamed: @"Bank.png"];
    }
    
    [cell setImage: categoryImage];
    
    NSInteger numberUnread = 0;
    
    if ([cat isBankAccount] && cat.accountNumber == nil) {
        [cell setImage: folderImage];
    }
    
    if ([cat isBankAccount] && cat.accountNumber != nil)
    {
        BankAccount *account = (BankAccount*)cat;
        if ([account.isManual boolValue] || [account.noAutomaticQuery boolValue])
            [cell setImage: moneyImage];
        else
            [cell setImage: moneySyncImage];
    }
    
    if (![cat isBankAccount] || [cat isRoot]) {
        numberUnread = 0;
    } else {
        numberUnread = [(BankAccount*)cat unread];
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
    
    [cell setValues: [cat catSum]
           currency: cat.currency
             unread: numberUnread
           disabled: itemIsDisabled
             isRoot: itemIsRoot];
}

#pragma mark -
#pragma mark Splitview delegate methods

- (CGFloat)splitView: (NSSplitView *)splitView constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainVSplit) {
        return 370;
    }
    if (splitView == rightSplitter) {
        return 240;
    }
    return proposedMin;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainVSplit) {
        return NSWidth([mainWindow frame]) - 800;
    }
    if (splitView == rightSplitter) {
        return NSHeight([rightSplitter frame]) - 300;
    }
    return proposedMax;
}

#pragma mark -
#pragma mark Sorting and searching statements

-(IBAction)filterStatements: (id)sender
{
    NSTextField	*te = sender;
    NSString	*searchName = [te stringValue];
    
    if ([searchName length] == 0) {
        [categoryAssignments setFilterPredicate: [timeSlicer predicateForField: @"date"]];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithFormat: @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or userInfo contains[c] %@ or value = %@",
                             searchName, searchName, searchName, [NSDecimalNumber decimalNumberWithString:searchName locale: [NSLocale currentLocale]]];
        if(pred) [categoryAssignments setFilterPredicate: pred];
    }
}

- (IBAction)sortingChanged: (id)sender
{
    if ([sender selectedSegment] == sortIndex) {
        sortAscending = !sortAscending;
    } else {
        sortAscending = NO; // Per default entries are sorted by date in decreasing order.
    }
    
    [self updateSorting];
}

#pragma mark -
#pragma mark Menu handling

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];
    
    if(idx != 0) {
        if ([item action] == @selector(export:)) return NO;
        if ([item action] == @selector(addAccount:)) return NO;
        if ([item action] == @selector(changeAccount:)) return NO;
        if ([item action] == @selector(deleteAccount:)) return NO;
        if ([item action] == @selector(enqueueRequest:)) return NO;
        if ([item action] == @selector(transfer_local:)) return NO;
        if ([item action] == @selector(transfer_eu:)) return NO;
        if ([item action] == @selector(transfer_sepa:)) return NO;
        if ([item action] == @selector(transfer_dated:)) return NO;
        if ([item action] == @selector(transfer_internal:)) return NO;
        if ([item action] == @selector(splitStatement:)) return NO;
        if ([item action] == @selector(donate:)) return NO;
        if ([item action] == @selector(deleteStatement:)) return NO;
        if ([item action] == @selector(addStatement:)) return NO;
    }
    
    if(idx == 0) {
        Category* cat = [self currentSelection];
        if(cat == nil || [cat accountNumber] == nil) {
            if ([item action] == @selector(enqueueRequest:)) return NO;
            if ([item action] == @selector(changeAccount:)) return NO;
            if ([item action] == @selector(deleteAccount:)) return NO;
            if ([item action] == @selector(transfer_local:)) return NO;
            if ([item action] == @selector(transfer_eu:)) return NO;
            if ([item action] == @selector(transfer_sepa:)) return NO;
            if ([item action] == @selector(transfer_dated:)) return NO;
            if ([item action] == @selector(transfer_internal:)) return NO;
            if ([item action] == @selector(addStatement:)) return NO;
        }
        if ([cat isKindOfClass:[BankAccount class]] ) {
            if ([[(BankAccount*)cat isManual] boolValue] == YES) {
                if ([item action] == @selector(transfer_local:)) return NO;
                if ([item action] == @selector(transfer_eu:)) return NO;
                if ([item action] == @selector(transfer_sepa:)) return NO;
                if ([item action] == @selector(transfer_dated:)) return NO;
                if ([item action] == @selector(transfer_internal:)) return NO;
            } else {
                if ([item action] == @selector(addStatement:)) return NO;
            }
        }
        
        if ([item action] == @selector(deleteStatement:)) {
            if ([cat isBankAccount] == NO) return NO;
            if ([[categoryAssignments selectedObjects] count] != 1) return NO;
        }
        if ([item action] == @selector(splitStatement:)) {
            if ([[categoryAssignments selectedObjects] count] != 1) return NO;
        }
        if(requestRunning && [item action] == @selector(enqueueRequest:)) return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark Category management

-(void)updateNotAssignedCategory
{
    NSError *error = nil;
    
    // fetch all bank statements
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    NSArray *stats = [self.managedObjectContext executeFetchRequest:request error:&error];
    if(error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    for (BankStatement *stat in stats) {
        [stat updateAssigned];
    }
}

- (void)deleteCategory: (id)sender
{
    Category *cat = [self currentSelection];
    if(cat == nil) return;
    
    if([cat isRemoveable] == NO) return;
    NSArray *stats = [[cat mutableSetValueForKey: @"assignments"] allObjects];
    StatCatAssignment *stat;
    
    if([stats count] > 0) {
        int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP84", @"Delete category"),
                                          NSLocalizedString(@"AP85", @"Category '%@' still has %d assigned transactions. Do you want to proceed anyway?"),
                                          NSLocalizedString(@"no", @"No"),
                                          NSLocalizedString(@"yes", @"Yes"),
                                          nil,
                                          [cat localName],
                                          [stats count],
                                          nil
                                          );
        if(res != NSAlertAlternateReturn) return;
    }
    
    //  Delete bank statements from category first.
    for (stat in stats) {
        [stat remove];
    }
    [categoryController remove: cat];
    [Category updateCatValues];
    
    // workaround: NSTreeController issue: when an item is removed and the NSOutlineViewSelectionDidChange notification is sent,
    // the selectedObjects: message returns the wrong (the old) selection
    [self performSelector:@selector(outlineViewSelectionDidChange:) withObject: nil afterDelay:0 ];    
}

- (void)addCategory: (id)sender
{
    Category *cat = [self currentSelection];
    if(cat.isBankAccount) return;
    if(cat.isRoot) [categoryController addChild: sender]; else	[categoryController add: sender]; 
    [accountsView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];
}

- (void)insertCategory: (id)sender
{
    Category *cat = [self currentSelection];
    if([cat isInsertable] == NO) return;
    [categoryController addChild: sender];
    [accountsView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];
}

-(IBAction)manageCategories:(id)sender
{
    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
    switch(clickedSegmentTag) {
        case 0: [self addCategory: sender]; break;
        case 1: [self insertCategory: sender]; break;
        case 2: [self deleteCategory: sender]; break;
        default: return;
    }
    [currentSection activate]; // Notifies the current section to updates values if necessary.
}

-(NSString*)autosaveNameForTimeSlicer: (TimeSliceManager*)tsm
{
    return @"AccMainTimeSlice";
}

-(void)timeSliceManager: (TimeSliceManager*)tsm changedIntervalFrom: (ShortDate*)from to: (ShortDate*)to
{
    if (self.managedObjectContext == nil) return;
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];
    if(idx) return;
    Category *cat = [Category catRoot];
    [Category setCatReportFrom: from to: to];
    // change filter
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(statement.date => %@) AND (statement.date <= %@)", [from lowDate], [to highDate]];
    [categoryAssignments setFilterPredicate: predicate];
    
    [cat rebuildValues];
    [cat rollup];
    
    // Update current section if the default is not active.
    if (currentSection != nil) {
        [currentSection setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
    }

    [self updateStatusbar];
}

-(void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
    if([aNotification object] == accountsView) {
        Category *cat = [self currentSelection];
        accountsView.saveCatName = [cat name];
    }	
    if([aNotification object] == valueField) {
        NSArray *sel = [categoryAssignments selectedObjects];
        if(sel && [sel count] == 1) {
            StatCatAssignment *stat = [sel objectAtIndex:0];
            self.saveValue = stat.value;
        }
    }
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    // Category name changed
    if([aNotification object] == accountsView) {
        Category *cat = [self currentSelection];
        if([cat name] == nil) {
            [cat setValue: accountsView.saveCatName forKey: @"name"];
        }
        [categoryController resort];
        if(cat) [categoryController setSelectedObject: cat];
    }
    
    // Value field changed (todo: replace by key value observation).
    if ([aNotification object] == valueField)
    {
        NSArray *sel = [categoryAssignments selectedObjects];
        if(sel && [sel count] == 1)
        {
            StatCatAssignment *stat = [sel objectAtIndex:0];
            
            // do some checks
            // amount must have correct sign
            NSDecimal d1 = [stat.statement.value decimalValue];
            NSDecimal d2 = [stat.value decimalValue];
            if (d1._isNegative != d2._isNegative)
            {
                NSBeep();
                stat.value = self.saveValue;
                return;
            }
            
            // amount must not be higher than original amount
            if (d1._isNegative)
            {
                if ([stat.value compare:stat.statement.value] == NSOrderedAscending)
                {
                    NSBeep();
                    stat.value = self.saveValue;
                    return;
                }
            }
            else
            {
                if ([stat.value compare:stat.statement.value] == NSOrderedDescending) {
                    NSBeep();
                    stat.value = self.saveValue;
                    return;
                }
            }
            
            // [Category updateCatValues] invalidates the selection we got. So re-set it first and then update.
            [categoryAssignments setSelectedObjects:sel];
            
            [stat.statement updateAssigned];
            Category *cat = [self currentSelection];
            if(cat !=  nil)
            {
                [cat invalidateBalance];
                [Category updateCatValues];
                [statementsListView updateSelectedCells];
            }
        }
    }
    if ([aNotification object] == assignValueField) {
        [NSApp stopModalWithCode:0];
        [assignValueWindow orderOut:self];
    }
}

-(void)setRestart
{
    restart = YES;
}

-(IBAction)deleteStatement: (id)sender
{
    BOOL duplicate = NO;
    NSError *error = nil;
    BankAccount *account = (BankAccount*)[self currentSelection];
    if(account == nil) return;
    
    // get selected statement
    NSArray *stats = [categoryAssignments selectedObjects];
    if([stats count] != 1) return;
    BankStatement *stat = [[stats objectAtIndex:0] statement];
    
    // check if statement is duplicate. Select all statements with same date
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date = %@)", account, stat.date ];
    [request setPredicate:predicate];
    stats = [self.managedObjectContext executeFetchRequest:request error:&error];
    if(error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    
    BankStatement *iter;
    for(iter in stats) {
        if(iter != stat && [iter matches: stat]) {
            duplicate = YES;
            break;
        }
    }
    
    int res;
    BOOL deleteStatement = NO;
    if(duplicate) {
        res = NSRunAlertPanel(NSLocalizedString(@"AP68", @""),
                              NSLocalizedString(@"AP69", @""),
                              NSLocalizedString(@"yes", @"Yes"),
                              NSLocalizedString(@"no", @"No"),
                              nil);
        if(res == NSAlertDefaultReturn) {
            deleteStatement = YES;
        }
    } else {
        res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP68", @""),
                                      NSLocalizedString(@"AP70", @""),
                                      NSLocalizedString(@"no", @"No"),
                                      NSLocalizedString(@"yes", @"Yes"),
                                      nil);
        if(res == NSAlertAlternateReturn) {
            deleteStatement = YES;
        }
    }
    
    if (deleteStatement == YES) {
        [self.managedObjectContext deleteObject: stat];
        
        // special behaviour for top bank accounts
        if(account.accountNumber == nil) {
            [self.managedObjectContext processPendingChanges];
            [categoryAssignments setContent: [account combinedStatements]];
        }
        
        // rebuild saldos - only for manual accounts
        if (account.userId == nil) {
            NSPredicate *saldoPredicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date > %@)", account, stat.date ];
            [request setPredicate: saldoPredicate];
            stats = [self.managedObjectContext executeFetchRequest:request error:&error];
            if(error) {
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
                return;
            }
            
            for(BankStatement *s in stats) {
                s.saldo = [s.saldo decimalNumberBySubtracting:stat.value];
            }
            
            account.balance = [account.balance decimalNumberBySubtracting:stat.value];
            [[Category bankRoot] rollup];
        }
        
        //		[self.managedObjectContext deleteObject: stat];
    }
    
}

-(void)splitStatement:(id)sender
{
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];
    if (idx == 0) {
        NSArray *sel = [categoryAssignments selectedObjects];
        if (sel != nil && [sel count] == 1) {
            StatSplitController *splitController = [[[StatSplitController alloc] initWithStatement: [[sel objectAtIndex:0] statement]
                                                                                               view: accountsView] autorelease];
            [splitController showWindow:mainWindow];
        }
    }
}

-(IBAction)addStatement: (id)sender
{
    Category* cat = [self currentSelection];
    if (cat == nil) return;
    if (cat.accountNumber == nil) return;
    
    BankStatementController *statementController = [[[BankStatementController alloc] initWithAccount: (BankAccount*)cat statement: nil] autorelease];
    
    int res = [NSApp runModalForWindow: [statementController window]];
    if(res) {
        [ categoryAssignments rearrangeObjects];
        
        // statement was created
        NSError *error = nil;
        
        // save updates
        if([self.managedObjectContext save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return;
        }
    }
}

-(IBAction)splitPurpose:(id)sender
{
    Category* cat = [self currentSelection];
    
    PurposeSplitController *splitController = [[[PurposeSplitController alloc] initWithAccount:(BankAccount*)cat] autorelease];
    [NSApp runModalForWindow: [splitController window]];
}

#pragma mark -
#pragma mark Miscellaneous code

/**
 * Saves the expand states of the top bank account node and all its children.
 * Also saves the current selection if it is on a bank account.
 */
- (void)saveBankAccountItemsStates
{
    Category* category = [self currentSelection];
    if ([category isBankAccount]) {
        lastSelection = category;
        [categoryController setSelectedObject: Category.nassRoot];
    }
    bankAccountItemsExpandState = [[NSMutableArray array] retain];
    NSUInteger row, numberOfRows = [accountsView numberOfRows];
    
    for (row = 0 ; row < numberOfRows; row++)
    {
        id item = [accountsView itemAtRow: row];
        Category *category = [item representedObject];
        if (![category isBankAccount]) {
            break;
        }
        if ([accountsView isItemExpanded: item])
            [bankAccountItemsExpandState addObject: category];
    }
}

/**
 * Restores the previously saved expand states of all bank account nodes and sets the
 * last selection if it was on a bank account node.
 */
- (void)restoreBankAccountItemsStates
{
    NSUInteger row, numberOfRows = [accountsView numberOfRows];
    for (Category *savedItem in bankAccountItemsExpandState) {
        for (row = 0 ; row < numberOfRows ; row++) {
            id item = [accountsView itemAtRow: row];
            Category *object = [item representedObject];
            if ([object.name isEqualToString: savedItem.name]) {
                [accountsView expandItem: item];
                numberOfRows = [accountsView numberOfRows];
                break;
            }
        }
    }
    [bankAccountItemsExpandState release];
    bankAccountItemsExpandState = nil;
    
    // Restore the last selection, but only when selecting the item is allowed.
    if (lastSelection != nil && currentSection != categoryReportingController && currentSection != categoryDefinitionController) {
        [categoryController setSelectedObject: lastSelection];
    }
    lastSelection = nil;
}

-(void)syncAllAccounts
{
    NSError *error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"allBankAccounts"];
    NSArray *selectedAccounts = [self.managedObjectContext executeFetchRequest:request error:&error];
    if(error) {
        NSLog(@"Read bank accounts error on automatic sync");
        return;
    }
    
    // now selectedAccounts has all selected Bank Accounts
    BankAccount *account;
    NSMutableArray *resultList = [NSMutableArray arrayWithCapacity: [selectedAccounts count]];
    for(account in selectedAccounts) {
        if ([account.noAutomaticQuery boolValue] == YES) continue;
        
        BankQueryResult *result = [[BankQueryResult alloc] init];
        result.accountNumber = account.accountNumber;
        result.accountSubnumber = account.accountSuffix;
        result.bankCode = account.bankCode;
        result.userId = account.userId;
        result.account = account;
        [resultList addObject: [result autorelease]];
    }
    
    // prepare UI
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: NO];
    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP41", @"Load statements...") removeAfter:0];
    
    // get statements in separate thread
    autoSyncRunning = YES;
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(statementsNotification:) name: PecuniaStatementsNotification object: nil];
    [[HBCIClient hbciClient] getStatements: resultList];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: [NSDate date] forKey: @"lastSyncDate"];
    
    // if autosync, setup next timer event
    BOOL autoSync = [defaults boolForKey: @"autoSync"];
    if(autoSync) {
        NSDate *syncTime = [defaults objectForKey:@"autoSyncTime"];
        if(syncTime == nil) {
            NSLog(@"No autosync time defined");
            return;
        }
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        // set date +24Hr
        NSDateComponents *comps1 = [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate: [NSDate dateWithTimeIntervalSinceNow: 86400]];
        NSDateComponents *comps2 = [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: syncTime];
        [comps1 setHour: [comps2 hour] ];
        [comps1 setMinute: [comps2 minute]];
        NSDate *syncDate = [calendar dateFromComponents: comps1];
        // syncTime in future: setup Timer
        NSTimer *timer = [[NSTimer alloc] initWithFireDate:syncDate 
                                                   interval:0.0 
                                                     target:self 
                                                   selector:@selector(autoSyncTimerEvent) 
                                                   userInfo:nil 
                                                    repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [timer release];
        [calendar release];
    }
}

-(void)checkForAutoSync
{
    BOOL syncDone = NO;
    NSDate *syncTime;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL syncAtStartup = [defaults boolForKey: @"syncAtStartup"];
    BOOL autoSync = [defaults boolForKey: @"autoSync"];
    if(!(autoSync || syncAtStartup)) return;
    if(autoSync) {
        syncTime = [defaults objectForKey:@"autoSyncTime"];
        if(syncTime == nil) {
            NSLog(@"No autosync time defined");
            autoSync = NO;
        }
    }
    NSDate *lastSyncDate = [defaults objectForKey: @"lastSyncDate"];
    ShortDate *d1 = [ShortDate dateWithDate: lastSyncDate];
    ShortDate *d2 = [ShortDate dateWithDate: [NSDate date]];
    if((d1 == nil || [d1 compare: d2] != NSOrderedSame) && syncAtStartup) {
        // no sync done today. If in startup, do immediate sync
        [self performSelector: @selector(syncAllAccounts) withObject: nil afterDelay: 5.0];
        syncDone = YES;
    }
    
    if(!autoSync) return;
    // get today's sync time. 
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    NSDateComponents *comps1 = [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate: [NSDate date]];
    NSDateComponents *comps2 = [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: syncTime];
    
    [comps1 setHour: [comps2 hour] ];
    [comps1 setMinute: [comps2 minute]];
    NSDate *syncDate = [calendar dateFromComponents: comps1];
    // if syncTime has passed, do immediate sync
    if([syncDate compare: [NSDate date]] == NSOrderedAscending) {
        if(!syncDone) [self performSelector: @selector(syncAllAccounts) withObject: nil afterDelay: 5.0];
    } else {
        // syncTime in future: setup Timer
        NSTimer *timer = [[[NSTimer alloc] initWithFireDate: syncDate 
                                                   interval: 0.0 
                                                     target: self 
                                                   selector: @selector(autoSyncTimerEvent) 
                                                   userInfo: nil 
                                                    repeats: NO] autorelease];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
    [calendar release];
}

-(IBAction)showLicense: (id)sender
{
    NSString *path = [[NSBundle mainBundle] pathForResource: @"gpl-2.0" ofType: @"txt"];
    [[NSWorkspace sharedWorkspace] openFile: path];
}

-(void)applicationWillFinishLaunching:(NSNotification *)notification
{
    if ([[MOAssistant assistant] encrypted]) {
        StatusBarController *sc = [StatusBarController controller];
        [sc startSpinning];
        [sc setMessage: NSLocalizedString(@"AP110", @"Open database...") removeAfter:0];
        
        @try {
            [[MOAssistant assistant] openImage];
            self.managedObjectContext = [[MOAssistant assistant] context];
        }
        @catch(NSError* error) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            [NSApp terminate: self];
        }
        [self publishContext];
        [sc stopSpinning];
        [sc clearMessage];
    }
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self checkForAutoSync];
}

-(void)autoSyncTimerEvent:(NSTimer*)theTimer
{
    [self syncAllAccounts];
}

-(void)setEncrypted:(BOOL)encrypted
{
    if(encrypted) [lockImage setHidden:NO]; else [lockImage setHidden:YES];
}

- (BOOL)checkForUnhandledTransfersAndSend
{
    // Check for a new transfer not yet finished.
    if ([transfersController editingInProgress]) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP114", @""),
                                  NSLocalizedString(@"AP111.2", @""),
                                  NSLocalizedString(@"AP411", @""),
                                  NSLocalizedString(@"AP113", @""),
                                  nil
                                  );
        if (res == NSAlertAlternateReturn) {
            NSButton *dummy = [[NSButton alloc] init];
            dummy.tag = 1;
            [self activateMainPage: dummy];
            [dummy release];
            return NO;
        }
        [transfersController cancelEditing];
    }
    
    // Check for unsent transfers.
    NSError *error = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"Transfer" inManagedObjectContext: self.managedObjectContext];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity: entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isSent = NO"];
    [request setPredicate: predicate];
    NSArray *transfers = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error || [transfers count] == 0) return YES;
    
    int res = NSRunAlertPanel(NSLocalizedString(@"AP114", @""),
                              NSLocalizedString(@"AP111", @""),
                              NSLocalizedString(@"close anyway", @""),
                              NSLocalizedString(@"AP113", @""),
                              NSLocalizedString(@"AP112", @""),
                              nil
                              );
    if (res == NSAlertDefaultReturn)
    {
        return YES;
    }
    if (res == NSAlertAlternateReturn) {
        NSButton *dummy = [[NSButton alloc] init];
        dummy.tag = 1;
        [self activateMainPage: dummy];
        [dummy release];
        return NO;
    }
    
    // send transfers
    BOOL sent = [[HBCIClient hbciClient] sendTransfers: transfers];
    if(sent) {
        // save updates
        if([self.managedObjectContext save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return NO;
        }
    }
    return NO;
}

-(void)updateUnread
{
    NSTableColumn* tc = [accountsView tableColumnWithIdentifier: @"name"];
    if(tc) {
        ImageAndTextCell *cell = (ImageAndTextCell*)[tc dataCell];
        // update unread information
        NSInteger maxUnread = [BankAccount maxUnread];
        [cell setMaxUnread:maxUnread];
    }
}

- (void)printCurrentAccountsView
{
    if (currentSection == nil) {
        NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo];
        [printInfo setTopMargin: 45];
        [printInfo setBottomMargin: 45];
        NSPrintOperation *printOp;
        NSView *view = [[[BankStatementPrintView alloc] initWithStatements: [categoryAssignments arrangedObjects] printInfo: printInfo] autorelease];
        printOp = [NSPrintOperation printOperationWithView:view printInfo: printInfo];
        [printOp setShowsPrintPanel: YES];
        [printOp runOperation];
        
        return;
    }

    [currentSection print];
}

-(IBAction)printDocument:(id)sender
{
    switch ([mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]]) {
        case 0:
            [self printCurrentAccountsView];
            break;
        case 1:
        {
            NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo];
            [printInfo setTopMargin:45];
            [printInfo setBottomMargin:45];
            [printInfo setHorizontalPagination:NSFitPagination];
            [printInfo setVerticalPagination:NSFitPagination];
            NSPrintOperation *printOp;
            printOp = [NSPrintOperation printOperationWithView:[[mainTabView selectedTabViewItem] view] printInfo: printInfo];
            [printOp setShowsPrintPanel:YES];
            [printOp runOperation];
            
            break;
        }
        default:
        {
            id <PecuniaSectionItem> item = [mainTabItems objectForKey: [[mainTabView selectedTabViewItem] identifier]];
            [item print];
        }
    }
}

-(IBAction)repairSaldo:(id)sender
{
    NSError *error = nil;
    BankAccount *account = nil;
    Category* cat = [self currentSelection];
    if (cat == nil || cat.accountNumber == nil) return;
    account = (BankAccount*)cat;
	
	[account repairStatementBalances ];
    
    // save updates
    if([self.managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }	
}

-(IBAction)getAccountBalance:(id)sender
{
    NSError *error = nil;
	PecuniaError *pec_err = nil;
    BankAccount *account = nil;
    Category* cat = [self currentSelection];
    if (cat == nil || cat.accountNumber == nil) return;
    account = (BankAccount*)cat;
	
	pec_err = [[HBCIClient hbciClient ] getBalanceForAccount:account ];
    if (pec_err) return;
	
    // save updates
    if([self.managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }		
}

-(IBAction)resetIsNewStatements:(id)sender
{
    NSError *error = nil;
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isNew = 1"];
    [request setPredicate:predicate];
    NSArray *statements = [context executeFetchRequest:request error:&error];
    for(BankStatement *stat in statements) stat.isNew = [NSNumber numberWithBool:NO];
    
    // save updates
    if([self.managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }
    [self updateUnread];
    [accountsView setNeedsDisplay: YES];
    [categoryAssignments rearrangeObjects];
}

-(IBAction)showAboutPanel:(id)sender
{
    if (aboutWindow == nil) {
        [NSBundle loadNibNamed: @"About" owner: self];
        
        NSBundle* mainBundle = [NSBundle mainBundle];
        NSString* path = [mainBundle pathForResource: @"Credits" ofType: @"rtf"];
        [aboutText readRTFDFromFile: path];
        [versionText setStringValue: [NSString stringWithFormat: @"Version %@ (%@)",
                                      [mainBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                      [mainBundle objectForInfoDictionaryKey: @"CFBundleVersion"]
                                     ]];
        [copyrightText setStringValue: [mainBundle objectForInfoDictionaryKey: @"NSHumanReadableCopyright"]];
        gradient.fillColor = [NSColor whiteColor];
        
        // Delayed show gives the about window time to finish initialization. Otherwise it will
        // simply pop up without animation first time it is shown.
        [aboutWindow performSelector: @selector(fadeIn) withObject: nil afterDelay: 0.05];
        return;
    }
    
    [aboutWindow fadeIn];
}

- (IBAction)toggleFullscreenIfSupported: (id)sender
{
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_6
    if (runningOnLionOrLater) {
        [mainWindow toggleFullScreen: mainWindow];
    }
#endif
}

-(void)migrate
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL migrated10 = [defaults boolForKey:@"Migrated10"];
    if (migrated10 == NO) {
		
		NSError *error = nil;
		NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
		NSArray *bankUsers = [BankUser allUsers ];		
		NSArray *users = [[HBCIClient hbciClient ] getOldBankUsers ];
		
		for(User *user in users) {
			BOOL found = NO;
			for(BankUser *bankUser in bankUsers) {
				if ([user.userId isEqualToString:bankUser.userId ] &&
					[user.bankCode isEqualToString:bankUser.bankCode ] && 
					(user.customerId == nil || [user.customerId isEqualToString:bankUser.customerId ])) {
					found = YES;
				}
			}
			if (found == NO) {
				// create BankUser
				BankUser *bankUser = [NSEntityDescription insertNewObjectForEntityForName:@"BankUser" inManagedObjectContext:context];
				bankUser.name = user.name;
				bankUser.bankCode = user.bankCode;
				bankUser.bankName = user.bankName;
				bankUser.bankURL = user.bankURL;
				bankUser.port = user.port;
				bankUser.hbciVersion = user.hbciVersion;
				bankUser.checkCert = [NSNumber numberWithBool:user.checkCert];
				bankUser.country = user.country;
				bankUser.userId = user.userId;
				bankUser.customerId = user.customerId;
                bankUser.secMethod = [NSNumber numberWithInt:SecMethod_PinTan ];
			}
		}
        
        // BankUser Konten zuordnen
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:context];
        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"userId != nil", self ];
        [request setPredicate:predicate];
        NSArray *accounts = [context executeFetchRequest:request error:&error];
        
        for(BankAccount *account in accounts) {
            BankUser *user = [BankUser userWithId:account.userId bankCode:account.bankCode ];
            if (user) {
                NSMutableSet *users = [account mutableSetValueForKey:@"users" ];
                [users addObject:user ];
            }
        }
	
		if([context save:&error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	
	        
        [defaults setBool:YES forKey:@"Migrated10"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == categoryController) {
        [accountsView setNeedsDisplay: YES];
    } else {
        if (object == categoryAssignments) {
            if ([keyPath compare: @"selectionIndexes"] == NSOrderedSame) {
                // Selection did change. If the currently selected entry is a new one remove the "new" mark.
                NSEnumerator *enumerator = [[categoryAssignments selectedObjects] objectEnumerator];
                StatCatAssignment* stat = nil;
                NSDecimalNumber* firstValue = nil;
                while ((stat = [enumerator nextObject]) != nil) {
                    if (firstValue == nil) {
                        firstValue = stat.statement.value;
                    }
                    if ([stat.category isBankAccount] && ![stat.category isRoot])
                    {
                        BankAccount* account = (BankAccount*)stat.category;
                        if ([stat.statement.isNew boolValue])
                        {
                            stat.statement.isNew = [NSNumber numberWithBool: NO];
                            account.unread = account.unread - 1;
                            if (account.unread == 0) {
                                [self updateUnread];
                            }
                            [accountsView setNeedsDisplay: YES];
                        }
                    }
                }
                
                // Check for the type of transaction and adjust remote name display accordingly.
                if ([firstValue compare: [NSDecimalNumber zero]] == NSOrderedAscending) {
                    [remoteNameLabel setStringValue: NSLocalizedString(@"AP134", "")];
                } else {
                    [remoteNameLabel setStringValue: NSLocalizedString(@"AP135", "")];
                }
                
                [statementDetails setNeedsDisplay:YES ];
                [self updateStatusbar];
            }
        }
    }
}

- (void)updateSorting
{
    [sortControl setImage: nil forSegment: sortIndex];
    sortIndex = [sortControl selectedSegment];
    NSImage *sortImage = sortAscending ? [NSImage imageNamed: @"sort-indicator-inc"] : [NSImage imageNamed: @"sort-indicator-dec"];
    [sortControl setImage: sortImage forSegment: sortIndex];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue: [NSNumber numberWithInt: sortIndex] forKey: @"mainSortIndex"];
    [userDefaults setValue: [NSNumber numberWithBool: sortAscending] forKey: @"mainSortAscending"];
    
    NSString *key;
    switch (sortIndex) {
        case 1:
            statementsListView.showHeaders = false;
            key = @"statement.remoteName";
            break;
        case 2:
            statementsListView.showHeaders = false;
            key = @"statement.purpose";
            break;
        case 3:
            statementsListView.showHeaders = false;
            key = @"statement.categoriesDescription";
            break;
        case 4:
            statementsListView.showHeaders = false;
            key = @"statement.value";
            break;
        default:
            statementsListView.showHeaders = true;
            key = @"statement.date";
            break;
    }
    [categoryAssignments setSortDescriptors:
     [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: key ascending: sortAscending] autorelease]]];
}

+(BankingController*)controller
{
    return bankinControllerInstance;
}

//--------------------------------------------------------------------------------------------------

@end
