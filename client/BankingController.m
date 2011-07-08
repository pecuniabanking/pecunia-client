//
//  BankingController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "BankingController.h"
#import "ABAccount.h"
#import "NewBankUserController.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "Category.h"
#import "PreferenceController.h"
#import "AccountSettingsController.h"
#import "MOAssistant.h"
#import "TransactionController.h"
#import "LogController.h"
#import "CatAssignClassification.h"
#import "ExportController.h"
#import "CatDefWindowController.h"
#import "MCEMOutlineViewLayout.h"
#import "AccountDefController.h"
#import "TimeSliceManager.h"
#import "MCEMTreeController.h"
#import "WorkerThread.h"
#import "BSSelectWindowController.h"
#import "StatusBarController.h"
#import "MCEMTableView.h"
#import "DonationMessageController.h"
#import "BankQueryResult.h"
#import "CategoryView.h"
#import "HBCIClient.h"
#import "StatCatAssignment.h"
#import "PecuniaError.h"
#import	"StatSplitController.h"
#import "MigrationManagerWorkaround.h"
#import "ShortDate.h"
#import "BankStatementController.h"
#import "AccountChangeController.h"
#import "TransferListController.h"
#import "PurposeSplitController.h"
#import "TransferTemplateController.h"
#import "BankStatementPrintView.h"
#import "MainTabViewItem.h"
#import "GenericImportController.h"
#import "ImageAndTextCell.h"
#import "DateAndValutaCell.h"
#import "AmountCell.h"
#import "DockIconController.h"

#define _expandedRows @"EMT_expandedRows"
#define _accountsViewSD @"EMT_accountsSorting"
#define _accountsTreeWidth @"EMT_accountsTreeWidth"

#define _mainVSplit @"mainVSplit"
#define _mainHSplit @"mainHSplit"

#define BankStatementDataType	@"BankStatementDataType"
#define CategoryDataType		@"CategoryDataType"

// Singleton simulation
static BankingController	*con;

@implementation BankingController

@synthesize saveValue;
@synthesize managedObjectContext;
@synthesize dockIconController;

-(id)init
{
	HBCIClient *client = nil;
	
	[super init ];
	if(con) [con release ]; 
	con = self;
	restart = NO;
	requestRunning = NO;
	statementsBound = YES;
	mainTabItems = [[NSMutableDictionary dictionaryWithCapacity:10 ] retain ];
	
	[Category setCatReportFrom: [ShortDate dateWithYear: 2009 month:1 day:1 ] to: [ShortDate distantFuture ] ];

	// load context & model
	@try {
		model   = [[MOAssistant assistant ] model ];
		self.managedObjectContext = [[MOAssistant assistant ] context ];
	}
	@catch(NSError* error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		[NSApp terminate: self ];
	}

	@try {
		client = [HBCIClient hbciClient ];
	}
	@catch (NSError *error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		[NSApp terminate: self ];
	}
	
	logController = [LogController logController ];

	return self;
}

-(void)awakeFromNib
{
	NSTableColumn	*tc;
/*	
	// green color for transactions view
	tc = [transactionsView tableColumnWithIdentifier: @"value" ];
	if(tc) {
		NSCell	*cell = [tc dataCell ];
		NSNumberFormatter	*form = [cell formatter ];
		if(form) {
			NSDictionary *newAttrs = [NSDictionary dictionaryWithObjectsAndKeys: 
				[NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100], @"NSColor", nil ];
			[form setTextAttributesForPositiveValues: newAttrs ];
		}
	}
	// green color for transactions view	
	tc = [transactionsView tableColumnWithIdentifier: @"nassValue" ];
	if(tc) {
		NSCell	*cell = [tc dataCell ];
		NSNumberFormatter	*form = [cell formatter ];
		if(form) {
			NSDictionary *newAttrs = [NSDictionary dictionaryWithObjectsAndKeys: 
									  [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100], @"NSColor", nil ];
			[form setTextAttributesForPositiveValues: newAttrs ];
		}
	}
	tc = [transactionsView tableColumnWithIdentifier: @"saldo" ];
	if(tc) {
		NSCell	*cell = [tc dataCell ];
		NSNumberFormatter	*form = [cell formatter ];
		if(form) {
			NSDictionary *newAttrs = [NSDictionary dictionaryWithObjectsAndKeys: 
									  [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100], @"NSColor", nil ];
			[form setTextAttributesForPositiveValues: newAttrs ];
		}
	}
	
	NSCell	*cell = [valueField cell ];
	if(cell) {
		NSNumberFormatter	*form = [cell formatter ];
		if(form) {
			NSDictionary *newAttrs = [NSDictionary dictionaryWithObjectsAndKeys: 
									  [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100], @"NSColor", nil ];
			[form setTextAttributesForPositiveValues: newAttrs ];
		}
	}

	cell = [nassValueField cell ];
	if(cell) {
		NSNumberFormatter	*form = [cell formatter ];
		if(form) {
			NSDictionary *newAttrs = [NSDictionary dictionaryWithObjectsAndKeys: 
									  [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100], @"NSColor", nil ];
			[form setTextAttributesForPositiveValues: newAttrs ];
		}
	}
*/	
	tc = [accountsView tableColumnWithIdentifier: @"name" ];
	if(tc) {
		ImageAndTextCell *cell = (ImageAndTextCell*)[tc dataCell ];
		if (cell) [cell setFont: [NSFont fontWithName: @"Lucida Grande" size: 12 ] ];
		// update unread information
		NSInteger maxUnread = [BankAccount maxUnread ];
		[cell setMaxUnread:maxUnread ];
	}
	
	// sort descriptor for transactions view
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"statement.date" ascending:NO] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[transactionController setSortDescriptors: sds ];

	// sort descriptor for accounts view
	sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	sds = [NSArray arrayWithObject:sd];
	[categoryController setSortDescriptors: sds ];
	
	// status (content) bar
	[mainWindow setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
	[mainWindow setContentBorderThickness:30.0f forEdge:NSMinYEdge];
	
	if (self.managedObjectContext) [self publishContext ];
	
	// set toolbar selection state
	int i;
	NSArray* items = [toolbar items ];
	for(i = 0; i < [items count ]; i++) {
		NSToolbarItem *item = [items objectAtIndex: i ];
		if([item tag ] == 10) { [toolbar setSelectedItemIdentifier: [item itemIdentifier ] ]; break; }
	}

	// register Drag'n Drop
	[transactionsView registerForDraggedTypes: [NSArray arrayWithObject: BankStatementDataType ] ];
	[accountsView registerForDraggedTypes: [NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil ] ];
	
	// set lock image
	[self setEncrypted: [[MOAssistant assistant ] encrypted ] ];
	[mainWindow setContentMinSize:NSMakeSize(800, 450) ];
	splitCursor = [[NSCursor alloc ] initWithImage:[NSImage imageNamed: @"cursor.png" ] hotSpot:NSMakePoint(0, 0)];
	[WorkerThread init ];
	
	[self migrate ];
	[categoryController addObserver:self forKeyPath:@"arrangedObjects.catSum" options:0 context:NULL];	
}

-(void)publishContext
{
	NSError *error=nil;

	[categoryController setManagedObjectContext:self.managedObjectContext ];
	[transactionController setManagedObjectContext:self.managedObjectContext ];
	
	// repair Category Root
	[self repairCategories ];
	
	// update Bank Accounts if needed
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	BOOL accUpdated = [defaults boolForKey:@"accountsUpdated" ];
	if (accUpdated == NO) {
		[self updateBankAccounts:nil ];
	}
	
	[self updateBalances ];
	
	// update unread information
	[self updateUnread ];
	
    [categoryController fetchWithRequest:nil merge:NO error:&error];
	[transferListController setManagedObjectContext:self.managedObjectContext ];
	[catDefWinController setManagedObjectContext:self.managedObjectContext ];
	[transferWindowController setManagedObjectContext:self.managedObjectContext ];
	[timeSlicer updateDelegate ];
	[self performSelector: @selector(restoreAccountsView) withObject: nil afterDelay: 0.0];
	dockIconController = [[DockIconController alloc ] initWithManagedObjectContext:self.managedObjectContext ];
}

