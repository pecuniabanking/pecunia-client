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
#import "AccountRepWindowController.h"
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

-(id)init
{
	HBCIClient *client = nil;
	
	[super init ];
	if(con) [con release ]; 
	con = self;
	restart = NO;
	requestRunning = NO;
	statementsBound = YES;
	mainTabItems = [[NSMutableArray arrayWithCapacity:10 ] retain ];
	
	[Category setCatReportFrom: [ShortDate dateWithYear: 2009 month:1 day:1 ] to: [ShortDate distantFuture ] ];
	
	// load context & model
	@try {
		context = [[MOAssistant assistant ] context ];
		model   = [[MOAssistant assistant ] model ];
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
	
	[client initHBCI ];
	logController = [LogController logController ];

	return self;
}

-(void)awakeFromNib
{
	NSTableColumn	*tc;
	
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
	
	
	// sort descriptor for transactions view
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"statement.date" ascending:NO] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[transactionController setSortDescriptors: sds ];

	// status (content) bar
	[mainWindow setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
	[mainWindow setContentBorderThickness:30.0f forEdge:NSMinYEdge];
	
	// repair Category Root
	[self repairCategories ];

	// set Bank Accounts
	[self updateBankAccounts ];
	[self updateBalances ];

	NSError *error;
    if([categoryController fetchWithRequest:nil merge:NO error:&error]); // [accountsView restoreAll ];
	
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
	[self performSelector: @selector(restoreAccountsView) withObject: nil afterDelay: 0.0];
	
	// set lock image
	[self setEncrypted: [[MOAssistant assistant ] encrypted ] ];
	
	[WorkerThread init ];
}

/*
-(void)setBankAccounts
{
	NSError	*error = nil;
	BankAccount *account;
	BOOL changed = NO;
	
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"allBankAccounts"];
	NSArray *bankAccounts = [context executeFetchRequest:request error:&error];
	if( error != nil || bankAccounts == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	
    NSMutableArray* relevantAccounts = [NSMutableArray arrayWithCapacity:20 ];
	
	for(account in bankAccounts) {
		if (account.userId == nil || account.customerId == nil) {
			// check if account is defined in HBCI Client
			Account* acc = [[HBCIClient hbciClient ] accountWithNumber:account.accountNumber bankCode:account.bankCode ];
			if (acc) {
				account.userId = acc.userId;
				account.customerId = acc.customerId;
				changed = YES;
				[relevantAccounts addObject:account ];
			}
		} else {
			[relevantAccounts addObject:account ];
		}

	}
	
	if (changed) {
		// save updates
		if([context save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
	
	[[HBCIClient hbciClient ] setAccounts:relevantAccounts ];
}
 */

-(void)updateBankAccounts
{
	NSError	*error = nil;
	int		i,j;
	BOOL	found;
	
	NSArray* hbciAccounts = [[HBCIClient hbciClient ] accounts ];
	
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"allBankAccounts"];
	NSArray *tmpAccounts = [context executeFetchRequest:request error:&error];
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
		} else {
			// Account was not found: create it
			BankAccount* bankRoot = [self getBankNodeWithAccount: acc inAccounts: bankAccounts ];
			if(bankRoot == nil) return;
			BankAccount	*bankAccount = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount"
																		 inManagedObjectContext:context];
			
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
//			bankAccount.uid = [NSNumber numberWithUnsignedInt: [acc uid ]];
//			bankAccount.type = [NSNumber numberWithUnsignedInt: [acc type ]];

			// link
			bankAccount.parent = bankRoot;
		} 
		
	}
	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
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
			[context deleteObject:statement ];
		} else {
			NSSet *assignments = [statement mutableSetValueForKey:@"assignments" ];
			if ([assignments count ] < 2) {
				[context deleteObject:statement ];
			} else if ([assignments count ] == 2) {
				// delete statement if not assigned yet
				if ([statement hasAssignment ] == NO) {
					[context deleteObject:statement ];
				}
			} else {
				statement.account = nil;
			}
		}
	}
	
	[context processPendingChanges ];
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
				[context deleteObject: node ];
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
	NSArray *cats = [context executeFetchRequest:request error:&error];
	if( error != nil || cats == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return nil;
	}
	if([cats count ] > 0) return [cats objectAtIndex: 0 ];
	
	// create Root object
	Category *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
												  inManagedObjectContext:context];
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
	NSArray *cats = [context executeFetchRequest:request error:&error];
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
	cats = [context executeFetchRequest:request error:&error];
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
													  inManagedObjectContext:context];
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
	cats = [context executeFetchRequest:request error:&error];
	if( error != nil || cats == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	if([cats count ] == 0) {
		Category *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
													  inManagedObjectContext:context];
		[obj setPrimitiveValue: @"++nassroot" forKey: @"name" ];
		[obj setValue: [NSNumber numberWithBool: NO ] forKey: @"isBankAcc" ];
		[obj setValue: catRoot forKey: @"parent" ];
		
		[self updateNotAssignedCategory ];
	}
	
	// save updates
	if([context save: &error ] == NO) {
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
		bankNode = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:context];
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
	NSArray *cats = [context executeFetchRequest:request error:&error];
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
	if([context save: &error ] == NO) {
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
		NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:context];
		NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
		[request setEntity:entityDescription];
		if(cat.parent == nil) {
			// root was selected
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@", cat ];
			[request setPredicate:predicate];
			selectedNodes = [context executeFetchRequest:request error:&error];
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
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@", account ];
			[request setPredicate:predicate];
			result = [context executeFetchRequest:request error:&error];
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
			[result.account evaluateStatements: stats ];
		}
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
		[self requestFinished: resultList ];
		
		// status message
		[sc setMessage: [NSString stringWithFormat: NSLocalizedString(@"AP80", @""), count ] removeAfter:120  ];
	}
	[resultList autorelease ];
}


