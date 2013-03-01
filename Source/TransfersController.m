/**
 * Copyright (c) 2010, 2013, Pecunia Project. All rights reserved.
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

#import "TransfersController.h"
#import "TransactionController.h"
#import "PecuniaError.h"
#import "LogController.h"
#import "HBCIClient.h"
#import "MOAssistant.h"
#import "BankAccount.h"
#import "TransferPrintView.h"
#import "TransferTemplate.h"
#import "TransactionLimits.h"
#import "TransferFormularView.h"
#import "GradientButtonCell.h"
#import "NSString+PecuniaAdditions.h"
#import "GraphicsAdditions.h"
#import "AnimationHelper.h"

#import "MAAttachedWindow.h"

// Keys for details dictionary used for transfers + statements listviews.
NSString *StatementDateKey            = @"date";             // NSDate
NSString *StatementTurnoversKey       = @"turnovers";        // NSString
NSString *StatementRemoteNameKey      = @"remoteName";       // NSString
NSString *StatementPurposeKey         = @"purpose";          // NSString
NSString *StatementCategoriesKey      = @"categories";       // NSString
NSString *StatementValueKey           = @"value";            // NSDecimalNumber
NSString *StatementSaldoKey           = @"saldo";            // NSDecimalNumber
NSString *StatementCurrencyKey        = @"currency";         // NSString
NSString *StatementTransactionTextKey = @"transactionText";  // NSString
NSString *StatementIndexKey           = @"index";            // NSNumber
NSString *StatementNoteKey            = @"note";             // NSString
NSString *StatementRemoteBankNameKey  = @"remoteBankName";   // NSString
NSString *StatementColorKey           = @"color";            // NSColor
NSString *StatementRemoteAccountKey   = @"account";          // NSString
NSString *StatementRemoteBankCodeKey  = @"remoteBankCode";   // NSString
NSString *StatementRemoteIBANKey      = @"iban";             // NSString
NSString *StatementRemoteBICKey       = @"bic";              // NSString
NSString *StatementTypeKey            = @"type";             // NSNumber

NSString* const TransferPredefinedTemplateDataType = @"TransferPredefinedTemplateDataType"; // For dragging one of the "menu" template images.
NSString* const TransferDataType = @"TransferDataType"; // For dragging an existing transfer (sent or not).
extern NSString *TransferReadyForUseDataType;     // For dragging an edited transfer.
extern NSString *TransferTemplateDataType;        // For dragging one of the stored templates.

@interface TransferCalendarWindow : MAAttachedWindow
{
}

@property (nonatomic, unsafe_unretained) TransfersController *controller;

@end

@implementation TransferCalendarWindow

@synthesize controller;

- (void)cancelOperation:(id)sender
{
    [controller hideCalendarWindow];
}
@end

//--------------------------------------------------------------------------------------------------

@interface DeleteTransferTargetView : NSImageView
{    
}

@property (nonatomic, unsafe_unretained) TransfersController *controller;

@end

@implementation DeleteTransferTargetView

@synthesize controller;

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];

    // Register for types that can be deleted.
    [self registerForDraggedTypes: @[TransferDataType, TransferReadyForUseDataType,
                                    TransferTemplateDataType]];
}

- (NSDragOperation)draggingEntered: (id <NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString *type = [pasteboard availableTypeFromArray: @[TransferDataType,
                                                          TransferReadyForUseDataType, TransferTemplateDataType]];
    if (type == nil) {
        return NSDragOperationNone;
    }

    [[NSCursor disappearingItemCursor] set];
    return NSDragOperationDelete;
}

- (void)draggingExited: (id <NSDraggingInfo>)info
{
    [[NSCursor arrowCursor] set];
}

- (BOOL)performDragOperation: (id<NSDraggingInfo>)info
{
    if ([controller concludeDropDeleteOperation: info]) {
        NSShowAnimationEffect(NSAnimationEffectPoof, [NSEvent mouseLocation], NSZeroSize, nil, nil, NULL);
        return YES;
    }
    return NO;
}

@end

//--------------------------------------------------------------------------------------------------

@interface DragImageView : NSImageView
{
@private
    BOOL canDrag;
    
}

@property (nonatomic, unsafe_unretained) TransfersController *controller;

@end

@implementation DragImageView

@synthesize controller;

- (void)mouseDown: (NSEvent *)theEvent
{
    if ([theEvent clickCount] > 1) {
        // Double click event. Start editing directly if possible.
        TransferType type;
        switch (self.tag) {
            case 0:
                type = TransferTypeInternal;
                break;
            case 2:
                type = TransferTypeEU;
                break;
            case 3:
                type = TransferTypeSEPA;
                break;
            case 4:
                return; // Not yet implemented.
                break;
            default:
                type = TransferTypeStandard;
                break;
        }
        
        if (![controller startTransferOfType: type withAccount: nil]) {
            [super mouseDown: theEvent];
        }
        return;
    }

    // Keep track of mouse clicks in the view because mouseDragged may be called even when another
    // view was clicked on.
    canDrag = YES;
    [super mouseDown: theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp: theEvent];
    canDrag = NO;
}

- (void)mouseDragged: (NSEvent *)theEvent
{
    if (!canDrag) {
        [super mouseDragged: theEvent];
        return;
    }
    
    TransferType type;
    switch (self.tag) {
        case 0:
            type = TransferTypeInternal;
            break;
        case 2:
            type = TransferTypeEU;
            break;
        case 3:
            type = TransferTypeSEPA;
            break;
        case 4:
            return; // Not yet implemented.
            break;
        default:
            type = TransferTypeStandard;
            break;
    }
    
    if ([controller prepareTransferOfType: type]) {
        NSPasteboard *pasteBoard = [NSPasteboard pasteboardWithUniqueName];
        [pasteBoard setString: [NSString stringWithFormat: @"%i", type] forType: TransferPredefinedTemplateDataType];
        
        NSPoint location;
        location.x = 0;
        location.y = 0;
        
        [self dragImage: [self image]
                     at: location
                 offset: NSZeroSize
                  event: theEvent
             pasteboard: pasteBoard
                 source: self
              slideBack: YES];
    }
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return isLocal ? NSDragOperationCopy : NSDragOperationNone; 
}

- (BOOL)ignoreModifierKeysWhileDragging
{
    return YES;
}

- (void)draggedImage: (NSImage *)image endedAt: (NSPoint)screenPoint operation: (NSDragOperation)operation
{
    canDrag = NO;
}

@end

//--------------------------------------------------------------------------------------------------

@implementation TransferTemplateDragDestination

@synthesize controller;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self != nil) {
        formularVisible = NO;
    }
    return self;
}

#pragma mark -
#pragma mark Drag and drop

- (NSDragOperation)draggingEntered: (id<NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    currentDragDataType = [pasteboard availableTypeFromArray:
                           @[TransferDataType,
                             TransferPredefinedTemplateDataType,
                             TransferReadyForUseDataType,
                             TransferTemplateDataType]];
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated: (id<NSDraggingInfo>)info
{
    if (currentDragDataType == nil) {
        return NSDragOperationNone;
    }
    
    NSPoint location = info.draggingLocation;
    if (NSPointInRect(location, [self dropTargetFrame])) {
        
        // Mouse is within our drag target area.
        if ((currentDragDataType == TransferDataType || currentDragDataType == TransferPredefinedTemplateDataType
             || currentDragDataType == TransferTemplateDataType)
            && [controller editingInProgress]) {
            return NSDragOperationNone;
        }
        
        // User is dragging either a template or an existing transfer around.
        // The controller tells us if a transfer can be edited right now.
        if (formularVisible) {
            // We have already checked editing is possible when we come here.
            return NSDragOperationCopy;
        }
        
        // Check if we can start a new editing process.
        if ([controller prepareEditingFromDragging: info]) {
            [self showFormular];
            return NSDragOperationCopy;
        }
        return NSDragOperationNone;
    } else {
        // Mouse moving outside the drop target area. Hide the formular if the drag
        // operation was initiated outside this view.
        if (currentDragDataType != TransferReadyForUseDataType && ![controller editingInProgress]) {
            [self hideFormular];
        }
        return NSDragOperationNone;
    }
}

- (void)draggingExited: (id<NSDraggingInfo>)info
{
    // Re-show the transfer formular if we dragged it out to another view.
    // Hide the formular, however, if it was shown during a template-to-edit operation, which is
    // not yet finished.
    NSWindow *window = [[NSApplication sharedApplication] mainWindow];
    if (!formularVisible && [controller editingInProgress] && NSPointInRect([NSEvent mouseLocation], [window frame])) {
        [self showFormular];
    }
    if (formularVisible && ![controller editingInProgress]) {
        [self hideFormular];
    }
}

- (BOOL)prepareForDragOperation: (id<NSDraggingInfo>)info
{
    return YES;
}

- (BOOL)performDragOperation: (id<NSDraggingInfo>)info
{
    NSPoint location = info.draggingLocation;
    if (NSPointInRect(location, [self dropTargetFrame])) {
        if (currentDragDataType == TransferReadyForUseDataType) {
            
            // Nothing to do for this type.
            return false;
        }
        return [controller startEditingFromDragging: info];
    }
    return false;
}

- (void)concludeDragOperation: (id<NSDraggingInfo>)info
{
}

- (void)draggingEnded: (id <NSDraggingInfo>)info
{
}

- (BOOL)wantsPeriodicDraggingUpdates
{
    return NO;
}

/**
 * Returns the area in which a drop operation is accepted.
 */
