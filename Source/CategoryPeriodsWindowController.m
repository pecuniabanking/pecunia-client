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

#import "MBTableGrid/MBTableGrid.h"
#import "MBTableGrid/MBTableGridHeaderView.h"
#import "BWGradientBox.h"

#import "CategoryPeriodsWindowController.h"
#import "ShortDate.h"
#import "NSOutlineView+PecuniaAdditions.h"
#import "CategoryReportingNode.h"
#import "MOAssistant.h"
#import "AmountCell.h"
#import "StatCatAssignment.h"
#import "BankStatement.h"

#import "NSColor+PecuniaAdditions.h"
#import "AnimationHelper.h"
#import "SynchronousScrollView.h"
#import "StatementsListview.h"

extern void *UserDefaultsBindingContext;

@interface CategoryPeriodsWindowController (Private)

- (void)loadDataForIndex: (NSInteger)index;
- (void)showStatementList: (NSRect)cellBounds;
- (void)updateStatementList: (NSRect)cellBounds;
- (void)updateData;
- (void)updateLimitLabel: (NSTextField *)field index: (NSUInteger)index;
- (void)updateSorting;

@end

@implementation CategoryPeriodsWindowController

@synthesize outline;

#pragma mark -
#pragma mark Initialization and Deallocation

- (id)init
{
    self = [super init];
    if (self != nil) {
        active = NO;
        dates = [NSMutableArray array];
        balances = [NSMutableArray array];
        turnovers = [NSMutableArray array];
        selectedDates = [NSMutableArray array];
        managedObjectContext = [[MOAssistant assistant] context];
        sortIndex = 0;
    }

    return self;
}

- (void)dealloc
{
    self.outline = nil; // Will remove self from default notification center.

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"colors"];
    [userDefaults removeObserver: self forKeyPath: @"recursiveTransactions"];
    [userDefaults removeObserver: self forKeyPath: @"showHiddenCategories"];
}

- (void)awakeFromNib
{
    fromIndex = 0;
    toIndex = 1;
    sortAscending = NO;
    groupingInterval = GroupByMonths;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary   *values = [userDefaults objectForKey: @"categoryPeriods"];
    if (values) {
        if (values[@"fromIndex"]) {
            fromIndex = [values[@"fromIndex"] intValue];
        }
        if (values[@"toIndex"]) {
            toIndex = [values[@"toIndex"] intValue];
        }
        if (values[@"grouping"]) {
            groupingInterval = [values[@"grouping"] intValue];
            groupingSlider.intValue = groupingInterval;
        }
        if (values[@"sortIndex"]) {
            sortIndex = [values[@"sortIndex"] intValue];
            if (sortIndex < 0 || sortIndex >= sortControl.segmentCount) {
                sortIndex = 0;
            }
            sortControl.selectedSegment = sortIndex;
        }
        if (values[@"sortAscending"]) {
            sortAscending = ![values[@"sortAscending"] boolValue];
        }
    }
    [self updateSorting];

    if (toIndex < fromIndex) {
        toIndex = fromIndex;
    }

    [fromSlider setContinuous: YES];
    fromSlider.intValue = fromIndex;
    [self updateLimitLabel: fromText index: fromIndex];
    [toSlider setContinuous: YES];
    toSlider.intValue = toIndex;
    [self updateLimitLabel: toText index: toIndex];

    valueGrid.defaultCellSize = NSMakeSize(100, 22);
    [valueGrid.rowHeaderView setHidden: YES];

    AmountCell *cell = [[AmountCell alloc] initTextCell: @""];
    [cell setAlignment: NSRightTextAlignment];
    valueGrid.cell = cell;

    NSNumberFormatter *formatter = cell.formatter;

    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    [formatter setLocale: [NSLocale currentLocale]];
    [formatter setCurrencySymbol: @""];

    valueGrid.allowsMultipleSelection = NO;
    valueGrid.showSelectionRing = NO;

    [statementsListView bind: @"dataSource" toObject: statementsController withKeyPath: @"arrangedObjects" options: nil];

    // Bind controller to selectedRow property and the listview to the controller's selectedIndex property to get notified about selection changes.
    [statementsController bind: @"selectionIndexes" toObject: statementsListView withKeyPath: @"selectedRows" options: nil];
    [statementsListView bind: @"selectedRows" toObject: statementsController withKeyPath: @"selectionIndexes" options: nil];

    statementsListView.cellSpacing = 0;
    statementsListView.allowsEmptySelection = YES;
    statementsListView.allowsMultipleSelection = NO;
    statementsListView.disableSelection = YES;

    selectionBox.hasGradient = YES;
    selectionBox.fillStartingColor = [NSColor applicationColorForKey: @"Small Background Gradient (low)"];
    selectionBox.fillEndingColor = [NSColor applicationColorForKey: @"Small Background Gradient (high)"];
    selectionBox.cornerRadius = 5;
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor colorWithCalibratedWhite: 0 alpha: 0.5];
    shadow.shadowOffset = NSMakeSize(1, -1);
    shadow.shadowBlurRadius = 3;
    selectionBox.shadow = shadow;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
    [defaults addObserver: self forKeyPath: @"recursiveTransactions" options: 0 context: UserDefaultsBindingContext];
    [defaults addObserver: self forKeyPath: @"showHiddenCategories" options: 0 context: UserDefaultsBindingContext];
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            [self updateColors];
            [selectionBox setNeedsDisplay: YES];
        }
        if ([keyPath isEqualToString: @"recursiveTransactions"]) {
            [self updateData];
        }
        if ([keyPath isEqualToString: @"showHiddenCategories"]) {
            [valueGrid reloadData];
        }
    }
}

