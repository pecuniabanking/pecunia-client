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
#import "MAAttachedWindow.h"

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
        histType = cat_histtype_month;
        dates = [[NSMutableArray array] retain];
        balances = [[NSMutableArray array] retain];
        turnovers = [[NSMutableArray array] retain];
        selectedDates = [[NSMutableArray array] retain];
        managedObjectContext = [[[MOAssistant assistant] context] retain];
    }
    
    return self;
}

- (void)dealloc
{
    self.outline = nil; // Will remove self from default notification center.
    
    [dates release];
    [balances release];
    [turnovers release];
    
    [categoryHistory release], categoryHistory = nil;
    [selectedDates release], selectedDates = nil;
    [fromDate release], fromDate = nil;
    [toDate release], toDate = nil;
    [dataRoot release ], dataRoot = nil;
    [periodRoot release ], periodRoot = nil;
    [minDate release], minDate = nil;
    [maxDate release], maxDate = nil;
    [managedObjectContext release], managedObjectContext = nil;
    
    [super dealloc];
}

-(void)awakeFromNib
{	
    NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey: @"self" ascending: NO] autorelease];
    NSArray          *sds = [NSArray arrayWithObject: sd];
    [catPeriodDatesController setSortDescriptors: sds];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *values = [userDefaults objectForKey: @"categoryPeriods"];
    if (values) {
        if ([values objectForKey: @"type" ]) {
            histType = (CatHistoryType)[[values objectForKey: @"type" ] intValue];
        }
        if ([values objectForKey: @"fromDate" ]) {
            fromDate = [ShortDate dateWithDate: [values objectForKey: @"fromDate" ]];
        }
        if ([values objectForKey: @"toDate" ]) {
            toDate = [ShortDate dateWithDate: [values objectForKey: @"toDate" ]];
        }
        groupingInterval = [[values objectForKey: @"grouping"] intValue];
        groupingSlider.intValue = groupingInterval;
    }
    
    if (fromDate == nil) {
        fromDate = [[[ShortDate currentDate] firstDayInYear] retain];
    }
    if (toDate == nil) {
        toDate = [[[ShortDate currentDate] firstDayInMonth] retain];
    }

    valueGrid.defaultCellSize = NSMakeSize(100, 20);
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
    [statementsListView bind: @"valueArray" toObject: statementsController withKeyPath: @"arrangedObjects.value" options: nil];
    
    // Bind controller to selectedRow property and the listview to the controller's selectedIndex property to get notified about selection changes.
    [statementsController bind: @"selectionIndexes" toObject: statementsListView withKeyPath: @"selectedRows" options: nil];
    [statementsListView bind: @"selectedRows" toObject: statementsController withKeyPath: @"selectionIndexes" options: nil];
    
    [statementsListView setCellSpacing: 0];
    [statementsListView setAllowsEmptySelection: YES];
    [statementsListView setAllowsMultipleSelection: YES];
    formatter = [statementsListView numberFormatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
}

#pragma mark -
#pragma mark Properties

-(void)updatePeriodDates
{
    [dates removeAllObjects];
    ShortDate *refDate = [self periodRefDateForDate: minDate];
    
    while ([refDate compare: maxDate ] != NSOrderedDescending) {
        [dates addObject: refDate];
        switch (histType) {
            case cat_histtype_year:
                refDate = [refDate dateByAddingUnits: 1 byUnit: NSYearCalendarUnit];
                break;
            case cat_histtype_quarter:
                refDate = [refDate dateByAddingUnits: 3 byUnit: NSMonthCalendarUnit];
                break;
            default:
                refDate = [refDate dateByAddingUnits: 1 byUnit: NSMonthCalendarUnit];
                break;
        }
    } //while
    
    [catPeriodDatesController setContent: dates];
    [catPeriodDatesController rearrangeObjects];
}

-(NSString*)keyForDate: (ShortDate*)date
{
    return [NSString stringWithFormat: @"%d%d%d", date.year, date.month, date.day]; 
}

-(ShortDate*)periodRefDateForDate: (ShortDate*)date
{
    switch (histType) {
        case cat_histtype_year: return [date firstDayInYear];
        case cat_histtype_quarter: return [date firstDayInQuarter];
        default: return date;
    }
}

#pragma mark -
#pragma mark MBTableGrid Delegate Methods

- (NSUInteger)numberOfRowsInTableGrid: (MBTableGrid*)aTableGrid
{
	return outline.numberOfRows - 1; // Leave out the top category node.
}

- (NSUInteger)numberOfColumnsInTableGrid: (MBTableGrid *)aTableGrid
{
	return [dates count];
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
	return ([rowValues count] > columnIndex) ? [rowValues objectAtIndex: columnIndex] : @"";
}

- (void)tableGrid: (MBTableGrid *)aTableGrid setObjectValue: (id)anObject forColumn: (NSUInteger)columnIndex row: (NSUInteger)rowIndex
{
    // Only needed to have the grid call us for editing.
}