-(void)requestFinished: (NSArray*)resultList
{
	[context processPendingChanges ];
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
		[timeSlicer stepIn: [ShortDate dateWithDate: maxDate ] ];
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
		[context executeFetchRequest:fetchRequest error:&error];
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
	[[HBCIClient hbciClient ] addBankUser ];
	
//	if(!bankUserController) bankUserController = [[NewBankUserController alloc] initForController: self];
//	[bankUserController showWindow: self ];
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
		if([context save: &error ] == NO) {
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
		if([context save: &error ] == NO) {
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

	
	// issue a confirmation
	int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP30", @"Delete account"),
									  NSLocalizedString(@"AP100", @"Do you really want to delete account %@?"),
									  NSLocalizedString(@"no", @"No"),
									  NSLocalizedString(@"yes", @"Yes"),
									  nil,
									  cat.accountNumber
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
											  nil
											  );
			if (res == NSAlertDefaultReturn) {
				keepAssignedStatements = YES;
			} else keepAssignedStatements = NO;
		}
	}
		// delete account
	[self removeBankAccount: (BankAccount*)cat keepAssignedStatements: keepAssignedStatements ];

	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
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
-(IBAction)accountsRep: (id)sender 
{
	[accountRepWinController prepare ];
	[mainTabView selectTabViewItemAtIndex: 3 ]; 
	[self adjustSearchField ];
}

-(IBAction)categoryRep: (id)sender
{
	[categoryRepWinController prepare ];
	[mainTabView selectTabViewItemAtIndex: 4 ];
	[self adjustSearchField ];
}

