//
//  BankingController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ABWindowController;
@class ABInputWindowController;
@class ABInfoBoxController;
@class ABProgressWindowController;
@class ABController;
@class ABAccount;
@class BankAccount;
@class NewBankUserController;
@class PreferenceController;
@class AccountSettingsController;
@class LogController;
@class TransactionController;
@class CatDefWindowController;
@class AccountRepWindowController;
@class CategoryRepWindowController;
@class Category;
@class MCEMTreeController;
@class TimeSliceManager;
@class MCEMTableView;
@class CategoryView;

@interface BankingController : NSObject
{
	IBOutlet NSArrayController	*transactionController;
	IBOutlet NSWindow			*mainWindow;
	IBOutlet NSTabView			*mainTabView;
	IBOutlet MCEMTableView		*transactionsView;
	IBOutlet CategoryView		*accountsView;
	IBOutlet MCEMTreeController *categoryController;
//	IBOutlet NSTreeController   *catDefController;
	IBOutlet NSArrayController  *transferController;
	IBOutlet NSTableView		*transferView;
	IBOutlet NSSplitView		*mainVSplit;
	IBOutlet NSSplitView		*mainHSplit;
	IBOutlet NSPredicateEditor  *predicateEditor;
	IBOutlet NSArrayController  *assignPreviewController;
	IBOutlet NSToolbar			*toolbar;
	IBOutlet NSToolbarItem		*searchItem;
	IBOutlet NSSearchField		*searchField;
	IBOutlet TimeSliceManager	*timeSlicer;
	IBOutlet NSSegmentedControl *catActions;
	IBOutlet NSImageView		*lockImage;
	
	IBOutlet CatDefWindowController			*catDefWinController;
	IBOutlet AccountRepWindowController		*accountRepWinController;
	IBOutlet CategoryRepWindowController	*categoryRepWinController;
	
    NSMutableArray				*transactions;
	ABWindowController			*abWinController;
	ABInfoBoxController			*abInfoBoxController;
	ABInputWindowController		*abInputWindowController;
	ABProgressWindowController	*abProgressController;
	NSManagedObjectContext      *context;
	NSManagedObjectModel		*model;
	ABController				*abController;
	NewBankUserController		*bankUserController;
	PreferenceController		*prefController;
	AccountSettingsController   *accountSettingsController;
	LogController				*logController;
	TransactionController		*transferWindowController;
	BOOL						restart;
	BOOL						requestRunning;
	BOOL						statementsBound;
}

-(IBAction)listUsers:(id)sender;
-(IBAction)showInput:(id)sender;
-(IBAction)showInfo:(id)sender;
-(IBAction)showProgress:(id)sender;
-(IBAction)addAccount:(id)sender;
-(IBAction)changeAccount:(id)sender;
-(IBAction)deleteAccount:(id)sender;
-(IBAction)editPreferences:(id)sender;

-(IBAction)accountsView: (id)sender;
-(IBAction)transferView: (id)sender;
-(IBAction)editRules: (id)sender;
-(IBAction)accountsRep: (id)sender;
-(IBAction)categoryRep: (id)sender;

-(IBAction)enqueueRequest: (id)sender;
-(IBAction)save: (id)sender;
-(IBAction)editBankUsers:(id)sender;
-(IBAction)accountSettings:(id)sender;
-(IBAction)sendTransfers: (id)sender;
-(IBAction)deleteTransfers: (id)sender;
-(IBAction)changeTransfer: (id)sender;
-(IBAction)export: (id)sender;
-(IBAction)test: (id)sender;
-(IBAction)transfer_local: (id)sender;
-(IBAction)transfer_eu: (id)sender;
-(IBAction)transfer_dated: (id)sender;
-(IBAction)transfer_internal: (id)sender;
-(IBAction)donate: (id)sender;
-(IBAction)moveAccount: (id)sender;
-(IBAction)import: (id)sender;

-(IBAction)doSearch: (id)sender;

-(IBAction)manageCategories:(id)sender;

-(IBAction)addCategory: (id)sender;
-(IBAction)insertCategory: (id)sender;

-(IBAction)deleteStatement: (id)sender;
-(IBAction)showLicense: (id)sender;

-(ABController*)abController;

-(void)windowWillClose:(NSNotification *)aNotification;
-(NSArray*)selectedNodes;
-(BankAccount*)selectBankAccountWithNumber:(NSString*)accNum bankCode:(NSString*)code;
-(void)awakeFromNib;
-(int)AccSize;
-(NSManagedObjectContext*)managedObjectContext;
-(BankAccount*)getBankNodeWithAccount: (ABAccount*)acc inAccounts: (NSMutableArray*)bankAccounts;
-(Category*)getBankingRoot;
-(void)updateBankAccounts;
-(void)removeDeletedAccounts;
-(void)updateBalances;
-(void)adjustSearchField;
-(void)updateNotAssignedCategory;
-(void)requestFinished: (NSArray*)resultList;
-(BOOL)requestRunning;
-(void)setEncrypted:(BOOL)encrypted;
-(void)statementsNotification: (NSArray*)resultList;

-(Category*)currentSelection;
-(void)repairCategories;
-(void)setRestart;
-(void)syncAllAccounts;

+(BankingController*)controller;
@end