- (void)updateColors
{
    selectionBox.fillStartingColor = [NSColor applicationColorForKey: @"Small Background Gradient (low)"];
    selectionBox.fillEndingColor = [NSColor applicationColorForKey: @"Small Background Gradient (high)"];
}

#pragma mark -
#pragma mark MBTableGrid Delegate Methods

- (NSUInteger)numberOfRowsInTableGrid: (MBTableGrid *)aTableGrid
{
    return outline.numberOfRows - 1;     // Leave out the top category node.
}

- (NSUInteger)numberOfColumnsInTableGrid: (MBTableGrid *)aTableGrid
{
    if (dates.count == 0) {
        return 0;
    }
    return toIndex - fromIndex + 1;
}

- (id)tableGrid: (MBTableGrid *)aTableGrid objectValueForColumn: (NSUInteger)columnIndex row: (NSUInteger)rowIndex
{
    NSArray *rowValues = balances[rowIndex];
    if (rowValues.count == 0) {
        [self loadDataForIndex: rowIndex];
        rowValues = balances[rowIndex];
    }
    Category   *cat = [[outline itemAtRow: rowIndex + 1] representedObject];
    AmountCell *cell = valueGrid.cell;
    cell.currency = cat.currency;

    columnIndex += fromIndex;
    return ([rowValues count] > columnIndex) ? rowValues[columnIndex] : @"";
}

- (void)tableGrid: (MBTableGrid *)aTableGrid setObjectValue: (id)anObject forColumn: (NSUInteger)columnIndex row: (NSUInteger)rowIndex
{
    // Only needed to have the grid call us for editing.
}

- (NSString *)tableGrid: (MBTableGrid *)aTableGrid headerStringForColumn: (NSUInteger)columnIndex
{
    ShortDate *date = dates[columnIndex + fromIndex];
    NSString  *title;

    switch (groupingInterval) {
        case GroupByYears:
            title = [date yearDescription];
            break;

        case GroupByQuarters:
            title = [date quarterYearDescription];
            break;

        default:
            title = [date monthYearDescription];
            break;
    }
    return title;
}

- (BOOL)tableGrid: (MBTableGrid *)aTableGrid canMoveColumns: (NSIndexSet *)columnIndexes toIndex: (NSUInteger)index
{
    return YES;
}

/**
 * Triggered when the grid wants to start editing a cell. We don't allow that but instead show the
 * statement details popup.
 */
- (BOOL)tableGrid: (MBTableGrid *)aTableGrid shouldEditColumn: (NSUInteger)columnIndex row: (NSUInteger)rowIndex
{
    if (detailsPopover.shown) {
        [detailsPopover performClose: self];
    } else {
        id item = [outline itemAtRow: rowIndex + 1];
        self.selectedCategory = [item representedObject];
        [self showStatementList: [valueGrid frameOfCellAtColumn: columnIndex row: rowIndex]];
    }
    return false;
}

- (void)cancelEditForTableGrid: (MBTableGrid *)aTableGrid
{
    if (detailsPopover.shown) {
        [detailsPopover performClose: self];
    }
}

