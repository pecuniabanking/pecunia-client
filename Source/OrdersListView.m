/**
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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
#import "Category.h"

#import "HBCIClient.h"
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

extern NSString* OrderDataType;

@interface OrdersListView (Private)

- (void)updateVisibleCells;

@end

@implementation OrdersListView

@synthesize numberFormatter;
@synthesize dataSource;

- (id)initWithCoder: (NSCoder*)decoder
{
    self = [super initWithCoder: decoder];
    if (self != nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale: [NSLocale currentLocale]];
        [dateFormatter setDateStyle: kCFDateFormatterShortStyle];
        [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
        
        numberFormatter = [[NSNumberFormatter alloc] init];
        hunderedYearsLater = [[[ShortDate currentDate] dateByAddingUnits: 100 byUnit: NSYearCalendarUnit] retain];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setDelegate: self];
}

- (void) dealloc
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
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteBankCode"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteAccount"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.remoteBankName"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.account.categoryColor"];

    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.isChanged"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.isSent"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.toDelete"];

    [observedObject removeObserver: self forKeyPath: @"arrangedObjects"];
    [observedObject release];
    
    [dateFormatter release];
    [numberFormatter release];
    [hunderedYearsLater release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Bindings, KVO and KVC

static void *DataSourceBindingContext = (void *)@"DataSourceContext";

- (void)bind: (NSString *)binding
    toObject: (id)observableObject
 withKeyPath: (NSString *)keyPath
     options: (NSDictionary *)options
{
    if ([binding isEqualToString: @"dataSource"])
    {
        [observedObject release];
        observedObject = [observableObject retain];
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
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteBankCode" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.remoteAccount" options: 0 context: nil];
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
    if (context == DataSourceBindingContext) {
        [self reloadData];
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget: self];
        [self performSelector: @selector(updateVisibleCells) withObject: nil afterDelay: 0.25];
    }
}

#pragma mark -
#pragma mark PXListViewDelegate protocol implementation

- (NSUInteger)numberOfRowsInListView: (PXListView*)aListView
{
#pragma unused(aListView)
	return [dataSource count];
}

- (id)safeAndFormattedValue: (id)value
{
    if (value == nil || [value isKindOfClass: [NSNull class]])
        value = @"";
    else
    {
        if ([value isKindOfClass: [NSDate class]]) {
            ShortDate *date = [ShortDate dateWithDate: value];
            if ([hunderedYearsLater unitsToDate: date byUnit: NSYearCalendarUnit] > 0) {
                // Silently assumes that only last execution dates are set that high.
                value = @"--";
            } else {
                value = [dateFormatter stringFromDate: value];
            }
        }
    }
    
    return value;
}

#define CELL_HEIGHT 80

- (void) fillCell: (OrdersListViewCell*)cell forRow: (NSUInteger)row
{
    StandingOrder *order = [dataSource objectAtIndex: row];
    
    // Update the bank name in case it isn't set yet.
    if (order.remoteBankName == nil && order.remoteBankCode != nil && order.account != nil && order.account.country != nil) {
        NSString *bankName = [[HBCIClient hbciClient] bankNameForCode: order.remoteBankCode inCountry: order.account.country];
        if (bankName) {
            order.remoteBankName = bankName;
        }
    }
    
    NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt: row], StatementIndexKey,
                             [self safeAndFormattedValue: order.firstExecDate], OrderFirstExecDateKey,
                             [self safeAndFormattedValue: order.nextExecDate], StatementDateKey,
                             [self safeAndFormattedValue: order.lastExecDate], OrderLastExecDateKey,
                             [self safeAndFormattedValue: order.remoteName], StatementRemoteNameKey,
                             [self safeAndFormattedValue: order.purpose], StatementPurposeKey,
                             [self safeAndFormattedValue: order.value], StatementValueKey,
                             [self safeAndFormattedValue: order.currency], StatementCurrencyKey,
                             [self safeAndFormattedValue: order.remoteBankName], StatementRemoteBankNameKey,
                             [self safeAndFormattedValue: order.remoteBankCode], StatementRemoteBankCodeKey,
                             [self safeAndFormattedValue: order.remoteAccount], StatementRemoteAccountKey,
                             [self safeAndFormattedValue: order.type], StatementTypeKey,
                             order.isChanged, OrderIsChangedKey,
                             order.toDelete, OrderPendingDeletionKey,
                             order.isSent, OrderIsSentKey,
                             [order.account categoryColor], StatementColorKey,
                             nil];
    
    [cell setDetails: details];
    
    NSRect frame = [cell frame];
    frame.size.height = CELL_HEIGHT;
    [cell setFrame: frame];
    
    [cell setTextAttributesForPositivNumbers: [[self numberFormatter] textAttributesForPositiveValues]
                             negativeNumbers: [[self numberFormatter ] textAttributesForNegativeValues]];
    
}

- (PXListViewCell*)listView: (PXListView*)aListView cellForRow: (NSUInteger)row
{
	OrdersListViewCell* cell = (OrdersListViewCell*)[aListView dequeueCellWithReusableIdentifier: @"order-cell"];
	
	if (!cell) {
		cell = [OrdersListViewCell cellLoadedFromNibNamed: @"OrdersListViewCell" reusableIdentifier: @"order-cell"];
        cell.listView = self;
	}
	
    [self fillCell: cell forRow: row];
    
    return cell;
}

- (CGFloat)listView: (PXListView*)aListView heightOfRow: (NSUInteger)row forDragging: (BOOL)forDragging
{
    return CELL_HEIGHT;
}

- (NSRange)listView: (PXListView*)aListView rangeOfDraggedRow: (NSUInteger)row
{
    return NSMakeRange(0, CELL_HEIGHT);    
}

- (void)listViewSelectionDidChange:(NSNotification*)aNotification
{
    // Also let every entry check its selection state, in case internal states must be updated.
    NSArray* cells = [self visibleCells];
    for (OrdersListViewCell *cell in cells) {
        [cell selectionChanged];
    }
}

/**
 * Triggered when KVO notifies us about changes.
 */
- (void)updateVisibleCells
{
    NSArray *cells = [self visibleCells];
    for (OrdersListViewCell *cell in cells)
        [self fillCell: cell forRow: [cell row]];
}

#pragma mark -
#pragma mark Drag'n drop

- (BOOL)listView: (PXListView*)aListView writeRowsWithIndexes: (NSIndexSet*)rowIndexes
    toPasteboard: (NSPasteboard*)dragPasteboard
       slideBack: (BOOL*)slideBack
{
    *slideBack = YES;
	NSMutableArray *draggedTransfers = [NSMutableArray arrayWithCapacity: 5];
    
    // Collect the ids of all selected transfers and put them on the dragboard.
    NSUInteger index = [rowIndexes firstIndex];
    while (index != NSNotFound) {
        StandingOrder *order = [dataSource objectAtIndex: index];
        NSURL *url = [[order objectID] URIRepresentation];
        [draggedTransfers addObject: url];
        
        index = [rowIndexes indexGreaterThanIndex: index];
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: draggedTransfers];
    [dragPasteboard declareTypes: [NSArray arrayWithObject: OrderDataType] owner: self];
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
