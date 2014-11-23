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

#import "MBTableGridContentView.h"

#import "MBTableGrid.h"
#import "MBTableGridCell.h"

@interface MBTableGrid (Private)
- (id)_objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (void)_setObjectValue:(id)value forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (BOOL)_canEditCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (void)_cancelEdit;
- (void)_setStickyColumn:(MBTableGridEdge)stickyColumn row:(MBTableGridEdge)stickyRow;
- (MBTableGridEdge)_stickyColumn;
- (MBTableGridEdge)_stickyRow;
@end

@interface MBTableGridContentView (Cursors)
- (NSCursor *)_cellSelectionCursor;
- (NSImage *)_cellSelectionCursorImage;
@end

@interface MBTableGridContentView (DragAndDrop)
- (void)_setDraggingColumnOrRow:(BOOL)flag;
- (void)_setDropColumn:(NSInteger)columnIndex;
- (void)_setDropRow:(NSInteger)rowIndex;
- (void)_timerAutoscrollCallback:(NSTimer *)aTimer;
@end

@implementation MBTableGridContentView

#pragma mark -
#pragma mark Initialization & Superclass Overrides

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
  if (self != nil) {
		mouseDownColumn = NSNotFound;
		mouseDownRow = NSNotFound;
		
		editedColumn = NSNotFound;
		editedRow = NSNotFound;
		
		dropColumn = NSNotFound;
		dropRow = NSNotFound;
		
		// Cache the cursor image
		cursorImage = [self _cellSelectionCursorImage];
		
		isDraggingColumnOrRow = NO;
	}
	return self;
}


