/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

#import "DebitsController.h"
#import "PecuniaError.h"
#import "LogController.h"
#import "HBCIClient.h"
#import "MOAssistant.h"
#import "BankAccount.h"
#import "TransferPrintView.h"
#import "TransactionLimits.h"
#import "TransactionController.h"
#import "DebitFormularView.h"
#import "GradientButtonCell.h"
#import "NSString+PecuniaAdditions.h"
#import "GraphicsAdditions.h"
#import "AnimationHelper.h"

extern NSString *StatementDateKey;
extern NSString *StatementTurnoversKey;
extern NSString *StatementRemoteNameKey;
extern NSString *StatementPurposeKey;
extern NSString *StatementCategoriesKey;
extern NSString *StatementValueKey;
extern NSString *StatementSaldoKey;
extern NSString *StatementCurrencyKey;
extern NSString *StatementTransactionTextKey;
extern NSString *StatementIndexKey;
extern NSString *StatementNoteKey;
extern NSString *StatementRemoteBankNameKey;
extern NSString *StatementColorKey;
extern NSString *StatementRemoteAccountKey;
extern NSString *StatementRemoteBankCodeKey;
extern NSString *StatementRemoteIBANKey;
extern NSString *StatementRemoteBICKey;
extern NSString *StatementTypeKey;

NSString *const DebitPredefinedTemplateDataType = @"DebitPredefinedTemplateDataType"; // For dragging one of the "menu" template images.
NSString *const DebitDataType = @"DebitDataType"; // For dragging an existing debit (sent or not).
extern NSString *DebitReadyForUseDataType;        // For dragging an edited transfer.

@interface DeleteDebitTargetView : NSImageView
{
}

@property (nonatomic, weak) DebitsController *controller;

@end

@implementation DeleteDebitTargetView

@synthesize controller;

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];

    // Register for types that can be deleted.
    [self registerForDraggedTypes: @[DebitDataType, DebitReadyForUseDataType]];
}

