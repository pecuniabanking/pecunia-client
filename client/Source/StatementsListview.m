//
//  StatementsListview.m
//  Pecunia
//
//  Created by Mike on 01.10.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "StatementsListview.h"
#import "StatementsListViewCell.h"
#import "StatCatAssignment.h"
#import "ShortDate.h"
#import "BankStatement.h"

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

- (id)formatValue: (id)value capitalize: (BOOL)capitalize
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

- (BOOL)showsHeaderForRow: (NSUInteger)row
{
    BOOL result = (row == 0);
    if (!result)
    {
        BankStatement *statement = (BankStatement*)[[_dataSource objectAtIndex: row] valueForKey: @"statement"];
        BankStatement *previousStatement = (BankStatement*)[[_dataSource objectAtIndex: row - 1] valueForKey: @"statement"];
        
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
    id statement = [[_dataSource objectAtIndex: row] valueForKey: @"statement"];
    ShortDate* currentDate = [ShortDate dateWithDate: [statement valueForKey: @"date"]];
    
    int totalCount = [_dataSource count];
    while (++row < totalCount)
    {
        statement = [[_dataSource objectAtIndex: row] valueForKey: @"statement"];
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
    id statement = [[_dataSource objectAtIndex: row] valueForKey: @"statement"];
    
    NSDate* currentDate = [statement valueForKey: @"date"];
    
    // Count how many statements have been booked for the current date.
    int turnovers = [self countSameDatesFromRow: row];
    NSString* turnoversString;
    if (turnovers != 1)
        turnoversString = [NSString stringWithFormat: NSLocalizedString(@"AP133", @""), turnovers];
    else
        turnoversString = NSLocalizedString(@"AP132", @"");
    
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

- (NSRange)listView: (PXListView*)aListView rangeOfDraggedRow: (NSUInteger)row
{
    if ([self showsHeaderForRow: row])
        return NSMakeRange(CELL_HEADER_HEIGHT, CELL_BODY_HEIGHT);
    return NSMakeRange(0, CELL_BODY_HEIGHT);    
}

- (void)listViewSelectionDidChange:(NSNotification*)aNotification
{
    // A selected statement automatically loses the "new" state.
    NSIndexSet* selection = [self selectedRows];
    NSUInteger index = [selection firstIndex];
    while (index != NSNotFound) {
        StatementsListViewCell *cell = (id)[self cellForRowAtIndex: index];
        [cell setIsNew: NO];
        index = [selection indexGreaterThanIndex: index];
    }
}

/**
 * Used to set all values for the current cells again, for changes not covered by KVO.
 */
- (void)updateSelectedCells
{
    NSIndexSet* selection = [self selectedRows];
    NSUInteger index = [selection firstIndex];
    while (index != NSNotFound) {
        StatementsListViewCell *cell = (id)[self cellForRowAtIndex: index];
        [self fillCell: cell forRow: index];
        index = [selection indexGreaterThanIndex: index];
    }
}

/**
 * Used to set all values for the those cells that were dragged previously, for changes not covered by KVO.
 */
- (void)updateDraggedCells
{
    if (draggedIndexes == nil)
        return;
    
    NSUInteger index = [draggedIndexes firstIndex];
    while (index != NSNotFound) {
        StatementsListViewCell *cell = (id)[self cellForRowAtIndex: index];
        
        // The cell can actually have been removed
        if (cell != nil)
            [self fillCell: cell forRow: index];
        index = [draggedIndexes indexGreaterThanIndex: index];
    }
    
    [draggedIndexes release];
    draggedIndexes = nil;
}

#pragma mark -
#pragma mark Drag'n drop

// TODO: Taken from BankinController.mm. Might be better to move them to a central location.
#define BankStatementDataType	@"BankStatementDataType"

- (BOOL)listView: (PXListView*)aListView writeRowsWithIndexes: (NSIndexSet*)rowIndexes toPasteboard: (NSPasteboard*)dragPasteboard
{
    // Keep a copy of the selected indexes as the selection is removed during the drag operation,
    // but we need to update the selected cells then.
    draggedIndexes = [rowIndexes copy];
    
    unsigned int indexes[30], count, i;
	NSRange range;
	StatCatAssignment* stat;
	NSMutableArray* uris = [NSMutableArray arrayWithCapacity: 30];
    
    range.location = 0;
	range.length = 100000;
    
    // Copy the row numbers to the pasteboard.
    do {
		count = [rowIndexes getIndexes: indexes maxCount: 30 inIndexRange: &range];
		for (i = 0; i < count; i++) {
			stat = [_dataSource objectAtIndex: indexes[i]];
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

@end
