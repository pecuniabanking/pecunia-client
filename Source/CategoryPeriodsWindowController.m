/** 
 * Copyright (c) 2010, 2012, Pecunia Project. All rights reserved.
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
#import "MAAttachedWindow.h"
#import "BWGradientBox.h"

#import "CategoryPeriodsWindowController.h"
#import "ShortDate.h"
#import "MCEMOutlineViewLayout.h"
#import "CategoryReportingNode.h"
#import "MOAssistant.h"
#import "AmountCell.h"
#import "StatCatAssignment.h"
#import "BankStatement.h"

#import "GraphicsAdditions.h"
#import "AnimationHelper.h"
#import "SynchronousScrollView.h"
#import "StatementsListview.h"

@interface CategoryPeriodsWindowController (Private)

- (void)loadDataForIndex: (NSInteger)index;
- (void)hideStatementList;
- (void)showStatementList: (NSRect)cellBounds;
- (void)updateStatementList: (NSRect)cellBounds;
- (void)updateData;
- (void)updateLimitLabel: (NSTextField *)field index: (NSUInteger) index;
- (void)updateSorting;

@end

@implementation CategoryPeriodsWindowController

@synthesize outline;

#pragma mark -
#pragma mark Initialization and Deallocation

-(id)init
{
    self = [super init];
    if (self != nil) {
        active = NO;
        dates = [NSMutableArray array];
        balances = [NSMutableArray array];
        turnovers = [NSMutableArray array];
        selectedDates = [NSMutableArray array];
        managedObjectContext = [[MOAssistant assistant] context];
    }
    
    return self;
}

- (void)dealloc
{
    self.outline = nil; // Will remove self from default notification center.
}

-(void)awakeFromNib
{
	fromIndex = 0;
    toIndex = 1;
    sortAscending = NO;
    sortIndex = 0;
    groupingInterval = GroupByMonths;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *values = [userDefaults objectForKey: @"categoryPeriods"];
    if (values) {
        if ([values objectForKey: @"fromIndex" ]) {
            fromIndex = [[values objectForKey: @"fromIndex" ] intValue];
        }
        if ([values objectForKey: @"toIndex" ]) {
            toIndex = [[values objectForKey: @"toIndex" ] intValue];
        }
        if ([values objectForKey: @"grouping" ]) {
            groupingInterval = [[values objectForKey: @"grouping"] intValue];
            groupingSlider.intValue = groupingInterval;
        }
        if ([values objectForKey: @"sortIndex" ]) {
            sortControl.selectedSegment = [[values objectForKey: @"sortIndex"] intValue];
        }
        if ([values objectForKey: @"sortAscending" ]) {
            sortAscending = ![[values objectForKey: @"sortAscending"] boolValue];
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
    NSDictionary *positiveAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Positive Cash"], NSForegroundColorAttributeName,
                                        nil
                                        ];
    NSDictionary *negativeAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Negative Cash"], NSForegroundColorAttributeName,
                                        nil
                                        ];
    
    NSNumberFormatter *formatter = cell.formatter;
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];

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
    
    formatter = [statementsListView numberFormatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    
    selectionBox.hasGradient = YES;
    selectionBox.fillStartingColor = [NSColor applicationColorForKey: @"Small Background Gradient (low)"];
    selectionBox.fillEndingColor = [NSColor applicationColorForKey: @"Small Background Gradient (high)"];
    selectionBox.cornerRadius = 5;
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor colorWithCalibratedWhite: 0 alpha: 0.5];
    shadow.shadowOffset = NSMakeSize(1, -1);
    shadow.shadowBlurRadius = 3;
    selectionBox.shadow = shadow;
}

#pragma mark -
#pragma mark MBTableGrid Delegate Methods

- (NSUInteger)numberOfRowsInTableGrid: (MBTableGrid*)aTableGrid
{
	return outline.numberOfRows - 1; // Leave out the top category node.
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
    NSArray* rowValues = [balances objectAtIndex: rowIndex];
    if (rowValues.count == 0) {
        [self loadDataForIndex: rowIndex];
        rowValues = [balances objectAtIndex: rowIndex];
    }
    Category *cat = [[outline itemAtRow: rowIndex] representedObject];
    AmountCell *cell = valueGrid.cell;
    cell.currency = cat.currency;
    
    columnIndex +=  fromIndex;
	return ([rowValues count] > columnIndex) ? [rowValues objectAtIndex: columnIndex] : @"";
}

- (void)tableGrid: (MBTableGrid *)aTableGrid setObjectValue: (id)anObject forColumn: (NSUInteger)columnIndex row: (NSUInteger)rowIndex
{
    // Only needed to have the grid call us for editing.
}

- (NSString *) tableGrid: (MBTableGrid*)aTableGrid headerStringForColumn: (NSUInteger)columnIndex
{
    ShortDate* date = [dates objectAtIndex: columnIndex + fromIndex];
    NSString* title;
        
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
    if (detailsPopupWindow != nil) {
        [self hideStatementList];
    } else {
        id item = [outline itemAtRow: rowIndex + 1];
        self.category = [item representedObject];
        [self showStatementList: [valueGrid frameOfCellAtColumn: columnIndex row: rowIndex]];
    }
    return false;
}

- (void)cancelEditForTableGrid: (MBTableGrid *)aTableGrid
{
    if (detailsPopupWindow != nil) {
        [self hideStatementList];
    }
}

- (void)tableGridDidChangeSelection: (NSNotification *)aNotification
{
    // Since we only have single selection enabled there should only be at most one row in this set.
    NSIndexSet *selectedRows;
    if (valueGrid.selectedRowIndexes.count == 0) {
        selectedRows = [NSIndexSet indexSet];
        [self hideStatementList];
    } else {
        selectedRows = [NSIndexSet indexSetWithIndex: valueGrid.selectedRowIndexes.firstIndex + 1];
    }
    
    if (![selectedRows isEqualToIndexSet: [outline selectedRowIndexes]]) {
        [outline selectRowIndexes: selectedRows byExtendingSelection: NO];
    }
    if (selectedRows.count > 0) {
        NSUInteger columnIndex = valueGrid.selectedColumnIndexes.firstIndex;
        id item = [outline itemAtRow: selectedRows.firstIndex];
        self.category = [item representedObject];
        [self updateStatementList: [valueGrid frameOfCellAtColumn: columnIndex row: selectedRows.firstIndex - 1]];
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

-(void)print
{
    NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    [printInfo setHorizontalPagination: NSFitPagination];
    [printInfo setVerticalPagination: NSAutoPagination];
    NSPrintOperation *printOp;
    printOp = [NSPrintOperation printOperationWithView: printView printInfo: printInfo];
    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];	
}

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

-(void)updateData
{
    if (!active) {
        return;
    }
    
    [self hideStatementList];
    
    [dates removeAllObjects];
    [balances removeAllObjects];
    [turnovers removeAllObjects];
    NSInteger rowCount = outline.numberOfRows - 1;
    
    for (int i = 0; i < rowCount; i++) {
        [balances addObject: [NSArray array]];
        [turnovers addObject: [NSArray array]];
    }
    
    if (rowCount > 0) {
        // Fill the dates array with dates that fill the entire range of available values.
        ShortDate *min = minDate;
        ShortDate *max = maxDate;
        [[[outline itemAtRow: 0] representedObject] getDatesMin: &min max: &max];
        switch (groupingInterval) {
            case GroupByYears:
                minDate = [min firstDayInYear];
                maxDate = [max firstDayInYear];
                break;
            case GroupByQuarters:
                minDate = [min firstDayInQuarter];
                maxDate = [max firstDayInQuarter];
                break;
            default:
                minDate = [min firstDayInMonth];
                maxDate = [max firstDayInMonth];
        }

        ShortDate* date = minDate;
        while ([date compare: maxDate] != NSOrderedDescending) {
            [dates addObject: date];
            switch (groupingInterval) {
                case GroupByYears:
                    date = [date dateByAddingUnits: 1 byUnit: NSYearCalendarUnit];
                    break;
                case GroupByQuarters:
                    date = [date dateByAddingUnits: 1 byUnit: NSQuarterCalendarUnit];
                    break;
                default:
                    date = [date dateByAddingUnits: 1 byUnit: NSMonthCalendarUnit];
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
        fromSlider.intValue = toIndex;
    }
    [self updateLimitLabel: toText index: toIndex];
    
    // Remaining data is loaded on demand.
    //[self performSelectorInBackground:@selector(updateOutline) withObject:nil]; // <- this is leaking objects
    [self updateOutline];
    [valueGrid reloadData];
    [valueGrid setNeedsDisplay: YES];
}

- (void)loadDataForIndex: (NSInteger) index
{
    Category *item = [[outline itemAtRow: index + 1] representedObject];
    
    NSArray *nodeDates = nil;
    NSArray *nodeBalances = nil;
    NSArray *nodeTurnovers = nil;
    [item categoryHistoryToDates: &nodeDates
                        balances: &nodeBalances
                   balanceCounts: &nodeTurnovers
                    withGrouping: groupingInterval];
    
    if (nodeDates == nil) {
        nodeDates = [NSArray array]; // Just to avoid frequent checks in the loop below.
    }
    // Dates for this category might not correspond to the display range (i.e. no value for all dates)
    // so move the existing values to the appropriate array index and fill the rest with 0.
    NSMutableArray *balanceArray = [NSMutableArray arrayWithCapacity: [dates count]];
    NSUInteger dateIndex = 0;
    for (ShortDate *date in dates) {
        if (dateIndex >= [nodeDates count] || [date compare: [nodeDates objectAtIndex: dateIndex]] == NSOrderedAscending) {
            [balanceArray addObject: [NSDecimalNumber zero]];
        } else {
            [balanceArray addObject: [nodeBalances objectAtIndex: dateIndex]];
            dateIndex++;
        }
    }
    
    [balances replaceObjectAtIndex: index withObject: balanceArray];
}

- (void)showStatementList: (NSRect)cellBounds
{
    if (detailsPopupWindow == nil) {
        NSPoint targetPoint = NSMakePoint(NSMidX(cellBounds),
                                          NSMidY(cellBounds));
        targetPoint = [valueGrid convertPoint: targetPoint toView: nil];
        detailsPopupWindow = [[MAAttachedWindow alloc] initWithView: statementDetailsView 
                                                    attachedToPoint: targetPoint 
                                                           inWindow: [valueGrid window] 
                                                             onSide: MAPositionAutomatic 
                                                         atDistance: 11];
        
        [detailsPopupWindow setBackgroundColor: [NSColor colorWithCalibratedWhite: 1 alpha: 0.8]];
        [detailsPopupWindow setViewMargin: 1];
        [detailsPopupWindow setBorderWidth: 1];
        [detailsPopupWindow setBorderColor: [NSColor colorWithCalibratedWhite: 0 alpha: 0.3]];
        [detailsPopupWindow setCornerRadius: 10];
        [detailsPopupWindow setHasArrow: YES];
        [detailsPopupWindow setDrawsRoundCornerBesideArrow: YES];
        
        [self updateStatementList: cellBounds];
        
        [detailsPopupWindow setAlphaValue: 0];
        [[valueGrid window] addChildWindow: detailsPopupWindow ordered: NSWindowAbove];
        [detailsPopupWindow fadeIn];
    }
}

- (void)updateStatementList: (NSRect)cellBounds
{
    if (detailsPopupWindow != nil) {
        NSInteger columnIndex = valueGrid.selectedColumnIndexes.firstIndex;
        ShortDate *selFromDate = [dates objectAtIndex: columnIndex + fromIndex];
        ShortDate *selToDate;
        switch (groupingInterval) {
            case GroupByYears:
                selToDate = [selFromDate lastDayInYear];
                break;
            case GroupByQuarters:
                selToDate = [selFromDate lastDayInQuarter];
                break;
            default:
                selToDate = [selFromDate lastDayInMonth];
                break;
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"category IN %@ AND statement.date >= %@ AND statement.date <= %@",
                                  [self.category allCategories], [selFromDate lowDate], [selToDate highDate]];
        [statementsController setFetchPredicate: predicate];
        [statementsController prepareContent];	

        NSPoint targetPoint = NSMakePoint(NSMidX(cellBounds),
                                          NSMidY(cellBounds));
        targetPoint = [valueGrid convertPoint: targetPoint toView: nil];
        [detailsPopupWindow setPoint: targetPoint side: MAPositionAutomatic];
    }    
}

- (void)releaseStatementList
{
    [[valueGrid window] removeChildWindow: detailsPopupWindow];
    [detailsPopupWindow orderOut: self];
    detailsPopupWindow = nil;
    fadeInProgress = NO;
}

- (void)hideStatementList
{
    if (detailsPopupWindow != nil && !fadeInProgress) {
        fadeInProgress = YES;
        [detailsPopupWindow fadeOut];
        
        // We need to delay the release of the help window
        // otherwise it will just disappear instead to fade out.
        // With 10.7 and completion handlers it would be way more elegant.
        [NSTimer scheduledTimerWithTimeInterval: 0.5
                                         target: self 
                                       selector: @selector(releaseStatementList)
                                       userInfo: nil
                                        repeats: NO];
    }
}

- (void)updateLimitLabel: (NSTextField *)field index: (NSUInteger) index
{
    if (dates.count == 0) {
        field.stringValue = @"--";
    } else {
        ShortDate* date = [dates objectAtIndex: index];
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
    NSImage *sortImage = sortAscending ? [NSImage imageNamed: @"sort-indicator-inc"] : [NSImage imageNamed: @"sort-indicator-dec"];
    [sortControl setImage: sortImage forSegment: sortIndex];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *values = [[userDefaults objectForKey: @"categoryPeriods"] mutableCopy];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 2];
    }
    [values setValue: [NSNumber numberWithInt: sortIndex] forKey: @"sortIndex"];
    [values setValue: [NSNumber numberWithBool: sortAscending] forKey: @"sortAscending"];
    [userDefaults setObject: values forKey: @"categoryPeriods"];
    
    NSString *key;
    switch (sortIndex) {
        case 1:
            statementsListView.showHeaders = false;
            key = @"statement.remoteName";
            break;
        case 2:
            statementsListView.showHeaders = false;
            key = @"statement.purpose";
            break;
        case 3:
            statementsListView.showHeaders = false;
            key = @"statement.categoriesDescription";
            break;
        case 4:
            statementsListView.showHeaders = false;
            key = @"statement.value";
            break;
        default:
            statementsListView.showHeaders = true;
            key = @"statement.valutaDate";
            break;
    }
    [statementsController setSortDescriptors:
     [NSArray arrayWithObject: [[NSSortDescriptor alloc] initWithKey: key ascending: sortAscending]]];
}

- (void)updateOutline
{
    if ([dates count] == 0) {
        return;
    }
     
    ShortDate *fromDate = [dates objectAtIndex:fromIndex];
    ShortDate *toDate = [dates objectAtIndex:toIndex];
    
    switch (groupingInterval) {
        case GroupByMonths:
            toDate = [toDate lastDayInMonth];
            break;
        case GroupByQuarters:
            toDate = [toDate lastDayInQuarter];
            break;
        case GroupByYears:
            toDate = [toDate lastDayInYear];
            break;
        default:
            break;
    }
    
    [Category setCatReportFrom:fromDate to:toDate];
}

#pragma mark -
#pragma mark Interface Builder Actions

- (IBAction)setGrouping: (id)sender
{
    [self hideStatementList];
    
    groupingInterval = [sender intValue];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* values = [[userDefaults objectForKey: @"categoryPeriods"] mutableCopy];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 1];
    }
    [values setValue: [NSNumber numberWithInt: groupingInterval] forKey: @"grouping"];
    [userDefaults setObject: values forKey: @"categoryPeriods"];
    
    [self updateData];
}

- (IBAction)fromChanged: (id)sender
{
    [self hideStatementList];
    
    NSUInteger fromPosition = [sender intValue];
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

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* values = [[userDefaults objectForKey: @"categoryPeriods"] mutableCopy];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 1];
    }
    [values setValue: [NSNumber numberWithInt: fromIndex] forKey: @"fromIndex"];
    [userDefaults setObject: values forKey: @"categoryPeriods"];
    
    [self updateOutline];
    [valueGrid reloadData];
}

- (IBAction)toChanged: (id)sender
{
    [self hideStatementList];
    
    NSUInteger toPosition = [sender intValue];
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
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* values = [[userDefaults objectForKey: @"categoryPeriods"] mutableCopy];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 1];
    }
    [values setValue: [NSNumber numberWithInt: toIndex] forKey: @"toIndex"];
    [userDefaults setObject: values forKey: @"categoryPeriods"];
    
    [self updateOutline];
    [valueGrid reloadData];
}

- (IBAction)filterStatements: (id)sender
{
    NSTextField	*field = sender;
    NSString *text = [field stringValue];
    
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

@synthesize category;

-(NSView*)mainView
{
    return mainView;
}

- (void)activate
{
    active = YES;
    
    // Reload the grid data, but not before the current run loop ended. Otherwise we end
    // up with a wrong number of rows (predicate changes in the tree controller are applied to the
    // outline not before the end of the current run loop.
    [self performSelector: @selector(updateData) withObject: nil afterDelay: 0.25];
}

- (void)deactivate
{
    [self hideStatementList];
    active = NO;
}

- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to
{
}

@end