-(void)updateBankAccounts:(NSArray*)hbciAccounts
{
	NSError	*error = nil;
	int		i,j;
	BOOL	found;
	
	if (hbciAccounts == nil) hbciAccounts = [[HBCIClient hbciClient ] accounts ];	
//	NSArray* hbciAccounts = [[HBCIClient hbciClient ] accounts ];
	
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"allBankAccounts"];
	NSArray *tmpAccounts = [self.managedObjectContext executeFetchRequest:request error:&error];
	if( error != nil || tmpAccounts == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	NSMutableArray*	bankAccounts = [NSMutableArray arrayWithArray: tmpAccounts ];
	
	for(i=0; i < [hbciAccounts count ]; i++) {
		ABAccount* acc = [hbciAccounts objectAtIndex: i ];
		BankAccount *account;
		
		//lookup
		found = NO;
		for(j=0; j<[bankAccounts count ]; j++) {
			account = [bankAccounts objectAtIndex: j ];
			if( [account.bankCode isEqual: acc.bankCode ] &&
				[account.accountNumber isEqual: acc.accountNumber ]) {
				found = YES;
				break;
			}
		}
		if (found == YES) {
			// Account was found: update user- and customer-id
			account.userId = acc.userId;
			account.customerId = acc.customerId;
			account.collTransfer = [NSNumber numberWithBool:acc.collTransfer ];
		} else {
			// Account was not found: create it
			BankAccount* bankRoot = [self getBankNodeWithAccount: acc inAccounts: bankAccounts ];
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
			bankAccount.isBankAcc = [NSNumber numberWithBool: YES ];
			bankAccount.uid = [NSNumber numberWithUnsignedInt: [acc uid ]];
			bankAccount.type = [NSNumber numberWithUnsignedInt: [acc type ]];

			// link
			bankAccount.parent = bankRoot;
		} 
		
	}
	// save updates
	if([self.managedObjectContext save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	[defaults setBool:YES forKey:@"accountsUpdated" ];
}

-(NSIndexPath*)indexPathForCategory: (Category*)cat inArray: (NSArray*)nodes
{
	int i;
	for(i=0; i<[nodes count ]; i++) {
		NSTreeNode *node = [nodes objectAtIndex:i ];
		Category *obj = [node representedObject ];
		if(obj == cat) return [NSIndexPath indexPathWithIndex: i ];
		else {
			NSArray *children = [node childNodes ];
			if(children == nil) continue;
			NSIndexPath *p = [self indexPathForCategory: cat inArray: children ];
			if(p) return [p indexPathByAddingIndex: i ];
		}
	}
	return nil;
}


-(void)removeBankAccount: (BankAccount*)bankAccount keepAssignedStatements:(BOOL)keepAssignedStats
{
	NSSet* stats = [bankAccount mutableSetValueForKey: @"statements" ];
	NSEnumerator *enumerator = [stats objectEnumerator];
	BankStatement*	statement;
	int		i;
	BOOL	removeParent = NO;
	
	//  Delete bank statements which are not assigned first
	while ((statement = [enumerator nextObject])) {
		if (keepAssignedStats == NO) {
			[self.managedObjectContext deleteObject:statement ];
		} else {
			NSSet *assignments = [statement mutableSetValueForKey:@"assignments" ];
			if ([assignments count ] < 2) {
				[self.managedObjectContext deleteObject:statement ];
			} else if ([assignments count ] == 2) {
				// delete statement if not assigned yet
				if ([statement hasAssignment ] == NO) {
					[self.managedObjectContext deleteObject:statement ];
				}
			} else {
				statement.account = nil;
			}
		}
	}
	
	[self.managedObjectContext processPendingChanges ];
	[[Category nassRoot ] invalidateBalance ];
	[Category updateCatValues ];
	
	// remove parent?
	BankAccount *parent = [bankAccount valueForKey: @"parent" ];
	if(parent != nil) {
		NSSet *childs = [parent mutableSetValueForKey: @"children" ];
		if([childs count ] == 1 ) removeParent = YES;
	}
	
	// calculate index path of current object
	NSArray *nodes = [[categoryController arrangedObjects ] childNodes ];
	NSIndexPath *path = [self indexPathForCategory: bankAccount inArray: nodes ];
	// IndexPath umdrehen
	NSIndexPath *newPath = [[NSIndexPath alloc ] init];
	for(i=[path length ]-1; i>=0; i--) newPath = [newPath indexPathByAddingIndex: [path indexAtPosition:i ] ]; 
	
	[categoryController removeObjectAtArrangedObjectIndexPath: newPath ];
	if(removeParent) {
		newPath = [newPath indexPathByRemovingLastIndex ];
		[categoryController removeObjectAtArrangedObjectIndexPath: newPath ];
	}
//	[categoryController remove: self ];
	[[Category bankRoot ] rollup ];

//	[accountsView setNeedsDisplay: YES ];
}

-(BOOL)cleanupBankNodes
{
	int i;
	BOOL flg_changed = NO;
	// remove empty bank nodes
	Category *root = [Category bankRoot ];
	if(root != nil) {
		NSArray *bankNodes = [[root mutableSetValueForKey: @"children" ] allObjects ];
		for(i=0; i<[bankNodes count ]; i++) {
			BankAccount *node = [bankNodes objectAtIndex:i ];
			NSMutableSet *childs = [node mutableSetValueForKey: @"children" ];
			if(childs == nil || [childs count ] == 0) {
				[self.managedObjectContext deleteObject: node ];
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
	if([cats count ] > 0) return [cats objectAtIndex: 0 ];
	
	// create Root object
	Category *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
												  inManagedObjectContext:self.managedObjectContext];
	[obj setValue: @"++bankroot" forKey: @"name" ];
	[obj setValue: [NSNumber numberWithBool: YES ] forKey: @"isBankAcc" ];
	return obj;
}


-(void)repairCategories
{
	NSError		*error = nil;
	Category	*catRoot;
	int			i;
	BOOL		found = NO;

	// repair bank root
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"getBankingRoot"];
	NSArray *cats = [self.managedObjectContext executeFetchRequest:request error:&error];
	if( error != nil || cats == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	
	for(i=0; i<[cats count ]; i++) {
		Category *cat = [cats objectAtIndex:i ];
		NSString *n = [cat primitiveValueForKey:@"name"];
		if(![n isEqualToString: @"++bankroot" ]) {
			[cat setValue: @"++bankroot" forKey: @"name" ];
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

	for(i=0; i<[cats count ]; i++) {
		Category *cat = [cats objectAtIndex:i ];
		NSString *n = [cat primitiveValueForKey:@"name"];
		if([n isEqualToString: @"++catroot" ] ||
		   [n isEqualToString: @"Umsatzkategorien" ] ||
		   [n isEqualToString: @"Transaction categories" ]) {
			[cat setValue: @"++catroot" forKey: @"name" ];
			catRoot = cat;
			found = YES;
			break;
		}
	}
	
	if(found == NO) {
		// create Category Root object
		Category *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
													  inManagedObjectContext:self.managedObjectContext];
		[obj setValue: @"++catroot" forKey: @"name" ];
		[obj setValue: [NSNumber numberWithBool: NO ] forKey: @"isBankAcc" ];
		catRoot = obj;
	}
	
	// reassign categories
	for(i=0; i<[cats count ]; i++) {
		Category *cat = [cats objectAtIndex:i ];
		if(cat == catRoot) continue;
		if([cat valueForKey: @"parent" ] == nil) [cat setValue: catRoot forKey: @"parent" ];
	}
	
	// insert not assigned node
	request = [model fetchRequestTemplateForName:@"getNassRoot"];
	cats = [self.managedObjectContext executeFetchRequest:request error:&error];
	if( error != nil || cats == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	if([cats count ] == 0) {
		Category *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
													  inManagedObjectContext:self.managedObjectContext];
		[obj setPrimitiveValue: @"++nassroot" forKey: @"name" ];
		[obj setValue: [NSNumber numberWithBool: NO ] forKey: @"isBankAcc" ];
		[obj setValue: catRoot forKey: @"parent" ];
		
		[self updateNotAssignedCategory ];
	}
	
	// save updates
	if([self.managedObjectContext save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

-(BankAccount*)getBankNodeWithAccount: (ABAccount*)acc inAccounts: (NSMutableArray*)bankAccounts
{
	BankAccount *bankNode = [BankAccount bankRootForCode: acc.bankCode ];
	
	if(bankNode == nil) {
		Category *root = [Category bankRoot ];
		if(root == nil) return nil;
		// create bank node
		bankNode = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:self.managedObjectContext];
		bankNode.name = acc.bankName;
		bankNode.bankCode = acc.bankCode;
		bankNode.currency = acc.currency;
		bankNode.bic = acc.bic;
		bankNode.isBankAcc = [NSNumber numberWithBool: YES ];
		bankNode.parent = root;
		if(bankAccounts) [bankAccounts addObject: bankNode ];
	}
	return bankNode;
}

-(void)updateBalances
{
	NSError *error = nil;
	int     i;
	
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"getRootNodes"];
	NSArray *cats = [self.managedObjectContext executeFetchRequest:request error:&error];
	if( error != nil || cats == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	for(i=0; i<[cats count ]; i++) {
		Category* cat = [cats objectAtIndex: i ];
		if([cat isBankingRoot ] == NO) [cat updateInvalidBalances ];
		[cat rollup ];
	}
	
	// save updates
	if([self.managedObjectContext save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

-(IBAction)showInput:(id)sender
{
}

-(IBAction)showInfo:(id)sender
{
}

-(IBAction)updateAllAccounts:(id)sender
{
	[self updateBankAccounts:nil ];
}


-(IBAction)enqueueRequest: (id)sender
{
	NSMutableArray	*selectedAccounts = [NSMutableArray arrayWithCapacity: 10 ];
	NSArray			*selectedNodes = nil;
	Category		*cat;
	NSError			*error = nil;
	
	cat = [self currentSelection ];
	if(cat == nil) return;
	
	// one bank account selected
	if(cat.accountNumber != nil) [selectedAccounts addObject: cat ];
	else {
		// a node was selected
		NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:self.managedObjectContext];
		NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
		[request setEntity:entityDescription];
		if(cat.parent == nil) {
			// root was selected
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@", cat ];
			[request setPredicate:predicate];
			selectedNodes = [self.managedObjectContext executeFetchRequest:request error:&error];
			if(error) {
				NSAlert *alert = [NSAlert alertWithError:error];
				[alert runModal];
				return;
			}
		} else {
			// a node was selected
			selectedNodes = [NSArray arrayWithObjects: cat, nil ];
		}
		// now select accounts from nodes
		BankAccount *account;
		for(account in selectedNodes) {
			NSArray *result;
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@ AND noAutomaticQuery == 0", account ];
			[request setPredicate:predicate];
			result = [self.managedObjectContext executeFetchRequest:request error:&error];
			if(error) {
				NSAlert *alert = [NSAlert alertWithError:error];
				[alert runModal];
				return;
			}
			[selectedAccounts addObjectsFromArray: result ];
		}
	}
	if([selectedAccounts count ] == 0) return;
	
	// check if at least one Account is assigned to a user
	int nInactive = 0;
	BankAccount *account;
	for(account in selectedAccounts) if(account.userId == nil) nInactive++;
	if(nInactive == [selectedAccounts count ]) {
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
						[selectedAccounts count ]
						);
	}
	
	// now selectedAccounts has all selected Bank Accounts
	NSMutableArray *resultList = [[NSMutableArray arrayWithCapacity: [selectedAccounts count ] ] retain ];
	for(account in selectedAccounts) {
		if (account.userId) {
			BankQueryResult *result = [[BankQueryResult alloc ] init ];
			result.accountNumber = account.accountNumber;
			result.bankCode = account.bankCode;
			result.userId = account.userId;
			result.account = account;
			[resultList addObject: [result autorelease] ];
		}
	}
	
	// show log if wanted
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL showLog = [defaults boolForKey: @"logForBankQuery" ];
	if (showLog) {
		[logController showWindow:self ];
		[[logController window ] orderFront:self ];
	}

	// prepare UI
	[[[mainWindow contentView ] viewWithTag: 100 ] setEnabled: NO ];
	StatusBarController *sc = [StatusBarController controller ];
	[sc startSpinning ];
	[sc setMessage: NSLocalizedString(@"AP41", @"Load statements...") removeAfter:0 ];
	
	[[HBCIClient hbciClient ] getStatements: resultList ];
}

-(void)statementsNotification: (NSArray*)resultList
{
	BankQueryResult *result;
	StatusBarController *sc = [StatusBarController controller ];
	BOOL			noStatements;
	int				count = 0;
	
	if(resultList == nil) {
		[sc stopSpinning ];
		[sc clearMessage ];
		requestRunning = NO;
		return;
	}
	
	// get Proposals
	for(result in resultList) {
		NSArray *stats = result.statements;
		if([stats count ] > 0) {
			noStatements = FALSE;
			[result.account evaluateQueryResult: result ];
		}
		[result.account updateStandingOrders: result.standingOrders ];
	}
	
	[BankStatement initCategoriesCache ];
	
	[sc stopSpinning ];
	[sc clearMessage ];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL check = [defaults boolForKey: @"manualTransactionCheck" ];
	
	if(check && noStatements == FALSE) {
		BSSelectWindowController *con = [[BSSelectWindowController alloc ] initWithResults: resultList ];
		[con showWindow: self ];
	} else {
		for(result in resultList) {
			count += [result.account updateFromQueryResult: result ];
		}
		if (autoSyncRunning == YES) [self checkBalances:resultList ];
		[self requestFinished: resultList ];
		
		// status message
		[sc setMessage: [NSString stringWithFormat: NSLocalizedString(@"AP80", @""), count ] removeAfter:120  ];
	}
	[resultList autorelease ];
	autoSyncRunning = NO;
}


-(void)requestFinished: (NSArray*)resultList
{
	[self.managedObjectContext processPendingChanges ];
	[self updateBalances ];
	requestRunning = NO;
	[[[mainWindow contentView ] viewWithTag: 100 ] setEnabled: YES ];

	if(resultList != nil) {
		Category *cat = [self currentSelection ];
		if(cat && [cat isBankAccount ] && cat.accountNumber == nil) [transactionController setContent: [cat combinedStatements ] ];

		BankQueryResult *result;
		NSDate *maxDate = nil;
		for(result in resultList) {
			NSDate *lDate = result.account.latestTransferDate;
			if(maxDate && [maxDate compare: lDate ] == NSOrderedAscending || maxDate == nil) maxDate = lDate;
		}
		if(maxDate) [timeSlicer stepIn: [ShortDate dateWithDate: maxDate ] ];
		
		// update unread information
		NSInteger maxUnread = [BankAccount maxUnread ];
		
		// update data cell
		NSTableColumn *tc = [accountsView tableColumnWithIdentifier: @"name" ];
		if(tc) {
			ImageAndTextCell *cell = (ImageAndTextCell*)[tc dataCell ];
			[cell setMaxUnread:maxUnread ];
		}
		
		// redraw accounts view
		[accountsView setNeedsDisplay:YES ];

		[transactionController rearrangeObjects ];
	}
}

-(void)checkBalances:(NSArray*)resultList
{
	NSNumber *threshold;
	BOOL alert = NO;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	BOOL accWarning = [defaults boolForKey:@"accWarning" ];
	if (accWarning == NO) return;
	
	threshold = [defaults objectForKey:@"accWarningThreshold" ];
	if (threshold == nil) {
		threshold = [NSDecimalNumber zero ];
	}
	
	// check if account balances change below threshold
	for(BankQueryResult *result in resultList) {
		if ([result.oldBalance compare:threshold] == NSOrderedDescending && [result.balance compare:threshold ] == NSOrderedAscending) {
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
	if(results == nil || [results count ] != 1) return nil;
	return [results objectAtIndex: 0 ];
}


-(NSArray*)selectedNodes
{
	return [categoryController selectedObjects ];
}

-(IBAction)editBankUsers:(id)sender
{	
	if(!bankUserController) bankUserController = [[NewBankUserController alloc] initForController: self];
	[bankUserController showWindow: self ];
}

-(IBAction)editPreferences:(id)sender
{
	if(!prefController) { 
		prefController = [[PreferenceController alloc] init];
		[prefController setMainWindow: mainWindow ];
	}
	[prefController showWindow: self ];
}

-(IBAction)manageTransferTemplates: (id)sender
{
	TransferTemplateController *controller = [[TransferTemplateController alloc ] init ];
	[controller showWindow: mainWindow ];
}


-(void)windowWillClose:(NSNotification *)aNotification
{
	// save state of accountsView
//	[self saveAccountsViewState ];
}

-(IBAction)listUsers:(id)sender
{
}

-(IBAction)test: (id)sender
{
}

-(IBAction)addAccount: (id)sender
{
	NSString *bankCode = nil;
	Category* cat = [self currentSelection ];
	if(cat != nil) {
		if([cat isBankAccount ] == YES && [cat isRoot ] == NO) bankCode = [cat valueForKey: @"bankCode" ];
	}

	// check if there is any User
	if([[[HBCIClient hbciClient ] users ] count ] == 0) {
		int res = NSRunAlertPanel(NSLocalizedString(@"AP37", @"Account cannot be created"), 
								  NSLocalizedString(@"AP38", @"Please setup Bank ID first"), 
								  NSLocalizedString(@"ok", @"Ok"), 
								  NSLocalizedString(@"AP39", @"Setup Bank ID") , nil);
		if(res == NSAlertAlternateReturn) [self editBankUsers: self ];
		return;
	}

	AccountDefController *con = [[AccountDefController alloc ] init ];
	if(bankCode) [con setBankCode: bankCode name: [cat valueForKey: @"bankName" ] ];

	int res = [NSApp runModalForWindow: [con window]];
	if(res) {
		// account was created
		NSError *error = nil;

		// save updates
		if([self.managedObjectContext save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
	[categoryController rearrangeObjects ];
	[self updateBalances ];
}

-(IBAction)changeAccount: (id)sender
{
	Category* cat = [self currentSelection ];
	if(cat == nil) return;
	if([cat isBankAccount ] == NO) return;
	if([cat accountNumber ] == nil) return;
	
	AccountChangeController *con = [[AccountChangeController alloc ] initWithAccount: (BankAccount*)cat ];
	int res = [NSApp runModalForWindow: [con window]];
	if(res) {
		// account was changed
		NSError *error = nil;
		// save updates
		if([self.managedObjectContext save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
	[categoryController rearrangeObjects ];
}

-(IBAction)deleteAccount:(id)sender
{
	NSError	*error = nil;
	Category* cat = [self currentSelection ];
	if(cat == nil) return;
	if([cat isBankAccount ] == NO) return;
	if([cat accountNumber ] == nil) return;
	
	BankAccount *account = (BankAccount*)cat;
	
	// issue a confirmation
	int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP30", @"Delete account"),
									  NSLocalizedString(@"AP100", @"Do you really want to delete account %@?"),
									  NSLocalizedString(@"no", @"No"),
									  NSLocalizedString(@"yes", @"Yes"),
									  nil,
									  account.accountNumber
									  );
	if(res != NSAlertAlternateReturn) return;	
	
	// check for transactions
	BOOL keepAssignedStatements = NO;
	NSMutableSet *stats = [cat mutableSetValueForKey: @"statements" ];
	if(stats && [stats count ] > 0) {
		BOOL hasAssignment;
		
		// check if transactions are assigned
		for(BankStatement* stat in stats) {
			if ([stat hasAssignment ]) {
				hasAssignment = YES;
				break;
			}
		}
		
		if (hasAssignment) {
			int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP30", @"Delete account"),
											  NSLocalizedString(@"AP29", @"There are already transactions assigned to the selected account. Do you want to delete the account %@ anyway?"),
											  NSLocalizedString(@"yes", @"Yes"),
											  NSLocalizedString(@"no", @"No"),
											  NSLocalizedString(@"cancel", @"Cancel"),
											  account.accountNumber
											  );
			if (res == NSAlertDefaultReturn) {
				keepAssignedStatements = YES;
			} else {
				if (res == NSAlertOtherReturn) return;
				else keepAssignedStatements = NO;
			}
		}
	}
		// delete account
	[self removeBankAccount: account keepAssignedStatements: keepAssignedStatements ];

	// save updates
	if([self.managedObjectContext save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

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
	NSArray *hbciAccounts = [[HBCIClient hbciClient ] accounts ];
	for(BankAccount *account in bankAccounts) {
		BOOL found = NO;
		for(ABAccount *acc in hbciAccounts) {
			if ([acc.accountNumber isEqualToString: account.accountNumber ] && [acc.bankCode isEqualToString:account.bankCode ]) {
				found = YES;
				break;
			}
		}
		if (found == NO) {
			// Accounts will be deleted - keep Statements ?
			BOOL keepAssignedStatements = NO;
			NSMutableSet *stats = [account mutableSetValueForKey: @"statements" ];
			if(stats && [stats count ] > 0) {
				BOOL hasAssignment;
				
				// check if transactions are assigned
				for(BankStatement* stat in stats) {
					if ([stat hasAssignment ]) {
						hasAssignment = YES;
						break;
					}
				}
				
				if (hasAssignment) {
					int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP30", @"Delete account"),
													  NSLocalizedString(@"AP29", @"There are already transactions assigned to the selected account. Do you want to delete the account %@ anyway?"),
													  NSLocalizedString(@"yes", @"Yes"),
													  NSLocalizedString(@"no", @"No"),
													  nil,
													  account.accountNumber
													  );
					if (res == NSAlertDefaultReturn) {
						keepAssignedStatements = YES;
					} else keepAssignedStatements = NO;
				}
			}
			[self removeBankAccount:account keepAssignedStatements:keepAssignedStatements ];
			flg_update = YES;
		}
	}
	
	// save updates
	if(flg_update == YES) {
		if([self.managedObjectContext save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
}

// TAB views
-(IBAction)accountsView: (id)sender 
{ 
	[mainTabView selectTabViewItemAtIndex: 0 ];
	[self adjustSearchField ];
	
	// update values according to slicer
	Category *cat = [Category catRoot ];
	[Category setCatReportFrom: [timeSlicer lowerBounds ] to: [timeSlicer upperBounds ] ];
	[cat rebuildValues ];
	[cat rollup ];
}

-(IBAction)transferView: (id)sender 
{ 
	[mainTabView selectTabViewItemAtIndex: 1 ];
	[self adjustSearchField ];
}

-(IBAction)editRules: (id)sender {
	[catDefWinController prepare ];
	[mainTabView selectTabViewItemAtIndex: 2 ]; 
	[self adjustSearchField ];
}

-(IBAction)save: (id)sender
{
	NSError *error = nil;

	if(self.managedObjectContext == nil) return;
	if([self.managedObjectContext save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

-(IBAction)export: (id)sender
{
	Category			*cat;

	cat = [self currentSelection ];
	ExportController *controller = [ExportController controller ];
	[controller startExport:cat fromDate:[timeSlicer lowerBounds ] toDate:[timeSlicer upperBounds ] ];
}

-(IBAction)import: (id)sender
{
	NSError *error=nil;
	
	GenericImportController *con = [[GenericImportController alloc ] init ];
	
	int res = [NSApp runModalForWindow: [con window]];
	if(res) {
		// save updates
		if([self.managedObjectContext save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
	[self updateBalances ];
}


-(BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	if(flag == NO) [mainWindow makeKeyAndOrderFront: self ];
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	// check if there are unsent transfers
	BOOL close = [self checkForUnsentTransfers ];
	if (close == NO) return NSTerminateCancel;
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL hideDonationMessage = [defaults boolForKey: @"DonationPopup030" ];
	
	if(!hideDonationMessage) {
		DonationMessageController *controller = [[DonationMessageController alloc ] init ];
		BOOL donate = [controller run ];
		[controller release ];
		if(donate) {
			[self performSelector: @selector(donate:) withObject: self afterDelay: 0.0];
			return NSTerminateCancel;
		}
	}
//	[[MOAssistant assistant ] shutdown ];
	return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	NSError	*error = nil;
	
	[accountsView saveLayout ];
	[catDefWinController terminateController ];
	
	for(id <MainTabViewItem> item in [mainTabItems allValues ]) {
		[item terminate ];
	}
	
	if (self.managedObjectContext) {
		if([self.managedObjectContext save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
	
	// if application shall restart, launch new task
	if(restart) {
		NSProcessInfo *pi = [NSProcessInfo processInfo ];
		NSArray *args = [pi arguments ];
		NSString *path = [args objectAtIndex:0 ];
		if(path) {
			int pid = [pi processIdentifier ];
			[NSTask launchedTaskWithLaunchPath:path arguments:[NSArray arrayWithObjects:path, [NSString stringWithFormat:@"%d", pid], nil]];
		}
	}
	
	[[MOAssistant assistant ] shutdown ];
	[WorkerThread finish ];
}

// workaround for strange outlineView collapsing...
-(void)restoreAccountsView
{
	[accountsView restoreAll ];
}

-(int)AccSize
{
	return 20;
}

-(IBAction)accountSettings:(id)sender
{
	if(!accountSettingsController) accountSettingsController = [[AccountSettingsController alloc] init];
	[accountSettingsController showWindow: mainWindow ];
}

-(IBAction)showLog:(id)sender
{
//	[logController performSelector:@selector(showWindow:) onThread:[WorkerThread thread ] withObject:nil waitUntilDone:NO ];

	[logController showWindow: self ];
}

-(BankAccount*)selectedBankAccount
{
	Category	*cat = [self currentSelection ];
	if(cat == nil) return nil;
	if([cat isMemberOfClass: [Category class ] ]) return nil;
	
	NSString *accNumber = [cat valueForKey: @"accountNumber" ];
	if(accNumber == nil || [accNumber isEqual: @"" ]) return nil;
	return (BankAccount*)cat;
}

-(IBAction)transfer_local: (id)sender
{
	BankAccount* account = [self selectedBankAccount ];
	if(account == nil) return;
	if ([[account isManual ] boolValue] == YES) return;
	[transferWindowController transferOfType: TransferTypeLocal forAccount: account ];
}

-(IBAction)donate: (id)sender
{
	BankAccount* account = [self selectedBankAccount ];
	if(account == nil || [[account isManual ] boolValue] == YES) {
		NSRunAlertPanel(NSLocalizedString(@"AP91", @""), 
						NSLocalizedString(@"AP92", @""), 
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return;
	}
	[transferWindowController donateWithAccount: account ];
}


-(IBAction)transfer_internal: (id)sender
{
	BankAccount* account = [self selectedBankAccount ];
	if(account == nil) return;
	if ([[account isManual ] boolValue] == YES) return;
	[transferWindowController transferOfType: TransferTypeInternal forAccount: account ];
}

-(IBAction)transfer_dated: (id)sender
{
	BankAccount* account = [self selectedBankAccount ];
	if(account == nil) return;
	if ([[account isManual ] boolValue] == YES) return;
	[transferWindowController transferOfType: TransferTypeDated forAccount: account ];
}

-(IBAction)transfer_eu: (id)sender
{
	BankAccount* account = [self selectedBankAccount ];
	if(account == nil) return;
	if ([[account isManual ] boolValue] == YES) return;
	// check if bic and iban is defined
/*
	if([[account iban ] isEqual: @"" ] || [[ isEqual: @"" ]) {
		NSRunAlertPanel(NSLocalizedString(@"AP35", @"Incomplete data"), 
						[NSString stringWithFormat: NSLocalizedString(@"AP36", @"Missing IBAN or BIC for account %@"), [account accountNumber ] ], 
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return;
	}
*/ 
	
	[transferWindowController transferOfType: TransferTypeEU forAccount: account ];
}

-(Category*)currentSelection
{
	NSArray* sel = [categoryController selectedObjects ];
	if(sel == nil || [sel count ] != 1) return nil;
	return [sel objectAtIndex: 0 ];
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)tb;
{
    // Optional delegate method: Returns the identifiers of the subset of
    // toolbar items that are selectable. In our case, all of them
	int i;
	NSArray* items = [tb items ];
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5 ];
	for(i = 0; i < [items count ]; i++) {
		NSToolbarItem *item = [items objectAtIndex: i ];
		if([item tag ] > 0) [result addObject: [item itemIdentifier] ];
	}
    return result;
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item 
{
    return [outlineView persistentObjectForItem: item ];
}

-(IBAction)doSearch: (id)sender
{
	NSTextField	*te = sender;
	NSString	*searchName = [te stringValue ];
	
	int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem ] ];
	
	switch(idx) {
		case 0:
			if([searchName length ] == 0) [transactionController setFilterPredicate: [timeSlicer predicateForField: @"date" ] ];
			else {
				NSPredicate *pred = [NSPredicate predicateWithFormat: @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or userInfo contains[c] %@ or value = %@",
									 searchName, searchName, searchName, [NSDecimalNumber decimalNumberWithString:searchName locale: [NSLocale currentLocale ]] ];
				if(pred) [transactionController setFilterPredicate: pred ];
			}
			break;
			case 1:
			if([searchName length ] == 0) [transferListController setFilterPredicate: nil ];
			else {
				NSPredicate *pred = [NSPredicate predicateWithFormat: @"purpose contains[c] %@ or remoteName contains[c] %@ or value = %@",
									 searchName, searchName, [NSDecimalNumber decimalNumberWithString:searchName locale: [NSLocale currentLocale ] ]];
				if(pred) [transferListController setFilterPredicate: pred ];
			}
			break;
	}
	
}


-(void)adjustSearchField
{
	int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem ] ];

	[searchField setStringValue: @"" ];
	[transactionController setFilterPredicate: [timeSlicer predicateForField: @"date" ] ];
	[transferListController setFilterPredicate: nil ];
	if(idx == 0  || idx == 1) [searchItem setEnabled: YES ]; else [searchItem setEnabled: NO ];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem ] ];

	if(idx != 0) {
		if ([item action] == @selector(export:)) return NO;
		if ([item action] == @selector(addAccount:)) return NO;
		if ([item action] == @selector(changeAccount:)) return NO;
		if ([item action] == @selector(deleteAccount:)) return NO;
		if ([item action] == @selector(enqueueRequest:)) return NO;
		if ([item action] == @selector(accountSettings:)) return NO;
		if ([item action] == @selector(transfer_local:)) return NO;
		if ([item action] == @selector(transfer_eu:)) return NO;
		if ([item action] == @selector(transfer_dated:)) return NO;
		if ([item action] == @selector(splitStatement:)) return NO;
		if ([item action] == @selector(donate:)) return NO;
		if ([item action] == @selector(deleteStatement:)) return NO;
		if ([item action] == @selector(addStatement:)) return NO;
	}
	
	if(idx == 0) {
		Category* cat = [self currentSelection ];
		if(cat == nil || [cat accountNumber ] == nil) {
			if ([item action] == @selector(enqueueRequest:)) return NO;
			if ([item action] == @selector(changeAccount:)) return NO;
			if ([item action] == @selector(deleteAccount:)) return NO;
			if ([item action] == @selector(transfer_local:)) return NO;
			if ([item action] == @selector(transfer_eu:)) return NO;
			if ([item action] == @selector(transfer_dated:)) return NO;
			if ([item action] == @selector(addStatement:)) return NO;
		}
		if ([cat isBankAccount ] == YES) {
			if ([[(BankAccount*)cat isManual ] boolValue] == YES) {
				if ([item action] == @selector(transfer_local:)) return NO;
				if ([item action] == @selector(transfer_eu:)) return NO;
				if ([item action] == @selector(transfer_dated:)) return NO;
			} else {
				if ([item action] == @selector(addStatement:)) return NO;
			}
		}
		
		if ([item action ] == @selector(deleteStatement:)) {
			if ([cat isBankAccount ] == NO) return NO;
			if ([[transactionController selectedObjects] count ] == 0) return NO;
		}
		if ([item action ] == @selector(splitStatement:)) {
			if ([[transactionController selectedObjects] count ] == 0) return NO;
		}
		if(requestRunning && [item action] == @selector(enqueueRequest:)) return NO;
	}
	return YES;
}

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSArray *sel = [transactionController selectedObjects ];
	if(sel && [sel count ] == 1) {
		StatCatAssignment *stat = [sel objectAtIndex:0 ];
		if ([stat.category isBankAccount] && [stat.category isRoot ] == NO) {
			BankAccount *account = (BankAccount*)stat.category;
			if ([stat.statement.isNew boolValue] == YES) {
				stat.statement.isNew = [NSNumber numberWithBool:NO ];
				account.unread = account.unread - 1;
//				[account calcUnread ];
				if (account.unread == 0) {
					[self updateUnread ];
				}
				[accountsView setNeedsDisplay: YES ];
			}
		}
	}
}


// Dragging Bank Statements
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	unsigned int		idx;
	StatCatAssignment	*stat;
	
    // Copy the row numbers to the pasteboard.
	NSArray *objs = [transactionController arrangedObjects ];
	
	[rowIndexes getIndexes: &idx maxCount:1 inIndexRange: nil ];
	stat = [objs objectAtIndex: idx ];
	NSURL *uri = [[stat objectID] URIRepresentation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uri];
    [pboard declareTypes:[NSArray arrayWithObject: BankStatementDataType] owner:self];
    [pboard setData:data forType: BankStatementDataType];
	if([[self currentSelection ] isBankAccount ]) [tv setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove | NSDragOperationGeneric forLocal: YES ];
	else [tv setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove forLocal: YES ];
	[tv setDraggingSourceOperationMask: NSDragOperationDelete forLocal: NO]; 
    return YES;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier ] isEqualToString: @"date" ]) {
		NSArray *statements = [transactionController arrangedObjects ];
		StatCatAssignment *stat = [statements objectAtIndex:rowIndex ];

		DateAndValutaCell *cell = (DateAndValutaCell*)aCell;
		ShortDate *pDate = [ShortDate dateWithDate:stat.statement.date ];
		ShortDate *vDate = [ShortDate dateWithDate:stat.statement.valutaDate ];
		if ([pDate compare:vDate ] != NSOrderedSame) {
			cell.valuta = stat.statement.valutaDate;
		} else {
			cell.valuta = nil;
		}
	}
	if ([[aTableColumn identifier ] isEqualToString: @"value" ]) {
		NSArray *statements = [transactionController arrangedObjects ];
		StatCatAssignment *stat = [statements objectAtIndex:rowIndex ];
		
		AmountCell *cell = (AmountCell*)aCell;
		cell.amount = stat.value;
		cell.currency = stat.statement.currency;
	}
	if ([[aTableColumn identifier ] isEqualToString: @"saldo" ]) {
		NSArray *statements = [transactionController arrangedObjects ];
		StatCatAssignment *stat = [statements objectAtIndex:rowIndex ];
		
		AmountCell *cell = (AmountCell*)aCell;
		cell.amount = stat.statement.saldo;
		cell.currency = stat.statement.currency;
	}
	if ([[aTableColumn identifier ] isEqualToString: @"nassValue" ]) {
		NSArray *statements = [transactionController arrangedObjects ];
		StatCatAssignment *stat = [statements objectAtIndex:rowIndex ];
		
		AmountCell *cell = (AmountCell*)aCell;
		cell.amount = stat.statement.nassValue;
		cell.currency = stat.statement.currency;
	}
}

- (BOOL)outlineView:(NSOutlineView*)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard 
{
	Category		*cat;
	
	cat = [[items objectAtIndex:0 ] representedObject ];
	if(cat == nil) return NO;
	if([cat isBankAccount ]) return NO;
	if([cat isRoot ]) return NO;
	if(cat == [Category nassRoot ]) return NO;
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
	Category* cat = (Category*)[item representedObject ];
	if(cat == nil) return NSDragOperationNone;
    [[NSCursor arrowCursor ] set ];
	
	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil]];
	if(type == nil) return NO;
	if([type isEqual: BankStatementDataType ]) {
		if([cat isBankAccount]) {
			// only allow for manual accounts
			BankAccount *account = (BankAccount*)cat;
			if ([account.isManual boolValue] == YES) return NSDragOperationCopy;
			return NSDragOperationNone;
		}
		
		NSDragOperation mask = [info draggingSourceOperationMask];
		Category *scat = [self currentSelection ];
		if([cat isRoot ]) return NSDragOperationNone;
		// if not yet assigned: move
		if(scat == [Category nassRoot ]) return NSDragOperationMove;
		if(mask == NSDragOperationCopy && cat != [Category nassRoot ]) return NSDragOperationCopy;
		if(mask == NSDragOperationGeneric && cat != [Category nassRoot ]) {
			[splitCursor set ];
			return NSDragOperationGeneric;
		}
		return NSDragOperationMove;
	} else {
		if([cat isBankAccount]) return NSDragOperationNone;
		NSData *data = [pboard dataForType: type ];
		NSURL *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data ];
		NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri ];
		Category *scat = (Category*)[self.managedObjectContext objectWithID: moID];
		if ([scat checkMoveToCategory:cat ] == NO) return NSDragOperationNone;
		return NSDragOperationMove;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex 
{
	NSError *error;
	Category *cat = (Category*)[item representedObject ];
	NSPasteboard *pboard = [info draggingPasteboard];
	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil]];
	if(type == nil) return NO;
	NSData *data = [pboard dataForType: type ];
	NSURL *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data ];
	
	NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri ];
	if(moID == nil) return NO;
	// assume moID non-nil...
	
	if([type isEqual: BankStatementDataType ]) {
		NSDragOperation mask = [info draggingSourceOperationMask];
		StatCatAssignment *stat = (StatCatAssignment*)[self.managedObjectContext objectWithID: moID];
		
		if([[self currentSelection ] isBankAccount ]) {
			// if already assigned or copy modifier is pressed, copy the complete bank statement amount - else assign residual amount (move)
			if ([cat isBankAccount ]) {
				// drop on a manual account
				BankAccount *account = (BankAccount*)cat;
				[account copyStatement:stat.statement ];
				[[Category bankRoot ] rollup ];

			} else {
				if(mask == NSDragOperationCopy || [stat.statement.isAssigned boolValue]) [stat.statement assignToCategory: cat ];
				else if(mask == NSDragOperationGeneric) {
					BOOL negate = NO;
					NSDecimalNumber *residual = stat.statement.nassValue;
					if ([residual compare:[NSDecimalNumber zero ] ] == NSOrderedAscending) negate = YES;
					if (negate) residual = [[NSDecimalNumber zero ] decimalNumberBySubtracting:residual ];				
					[assignValueField setObjectValue:residual ];
					[NSApp runModalForWindow: assignValueWindow ];
					residual = [NSDecimalNumber decimalNumberWithDecimal: [[assignValueField objectValue ] decimalValue ]];
					if (negate) residual = [[NSDecimalNumber zero ] decimalNumberBySubtracting:residual ];				
					[stat.statement assignAmount:residual toCategory:cat ];
				} else [stat.statement assignAmount: stat.statement.nassValue toCategory: cat ];
			}
		} else {
			if(mask == NSDragOperationCopy) [stat.statement assignAmount: stat.value toCategory: cat ];
			else [stat moveToCategory: cat ];
		}
		
		// update values including rollup
		[Category updateCatValues ];
		
		// update tableview to maybe new row colors
		[transactionsView display ];
	} else {
		Category *scat = (Category*)[self.managedObjectContext objectWithID: moID];
		[scat setValue: cat forKey: @"parent" ];
		[[Category catRoot ] rollup ];
	}
//	[accountsView setNeedsDisplay: YES ];

	// save updates
	if([self.managedObjectContext save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return NO;
	}
	return YES;
}

-(void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	if (self.managedObjectContext == nil) return;
	
	if([cat isBankAccount ] && cat.accountNumber == nil) {
		if (statementsBound) {
			[transactionController unbind:@"contentSet" ];
			statementsBound = NO;
		}
		[transactionController setContent: [cat combinedStatements ] ];
	} else {
		if (statementsBound == NO) {
			[transactionController bind:@"contentSet" toObject:categoryController withKeyPath:@"selection.assignments" options:nil ];
			statementsBound = YES;
		}
	}
	
	// set states of categorie Actions Control
	[catActions setEnabled: [cat isRemoveable ] forSegment: 2 ];
	[catActions setEnabled: [cat isInsertable ] forSegment: 1 ];

	// hide saldo for Categories
	NSTableColumn	*tc;
	tc = [transactionsView tableColumnWithIdentifier: @"saldo" ];
	[tc setHidden: ![cat isBankAccount ] ];

	BOOL editable = NO;
	if(![cat isBankAccount ] && cat != [Category nassRoot ] && cat != [Category catRoot ]) {
		editable = YES;
		NSArray *sel = [transactionController selectedObjects ];
		if(sel && [sel count ] > 0) editable = YES;
	}
	tc = [transactionsView tableColumnWithIdentifier: @"value" ];
	[tc setEditable: editable ];
	
	// value field
	[valueField setEditable: editable ];
	if (editable) {
		[valueField setBackgroundColor:[NSColor whiteColor ] ];
	} else {
		[valueField setBackgroundColor:[NSColor colorWithDeviceRed: 0.95 green: 0.97 blue: 1.0 alpha: 100 ] ];
	}
//	[valueField setDrawsBackground: editable ];
//	[valueField setBezeled: editable ];

	[valueField setHidden: YES ];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(ImageAndTextCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([[tableColumn identifier ] isEqualToString: @"name" ] == NO) return;
	
	Category *cat = [item representedObject ];
	if(cat == nil) return;
	
	NSImage *catImage		= [NSImage imageNamed:@"catdef4_18.png"];
	NSImage *moneyImage		= [NSImage imageNamed:@"money_18.png"];
	NSImage *moneySyncImage	= [NSImage imageNamed:@"money_sync_18.png"];
	NSImage *folderImage	= [NSImage imageNamed:@"folder_18.png"];
	
	[cell setImage: catImage];
	
	NSInteger numberUnread = 0;
	
	if([cat isBankAccount] && cat.accountNumber == nil) 	[cell setImage: folderImage];
	if([cat isBankAccount] && cat.accountNumber != nil) {
		BankAccount *account = (BankAccount*)cat;
		if([account.isManual boolValue ] == YES || [account.noAutomaticQuery boolValue ] == YES) [cell setImage: moneyImage];
		else [cell setImage: moneySyncImage];
	}

	if ([cat isBankAccount ] == NO || [cat isRoot ]) {
		numberUnread = 0;
	} else numberUnread = [(BankAccount*)cat unread ];
	
	BOOL itemIsSelected = FALSE;
	if ([outlineView itemAtRow:[outlineView selectedRow]] == item)	 itemIsSelected = TRUE;
	
	
	BOOL itemIsRoot = [cat isRoot];
	if (itemIsRoot == TRUE) {
		[cell setImage:Nil];
	}
	
	
	[cell setValues:[cat catSum] currency:cat.currency unread:numberUnread selected:itemIsSelected root:itemIsRoot ];
}


-(void)updateNotAssignedCategory
{
	NSError *error = nil;
	int		i;
	
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
	for(i=0; i<[stats count ]; i++) {
		BankStatement *stat = [stats objectAtIndex: i ];
		[stat updateAssigned ];
	}
}

- (IBAction)deleteCategory: (id)sender
{
	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	
	if([cat isRemoveable ] == NO) return;
	NSArray *stats = [[cat mutableSetValueForKey: @"assignments" ] allObjects ];
	StatCatAssignment *stat;
	
	if([stats count ] > 0) {
		int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP84", @"Delete category"),
										  NSLocalizedString(@"AP85", @"Category '%@' still has %d assigned transactions. Do you want to proceed anyway?"),
										  NSLocalizedString(@"no", @"No"),
										  NSLocalizedString(@"yes", @"Yes"),
										  nil,
										  [cat localName ],
										  [stats count ],
										  nil
										  );
		if(res != NSAlertAlternateReturn) return;
	}
	
	//  Delete bank statements from category first
	for(stat in stats) {
		[stat remove ];
	}
	[categoryController remove: cat ];
	[Category updateCatValues ];
//	[accountsView setNeedsDisplay: YES ];
}

-(IBAction)addCategory: (id)sender
{
	Category *cat = [self currentSelection ];
	if(cat.isBankAccount) return;
	if(cat.isRoot) [categoryController addChild: sender ]; else	[categoryController add: sender ]; 
	[accountsView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];
}

-(IBAction)insertCategory: (id)sender
{
	Category *cat = [self currentSelection ];
	if([cat isInsertable ] == NO) return;
	[categoryController addChild: sender ];
	[accountsView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];
}

-(IBAction)manageCategories:(id)sender
{
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	switch(clickedSegmentTag) {
		case 0: [self addCategory: sender ]; break;
		case 1: [self insertCategory: sender ]; break;
		case 2: [self deleteCategory: sender ]; break;
		default: return;
	}
}

-(NSString*)autosaveNameForTimeSlicer: (TimeSliceManager*)tsm
{
	return @"AccMainTimeSlice";
}

-(void)timeSliceManager: (TimeSliceManager*)tsm changedIntervalFrom: (ShortDate*)from to: (ShortDate*)to
{
	if (self.managedObjectContext == nil) return;
	int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem ] ];
	if(idx) return;
	Category *cat = [Category catRoot ];
	[Category setCatReportFrom: from to: to ];
	// change filter
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(statement.date => %@) AND (statement.date <= %@)", [from lowDate ], [to highDate ] ];
	[transactionController setFilterPredicate: predicate];

	[cat rebuildValues ];
	[cat rollup ];
	
	[searchField setStringValue: @"" ];
}

-(void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
	if([aNotification object ] == accountsView) {
		Category *cat = [self currentSelection ];
		accountsView.saveCatName = [[cat name ] retain];
	}	
	if([aNotification object ] == valueField) {
		NSArray *sel = [transactionController selectedObjects ];
		if(sel && [sel count ] == 1) {
			StatCatAssignment *stat = [sel objectAtIndex:0 ];
			self.saveValue = stat.value;
		}
	}
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	// Category name changed
	if([aNotification object ] == accountsView) {
		Category *cat = [self currentSelection ];
		if([cat name ] == nil) {
			[cat setValue: [accountsView.saveCatName autorelease ] forKey: @"name"];
		}
		[categoryController resort ];
		if(cat) [categoryController setSelectedObject: cat ];
	}
	// Value field changed (todo: replace by key value observation)
	if([aNotification object ] == transactionsView || [aNotification object] == valueField) {
		NSArray *sel = [transactionController selectedObjects ];
		if(sel && [sel count ] == 1) {
			StatCatAssignment *stat = [sel objectAtIndex:0 ];
			
			// do some checks
			// amount must have correct sign
			NSDecimal d1 = [stat.statement.value decimalValue ];
			NSDecimal d2 = [stat.value decimalValue ];
			if (d1._isNegative != d2._isNegative) {
				NSBeep();
				stat.value = self.saveValue;
				return;
			}
			
			// amount must not be higher than original amount
			if (d1._isNegative) {
				if ([stat.value compare:stat.statement.value ] == NSOrderedAscending) {
					NSBeep();
					stat.value = self.saveValue;
					return;
				}
			} else {
				if ([stat.value compare:stat.statement.value ] == NSOrderedDescending) {
					NSBeep();
					stat.value = self.saveValue;
					return;
				}
			}

			[stat.statement updateAssigned ];
			Category *cat = [self currentSelection ];
			if(cat !=  nil) {
				[cat invalidateBalance ];
				[Category updateCatValues ];
//				[accountsView setNeedsDisplay: YES ];
			}
		}
		[transactionController setSelectedObjects:sel ];
	}
	if ([aNotification object ] == assignValueField) {
		[NSApp stopModalWithCode:0 ];
		[assignValueWindow orderOut:self ];
	}
}

-(void)setRestart
{
	restart = YES;
}

-(NSColor*)tableView:(MCEMTableView*)tv labelColorForRow:(int)row
{
	NSColor *color = nil;
	Category *cat = [self currentSelection ];
	if(![cat isBankAccount ]) return nil;
	
	StatCatAssignment *stat = [[transactionController arrangedObjects ] objectAtIndex: row ];
	if([stat.statement.isNew boolValue]) color = [PreferenceController newStatementRowColor ];
	if(![stat.statement.isAssigned boolValue ] && color == nil) color = [PreferenceController notAssignedRowColor ];
	return color;
}

-(IBAction)deleteStatement: (id)sender
{
	BOOL duplicate = NO;
	NSError *error = nil;
	BankAccount *account = (BankAccount*)[self currentSelection ];
	if(account == nil) return;
	
	// get selected statement
	NSArray *stats = [transactionController selectedObjects ];
	if([stats count ] != 1) return;
	BankStatement *stat = [[stats objectAtIndex:0 ] statement ];
	
	// check if statement is duplicate. Select all statements with same date
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date = %@)", account, stat.date  ];
	[request setPredicate:predicate];
	stats = [self.managedObjectContext executeFetchRequest:request error:&error];
	if(error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	
	BankStatement *iter;
	for(iter in stats) {
		if(iter != stat && [iter matches: stat ]) {
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
		[self.managedObjectContext deleteObject: stat ];

		// special behaviour for top bank accounts
		if(account.accountNumber == nil) {
			[self.managedObjectContext processPendingChanges ];
			[transactionController setContent: [account combinedStatements ] ];
		}
		
		// rebuild saldos - only for manual accounts
		if (account.userId == nil) {
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date > %@)", account, stat.date  ];
			[request setPredicate:predicate];
			stats = [self.managedObjectContext executeFetchRequest:request error:&error];
			if(error) {
				NSAlert *alert = [NSAlert alertWithError:error];
				[alert runModal];
				return;
			}
			
			for(BankStatement *s in stats) {
				s.saldo = [s.saldo decimalNumberBySubtracting:stat.value ];
			}
			
			account.balance = [account.balance decimalNumberBySubtracting:stat.value ];
			[[Category bankRoot ] rollup ];
		}

//		[self.managedObjectContext deleteObject: stat ];
	}
	
}

-(void)splitStatement:(id)sender
{
	int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem ] ];
	if (idx == 0) {
		NSArray *sel = [transactionController selectedObjects ];
		if (sel != nil && [sel count ] == 1) {
			StatSplitController *splitController = [[StatSplitController alloc ] initWithStatement:[[sel objectAtIndex:0 ] statement ] view:accountsView ];
			[splitController showWindow:mainWindow ];
		}
	}
}

-(IBAction)addStatement: (id)sender
{
	Category* cat = [self currentSelection ];
	if (cat == nil) return;
	if (cat.accountNumber == nil) return;
	
	BankStatementController *con = [[BankStatementController alloc ] initWithAccount: (BankAccount*)cat statement: nil ];
	
	int res = [NSApp runModalForWindow: [con window]];
	if(res) {
		[ transactionController rearrangeObjects ];
		
		// statement was created
		NSError *error = nil;
		
		// save updates
		if([self.managedObjectContext save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
}

-(IBAction)splitPurpose:(id)sender
{
	BankAccount *acc = nil;
	Category* cat = [self currentSelection ];
	if (cat != nil && cat.accountNumber != nil) {
		acc = (BankAccount*)cat;
	}
	
	PurposeSplitController *con = [[PurposeSplitController alloc ] initWithAccount:(BankAccount*)cat ];
	[NSApp runModalForWindow: [con window ] ];
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
	NSMutableArray *resultList = [[NSMutableArray arrayWithCapacity: [selectedAccounts count ] ] retain ];
	for(account in selectedAccounts) {
		if ([account.noAutomaticQuery boolValue] == NO) continue;
		
		BankQueryResult *result = [[BankQueryResult alloc ] init ];
		result.accountNumber = account.accountNumber;
		result.bankCode = account.bankCode;
		result.account = account;
		[resultList addObject: [result autorelease] ];
	}
	
	// prepare UI
	[[[mainWindow contentView ] viewWithTag: 100 ] setEnabled: NO ];
	StatusBarController *sc = [StatusBarController controller ];
	[sc startSpinning ];
	[sc setMessage: NSLocalizedString(@"AP41", @"Load statements...") removeAfter:0 ];
	
	// get statements in separate thread
	autoSyncRunning = YES;
	[[HBCIClient hbciClient ] getStatements: resultList ];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	[defaults setObject: [NSDate date ] forKey: @"lastSyncDate" ];
	
	// if autosync, setup next timer event
	BOOL autoSync = [defaults boolForKey: @"autoSync" ];
	if(autoSync) {
		NSDate *syncTime = [defaults objectForKey:@"autoSyncTime" ];
		if(syncTime == nil) {
			NSLog(@"No autosync time defined");
			return;
		}
		NSCalendar *calendar = [[NSCalendar alloc ] initWithCalendarIdentifier: NSGregorianCalendar ];
		// set date +24Hr
		NSDateComponents *comps1 = [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate: [NSDate dateWithTimeIntervalSinceNow: 86400 ] ];
		NSDateComponents *comps2 = [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: syncTime ];
		[comps1 setHour: [comps2 hour ]  ];
		[comps1 setMinute: [comps2 minute ] ];
		NSDate *syncDate = [calendar dateFromComponents: comps1 ];
		// syncTime in future: setup Timer
		NSTimer *timer = [[NSTimer alloc ] initWithFireDate:syncDate 
												   interval:0.0 
													 target:self 
												   selector:@selector(autoSyncTimerEvent) 
												   userInfo:nil 
													repeats:NO];
		[[NSRunLoop currentRunLoop ] addTimer:timer forMode:NSDefaultRunLoopMode ];
		[timer release ];
		[calendar release ];
	}
}

-(void)checkForAutoSync
{
	BOOL syncDone = NO;
	NSDate *syncTime;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL syncAtStartup = [defaults boolForKey: @"syncAtStartup" ];
	BOOL autoSync = [defaults boolForKey: @"autoSync" ];
	if(!(autoSync || syncAtStartup)) return;
	if(autoSync) {
		syncTime = [defaults objectForKey:@"autoSyncTime" ];
		if(syncTime == nil) {
			NSLog(@"No autosync time defined");
			autoSync = NO;
		}
	}
	NSDate *lastSyncDate = [defaults objectForKey: @"lastSyncDate"];
	ShortDate *d1 = [ShortDate dateWithDate: lastSyncDate ];
	ShortDate *d2 = [ShortDate dateWithDate: [NSDate date ] ];
	if((d1 == nil || [d1 compare: d2 ] != NSOrderedSame) && syncAtStartup) {
		// no sync done today. If in startup, do immediate sync
		[self performSelector: @selector(syncAllAccounts) withObject: nil afterDelay: 5.0];
		syncDone = YES;
	}
	
	if(!autoSync) return;
	// get today's sync time. 
	NSCalendar *calendar = [[NSCalendar alloc ] initWithCalendarIdentifier: NSGregorianCalendar ];
	NSDateComponents *comps1 = [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate: [NSDate date ] ];
	NSDateComponents *comps2 = [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: syncTime ];
	
	[comps1 setHour: [comps2 hour ]  ];
	[comps1 setMinute: [comps2 minute ] ];
	NSDate *syncDate = [calendar dateFromComponents: comps1 ];
	// if syncTime has passed, do immediate sync
	if([syncDate compare: [NSDate date ] ] == NSOrderedAscending) {
		if(!syncDone) [self performSelector: @selector(syncAllAccounts) withObject: nil afterDelay: 5.0];
	} else {
		// syncTime in future: setup Timer
		NSTimer *timer = [[NSTimer alloc ] initWithFireDate:syncDate 
												   interval:0.0 
													 target:self 
												   selector:@selector(autoSyncTimerEvent) 
												   userInfo:nil 
													repeats:NO];
		[[NSRunLoop currentRunLoop ] addTimer:timer forMode:NSDefaultRunLoopMode ];
//		[timer release ];
	}
	[calendar release ];
}

-(IBAction)showLicense: (id)sender
{
	NSString *path = [[NSBundle mainBundle ] pathForResource: @"gpl-2.0" ofType: @"txt" ];
	[[NSWorkspace sharedWorkspace ] openFile: path ];
}

-(void)applicationWillFinishLaunching:(NSNotification *)notification
{
	if ([[MOAssistant assistant ] encrypted ]) {
		StatusBarController *sc = [StatusBarController controller ];
		[sc startSpinning ];
		[sc setMessage: NSLocalizedString(@"AP110", @"Open database...") removeAfter:0 ];
		
		@try {
			[[MOAssistant assistant ] openImage ];
			self.managedObjectContext = [[MOAssistant assistant ] context ];
		}
		@catch(NSError* error) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			[NSApp terminate: self ];
		}
		[self publishContext ];
		[sc stopSpinning ];
		[sc clearMessage ];
	}
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self checkForAutoSync ];
}

-(void)autoSyncTimerEvent:(NSTimer*)theTimer
{
	[self syncAllAccounts ];
}

-(void)setEncrypted:(BOOL)encrypted
{
	if(encrypted) [lockImage setHidden:NO ]; else [lockImage setHidden:YES ];
}

-(BOOL)checkForUnsentTransfers
{
	NSError *error = nil;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Transfer" inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(isSent = 0)" ];
	[request setPredicate:predicate];
	NSArray *transfers = [self.managedObjectContext executeFetchRequest:request error:&error];
	if (error || [transfers count ] == 0) return YES;
	
	int res = NSRunAlertPanel(NSLocalizedString(@"AP114", @""),
							  NSLocalizedString(@"AP111", @""),
							  NSLocalizedString(@"yes", @"Yes"),
							  NSLocalizedString(@"AP113", @""),
							  NSLocalizedString(@"AP112", @""),
							  nil
							  );
	if (res == NSAlertDefaultReturn) return YES;
	if (res == NSAlertAlternateReturn) {
		NSArray *items = [toolbar items ];
		for(NSToolbarItem *item in items) {
			if ([item tag ] == 20) {
				[toolbar setSelectedItemIdentifier:[item itemIdentifier ] ];
				break;
			}
		}
		[self performSelector: @selector(transferView:) withObject: self afterDelay: 0.0 ];
		return NO;
	}
	
	// send transfers
	BOOL sent = [[HBCIClient hbciClient ] sendTransfers: transfers ];
	if(sent) {
		// save updates
		if([self.managedObjectContext save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return NO;
		}
	}
	return NO;
}

-(void)updateUnread
{
	NSTableColumn* tc = [accountsView tableColumnWithIdentifier: @"name" ];
	if(tc) {
		ImageAndTextCell *cell = (ImageAndTextCell*)[tc dataCell ];
		// update unread information
		NSInteger maxUnread = [BankAccount maxUnread ];
		[cell setMaxUnread:maxUnread ];
	}
}

-(IBAction)printDocument:(id)sender
{
	int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem ] ];
	if (idx == 0) {
		NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo ];
		[printInfo setTopMargin:45 ];
		[printInfo setBottomMargin:45 ];
		NSPrintOperation *printOp;
		NSView *view = [[BankStatementPrintView alloc ] initWithStatements:[transactionController arrangedObjects ] printInfo:printInfo ];
		printOp = [NSPrintOperation printOperationWithView:view printInfo: printInfo ];
		[printOp setShowsPrintPanel:YES ];
		//	NSGraphicsContext *context = [printOp context ];
		[printOp runOperation ];
	}
	if (idx == 1) {
		NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo ];
		[printInfo setTopMargin:45 ];
		[printInfo setBottomMargin:45 ];
		[printInfo setHorizontalPagination:NSFitPagination ];
		[printInfo setVerticalPagination:NSFitPagination ];
		NSPrintOperation *printOp;
//		NSView *view = [[BankStatementPrintView alloc ] initWithStatements:[transactionController arrangedObjects ] printInfo:printInfo ];
		printOp = [NSPrintOperation printOperationWithView:[[mainTabView selectedTabViewItem ] view] printInfo: printInfo ];
		[printOp setShowsPrintPanel:YES ];
		//	NSGraphicsContext *context = [printOp context ];
		[printOp runOperation ];
	}
	
	if (idx > 2) {
		id <MainTabViewItem> item = [mainTabItems objectForKey:[[mainTabView selectedTabViewItem ] identifier ]];
		[item print ];
	}
}

-(IBAction)resetIsNewStatements:(id)sender
{
	NSError *error = nil;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isNew = 1" ];
	[request setPredicate:predicate];
	NSArray *statements = [context executeFetchRequest:request error:&error];
	for(BankStatement *stat in statements) stat.isNew = [NSNumber numberWithBool:NO ];
		
	// save updates
	if([self.managedObjectContext save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	[self updateUnread ];
	[accountsView setNeedsDisplay: YES ];
	[transactionsView setNeedsDisplay:YES ];
}

-(void)migrate
{
	// in Migration from 0.2 to 0.3, add additional toolbar items
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	BOOL migrated03 = [defaults boolForKey:@"Migrated03" ];
	if (migrated03 == NO) {
		[toolbar insertItemWithItemIdentifier:@"catHistory" atIndex:5 ];
		[toolbar insertItemWithItemIdentifier:@"catPeriods" atIndex:6 ];
		[toolbar insertItemWithItemIdentifier:@"standingOrders" atIndex:7 ];
		
		//initialize width of category table column
		NSTableColumn *tc = [accountsView tableColumnWithIdentifier: @"name" ];
		if(tc) {
			[tc setWidth:999 ];
		}
		
		[defaults setBool:YES forKey:@"Migrated03" ];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == categoryController) {
		[accountsView setNeedsDisplay: YES ];
	}	
}

+(BankingController*)controller
{
	return con;
}



@end