- (NSDragOperation)draggingEntered: (id <NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString     *type = [pasteboard availableTypeFromArray: @[DebitDataType, DebitReadyForUseDataType]];
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

@interface DebitDragImageView : NSImageView
{
@private
    BOOL canDrag;

}

@property (nonatomic, weak) DebitsController *controller;

@end

@implementation DebitDragImageView

@synthesize controller;

- (void)mouseDown: (NSEvent *)theEvent
{
    if ([theEvent clickCount] > 1) {
        if (![controller startDebitOfType: TransferTypeDebit withAccount: nil]) {
            [super mouseDown: theEvent];
        }
        return;
    }

    // Keep track of mouse clicks in the view because mouseDragged may be called even when another
    // view was clicked on.
    canDrag = YES;
    [super mouseDown: theEvent];
}

- (void)mouseUp: (NSEvent *)theEvent
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
            type = TransferTypeDebit;
            break;
    }

    if ([controller prepareDebitOfType: type]) {
        NSPasteboard *pasteBoard = [NSPasteboard pasteboardWithUniqueName];
        [pasteBoard setString: [NSString stringWithFormat: @"%i", type] forType: DebitPredefinedTemplateDataType];

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

- (NSDragOperation)draggingSourceOperationMaskForLocal: (BOOL)isLocal
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

@implementation DebitTemplateDragDestination

@synthesize controller;

- (id)initWithFrame: (NSRect)frameRect
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
                           @[DebitDataType,
                           DebitPredefinedTemplateDataType,
                           DebitReadyForUseDataType]];
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
        if ((currentDragDataType == DebitDataType || currentDragDataType == DebitPredefinedTemplateDataType)
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
        if (currentDragDataType != DebitReadyForUseDataType && ![controller editingInProgress]) {
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
        if (currentDragDataType == DebitReadyForUseDataType) {
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
        [[controller.debitFormular animator] removeFromSuperview];
        [[controller.dragToHereLabel animator] setHidden: NO];
    }
}

- (void)showFormular
{
    if (!formularVisible) {
        formularVisible = YES;
        [[controller.dragToHereLabel animator] setHidden: YES];

        NSRect formularFrame = controller.debitFormular.frame;
        formularFrame.origin.x = (self.bounds.size.width - formularFrame.size.width) / 2 - 10;
        formularFrame.origin.y = 0;
        controller.debitFormular.frame = formularFrame;

        [[self animator] addSubview: controller.debitFormular];
    }
}

@end

//--------------------------------------------------------------------------------------------------

@interface DebitsController (private)
- (void)prepareTargetAccountSelector: (BankAccount *)account forTransferType: (TransferType)transferType;
- (void)updateTargetAccountSelector;
- (void)storeReceiverInMRUList;
@end

@implementation DebitsController

@synthesize debitFormular;
@synthesize dropToEditRejected;


- (void)awakeFromNib
{
    [[mainView window] setInitialFirstResponder: receiverComboBox];

    NSArray *acceptedTypes = @[@(TransferTypeDebit), @(TransferTypeCollectiveDebit)];

    pendingDebits.managedObjectContext = MOAssistant.assistant.context;
    pendingDebits.filterPredicate = [NSPredicate predicateWithFormat: @"type in %@ and isSent = NO and changeState = %d",
                                     acceptedTypes, TransferChangeUnchanged];

    // We listen to selection changes in the pending transfers list.
    [pendingDebits addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: nil];

    // The pending transfers list listens to selection changes in the transfers listview (and vice versa).
    [pendingDebits bind: @"selectionIndexes" toObject: pendingDebitsListView withKeyPath: @"selectedRows" options: nil];
    [pendingDebitsListView bind: @"selectedRows" toObject: pendingDebits withKeyPath: @"selectionIndexes" options: nil];

    finishedDebits.managedObjectContext = MOAssistant.assistant.context;
    finishedDebits.filterPredicate = [NSPredicate predicateWithFormat: @"type in %@ and isSent = YES", acceptedTypes];

    [transactionController setManagedObjectContext: MOAssistant.assistant.context];

    // Sort transfer list views by date (newest first).
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO];
    NSArray          *sds = @[sd];
    [pendingDebits setSortDescriptors: sds];
    [finishedDebits setSortDescriptors: sds];

    [pendingDebitsListView setCellSpacing: 0];
    [pendingDebitsListView setAllowsEmptySelection: YES];
    [pendingDebitsListView setAllowsMultipleSelection: YES];

    pendingDebitsListView.owner = self;
    [pendingDebitsListView bind: @"dataSource" toObject: pendingDebits withKeyPath: @"arrangedObjects" options: nil];

    finishedDebitsListView.owner = self;
    [finishedDebitsListView setCellSpacing: 0];
    [finishedDebitsListView setAllowsEmptySelection: YES];
    [finishedDebitsListView setAllowsMultipleSelection: YES];

    [finishedDebitsListView bind: @"dataSource" toObject: finishedDebits withKeyPath: @"arrangedObjects" options: nil];
    [finishedDebits bind: @"selectionIndexes" toObject: finishedDebitsListView withKeyPath: @"selectedRows" options: nil];
    [finishedDebitsListView bind: @"selectedRows" toObject: finishedDebits withKeyPath: @"selectionIndexes" options: nil];

    rightPane.controller = self;
    [rightPane registerForDraggedTypes: @[DebitPredefinedTemplateDataType, DebitDataType, DebitReadyForUseDataType]];

    executeImmediatelyRadioButton.target = self;
    executeImmediatelyRadioButton.action = @selector(executionTimeChanged:);
    executeAtDateRadioButton.target = self;
    executeAtDateRadioButton.action = @selector(executionTimeChanged:);

    debitFormular.controller = self;
    debitFormular.draggable = YES;
    bankCode.delegate = self;

    debitImage.controller = self;
    [debitImage setFrameCenterRotation: -10];
    debitDeleteImage.controller = self;

    // Keep current row positions as set in the xib, so we can properly adjust control positions.
    // For now we don't need row 0 (the row with the receiver controls).
    rowPositions[1] = [[debitFormular viewWithTag: 11] frame].origin.y;
    rowPositions[2] = [[debitFormular viewWithTag: 21] frame].origin.y;
    rowPositions[3] = [[debitFormular viewWithTag: 31] frame].origin.y;
}

- (NSMenuItem *)createItemForAccountSelector: (BankAccount *)account
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: [account localName] action: nil keyEquivalent: @""];
    item.representedObject = account;

    return item;
}

