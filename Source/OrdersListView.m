/**
 * Copyright (c) 2012, 2013, Pecunia Project. All rights reserved.
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

#import "OrdersListview.h"
#import "OrdersListViewCell.h"
#import "ShortDate.h"
#import "StandingOrder.h"
#import "BankingCategory.h"

#import "HBCIController.h"
#import "BankAccount.h"

extern NSString *StatementDateKey;             // Here the next execution date.
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

NSString *OrderFirstExecDateKey   = @"OrderFirstExecDateKey";   // NSDate
NSString *OrderLastExecDateKey    = @"OrderLastExecDateKey";    // NSDate
NSString *OrderIsChangedKey       = @"OrderIsChangedKey";       // bool (as NSNumber)
NSString *OrderPendingDeletionKey = @"OrderPendingDeletionKey"; // bool (as NSNumber)
NSString *OrderIsSentKey          = @"OrderIsSentKey";          // bool (as NSNumber)

extern NSString *OrderDataType;

@interface OrdersListView (Private)

- (void)updateVisibleCells;

@end

static void *DataSourceBindingContext = (void *)@"DataSourceContext";
static void *UserDefaultsBindingContext = (void *)@"UserDefaultsContext";

@implementation OrdersListView

@synthesize owner;
@synthesize dataSource;

- (id)initWithCoder: (NSCoder *)decoder
{
    self = [super initWithCoder: decoder];
    if (self != nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale: [NSLocale currentLocale]];
        [dateFormatter setDateStyle: kCFDateFormatterShortStyle];
        [dateFormatter setTimeStyle: NSDateFormatterNoStyle];

        hunderedYearsLater = [[ShortDate currentDate] dateByAddingUnits: 100 byUnit: NSCalendarUnitYear];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self setDelegate: self];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults addObserver: self forKeyPath: @"autoCasing" options: 0 context: UserDefaultsBindingContext];
    autoCasing = YES;
    if ([userDefaults objectForKey: @"autoCasing"]) {
        autoCasing = [userDefaults boolForKey: @"autoCasing"];
    }
}

- (void)dealloc
{
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteName"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.date"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteName"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.purpose1"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.purpose2"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.purpose3"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.purpose4"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.value"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.currency"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteBIC"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteIBAN"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteBankName"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.account.categoryColor"];

    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.isChanged"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.isSent"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.toDelete"];

    [observedObject removeObserver: self forKeyPath: @"arrangedObjects"];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"autoCasing"];
}

#pragma mark -
#pragma mark Bindings, KVO and KVC

- (void)   bind: (NSString *)binding
       toObject: (id)observableObject
    withKeyPath: (NSString *)keyPath
        options: (NSDictionary *)options
{
    if ([binding isEqualToString: @"dataSource"]) {
        observedObject = observableObject;
        dataSource = [observableObject valueForKey: keyPath];

        // One binding for the array, to get notifications about insertion and deletions.
        [observableObject addObserver: self
                           forKeyPath: @"arrangedObjects"
                              options: 0
                              context: DataSourceBindingContext];

        // Bindings to specific attributes to get notfied about changes to each of them
        // (for all objects in the array).
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteName" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.firstExecDate" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.nextExecDate" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.lastExecDate" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteName" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.purpose1" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.purpose2" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.purpose3" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.purpose4" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.value" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.currency" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteBIC" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteBIAN" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteBankName" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.account.categoryColor" options: 0 context: nil];

        [observableObject addObserver: self forKeyPath: @"arrangedObjects.isChanged" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.isSent" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.toDelete" options: 0 context: nil];
    } else {
        [super bind: binding toObject: observableObject withKeyPath: keyPath options: options];
    }
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
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

#pragma mark -
#pragma mark PXListViewDelegate protocol implementation

- (NSUInteger)numberOfRowsInListView: (PXListView *)aListView
{
    pendingReload = NO;

#pragma unused(aListView)
    return [dataSource count];
}

- (id)formatValue: (id)value capitalize: (BOOL)capitalize
{
    if (value == nil || [value isKindOfClass: [NSNull class]]) {
        value = @"";
    } else {
        if ([value isKindOfClass: [NSDate class]]) {
            ShortDate *date = [ShortDate dateWithDate: value];
            if ([hunderedYearsLater unitsToDate: date byUnit: NSCalendarUnitYear] > 0) {
                // Silently assumes that only last execution dates are set that high.
                value = @"--";
            } else {
                value = [dateFormatter stringFromDate: value];
            }
        } else {
            if (capitalize && autoCasing) {
                NSMutableArray *words = [[value componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] mutableCopy];
                for (NSUInteger i = 0; i < [words count]; i++) {
                    NSString *word = words[i];
                    if (i == 0 || [word length] > 3) {
                        words[i] = [word capitalizedString];
                    }
                }
                value = [words componentsJoinedByString: @" "];
            }
        }
    }

    return value;
}

#define CELL_HEIGHT 80

- (void)fillCell: (OrdersListViewCell *)cell forRow: (NSUInteger)row
{
    StandingOrder *order = dataSource[row];

    // Update the bank name in case it isn't set yet.
    if (order.remoteBankName == nil && order.remoteBankCode != nil && order.account != nil && order.account.country != nil) {
        NSString *bankName = [[HBCIController controller] bankNameForCode: order.remoteBankCode];
        if (bankName) {
            order.remoteBankName = bankName;
        }
    }

    cell.delegate = self;
    NSColor      *color = [order.account categoryColor];
    NSDictionary *details = @{StatementIndexKey: @((int)row),
                              OrderFirstExecDateKey: [self formatValue: order.firstExecDate capitalize: NO],
                              StatementDateKey: [self formatValue: order.nextExecDate capitalize: NO],
                              OrderLastExecDateKey: [self formatValue: order.lastExecDate capitalize: NO],
                              StatementRemoteNameKey: [self formatValue: order.remoteName capitalize: YES],
                              StatementPurposeKey: [self formatValue: order.purpose capitalize: YES],
                              StatementValueKey: [self formatValue: order.value capitalize: NO],
                              StatementCurrencyKey: [self formatValue: order.currency capitalize: NO],
                              StatementRemoteBankNameKey: [self formatValue: order.remoteBankName capitalize: YES],
                              StatementRemoteBICKey: [self formatValue: order.remoteBIC capitalize: NO],
                              StatementRemoteIBANKey: [self formatValue: order.remoteIBAN capitalize: NO],
                              StatementTypeKey: [self formatValue: order.type capitalize: NO],
                              OrderIsChangedKey: order.isChanged,
                              OrderPendingDeletionKey: order.toDelete,
                              OrderIsSentKey: order.isSent,
                              StatementColorKey: (color != nil) ? color : [NSNull null]};

    [cell setDetails: details];

    NSRect frame = [cell frame];
    frame.size.height = CELL_HEIGHT;
    [cell setFrame: frame];
}

- (PXListViewCell *)listView: (PXListView *)aListView cellForRow: (NSUInteger)row
{
    OrdersListViewCell *cell = (OrdersListViewCell *)[aListView dequeueCellWithReusableIdentifier: @"order-cell"];

    if (!cell) {
        cell = [OrdersListViewCell cellLoadedFromNibNamed: @"OrdersListViewCell" reusableIdentifier: @"order-cell"];
        cell.listView = self;
    }

    [self fillCell: cell forRow: row];

    return cell;
}

- (CGFloat)listView: (PXListView *)aListView heightOfRow: (NSUInteger)row forDragging: (BOOL)forDragging
{
    return CELL_HEIGHT;
}

- (NSRange)listView: (PXListView *)aListView rangeOfDraggedRow: (NSUInteger)row
{
    return NSMakeRange(0, CELL_HEIGHT);
}

- (void)listViewSelectionDidChange: (NSNotification *)aNotification
{
    // Also let every entry check its selection state, in case internal states must be updated.
    NSArray *cells = [self visibleCells];
    for (OrdersListViewCell *cell in cells) {
        [cell selectionChanged];
    }
}

/**
 * Triggered when KVO notifies us about changes.
 */
