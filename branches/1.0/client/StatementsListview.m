//
//  StatementsListview.m
//  Pecunia
//
//  Created by Mike on 01.10.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "StatementsListview.h"
#import "StatementsListViewCell.h"

@implementation StatementsListView

+ (void)initialize
{
    [self exposeBinding: @"dataSource"];
    [self exposeBinding: @"valueArray"];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setDelegate: self];
    
    _dateFormatter = [[[NSDateFormatter alloc] init] retain];
    [_dateFormatter setLocale: [NSLocale currentLocale]];
    [_dateFormatter setDateStyle: kCFDateFormatterFullStyle];
    [_dateFormatter setTimeStyle: NSDateFormatterNoStyle];
}

- (void) dealloc
{
    [_dataSource release];
    [_dateFormatter release];
    [_numberFormatter release];
    [_calendar release];
    
    [super dealloc];
}

- (NSNumberFormatter*)numberFormatter
{
    // Cannot place this in awakeFromLib as it accessed by other awakeFromNib methods and might not
    // be ready yet by then.
    if (_numberFormatter == nil)
        _numberFormatter = [[[NSNumberFormatter alloc] init] retain];
    return _numberFormatter;
}

#pragma mark -
#pragma mark Bindings, KVO and KVC

- (NSArray*)dataSource
{
	return _dataSource;
}

- (void)setDataSource: (NSArray*)array
{
    if (_dataSource != array)
    {
        [_dataSource release];
        _dataSource = [array retain];
        
        [self reloadData];
    }
}

/**
 * The value array is part of the data source we have but we cannot listen directly to changes
 * in the data source, so we use the value array as proxy.
 */
- (NSArray*)valueArray
{
    return _valueArray;
}

- (void)setValueArray: (NSArray*)array
{
    [_valueArray release];
    _valueArray = [array retain];
    [self reloadData];
}

#pragma mark -
#pragma mark PXListViewDelegate protocoll implementation

- (NSUInteger)numberOfRowsInListView: (PXListView*)aListView
{
#pragma unused(aListView)
	return [_dataSource count];
}

- (id) formatValue: (id)value capitalize: (BOOL) capitalize
{
    if (value == nil || [value isKindOfClass: [NSNull class]])
        value = @"";
    else
    {
        if ([value isKindOfClass: [NSDate class]])
            value = [_dateFormatter stringFromDate: value];
        if (capitalize)
            value = [value capitalizedString];
    }
    
    return value;
}

/**
 * Taken from Cocoa help. Computes number of days between two dates.
 */
- (NSInteger)daysWithinEraFromDate: (NSDate*) startDate toDate: (NSDate*) endDate
{
    if (_calendar == nil)
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    
    NSUInteger startDay = [_calendar ordinalityOfUnit: NSDayCalendarUnit
                                               inUnit: NSEraCalendarUnit forDate: startDate];
    NSUInteger endDay = [_calendar ordinalityOfUnit: NSDayCalendarUnit
                                             inUnit: NSEraCalendarUnit forDate: endDate];
    
    return endDay - startDay;
}

- (BOOL)showsHeaderForRow: (NSUInteger)row
{
    BOOL result = (row == 0);
    if (!result)
    {
        id statement = [[_dataSource objectAtIndex: row] valueForKey: @"statement"];
        id previousStatement = [[_dataSource objectAtIndex: row - 1] valueForKey: @"statement"];
        result = [self daysWithinEraFromDate: [statement valueForKey: @"date"]
                                      toDate: [previousStatement valueForKey: @"date"]] != 0;
    }
    return result;
}

/**
 * Looks through the statement array starting with "row" and counts how many entries follow it with the 
 * same date (time is not compared).
 */
- (int) countSameDatesFromRow: (NSUInteger)row
{
    if (_calendar == nil)
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    
    int result = 1;
    id statement = [[_dataSource objectAtIndex: row] valueForKey: @"statement"];
    NSDate* currentDate = [statement valueForKey: @"date"];
    
    NSUInteger startDay = [_calendar ordinalityOfUnit: NSDayCalendarUnit
                                               inUnit: NSEraCalendarUnit forDate: currentDate];
    int totalCount = [_dataSource count];
    while (++row < totalCount)
    {
        id statement = [[_dataSource objectAtIndex: row] valueForKey: @"statement"];
        NSDate* nextDate = [statement valueForKey: @"date"];
        NSUInteger endDay = [_calendar ordinalityOfUnit: NSDayCalendarUnit
                                                 inUnit: NSEraCalendarUnit forDate: nextDate];
        if (startDay != endDay)
            break;
        result++;
    }
    return result;
}

#define CELL_BODY_HEIGHT 49
#define CELL_HEADER_HEIGHT 20

