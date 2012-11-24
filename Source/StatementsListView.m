/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#import "StatementsListview.h"
#import "StatementsListViewCell.h"
#import "StatCatAssignment.h"
#import "ShortDate.h"
#import "BankStatement.h"
#import "BankAccount.h"

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

@implementation StatementsListView

@synthesize showAssignedIndicators;
@synthesize owner;
@synthesize autoResetNew;
@synthesize disableSelection;
@synthesize showHeaders;
@synthesize dataSource;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setDelegate: self];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setLocale: [NSLocale currentLocale]];
    [_dateFormatter setDateStyle: kCFDateFormatterFullStyle];
    [_dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    autoResetNew = YES;
    disableSelection = NO;
    showHeaders = YES;
}

- (void) dealloc
{
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.date"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.remoteName"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.floatingPurpose"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.userInfo"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.categoryDescription"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.value"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.saldo"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.currency"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.valutaDate"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.remoteName"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.remoteBankCode"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.remoteAccount"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.remoteBankName"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.remoteIBAN"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.remoteBIC"];
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects.statement.transactionText"];

    [observedObject removeObserver: self forKeyPath: @"arrangedObjects"];
}

- (NSNumberFormatter*)numberFormatter
{
    // Cannot place this in awakeFromLib as it accessed by other awakeFromNib methods and might not
    // be ready yet by then.
    if (_numberFormatter == nil)
        _numberFormatter = [[NSNumberFormatter alloc] init];
    return _numberFormatter;
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
        observedObject = observableObject;
        dataSource = [observableObject valueForKey: keyPath];

        // One binding for the array, to get notifications about insertion and deletions.
        [observableObject addObserver: self
                           forKeyPath: @"arrangedObjects"
                              options: 0
                              context: DataSourceBindingContext];

        // Bindings to specific attributes to get notified about changes to each of them
        // (for all objects in the array).
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.date" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.remoteName" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.floatingPurpose" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.userInfo" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.categoryDescription" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.value" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.saldo" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.currency" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.valutaDate" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.remoteName" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.remoteBankCode" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.remoteAccount" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.remoteBankName" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.remoteIBAN" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.remoteBIC" options: 0 context: nil];
        [observableObject addObserver: self forKeyPath: @"arrangedObjects.statement.transactionText" options: 0 context: nil];

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
    if (context == DataSourceBindingContext) {
        [NSObject cancelPreviousPerformRequestsWithTarget: self]; // Remove any pending notification.
        pendingReload = YES;
        [self performSelector: @selector(reloadData) withObject: nil afterDelay: 0.1];
    } else {
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
        } else {
            // Reschedule the reload call.
            [NSObject cancelPreviousPerformRequestsWithTarget: self];
            [self performSelector: @selector(reloadData) withObject: nil afterDelay: 0.1];
        }
    }
}

#pragma mark -
#pragma mark PXListViewDelegate protocoll implementation

- (NSUInteger)numberOfRowsInListView: (PXListView*)aListView
{
    pendingReload = NO;
    
#pragma unused(aListView)
	return [dataSource count];
}

- (id)formatValue: (id)value capitalize: (BOOL)capitalize
{
    if (value == nil || [value isKindOfClass: [NSNull class]])
        value = @"";
    else
    {
        if ([value isKindOfClass: [NSDate class]])
            value = [_dateFormatter stringFromDate: value];
        if (capitalize) {
            NSMutableArray *words = [[value componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] mutableCopy];
            for (NSUInteger i = 0; i < [words count]; i++) {
                NSString *word = [words objectAtIndex: i];
                if (i == 0 || [word length] > 3) {
                    [words replaceObjectAtIndex: i withObject: [word capitalizedString]];
                }
            }
            value = [words componentsJoinedByString: @" "];
        }
    }
    
    return value;
}

- (BOOL)showsHeaderForRow: (NSUInteger)row
{
    if (!showHeaders) {
        return false;
    }
    
    BOOL result = (row == 0);
    if (!result)
    {
        BankStatement *statement = (BankStatement*)[[dataSource objectAtIndex: row] valueForKey: @"statement"];
        BankStatement *previousStatement = (BankStatement*)[[dataSource objectAtIndex: row - 1] valueForKey: @"statement"];
        
        result = [[ShortDate dateWithDate: statement.date] compare: [ShortDate dateWithDate: previousStatement.date]] != NSOrderedSame;
    }
    return result;
}

/**
 * Looks through the statement array starting with "row" and counts how many entries follow it with the 
 * same date (time is not compared).
 */