- (NSRect)dropTargetFrame
{
    NSRect dragTargetFrame = self.frame;
    dragTargetFrame.size.width -= 150;
    dragTargetFrame.size.height = 350;
    dragTargetFrame.origin.x += 65;
    dragTargetFrame.origin.y += 35;
    
    return dragTargetFrame;
}

- (void)hideFormular
{
    if (formularVisible) {
        formularVisible = NO;
        [[controller.transferFormular animator] removeFromSuperview];
        [[controller.dragToHereLabel animator] setHidden: NO];
    }
}

- (void)showFormular
{
    if (!formularVisible) {
        formularVisible = YES;
        [[controller.dragToHereLabel animator] setHidden: YES];

        NSRect formularFrame = controller.transferFormular.frame;
        formularFrame.origin.x = (self.bounds.size.width - formularFrame.size.width) / 2 - 10;
        formularFrame.origin.y = 0;
        controller.transferFormular.frame = formularFrame;
        
        [[self animator] addSubview: controller.transferFormular];
    }
}

@end

//--------------------------------------------------------------------------------------------------

@interface TransfersController (private)
- (void)updateSourceAccountSelector;
- (void)prepareSourceAccountSelector:(BankAccount *)account forTransferType:(TransferType)transferType;
- (void)updateTargetAccountSelector;
- (void)storeReceiverInMRUList;
@end

@implementation TransfersController

@synthesize transferFormular;
@synthesize dropToEditRejected;


- (void)awakeFromNib
{
    [[mainView window] setInitialFirstResponder: receiverComboBox];

    NSArray *acceptedTypes = @[@(TransferTypeInternal), @(TransferTypeStandard), @(TransferTypeEU),	@(TransferTypeDated),
	    @(TransferTypeSEPA)];
    pendingTransfers.managedObjectContext = MOAssistant.assistant.context;
    pendingTransfers.filterPredicate = [NSPredicate predicateWithFormat: @"type in %@ and isSent = NO and changeState = %d",
                                        acceptedTypes, TransferChangeUnchanged];
    
    // We listen to selection changes in the pending transfers list.
    [pendingTransfers addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: nil];
    
    // The pending transfers list listens to selection changes in the transfers listview (and vice versa).
    [pendingTransfers bind: @"selectionIndexes" toObject: pendingTransfersListView withKeyPath: @"selectedRows" options: nil];
    [pendingTransfersListView bind: @"selectedRows" toObject: pendingTransfers withKeyPath: @"selectionIndexes" options: nil];
    
    finishedTransfers.managedObjectContext = MOAssistant.assistant.context;
    finishedTransfersPredicate = [NSPredicate predicateWithFormat: @"type in %@ and isSent = YES", acceptedTypes];
    finishedTransfers.filterPredicate = finishedTransfersPredicate;

    [transactionController setManagedObjectContext: MOAssistant.assistant.context];

	// Sort transfer list views by date (newest first).
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO];
	NSArray *sds = @[sd];
	[pendingTransfers setSortDescriptors: sds];
	[finishedTransfers setSortDescriptors: sds];
	
    NSDictionary* positiveAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]};
    NSDictionary* negativeAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]};
    
	formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
	[formatter setLocale: [NSLocale currentLocale]];
	[formatter setCurrencySymbol: @""];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    
    [pendingTransfersListView setCellSpacing: 0];
    [pendingTransfersListView setAllowsEmptySelection: YES];
    [pendingTransfersListView setAllowsMultipleSelection: YES];
    NSNumberFormatter* listViewFormatter = [pendingTransfersListView numberFormatter];
    [listViewFormatter setTextAttributesForPositiveValues: positiveAttributes];
    [listViewFormatter setTextAttributesForNegativeValues: negativeAttributes];

    pendingTransfersListView.owner = self;
    [pendingTransfersListView bind: @"dataSource" toObject: pendingTransfers withKeyPath: @"arrangedObjects" options: nil];

    finishedTransfersListView.owner = self;
    [finishedTransfersListView setCellSpacing: 0];
    [finishedTransfersListView setAllowsEmptySelection: YES];
    [finishedTransfersListView setAllowsMultipleSelection: YES];
    listViewFormatter = [finishedTransfersListView numberFormatter];
    [listViewFormatter setTextAttributesForPositiveValues: positiveAttributes];
    [listViewFormatter setTextAttributesForNegativeValues: negativeAttributes];
    
    [finishedTransfersListView bind: @"dataSource" toObject: finishedTransfers withKeyPath: @"arrangedObjects" options: nil];
    [finishedTransfers bind: @"selectionIndexes" toObject: finishedTransfersListView withKeyPath: @"selectedRows" options: nil];
    [finishedTransfersListView bind: @"selectedRows" toObject: finishedTransfers withKeyPath: @"selectionIndexes" options: nil];

    transferTemplateListView.owner = self;
    [transferTemplateListView bind: @"dataSource" toObject: transactionController.templateController withKeyPath: @"arrangedObjects" options: nil];
    [transactionController.templateController bind: @"selectionIndexes" toObject: transferTemplateListView withKeyPath: @"selectedRows" options: nil];
    [transferTemplateListView bind: @"selectedRows" toObject: transactionController.templateController withKeyPath: @"selectionIndexes" options: nil];

    rightPane.controller = self;
    [rightPane registerForDraggedTypes: @[TransferPredefinedTemplateDataType,
                                         TransferDataType, TransferReadyForUseDataType, TransferTemplateDataType]];

    executeImmediatelyRadioButton.target = self;
    executeImmediatelyRadioButton.action = @selector(executionTimeChanged:);
    executeAtDateRadioButton.target = self;
    executeAtDateRadioButton.action = @selector(executionTimeChanged:);

    transferFormular.controller = self;
    transferFormular.draggable = YES;
    bankCode.delegate = self;
    
    transferInternalImage.controller = self;
    [transferInternalImage setFrameCenterRotation: -10];
    transferNormalImage.controller = self;
    [transferNormalImage setFrameCenterRotation: -10];
    transferEUImage.controller = self;
    [transferEUImage setFrameCenterRotation: -10];
    transferSEPAImage.controller = self;
    [transferSEPAImage setFrameCenterRotation: -10];
    
    transferDeleteImage.controller = self;

    // Keep current row positions as set in the xib, so we can properly adjust control positions.
    // For now we don't need row 0 (the row with the receiver controls).
    rowPositions[1] = [[transferFormular viewWithTag: 11] frame].origin.y;
    rowPositions[2] = [[transferFormular viewWithTag: 21] frame].origin.y;
    rowPositions[3] = [[transferFormular viewWithTag: 31] frame].origin.y;
}

