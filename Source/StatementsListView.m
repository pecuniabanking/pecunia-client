/**
 * Copyright (c) 2011, 2014, Pecunia Project. All rights reserved.
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

@interface StatementsListView ()
{
    id observedObject;

    NSDateFormatter *dateFormatter;
    NSIndexSet      *draggedIndexes;

    BOOL showAssignedIndicators;
    id   owner;
    BOOL autoResetNew;
    BOOL pendingReload;  // Set when a notification arrived to completely reload the listview.
    BOOL pendingRefresh; // Set when there was already a notification to refresh visible cells (for property changes).
    BOOL activating;     // Set when a cells are activated programmatically (so we don't send notifications around).

    // These are cached user settings.
    BOOL showHeaders;
}

@end

@implementation StatementsListView

@synthesize showAssignedIndicators;
@synthesize owner;
@synthesize autoResetNew;
@synthesize disableSelection;
@synthesize dataSource;
@synthesize canShowHeaders;

static void *DataSourceBindingContext = (void *)@"DataSourceContext";
extern void *UserDefaultsBindingContext;

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self setDelegate: self];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale: [NSLocale currentLocale]];
    [dateFormatter setDateStyle: kCFDateFormatterFullStyle];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    autoResetNew = YES;
    disableSelection = NO;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey: @"showBalances"] == nil) {
        [defaults setBool: YES forKey: @"showBalances"];
    }

    [defaults addObserver: self forKeyPath: @"showHeadersInLists" options: 0 context: UserDefaultsBindingContext];
    showHeaders = YES;
    canShowHeaders = YES;
    if ([defaults objectForKey: @"showHeadersInLists"] != nil) {
        showHeaders = [defaults boolForKey: @"showHeadersInLists"];
    } else {
        [defaults setBool: YES forKey: @"showHeadersInLists"];
    }
}

- (void)dealloc
{
    [self removeBindings];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver: self forKeyPath: @"showHeadersInLists"];
}

#pragma mark - Bindings, KVO and KVC

- (void)removeBindings
{
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects"];
}

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

    } else {
        [super bind: binding toObject: observableObject withKeyPath: keyPath options: options];
    }
}

- (void)unbind: (NSString *)binding
{
    if ([binding isEqualToString: @"dataSource"]) {
        [self removeBindings];
    } else {
        [super unbind: binding];
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
        if ([keyPath isEqualToString: @"showHeadersInLists"]) {
            showHeaders = [userDefaults boolForKey: @"showHeadersInLists"];

            if (!pendingReload) {
                pendingReload = YES;
                [self performSelector: @selector(reloadData) withObject: nil afterDelay: 0.1];
            }
            return;
        }
    }

    if (context == DataSourceBindingContext) {
        if (!pendingReload) {
            pendingReload = YES;
            [self performSelector: @selector(reloadData) withObject: nil afterDelay: 0.1];
        }
        return;
    }

    /*
    if (!pendingReload && !pendingRefresh) {
        pendingRefresh = YES;
        [self performSelector: @selector(updateVisibleCells) withObject: nil afterDelay: 0.0];
    }
     */

    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

#pragma mark -
#pragma mark PXListViewDelegate protocoll implementation

- (NSUInteger)numberOfRowsInListView: (PXListView *)aListView
{
    pendingReload = NO;

#pragma unused(aListView)
    return [dataSource count];
}

- (BOOL)showsHeaderForRow: (NSUInteger)row
{
    // The given row can be out of bounds as we asynchronously reload the list on datasource changes
    // and there can be relayout events before the actual reload kicks in.
    if (!showHeaders || !canShowHeaders || row >= dataSource.count) {
        return false;
    }

    BOOL result = (row == 0);
    if (!result) {
        BankStatement *statement = (BankStatement *)[dataSource[row] valueForKey: @"statement"];
        BankStatement *previousStatement = (BankStatement *)[dataSource[row - 1] valueForKey: @"statement"];

        if (statement == nil || previousStatement == nil) {
            return NO;
        }
        result = [[ShortDate dateWithDate: statement.date] compare: [ShortDate dateWithDate: previousStatement.date]] != NSOrderedSame;
    }
    return result;
}

/**
 * Looks through the statement array starting with "row" and counts how many entries follow it with the
 * same date (time is not compared).
 */
- (int)countSameDatesFromRow: (NSUInteger)row
{
    int result = 1;

    BankStatement *statement = [dataSource[row] statement];
    ShortDate     *currentDate = [ShortDate dateWithDate: statement.date];

    NSUInteger totalCount = [dataSource count];
    while (++row < totalCount) {
        statement = [dataSource[row] statement];
        ShortDate *nextDate = [ShortDate dateWithDate: statement.date];
        if ([currentDate compare: nextDate] != NSOrderedSame) {
            break;
        }
        result++;
    }
    return result;
}

#define CELL_BODY_HEIGHT   49
#define CELL_HEADER_HEIGHT 20