- (void)tableGridDidChangeSelection: (NSNotification *)aNotification
{
    // Since we only have single selection enabled there should only be at most one row in this set.
    NSIndexSet *selectedRows;
    if (valueGrid.selectedRowIndexes.count == 0) {
        selectedRows = [NSIndexSet indexSet];
    } else {
        selectedRows = [NSIndexSet indexSetWithIndex: valueGrid.selectedRowIndexes.firstIndex + 1];
    }

    if (![selectedRows isEqualToIndexSet: [outline selectedRowIndexes]]) {
        [outline selectRowIndexes: selectedRows byExtendingSelection: NO];
    }

    if (selectedRows.count > 0) {
        NSUInteger columnIndex = valueGrid.selectedColumnIndexes.firstIndex;
        id         item = [outline itemAtRow: selectedRows.firstIndex];

        self.selectedCategory = [item representedObject];
        if (detailsPopover.shown) {
            [self updateStatementList: [valueGrid frameOfCellAtColumn: columnIndex row: selectedRows.firstIndex - 1]];
        }
    }
}

- (void)outlineDidChangeSelection
{
    if (!active) {
        return;
    }
    NSIndexSet *selectedRows;
    if (outline.selectedRowIndexes.count == 0) {
        selectedRows = [NSIndexSet indexSet];
    } else {
        selectedRows = [NSIndexSet indexSetWithIndex: outline.selectedRowIndexes.firstIndex - 1];
    }
    if (![selectedRows isEqualToIndexSet: valueGrid.selectedRowIndexes]) {
        valueGrid.selectedRowIndexes = selectedRows;
    }
}

#pragma mark -
#pragma mark Additional Stuff

- (void)connectScrollViews: (SynchronousScrollView *)other
{
    [valueGrid.contentScrollView setSynchronizedScrollView: other];
    [other setSynchronizedScrollView: valueGrid.contentScrollView];
}

- (void)setOutline: (NSOutlineView *)outlineView
{
    if (outline != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver: self];
    }
    outline = outlineView;
    if (outline != nil) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(updateData)
                                                     name: NSOutlineViewItemDidCollapseNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(updateData)
                                                     name: NSOutlineViewItemDidExpandNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(outlineDidChangeSelection)
                                                     name: NSOutlineViewSelectionDidChangeNotification
                                                   object: nil];
    }
}

- (void)updateData
{
    if (!active) {
        return;
    }

    [dates removeAllObjects];
    [balances removeAllObjects];
    [turnovers removeAllObjects];
    NSInteger rowCount = outline.numberOfRows - 1;

    for (int i = 0; i < rowCount; i++) {
        [balances addObject: @[]];
        [turnovers addObject: @[]];
    }
    if (rowCount > 0) {
        // Fill the dates array with dates that fill the entire range of available values.
        ShortDate *min = minDate;
        ShortDate *max = maxDate;
        [[[outline itemAtRow: 0] representedObject] getDatesMin: &min max: &max];
        switch (groupingInterval) {
            case GroupByYears:
                minDate = [min lastDayInYear];
                maxDate = [max lastDayInYear];
                break;

            case GroupByQuarters:
                minDate = [min lastDayInQuarter];
                maxDate = [max lastDayInQuarter];
                break;

            default:
                minDate = [min lastDayInMonth];
                maxDate = [max lastDayInMonth];
        }

        ShortDate *date = minDate;
        while ([date compare: maxDate] != NSOrderedDescending) {
            [dates addObject: date];
            switch (groupingInterval) {
                case GroupByYears:
                    date = [date dateByAddingUnits: 1 byUnit: NSCalendarUnitYear];
                    break;

                case GroupByQuarters:
                    date = [date dateByAddingUnits: 1 byUnit: NSCalendarUnitQuarter];
                    break;

                default:
                    date = [date dateByAddingUnits: 1 byUnit: NSCalendarUnitMonth];
            }
        }

    }

    fromSlider.maxValue = dates.count - 1;
    if (fromIndex > fromSlider.maxValue) {
        fromIndex = fromSlider.maxValue;
        fromSlider.intValue = fromIndex;
    }
    [self updateLimitLabel: fromText index: fromIndex];

    toSlider.maxValue = dates.count - 1;
    if (toIndex > toSlider.maxValue) {
        toIndex = toSlider.maxValue;
        toSlider.intValue = toIndex;
    }
    [self updateLimitLabel: toText index: toIndex];

    [self updateOutline];
    [valueGrid reloadData];
    [valueGrid setNeedsDisplay: YES];
}