- (NSMenuItem*)createItemForAccountSelector: (BankAccount *)account
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: [account localName] action: nil keyEquivalent: @""];
    item.representedObject = account;
    
    return item;
}

/**
 * Refreshes the content of the source account selector.
 * An attempt is made to keep the current selection.
 */
- (void)updateSourceAccountSelector
{
    Transfer *currentTransfer = transactionController.currentTransfer;
    if (currentTransfer != nil) {
        [self prepareSourceAccountSelector: sourceAccountSelector.selectedItem.representedObject forTransferType:currentTransfer.type.intValue];
    }
}

/**
 * Refreshes the content of the source account selector and selects the given account (if found).
 */

- (void)prepareSourceAccountSelector: (BankAccount *)selectedAccount forTransferType:(TransferType)transferType
{
    [sourceAccountSelector removeAllItems];
    
    NSMenu *sourceMenu = [sourceAccountSelector menu];
    
    Category *category = [Category bankRoot];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"localName" ascending: YES];
	NSArray *sortDescriptors = @[sortDescriptor];
    NSArray *institutes = [[category children] sortedArrayUsingDescriptors: sortDescriptors];
    
    // Convert list of accounts in their institutes branches to a flat list
    // usable by the selector.
    NSEnumerator *institutesEnumerator = [institutes objectEnumerator];
    Category *currentInstitute;
    NSInteger selectedItem = -1; // By default no entry is selected.
    while ((currentInstitute = [institutesEnumerator nextObject])) {
        if (![currentInstitute isKindOfClass: [BankAccount class]]) {
            continue;
        }
        
        NSArray        *accounts = [[currentInstitute children] sortedArrayUsingDescriptors: sortDescriptors];
        NSMutableArray *validAccounts = [NSMutableArray arrayWithCapacity: 10];
        NSEnumerator   *accountEnumerator = [accounts objectEnumerator];
        Category       *currentAccount;
        
        while ((currentAccount = [accountEnumerator nextObject])) {
            if (![currentAccount isKindOfClass: [BankAccount class]]) {
                continue;
            }

            BankAccount *account = (BankAccount *)currentAccount;
            
            // Exclude manual accounts from the list.
            if ([account.isManual boolValue]) {
                continue;
            }
            
            // check if the accout supports the current transfer type
            if ([[HBCIClient hbciClient] isTransferSupported:transferType forAccount:account] == NO) {
                continue;
            }
            
            [validAccounts addObject:account];
        }
        
        if ([validAccounts count] > 0) {
            NSMenuItem *item = [self createItemForAccountSelector: (BankAccount *)currentInstitute];
            [sourceMenu addItem: item];
            [item setEnabled: NO];
            for (BankAccount *account in validAccounts) {
                NSMenuItem *item = [self createItemForAccountSelector: account];
                [item setEnabled: YES];
                item.indentationLevel = 1;
                [sourceMenu addItem: item];
                if (account == selectedAccount)
                    selectedItem = sourceMenu.numberOfItems - 1;
            }
        }
    }
    
    if (sourceMenu.numberOfItems > 1) {
        [sourceAccountSelector selectItemAtIndex: selectedItem];
    } else {
        [sourceAccountSelector selectItemAtIndex: -1];
    }
    [self sourceAccountChanged: sourceAccountSelector];
}

/**
 * Refreshes the content of the target account selector, depending on the selected account in
 * the source selector. Since this is for internal transfers only also only siblings of the
 * selected accounts are valid.
 * An attempt is made to keep the currently selected account still selected.
 */
- (void)updateTargetAccountSelector
{
    if (transactionController.currentTransfer.type.intValue != TransferTypeInternal) {
        return;
    }
    
    BankAccount *currentAccount = targetAccountSelector.selectedItem.representedObject;
    BankAccount *sourceAccount = sourceAccountSelector.selectedItem.representedObject;
    
    [targetAccountSelector removeAllItems];
    
    NSMenu *targetMenu = [targetAccountSelector menu];
    
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"localName" ascending: YES];
	NSArray *sortDescriptors = @[sortDescriptor];
    NSArray *siblingAccounts = [[sourceAccount siblings] sortedArrayUsingDescriptors: sortDescriptors];
    NSInteger selectedItem = -1;
    for (BankAccount *account in siblingAccounts) {

        // Exclude manual accounts from the list.
        if ([account.isManual boolValue]) {
            continue;
        }

        NSMenuItem *item = [self createItemForAccountSelector: account];
        [item setEnabled: YES];
        item.indentationLevel = 1;
        [targetMenu addItem: item];
        if (currentAccount == account)
            selectedItem = targetMenu.numberOfItems - 1;
    }
    if (targetMenu.numberOfItems > 1) {
        [targetAccountSelector selectItemAtIndex: selectedItem];
    } else {
        [targetAccountSelector selectItemAtIndex: -1];
    }
    [self targetAccountChanged: targetAccountSelector];
}

/**
 * Prepares the transfer formular for editing a new or existing transfer.
 */
