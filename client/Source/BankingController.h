//
//  BankingController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ABWindowController;
@class AccountsTree;
@class Account;
@class BankAccount;
@class NewBankUserController;
@class PreferenceController;
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
@class TransferListController;
@class DockIconController;
@class CurrencyValueTransformer;

#import "StatementsListView.h"

@interface BankingController : NSObject
{
  IBOutlet NSArrayController	*transactionController;
  IBOutlet NSWindow             *mainWindow;
  IBOutlet NSTabView			*mainTabView;
  IBOutlet MCEMTableView		*transactionsView;
  IBOutlet CategoryView         *accountsView;
  IBOutlet MCEMTreeController   *categoryController;
  IBOutlet NSSplitView          *mainVSplit;
  IBOutlet NSSplitView          *mainHSplit;
  IBOutlet NSPredicateEditor    *predicateEditor;
  IBOutlet NSArrayController    *assignPreviewController;
  IBOutlet NSToolbar			*toolbar;
  IBOutlet NSToolbarItem		*searchItem;
  IBOutlet NSSearchField		*searchField;
  IBOutlet TimeSliceManager     *timeSlicer;
  IBOutlet NSSegmentedControl   *catActions;
  IBOutlet NSImageView          *lockImage;
  IBOutlet NSTextField          *valueField;
  IBOutlet NSTextField          *headerValueField;
  IBOutlet NSTextField          *nassValueField;
  IBOutlet NSWindow             *assignValueWindow;
  IBOutlet NSTextField          *assignValueField;
  IBOutlet NSTextField          *earningsField;
  IBOutlet NSTextField          *spendingsField;
  IBOutlet NSTextField          *turnoversField;
  IBOutlet NSTextField          *remoteNameLabel;
  
  IBOutlet CatDefWindowController   *catDefWinController;
  IBOutlet TransferListController   *transferListController;
  IBOutlet StatementsListView       *statementsListView;
  
  NSMutableArray			*transactions;
  NSMutableDictionary		*mainTabItems;
  NSManagedObjectContext    *managedObjectContext;
  NSManagedObjectModel		*model;
  NewBankUserController		*bankUserController;
  PreferenceController		*prefController;
  LogController				*logController;
  TransactionController		*transferWindowController;
  DockIconController		*dockIconController;
  BOOL						restart;
  BOOL						requestRunning;
  BOOL						statementsBound;
  BOOL						autoSyncRunning;
  NSDecimalNumber			*saveValue;
  NSCursor					*splitCursor;
 
}

@property(nonatomic, copy) NSDecimalNumber *saveValue;
@property(nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, retain) DockIconController *dockIconController;

-(IBAction)listUsers:(id)sender;
-(IBAction)showInput:(id)sender;
-(IBAction)showInfo:(id)sender;
-(IBAction)addAccount:(id)sender;
-(IBAction)changeAccount:(id)sender;
-(IBAction)deleteAccount:(id)sender;
-(IBAction)editPreferences:(id)sender;

-(IBAction)accountsView: (id)sender;
-(IBAction)transferView: (id)sender;
-(IBAction)editRules: (id)sender;
-(IBAction)activateMainPage: (id)sender;

-(IBAction)enqueueRequest: (id)sender;
-(IBAction)save: (id)sender;
-(IBAction)editBankUsers:(id)sender;
-(IBAction)export: (id)sender;
-(IBAction)import: (id)sender;
-(IBAction)test: (id)sender;
-(IBAction)transfer_local: (id)sender;
-(IBAction)transfer_eu: (id)sender;
-(IBAction)transfer_dated: (id)sender;
-(IBAction)transfer_internal: (id)sender;
-(IBAction)donate: (id)sender;
-(IBAction)splitPurpose:(id)sender;

-(IBAction)doSearch: (id)sender;

-(IBAction)manageCategories:(id)sender;

-(IBAction)addCategory: (id)sender;
-(IBAction)insertCategory: (id)sender;

-(IBAction)deleteStatement: (id)sender;
-(IBAction)splitStatement: (id)sender;
-(IBAction)addStatement: (id)sender;
-(IBAction)showLicense: (id)sender;
-(IBAction)resetIsNewStatements:(id)sender;

-(IBAction)manageTransferTemplates: (id)sender;

-(IBAction)printDocument:(id)sender;
-(IBAction)updateAllAccounts:(id)sender;
-(IBAction)repairSaldo:(id)sender;


-(void)windowWillClose:(NSNotification *)aNotification;
-(NSArray*)selectedNodes;
-(BankAccount*)selectBankAccountWithNumber:(NSString*)accNum bankCode:(NSString*)code;
//-(void)removeDeletedAccounts;
-(void)awakeFromNib;
-(int)AccSize;
//-(NSManagedObjectContext*)managedObjectContext;
-(BankAccount*)getBankNodeWithAccount: (Account*)acc inAccounts: (NSMutableArray*)bankAccounts;
-(void)statementsNotification: (NSNotification*)notification;
-(Category*)getBankingRoot;
-(void)updateBankAccounts:(NSArray*)hbciAccounts;
-(void)updateBalances;
-(void)adjustSearchField;
-(void)updateNotAssignedCategory;
-(void)requestFinished: (NSArray*)resultList;
-(BOOL)requestRunning;
-(void)setEncrypted:(BOOL)encrypted;

-(Category*)currentSelection;
-(void)repairCategories;
-(void)setRestart;
-(void)syncAllAccounts;
-(void)publishContext;
-(void)updateUnread;
-(BOOL)checkForUnsentTransfers;
-(void)migrate;
-(void)checkBalances:(NSArray*)resultList;
-(void)setHBCIAccounts;

+(BankingController*)controller;

@end