- (int) countSameDatesFromRow: (NSUInteger)row
{
    int result = 1;
    id statement = [[dataSource objectAtIndex: row] valueForKey: @"statement"];
    ShortDate* currentDate = [ShortDate dateWithDate: [statement valueForKey: @"date"]];
    
    NSUInteger totalCount = [dataSource count];
    while (++row < totalCount)
    {
        statement = [[dataSource objectAtIndex: row] valueForKey: @"statement"];
        ShortDate* nextDate = [ShortDate dateWithDate: [statement valueForKey: @"date"]];
        if ([currentDate compare: nextDate] != NSOrderedSame)
            break;
        result++;
    }
    return result;
}

#define CELL_BODY_HEIGHT 49
#define CELL_HEADER_HEIGHT 20

- (void) fillCell: (StatementsListViewCell*)cell forRow: (NSUInteger)row
{
    id statement = [[dataSource objectAtIndex: row] statement];
    
    NSDate* currentDate = [statement valueForKey: @"date"];
    
    // Count how many statements have been booked for the current date.
    int turnovers = [self countSameDatesFromRow: row];
    NSString* turnoversString;
    if (turnovers != 1)
        turnoversString = [NSString stringWithFormat: NSLocalizedString(@"AP133", @""), turnovers];
    else
        turnoversString = NSLocalizedString(@"AP132", @"");
    
    cell.delegate = self;
    NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:
                             [self formatValue: currentDate capitalize: NO], StatementDateKey,
                             turnoversString, StatementTurnoversKey,
                             [self formatValue: [statement remoteName] capitalize: YES], StatementRemoteNameKey,
                             [self formatValue: [statement floatingPurpose] capitalize: YES], StatementPurposeKey,
                             [self formatValue: [[dataSource objectAtIndex: row] userInfo] capitalize: YES], StatementNoteKey,
                             [self formatValue: [statement categoriesDescription] capitalize: NO], StatementCategoriesKey,
                             [self formatValue: [statement value] capitalize: NO], StatementValueKey,
                             [self formatValue: [statement saldo] capitalize: NO], StatementSaldoKey,
                             [self formatValue: [statement currency] capitalize: NO], StatementCurrencyKey,
                             [self formatValue: [statement transactionText] capitalize: YES], StatementTransactionTextKey,
                             [[[dataSource objectAtIndex: row] category] categoryColor], StatementColorKey,
                             [NSNumber numberWithInt: row], StatementIndexKey,
                             nil];
    
    [cell setDetails: details];
    [cell setIsNew: [[statement isNew] boolValue]];
    
    if (self.showAssignedIndicators) {
        id test = [[dataSource objectAtIndex: row] classify];
        [cell showActivator: YES markActive: test != nil];
    } else {
        [cell showActivator: NO markActive: NO];
    }
    
    NSDecimalNumber* nassValue = [statement nassValue];
    cell.hasUnassignedValue =  [nassValue compare: [NSDecimalNumber zero]] != NSOrderedSame;
    
    // Set the size of the cell, depending on if we show its header or not.
    NSRect frame = [cell frame];
    frame.size.height = CELL_BODY_HEIGHT;
    if ([self showsHeaderForRow: row]) {
        frame.size.height += CELL_HEADER_HEIGHT;
        [cell setHeaderHeight: CELL_HEADER_HEIGHT];
    } else {
        [cell setHeaderHeight: 0];
    }
    [cell setFrame: frame];
    
    [cell setTextAttributesForPositivNumbers: [[self numberFormatter] textAttributesForPositiveValues]
                             negativeNumbers: [[self numberFormatter ] textAttributesForNegativeValues]];
    
}

/**
 * Called by the PXListView when it needs to set up a new visual cell. This method uses enqueued cells
 * to avoid creating potentially many cells. This way we can have many entries but still only as many 
 * cells as fit in the window.
 */
- (PXListViewCell*)listView: (PXListView*)aListView cellForRow: (NSUInteger)row
{
	StatementsListViewCell* cell = (StatementsListViewCell*)[aListView dequeueCellWithReusableIdentifier: @"statcell"];
	
	if (!cell) {
		cell = [StatementsListViewCell cellLoadedFromNibNamed: @"StatementsListViewCell" reusableIdentifier: @"statcell"];
	}
	
    [self fillCell: cell forRow: row];
    
    return cell;
}

- (CGFloat)listView: (PXListView*)aListView heightOfRow: (NSUInteger)row forDragging: (BOOL)forDragging
{
    if (!forDragging && [self showsHeaderForRow: row]) {
        return CELL_BODY_HEIGHT + CELL_HEADER_HEIGHT;
    }
    return CELL_BODY_HEIGHT;
}