- (void)loadDataForIndex: (NSInteger)index
{
    Category *item = [[outline itemAtRow: index + 1] representedObject];

    NSArray *nodeDates = nil;
    NSArray *nodeBalances = nil;
    NSArray *nodeTurnovers = nil;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [item historyToDates: &nodeDates
                balances: &nodeBalances
           balanceCounts: &nodeTurnovers
            withGrouping: groupingInterval
                   sumUp: NO
               recursive: [defaults boolForKey: @"recursiveTransactions"]];

    if (nodeDates == nil) {
        nodeDates = @[]; // Just to avoid frequent checks in the loop below.
    }
    
    // Dates for this category might not correspond to the display range (i.e. no value for all dates)
    // so move the existing values to the appropriate array index and fill the rest with 0.
    NSMutableArray *balanceArray = [NSMutableArray arrayWithCapacity: [dates count]];
    NSUInteger     dateIndex = 0;
    for (ShortDate *date in dates) {
        if (dateIndex >= [nodeDates count] || [date compare: nodeDates[dateIndex]] == NSOrderedAscending) {
            [balanceArray addObject: [NSDecimalNumber zero]];
        } else {
            [balanceArray addObject: nodeBalances[dateIndex]];
            dateIndex++;
        }
    }
    balances[index] = balanceArray;
}

- (void)showStatementList: (NSRect)cellBounds
{
    if (!detailsPopover.shown) {
        [detailsPopover showRelativeToRect: cellBounds ofView: valueGrid preferredEdge: NSMinYEdge];
    }
    [self updateStatementList: cellBounds];
}

- (void)updateStatementList: (NSRect)cellBounds
{
    // It can happen data is not yet ready, so get out of here. We'll get a new chance later.
    NSUInteger columnIndex = valueGrid.selectedColumnIndexes.firstIndex;
    if (columnIndex + fromIndex > dates.count) {
        return;
    }
    
    ShortDate *selFromDate;
    ShortDate *selToDate = dates[columnIndex + fromIndex];
    switch (groupingInterval) {
        case GroupByYears:
            selFromDate = [selToDate firstDayInYear];
            break;

        case GroupByQuarters:
            selFromDate = [selToDate firstDayInQuarter];
            break;

        default:
            selFromDate = [selToDate firstDayInMonth];
            break;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSPredicate *predicate;

    if ([defaults boolForKey: @"recursiveTransactions"]) {
        predicate = [NSPredicate predicateWithFormat: @"category IN %@ AND statement.date >= %@ AND statement.date <= %@",
                     [self.selectedCategory allCategories], [selFromDate lowDate], [selToDate highDate]];
    } else {
        predicate = [NSPredicate predicateWithFormat: @"category = %@ AND statement.date >= %@ AND statement.date <= %@",
                     self.selectedCategory, [selFromDate lowDate], [selToDate highDate]];
    }
    [statementsController setFetchPredicate: predicate];
    [statementsController prepareContent];

    if (detailsPopover.shown) {
        [detailsPopover showRelativeToRect: cellBounds ofView: valueGrid preferredEdge: NSMinYEdge];
    }
}

- (void)updateLimitLabel: (NSTextField *)field index: (NSUInteger)index
{
    if (dates.count == 0) {
        field.stringValue = @"--";
    } else {
        ShortDate *date = dates[index];
        switch (groupingInterval) {
            case GroupByYears:
                field.stringValue = [date yearDescription];
                break;

            case GroupByQuarters:
                field.stringValue = [date quarterYearDescription];
                break;

            default:
                field.stringValue = [date monthYearDescription];
                break;
        }
    }
}

- (void)updateSorting
{
    [sortControl setImage: nil forSegment: sortIndex];
    sortIndex = [sortControl selectedSegment];
    if (sortIndex < 0) {
        sortIndex = 0;
    }
    NSImage *sortImage = sortAscending ? [NSImage imageNamed: @"sort-indicator-inc"] : [NSImage imageNamed: @"sort-indicator-dec"];
    [sortControl setImage: sortImage forSegment: sortIndex];

    NSUserDefaults      *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *values = [[userDefaults objectForKey: @"categoryPeriods"] mutableCopy];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 2];
    }
    [values setValue: @(sortIndex) forKey: @"sortIndex"];
    [values setValue: @(sortAscending) forKey: @"sortAscending"];
    [userDefaults setObject: values forKey: @"categoryPeriods"];

    NSString *key;
    switch (sortIndex) {
        case 1:
            statementsListView.canShowHeaders = false;
            key = @"statement.remoteName";
            break;

        case 2:
            statementsListView.canShowHeaders = false;
            key = @"statement.purpose";
            break;

        case 3:
            statementsListView.canShowHeaders = false;
            key = @"statement.categoriesDescription";
            break;

        case 4:
            statementsListView.canShowHeaders = false;
            key = @"statement.value";
            break;

        default:
            statementsListView.canShowHeaders = true;
            key = @"statement.date";
            break;
    }
    [statementsController setSortDescriptors:
     @[[[NSSortDescriptor alloc] initWithKey: key ascending: sortAscending]]];
}

