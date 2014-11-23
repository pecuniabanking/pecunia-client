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

#import "MessageLog.h"

#import "StatCatAssignment.h"
#import "ShortDate.h"
#import "BankStatement.h"
#import "BankAccount.h"

@interface StatementsListView ()
{
    id observedObject;

    NSDateFormatter *dateFormatter;
    NSIndexSet      *draggedIndexes;

    BOOL showAssignedIndicators;
    id   owner;
    BOOL activating;     // Set when cells are activated programmatically (so we don't send notifications around).

    BOOL showHeaders;
}

@end

@implementation StatementsListView

@synthesize showAssignedIndicators;
@synthesize disableSelection;
@synthesize canShowHeaders;

static void *DataSourceBindingContext = (void *)@"DataSourceContext";
extern void *UserDefaultsBindingContext;

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setDelegate: self];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale: [NSLocale currentLocale]];
    [dateFormatter setDateStyle: kCFDateFormatterFullStyle];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    disableSelection = NO;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults addObserver: self forKeyPath: @"showHeadersInLists" options: 0 context: UserDefaultsBindingContext];
    showHeaders = YES;
    canShowHeaders = YES;
    if ([defaults objectForKey: @"showHeadersInLists"] != nil) {
        showHeaders = [defaults boolForKey: @"showHeadersInLists"];
    }

    [self initDetailsWithNibName: @"StatementDetails"];
}

- (void)dealloc {
    [self removeBindings];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver: self forKeyPath: @"showHeadersInLists"];
}

#pragma mark - Bindings, KVO and KVC

- (void)removeBindings {
    [observedObject removeObserver: self forKeyPath: @"arrangedObjects"];
}

- (void)   bind: (NSString *)binding
       toObject: (id)observableObject
    withKeyPath: (NSString *)keyPath
        options: (NSDictionary *)options {
    if ([binding isEqualToString: @"dataSource"]) {
        observedObject = observableObject;
        self.dataSource = [observableObject valueForKey: keyPath];

        // One binding for the array, to get notifications about insertion and deletions.
        [observableObject addObserver: self
                           forKeyPath: @"arrangedObjects"
                              options: 0
                              context: DataSourceBindingContext];
    } else {
        [super bind: binding toObject: observableObject withKeyPath: keyPath options: options];
    }
}

- (void)unbind: (NSString *)binding {
    if ([binding isEqualToString: @"dataSource"]) {
        [self removeBindings];
    } else {
        [super unbind: binding];
    }
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context {
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"showHeadersInLists"]) {
            showHeaders = [NSUserDefaults.standardUserDefaults boolForKey: @"showHeadersInLists"];
            [self reloadData];
            return;
        }
    }

    if (context == DataSourceBindingContext) {
        [self reloadData];
        return;
    }

    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

#pragma mark - PXListViewDelegate protocoll implementation

- (NSUInteger)numberOfRowsInListView: (PXListView *)aListView {
#pragma unused(aListView)
    return [self.dataSource count];
}