/**
 * Refreshes the content of the target account selector.
 * An attempt is made to keep the current selection.
 */
- (void)updateTargetAccountSelector
{
    Transfer *currentTransfer = transactionController.currentTransfer;
    if (currentTransfer != nil) {
        [self prepareTargetAccountSelector: targetAccountSelector.selectedItem.representedObject forTransferType: currentTransfer.type.intValue];
    }
}

/**
 * Refreshes the content of the source account selector and selects the given account (if found).
 */

- (void)prepareTargetAccountSelector: (BankAccount *)selectedAccount forTransferType: (TransferType)transferType
{
    [targetAccountSelector removeAllItems];

    NSMenu *sourceMenu = [targetAccountSelector menu];

    Category         *category = [Category bankRoot];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"localName" ascending: YES];
    NSArray          *sortDescriptors = @[sortDescriptor];
    NSArray          *institutes = [[category children] sortedArrayUsingDescriptors: sortDescriptors];

    // Convert list of accounts in their institutes branches to a flat list
    // usable by the selector.
    NSEnumerator *institutesEnumerator = [institutes objectEnumerator];
    Category     *currentInstitute;
    NSInteger    selectedItem = 1; // By default the first entry after the first institute entry is selected.
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
            if (![[HBCIClient hbciClient] isTransferSupported: transferType forAccount: account]) {
                continue;
            }

            [validAccounts addObject: account];
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
                if (account == selectedAccount) {
                    selectedItem = sourceMenu.numberOfItems - 1;
                }
            }
        }
    }

    if (sourceMenu.numberOfItems > 1) {
        [targetAccountSelector selectItemAtIndex: selectedItem];
    } else {
        [targetAccountSelector selectItemAtIndex: -1];
    }
    [self targetAccountChanged: targetAccountSelector];
}

/**
 * Prepares the transfer formular for editing a new or existing transfer.
 */
- (BOOL)prepareDebitOfType: (TransferType)type
{
    if ([transactionController editingInProgress]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: NSLocalizedString(@"AP413", nil)];
        [alert runModal];

        return NO;
    }

    NSString *remoteAccountKey;
    NSString *remoteBankCodeKey;

    // Only debit transfer types must be passed in here.
    switch (type) {
        case TransferTypeDebit:
            [titleText setStringValue: NSLocalizedString(@"AP407", nil)];
            [receiverText setStringValue: NSLocalizedString(@"AP208", nil)];
            [accountText setStringValue: NSLocalizedString(@"AP401", nil)];
            [bankCodeText setStringValue: NSLocalizedString(@"AP400", nil)];
            debitFormular.icon = [NSImage imageNamed: @"debit-transfer-icon.png"];
            remoteAccountKey = @"selection.remoteAccount";
            remoteBankCodeKey = @"selection.remoteBankCode";
            break;

        case TransferTypeCollectiveCredit:
        case TransferTypeCollectiveDebit:
            return NO; // Not needed as individual transfer template type.

        default:
            return NO;
    }

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
    BOOL canBeTerminated = (type == TransferTypeOldStandard) || (type == TransferTypeOldStandardScheduled); // || (type == TransferTypeSEPA) || (type == TransferTypeDebit);
    [executeImmediatelyRadioButton setHidden: !canBeTerminated];
    [executeImmediatelyText setHidden: !canBeTerminated];
    [executeAtDateRadioButton setHidden: !canBeTerminated];
    [executeAtDateLabel setHidden: !canBeTerminated];
    [executionDatePicker setHidden: !canBeTerminated];
    [calendarButton setHidden: !canBeTerminated];

    executeAtDateRadioButton.state = (type == TransferTypeOldStandardScheduled) ? NSOnState : NSOffState;
    executeImmediatelyRadioButton.state = (type == TransferTypeOldStandardScheduled) ? NSOffState : NSOnState;

    executionDatePicker.dateValue = [NSDate date];
    [executionDatePicker setEnabled: type == TransferTypeOldStandardScheduled];
    [calendarButton setEnabled: type == TransferTypeOldStandardScheduled];

    // Load the set of previously entered text for the receiver combo box.
    [receiverComboBox removeAllItems];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary   *values = [userDefaults dictionaryForKey: @"transfers"];
    if (values != nil) {
        id previousReceivers = values[@"previousReceivers"];
        if ([previousReceivers isKindOfClass: [NSArray class]]) {
            [receiverComboBox addItemsWithObjectValues: previousReceivers];
        }
    }

    // Finally adjust controls so that no empty row is shown.
    BOOL row1Hidden = [(NSView *)[debitFormular viewWithTag: 11] isHidden];
    BOOL row2Hidden = [(NSView *)[debitFormular viewWithTag: 21] isHidden];

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
        NSView *view = [debitFormular viewWithTag: 20];
        NSRect newFrame = view.frame;
        newFrame.origin.y = row2Position + 3;
        view.frame = newFrame;

        view = [debitFormular viewWithTag: 22];
        newFrame = view.frame;
        newFrame.origin.y = row2Position + 3;
        view.frame = newFrame;

        // Edit controls.
        view = [debitFormular viewWithTag: 21];
        newFrame = view.frame;
        newFrame.origin.y = row2Position;
        view.frame = newFrame;

        view = [debitFormular viewWithTag: 23];
        newFrame = view.frame;
        newFrame.origin.y = row2Position;
        view.frame = newFrame;
    }

    {   // 3rd row.
        // Labels.
        NSView *view = [debitFormular viewWithTag: 30];
        NSRect newFrame = view.frame;
        newFrame.origin.y = row3Position + 2;
        view.frame = newFrame;

        view = [debitFormular viewWithTag: 32];
        newFrame = view.frame;
        newFrame.origin.y = row3Position;
        view.frame = newFrame;

        // Edit controls.
        view = [debitFormular viewWithTag: 31];
        newFrame = view.frame;
        newFrame.origin.y = row3Position;
        view.frame = newFrame;

    }

    return YES;
}