- (BOOL)prepareTransferOfType: (TransferType)type
{
    if ([transactionController editingInProgress]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: NSLocalizedString(@"AP413", @"")];
        [alert runModal];

        return NO;
    }
    
    NSString *remoteAccountKey;
    NSString *remoteBankCodeKey;
    switch (type) {
        case TransferTypeInternal:
            [titleText setStringValue: NSLocalizedString(@"AP403", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP408", @"")];
            transferFormular.icon = [NSImage imageNamed: @"internal-transfer-icon.png"];
            remoteAccountKey = @"selection.remoteAccount";
            remoteBankCodeKey = @"selection.remoteBankCode";
            break;
        case TransferTypeStandard:
        case TransferTypeDated: // TODO: needs to be handled differently, for all the various terminated flavours.
            [titleText setStringValue: NSLocalizedString(@"AP404", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP134", @"")];
            [accountText setStringValue: NSLocalizedString(@"AP401", @"")];
            [bankCodeText setStringValue: NSLocalizedString(@"AP400", @"")];
            transferFormular.icon = [NSImage imageNamed: @"standard-transfer-icon.png"];
            remoteAccountKey = @"selection.remoteAccount";
            remoteBankCodeKey = @"selection.remoteBankCode";
            break;
        case TransferTypeEU:
            [titleText setStringValue: NSLocalizedString(@"AP405", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP134", @"")];
            [accountText setStringValue: NSLocalizedString(@"AP409", @"")];
            [bankCodeText setStringValue: NSLocalizedString(@"AP410", @"")];
            transferFormular.icon = [NSImage imageNamed: @"eu-transfer-icon.png"];
            remoteAccountKey = @"selection.remoteIBAN";
            remoteBankCodeKey = @"selection.remoteBIC";
            break;
        case TransferTypeSEPA:
            [titleText setStringValue: NSLocalizedString(@"AP406", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP134", @"")];
            [accountText setStringValue: NSLocalizedString(@"AP409", @"")];
            [bankCodeText setStringValue: NSLocalizedString(@"AP410", @"")];
            transferFormular.icon = [NSImage imageNamed: @"sepa-transfer-icon.png"];
            remoteAccountKey = @"selection.remoteIBAN";
            remoteBankCodeKey = @"selection.remoteBIC";
            break;
        case TransferTypeDebit:
            [titleText setStringValue: NSLocalizedString(@"AP407", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP134", @"")];
            [accountText setStringValue: NSLocalizedString(@"AP401", @"")];
            [bankCodeText setStringValue: NSLocalizedString(@"AP400", @"")];
            transferFormular.icon = [NSImage imageNamed: @"debit-transfer-icon.png"];
            remoteAccountKey = @"selection.remoteAccount";
            remoteBankCodeKey = @"selection.remoteBankCode";
            break;
        case TransferTypeCollectiveCredit:
        case TransferTypeCollectiveDebit:
            return NO; // Not needed as individual transfer template type.
    }
    
    BOOL isInternal = (type == TransferTypeInternal);
    [targetAccountSelector setHidden: !isInternal];
    [receiverComboBox setHidden: isInternal];
    [accountText setHidden: isInternal];
    [accountNumber setHidden: isInternal];
    [bankCodeText setHidden: isInternal];
    [bankCode setHidden: isInternal];

    BOOL isEUTransfer = (type == TransferTypeEU);
    [targetCountryText setHidden: !isEUTransfer];
    [targetCountrySelector setHidden: !isEUTransfer];
    [feeText setHidden: !isEUTransfer];
    [feeSelector setHidden: !isEUTransfer];
    
    [bankDescription setHidden: type == TransferTypeEU];
    
    if (remoteAccountKey != nil) {
        NSDictionary *options = @{NSValueTransformerNameBindingOption: @"RemoveWhitespaceTransformer"};
        [accountNumber bind: @"value" toObject: transactionController.currentTransferController withKeyPath: remoteAccountKey options: options];
    }
    if (remoteBankCodeKey != nil) {
        NSDictionary *options = @{NSValueTransformerNameBindingOption: @"RemoveWhitespaceTransformer"};
        [bankCode bind: @"value" toObject: transactionController.currentTransferController withKeyPath: remoteBankCodeKey options: options];
    }

    // TODO: adjust formatters for bank code and account number fields depending on the type.
    
    // These business transactions support termination:
    //   - SEPA company/normal single debit/transfer
    //   - SEPA consolidated company/normal debits/transfers
    //   - Standard company/normal single debit/transfer
    //   - Standard consolidated company/normal debits/transfers
    // TODO: the bank has a final word if termination is available, so include this here.
    BOOL canBeTerminated = (type == TransferTypeStandard) || (type == TransferTypeDated); // || (type == TransferTypeSEPA) || (type == TransferTypeDebit);
    [executionText setHidden: !canBeTerminated];
    [executeImmediatelyRadioButton setHidden: !canBeTerminated];
    [executeImmediatelyText setHidden: !canBeTerminated];
    [executeAtDateRadioButton setHidden: !canBeTerminated];
    [executeAtDateLabel setHidden: !canBeTerminated];
    [executionDatePicker setHidden: !canBeTerminated];
    [calendarButton setHidden: !canBeTerminated];
    
    executeAtDateRadioButton.state = (type == TransferTypeDated) ? NSOnState : NSOffState;
    executeImmediatelyRadioButton.state = (type == TransferTypeDated) ? NSOffState : NSOnState;

    executionDatePicker.dateValue = [NSDate date];
    [executionDatePicker setEnabled: type == TransferTypeDated];
    [calendarButton setEnabled: type == TransferTypeDated];

    // Load the set of previously entered text for the receiver combo box.
    [receiverComboBox removeAllItems];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *values = [userDefaults dictionaryForKey: @"transfers"];
    if (values != nil) {
        id previousReceivers = values[@"previousReceivers"];
        if ([previousReceivers isKindOfClass: [NSArray class]]) {
            [receiverComboBox addItemsWithObjectValues: previousReceivers];
        }
    }

    // Finally adjust controls so that no empty row is shown.
    BOOL row1Hidden = [(NSView*)[transferFormular viewWithTag: 11] isHidden];
    BOOL row2Hidden = [(NSView*)[transferFormular viewWithTag: 21] isHidden];

    NSUInteger row2Position = rowPositions[2];
    if (row1Hidden) {
        row2Position = rowPositions[1];
    }

    NSUInteger row3Position = rowPositions[3];
    if (row1Hidden || row2Hidden) {
        if (row1Hidden && row2Hidden) {
            row3Position = rowPositions[1];
        } else {
            row3Position = rowPositions[2];
        }
    }

    if (!row2Hidden) {
        // Labels.
        NSView *view = [transferFormular viewWithTag: 20];
        NSRect newFrame = view.frame;
        newFrame.origin.y = row2Position + 3;
        view.frame = newFrame;

        view = [transferFormular viewWithTag: 22];
        newFrame = view.frame;
        newFrame.origin.y = row2Position + 3;
        view.frame = newFrame;

        // Edit controls.
        view = [transferFormular viewWithTag: 21];
        newFrame = view.frame;
        newFrame.origin.y = row2Position;
        view.frame = newFrame;

        view = [transferFormular viewWithTag: 23];
        newFrame = view.frame;
        newFrame.origin.y = row2Position;
        view.frame = newFrame;
    }
    
    { // 3rd row.
        // Labels.
        NSView *view = [transferFormular viewWithTag: 30];
        NSRect newFrame = view.frame;
        newFrame.origin.y = row3Position + 2;
        view.frame = newFrame;

        view = [transferFormular viewWithTag: 32];
        newFrame = view.frame;
        newFrame.origin.y = row3Position;
        view.frame = newFrame;

        // Edit controls.
        view = [transferFormular viewWithTag: 31];
        newFrame = view.frame;
        newFrame.origin.y = row3Position;
        view.frame = newFrame;

    }
    
    return YES;
}

#pragma mark -
#pragma mark Drag and drop

- (void)draggingStartsFor: (TransfersListView *)sender;
{
    dropToEditRejected = NO;
}

/**
 * Called when the template name sheet ended.
 */
- (void)sheetDidEnd: (NSWindow *)sheet returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo
{
    [sheet orderOut: nil];
    if (returnCode == NSRunStoppedResponse) {
        NSUInteger counter = 0;
        for (Transfer *transfer in draggedTransfers) {
            NSString *actualName = (counter++ == 0) ? [templateName stringValue] : [NSString stringWithFormat: @"%@ %li", [templateName stringValue], counter];
            [transactionController saveTransfer: transfer asTemplateWithName: actualName];
        }
        
        NSManagedObjectContext *context = MOAssistant.assistant.context;
        NSError *error = nil;
        if ([context save: &error ] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
        }
    }
}

/**
 * Used to determine certain cases of drop operations.
 */
- (BOOL)canAcceptDropFor: (id)sender context: (id<NSDraggingInfo>)info
{
    if (sender == finishedTransfersListView) {
        // Can accept drops only from other transfers list views.
        return info.draggingSource == pendingTransfersListView;
    }
    
    if (sender == pendingTransfersListView || sender == transferTemplateListView) {
        NSPasteboard *pasteboard = [info draggingPasteboard];
        NSString *type = [pasteboard availableTypeFromArray: @[TransferDataType, TransferReadyForUseDataType]];
        return type != nil;
    }
    
    return NO;
}

/**
 * Called when the user dragged something on one of the transfers listviews. The meaning depends
 * on the target.
 */
- (void)concludeDropOperation: (id)sender context: (id<NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString *type = [pasteboard availableTypeFromArray: @[TransferDataType, TransferReadyForUseDataType]];
    if (type == nil) {
        return;
    }
    
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    
    if (sender == transferTemplateListView) {
        if (type == TransferReadyForUseDataType) {
            // If this is an edited transfer then finish the edit operation first
            // (and do so the validation) before using it as template.
            if (![transactionController finishCurrentTransfer]) {
                return;
            }
            [rightPane hideFormular];
            draggedTransfers = @[transactionController.currentTransfer];
        } else {
            NSData *data = [pasteboard dataForType: type];
            NSArray *urls = [NSKeyedUnarchiver unarchiveObjectWithData: data];
            NSMutableArray *mutableTransfers = [NSMutableArray array];
            
            for (NSURL *url in urls) {
                NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: url];
                if (objectId == nil) {
                    continue;
                }
                [mutableTransfers addObject: [context objectWithID: objectId]];
            }
            draggedTransfers = mutableTransfers;
        }
        
        // Use the remote name of the first transfer as default for the template name.
        templateName.stringValue = [draggedTransfers[0] remoteName];
        [NSApp beginSheet: templateNameSheet
           modalForWindow: [mainView window]
            modalDelegate: self
           didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
              contextInfo: nil];
        return;
    }
    
    if (type == TransferReadyForUseDataType) {
        if ([transactionController finishCurrentTransfer]) {
            [rightPane hideFormular];
        }
    } else {
        NSData *data = [pasteboard dataForType: type];
        NSArray *transfers = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        
        for (NSURL *url in transfers) {
            NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: url];
            if (objectId == nil) {
                continue;
            }
            Transfer *transfer = (Transfer *)[context objectWithID: objectId];
            transfer.isSent = @((BOOL)(sender == finishedTransfersListView));
        }
        
        NSError *error = nil;
        if ([context save: &error ] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
        }
    }
    
    // Changing the status doesn't refresh the data controllers - so trigger this manually.
    [pendingTransfers prepareContent];
    [finishedTransfers prepareContent];
}

/**
 * Called when the user drags transfers to the waste basket, which represents a delete operation.
 */
- (BOOL)concludeDropDeleteOperation: (id<NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString *type = [pasteboard availableTypeFromArray: @[TransferDataType,
                                                          TransferReadyForUseDataType, TransferTemplateDataType]];
    if (type == nil) {
        return NO;
    }
    
    if (dropToEditRejected) {
        // No delete operation + animation if the drop was rejected.
        return NO;
    }
    
    // If we are deleting a new transfer then silently cancel editing and remove the formular from screen.
    if ((type == TransferReadyForUseDataType) && transactionController.currentTransfer.changeState == TransferChangeNew) {
        [self cancelEditing];
        return YES;
    }
    
    
	NSError *error = nil;
	NSManagedObjectContext *context = MOAssistant.assistant.context;
	
    if (type == TransferReadyForUseDataType) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP417", @""), 
                                  NSLocalizedString(@"AP419", @""),
                                  NSLocalizedString(@"cancel", @""), 
                                  NSLocalizedString(@"delete", @""), 
                                  nil);
        if (res != NSAlertAlternateReturn) {
            return NO;
        }
        
        // We are throwing away the currently being edited transfer which was already placed in the
        // pending transfers queue but brought back for editing. This time the user wants it deleted.
        [rightPane hideFormular];
        Transfer *transfer = transactionController.currentTransfer;
        [self cancelEditing];
        [context deleteObject: transfer];

        if (![context save: &error]) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
        }

        return YES;
    }
    
    NSData *data = [pasteboard dataForType: type];
    NSArray *entries = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    
    NSString *warningTitle;
    if (type == TransferDataType) {
        warningTitle = (entries.count == 1) ? NSLocalizedString(@"AP417", @"") : NSLocalizedString(@"AP418", @"");
    } else {
        warningTitle = (entries.count == 1) ? NSLocalizedString(@"AP421", @"") : NSLocalizedString(@"AP422", @"");
    }
    NSString *warningText = (entries.count == 1) ? NSLocalizedString(@"AP419", @"") : NSLocalizedString(@"AP420", @"");
    int res = NSRunAlertPanel(NSLocalizedString(warningTitle, @""), 
                              NSLocalizedString(warningText, @""),
                              NSLocalizedString(@"cancel", @""), 
                              NSLocalizedString(@"delete", @""), 
                              nil);
    if (res != NSAlertAlternateReturn) {
        return NO;
    }
    
    if (type == TransferDataType) {
        // Pending or finished transfers.
        for (NSURL *url in entries) {
            NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: url];
            if (objectId == nil) {
                continue;
            }
            Transfer *transfer = (Transfer *)[context objectWithID: objectId];
            [context deleteObject: transfer];
        }
    } else {
        // Stored templates.
        for (NSURL *url in entries) {
            NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: url];
            if (objectId == nil) {
                continue;
            }
            NSManagedObject *template = [context objectWithID: objectId];
            [context deleteObject: template];
        }
    }

    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }
    return YES;
}

/**
 * Will be called when the user drags entries from either transfers listview or any of the templates
 * onto the work area.
 */
- (BOOL)prepareEditingFromDragging: (id<NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString *type = [pasteboard availableTypeFromArray:
                      @[TransferDataType,
                        TransferPredefinedTemplateDataType,
                        TransferTemplateDataType]];
    if (type == nil) {
        return NO;
    }
    
    // Dragging a template does not require any more action here.
    if (type == TransferPredefinedTemplateDataType) {
        return YES;
    }
    
	NSManagedObjectContext *context = MOAssistant.assistant.context;
    
    NSData *data = [pasteboard dataForType: type];
    NSArray *transfers = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    
    if (transfers.count > 1) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: NSLocalizedString(@"AP414", @"")];
        [alert runModal];
        
        return NO;
    }
    
    NSURL *url = [transfers lastObject];
    NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: url];
    if (objectId == nil) {
        return NO;
    }
    
    Transfer *transfer = (Transfer *)[context objectWithID: objectId];
    if (![self prepareTransferOfType: [[transfer valueForKey: @"type"] intValue]]) {
        return NO;
    }
    
    BOOL isTerminated = transfer.type.intValue == TransferTypeDated;

    if (isTerminated) {
        executeAtDateRadioButton.state = NSOnState;
        executeImmediatelyRadioButton.state = NSOffState;
    } else {
        executeAtDateRadioButton.state = NSOffState;
        executeImmediatelyRadioButton.state = NSOnState;
    }
    return YES;
}