-(IBAction)save: (id)sender
{
	NSError *error = nil;

	if(context == nil) return;
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

-(IBAction)export: (id)sender
{
	Category			*cat;

	cat = [self currentSelection ];
	[ExportController export: cat ];
}


-(BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	if(flag == NO) [mainWindow makeKeyAndOrderFront: self ];
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL hideDonationMessage = [defaults boolForKey: @"DonationPopup024" ];
	
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
	NSError	*error;
	
	[accountsView saveLayout ];
	[accountRepWinController terminateController ];
	[categoryRepWinController terminateController ];
	[catDefWinController terminateController ];
	
	for(id <MainTabViewItem> item in mainTabItems) {
		[item terminate ];
	}
	
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
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

-(NSManagedObjectContext*)managedObjectContext
{
	return context;
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
	[transferWindowController transferOfType: TransferTypeLocal forAccount: account ];
}

-(IBAction)donate: (id)sender
{
	BankAccount* account = [self selectedBankAccount ];
	if(account == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP90", @""), 
						NSLocalizedString(@"AP91", @""), 
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return;
	}
	[transferWindowController donateWithAccount: account ];
}


-(IBAction)transfer_internal: (id)sender
{
	BankAccount* account = [self selectedBankAccount ];
	if(account == nil) return;
	[transferWindowController transferOfType: TransferTypeInternal forAccount: account ];
}

-(IBAction)transfer_dated: (id)sender
{
	BankAccount* account = [self selectedBankAccount ];
	if(account == nil) return;
	[transferWindowController transferOfType: TransferTypeDated forAccount: account ];
}

-(IBAction)transfer_eu: (id)sender
{
	BankAccount* account = [self selectedBankAccount ];
	if(account == nil) return;
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
				NSPredicate *pred = [NSPredicate predicateWithFormat: @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or statement.additional contains[c] %@",
									 searchName, searchName, searchName ];
				if(pred) [transactionController setFilterPredicate: pred ];
			}
			break;
			case 1:
			if([searchName length ] == 0) [transferListController setFilterPredicate: nil ];
			else {
				NSPredicate *pred = [NSPredicate predicateWithFormat: @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or statement.additional contains[c] %@",
									 searchName, searchName, searchName ];
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
			if ([item action] == @selector(donate:)) return NO;
			if ([item action] == @selector(addStatement:)) return NO;
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
	if([[self currentSelection ] isBankAccount ]) [tv setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove forLocal: YES ];
	else [tv setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove forLocal: YES ];
	[tv setDraggingSourceOperationMask: NSDragOperationDelete forLocal: NO]; 
    return YES;
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
	if([cat isBankAccount]) return NSDragOperationNone;

	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil]];
	if(type == nil) return NO;
	if([type isEqual: BankStatementDataType ]) {
		NSDragOperation mask = [info draggingSourceOperationMask];
		Category *scat = [self currentSelection ];
		if([cat isRoot ]) return NSDragOperationNone;
		// if not yet assigned: move
		if(scat == [Category nassRoot ]) return NSDragOperationMove;
		if(mask == NSDragOperationCopy && cat != [Category nassRoot ]) return NSDragOperationCopy;
		return NSDragOperationMove;
	} else {
		NSData *data = [pboard dataForType: type ];
		NSURL *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data ];
		NSManagedObjectID *moID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri ];
		Category *scat = (Category*)[context objectWithID: moID];
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
	
	NSManagedObjectID *moID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri ];
	if(moID == nil) return NO;
	// assume moID non-nil...
	
	if([type isEqual: BankStatementDataType ]) {
		NSDragOperation mask = [info draggingSourceOperationMask];
		StatCatAssignment *stat = (StatCatAssignment*)[context objectWithID: moID];
		if([[self currentSelection ] isBankAccount ]) {
			// if already assigned or copy modifier is pressed, copy the complete bank statement amount - else assign residual amount (move)
			if(mask == NSDragOperationCopy || [stat.statement isAssigned ]) [stat.statement assignToCategory: cat ];
			else [stat.statement assignAmount: [stat.statement residualAmount] toCategory: cat ];
		} else {
			if(mask == NSDragOperationCopy) [stat.statement assignAmount: stat.value toCategory: cat ];
			else [stat moveToCategory: cat ];
		}
		
		// update values including rollup
		[Category updateCatValues ];
		
		// update tableview to maybe new row colors
		[transactionsView display ];
	} else {
		Category *scat = (Category*)[context objectWithID: moID];
		[scat setValue: cat forKey: @"parent" ];
		[[Category catRoot ] rollup ];
	}
	// save updates
	if([context save: &error ] == NO) {
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

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	Category *cat = [item representedObject ];
	if(cat == nil) return;
	if([[tableColumn identifier ] isEqualToString: @"name" ]) {
		if([cat isRoot ]) {
			NSColor *txtColor;
			if([cell isHighlighted ]) txtColor = [NSColor whiteColor]; 
			else txtColor = [NSColor colorWithCalibratedHue: 0.6194 saturation: 0.32 brightness:0.56 alpha:1.0 ];
			NSFont *txtFont = [NSFont fontWithName: @"Arial Rounded MT Bold" size: 13];
			NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys: txtFont,NSFontAttributeName,txtColor, NSForegroundColorAttributeName, nil];
			NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString: [cat localName ] attributes:txtDict] autorelease];
			[cell setAttributedStringValue:attrStr];
		}
	}
	if([[tableColumn identifier ] isEqualToString: @"balance" ]) {
		if([cell isHighlighted ]){
			[(NSTextFieldCell*)cell setTextColor: [NSColor whiteColor ] ];
		} else {
			if([[cat catSum ] doubleValue ] >= 0) [(NSTextFieldCell*)cell setTextColor: [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100]];
			else [(NSTextFieldCell*)cell setTextColor: [NSColor redColor ] ];
		} 
	}
}


