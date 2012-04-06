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

#import <Cocoa/Cocoa.h>

#import "PecuniaSectionItem.h"

@class Account;
@class BankAccount;
@class NewBankUserController;
@class PreferenceController;
@class LogController;
@class TransactionController;
@class Category;
@class MCEMTreeController;
@class TimeSliceManager;
@class CategoryView;
@class TransferListController;
@class DockIconController;

@class StatementsListView;
@class RoundedOuterShadowView;

@class CategoryAnalysisWindowController;
@class CategoryRepWindowController;
@class CategoryDefWindowController;
@class CategoryPeriodsWindowController;

@class RoundedSidebar;
@class SideToolbarView;
@class BWGradientBox;
@class SynchronousScrollView;

@interface BankingController : NSObject
{
    IBOutlet NSArrayController  *transactionController;
    IBOutlet NSWindow           *mainWindow;
    IBOutlet NSTabView          *mainTabView;
    IBOutlet CategoryView       *accountsView;
    IBOutlet MCEMTreeController *categoryController;
    IBOutlet SynchronousScrollView *accountsScrollView;
    IBOutlet NSSplitView        *mainVSplit;
    IBOutlet NSArrayController  *assignPreviewController;
    IBOutlet NSToolbar          *toolbar;
    IBOutlet NSToolbarItem      *searchItem;
    IBOutlet NSSearchField      *searchField;
    IBOutlet TimeSliceManager   *timeSlicer;
    IBOutlet NSSegmentedControl *catActions;
    IBOutlet NSImageView        *lockImage;
    IBOutlet NSTextField        *valueField;
    IBOutlet NSTextField        *headerValueField;
    IBOutlet NSTextField        *nassValueField;
    IBOutlet NSWindow           *assignValueWindow;
    IBOutlet NSTextField        *assignValueField;
    IBOutlet NSTextField        *earningsField;
    IBOutlet NSTextField        *spendingsField;
    IBOutlet NSTextField        *turnoversField;
    IBOutlet NSTextField        *remoteNameLabel;
    IBOutlet NSSplitView        *rightSplitter;
    IBOutlet NSView             *rightPane;
    IBOutlet RoundedOuterShadowView* statementsListViewHost;
    
    // About panel.
    IBOutlet NSPanel            *aboutWindow;
    IBOutlet BWGradientBox      *gradient; 
    IBOutlet NSTextView         *aboutText;
    IBOutlet NSTextField        *versionText;
    IBOutlet NSTextField        *copyrightText;
    
    IBOutlet TransactionController  *transferWindowController;
    IBOutlet TransferListController *transferListController;
    IBOutlet StatementsListView     *statementsListView;
    IBOutlet NSSegmentedControl     *sortControl;
    
    IBOutlet RoundedSidebar  *sideBar;
    IBOutlet SideToolbarView *sideToolbar;
    
    IBOutlet NSMenuItem    *toggleFullscreenItem;
    
@private
    NSMutableDictionary    *mainTabItems;
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectModel   *model;
    NewBankUserController  *bankUserController;
    PreferenceController   *prefController;
    LogController          *logController;
    DockIconController     *dockIconController;
    BOOL                   restart;
    BOOL                   requestRunning;
    BOOL                   statementsBound;
    BOOL                   autoSyncRunning;
    NSDecimalNumber        *saveValue;
    NSCursor               *splitCursor;
    
    NSImage *categoryImage;
    NSImage *moneyImage;
    NSImage *moneySyncImage;
    NSImage *folderImage;
    
    NSMutableArray *bankAccountItemsExpandState;
    Category *lastSelection;
    
    CategoryAnalysisWindowController *categoryAnalysisController;
    CategoryRepWindowController *categoryReportingController;
    CategoryDefWindowController *categoryDefinitionController;
    CategoryPeriodsWindowController *categoryPeriodsController;
    id<PecuniaSectionItem> currentSection;
    
    // Sorting statements.
    NSInteger sortIndex;
    BOOL sortAscending;
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

-(IBAction)transferView: (id)sender;
-(IBAction)activateMainPage: (id)sender;
- (IBAction)activateAccountPage: (id)sender;

-(IBAction)enqueueRequest: (id)sender;
-(IBAction)save: (id)sender;
-(IBAction)editBankUsers:(id)sender;
-(IBAction)export: (id)sender;
-(IBAction)import: (id)sender;
-(IBAction)transfer_local: (id)sender;
-(IBAction)transfer_eu: (id)sender;
-(IBAction)transfer_sepa: (id)sender;
-(IBAction)transfer_dated: (id)sender;
-(IBAction)transfer_internal: (id)sender;
-(IBAction)donate: (id)sender;
-(IBAction)splitPurpose:(id)sender;

-(IBAction)filterStatements: (id)sender;

-(IBAction)manageCategories:(id)sender;

-(IBAction)deleteStatement: (id)sender;
-(IBAction)splitStatement: (id)sender;
-(IBAction)addStatement: (id)sender;
-(IBAction)showLicense: (id)sender;
-(IBAction)resetIsNewStatements:(id)sender;

-(IBAction)manageTransferTemplates: (id)sender;

-(IBAction)printDocument:(id)sender;
-(IBAction)updateAllAccounts:(id)sender;
-(IBAction)repairSaldo:(id)sender;

-(IBAction)showLog:(id)sender;
-(IBAction)showAboutPanel:(id)sender;
- (IBAction)toggleFullscreenIfSupported: (id)sender;

-(void)windowWillClose:(NSNotification *)aNotification;
-(NSArray*)selectedNodes;
-(BankAccount*)selectBankAccountWithNumber:(NSString*)accNum bankCode:(NSString*)code;
-(void)awakeFromNib;
-(int)AccSize;
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
