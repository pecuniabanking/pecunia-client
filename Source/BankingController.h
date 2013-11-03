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

#import <Cocoa/Cocoa.h>

#import "PecuniaSectionItem.h"

@class Account;
@class BankAccount;
@class BankUser;
@class NewBankUserController;
@class LogController;
@class Category;
@class MCEMTreeController;
@class TimeSliceManager;
@class CategoryView;
@class TransfersController;
@class DebitsController;
@class DockIconController;

@class StatementsListView;
@class RoundedOuterShadowView;

@class HomeScreenController;
@class CategoryAnalysisWindowController;
@class CategoryRepWindowController;
@class CategoryDefWindowController;
@class CategoryPeriodsWindowController;
@class StandingOrderController;
@class CategoryHeatMapController;

@class RoundedSidebar;
@class SideToolbarView;
@class BWGradientBox;
@class SynchronousScrollView;
@class StatementDetails;

@class AttachmentImageView;
@class TagView;

@interface PecuniaSplitView : NSSplitView
- (NSColor *)dividerColor;

@property NSUInteger fixedIndex; // The index of the subview that should not be resized when the splitview size changes.

@end

@interface BankingController : NSObject
{
    IBOutlet NSArrayController      *categoryAssignments;
    IBOutlet NSWindow               *mainWindow;
    IBOutlet NSTabView              *mainTabView;
    IBOutlet CategoryView           *accountsView;
    IBOutlet MCEMTreeController     *categoryController;
    IBOutlet SynchronousScrollView  *accountsScrollView;
    IBOutlet PecuniaSplitView       *mainVSplit;
    IBOutlet NSArrayController      *assignPreviewController;
    IBOutlet TimeSliceManager       *timeSlicer;
    IBOutlet NSSegmentedControl     *catActions;
    IBOutlet NSImageView            *lockImage;
    IBOutlet NSTextField            *valueField;
    IBOutlet NSTextField            *headerValueField;
    IBOutlet NSTextField            *sumValueField;
    IBOutlet NSTextField            *nassValueField;
    IBOutlet NSTextField            *assignValueField;
    IBOutlet NSTextField            *earningsField;
    IBOutlet NSTextField            *spendingsField;
    IBOutlet NSTextField            *remoteNameLabel;
    IBOutlet PecuniaSplitView       *rightSplitter;
    IBOutlet NSView                 *rightPane;
    IBOutlet StatementDetails       *standardDetails;
    IBOutlet StatementDetails       *creditCardDetails;
    IBOutlet RoundedOuterShadowView *statementsListViewHost;
    IBOutlet NSSegmentedControl     *toolbarButtons;

    // About panel.
    IBOutlet NSPanel       *aboutWindow;
    IBOutlet BWGradientBox *gradient;
    IBOutlet NSTextView    *aboutText;
    IBOutlet NSTextField   *versionText;
    IBOutlet NSTextField   *copyrightText;

    IBOutlet StatementsListView *statementsListView;
    IBOutlet NSSegmentedControl *sortControl;

    IBOutlet NSButton       *statementsButton;
    IBOutlet NSButton       *graph1Button;
    IBOutlet NSButton       *graph2Button;
    IBOutlet NSButton       *computingButton;
    IBOutlet NSButton       *rulesButton;
    IBOutlet NSButton       *heatMapButton;
    IBOutlet RoundedSidebar *sideBar;

    IBOutlet NSMenuItem *toggleFullscreenItem;
    IBOutlet NSMenuItem *developerMenu;

    IBOutlet NSWindow *licenseWindow;
    IBOutlet NSButton *toggleDetailsButton;

    IBOutlet NSArrayController *statementTags;
    IBOutlet NSArrayController *tagsController;
    IBOutlet NSButton          *tagButton;
    IBOutlet TagView           *tagsField;
    IBOutlet TagView           *tagViewPopup;
    IBOutlet NSView            *tagViewHost;

    IBOutlet AttachmentImageView *attachment1;
    IBOutlet AttachmentImageView *attachment2;
    IBOutlet AttachmentImageView *attachment3;
    IBOutlet AttachmentImageView *attachment4;

@private
    NSMutableDictionary    *mainTabItems;
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectModel   *model;
    NewBankUserController  *bankUserController;
    LogController          *logController;
    DockIconController     *dockIconController;
    BOOL                   restart;
    BOOL                   requestRunning;
    BOOL                   statementsBound;
    BOOL                   autoSyncRunning;
    NSDecimalNumber        *saveValue;
    NSCursor               *splitCursor;
    NSUInteger             lastSplitterPosition; // Last position of the right splitter.