-(void)updateNotAssignedCategory
{
	NSError *error = nil;
	int		i;
	
	// fetch all bank statements
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSArray *stats = [context executeFetchRequest:request error:&error];
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

/*
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if(control == accountsView) {
		NSString *s = [fieldEditor string];
		if(s == nil || [s length ] == 0) {
			NSBeep();
			return NO;
		}
		return YES;
	}
}
*/

-(void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
	if([aNotification object ] == accountsView) {
		Category *cat = [self currentSelection ];
		accountsView.saveCatName = [[cat name ] retain];
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
			[stat.statement updateAssigned ];
			Category *cat = [self currentSelection ];
			if(cat !=  nil) {
				[cat invalidateBalance ];
				[Category updateCatValues ];
			}
		}
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
	if(stat.statement.isNew) color = [PreferenceController newStatementRowColor ];
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
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date = %@)", account, stat.date  ];
	[request setPredicate:predicate];
	stats = [context executeFetchRequest:request error:&error];
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
		[context deleteObject: stat ];
		
		// rebuild saldos - only for manual accounts
		if (account.userId == nil) {
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date > %@)", account, stat.date  ];
			[request setPredicate:predicate];
			stats = [context executeFetchRequest:request error:&error];
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

		[context deleteObject: stat ];
	}
	
}

-(void)splitStatement:(id)sender
{
	int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem ] ];
	if (idx == 0) {
		NSArray *sel = [transactionController selectedObjects ];
		if (sel != nil && [sel count ] == 1) {
			StatSplitController *splitController = [[StatSplitController alloc ] initWithStatement:[[sel objectAtIndex:0 ] statement ]];
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
		if([context save: &error ] == NO) {
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
	int res = [NSApp runModalForWindow: [con window ] ];
	
}


-(void)syncAllAccounts
{
	NSError *error = nil;
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"allBankAccounts"];
	NSArray *selectedAccounts = [context executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"Read bank accounts error on automatic sync");
		return;
	}
	
	// now selectedAccounts has all selected Bank Accounts
	BankAccount *account;
	NSMutableArray *resultList = [[NSMutableArray arrayWithCapacity: [selectedAccounts count ] ] retain ];
	for(account in selectedAccounts) {
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
	[[HBCIClient hbciClient ] getStatements: resultList ];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	[defaults setObject: [NSDate date ] forKey: @"lastSyncDate" ];
	
	// if autosync, setup next timer event
	BOOL autoSync = [defaults boolForKey: @"autSync" ];
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

-(IBAction)print:(id)sender
{
	NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo ];
	[printInfo setTopMargin:45 ];
	[printInfo setBottomMargin:45 ];
	NSPrintOperation *printOp;
	NSView *view = [[BankStatementPrintView alloc ] initWithStatements:[transactionController arrangedObjects ] printInfo:printInfo ];
	printOp = [NSPrintOperation printOperationWithView:view printInfo: printInfo ];
	[printOp setShowsPrintPanel:YES ];
	NSGraphicsContext *context = [printOp context ];
	[printOp runOperation ];
}

+(BankingController*)controller
{
	return con;
}



@end