#pragma mark -
#pragma mark Drag and drop

- (void)draggingStartsFor: (DebitsListView *)sender;
{
    dropToEditRejected = NO;
}

/**
 * Used to determine certain cases of drop operations.
 */
- (BOOL)canAcceptDropFor: (id)sender context: (id<NSDraggingInfo>)info
{
    if (sender == finishedDebitsListView) {
        // Can accept drops only from other transfers list views.
        return info.draggingSource == pendingDebitsListView;
    }

    if (sender == pendingDebitsListView) {
        NSPasteboard *pasteboard = [info draggingPasteboard];
        NSString     *type = [pasteboard availableTypeFromArray: @[DebitDataType, DebitReadyForUseDataType]];
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
    NSString     *type = [pasteboard availableTypeFromArray: @[DebitDataType, DebitReadyForUseDataType]];
    if (type == nil) {
        return;
    }

    NSManagedObjectContext *context = MOAssistant.assistant.context;

    if (type == DebitReadyForUseDataType) {
        if ([transactionController finishCurrentTransfer]) {
            [rightPane hideFormular];
        }
    } else {
        NSData  *data = [pasteboard dataForType: type];
        NSArray *transfers = [NSKeyedUnarchiver unarchiveObjectWithData: data];

        for (NSURL *url in transfers) {
            NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: url];
            if (objectId == nil) {
                continue;
            }
            Transfer *transfer = (Transfer *)[context objectWithID: objectId];
            transfer.isSent = @((BOOL)(sender == finishedDebitsListView));
        }
        NSError *error = nil;
        if ([context save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
        }
    }

    // Changing the status doesn't refresh the data controllers - so trigger this manually.
    [pendingDebits prepareContent];
    [finishedDebits prepareContent];
}

/**
 * Called when the user drags transfers to the waste basket, which represents a delete operation.
 */
- (BOOL)concludeDropDeleteOperation: (id<NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString     *type = [pasteboard availableTypeFromArray: @[DebitDataType, DebitReadyForUseDataType]];
    if (type == nil) {
        return NO;
    }

    if (dropToEditRejected) {
        // No delete operation + animation if the drop was rejected.
        return NO;
    }

    // If we are deleting a new transfer then silently cancel editing and remove the formular from screen.
    if ((type == DebitReadyForUseDataType) && transactionController.currentTransfer.changeState == TransferChangeNew) {
        [self cancelEditing];
        return YES;
    }


    NSError                *error = nil;
    NSManagedObjectContext *context = MOAssistant.assistant.context;

    if (type == DebitReadyForUseDataType) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP417", nil),
                                  NSLocalizedString(@"AP419", nil),
                                  NSLocalizedString(@"AP2", nil),
                                  NSLocalizedString(@"AP10", nil),
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

    NSData  *data = [pasteboard dataForType: type];
    NSArray *entries = [NSKeyedUnarchiver unarchiveObjectWithData: data];

    NSString *warningTitle;
    if (type == DebitDataType) {
        warningTitle = (entries.count == 1) ? NSLocalizedString(@"AP417", nil) : NSLocalizedString(@"AP418", nil);
    } else {
        warningTitle = (entries.count == 1) ? NSLocalizedString(@"AP421", nil) : NSLocalizedString(@"AP422", nil);
    }
    NSString *warningText = (entries.count == 1) ? NSLocalizedString(@"AP419", nil) : NSLocalizedString(@"AP420", nil);
    int      res = NSRunAlertPanel(NSLocalizedString(warningTitle, nil),
                                   NSLocalizedString(warningText, nil),
                                   NSLocalizedString(@"AP2", nil),
                                   NSLocalizedString(@"AP10", nil),
                                   nil);
    if (res != NSAlertAlternateReturn) {
        return NO;
    }

    if (type == DebitDataType) {
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
    NSString     *type = [pasteboard availableTypeFromArray: @[DebitDataType, DebitPredefinedTemplateDataType, ]];
    if (type == nil) {
        return NO;
    }

    // Dragging a template does not require any more action here.
    if (type == DebitPredefinedTemplateDataType) {
        return YES;
    }

    NSManagedObjectContext *context = MOAssistant.assistant.context;

    NSData  *data = [pasteboard dataForType: type];
    NSArray *transfers = [NSKeyedUnarchiver unarchiveObjectWithData: data];

    if (transfers.count > 1) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: NSLocalizedString(@"AP414", nil)];
        [alert runModal];

        return NO;
    }

    NSURL             *url = [transfers lastObject];
    NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: url];
    if (objectId == nil) {
        return NO;
    }

    Transfer *transfer = (Transfer *)[context objectWithID: objectId];
    if (![self prepareDebitOfType: [[transfer valueForKey: @"type"] intValue]]) {
        return NO;
    }

    BOOL isTerminated = transfer.type.intValue == TransferTypeOldStandardScheduled;

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
        [alert setMessageText: NSLocalizedString(@"AP413", nil)];
        [alert runModal];

        return NO;
    }

    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString     *type = [pasteboard availableTypeFromArray: @[DebitDataType, DebitPredefinedTemplateDataType]];
    if (type == nil) {
        return NO;
    }

    if (type == DebitPredefinedTemplateDataType) {
        // A new transfer from the template "menu".
        TransferType transferType = [[pasteboard stringForType: DebitPredefinedTemplateDataType] intValue];
        BOOL         result = [transactionController newTransferOfType: transferType];
        if (result) {
            [self prepareTargetAccountSelector: nil forTransferType: transferType];
        }
        return result;
    }

    // A previous check has been performed already to ensure only one entry was dragged.
    NSManagedObjectContext *context = MOAssistant.assistant.context;

    NSData            *data = [pasteboard dataForType: type];
    NSArray           *transfers = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    NSURL             *url = [transfers lastObject];
    NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: url];
    if (objectId == nil) {
        return NO;
    }

    Transfer *transfer = (Transfer *)[context objectWithID: objectId];
    BOOL     result;
    if (transfer.isSent.intValue == 1) {
        // If this transfer was already sent then create a new transfer from this one.
        result = [transactionController newTransferFromExistingTransfer: transfer];
    } else {
        result = [transactionController editExistingTransfer: transfer];
        [pendingDebits prepareContent];
    }
    if (result) {
        [self prepareTargetAccountSelector: transfer.account forTransferType: transfer.type.intValue];
    }
    return result;
}