    NSImage *moneyImage;
    NSImage *moneySyncImage;
    NSImage *bankImage;

    NSMutableArray *bankAccountItemsExpandState;
    Category       *lastSelection;

    HomeScreenController             *homeScreenController;
    CategoryAnalysisWindowController *categoryAnalysisController;
    CategoryRepWindowController      *categoryReportingController;
    CategoryDefWindowController      *categoryDefinitionController;
    CategoryPeriodsWindowController  *categoryPeriodsController;
    TransfersController              *transfersController;
    StandingOrderController          *standingOrderController;
    DebitsController                 *debitsController;
    CategoryHeatMapController        *heatMapController;

    id<PecuniaSectionItem> currentSection;

    // current statement details
    StatementDetails *statementDetails;

    // Sorting statements.
    int  sortIndex;
    BOOL sortAscending;

    NSArray *defaultIcons; // Associations between categories and their default icons.
}

@property (weak) IBOutlet NSMenuItem *toggleDetailsPaneItem;

@property (nonatomic, copy) NSDecimalNumber          *saveValue;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) DockIconController     *dockIconController;

@property (nonatomic, assign) BOOL showBalances;
@property (nonatomic, assign) BOOL showRecursiveStatements;
@property (nonatomic, assign) BOOL showDetailsPane;
@property (nonatomic, assign) BOOL shuttingDown;

- (IBAction)addAccount: (id)sender;
- (IBAction)changeAccount: (id)sender;
- (IBAction)deleteAccount: (id)sender;
- (IBAction)editPreferences: (id)sender;
- (IBAction)sortingChanged: (id)sender;

- (IBAction)activateMainPage: (id)sender;
- (IBAction)activateAccountPage: (id)sender;

- (IBAction)enqueueRequest: (id)sender;
- (IBAction)editBankUsers: (id)sender;
- (IBAction)export: (id)sender;
- (IBAction)import: (id)sender;

- (IBAction)transfer_local: (id)sender;
- (IBAction)transfer_eu: (id)sender;
- (IBAction)transfer_sepa: (id)sender;
- (IBAction)transfer_dated: (id)sender;
- (IBAction)transfer_internal: (id)sender;

- (IBAction)donate: (id)sender;
- (IBAction)splitPurpose: (id)sender;

- (IBAction)filterStatements: (id)sender;

- (IBAction)manageCategories: (id)sender;

- (IBAction)deleteStatement: (id)sender;
- (IBAction)splitStatement: (id)sender;
- (IBAction)addStatement: (id)sender;
- (IBAction)showLicense: (id)sender;
- (IBAction)showConsole:(id)sender;
- (IBAction)resetIsNewStatements: (id)sender;

- (IBAction)printDocument: (id)sender;
- (IBAction)accountMaintenance: (id)sender;
- (IBAction)getAccountBalance: (id)sender;

- (IBAction)showLog: (id)sender;
- (IBAction)showAboutPanel: (id)sender;
- (IBAction)toggleFullscreenIfSupported: (id)sender;
- (IBAction)toggleDetailsPane: (id)sender;
- (IBAction)toggleFeature: (id)sender;

- (IBAction)deleteAllData: (id)sender;
- (IBAction)generateData: (id)sender;

- (IBAction)creditCardSettlements: (id)sender;

- (NSArray *)selectedNodes;
- (BankAccount *)selectBankAccountWithNumber: (NSString *)accNum bankCode: (NSString *)code;
- (void)awakeFromNib;
- (void)statementsNotification: (NSNotification *)notification;
- (Category *)getBankingRoot;
- (void)updateNotAssignedCategory;
- (void)requestFinished: (NSArray *)resultList;
- (BOOL)requestRunning;

- (Category *)currentSelection;
- (void)repairCategories;
- (void)setRestart;
- (void)syncAllAccounts;
- (void)publishContext;
- (void)updateUnread;
- (BOOL)checkForUnhandledTransfersAndSend;
- (void)migrate;
- (void)checkBalances: (NSArray *)resultList;
- (void)setHBCIAccounts;

+ (BankingController *)controller;

@end
