/**
 * Copyright (c) 2012, 2015, Pecunia Project. All rights reserved.
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

#import "Transfer.h"
#import "TransfersListview.h"
#import "TransfersListViewCell.h"
#import "ShortDate.h"
#import "BankingCategory.h"

#import "BankAccount.h"

#import "PXListView+UserInteraction.h"

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

extern NSString *TransferDataType;
extern NSString *TransferReadyForUseDataType;

static void *DataSourceBindingContext = (void *)@"DataSourceContext";
extern void *UserDefaultsBindingContext;

@interface TransfersListView (Private)

- (void)updateVisibleCells;

@end

@implementation TransfersListView

@synthesize owner;
@synthesize dataSource;

- (id)initWithCoder: (NSCoder *)decoder {
    self = [super initWithCoder: decoder];
    if (self != nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale: [NSLocale currentLocale]];
        [dateFormatter setDateStyle: kCFDateFormatterShortStyle];
        [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setDelegate: self];
    [self registerForDraggedTypes: @[TransferDataType, TransferReadyForUseDataType]];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults addObserver: self forKeyPath: @"autoCasing" options: 0 context: UserDefaultsBindingContext];
    autoCasing = YES;
    if ([userDefaults objectForKey: @"autoCasing"]) {
        autoCasing = [userDefaults boolForKey: @"autoCasing"];
    }
}

- (void)dealloc {
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteName"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.date"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteName"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.purpose1"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.purpose2"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.purpose3"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.purpose4"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.value"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.currency"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteBankCode"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteAccount"];

    if ([observedObject isKindOfClass: [Transfer class]]) {
        [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteBankName"];
        [observedObject removeObserver: self forKeyPath: @"arrangedObjects.account.categoryColor"];
    }

    [observedObject removeObserver: self forKeyPath: @"arrangedObjects"];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"autoCasing"];
}

#pragma mark - Bindings, KVO and KVC

- (void)   bind: (NSString *)binding
       toObject: (id)observableObject
    withKeyPath: (NSString *)keyPath
        options: (NSDictionary *)options {
    if ([binding isEqualToString: @"dataSource"]) {
        observedObject = observableObject;
        dataSource = [observableObject valueForKey: keyPath];

        // One binding for the array, to get notifications about insertion and deletions.
        [observableObject addObserver: self
                           forKeyPath: @"arrangedObjects"
                              options: 0
                              context: DataSourceBindingContext];

        // Bindings to specific attributes to get notified about changes to each of them
        // (for all objects in the array).
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteName" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.date" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.valutaDate" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteName" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.purpose1" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.purpose2" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.purpose3" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.purpose4" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.value" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.currency" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteBankCode" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteAccount" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteBankName" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.account.categoryColor" options: 0 context: nil];

    } else {
        [super bind: binding toObject: observableObject withKeyPath: keyPath options: options];
    }
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context {
    // Coalesce many notifications into one.
    if (context == UserDefaultsBindingContext) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([keyPath isEqualToString: @"autoCasing"]) {
            autoCasing = [userDefaults boolForKey: @"autoCasing"];
            if (!pendingRefresh && !pendingReload) {
                pendingRefresh = YES;
                [self performSelector: @selector(updateVisibleCells) withObject: nil afterDelay: 0.0];
            }
        }

        return;
    }

    if (context == DataSourceBindingContext) {
        [NSObject cancelPreviousPerformRequestsWithTarget: self]; // Remove any pending notification.
        pendingReload = YES;
        [self performSelector: @selector(reloadData) withObject: nil afterDelay: 0.1];

        return;
    }

    // If there's already a full reload pending do nothing.
    if (!pendingReload) {
        // If there's another property change pending cancel it and do a full reload instead.
        if (pendingRefresh) {
            pendingRefresh = NO;
            [NSObject cancelPreviousPerformRequestsWithTarget: self]; // Remove any pending notification.
            pendingReload = YES;
            [self performSelector: @selector(reloadData) withObject: nil afterDelay: 0.1];
        } else {
            pendingRefresh = YES;
            [self performSelector: @selector(updateVisibleCells) withObject: nil afterDelay: 0.1];
        }
    }
}

#pragma mark - PXListViewDelegate protocol implementation

- (NSUInteger)numberOfRowsInListView: (PXListView *)aListView {
    pendingReload = NO;

#pragma unused(aListView)
    return [dataSource count];
}

- (id)safeAndFormattedValue: (id)value {
    if (value == nil || [value isKindOfClass: [NSNull class]]) {
        value = @"";
    } else {
        if ([value isKindOfClass: [NSDate class]]) {
            value = [dateFormatter stringFromDate: value];
        }
    }

    return value;
}

#define CELL_HEIGHT 55

- (void)fillCell: (TransfersListViewCell *)cell forRow: (NSUInteger)row {
    Transfer *transfer = dataSource[row];

    NSDate *date = transfer.valutaDate;
    if (date == nil) {
        date = transfer.date;
    }
    NSColor      *color = [transfer.account categoryColor];
    NSDictionary *details = @{
        StatementIndexKey: @((int)row),
        StatementDateKey: [self safeAndFormattedValue: date],
        StatementRemoteNameKey: [self safeAndFormattedValue: transfer.remoteName],
        StatementPurposeKey: [self safeAndFormattedValue: transfer.purpose],
        StatementValueKey: [self safeAndFormattedValue: transfer.value],
        StatementCurrencyKey: [self safeAndFormattedValue: transfer.currency],
        StatementRemoteBankNameKey: [self safeAndFormattedValue: transfer.remoteBankName],
        StatementRemoteBankCodeKey: [self safeAndFormattedValue: transfer.remoteBankCode],
        StatementRemoteIBANKey: [self safeAndFormattedValue: transfer.remoteIBAN],
        StatementRemoteBICKey: [self safeAndFormattedValue: transfer.remoteBIC],
        StatementRemoteAccountKey: [self safeAndFormattedValue: transfer.remoteAccount],
        StatementTypeKey: [self safeAndFormattedValue: transfer.type],
        StatementColorKey: (color != nil) ? color : [NSNull null]
    };

    [cell setDetails: details];

    NSRect frame = [cell frame];
    frame.size.height = CELL_HEIGHT;
    [cell setFrame: frame];
}

- (PXListViewCell *)listView: (PXListView *)aListView cellForRow: (NSUInteger)row {
    TransfersListViewCell *cell = (TransfersListViewCell *)[aListView dequeueCellWithReusableIdentifier: @"transfer-cell"];

    if (!cell) {
        cell = [TransfersListViewCell cellLoadedFromNibNamed: @"TransfersListViewCell" owner: cell reusableIdentifier: @"transfer-cell"];
        cell.listView = self;
    }

    [self fillCell: cell forRow: row];

    return cell;
}

- (CGFloat)listView: (PXListView *)aListView heightOfRow: (NSUInteger)row forDragging: (BOOL)forDragging {
    return CELL_HEIGHT;
}

- (NSRange)listView: (PXListView *)aListView rangeOfDraggedRow: (NSUInteger)row {
    return NSMakeRange(0, CELL_HEIGHT);
}

- (void)listViewSelectionDidChange: (NSNotification *)aNotification {
    // Also let every entry check its selection state, in case internal states must be updated.
    NSArray *cells = [self visibleCells];
    for (TransfersListViewCell *cell in cells) {
        [cell selectionChanged];
    }
}

/**
 * Triggered when KVO notifies us about changes.
 */