- (void)cancelEditing
{
    // Cancel an ongoing transfer creation (if there is one).
    if (transactionController.editingInProgress) {
        [transactionController cancelCurrentTransfer];

        [rightPane hideFormular];
        [pendingDebits prepareContent]; // In case we edited an existing transfer.
    }
}

- (BOOL)editingInProgress
{
    return transactionController.editingInProgress;
}

// checks in the given list of transfers which of them can/should be sent as collective transfers and sends them
// returns the list of transfers still to be sent
- (NSArray *)doSendCollectiveTransfers: (NSArray *)transfers
{
    NSMutableArray      *singleTransfers = [NSMutableArray arrayWithCapacity: 20];
    NSMutableDictionary *transfersByAccount = [NSMutableDictionary dictionaryWithCapacity: 10];
    for (Transfer *transfer in transfers) {
        BankAccount *account = transfer.account;
        if ([account.collTransferMethod intValue] == CTM_none) {
            [singleTransfers addObject: transfer];
            continue;
        }
        NSMutableArray *collTransfers = transfersByAccount[account];
        if (collTransfers == nil) {
            transfersByAccount[account] = [NSMutableArray arrayWithCapacity: 10];
            collTransfers = transfersByAccount[account];
        }
        [collTransfers addObject: transfer];
    }
    // check accounts and transfers
    for (BankAccount *account in [transfersByAccount allKeys]) {
        BOOL collectiveTransfer = YES;

        // sort out single transfers (only one transfer per account)
        NSArray *collTransfers = transfersByAccount[account];
        if ([collTransfers count] == 1) {
            collectiveTransfer = NO;
        }

        // now ask for accounts with method "ask"
        if ([account.collTransferMethod intValue] == CTM_ask) {
            NSInteger res = NSRunAlertPanel(NSLocalizedString(@"AP426", nil),
                                            NSLocalizedString(@"AP427", nil),
                                            NSLocalizedString(@"AP4", nil),
                                            NSLocalizedString(@"AP3", nil),
                                            nil,
                                            account.accountNumber);
            if (res == NSAlertDefaultReturn) {
                collectiveTransfer = NO;
            }
        }

        if (collectiveTransfer == NO) {
            // do not create collective transfer for this account
            for (Transfer *transfer in collTransfers) {
                [singleTransfers addObject: transfer];
            }
            [transfersByAccount removeObjectForKey: account];
        } else {
            // now send collective transfer
            PecuniaError *error = [[HBCIClient hbciClient] sendCollectiveTransfer: collTransfers];
            if (error) {
                [error logMessage];
            }
        }
    }
    // return array of single transfers
    return singleTransfers;
}