- (void)drawRect:(NSRect)rect
{
	NSInteger numberOfColumns = [[self tableGrid] numberOfColumns];
	NSInteger numberOfRows = [[self tableGrid] numberOfRows];
	
	NSInteger firstColumn = NSNotFound;
	NSInteger lastColumn = numberOfColumns - 1;
	NSInteger firstRow = NSNotFound;
	NSInteger lastRow = numberOfRows - 1;
	
	NSIndexSet *selectedColumns = [[self tableGrid] selectedColumnIndexes];
	NSIndexSet *selectedRows = [[self tableGrid] selectedRowIndexes];
	
	// Find the columns to draw.
  // Note: we cannot optimize drawing here with [self visibleRect] as this doesn't work with
  //       layer-backed NSScrollView (which uses a CATiledLayer then). The passed in rect is
  //       however adjusted to draw only one tile.
	NSInteger column = 0;
	while (column < numberOfColumns) {
		NSRect columnRect = [self rectOfColumn:column];
		if (firstColumn == NSNotFound && NSMinX(rect) >= NSMinX(columnRect) && NSMinX(rect) <= NSMaxX(columnRect)) {
			firstColumn = column;
		} else if (firstColumn != NSNotFound && NSMaxX(rect) >= NSMinX(columnRect) && NSMaxX(rect) <= NSMaxX(columnRect)) {
			lastColumn = column;
			break;
		}
		column++;
	}
  
	// Find the rows to draw
	NSInteger row = 0;
	while (row < numberOfRows) {
		NSRect rowRect = [self rectOfRow:row];
		if (firstRow == NSNotFound && NSMinY(rect) >= rowRect.origin.x && NSMinY(rect) <= NSMaxY(rowRect)) {
			firstRow = row;
		} else if (firstRow != NSNotFound && NSMaxY(rect) >= NSMinY(rowRect) && NSMaxY(rect) <= NSMaxY(rowRect)) {
			lastRow = row;
			break;
		}
		row++;
	}	
	
  // First loop. Draw only cells which are not or only partially selected.
  id cell = [self tableGrid].cell;
	column = firstColumn;
	while (column <= lastColumn) {
		row = firstRow;
		while (row <= lastRow) {
			NSRect cellFrame = [self frameOfCellAtColumn:column row:row];
			
			// Only draw the cell if we need to
			if ([self needsToDrawRect: cellFrame]) {
        BOOL isFullySelected = [selectedRows containsIndex: row] && [selectedColumns containsIndex: column];
        if ([cell isKindOfClass: [MBTableGridCell class]]) {
          [cell setIsInSelectedRow: [selectedRows containsIndex: row]];
          [cell setIsInSelectedColumn: [selectedColumns containsIndex: column]];
        }
        if (!isFullySelected) {
          [cell setObjectValue:[[self tableGrid] _objectValueForColumn:column row:row]];
          [cell drawWithFrame:cellFrame inView:self];
        }
			}
			row++;
		}
		column++;
	}
	
  // Second loop. Draw only cells which are fully selected (i.e. are in both selection sets).
  // This allows to draw them oversized.
	column = firstColumn;
	while (column <= lastColumn) {
		row = firstRow;
		while (row <= lastRow) {
			NSRect cellFrame = [self frameOfCellAtColumn:column row:row];
			
			// Only draw the cell if we need to
			if ([self needsToDrawRect:cellFrame]) {
        BOOL isFullySelected = [selectedRows containsIndex: row] && [selectedColumns containsIndex: column];
        if ([cell isKindOfClass: [MBTableGridCell class]]) {
          [cell setIsInSelectedRow: YES];
          [cell setIsInSelectedColumn: YES];
        }
        if (isFullySelected) {
          [cell setObjectValue:[[self tableGrid] _objectValueForColumn:column row:row]];
          [cell drawWithFrame:cellFrame inView:self];
        }
			}
			row++;
		}
		column++;
	}
	
	// Draw the selection rectangle
	if (self.tableGrid.showSelectionRing && [selectedColumns count] && [selectedRows count] &&
      [[self tableGrid] numberOfColumns] > 0 && [[self tableGrid] numberOfRows] > 0) {
		NSRect selectionTopLeft = [self frameOfCellAtColumn:[selectedColumns firstIndex] row:[selectedRows firstIndex]];
		NSRect selectionBottomRight = [self frameOfCellAtColumn:[selectedColumns lastIndex] row:[selectedRows lastIndex]];
		
		NSRect selectionRect;
		selectionRect.origin = selectionTopLeft.origin;
		selectionRect.size.width = NSMaxX(selectionBottomRight)-selectionTopLeft.origin.x;
		selectionRect.size.height = NSMaxY(selectionBottomRight)-selectionTopLeft.origin.y;
		
		NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRect:NSInsetRect(selectionRect, 1, 1)];
		NSAffineTransform *translate = [NSAffineTransform transform];
		[translate translateXBy:-0.5 yBy:-0.5];
		[selectionPath transformUsingAffineTransform:translate];
		
		NSColor *selectionColor = [NSColor alternateSelectedControlColor];
		
		// If the view is not the first responder, the use a gray selection color
		NSResponder *firstResponder = [[self window] firstResponder];
		if (![[firstResponder class] isSubclassOfClass:[NSView class]] || ![(NSView *)firstResponder isDescendantOf:[self tableGrid]] || ![[self window] isKeyWindow]) {
			selectionColor = [[selectionColor colorUsingColorSpaceName:NSDeviceWhiteColorSpace] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
		}
		
		[selectionColor set];
		[selectionPath setLineWidth: 1.0];
		[selectionPath stroke];
	}
	
	// Draw the column drop indicator
	if (isDraggingColumnOrRow && dropColumn != NSNotFound &&
      dropColumn <= (NSInteger)[[self tableGrid] numberOfColumns] &&
      dropRow == NSNotFound) {
		NSRect columnBorder;
		if(dropColumn < (NSInteger)[[self tableGrid] numberOfColumns]) {
			columnBorder = [self rectOfColumn:dropColumn];
		} else {
			columnBorder = [self rectOfColumn:dropColumn-1];
			columnBorder.origin.x += columnBorder.size.width;
		}
		columnBorder.origin.x = NSMinX(columnBorder)-2.0;
		columnBorder.size.width = 4.0;
		
		NSColor *selectionColor = [NSColor alternateSelectedControlColor];
		
		NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:columnBorder];
		[borderPath setLineWidth:2.0];
		
		[selectionColor set];
		[borderPath stroke];
	}
	
	// Draw the row drop indicator
	if (isDraggingColumnOrRow &&
      dropRow != NSNotFound &&
      dropRow <= (NSInteger)[[self tableGrid] numberOfRows] &&
      dropColumn == NSNotFound) {
		NSRect rowBorder;
		if(dropRow < (NSInteger)[[self tableGrid] numberOfRows]) {
			rowBorder = [self rectOfRow:dropRow];
		} else {
			rowBorder = [self rectOfRow:dropRow-1];
			rowBorder.origin.y += rowBorder.size.height;
		}
		rowBorder.origin.y = NSMinY(rowBorder)-2.0;
		rowBorder.size.height = 4.0;
		
		NSColor *selectionColor = [NSColor alternateSelectedControlColor];
		
		NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:rowBorder];
		[borderPath setLineWidth:2.0];
		
		[selectionColor set];
		[borderPath stroke];
	}
	
	// Draw the cell drop indicator
	if (!isDraggingColumnOrRow &&
      dropRow != NSNotFound &&
      dropRow <= (NSInteger)[[self tableGrid] numberOfRows] &&
      dropColumn != NSNotFound &&
      dropColumn <= (NSInteger)[[self tableGrid] numberOfColumns]) {
		NSRect cellFrame = [self frameOfCellAtColumn:dropColumn row:dropRow];
		cellFrame.origin.x -= 2.0;
		cellFrame.origin.y -= 2.0;
		cellFrame.size.width += 3.0;
		cellFrame.size.height += 3.0;
		
		NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:NSInsetRect(cellFrame, 2, 2)];
		
		NSColor *dropColor = [NSColor alternateSelectedControlColor];
		[dropColor set];
		
		[borderPath setLineWidth:2.0];
		[borderPath stroke];
	}
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	// Setup the timer for autoscrolling 
	// (the simply calling autoscroll: from mouseDragged: only works as long as the mouse is moving)
	autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_timerAutoscrollCallback:) userInfo:nil repeats:YES];
	
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	mouseDownColumn = [self columnAtPoint:loc];
	mouseDownRow = [self rowAtPoint:loc];
	
	if ([theEvent clickCount] == 1 && mouseDownColumn != NSNotFound && mouseDownRow != NSNotFound) {
		// Pass the event back to the MBTableGrid (Used to give First Responder status)
		[[self tableGrid] mouseDown:theEvent];
		
		// Single click
		if(([theEvent modifierFlags] & NSShiftKeyMask) && [self tableGrid].allowsMultipleSelection) {
			// If the shift key was held down, extend the selection
			NSInteger stickyColumn = [[self tableGrid].selectedColumnIndexes firstIndex];
			NSInteger stickyRow = [[self tableGrid].selectedRowIndexes firstIndex];
			
			MBTableGridEdge stickyColumnEdge = [[self tableGrid] _stickyColumn];
			MBTableGridEdge stickyRowEdge = [[self tableGrid] _stickyRow];
			
			// Compensate for sticky edges
			if (stickyColumnEdge == MBTableGridRightEdge) {
				stickyColumn = [[self tableGrid].selectedColumnIndexes lastIndex];
			}
			if (stickyRowEdge == MBTableGridBottomEdge) {
				stickyRow = [[self tableGrid].selectedRowIndexes lastIndex];
			}
			
			NSRange selectionColumnRange = NSMakeRange(stickyColumn, mouseDownColumn-stickyColumn+1);
			NSRange selectionRowRange = NSMakeRange(stickyRow, mouseDownRow-stickyRow+1);
			
			if (mouseDownColumn < stickyColumn) {
				selectionColumnRange = NSMakeRange(mouseDownColumn, stickyColumn-mouseDownColumn+1);
				stickyColumnEdge = MBTableGridRightEdge;
			} else {
				stickyColumnEdge = MBTableGridLeftEdge;
			}
			
			if (mouseDownRow < stickyRow) {
				selectionRowRange = NSMakeRange(mouseDownRow, stickyRow-mouseDownRow+1);
				stickyRowEdge = MBTableGridBottomEdge;
			} else {
				stickyRowEdge = MBTableGridTopEdge;
			}
			
			// Select the proper cells
			[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:selectionColumnRange];
			[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:selectionRowRange];
			
			// Set the sticky edges
			[[self tableGrid] _setStickyColumn:stickyColumnEdge row:stickyRowEdge];
		} else {
			// No modifier keys, so change the selection
			[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndex:mouseDownColumn];
			[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndex:mouseDownRow];
			[[self tableGrid] _setStickyColumn:MBTableGridLeftEdge row:MBTableGridTopEdge];
		}
	} else if([theEvent clickCount] == 2) {
		// Double click
		[self editSelectedCell:self];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (mouseDownColumn != NSNotFound && mouseDownRow != NSNotFound && [self tableGrid].allowsMultipleSelection) {
		NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSInteger column = [self columnAtPoint:loc];
		NSInteger row = [self rowAtPoint:loc];
		
		MBTableGridEdge columnEdge = MBTableGridLeftEdge;
		MBTableGridEdge rowEdge = MBTableGridTopEdge;
		
		// Select the appropriate number of columns
		if(column != NSNotFound) {
			NSInteger firstColumnToSelect = mouseDownColumn;
			NSInteger numberOfColumnsToSelect = column-mouseDownColumn+1;
			if(column < mouseDownColumn) {
				firstColumnToSelect = column;
				numberOfColumnsToSelect = mouseDownColumn-column+1;
				
				// Set the sticky edge to the right
				columnEdge = MBTableGridRightEdge;
			}
			
			[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstColumnToSelect,numberOfColumnsToSelect)];
			
		}
		
		// Select the appropriate number of rows
		if(row != NSNotFound) {
			NSInteger firstRowToSelect = mouseDownRow;
			NSInteger numberOfRowsToSelect = row-mouseDownRow+1;
			if(row < mouseDownRow) {
				firstRowToSelect = row;
				numberOfRowsToSelect = mouseDownRow-row+1;
				
				// Set the sticky row to the bottom
				rowEdge = MBTableGridBottomEdge;
			}
			
			[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstRowToSelect,numberOfRowsToSelect)];
			
		}
		
		// Set the sticky edges
		[[self tableGrid] _setStickyColumn:columnEdge row:rowEdge];
		
	}
	
