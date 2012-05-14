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
#import "Category.h"

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

- (id)initWithCoder: (NSCoder*)decoder
{
    self = [super initWithCoder: decoder];
    if (self != nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale: [NSLocale currentLocale]];
        [dateFormatter setDateStyle: kCFDateFormatterShortStyle];
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
    [numberFormatter release];
    
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

- (id)formatValue: (id)value
{
    if (value == nil || [value isKindOfClass: [NSNull class]])
        value = @"";
    else
    {
        if ([value isKindOfClass: [NSDate class]]) {
            value = [dateFormatter stringFromDate: value];
        }
    }
    
    return value;
}

#define CELL_HEIGHT 49

- (void) fillCell: (TransfersListViewCell*)cell forRow: (NSUInteger)row
{
    id transfer = [dataSource objectAtIndex: row];
    
    NSDate* currentDate = [transfer valueForKey: @"date"];
    NSMutableDictionary *details = [NSMutableDictionary dictionary];
    [details setValue: [self formatValue: currentDate] forKey: @"date"];
    [details setValue: [self formatValue: [transfer valueForKey: @"remoteName"]] forKey: @"remoteName"];
    [details setValue: [self formatValue: [transfer valueForKey: @"purpose"]] forKey: @"purpose"];
    [details setValue: [transfer valueForKey: @"value"] forKey: @"value"];
    [details setValue: [self formatValue: [transfer valueForKey: @"currency"]] forKey: @"currency"];
    [details setValue: [self formatValue: [transfer valueForKey: @"remoteBankName"]] forKey: @"remoteBankName"];
    
    // Construct a formatted string for account and bank code to be displayed in a single text field.
    NSFont *normalFont = [NSFont fontWithName: @"Helvetica Neue" size: 11];
    NSDictionary *normalAttributes = [NSDictionary dictionaryWithObjectsAndKeys: normalFont, NSFontAttributeName,
                                      [NSColor grayColor], NSForegroundColorAttributeName, nil];
    
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *boldFont = [fontManager convertFont: normalFont toHaveTrait: NSBoldFontMask];
    NSDictionary *boldAttributes = [NSDictionary dictionaryWithObject: boldFont forKey: NSFontAttributeName];

    NSMutableAttributedString *accountString = [[[NSMutableAttributedString alloc] initWithString: NSLocalizedString(@"AP180", "")
                                                                                       attributes: normalAttributes] autorelease];
    [accountString appendAttributedString: [[[NSMutableAttributedString alloc] initWithString: [self formatValue: [transfer valueForKey: @"remoteBankCode"]]
                                                                                   attributes: boldAttributes]
                                            autorelease]
    ];
    [accountString appendAttributedString: [[[NSMutableAttributedString alloc] initWithString: NSLocalizedString(@"AP181", "")
                                                                                   attributes: normalAttributes]
                                            autorelease]
    ];
    [accountString appendAttributedString: [[[NSMutableAttributedString alloc] initWithString: [self formatValue: [transfer valueForKey: @"remoteAccount"]]
                                                                                   attributes: boldAttributes]
                                            autorelease]
     ];
    // TODO: add handling for IBAN and BIC.
    [details setValue: accountString forKey: @"account"];
    
    // TODO: add handling for changed category colors.
    [details setValue: [[transfer account] categoryColor] forKey: @"color"];
    
    [cell setDetails: details];
    
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

extern NSString* const BankStatementDataType;

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