/**
 * Here we actually try to start the editing process. This method is called when the user dropped
 * a template or an existing transfer entry on the work area.
 */
- (BOOL)startEditingFromDragging: (id<NSDraggingInfo>)info
{
    if ([transactionController editingInProgress]) {
        dropToEditRejected = YES;
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: NSLocalizedString(@"AP413", @"")];
        [alert runModal];
        
        return NO;
    }
    
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString *type = [pasteboard availableTypeFromArray:
                      @[TransferDataType,
                        TransferPredefinedTemplateDataType,
                        TransferTemplateDataType]];
    if (type == nil) {
        return NO;
    }
    
    if (type == TransferPredefinedTemplateDataType) {
        // A new transfer from the template "menu".
        TransferType transferType = [[pasteboard stringForType: TransferPredefinedTemplateDataType] intValue];
        BOOL result = [transactionController newTransferOfType: transferType];
        if (result) {
            [self prepareSourceAccountSelector: nil forTransferType:transferType];
        }
        return result;
    }

    // A previous check has been performed already to ensure only one entry was dragged.
	NSManagedObjectContext *context = MOAssistant.assistant.context;
    
    NSData *data = [pasteboard dataForType: type];
    NSArray *transfers = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    NSURL *url = [transfers lastObject];
    NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: url];
    if (objectId == nil) {
        return NO;
    }

    if (type == TransferTemplateDataType) {
        // A new transfer from a stored template.
        TransferTemplate *template = (TransferTemplate *)[context objectWithID: objectId];
        BOOL result = [transactionController newTransferFromTemplate: template];
        if (result) {
            [self prepareSourceAccountSelector: nil forTransferType:template.type.intValue];
        }
        return result;
    }
    
    Transfer *transfer = (Transfer *)[context objectWithID: objectId];
    BOOL result;
    if (transfer.isSent.intValue == 1) {
        // If this transfer was already sent then create a new transfer from this one.
        result = [transactionController newTransferFromExistingTransfer: transfer];
    } else {
        result = [transactionController editExistingTransfer: transfer];
        [pendingTransfers prepareContent];
    }
    if (result) {
        [self prepareSourceAccountSelector: transfer.account forTransferType:transfer.type.intValue];
    }
    return result;
}