//	[self autoscroll:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[autoscrollTimer invalidate];
	autoscrollTimer = nil;
	
	mouseDownColumn = NSNotFound;
	mouseDownRow = NSNotFound;
}

#pragma mark Cursor Rects

- (void)resetCursorRects
{
	// The main cursor should be the cell selection cursor
	[self addCursorRect:[self visibleRect] cursor:[self _cellSelectionCursor]];
}

#pragma mark -
#pragma mark Notifications

#pragma mark Field Editor

- (void)textDidEndEditing:(NSNotification *)aNotification
{	
	// Give focus back to the table grid (the field editor took it)
	[[self window] makeFirstResponder:[self tableGrid]];
	
	NSString *value = [[aNotification object] string];
	[[self tableGrid] _setObjectValue:value forColumn:editedColumn row:editedRow];
	
	editedColumn = NSNotFound;
	editedRow = NSNotFound;
	
	// End the editing session
	[[[self tableGrid] cell] endEditing:[[self window] fieldEditor:NO forObject:self]];
}

- (void)cancelEditing
{
  [[self window] makeFirstResponder:[self tableGrid]];
  
  [[self tableGrid] _cancelEdit];
  
  editedColumn = NSNotFound;
  editedRow = NSNotFound;
  
  // End the editing session
  [[self tableGrid] abortEditing];
}