- (void)updateOutline
{
    if ([dates count] == 0) {
        return;
    }

    ShortDate *fromDate = dates[fromIndex];
    ShortDate *toDate = dates[toIndex];

    switch (groupingInterval) {
        case GroupByMonths:
            fromDate = [fromDate firstDayInMonth];
            toDate = [toDate lastDayInMonth];
            break;

        case GroupByQuarters:
            fromDate = [fromDate firstDayInQuarter];
            toDate = [toDate lastDayInQuarter];
            break;

        case GroupByYears:
            fromDate = [fromDate firstDayInYear];
            toDate = [toDate lastDayInYear];
            break;

        default:
            break;
    }

    [Category setCatReportFrom: fromDate to: toDate];
}

#pragma mark -
#pragma mark Interface Builder Actions

- (IBAction)setGrouping: (id)sender
{
    groupingInterval = [sender intValue];

    NSUserDefaults      *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *values = [[userDefaults objectForKey: @"categoryPeriods"] mutableCopy];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 1];
    }
    [values setValue: @((int)groupingInterval) forKey: @"grouping"];
    [userDefaults setObject: values forKey: @"categoryPeriods"];

    [self updateData];
}

- (IBAction)fromChanged: (id)sender
{
    int fromPosition = [sender intValue];
    if (fromIndex == fromPosition) {
        return;
    }
    fromIndex = fromPosition;
    if (fromIndex > toIndex) {
        toIndex = fromIndex;
        toSlider.intValue = toIndex;
        [self updateLimitLabel: toText index: toIndex];
    }

    [self updateLimitLabel: fromText index: fromIndex];

    NSUserDefaults      *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *values = [[userDefaults objectForKey: @"categoryPeriods"] mutableCopy];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 1];
    }
    [values setValue: @(fromIndex) forKey: @"fromIndex"];
    [userDefaults setObject: values forKey: @"categoryPeriods"];

    [self updateOutline];
    [valueGrid reloadData];
}

- (IBAction)toChanged: (id)sender
{
    int toPosition = [sender intValue];
    if (toIndex == toPosition) {
        return;
    }

    toIndex = toPosition;
    if (toIndex < fromIndex) {
        fromIndex = toIndex;
        fromSlider.intValue = fromIndex;
        [self updateLimitLabel: fromText index: fromIndex];
    }

    [self updateLimitLabel: toText index: toIndex];

    NSUserDefaults      *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *values = [[userDefaults objectForKey: @"categoryPeriods"] mutableCopy];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 1];
    }
    [values setValue: @(toIndex) forKey: @"toIndex"];
    [userDefaults setObject: values forKey: @"categoryPeriods"];

    [self updateOutline];
    [valueGrid reloadData];
}

- (IBAction)filterStatements: (id)sender
{
    NSTextField *field = sender;
    NSString    *text = [field stringValue];

    if ([text length] == 0) {
        [statementsController setFilterPredicate: nil];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or userInfo contains[c] %@ or value = %@",
                                  text, text, text, [NSDecimalNumber decimalNumberWithString: text locale: [NSLocale currentLocale]]];
        if (predicate != nil) {
            [statementsController setFilterPredicate: predicate];
        }
    }
}

- (IBAction)sortingChanged: (id)sender
{
    if ([sender selectedSegment] == sortIndex) {
        sortAscending = !sortAscending;
    } else {
        sortAscending = YES;
    }

    [self updateSorting];
}

#pragma mark -
#pragma mark PecuniaSectionItem protocol

@synthesize selectedCategory;

- (void)print
{
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    [printInfo setHorizontalPagination: NSFitPagination];
    [printInfo setVerticalPagination: NSAutoPagination];
    NSPrintOperation *printOp;
    printOp = [NSPrintOperation printOperationWithView: printView printInfo: printInfo];
    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];
}

- (NSView *)mainView
{
    return mainView;
}

- (void)activate
{
    active = YES;

    // Reload the grid data, but not before the current run loop ended. Otherwise we end
    // up with a wrong number of rows (predicate changes in the tree controller are applied to the
    // outline not before the end of the current run loop).
    [self performSelector: @selector(updateData) withObject: nil afterDelay: 0];
}

- (void)deactivate
{
    active = NO;
}

- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to
{
}

@end