- (void)cancelEditing
{
	// Cancel an ongoing transfer creation (if there is one).
    if (transactionController.editingInProgress) {
        [transactionController cancelCurrentTransfer];

        [rightPane hideFormular];
        [pendingTransfers prepareContent]; // In case we edited an existing transfer.
    }
}

- (BOOL)editingInProgress
{
    return transactionController.editingInProgress;  
}

// checks in the given list of transfers which of them can/should be sent as collective transfers and sends them
// returns the list of transfers still to be sent
- (NSArray*)doSendCollectiveTransfers:(NSArray*)transfers
{
    NSMutableArray *singleTransfers = [NSMutableArray arrayWithCapacity:20 ];
    NSMutableDictionary *transfersByAccount = [NSMutableDictionary dictionaryWithCapacity:10 ];
    for (Transfer *transfer in transfers) {
        BankAccount *account = transfer.account;
        if ([account.collTransferMethod intValue] == CTM_none) {
            [singleTransfers addObject:transfer ];
            continue;
        }
        NSMutableArray *collTransfers = transfersByAccount[account];
        if (collTransfers == nil) {
            transfersByAccount[account] = [NSMutableArray arrayWithCapacity:10 ];
            collTransfers = transfersByAccount[account];
        }
        [collTransfers addObject:transfer ];
    }
    
    // check accounts and transfers
    for (BankAccount *account in [transfersByAccount allKeys ]) {
        BOOL collectiveTransfer = YES;
        
        // sort out single transfers (only one transfer per account)
        NSArray *collTransfers = transfersByAccount[account];
        if ([collTransfers count ] == 1) {
            collectiveTransfer = NO;
        }
        
        // now ask for accounts with method "ask"
        if ([account.collTransferMethod intValue] == CTM_ask) {
            NSInteger res = NSRunAlertPanel(NSLocalizedString(@"AP426", @""), 
                                            NSLocalizedString(@"AP427", @""), 
                                            NSLocalizedString(@"no", @"No"), 
                                            NSLocalizedString(@"yes", @"Yes"), 
                                            nil,
                                            account.accountNumber);
            if (res == NSAlertDefaultReturn) {
                collectiveTransfer = NO;
            }
        }
        
        if (collectiveTransfer == NO) {
            // do not create collective transfer for this account
            for (Transfer *transfer in collTransfers) {
                [singleTransfers addObject:transfer ];
            }
            [transfersByAccount removeObjectForKey:account ];
        } else {
            // now send collective transfer
            PecuniaError *error = [[HBCIClient hbciClient ] sendCollectiveTransfer:collTransfers];
            if (error) {
                [error logMessage ];
            }
        }
    }
    
    // return array of single transfers
    return singleTransfers;
}

/**
 * Sends the given transfers out.
 */
- (void)doSendTransfers: (NSArray*)transfers
{
    if (transfers.count == 0) {
        return;
    }
    
    // Show log output if wanted.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL showLog = [defaults boolForKey: @"logForTransfers"];
    if (showLog) {
        LogController *logController = [LogController logController];
        [logController showWindow: self];
        [[logController window] orderFront: self];
    }
    
    // first check for collective transfers
    transfers = [self doSendCollectiveTransfers:transfers ];
    
    BOOL sent = [[HBCIClient hbciClient] sendTransfers: transfers];
    if (sent) {
        // Save updates and refresh UI.
        NSError *error = nil;
        NSManagedObjectContext *context = MOAssistant.assistant.context;
        if (![context save: &error]) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return;
        }
    }
    [pendingTransfers prepareContent];
    [finishedTransfers prepareContent];
}

- (void)startDonationTransfer
{
    if (![self prepareTransferOfType: TransferTypeStandard]) {
        return;
    }
    
    BOOL result = [transactionController newTransferOfType: TransferTypeStandard];
    if (result) {
        Transfer *transfer = transactionController.currentTransfer;
        transfer.remoteAccount = @"1016381558";
        transfer.remoteBankCode = @"12030000";
        transfer.remoteBankName = [[HBCIClient hbciClient] bankNameForCode: @"12030000" inCountry: @"de"];
        transfer.remoteName = @"Frank Emminghaus";
        transfer.purpose1 = @"Spende fuer Pecunia";
        
        [self prepareSourceAccountSelector: nil forTransferType:TransferTypeStandard];
    }
    
    [rightPane showFormular];
    [amountField.window makeFirstResponder: amountField];
}

- (BOOL)startTransferOfType: (TransferType)type withAccount:(BankAccount*)account
{
    if (![self prepareTransferOfType: type]) {
        return NO;
    }
    
    BOOL result = [transactionController newTransferOfType: type];
    if (result) {
        [self prepareSourceAccountSelector: account forTransferType: type];
        [rightPane showFormular];
    }
    return result;
}

- (BOOL)startTransferFromTemplate: (TransferTemplate *)template
{
    TransferType type = template.type.intValue;
    if (![self prepareTransferOfType:type]) {
        return NO;
    }
    
    BOOL result = [transactionController newTransferFromTemplate: template];
    if (result) {
        [self prepareSourceAccountSelector: nil forTransferType:type];
        [rightPane showFormular];
    }
    return result;
}

#pragma mark -
#pragma mark Actions messages

/**
 * Sends transfers from the pending transfer list. If nothing is selected then all transfers are
 * sent, otherwise only the selected ones are sent.
 */
- (IBAction)sendTransfers: (id)sender
{
    NSArray* transfers = pendingTransfers.selectedObjects;
    if (transfers == nil || transfers.count == 0) {
        transfers = pendingTransfers.arrangedObjects;
    }
    [self doSendTransfers: transfers];
}

/**
 * Places the current transfer in the queue so it can be sent.
 * Actually, the transfer is already in the queue (when it is created) but is marked
 * as being worked on, so it does not appear in the list.
 */
- (IBAction)queueTransfer: (id)sender
{
    [self storeReceiverInMRUList];
    
    if ([transactionController finishCurrentTransfer]) {
        [rightPane hideFormular];
        [pendingTransfers prepareContent];
    }
}

/**
 * Sends the transfer that is currently begin edited.
 */
- (IBAction)sendTransfer: (id)sender
{
    [self storeReceiverInMRUList];
    
    // Can never be called if editing is not in progress, but better safe than sorry.
    if ([self editingInProgress] && [transactionController finishCurrentTransfer]) {
        NSArray* transfers = @[transactionController.currentTransfer];
        [self doSendTransfers: transfers];
        [rightPane hideFormular];
    }
}

- (IBAction)deleteTransfer:(id)sender
{
    // If we are deleting a new transfer then silently cancel editing and remove the formular from screen.
    if (transactionController.currentTransfer.changeState == TransferChangeNew) {
        [self cancelEditing];
        return;
    }

	NSManagedObjectContext *context = MOAssistant.assistant.context;

    int res = NSRunAlertPanel(NSLocalizedString(@"AP417", @""),
                              NSLocalizedString(@"AP419", @""),
                              NSLocalizedString(@"cancel", @""),
                              NSLocalizedString(@"delete", @""),
                              nil);
    if (res != NSAlertAlternateReturn) {
        return;
    }

    // We are throwing away the currently being edited transfer which was already placed in the
    // pending transfers queue but brought back for editing. This time the user wants it deleted.
    [rightPane hideFormular];
    Transfer *transfer = transactionController.currentTransfer;
    [self cancelEditing];
    [context deleteObject: transfer];

	NSError *error = nil;
    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }
}

- (IBAction)saveTemplate: (id)sender
{
    NSString *name = templateName.stringValue;
    if (name.length == 0) {
        NSBeep();
        return;
    }
    [NSApp endSheet: templateNameSheet returnCode: NSRunStoppedResponse];
}

- (IBAction)cancelCreateTemplate: (id)sender
{
    [NSApp endSheet: templateNameSheet returnCode: NSRunAbortedResponse];
}