- (NSRange)listView: (PXListView*)aListView rangeOfDraggedRow: (NSUInteger)row
{
    if ([self showsHeaderForRow: row]) {
        return NSMakeRange(CELL_HEADER_HEIGHT, CELL_BODY_HEIGHT);
    }
    return NSMakeRange(0, CELL_BODY_HEIGHT);    
}

- (void)listViewSelectionDidChange:(NSNotification*)aNotification
{
    if (autoResetNew) {
        // A selected statement automatically loses the "new" state (if auto reset is enabled).
        NSIndexSet* selection = [self selectedRows];
        NSUInteger index = [selection firstIndex];
        while (index != NSNotFound) {
            StatementsListViewCell *cell = (id)[self cellForRowAtIndex: index];
            [cell setIsNew: NO];
            index = [selection indexGreaterThanIndex: index];
        }
    }
    
    // Also let every entry check its selection state, in case internal states must be updated.
    NSArray* cells = [self visibleCells];
    for (StatementsListViewCell *cell in cells) {
        [cell selectionChanged];
    }
}

- (bool)listView:(PXListView*)aListView shouldSelectRows: (NSIndexSet *)rows byExtendingSelection:(BOOL)shouldExtend
{
    return !self.disableSelection;
}

/**
 * Triggered when KVO notifies us about changes.
 */
- (void)updateVisibleCells
{
    pendingRefresh = NO;
    
    NSArray *cells = [self visibleCells];
    for (StatementsListViewCell *cell in cells)
        [self fillCell: cell forRow: [cell row]];
}

/**
 * Activates all selected cells. If no cell is selected then all cells are activated.
 * Implicitly makes all cells show the activator.
 */
- (void)activateCells
{
    activating = YES;
    @try {
        NSIndexSet* selection = [self selectedRows];
        if (selection.count > 0) {
            NSUInteger index = [selection firstIndex];
            while (index != NSNotFound) {
                StatementsListViewCell *cell = (id)[self cellForRowAtIndex: index];
                [cell showActivator: YES markActive: YES];
                index = [selection indexGreaterThanIndex: index];
            }
        } else {
            for (NSUInteger index = 0; index < [dataSource count]; index++)  {
                StatementsListViewCell *cell = (id)[self cellForRowAtIndex: index];
                [cell showActivator: YES markActive: YES];
            }
        }
    }
    @finally {
        activating = NO;
    }
}

#pragma mark -
#pragma mark Drag'n drop

extern NSString* const BankStatementDataType;

- (BOOL)listView: (PXListView*)aListView writeRowsWithIndexes: (NSIndexSet*)rowIndexes
    toPasteboard: (NSPasteboard*)dragPasteboard
       slideBack: (BOOL *)slideBack
{
    *slideBack = YES;
    
    // Keep a copy of the selected indexes as the selection is removed during the drag operation,
    // but we need to update the selected cells then.
    draggedIndexes = [rowIndexes copy];
    
    NSUInteger indexes[30], count, i;
	NSRange range;
	StatCatAssignment* stat;
	NSMutableArray* uris = [NSMutableArray arrayWithCapacity: 30];
    
    range.location = 0;
	range.length = 100000;
    
    // Copy the row numbers to the pasteboard.
    do {
		count = [rowIndexes getIndexes: indexes maxCount: 30 inIndexRange: &range];
		for (i = 0; i < count; i++) {
			stat = [dataSource objectAtIndex: indexes[i]];
			NSURL *uri = [[stat objectID] URIRepresentation];
			[uris addObject: uri];
		}
	} while (count > 0);    
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uris];
    [dragPasteboard declareTypes:[NSArray arrayWithObject: BankStatementDataType] owner: self];
    [dragPasteboard setData:data forType: BankStatementDataType];

    return YES;
}

// TODO: doesn't seem to have any effect, remove?
- (NSDragOperation)listView: (PXListView*)aListView validateDrop: (id <NSDraggingInfo>)info proposedRow: (NSUInteger)row
      proposedDropHighlight: (PXListViewDropHighlight)dropHighlight;
{
	return NSDragOperationCopy;
}

- (void)cellActivationChanged: (BOOL)state forIndex: (NSUInteger)index
{
    if (!activating) {
        // Simply forward the notification to the notification delegate if any is set.
        if ([self.owner respondsToSelector: @selector(activationChanged:forIndex:)]) {
            [self.owner activationChanged: state forIndex: index];
        }
    }
}

@end