- (void)updateVisibleCells {
    pendingRefresh = NO;
    NSArray *cells = [self visibleCells];
    for (TransfersListViewCell *cell in cells) {
        [self fillCell: cell forRow: [cell row]];
    }
}

#pragma mark - Drag'n drop

- (BOOL)listView: (PXListView *)aListView writeRowsWithIndexes: (NSIndexSet *)rowIndexes
    toPasteboard: (NSPasteboard *)dragPasteboard
       slideBack: (BOOL *)slideBack {
    *slideBack = YES;
    NSMutableArray *draggedTransfers = [NSMutableArray arrayWithCapacity: 5];

    // Collect the ids of all selected transfers and put them on the dragboard.
    NSUInteger index = [rowIndexes firstIndex];
    while (index != NSNotFound) {
        Transfer *transfer = dataSource[index];
        NSURL    *url = [[transfer objectID] URIRepresentation];
        [draggedTransfers addObject: url];

        index = [rowIndexes indexGreaterThanIndex: index];
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: draggedTransfers];
    [dragPasteboard declareTypes: @[TransferDataType] owner: self];
    [dragPasteboard setData: data forType: TransferDataType];
    [owner draggingStartsFor: self];

    return YES;
}

// The listview as drag source.
- (NSDragOperation)draggingSourceOperationMaskForLocal: (BOOL)flag {
    return flag ? NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)ignoreModifierKeysWhileDragging {
    return YES;
}

// The listview as drag destination.

- (NSDragOperation)listView: (PXListView *)aListView
               validateDrop: (id<NSDraggingInfo>)sender
                proposedRow: (NSUInteger)row
      proposedDropHighlight: (PXListViewDropHighlight)highlight {
    if (sender.draggingSource == self) {
        [[NSCursor arrowCursor] set];
        return NSDragOperationNone;
    } else {
        if (![owner canAcceptDropFor: self context: sender]) {
            [[NSCursor arrowCursor] set];
            return NSDragOperationNone;
        }

        [[NSCursor openHandCursor] set];
        return NSDragOperationMove;
    }
}

- (BOOL) listView: (PXListView *)aListView
       acceptDrop: (id<NSDraggingInfo>)info
              row: (NSUInteger)row
    dropHighlight: (PXListViewDropHighlight)highlight {
    if (info.draggingSource == self) {
        return NO;
    }

    [owner concludeDropOperation: self context: info];
    return YES;
}

- (void)draggingExited: (id <NSDraggingInfo>)info {
    [[NSCursor arrowCursor] set];
    [super draggingExited: info];
}

#pragma mark - Keyboard handling

- (void)deleteToBeginningOfLine: (id)sender {
    [owner deleteSelectionFrom: self];
}

- (void)deleteForward: (id)sender {
    [owner deleteSelectionFrom: self];
}

#pragma mark - Mouse handling

- (void)handleMouseDown: (NSEvent *)theEvent inCell: (PXListViewCell *)theCell {
    [super handleMouseDown: theEvent inCell: theCell];

    if (theEvent.clickCount > 1) {
        Transfer *transfer = dataSource[theCell.row];
        [owner transferActivated: transfer];
    }
}

@end