- (IBAction)showCalendar: (id)sender
{
    if (calendarWindow == nil) {
        NSPoint buttonPoint = NSMakePoint(NSMidX([sender frame]),
                                          NSMidY([sender frame]));
        buttonPoint = [transferFormular convertPoint: buttonPoint toView: nil];
        calendarWindow = (id)[[TransferCalendarWindow alloc] initWithView: calendarView
                                                          attachedToPoint: buttonPoint
                                                                 inWindow: [transferFormular window]
                                                                   onSide: MAPositionTopLeft
                                                               atDistance: 20];

        [calendarWindow setBackgroundColor: [NSColor colorWithCalibratedWhite: 1 alpha: 0.9]];
        [calendarWindow setViewMargin: 0];
        [calendarWindow setBorderWidth: 0];
        [calendarWindow setCornerRadius: 10];
        [calendarWindow setHasArrow: YES];
        [calendarWindow setDrawsRoundCornerBesideArrow: YES];
        
        [calendarWindow setAlphaValue: 0];
        [[sender window] addChildWindow: calendarWindow ordered: NSWindowAbove];
        [calendarWindow fadeIn];
        [calendarWindow makeKeyWindow];
        calendarWindow.delegate = self;
        calendarWindow.controller = self;
        [calendar setDateValue: executionDatePicker.dateValue];
    }
}

/**
 * Called from the calendarWindow.
 */
- (void)windowDidResignKey: (NSNotification *)notification
{
    [self hideCalendarWindow];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self hideCalendarWindow];
}

- (IBAction)calendarChanged: (id)sender
{
    executionDatePicker.dateValue = [sender dateValue];
    transactionController.currentTransfer.valutaDate = [sender dateValue];
    [self hideCalendarWindow];
}

- (IBAction)sourceAccountChanged: (id)sender
{
    if (![self editingInProgress]) {
        return;
    }

    BOOL accountSelected = [sender selectedItem] != nil;
    for (NSUInteger row = 0; row <= 5; row++) {
        for (NSUInteger index = 0; index < 5; index++) {
            [[transferFormular viewWithTag: row * 10 + index] setEnabled: accountSelected];
        }
    }
    
    if (!accountSelected) {
        [saldoText setObjectValue: @""];
    } else {
        BankAccount *account = [sender selectedItem].representedObject;
        [saldoText setObjectValue: [account catSum]];

        transactionController.currentTransfer.account = account;

        if (account.currency.length == 0) {
            transactionController.currentTransfer.currency = @"EUR";
        } else {
            transactionController.currentTransfer.currency = account.currency;
        }
    }
    [self updateTargetAccountSelector];
    [self updateLimits];
}

- (IBAction)targetAccountChanged: (id)sender
{
    if (![self editingInProgress] || transactionController.currentTransfer.type.intValue != TransferTypeInternal) {
        return;
    }
    
    BankAccount *account = targetAccountSelector.selectedItem.representedObject;
    transactionController.currentTransfer.remoteName = account.owner;
    transactionController.currentTransfer.remoteAccount = account.accountNumber;
    transactionController.currentTransfer.remoteBankCode = account.bankCode;
    transactionController.currentTransfer.remoteBankName = account.bankName;

}

- (IBAction)executionTimeChanged: (id)sender
{
    if (sender == executeImmediatelyRadioButton) {
        executeAtDateRadioButton.state = NSOffState;
        [executionDatePicker setEnabled: NO];
        [calendarButton setEnabled: NO];

        // Remove valuta date, which is used to automatically switch to the dated type of the
        // transfer (in the transaction controller). Set the transfer type accordingly in case it was changed.
        transactionController.currentTransfer.valutaDate = nil;
        transactionController.currentTransfer.type = @(TransferTypeStandard);
    } else {
        executeImmediatelyRadioButton.state = NSOffState;
        [executionDatePicker setEnabled: YES];
        [calendarButton setEnabled: YES];

        transactionController.currentTransfer.valutaDate = executionDatePicker.dateValue;
        transactionController.currentTransfer.type = @(TransferTypeDated);
    }
}

/**
 * Triggered by the listview when the user pressed the forward delete button or the backward delete button
 * in conjunction with the command key.
 */
- (void)deleteSelectionFrom: (id)sender
{
    NSArray *selection;
    if (sender == transferTemplateListView) {
        selection = transactionController.templateController.selectedObjects;
    } else if (sender == pendingTransfersListView) {
        selection = pendingTransfers.selectedObjects;
    } else {
        selection = finishedTransfers.selectedObjects;
    }
    
    if (selection.count == 0) {
        return;
    }

    NSString *warningTitle;
    if (sender != transferTemplateListView) {
        warningTitle = (selection.count == 1) ? NSLocalizedString(@"AP417", @"") : NSLocalizedString(@"AP418", @"");
    } else {
        warningTitle = (selection.count == 1) ? NSLocalizedString(@"AP421", @"") : NSLocalizedString(@"AP422", @"");
    }
    NSString *warningText = (selection.count == 1) ? NSLocalizedString(@"AP419", @"") : NSLocalizedString(@"AP420", @"");
    int res = NSRunAlertPanel(NSLocalizedString(warningTitle, @""),
                              NSLocalizedString(warningText, @""),
                              NSLocalizedString(@"cancel", @""),
                              NSLocalizedString(@"delete", @""),
                              nil);
    if (res != NSAlertAlternateReturn) {
        return;
    }

    if (sender == transferTemplateListView) {
        [transactionController.templateController removeObjects: selection];
    } else if (sender == pendingTransfersListView) {
        [pendingTransfers removeObjects: selection];
    } else {
        [finishedTransfers removeObjects: selection];
    }

	NSError *error = nil;
	NSManagedObjectContext *context = MOAssistant.assistant.context;

    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }
}

#pragma mark -
#pragma mark Search/Filtering

-(IBAction)filterStatements: (id)sender
{
    NSString *searchString = [sender stringValue];

    if ([searchString length] == 0) {
        [finishedTransfers setFilterPredicate: finishedTransfersPredicate];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"currency contains[c] %@ or "
                                  "purpose1 contains[c] %@ or "
                                  "purpose2 contains[c] %@ or "
                                  "purpose3 contains[c] %@ or "
                                  "purpose4 contains[c] %@ or "
                                  "remoteAccount contains[c] %@ or "
                                  "remoteAddrCity contains[c] %@ or "
                                  "remoteAddrPhone contains[c] %@ or "
                                  "remoteAddrStreet contains[c] %@ or "
                                  "remoteAddrZip contains[c] %@ or "
                                  "remoteBankCode contains[c] %@ or "
                                  "remoteBankName contains[c] %@ or "
                                  "remoteBIC contains[c] %@ or "
                                  "remoteCountry contains[c] %@ or "
                                  "remoteIBAN contains[c] %@ or "
                                  "remoteName contains[c] %@ or "
                                  "remoteSuffix contains[c] %@ or "
                                  "value = %@",
                                  searchString, searchString, searchString, searchString, searchString, searchString,
                                  searchString, searchString, searchString, searchString, searchString, searchString,
                                  searchString, searchString, searchString, searchString, searchString,
                                  [NSDecimalNumber decimalNumberWithString: searchString locale: [NSLocale currentLocale]]
                                 ];
        NSPredicate *comp = [NSCompoundPredicate andPredicateWithSubpredicates:@[finishedTransfersPredicate, predicate]];
        [finishedTransfers setFilterPredicate: comp];
    }
}