/**
 * Sends the given transfers out.
 */
- (void)doSendTransfers: (NSArray *)transfers
{
    if (transfers.count == 0) {
        return;
    }

    // Show log output if wanted.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           showLog = [defaults boolForKey: @"logForTransfers"];
    if (showLog) {
        LogController *logController = [LogController logController];
        [logController showWindow: self];
        [[logController window] orderFront: self];
    }

    // first check for collective transfers
    transfers = [self doSendCollectiveTransfers: transfers];

    BOOL sent = [[HBCIClient hbciClient] sendTransfers: transfers];
    if (sent) {
        // Save updates and refresh UI.
        NSError                *error = nil;
        NSManagedObjectContext *context = MOAssistant.assistant.context;
        if (![context save: &error]) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return;
        }
    }
    [pendingDebits prepareContent];
    [finishedDebits prepareContent];
}

- (BOOL)startDebitOfType: (TransferType)type withAccount: (BankAccount *)account
{
    if (![self prepareDebitOfType: type]) {
        return NO;
    }

    BOOL result = [transactionController newTransferOfType: type];
    if (result) {
        [self prepareTargetAccountSelector: account forTransferType: type];
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
- (IBAction)sendDebits: (id)sender
{
    NSArray *debits = pendingDebits.selectedObjects;
    if (debits == nil || debits.count == 0) {
        debits = pendingDebits.arrangedObjects;
    }
    [self doSendTransfers: debits];
}

/**
 * Places the current transfer in the queue so it can be sent.
 * Actually, the transfer is already in the queue (when it is created) but is marked
 * as being worked on, so it does not appear in the list.
 */
- (IBAction)queueDebit: (id)sender
{
    [self storeReceiverInMRUList];

    if ([transactionController finishCurrentTransfer]) {
        [rightPane hideFormular];
        [pendingDebits prepareContent];
    }
}

/**
 * Sends the transfer that is currently begin edited.
 */
- (IBAction)sendDebit: (id)sender
{
    [self storeReceiverInMRUList];

    // Can never be called if editing is not in progress, but better safe than sorry.
    if ([self editingInProgress] && [transactionController finishCurrentTransfer]) {
        NSArray *debits = @[transactionController.currentTransfer];
        [self doSendTransfers: debits];
        [rightPane hideFormular];
    }
}

- (IBAction)deleteDebit: (id)sender
{
    // If we are deleting a new transfer then silently cancel editing and remove the formular from screen.
    if (transactionController.currentTransfer.changeState == TransferChangeNew) {
        [self cancelEditing];
        return;
    }

    NSManagedObjectContext *context = MOAssistant.assistant.context;

    int res = NSRunAlertPanel(NSLocalizedString(@"AP417", nil),
                              NSLocalizedString(@"AP419", nil),
                              NSLocalizedString(@"AP2", nil),
                              NSLocalizedString(@"AP10", nil),
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

- (IBAction)showCalendar: (id)sender
{
}

- (IBAction)calendarChanged: (id)sender
{
    executionDatePicker.dateValue = [sender dateValue];
    transactionController.currentTransfer.valutaDate = [sender dateValue];
    //[self hideCalendarWindow];
}

- (IBAction)targetAccountChanged: (id)sender
{
    if (![self editingInProgress]) {
        return;
    }

    BOOL accountSelected = [sender selectedItem] != nil;
    for (NSUInteger row = 0; row <= 5; row++) {
        for (NSUInteger index = 0; index < 5; index++) {
            [[debitFormular viewWithTag: row * 10 + index] setEnabled: accountSelected];
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
        [self updateLimits];
    }
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
        transactionController.currentTransfer.type = @(TransferTypeOldStandard);
    } else {
        executeImmediatelyRadioButton.state = NSOffState;
        [executionDatePicker setEnabled: YES];
        [calendarButton setEnabled: YES];

        transactionController.currentTransfer.valutaDate = executionDatePicker.dateValue;
        transactionController.currentTransfer.type = @(TransferTypeOldStandardScheduled);
    }
}

/**
 * Triggered by the listview when the user pressed the forward delete button or the backward delete button
 * in conjunction with the command key.
 */
- (void)deleteSelectionFrom: (id)sender
{
    NSArray *selection;
    if (sender == pendingDebitsListView) {
        selection = pendingDebits.selectedObjects;
    } else {
        selection = finishedDebits.selectedObjects;
    }

    if (selection.count == 0) {
        return;
    }

    NSString *warningTitle;
    warningTitle = (selection.count == 1) ? NSLocalizedString(@"AP421", nil) : NSLocalizedString(@"AP422", nil);
    NSString *warningText = (selection.count == 1) ? NSLocalizedString(@"AP419", nil) : NSLocalizedString(@"AP420", nil);
    int      res = NSRunAlertPanel(NSLocalizedString(warningTitle, nil),
                                   NSLocalizedString(warningText, nil),
                                   NSLocalizedString(@"AP2", nil),
                                   NSLocalizedString(@"AP10", nil),
                                   nil);
    if (res != NSAlertAlternateReturn) {
        return;
    }

    if (sender == pendingDebitsListView) {
        [pendingDebits removeObjects: selection];
    } else {
        [finishedDebits removeObjects: selection];
    }

    NSError                *error = nil;
    NSManagedObjectContext *context = MOAssistant.assistant.context;

    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }
}

#pragma mark -
#pragma mark Search/Filtering

- (IBAction)filterStatements: (id)sender
{
    NSString *searchString = [sender stringValue];

    if ([searchString length] == 0) {
        [finishedDebits setFilterPredicate: nil];
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
        [finishedDebits setFilterPredicate: predicate];
    }
}

- (IBAction)filterTemplates: (id)sender
{
    NSString *searchString = [sender stringValue];

    if ([searchString length] == 0) {
        [transactionController.templateController setFilterPredicate: nil];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"currency contains[c] %@ or "
                                  "purpose contains[c] %@ or "
                                  "remoteAccount contains[c] %@ or "
                                  "remoteBankCode contains[c] %@ or "
                                  "remoteBIC contains[c] %@ or "
                                  "remoteCountry contains[c] %@ or "
                                  "remoteIBAN contains[c] %@ or "
                                  "remoteName contains[c] %@ or "
                                  "remoteSuffix contains[c] %@ or "
                                  "value = %@",
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
    limits = [[HBCIClient hbciClient] limitsForType: transactionController.currentTransfer.type.intValue
                                            account: transactionController.currentTransfer.account
                                            country: transactionController.currentTransfer.remoteCountry];

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
    BOOL         allowsDated = NO;
    if (tt == TransferTypeOldStandard || tt == TransferTypeOldStandardScheduled) {
        if ([[HBCIClient hbciClient] isTransferSupported: TransferTypeOldStandardScheduled forAccount: transactionController.currentTransfer.account]) {
            [executeAtDateRadioButton setEnabled: YES];
            allowsDated = YES;
        }
    }
    if (allowsDated == NO) {
        [executeAtDateRadioButton setEnabled: NO];
        [executionDatePicker setEnabled: NO];
        [calendarButton setEnabled: NO];
    }
}

/**
 * Stores the current value of the receiver edit field in the MRU list used for lookup
 * of previously entered receivers. The list is kept at no more than 15 entries and no duplicates.
 */
- (void)storeReceiverInMRUList
{
    NSUserDefaults      *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary        *values = [userDefaults dictionaryForKey: @"transfers"];
    NSMutableDictionary *mutableValues;
    if (values == nil) {
        mutableValues = [NSMutableDictionary dictionary];
    } else {
        mutableValues = [values mutableCopy];
    }

    NSString       *newValue = receiverComboBox.stringValue;
    id             previousReceivers = values[@"previousReceivers"];
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

- (void)controlTextDidChange: (NSNotification *)aNotification
{
    NSTextField *te = [aNotification object];
    NSUInteger  maxLen;

    if (te == purpose1 || te == purpose2 || te == purpose3 || te == purpose4) {
        maxLen = limits.maxLenPurpose;
    } else if (te == receiverComboBox) {
        maxLen = limits.maxLengthRemoteName;
    } else {return; }

    if ([[te stringValue] length] > maxLen) {
        [te setStringValue:  [[te stringValue] substringToIndex: maxLen]];
        NSBeep();
        return;
    }
    return;
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    NSTextField *textField = [aNotification object];
    NSString    *bankName = nil;

    if (textField == bankCode || textField == accountNumber) {
        NSString *s = [textField stringValue];
        s = [s stringByRemovingWhitespaces: s];
        s = [s uppercaseString];
        [textField setStringValue: s];
    }

    if (transactionController.currentTransfer.type.intValue == TransferTypeEU ||
        transactionController.currentTransfer.type.intValue == TransferTypeSEPA) {
        if (textField == accountNumber) {
            bankName = [[HBCIClient hbciClient] bankNameForIBAN: textField.stringValue];
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
    if (object == pendingDebits) {
        if (pendingDebits.selectedObjects.count == 0) {
            sendDebitsButton.title = NSLocalizedString(@"AP415", nil);
        } else {
            sendDebitsButton.title = NSLocalizedString(@"AP416", nil);
        }
        [sendDebitsButton setEnabled: [pendingDebits.arrangedObjects count] > 0];

        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
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
    [self updateTargetAccountSelector];
}

- (void)deactivate
{
}

- (void)terminate
{
    [self cancelEditing];
}

- (void)print
{
    NSInteger idx = [debitTab indexOfTabViewItem: [debitTab selectedTabViewItem]];
    if (idx == NSNotFound) {
        return;
    }

    if (idx == 0) {
        // transfers
        NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
        [printInfo setTopMargin: 45];
        [printInfo setBottomMargin: 45];
        NSPrintOperation *printOp;
        NSView           *view = [[TransferPrintView alloc] initWithTransfers: [finishedDebits arrangedObjects] printInfo: printInfo];
        printOp = [NSPrintOperation printOperationWithView: view printInfo: printInfo];
        [printOp setShowsPrintPanel: YES];
        [printOp runOperation];

    }
}

@end
