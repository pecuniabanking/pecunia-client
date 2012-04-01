/*
 Copyright (c) 2008 Matthew Ball - http://www.mattballdesign.com
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

#import "MBTableGridHeaderView.h"
#import "MBTableGrid.h"
#import "MBTableGridContentView.h"

@interface MBTableGrid (Private)
- (NSString *)_headerStringForColumn:(NSUInteger)columnIndex;
- (NSString *)_headerStringForRow:(NSUInteger)rowIndex;
- (MBTableGridContentView *)_contentView;
- (void)_dragColumnsWithEvent:(NSEvent *)theEvent;
- (void)_dragRowsWithEvent:(NSEvent *)theEvent;
@end

@implementation MBTableGridHeaderView

@synthesize orientation;
@synthesize headerCell;

- (id)initWithFrame:(NSRect)frameRect
{
	if(self = [super initWithFrame:frameRect]) {
		// Setup the header cell
		headerCell = [[MBTableGridHeaderCell alloc] init];
		
		// We haven't clicked any item
		mouseDownItem = -1;
		
		// Initially, we're not dragging anything
		shouldDragItems = NO;
		isInDrag = NO;
	}
	return self;
}

- (void)dealloc
{
	[headerCell release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	NSColor *topGradientTop = [NSColor colorWithDeviceWhite:0.91 alpha:1.0];
	NSColor *topGradientBottom = [NSColor colorWithDeviceWhite:0.89 alpha:1.0];
	NSColor *bottomGradientTop = [NSColor colorWithDeviceWhite:0.85 alpha:1.0];
	NSColor *bottomGradientBottom = [NSColor colorWithDeviceWhite:0.83 alpha:1.0];	
	
	NSGradient *topGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:topGradientTop, topGradientBottom, nil]];
	NSGradient *bottomGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:bottomGradientTop, bottomGradientBottom, nil]];
	
	if (self.orientation == MBTableHeaderHorizontalOrientation) {
		// Draw the column headers
		NSUInteger numberOfColumns = [[self tableGrid] numberOfColumns];
		[headerCell setOrientation:self.orientation];
		NSUInteger column = 0;
		while (column < numberOfColumns) {
			NSRect headerRect = [self headerRectOfColumn:column];
			
			// Only draw the header if we need to
			if ([self needsToDrawRect:headerRect]) {
				// Check if any part of the selection is in this column
				NSIndexSet *selectedColumns = [[self tableGrid] selectedColumnIndexes];
				if ([selectedColumns containsIndex:column]) {
					[headerCell setState:NSOnState];
				} else {
					[headerCell setState:NSOffState];
				}
				
				[headerCell setStringValue:[[self tableGrid] _headerStringForColumn:column]];
				[headerCell drawWithFrame:headerRect inView:self];
			}
			column++;
		}
	} else if (self.orientation == MBTableHeaderVerticalOrientation) {
		// Draw the row headers
		NSUInteger numberOfRows = [[self tableGrid] numberOfRows];
		[headerCell setOrientation:self.orientation];
		NSUInteger row = 0;
		while(row < numberOfRows) {
			NSRect headerRect = [self headerRectOfRow:row];
			
			// Only draw the header if we need to
			if ([self needsToDrawRect:headerRect]) {
				// Check if any part of the selection is in this column
				NSIndexSet *selectedRows = [[self tableGrid] selectedRowIndexes];
				if ([selectedRows containsIndex:row]) {
					[headerCell setState:NSOnState];
				} else {
					[headerCell setState:NSOffState];
				}
				
				[headerCell setStringValue:[[self tableGrid] _headerStringForRow:row]];
				[headerCell drawWithFrame:headerRect inView:self];
			}
			row++;
		}
	}
	
	[topGradient release];
	[bottomGradient release];
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	// Get the location of the click
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	mouseDownLocation = loc;
	NSInteger column = [[self tableGrid] columnAtPoint:[self convertPoint:loc toView:[self tableGrid]]];
	NSInteger row = [[self tableGrid] rowAtPoint:[self convertPoint:loc toView:[self tableGrid]]];
	
	// For single clicks,
	if ([theEvent clickCount] == 1 && column != NSNotFound && row != NSNotFound) {
		if(([theEvent modifierFlags] & NSShiftKeyMask) && [self tableGrid].allowsMultipleSelection) {
			// If the shift key was held down, extend the selection
		} else {
			// No modifier keys, so change the selection
			if(self.orientation == MBTableHeaderHorizontalOrientation) {
				mouseDownItem = column;
				
				if([[self tableGrid].selectedColumnIndexes containsIndex:column] && [[self tableGrid].selectedRowIndexes count] == [[self tableGrid] numberOfRows]) {
					// Allow the user to drag the column
					shouldDragItems = YES;
				} else {
					[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndex:column];
					// Select every row
					[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[self tableGrid] numberOfRows])];
				}
			} else if(self.orientation == MBTableHeaderVerticalOrientation) {
				mouseDownItem = row;
				
				if([[self tableGrid].selectedRowIndexes containsIndex:row] && [[self tableGrid].selectedColumnIndexes count] == [[self tableGrid] numberOfColumns]) {
					// Allow the user to drag the row
					shouldDragItems = YES;
				} else {
					[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndex:row];
					// Select every column
					[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[self tableGrid] numberOfColumns])];
				}
			}
			
		}
	}
	
	// Pass the event back to the MBTableGrid (Used to give First Responder status)
	[[self tableGrid] mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{	
	// Get the location of the mouse
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	float deltaX = abs(loc.x - mouseDownLocation.x);
	float deltaY = abs(loc.y - mouseDownLocation.y);
	
	// Drag operation doesn't start until the mouse has moved more than 5 points
	float dragThreshold = 5.0;
	
	// If we've met the conditions for a drag operation,
	if (shouldDragItems && mouseDownItem >= 0 && (deltaX >= dragThreshold || deltaY >= dragThreshold)) {
		if (self.orientation == MBTableHeaderHorizontalOrientation) {
			[[self tableGrid] _dragColumnsWithEvent:theEvent];
		} else if (self.orientation == MBTableHeaderVerticalOrientation) {
			[[self tableGrid] _dragRowsWithEvent:theEvent];
		}
		
		// We've responded to the drag, so don't respond again during this drag session
		shouldDragItems = NO;
		
		// Flag that we are currently dragging items
		isInDrag = YES;
	} 
	// Otherwise, extend the selection (if possible)
	else if (mouseDownItem >= 0 && !isInDrag && !shouldDragItems) {
		// Determine which item is under the mouse
		NSInteger itemUnderMouse = -1;
		if (self.orientation == MBTableHeaderHorizontalOrientation) {
			itemUnderMouse = [[self tableGrid] columnAtPoint:[self convertPoint:loc toView:[self tableGrid]]];
		} else if(self.orientation == MBTableHeaderVerticalOrientation) {
			itemUnderMouse = [[self tableGrid] rowAtPoint:[self convertPoint:loc toView:[self tableGrid]]];
		}
		
		// If there's nothing under the mouse, bail out (something went wrong)
		if (itemUnderMouse < 0)
			return;
		
		// Calculate the range of items to select
		NSInteger firstItemToSelect = mouseDownItem;
		NSInteger numberOfItemsToSelect = itemUnderMouse - mouseDownItem + 1;
		if(itemUnderMouse < mouseDownItem) {
			firstItemToSelect = itemUnderMouse;
			numberOfItemsToSelect = mouseDownItem - itemUnderMouse + 1;
		}
		
		// Set the selected items
		if (self.orientation == MBTableHeaderHorizontalOrientation) {
			[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstItemToSelect, numberOfItemsToSelect)];
		} else if (self.orientation == MBTableHeaderVerticalOrientation) {
			[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstItemToSelect, numberOfItemsToSelect)];
		}
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	// If we only clicked on a header that was part of a bigger selection, select it
	if(shouldDragItems && !isInDrag) {
		if (self.orientation == MBTableHeaderHorizontalOrientation) {
			[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndex:mouseDownItem];
			// Select every row
			[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[self tableGrid] numberOfRows])];			
		} else if (self.orientation == MBTableHeaderVerticalOrientation) {
			[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndex:mouseDownItem];
			// Select every column
			[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[self tableGrid] numberOfColumns])];			
		}
	}
	// Reset the pressed item
	mouseDownItem = -1;
	
	// In case it didn't already happen, reset the drag flags
	shouldDragItems = NO;
	isInDrag = NO;
	
	// Reset the location
	mouseDownLocation = NSZeroPoint;
}

#pragma mark -
#pragma mark Subclass Methods

- (MBTableGrid *)tableGrid
{
	return (MBTableGrid *)[[self enclosingScrollView] superview];
}

#pragma mark Layout Support

- (NSRect)headerRectOfColumn:(NSUInteger)columnIndex
{
	NSRect rect = [[[self tableGrid] _contentView] rectOfColumn:columnIndex];
	rect.size.height = MBTableGridColumnHeaderHeight;
	
	return rect;
}

- (NSRect)headerRectOfRow:(NSUInteger)rowIndex
{
	NSRect rect = [[[self tableGrid] _contentView] rectOfRow:rowIndex];
	rect.size.width = MBTableGridRowHeaderWidth;
	
	return rect;
}

@end