- (NSString *) tableGrid: (MBTableGrid*)aTableGrid headerStringForColumn: (NSUInteger)columnIndex
{
    ShortDate* date = [dates objectAtIndex: columnIndex];
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

-(void)updatePeriodDataForNode: (CategoryReportingNode*)node
{
    for(CategoryReportingNode *child in node.children) {
        [self updatePeriodDataForNode: child];
    }
    
    NSArray *keys = [node.values allKeys];
    
    [node.periodValues removeAllObjects]; 
    for(ShortDate *date in keys) {
        ShortDate *refDate = [self periodRefDateForDate: date];
        
        // add up values
        if ([refDate compare: fromDate ] != NSOrderedAscending && [refDate compare: toDate ] != NSOrderedDescending) {
            NSDecimalNumber *num = [node.periodValues objectForKey: [self keyForDate: refDate ]];
            if (num) {
                num = [num decimalNumberByAdding: [node.values objectForKey: date ]];
            } else {
                num = [node.values objectForKey: date];
            }
            [node.periodValues setObject: num forKey: [self keyForDate: refDate ]];
        }
        
        // check that there is an entry for each date
        refDate = fromDate;
        while ([refDate compare: toDate ] != NSOrderedDescending) {
            NSDecimalNumber *num = [node.periodValues objectForKey: [self keyForDate: refDate ]];
            if (num == nil) {
                [node.periodValues setObject: [NSDecimalNumber zero ] forKey: [self keyForDate: refDate ]];
            }
            switch (histType) {
                case cat_histtype_year:
                    refDate = [refDate dateByAddingUnits: 1 byUnit: NSYearCalendarUnit];
                    break;
                case cat_histtype_quarter:
                    refDate = [refDate dateByAddingUnits: 3 byUnit: NSMonthCalendarUnit];
                    break;
                default:
                    refDate = [refDate dateByAddingUnits: 1 byUnit: NSMonthCalendarUnit];
                    break;
            }
        } //while
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
        [[[outline itemAtRow: 0] representedObject] getDatesMin: &minDate max: &maxDate];
        switch (groupingInterval) {
            case GroupByYears:
                minDate = [minDate firstDayInYear];
                maxDate = [maxDate firstDayInYear];
                break;
            case GroupByQuarters:
                minDate = [minDate firstDayInQuarter];
                maxDate = [maxDate firstDayInQuarter];
                break;
            default:
                minDate = [minDate firstDayInMonth];
                maxDate = [maxDate firstDayInMonth];
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
    
    // Remaining data is loaded on demand.
    
    [valueGrid reloadData];
    [valueGrid setNeedsDisplay: YES];
}

-(void)adjustDates
{
    if ([dates count ] == 0) return;
    ShortDate *firstDate = [dates objectAtIndex: 0];
    ShortDate *lastDate = [dates lastObject];
    ShortDate *refFromDate;
    ShortDate *refToDate;
    
    switch (histType) {
        case cat_histtype_year:
            refFromDate = [fromDate firstDayInYear];
            refToDate = [toDate firstDayInYear];
            break;
        case cat_histtype_quarter:
            refFromDate = [fromDate firstDayInQuarter];
            refToDate = [toDate firstDayInQuarter];
            break;
        default:
            refFromDate = fromDate;
            refToDate = toDate;
            break;
    }
    
    if ([fromDate compare: firstDate ] == NSOrderedAscending || [fromDate compare: lastDate ] == NSOrderedDescending) {
        fromDate = firstDate;
        [fromButton selectItemAtIndex: [dates count ] - 1];
    } else {
        int idx = [dates count ] - 1;
        for(ShortDate *date in dates) {
            if ([date isEqual: refFromDate ]) {
                [fromButton selectItemAtIndex: idx];
            } else idx--;
        }
    }
    
    if ([toDate compare: lastDate ] == NSOrderedDescending || [toDate compare: firstDate ] == NSOrderedAscending) {
        toDate = lastDate;
        [toButton selectItemAtIndex: 0];
    } else {
        int idx = [dates count ] - 1;
        for(ShortDate *date in dates) {
            if ([date isEqual: refToDate ]) {
                [toButton selectItemAtIndex: idx];
            } else idx--;
        }
    }
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
        
        [detailsPopupWindow setBackgroundColor: [NSColor colorWithCalibratedWhite: 1 alpha: 0.95]];
        [detailsPopupWindow setViewMargin: 0];
        [detailsPopupWindow setBorderWidth: 0];
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
        ShortDate *selFromDate = [dates objectAtIndex: columnIndex];
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
                                  [self.category allChildren], [selFromDate lowDate], [selToDate highDate]];
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
    [detailsPopupWindow release];
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


#pragma mark -
#pragma mark Interface Builder Actions

- (IBAction)setGrouping: (id)sender
{
    groupingInterval = [sender intValue];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* values = [userDefaults objectForKey: @"categoryPeriods"];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 1];
        [userDefaults setObject: values forKey: @"categoryPeriods"];
    }
    [values setValue: [NSNumber numberWithInt: groupingInterval] forKey: @"grouping"];
    
    [self updateData];
}

-(IBAction)fromButtonPressed: (id)sender
{
    int idx_from = [fromButton indexOfSelectedItem];
    int idx_to = [toButton indexOfSelectedItem];
    if (idx_from >=0 ) {
        fromDate = [[catPeriodDatesController arrangedObjects ] objectAtIndex: idx_from];
    }
    if (idx_from < idx_to) {
        [toButton selectItemAtIndex: idx_from];
        toDate = fromDate;
    }
    [self updateData];
}

-(IBAction)toButtonPressed: (id)sender
{
    int idx_from = [fromButton indexOfSelectedItem];
    int idx_to = [toButton indexOfSelectedItem];
    if (idx_to >=0 ) {
        toDate = [[catPeriodDatesController arrangedObjects ] objectAtIndex: idx_to];
    }
    if (idx_from < idx_to) {
        [fromButton selectItemAtIndex: idx_to];
        fromDate = toDate;
    }
    [self updateData];
}

- (IBAction)filterStatements: (id)sender
{
    NSTextField	*field = sender;
    NSString *text = [field stringValue];
    
    if ([text length] == 0) {
        [statementsController setFilterPredicate: nil];
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or userInfo contains[c] %@ or value = %@",
                                  text, text, text, [NSDecimalNumber decimalNumberWithString: text locale: [NSLocale currentLocale]]];
        if (predicate != nil) {
            [statementsController setFilterPredicate: predicate];
        }
    }
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