#pragma mark -
#pragma mark Protocol Methods

#pragma mark NSDraggingDestination

/*
 * These methods simply pass the drag event back to the table grid.
 * They are only required for autoscrolling.
 */

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	// Setup the timer for autoscrolling 
	// (the simply calling autoscroll: from mouseDragged: only works as long as the mouse is moving)
	autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_timerAutoscrollCallback:) userInfo:nil repeats:YES];
	
	return [[self tableGrid] draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [[self tableGrid] draggingUpdated:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[autoscrollTimer invalidate];
	autoscrollTimer = nil;
	
	[[self tableGrid] draggingExited:sender];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	[[self tableGrid] draggingEnded:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return [[self tableGrid] prepareForDragOperation:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return [[self tableGrid] performDragOperation:sender];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[[self tableGrid] concludeDragOperation:sender];
}

#pragma mark -
#pragma mark Subclass Methods

- (MBTableGrid *)tableGrid
{
	return (MBTableGrid *)[[self enclosingScrollView] superview];
}

- (void)editSelectedCell:(id)sender
{
	// Get the top-left selection
	editedColumn = [[self tableGrid].selectedColumnIndexes firstIndex];
	editedRow = [[self tableGrid].selectedRowIndexes firstIndex];
	
	// Check if the cell can be edited
	if(![[self tableGrid] _canEditCellAtColumn:editedColumn row:editedRow]) {
		editedColumn = NSNotFound;
		editedRow = NSNotFound;
		return;
	}
	
	// Select it and only it
	if([[self tableGrid].selectedColumnIndexes count] > 1) {
		[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndex:editedColumn];
	}
	if([[self tableGrid].selectedRowIndexes count] > 1) {
		[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndex:editedRow];
	}
	
	NSTextFieldCell *cell = [[self tableGrid] cell];
	[cell setEditable:YES];
	[cell setSelectable:YES];
	[cell setObjectValue:[[self tableGrid] _objectValueForColumn:editedColumn row:editedRow]];
	
	NSRect cellFrame = [self frameOfCellAtColumn:editedColumn row:editedRow];
	NSText *editor = [[self window] fieldEditor:YES forObject:self];
	[cell editWithFrame:cellFrame inView:self editor:editor delegate:self event:nil];
}

#pragma mark Layout Support

- (NSRect)rectOfColumn: (NSInteger)columnIndex
{
	NSRect rect = NSMakeRect(0, 0, [[self tableGrid] defaultCellSize].width, [self frame].size.height);
  if (columnIndex >= 0) {
    rect.origin.x += rect.size.width * columnIndex;
  }
	return rect;
}

- (NSRect)rectOfRow: (NSInteger)rowIndex
{
	NSRect rect = NSMakeRect(0, 0, [self frame].size.width, [[self tableGrid] defaultCellSize].height);
	
  if (rowIndex >= 0) {
    rect.origin.y += rect.size.height * rowIndex;
  }
	
	return rect;
}

- (NSRect)frameOfCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
	NSRect columnRect = [self rectOfColumn: columnIndex];
	NSRect rowRect = [self rectOfRow: rowIndex];
	return NSMakeRect(columnRect.origin.x, rowRect.origin.y, columnRect.size.width, rowRect.size.height);
}

- (NSInteger)columnAtPoint:(NSPoint)aPoint
{
	NSUInteger column = 0;
	while(column < [[self tableGrid] numberOfColumns]) {
		NSRect columnFrame = [self rectOfColumn:column];
		if(NSPointInRect(aPoint, columnFrame)) {
			return column;
		}
		column++;
	}
	return NSNotFound;
}

- (NSInteger)rowAtPoint:(NSPoint)aPoint
{
	NSUInteger row = 0;
	while(row < [[self tableGrid] numberOfRows]) {
		NSRect rowFrame = [self rectOfRow:row];
		if(NSPointInRect(aPoint, rowFrame)) {
			return row;
		}
		row++;
	}
	return NSNotFound;
}

@end

@implementation MBTableGridContentView (Cursors)

- (NSCursor *)_cellSelectionCursor
{
	NSCursor *cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8, 8)];	
	return cursor;
}