- (BOOL)showsHeaderForRow: (NSUInteger)row {
    // The given row can be out of bounds as we asynchronously reload the list on datasource changes
    // and there can be relayout events before the actual reload kicks in.
    if (!showHeaders || !canShowHeaders || row >= self.dataSource.count) {
        return false;
    }

    BOOL result = (row == 0);
    if (!result) {
        BankStatement *statement = (BankStatement *)[self.dataSource[row] valueForKey: @"statement"];
        BankStatement *previousStatement = (BankStatement *)[self.dataSource[row - 1] valueForKey: @"statement"];

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
- (int)countSameDatesFromRow: (NSUInteger)row {
    int result = 1;

    BankStatement *statement = [self.dataSource[row] statement];
    ShortDate     *currentDate = [ShortDate dateWithDate: statement.date];

    NSUInteger totalCount = [self.dataSource count];
    while (++row < totalCount) {
        statement = [self.dataSource[row] statement];
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

- (void)fillCell: (StatementsListViewCell *)cell forRow: (NSUInteger)row {
    StatCatAssignment *assignment = (StatCatAssignment *)self.dataSource[row];

    cell.delegate = self;
    cell.representedObject = assignment;

    if (self.showAssignedIndicators) {
        bool activate = assignment.category != nil && assignment.category != BankingCategory.nassRoot;
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
- (PXListViewCell *)listView: (PXListView *)aListView cellForRow: (NSUInteger)row {
    StatementsListViewCell *cell = (StatementsListViewCell *)[aListView dequeueCellWithReusableIdentifier: @"statcell"];

    if (!cell) {
        cell = [StatementsListViewCell cellLoadedFromNibNamed: @"StatementsListViewCell" reusableIdentifier: @"statcell"];
    }

    [self fillCell: cell forRow: row];

    return cell;
}

- (CGFloat)listView: (PXListView *)aListView heightOfRow: (NSUInteger)row forDragging: (BOOL)forDragging {
    if (!forDragging && [self showsHeaderForRow: row]) {
        return CELL_BODY_HEIGHT + CELL_HEADER_HEIGHT;
    }
    return CELL_BODY_HEIGHT;
}

- (NSRange)listView: (PXListView *)aListView rangeOfDraggedRow: (NSUInteger)row {
    if ([self showsHeaderForRow: row]) {
        return NSMakeRange(CELL_HEADER_HEIGHT, CELL_BODY_HEIGHT);
    }
    return NSMakeRange(0, CELL_BODY_HEIGHT);
}

- (void)listViewSelectionDidChange: (NSNotification *)aNotification {
    // Let every visible entry check its selection state, in case internal states must be updated.
    NSArray *cells = [self visibleCells];
    for (StatementsListViewCell *cell in cells) {
        [cell selectionChanged];
    }
}

- (bool)listView: (PXListView *)aListView shouldSelectRows: (NSIndexSet *)rows byExtendingSelection: (BOOL)shouldExtend {
    return !self.disableSelection;
}

#pragma mark - General stuff and User actions

/**
 * Triggered when KVO notifies us about changes.
 */
- (void)updateVisibleCells {
    NSArray *cells = [self visibleCells];
    for (StatementsListViewCell *cell in cells) {
        [self fillCell: cell forRow: [cell row]];
    }
}

/**
 * Activates all selected cells. If no cell is selected then all cells are activated.
 * Implicitly makes all cells show the activator.
 */
- (void)activateCells {
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
            for (NSUInteger index = 0; index < self.dataSource.count; index++) {
                StatementsListViewCell *cell = (id)[self cellForRowAtIndex : index];
                [cell showActivator: YES markActive: YES];
            }
        }
    }
    @finally {
        activating = NO;
    }
}

#pragma mark - Drag'n drop

extern NSString *const BankStatementDataType;

- (BOOL)listView: (PXListView *)aListView writeRowsWithIndexes: (NSIndexSet *)rowIndexes
    toPasteboard: (NSPasteboard *)dragPasteboard
       slideBack: (BOOL *)slideBack {
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
            stat = self.dataSource[indexes[i]];
            if (stat.statement.isPreliminary.boolValue == NO) {
                NSURL *uri = [[stat objectID] URIRepresentation];
                [uris addObject: uri];
            }
        }
    } while (count > 0);
    
    if (uris.count == 0) {
        return NO;
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uris];
    [dragPasteboard declareTypes: @[BankStatementDataType] owner: self];
    [dragPasteboard setData: data forType: BankStatementDataType];

    return YES;
}

#pragma mark - StatementsListViewNotificationProtocol

- (void)cellActivationChanged: (BOOL)state forIndex: (NSUInteger)index {
    if (!activating) {
        // Simply forward the notification to the notification delegate if any is set.
        if ([self.owner respondsToSelector: @selector(activationChanged:forIndex:)]) {
            [self.owner activationChanged: state forIndex: index];
        }
    }
}

- (void)menuActionForCell: (PecuniaListViewCell *)cell action: (StatementMenuAction)action {
    if ([self.owner respondsToSelector: @selector(actionForCategory:action:)]) {
        [self.owner actionForCategory: cell.representedObject action: action];
    }
}

- (BOOL)canHandleMenuActions {
    return [self.owner respondsToSelector: @selector(actionForCategory:action:)];
}

@end
