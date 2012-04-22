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

#import "TransfersListview.h"
#import "TransfersListViewCell.h"
#import "ShortDate.h"
#import "BankStatement.h"

@implementation TransfersListView

@synthesize owner;
@synthesize numberFormatter;
@synthesize dataSource;
@synthesize valueArray;

+ (void)initialize
{
    [self exposeBinding: @"dataSource"];
    [self exposeBinding: @"valueArray"];
}

- (id)initWithFrame:(NSRect)theFrame
{
    self = [super initWithFrame: theFrame];
    if (self != nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale: [NSLocale currentLocale]];
        [dateFormatter setDateStyle: kCFDateFormatterFullStyle];
        [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
        
        numberFormatter = [[NSNumberFormatter alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    if (self != nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale: [NSLocale currentLocale]];
        [dateFormatter setDateStyle: kCFDateFormatterFullStyle];
        [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
        
        numberFormatter = [[NSNumberFormatter alloc] init];
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
    [dataSource release];
    [valueArray release];
    [dateFormatter release];
    [calendar release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Bindings, KVO and KVC

- (void)setDataSource: (NSArray*)array
{
    if (dataSource != array)
    {
        [dataSource release];
        dataSource = [array retain];
        
        [self reloadData];
    }
}

/**
 * The value array is part of the data source we have but we cannot listen directly to changes
 * in the data source, so we use the value array as proxy.
 */
- (void)setValueArray: (NSArray*)array
{
    [valueArray release];
    valueArray = [array retain];
    [self reloadData];
}

#pragma mark -
#pragma mark PXListViewDelegate protocoll implementation

- (NSUInteger)numberOfRowsInListView: (PXListView*)aListView
{
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
            value = [dateFormatter stringFromDate: value];
        if (capitalize)
            value = [value capitalizedString];
    }
    
    return value;
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

#define CELL_HEIGHT 49

- (void) fillCell: (TransfersListViewCell*)cell forRow: (NSUInteger)row
{
    id statement = [[dataSource objectAtIndex: row] valueForKey: @"statement"];
    
    NSDate* currentDate = [statement valueForKey: @"date"];
    
    [cell setDetailsDate: [self formatValue: currentDate capitalize: NO]
              remoteName: [self formatValue: [statement valueForKey: @"remoteName"] capitalize: YES]
                 purpose: [self formatValue: [statement valueForKey: @"floatingPurpose"] capitalize: YES]
                   value: [statement valueForKey: @"value"]
                currency: [self formatValue: [statement valueForKey: @"currency"] capitalize: NO]
     ];
    
    NSRect frame = [cell frame];
    frame.size.height = CELL_HEIGHT;
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
	TransfersListViewCell* cell = (TransfersListViewCell*)[aListView dequeueCellWithReusableIdentifier: @"transfer-cell"];
	
	if (!cell) {
		cell = [TransfersListViewCell cellLoadedFromNibNamed: @"TransfersListViewCell" reusableIdentifier: @"transfer-cell"];
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

/**
 * Used to set all values for the current cells again, for changes not covered by KVO.
 */
- (void)updateSelectedCells
{
    NSIndexSet* selection = [self selectedRows];
    NSUInteger index = [selection firstIndex];
    while (index != NSNotFound) {
        TransfersListViewCell *cell = (id)[self cellForRowAtIndex: index];
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
        TransfersListViewCell *cell = (id)[self cellForRowAtIndex: index];
        
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

@end