- (void)updateVisibleCells
{
    pendingRefresh = NO;
    NSArray *cells = [self visibleCells];
    for (OrdersListViewCell *cell in cells) {
        [self fillCell: cell forRow: [cell row]];
    }
}

#pragma mark -
#pragma mark OrdersListViewNotificationProtocol

- (void)cancelDeletionForIndex: (NSUInteger)index
{
    // Simply forward the notification to the notification delegate if any is set.
    if ([self.owner respondsToSelector: @selector(cancelDeletionForIndex:)]) {
        [self.owner cancelDeletionForIndex: index];
    }
}

#pragma mark -
#pragma mark Drag'n drop

- (BOOL)listView: (PXListView *)aListView writeRowsWithIndexes: (NSIndexSet *)rowIndexes
    toPasteboard: (NSPasteboard *)dragPasteboard
       slideBack: (BOOL *)slideBack
{
    *slideBack = YES;
    NSMutableArray *draggedTransfers = [NSMutableArray arrayWithCapacity: 5];

    // Collect the ids of all selected transfers and put them on the dragboard.
    NSUInteger index = [rowIndexes firstIndex];
    while (index != NSNotFound) {
        StandingOrder *order = dataSource[index];
        NSURL         *url = [[order objectID] URIRepresentation];
        [draggedTransfers addObject: url];

        index = [rowIndexes indexGreaterThanIndex: index];
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: draggedTransfers];
    [dragPasteboard declareTypes: @[OrderDataType] owner: self];
    [dragPasteboard setData: data forType: OrderDataType];

    return YES;
}

// The listview as drag source.
- (NSDragOperation)draggingSourceOperationMaskForLocal: (BOOL)flag
{
    return flag ? NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
    return YES;
}

@end