- (void)fillCell: (StatementsListViewCell *)cell forRow: (NSUInteger)row
{
    StatCatAssignment *assignment = (StatCatAssignment *)dataSource[row];

    cell.delegate = self;
    cell.representedObject = assignment;

    if (self.showAssignedIndicators) {
        bool activate = assignment.category != nil && assignment.category != Category.nassRoot;
        [cell showActivator: YES markActive: activate];
    } else {
        [cell showActivator: NO markActive: NO];
    }

    if ([self showsHeaderForRow: row]) {
        cell.turnovers = [self countSameDatesFromRow: row];
    }

    // Set the size of the cell, depending on if we show its header or not.
    NSRect frame = cell.frame;
    frame.size.height = CELL_BODY_HEIGHT;
    if ([self showsHeaderForRow: row]) {
        frame.size.height += CELL_HEADER_HEIGHT;
        [cell setHeaderHeight: CELL_HEADER_HEIGHT];
    } else {
        cell.headerHeight = 0;
    }

    cell.frame = frame;
}

/**
 * Called by the PXListView when it needs to set up a new visual cell. This method uses enqueued cells
 * to avoid creating potentially many cells. This way we can have many entries but still only as many
 * cells as fit in the window.
 */
- (PXListViewCell *)listView: (PXListView *)aListView cellForRow: (NSUInteger)row
{
    StatementsListViewCell *cell = (StatementsListViewCell *)[aListView dequeueCellWithReusableIdentifier: @"statcell"];

    if (!cell) {
        cell = [StatementsListViewCell cellLoadedFromNibNamed: @"StatementsListViewCell" reusableIdentifier: @"statcell"];
    }

    [self fillCell: cell forRow: row];

    return cell;
}

- (CGFloat)listView: (PXListView *)aListView heightOfRow: (NSUInteger)row forDragging: (BOOL)forDragging
{
    if (!forDragging && [self showsHeaderForRow: row]) {
        return CELL_BODY_HEIGHT + CELL_HEADER_HEIGHT;
    }
    return CELL_BODY_HEIGHT;
}

- (NSRange)listView: (PXListView *)aListView rangeOfDraggedRow: (NSUInteger)row
{
    if ([self showsHeaderForRow: row]) {
        return NSMakeRange(CELL_HEADER_HEIGHT, CELL_BODY_HEIGHT);
    }
    return NSMakeRange(0, CELL_BODY_HEIGHT);
}

- (void)listViewSelectionDidChange: (NSNotification *)aNotification
{
    if (autoResetNew) {
        // A selected statement automatically loses the "new" state (if auto reset is enabled).
        NSIndexSet *selection = [self selectedRows];
        NSUInteger index = [selection firstIndex];
        while (index != NSNotFound) {
            StatementsListViewCell *cell = (id)[self cellForRowAtIndex : index];
            cell.isNew = NO;
            index = [selection indexGreaterThanIndex: index];
        }
    }

    // Also let every entry check its selection state, in case internal states must be updated.
    NSArray *cells = [self visibleCells];
    for (StatementsListViewCell *cell in cells) {
        [cell selectionChanged];
    }
}

- (bool)listView: (PXListView *)aListView shouldSelectRows: (NSIndexSet *)rows byExtendingSelection: (BOOL)shouldExtend
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
    for (StatementsListViewCell *cell in cells) {
        [self fillCell: cell forRow: [cell row]];
    }
}

/**
 * Activates all selected cells. If no cell is selected then all cells are activated.
 * Implicitly makes all cells show the activator.
 */
- (void)activateCells
{
    activating = YES;
    @try {
        NSIndexSet *selection = [self selectedRows];
        if (selection.count > 0) {
            NSUInteger index = [selection firstIndex];
            while (index != NSNotFound) {
                StatementsListViewCell *cell = (id)[self cellForRowAtIndex : index];
                [cell showActivator: YES markActive: YES];
                index = [selection indexGreaterThanIndex: index];
            }
        } else {
            for (NSUInteger index = 0; index < [dataSource count]; index++) {
                StatementsListViewCell *cell = (id)[self cellForRowAtIndex : index];
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

extern NSString *const BankStatementDataType;

- (BOOL)listView: (PXListView *)aListView writeRowsWithIndexes: (NSIndexSet *)rowIndexes
    toPasteboard: (NSPasteboard *)dragPasteboard
       slideBack: (BOOL *)slideBack
{
    *slideBack = YES;

    // Keep a copy of the selected indexes as the selection is removed during the drag operation,
    // but we need to update the selected cells then.
    draggedIndexes = [rowIndexes copy];

    NSUInteger        indexes[30], count, i;
    NSRange           range;
    StatCatAssignment *stat;
    NSMutableArray    *uris = [NSMutableArray arrayWithCapacity: 30];

    range.location = 0;
    range.length = 100000;

    // Copy the row numbers to the pasteboard.
    do {
        count = [rowIndexes getIndexes: indexes maxCount: 30 inIndexRange: &range];
        for (i = 0; i < count; i++) {
            stat = dataSource[indexes[i]];
            NSURL *uri = [[stat objectID] URIRepresentation];
            [uris addObject: uri];
        }
    } while (count > 0);

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uris];
    [dragPasteboard declareTypes: @[BankStatementDataType] owner: self];
    [dragPasteboard setData: data forType: BankStatementDataType];

    return YES;
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