/**
 * @warning		This method is not as efficient as it could be, but
 *				it should only be called once, at initialization.
 *				TODO: Make it faster
 */
- (NSImage *)_cellSelectionCursorImage
{
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(20, 20)];
    //[image setFlipped:YES];
	[image lockFocus];
	
	NSRect horizontalInner = NSMakeRect(7.0, 2.0, 2.0, 12.0);
	NSRect verticalInner = NSMakeRect(2.0, 7.0, 12.0, 2.0);
	
	NSRect horizontalOuter = NSInsetRect(horizontalInner, -1.0, -1.0);
	NSRect verticalOuter = NSInsetRect(verticalInner, -1.0, -1.0);
	
	// Set the shadow
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.8]];
	[shadow setShadowBlurRadius:2.0];
	[shadow setShadowOffset:NSMakeSize(0, -1.0)];
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	[shadow set];
	
	[[NSColor blackColor] set];
	NSRectFill(horizontalOuter);
	NSRectFill(verticalOuter);
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	// Fill them again to compensate for the shadows
	NSRectFill(horizontalOuter);
	NSRectFill(verticalOuter);
	
	[[NSColor whiteColor] set];
	NSRectFill(horizontalInner);
	NSRectFill(verticalInner);
	
	[image unlockFocus];
	
	return image;
}

@end

@implementation MBTableGridContentView (DragAndDrop)

- (void)_setDraggingColumnOrRow:(BOOL)flag
{
	isDraggingColumnOrRow = flag;
}

- (void)_setDropColumn:(NSInteger)columnIndex
{
	dropColumn = columnIndex;
	[self setNeedsDisplay:YES];
}

- (void)_setDropRow:(NSInteger)rowIndex
{
	dropRow = rowIndex;
	[self setNeedsDisplay:YES];
}

- (void)_timerAutoscrollCallback:(NSTimer *)aTimer
{
	NSEvent* event = [NSApp currentEvent];
    if ([event type] == NSLeftMouseDragged )
        [self autoscroll:event];
}

@end