-(IBAction)filterTemplates: (id)sender
{
    NSString *searchString = [sender stringValue];

    if ([searchString length] == 0) {
        [transactionController.templateController setFilterPredicate: nil];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"purpose contains[c] %@ or "
                                  "remoteAccount contains[c] %@ or "
                                  "remoteBankCode contains[c] %@ or "
                                  "remoteBIC contains[c] %@ or "
                                  "remoteCountry contains[c] %@ or "
                                  "remoteIBAN contains[c] %@ or "
                                  "remoteName contains[c] %@ or "
                                  "remoteSuffix contains[c] %@",
                                  searchString, searchString, searchString,
                                  searchString, searchString, searchString,
                                  searchString, searchString, searchString,
                                  [NSDecimalNumber decimalNumberWithString: searchString locale: [NSLocale currentLocale]]
                                  ];
        [transactionController.templateController setFilterPredicate: predicate];
    }
}

#pragma mark -
#pragma mark Other application logic

- (void)updateLimits
{
    // currentTransfer must be valid
    limits = [[HBCIClient hbciClient] limitsForType:transactionController.currentTransfer.type.intValue
                                            account:transactionController.currentTransfer.account
                                            country:transactionController.currentTransfer.remoteCountry];
    
    [purpose2 setHidden: limits.maxLinesPurpose < 2 && limits.maxLinesPurpose > 0];
    [purpose3 setHidden: limits.maxLinesPurpose < 3 && limits.maxLinesPurpose > 0];
    [purpose4 setHidden: limits.maxLinesPurpose < 4 && limits.maxLinesPurpose > 0];
    
    if (limits.maxLinesPurpose > 0) {
        if (limits.maxLinesPurpose < 2 && transactionController.currentTransfer.purpose2 && [transactionController.currentTransfer.purpose2 length] > 0) {
            transactionController.currentTransfer.purpose2 = nil;
        }
        if (limits.maxLinesPurpose < 3 && transactionController.currentTransfer.purpose3 && [transactionController.currentTransfer.purpose3 length] > 0) {
            transactionController.currentTransfer.purpose3 = nil;
        }
        if (limits.maxLinesPurpose < 4 && transactionController.currentTransfer.purpose4 && [transactionController.currentTransfer.purpose4 length] > 0) {
            transactionController.currentTransfer.purpose4 = nil;
        }
    }
    
    // check if dated is allowed
    // At the moment this is only possible for Standard Transfers
    TransferType tt = transactionController.currentTransfer.type.intValue;
    BOOL allowsDated = NO;
    if (tt == TransferTypeStandard || tt == TransferTypeDated) {
        if ([[HBCIClient hbciClient] isTransferSupported:TransferTypeDated forAccount:transactionController.currentTransfer.account]) {
            [executeAtDateRadioButton setEnabled:YES];
            allowsDated = YES;
        }
    }
    if (allowsDated == NO) {
        [executeAtDateRadioButton setEnabled:NO];
        [executionDatePicker setEnabled: NO];
        [calendarButton setEnabled: NO];
    }
}


- (void)releaseCalendarWindow
{
    [[calendarButton window] removeChildWindow: calendarWindow];
    [calendarWindow orderOut: self];
    calendarWindow = nil;
}

- (void)hideCalendarWindow
{
    if (calendarWindow != nil) {
        [calendarWindow fadeOut];
        
        // We need to delay the release of the calendar window
        // otherwise it will just disappear instead to fade out.
        [NSTimer scheduledTimerWithTimeInterval: .5
                                         target: self 
                                       selector: @selector(releaseCalendarWindow)
                                       userInfo: nil
                                        repeats: NO];
    }
}

/**
 * Stores the current value of the receiver edit field in the MRU list used for lookup
 * of previously entered receivers. The list is kept at no more than 15 entries and no duplicates.
 */
- (void)storeReceiverInMRUList
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *values = [userDefaults dictionaryForKey: @"transfers"];
    NSMutableDictionary *mutableValues;
    if (values == nil) {
        mutableValues = [NSMutableDictionary dictionary];
    } else {
        mutableValues = [values mutableCopy];
    }
    
    NSString *newValue = receiverComboBox.stringValue;
    id previousReceivers = values[@"previousReceivers"];
    NSMutableArray *mutableReceivers;
    if (![previousReceivers isKindOfClass: [NSArray class]]) {
        mutableReceivers = [NSMutableArray arrayWithObject: newValue];
    } else {
        mutableReceivers = [previousReceivers mutableCopy];
    }

    // Now remove a possible duplicate and add the new entry
    // at the top. Remove any entry beyond the first 15 entries finally.
    [mutableReceivers removeObject: newValue];
    [mutableReceivers insertObject: newValue atIndex: 0];
    if ([mutableReceivers count] > 15) {
        NSRange unwantedEntries = NSMakeRange(15, [mutableReceivers count] - 15);
        if (unwantedEntries.length > 0) {
            [mutableReceivers removeObjectsInRange: unwantedEntries];
        }
    }
    
    mutableValues[@"previousReceivers"] = mutableReceivers;
    [userDefaults setObject: mutableValues forKey: @"transfers"];
}

#pragma mark -
#pragma mark Other delegate methods

-(void)controlTextDidChange: (NSNotification*)aNotification
{
	NSTextField	*te = [aNotification object ];
	NSUInteger maxLen;
	
	if(te == purpose1 || te == purpose2 || te == purpose3 || te == purpose4) maxLen = limits.maxLenPurpose;
	else if(te == receiverComboBox) maxLen = limits.maxLengthRemoteName;
	else return;
	
	if ([[te stringValue ] length ] > maxLen) {
		[te setStringValue:  [[te stringValue ] substringToIndex: maxLen ] ];
		NSBeep();
		return;
	};
	return;
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
	NSTextField	*textField = [aNotification object];
	NSString *bankName = nil;

	if (textField == bankCode || textField == accountNumber) {
        NSString *s = [textField stringValue];
        s = [s stringByRemovingWhitespaces:s];
        s = [s uppercaseString];
        [textField setStringValue:s];
    }
    
	if (transactionController.currentTransfer.type.intValue == TransferTypeEU ||
        transactionController.currentTransfer.type.intValue == TransferTypeSEPA) {
        if (textField == accountNumber) {
            NSString *s = [textField stringValue];
            if ([s hasPrefix:@"DE"]) {
                bankName = [[HBCIClient hbciClient] bankNameForCode: [s substringWithRange: NSMakeRange(4, 8) ]
                                                          inCountry: transactionController.currentTransfer.remoteCountry];
            }
        }
	} else {
        if (textField == bankCode) {
            bankName = [[HBCIClient hbciClient] bankNameForCode: [textField stringValue]
                                                      inCountry: transactionController.currentTransfer.remoteCountry];
        }
 	}
	if (bankName != nil) {
        transactionController.currentTransfer.remoteBankName = bankName;
    }
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context
{
    if (object == pendingTransfers) {
        if (pendingTransfers.selectedObjects.count == 0) {
            sendTransfersButton.title = NSLocalizedString(@"AP415", @"");
        } else {
            sendTransfersButton.title = NSLocalizedString(@"AP416", @"");
        }
        [sendTransfersButton setEnabled: [pendingTransfers.arrangedObjects count] > 0];
    }
}

#pragma mark -
#pragma mark PecuniaTabItem protocol

- (NSView *)mainView
{
    return mainView;
}

- (void)prepare
{
}

- (void)activate
{
    [self updateSourceAccountSelector];
}

- (void)deactivate
{
    [self hideCalendarWindow];
}

- (void)terminate
{
    [self cancelEditing];
}

- (void)print
{
    NSInteger idx = [transferTab indexOfTabViewItem:[transferTab selectedTabViewItem]];
    if (idx == NSNotFound) {
        return;
    }
    
    if (idx == 0) {
        // transfers
        NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo];
        [printInfo setTopMargin: 45];
        [printInfo setBottomMargin: 45];
        NSPrintOperation *printOp;
        NSView *view = [[TransferPrintView alloc] initWithTransfers:[finishedTransfers arrangedObjects ] printInfo:printInfo];
        printOp = [NSPrintOperation printOperationWithView:view printInfo: printInfo];
        [printOp setShowsPrintPanel: YES];
        [printOp runOperation];
        
    }
}

@end