- (void) fillCell: (StatementsListViewCell*)cell forRow: (NSUInteger)row
{
    id statement = [[_dataSource objectAtIndex: row] valueForKey: @"statement"];
    
    NSDate* currentDate = [statement valueForKey: @"date"];
    
    // Count how many statements have been booked for the current date.
    int turnovers = [self countSameDatesFromRow: row];
    NSString* turnoversString;
    if (turnovers != 1)
        turnoversString = [NSString stringWithFormat: NSLocalizedString(@"AP133", @"%u turnovers"), turnovers];
    else
        turnoversString = NSLocalizedString(@"AP132", @"1 turnover");
    
    [cell setDetailsDate: [self formatValue: currentDate capitalize: NO]
               turnovers: turnoversString
              remoteName: [self formatValue: [statement valueForKey: @"remoteName"] capitalize: YES]
                 purpose: [self formatValue: [statement valueForKey: @"floatingPurpose"] capitalize: YES]
              categories: [self formatValue: [statement valueForKey: @"categoriesDescription"] capitalize: NO]
                   value: [[_dataSource objectAtIndex: row] valueForKey: @"value"]
                   saldo: [statement valueForKey: @"saldo"]
                currency: [self formatValue: [statement valueForKey: @"currency"] capitalize: NO]
         transactionText: [self formatValue: [statement valueForKey: @"transactionText"] capitalize: YES]
     ];
    [cell setIsNew: [[statement valueForKey: @"isNew"] boolValue]];
    
    NSDecimalNumber* nassValue = [statement valueForKey: @"nassValue"];
    [cell setHasNotAssignedValue:  [nassValue compare: [NSDecimalNumber zero]] != NSOrderedSame];
    
    // Set the size of the cell, depending on if we show its header or not.
    NSRect frame = [cell frame];
    frame.size.height = CELL_BODY_HEIGHT;
    if ([self showsHeaderForRow: row])
    {
        frame.size.height += CELL_HEADER_HEIGHT;
        [cell setHeaderHeight: CELL_HEADER_HEIGHT];
    }
    else
    {
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
	
	if (!cell)
    {
		cell = [StatementsListViewCell cellLoadedFromNibNamed: @"StatementsListViewCell" reusableIdentifier: @"statcell"];
	}
	
    [self fillCell: cell forRow: row];
    
    return cell;
}

- (CGFloat)listView: (PXListView*)aListView heightOfRow: (NSUInteger)row forDragging: (BOOL)forDragging
{
    if (!forDragging && [self showsHeaderForRow: row])
        return CELL_BODY_HEIGHT + CELL_HEADER_HEIGHT;
    return CELL_BODY_HEIGHT;
}

- (void)listViewSelectionDidChange:(NSNotification*)aNotification
{
    // A selected statement automatically loses the "new" state.
    id cell = [self cellForRowAtIndex: [self selectedRow]];
    [cell setIsNew: NO];
}

/**
 * Used to set all values for the current cell again, for changes not covered by KVO.
 */
- (void)updateSelectedCell
{
    NSUInteger row = [self selectedRow];
    if (row == NSNotFound)
        return;
    
    StatementsListViewCell* cell = (StatementsListViewCell*)[self cellForRowAtIndex: row];
    [self fillCell: cell forRow: row];
}

#pragma mark -
#pragma mark Drag'n drop

// TODO: Taken from BankinController.mm. Might be better to move them to a central location.
#define BankStatementDataType	@"BankStatementDataType"

- (BOOL)listView: (PXListView*)aListView writeRowsWithIndexes: (NSIndexSet*)rowIndexes toPasteboard: (NSPasteboard*)dragPasteboard
{
    unsigned int idx;
    //StatCatAssignment	*stat;
    id stat;
    
    // Copy the row numbers to the pasteboard.
    [rowIndexes getIndexes: &idx maxCount: 1 inIndexRange: nil];
    stat = [_dataSource objectAtIndex: idx];
    NSURL *uri = [[stat objectID] URIRepresentation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uri];
    [dragPasteboard declareTypes: [NSArray arrayWithObject: BankStatementDataType] owner: self];
    [dragPasteboard setData:data forType: BankStatementDataType];
    /*
     if ([[self currentSelection ] isBankAccount ])
     [aListView setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove | NSDragOperationGeneric forLocal: YES];
     else
     [aListView setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove forLocal: YES];
     [aListView setDraggingSourceOperationMask: NSDragOperationDelete forLocal: NO];
     */
    return YES;
}

- (NSDragOperation)listView: (PXListView*)aListView validateDrop: (id <NSDraggingInfo>)info proposedRow: (NSUInteger)row
      proposedDropHighlight: (PXListViewDropHighlight)dropHighlight;
{
	return NSDragOperationCopy;
}

@end
