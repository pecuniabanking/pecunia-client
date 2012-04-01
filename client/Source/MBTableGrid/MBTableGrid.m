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

#import "MBTableGrid.h"
#import "MBTableGridHeaderView.h"
#import "MBTableGridHeaderCell.h"
#import "MBTableGridContentView.h"
#import "MBTableGridCell.h"

#import "SynchronousScrollView.h"

#pragma mark -
#pragma mark Constant Definitions
NSString *MBTableGridDidChangeSelectionNotification		= @"MBTableGridDidChangeSelectionNotification";
NSString *MBTableGridDidMoveColumnsNotification			= @"MBTableGridDidMoveColumnsNotification";
NSString *MBTableGridDidMoveRowsNotification			= @"MBTableGridDidMoveRowsNotification";

#pragma mark -
#pragma mark Drag Types
NSString *MBTableGridColumnDataType = @"MBTableGridColumnDataType";
NSString *MBTableGridRowDataType = @"MBTableGridRowDataType";

@interface MBTableGrid (Drawing)
- (void)_drawColumnHeaderBackgroundInRect:(NSRect)aRect;
- (void)_drawRowHeaderBackgroundInRect:(NSRect)aRect;
- (void)_drawCornerHeaderBackgroundInRect:(NSRect)aRect;
@end

@interface MBTableGrid (DataAccessors)
- (NSString *)_headerStringForColumn:(NSUInteger)columnIndex;
- (NSString *)_headerStringForRow:(NSUInteger)rowIndex;
- (id)_objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (void)_setObjectValue:(id)value forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (BOOL)_canEditCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
@end

@interface MBTableGrid (DragAndDrop)
- (void)_dragColumnsWithEvent:(NSEvent *)theEvent;
- (void)_dragRowsWithEvent:(NSEvent *)theEvent;
- (NSImage *)_imageForSelectedColumns;
- (NSImage *)_imageForSelectedRows;
- (NSUInteger)_dropColumnForPoint:(NSPoint)aPoint;
- (NSUInteger)_dropRowForPoint:(NSPoint)aPoint;
@end

@interface MBTableGrid (PrivateAccessors)
- (MBTableGridContentView *)_contentView;
- (void)_setStickyColumn:(MBTableGridEdge)stickyColumn row:(MBTableGridEdge)stickyRow;
- (MBTableGridEdge)_stickyColumn;
- (MBTableGridEdge)_stickyRow;
@end

@interface MBTableGridContentView (Private)
- (void)_setDraggingColumnOrRow:(BOOL)flag;
- (void)_setDropColumn:(NSInteger)columnIndex;
- (void)_setDropRow:(NSInteger)rowIndex;
@end


@implementation MBTableGrid

@synthesize allowsMultipleSelection;
@synthesize showSelectionRing;
@synthesize dataSource;
@synthesize delegate;
@synthesize selectedColumnIndexes;
@synthesize selectedRowIndexes;

@synthesize defaultCellSize;

#pragma mark -
#pragma mark Initialization & Superclass Overrides

+ (void)initialize
{
  [self exposeBinding: @"selectedRowIndexes"];
  [self exposeBinding: @"selectedColumnIndexes"];
}

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
  if (self != nil) {
		// Post frame changed notifications
		[self setPostsFrameChangedNotifications:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self];
		
		// Set the default cell
		MBTableGridCell *defaultCell = [[MBTableGridCell alloc] initTextCell:@""];
		[defaultCell setBezeled:YES];
		[defaultCell setScrollable:YES];
		[defaultCell setLineBreakMode:NSLineBreakByTruncatingTail];
		[self setCell:defaultCell];
		[defaultCell release];
		
    defaultCellSize = NSMakeSize(60, 20);
    
		// Setup the column headers
		NSRect columnHeaderFrame = NSMakeRect(MBTableGridRowHeaderWidth, 0, frameRect.size.width-MBTableGridRowHeaderWidth, MBTableGridColumnHeaderHeight);
		columnHeaderScrollView = [[NSScrollView alloc] initWithFrame:columnHeaderFrame];
		columnHeaderView = [[MBTableGridHeaderView alloc] initWithFrame:NSMakeRect(0,0,columnHeaderFrame.size.width,columnHeaderFrame.size.height)];
	//	[columnHeaderView setAutoresizingMask:NSViewWidthSizable];
		[columnHeaderView setOrientation:MBTableHeaderHorizontalOrientation];
		[columnHeaderScrollView setDocumentView:columnHeaderView];
		[columnHeaderScrollView setAutoresizingMask:NSViewWidthSizable];
		[columnHeaderScrollView setDrawsBackground:NO];
		[self addSubview:columnHeaderScrollView];
		
		// Setup the row headers
		NSRect rowHeaderFrame = NSMakeRect(0, MBTableGridColumnHeaderHeight, MBTableGridRowHeaderWidth, [self frame].size.height-MBTableGridColumnHeaderHeight);
		rowHeaderScrollView = [[NSScrollView alloc] initWithFrame:rowHeaderFrame];
		rowHeaderView = [[MBTableGridHeaderView alloc] initWithFrame:NSMakeRect(0,0,rowHeaderFrame.size.width,rowHeaderFrame.size.height)];
		//[rowHeaderView setAutoresizingMask:NSViewHeightSizable];
		[rowHeaderView setOrientation:MBTableHeaderVerticalOrientation];
		[rowHeaderScrollView setDocumentView:rowHeaderView];
		[rowHeaderScrollView setAutoresizingMask:NSViewHeightSizable];
		[rowHeaderScrollView setDrawsBackground:NO];
		[self addSubview:rowHeaderScrollView];
		
		// Setup the content view
		NSRect contentFrame = NSMakeRect(MBTableGridRowHeaderWidth, MBTableGridColumnHeaderHeight, [self frame].size.width-MBTableGridRowHeaderWidth, [self frame].size.height-MBTableGridColumnHeaderHeight);
		contentScrollView = [[SynchronousScrollView alloc] initWithFrame: contentFrame];
		contentView = [[MBTableGridContentView alloc] initWithFrame:NSMakeRect(0,0,contentFrame.size.width,contentFrame.size.height)];
		[contentScrollView setDocumentView:contentView];
		[contentScrollView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
		[contentScrollView setHasHorizontalScroller:YES];
		[contentScrollView setHasVerticalScroller:YES];
		[contentScrollView setAutohidesScrollers:YES];
		[self addSubview:contentScrollView];
		
		// We want to synchronize the scroll views
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewDidScroll:) name:NSViewBoundsDidChangeNotification object:[contentScrollView contentView]];
	
		// Set the default selection
		self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:0];
		self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:0];
		self.allowsMultipleSelection = YES;
    self.showSelectionRing = YES;
		
		// Set the default sticky edges
		stickyColumnEdge = MBTableGridLeftEdge;
		stickyRowEdge = MBTableGridTopEdge;
		
		shouldOverrideModifiers = NO;
	}
	return self;
}

- (void)awakeFromNib
{
//	[self reloadData];
	[self registerForDraggedTypes:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[columnHeaderScrollView release];
	[columnHeaderView release];
	[rowHeaderScrollView release];
	[rowHeaderView release];
	[super dealloc];
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)canBecomeKeyView
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)drawRect:(NSRect)aRect
{		
	// If the view is the first responder, draw the focus ring
	NSResponder *firstResponder = [[self window] firstResponder];
	if (([[firstResponder class] isSubclassOfClass:[NSView class]] && [(NSView *)firstResponder isDescendantOf:self]) && [[self window] isKeyWindow]) {
		[[NSGraphicsContext currentContext] saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);
		
		[[NSBezierPath bezierPathWithRect:NSMakeRect(0,0,[self frame].size.width,[self frame].size.height)] fill];
		
		[[NSGraphicsContext currentContext] restoreGraphicsState];
		[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
	}
	
	// Draw the corner header if both headers are visible.
	NSRect cornerRect = [self headerRectOfCorner];
  if (![columnHeaderView isHidden] && ![rowHeaderView isHidden]) {
    [self _drawCornerHeaderBackgroundInRect:cornerRect];
  } else {
    if ([columnHeaderView isHidden]) {
      cornerRect.size.height = 0;
    } else {
      cornerRect.size.width = 0;
    }
  }
	
	// Draw the column header background
  if (![columnHeaderView isHidden]) {
    NSRect columnHeaderRect = NSMakeRect(NSWidth(cornerRect), 0,
                                         [self frame].size.width - NSWidth(cornerRect), MBTableGridColumnHeaderHeight);
    [self _drawColumnHeaderBackgroundInRect:columnHeaderRect];
  }
	
	// Draw the row header background
  if (![rowHeaderView isHidden]) {
    NSRect rowHeaderRect = NSMakeRect(0, NSMaxY(cornerRect), MBTableGridRowHeaderWidth,
                                      [self frame].size.height - cornerRect.size.height);
    [self _drawRowHeaderBackgroundInRect:rowHeaderRect];
  }
}

- (void)registerForDraggedTypes:(NSArray *)pboardTypes
{
	// Add the column and row types to the array
	NSMutableArray *types = [NSMutableArray arrayWithArray:pboardTypes];
	
	if (!pboardTypes) {
		types = [NSMutableArray array];
	}
	[types addObjectsFromArray:[NSArray arrayWithObjects:MBTableGridColumnDataType, MBTableGridRowDataType, nil]];
	
	[super registerForDraggedTypes:types];
	
	// Register the content view for everything
	[contentView registerForDraggedTypes:types];
}
#pragma mark Property Setters

- (void)setSelectedColumnIndexes:(NSIndexSet *)anIndexSet
{
	if(anIndexSet == selectedColumnIndexes)
		return;
	
	if(selectedColumnIndexes) {
		[selectedColumnIndexes release];
	}
	
	// Allow the delegate to validate the selection
	if ([[self delegate] respondsToSelector:@selector(tableGrid:willSelectColumnsAtIndexPath:)]) {
		anIndexSet = [[self delegate] tableGrid:self willSelectColumnsAtIndexPath:anIndexSet];
	}
	
	selectedColumnIndexes = [anIndexSet retain];
  if ([selectedColumnIndexes count] == 1) {
    [self scrollColumnToVisible: selectedColumnIndexes.firstIndex];
  }
	
	[self setNeedsDisplay:YES];
  
   // Explicitly set needsDisplay for subviews too, as this doesn't happen automatically if we are layer-backed.
  [contentView setNeedsDisplay: YES];
  [columnHeaderView setNeedsDisplay: YES];
  [rowHeaderView setNeedsDisplay: YES];
	
	// Post the notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MBTableGridDidChangeSelectionNotification object:self];
}

- (void)setSelectedRowIndexes:(NSIndexSet *)anIndexSet
{
	if(anIndexSet == selectedColumnIndexes)
		return;
	
	if(selectedRowIndexes) {
		[selectedRowIndexes release];
	}
	
	// Allow the delegate to validate the selection
	if ([[self delegate] respondsToSelector:@selector(tableGrid:willSelectRowsAtIndexPath:)]) {
		anIndexSet = [[self delegate] tableGrid:self willSelectRowsAtIndexPath:anIndexSet];
	}
	
	selectedRowIndexes = [anIndexSet retain];
  if ([selectedRowIndexes count] == 1) {
    [self scrollRowToVisible: selectedRowIndexes.firstIndex];
  }
	
	[self setNeedsDisplay:YES];
	
  // Explicitly set needsDisplay for subviews too, as this doesn't happen automatically if we are layer-backed.
  [contentView setNeedsDisplay: YES];
  [columnHeaderView setNeedsDisplay: YES];
  [rowHeaderView setNeedsDisplay: YES];
	
	// Post the notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MBTableGridDidChangeSelectionNotification object:self];
}

- (void)setDelegate:(id <MBTableGridDelegate>)anObject
{
	if (anObject == delegate)
		return;
	
	if (delegate) {
		// Unregister the delegate for relavent notifications
		[[NSNotificationCenter defaultCenter] removeObserver:delegate name:MBTableGridDidChangeSelectionNotification object:self];
		[[NSNotificationCenter defaultCenter] removeObserver:delegate name:MBTableGridDidMoveColumnsNotification object:self];
		[[NSNotificationCenter defaultCenter] removeObserver:delegate name:MBTableGridDidMoveRowsNotification object:self];
	}
	
	delegate = anObject;
	
	// Register the new delegate for relavent notifications
	if ([delegate respondsToSelector:@selector(tableGridDidChangeSelection:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(tableGridDidChangeSelection:) name:MBTableGridDidChangeSelectionNotification object:self];
	}
	if ([delegate respondsToSelector:@selector(tableGridDidMoveColumns:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(tableGridDidMoveColumns:) name:MBTableGridDidMoveColumnsNotification object:self];
	}
	if ([delegate respondsToSelector:@selector(tableGridDidMoveRows:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(tableGridDidMoveRows:) name:MBTableGridDidMoveRowsNotification object:self];
	}
}

#pragma mark Mouse Events

- (void)mouseDown:(NSEvent *)theEvent
{
	// End editing (if necessary)
  NSText *fieldEditor = [[self window] fieldEditor:NO forObject:contentView];
  if (fieldEditor != nil)
    [[self cell] endEditing: fieldEditor];
	
	// If we're not the first responder, we need to be
	if([[self window] firstResponder] != self) {
		[[self window] makeFirstResponder:self];
	}
}

#pragma mark Keyboard Events

- (void)keyDown:(NSEvent *)theEvent
{
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

/*- (void)interpretKeyEvents:(NSArray *)eventArray
{
	
}*/

#pragma mark NSResponder Event Handlers

- (void)insertTab:(id)sender 
{
	// Pressing "Tab" moves to the next column
    [self moveRight:sender];
}

- (void)insertBacktab:(id)sender 
{
	// We want to change the selection, not expand it
	shouldOverrideModifiers = YES;
	
    // Pressing Shift+Tab moves to the previous column
	[self moveLeft:sender];
}

- (void)insertNewline:(id)sender
{
	if([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
		// Pressing Shift+Return moves to the previous row
		shouldOverrideModifiers = YES;
		[self moveUp:sender];
	} else {
		// Pressing Return moves to the next row
		[self moveDown:sender];
	}
}

- (void)moveUp:(id)sender
{
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	NSUInteger row = [self.selectedRowIndexes firstIndex];
	
	// Accomodate for the sticky edges
	if(stickyColumnEdge == MBTableGridRightEdge) {
		column = [self.selectedColumnIndexes lastIndex];
	}
	if(stickyRowEdge == MBTableGridBottomEdge) {
		row = [self.selectedRowIndexes lastIndex];
	}
	
	// If we're already at the first row, do nothing
	if(row <= 0)
		return;
	
	// If the Shift key was not held, move the selection
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:column];
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:(row-1)];
}

- (void)moveUpAndModifySelection:(id)sender
{
	if(shouldOverrideModifiers) {
		[self moveLeft:sender];
		shouldOverrideModifiers = NO;
		return;
	}
	
	NSUInteger firstRow = [self.selectedRowIndexes firstIndex];
	NSUInteger lastRow = [self.selectedRowIndexes lastIndex];
	
	// If there is only one row selected, change the sticky edge to the bottom
	if([self.selectedRowIndexes count] == 1) {
		stickyRowEdge = MBTableGridBottomEdge;
	}
	
	// We can't expand past the last row
	if(stickyRowEdge == MBTableGridBottomEdge && firstRow <= 0)
		return;
	
	if(stickyRowEdge == MBTableGridTopEdge) {
		// If the top edge is sticky, contract the selection
		lastRow--;
	} else if(stickyRowEdge == MBTableGridBottomEdge) {
		// If the bottom edge is sticky, expand the contraction
		firstRow--;
	}
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstRow, lastRow-firstRow+1)];	
}

- (void)moveDown:(id)sender
{
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	NSUInteger row = [self.selectedRowIndexes firstIndex];
	
	// Accomodate for the sticky edges
	if(stickyColumnEdge == MBTableGridRightEdge) {
		column = [self.selectedColumnIndexes lastIndex];
	}
	if(stickyRowEdge == MBTableGridBottomEdge) {
		row = [self.selectedRowIndexes lastIndex];
	}
	
	// If we're already at the last row, do nothing
	if(row >= ([self numberOfRows]-1))
		return;
	
	// If the Shift key was not held, move the selection
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:column];
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:(row+1)];
}

- (void)moveDownAndModifySelection:(id)sender
{
	if(shouldOverrideModifiers) {
		[self moveDown:sender];
		shouldOverrideModifiers = NO;
		return;
	}
	
	NSUInteger firstRow = [self.selectedRowIndexes firstIndex];
	NSUInteger lastRow = [self.selectedRowIndexes lastIndex];
	
	// If there is only one row selected, change the sticky edge to the top
	if([self.selectedRowIndexes count] == 1) {
		stickyRowEdge = MBTableGridTopEdge;
	}
	
	// We can't expand past the last row
	if(stickyRowEdge == MBTableGridTopEdge && lastRow >= ([self numberOfRows]-1))
		return;
	
	if(stickyRowEdge == MBTableGridTopEdge) {
		// If the top edge is sticky, contract the selection
		lastRow++;
	} else if(stickyRowEdge == MBTableGridBottomEdge) {
		// If the bottom edge is sticky, expand the contraction
		firstRow++;
	}
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstRow, lastRow-firstRow+1)];	
}

- (void)moveLeft:(id)sender
{
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	NSUInteger row = [self.selectedRowIndexes firstIndex];
	
	// Accomodate for the sticky edges
	if(stickyColumnEdge == MBTableGridRightEdge) {
		column = [self.selectedColumnIndexes lastIndex];
	}
	if(stickyRowEdge == MBTableGridBottomEdge) {
		row = [self.selectedRowIndexes lastIndex];
	}
	
	// If we're already at the first column, do nothing
	if(column <= 0)
		return;
	
	// If the Shift key was not held, move the selection
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:(column-1)];
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:row];
}

- (void)moveLeftAndModifySelection:(id)sender
{
	if(shouldOverrideModifiers) {
		[self moveLeft:sender];
		shouldOverrideModifiers = NO;
		return;
	}
	
	NSUInteger firstColumn = [self.selectedColumnIndexes firstIndex];
	NSUInteger lastColumn = [self.selectedColumnIndexes lastIndex];
	
	// If there is only one column selected, change the sticky edge to the right
	if([self.selectedColumnIndexes count] == 1) {
		stickyColumnEdge = MBTableGridRightEdge;
	}
	
	// We can't expand past the first column
	if(stickyColumnEdge == MBTableGridRightEdge && firstColumn <= 0)
		return;
	
	if(stickyColumnEdge == MBTableGridLeftEdge) {
		// If the top edge is sticky, contract the selection
		lastColumn--;
	} else if(stickyColumnEdge == MBTableGridRightEdge) {
		// If the bottom edge is sticky, expand the contraction
		firstColumn--;
	}
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstColumn, lastColumn-firstColumn+1)];	
}

- (void)moveRight:(id)sender
{
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	NSUInteger row = [self.selectedRowIndexes firstIndex];
	
	// Accomodate for the sticky edges
	if(stickyColumnEdge == MBTableGridRightEdge) {
		column = [self.selectedColumnIndexes lastIndex];
	}
	if(stickyRowEdge == MBTableGridBottomEdge) {
		row = [self.selectedRowIndexes lastIndex];
	}
	
	// If we're already at the last column, do nothing
	if(column >= ([self numberOfColumns]-1))
		return;
	
	// If the Shift key was not held, move the selection
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:(column+1)];
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:row];
}

- (void)moveRightAndModifySelection:(id)sender
{
	if(shouldOverrideModifiers) {
		[self moveRight:sender];
		shouldOverrideModifiers = NO;
		return;
	}
	
	NSUInteger firstColumn = [self.selectedColumnIndexes firstIndex];
	NSUInteger lastColumn = [self.selectedColumnIndexes lastIndex];
	
	// If there is only one column selected, change the sticky edge to the right
	if([self.selectedColumnIndexes count] == 1) {
		stickyColumnEdge = MBTableGridLeftEdge;
	}
	
	// We can't expand past the last column
	if(stickyColumnEdge == MBTableGridLeftEdge && lastColumn >= ([self numberOfColumns]-1))
		return;
	
	if(stickyColumnEdge == MBTableGridLeftEdge) {
		// If the top edge is sticky, contract the selection
		lastColumn++;
	} else if(stickyColumnEdge == MBTableGridRightEdge) {
		// If the bottom edge is sticky, expand the contraction
		firstColumn++;
	}
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstColumn, lastColumn-firstColumn+1)];	
}

- (void)selectAll:(id)sender
{
	stickyColumnEdge = MBTableGridLeftEdge;
	stickyRowEdge = MBTableGridTopEdge;
	
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfColumns])];
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])];
}

- (void)deleteBackward:(id)sender
{
	// Clear the contents of every selected cell
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	while(column <= [self.selectedColumnIndexes lastIndex]) {
		NSUInteger row = [self.selectedRowIndexes firstIndex];
		while(row <= [self.selectedRowIndexes lastIndex]) {
			[self _setObjectValue:nil forColumn:column row:row];
			row++;
		}
		column++;
	}
	[self reloadData];
}

- (void)insertText:(id)aString
{
	[contentView editSelectedCell:self];
	
	// Insert the typed string into the field editor
	NSText *fieldEditor = [[self window] fieldEditor:YES forObject:self];
  [fieldEditor setAlignment: [self.cell alignment]];
	[fieldEditor setString:aString];
}

#pragma mark -
#pragma mark Notifications

- (void)viewFrameDidChange:(NSNotification *)aNotification
{
	//[self reloadData];
}

- (void)contentViewDidScroll:(NSNotification *)aNotification
{
	NSView *changedView = [aNotification object];
	
	// Get the origin of the NSClipView
	NSPoint changedBoundsOrigin = [changedView bounds].origin;
	
	/*
	 * Column Header Synchronization
	 */
	
	// Get the column headers' current origin
	NSPoint curColumnOffset = [[columnHeaderScrollView contentView] bounds].origin;
	NSPoint newColumnOffset = curColumnOffset;
	
	// Column headers are synchronized in the horizontal plane
	newColumnOffset.x = changedBoundsOrigin.x;
	
	// If the synced position is different from our current position, reposition the headers view
    if (!NSEqualPoints(curColumnOffset, changedBoundsOrigin))
    {
		[[columnHeaderScrollView contentView] scrollToPoint:newColumnOffset];
		// we have to tell the NSScrollView to update its
		// scrollers
		[columnHeaderScrollView reflectScrolledClipView:[columnHeaderScrollView contentView]];
    }
	
	/*
	 * Row Header Synchronization
	 */
	
	// Get the row headers' current origin
	NSPoint curRowOffset = [[rowHeaderScrollView contentView] bounds].origin;
	NSPoint newRowOffset = curRowOffset;
	
	// Row headers are synchronized in the vertical plane
	newRowOffset.y = changedBoundsOrigin.y;
	
	// If the synced position is different from our current position, reposition the headers view
    if (!NSEqualPoints(curRowOffset, changedBoundsOrigin))
    {
		[[rowHeaderScrollView contentView] scrollToPoint:newRowOffset];
		// we have to tell the NSScrollView to update its
		// scrollers
		[rowHeaderScrollView reflectScrolledClipView:[rowHeaderScrollView contentView]];
    }
}

#pragma mark -
#pragma mark Protocol Methods

#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	NSData *columnData = [pboard dataForType:MBTableGridColumnDataType];
	NSData *rowData = [pboard dataForType:MBTableGridRowDataType];
	
	if (columnData) {
		return NSDragOperationMove;
	} else if (rowData) {
		return NSDragOperationMove;
	} else {
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:validateDrop:proposedColumn:row:)]) {
			NSPoint mouseLocation = [self convertPoint:[sender draggingLocation] fromView:nil]; 
			NSUInteger dropColumn = [self columnAtPoint:mouseLocation];
			NSUInteger dropRow = [self rowAtPoint:mouseLocation];
			
			NSDragOperation dragOperation = [[self dataSource] tableGrid:self validateDrop:sender proposedColumn:dropColumn row:dropRow];
			
			// If the drag is okay, highlight the appropriate cell
			if (dragOperation != NSDragOperationNone) {
				[contentView _setDropColumn:dropColumn];
				[contentView _setDropRow:dropRow];
			}
			
			return dragOperation;
		}
	}
	
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSData *columnData = [pboard dataForType:MBTableGridColumnDataType];
	NSData *rowData = [pboard dataForType:MBTableGridRowDataType];
	NSPoint mouseLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
	
	if (columnData) {
		// If we're dragging a column
		
		NSUInteger dropColumn = [self _dropColumnForPoint:mouseLocation];
		
		if (dropColumn == NSNotFound) {
			return NSDragOperationNone;
		}
		
		NSIndexSet *draggedColumns = (NSIndexSet *)[NSKeyedUnarchiver unarchiveObjectWithData:columnData];
		
		BOOL canDrop = NO;
		if([[self dataSource] respondsToSelector:@selector(tableGrid:canMoveColumns:toIndex:)]) {
			canDrop = [[self dataSource] tableGrid:self canMoveColumns:draggedColumns toIndex:dropColumn];
		}
		
		[contentView _setDraggingColumnOrRow:YES];
		
		if(canDrop) {
			[contentView _setDropColumn:dropColumn];
			return NSDragOperationMove;
		} else {
			[contentView _setDropColumn:NSNotFound];
		}
			
	} else if (rowData) {
		// If we're dragging a row
		
		NSUInteger dropRow = [self _dropRowForPoint:mouseLocation];
		
		if(dropRow == NSNotFound) {
			return NSDragOperationNone;
		}
		
		NSIndexSet *draggedRows = (NSIndexSet *)[NSKeyedUnarchiver unarchiveObjectWithData:rowData];
		
		BOOL canDrop = NO;
		if([[self dataSource] respondsToSelector:@selector(tableGrid:canMoveRows:toIndex:)]) {
			canDrop = [[self dataSource] tableGrid:self canMoveRows:draggedRows toIndex:dropRow];
		}
		
		[contentView _setDraggingColumnOrRow:YES];
		
		if(canDrop) {
			[contentView _setDropRow:dropRow];
			return NSDragOperationMove;
		} else {
			[contentView _setDropRow:NSNotFound];
		}
		
	} else {
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:validateDrop:proposedColumn:row:)]) {
			NSUInteger dropColumn = [self columnAtPoint:mouseLocation];
			NSUInteger dropRow = [self rowAtPoint:mouseLocation];
			
			[contentView _setDraggingColumnOrRow:NO];
			
			NSDragOperation dragOperation = [[self dataSource] tableGrid:self validateDrop:sender proposedColumn:dropColumn row:dropRow];
			
			// If the drag is okay, highlight the appropriate cell
			if (dragOperation != NSDragOperationNone) {
				[contentView _setDropColumn:dropColumn];
				[contentView _setDropRow:dropRow];
			}
			
			return dragOperation;
		}
	}
	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[contentView _setDropColumn:NSNotFound];
	[contentView _setDropRow:NSNotFound];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	[contentView _setDropColumn:NSNotFound];
	[contentView _setDropRow:NSNotFound];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSData *columnData = [pboard dataForType:MBTableGridColumnDataType];
	NSData *rowData = [pboard dataForType:MBTableGridRowDataType];
	NSPoint mouseLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
	
	if (columnData) {
		// If we're dragging a column
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:moveColumns:toIndex:)]) {
			// Get which columns are being dragged
			NSIndexSet *draggedColumns = (NSIndexSet *)[NSKeyedUnarchiver unarchiveObjectWithData:columnData];
			
			// Get the index to move the columns to
			NSUInteger dropColumn = [self _dropColumnForPoint:mouseLocation];
			
			// Tell the data source to move the columns
			BOOL didDrag = [[self dataSource] tableGrid:self moveColumns:draggedColumns toIndex:dropColumn];
			
			if (didDrag) {
				NSUInteger startIndex = dropColumn;
				NSUInteger length = [draggedColumns count];
				
				if (dropColumn > [draggedColumns firstIndex]) {
					startIndex -= [draggedColumns count];
				}
				
				NSIndexSet *newColumns = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, length)];
				
				// Post the notification
				[[NSNotificationCenter defaultCenter] postNotificationName:MBTableGridDidMoveColumnsNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:draggedColumns, @"OldColumns", newColumns, @"NewColumns", nil]];
			
				// Change the selection to reflect the newly-dragged columns
				self.selectedColumnIndexes = newColumns;
			}
			
			return didDrag;
		}
	} else if (rowData) {
		// If we're dragging a row
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:moveRows:toIndex:)]) {
			// Get which rows are being dragged
			NSIndexSet *draggedRows = (NSIndexSet *)[NSKeyedUnarchiver unarchiveObjectWithData:rowData];
			
			// Get the index to move the rows to
			NSUInteger dropRow = [self _dropRowForPoint:mouseLocation];
			
			// Tell the data source to move the rows
			BOOL didDrag = [[self dataSource] tableGrid:self moveRows:draggedRows toIndex:dropRow];
			
			if (didDrag) {
				NSUInteger startIndex = dropRow;
				NSUInteger length = [draggedRows count];
				
				if (dropRow > [draggedRows firstIndex]) {
					startIndex -= [draggedRows count];
				}
				
				NSIndexSet *newRows = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, length)];
				
				// Post the notification
				[[NSNotificationCenter defaultCenter] postNotificationName:MBTableGridDidMoveRowsNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:draggedRows, @"OldRows", newRows, @"NewRows", nil]];
				
				// Change the selection to reflect the newly-dragged rows
				self.selectedRowIndexes = newRows;
			}
			
			return didDrag;
		}
	} else {
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:acceptDrop:column:row:)]) {
			NSUInteger dropColumn = [self columnAtPoint:mouseLocation];
			NSUInteger dropRow = [self rowAtPoint:mouseLocation];
			
			// Pass the drag to the data source
			BOOL didPerformDrag = [[self dataSource] tableGrid:self acceptDrop:sender column:dropColumn row:dropRow];
			
			return didPerformDrag;
		}
	}
	
	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[contentView _setDropColumn:NSNotFound];
	[contentView _setDropRow:NSNotFound];
}

#pragma mark -
#pragma mark Subclass Methods

#pragma mark Dimensions

- (NSUInteger)numberOfRows
{
	// Ask the data source
	if([[self dataSource] respondsToSelector:@selector(numberOfRowsInTableGrid:)]) {
		return [[self dataSource] numberOfRowsInTableGrid:self];
	}
	return 0;
}

- (NSUInteger)numberOfColumns
{
	// Ask the data source
	if([[self dataSource] respondsToSelector:@selector(numberOfColumnsInTableGrid:)]) {
		return [[self dataSource] numberOfColumnsInTableGrid:self];
	}
	return 0;
}

#pragma mark Reloading the Grid

- (void)reloadData
{
	// Update the content view's size
	NSInteger lastColumn = [self numberOfColumns] - 1;
	NSInteger lastRow = [self numberOfRows] - 1;
	NSRect bottomRightCellFrame = [contentView frameOfCellAtColumn:lastColumn row:lastRow];
	
	NSRect contentRect = NSMakeRect([contentView frame].origin.x, [contentView frame].origin.y, NSMaxX(bottomRightCellFrame), NSMaxY(bottomRightCellFrame));
	[contentView setFrameSize:contentRect.size];
	
	// Update the column header view's size
	NSRect columnHeaderFrame = [columnHeaderView frame];
	columnHeaderFrame.size.width = contentRect.size.width;
	if(![[contentScrollView verticalScroller] isHidden]) {
		columnHeaderFrame.size.width += [NSScroller scrollerWidth];
	}
	[columnHeaderView setFrameSize:columnHeaderFrame.size];
	
	// Update the row header view's size
	NSRect rowHeaderFrame = [rowHeaderView frame];
	rowHeaderFrame.size.height = contentRect.size.height;
	if(![[contentScrollView horizontalScroller] isHidden]) {
		columnHeaderFrame.size.height += [NSScroller scrollerWidth];
	}
	[rowHeaderView setFrameSize:rowHeaderFrame.size];
	
  [self updateLayout];
	[self setNeedsDisplay:YES];
}

#pragma mark Layout Support

- (NSRect)rectOfColumn:(NSUInteger)columnIndex
{
	NSRect rect = [self convertRect:[contentView rectOfColumn:columnIndex] fromView:contentView];
	rect.origin.y = 0;
  if (![columnHeaderView isHidden]) {
    rect.size.height += MBTableGridColumnHeaderHeight;
  }
	if(rect.size.height > [self frame].size.height) {
		rect.size.height = [self frame].size.height;
		
		// If the scrollbar is visible, don't include it in the rect.
    // TODO: incorrect with active embedded scrollers in Lion and newer.
		if(![[contentScrollView horizontalScroller] isHidden]) {
			rect.size.height -= [NSScroller scrollerWidth];
		}
	}
	
	return rect;
}

- (NSRect)rectOfRow:(NSUInteger)rowIndex
{
	NSRect rect = [self convertRect:[contentView rectOfRow:rowIndex] fromView:contentView];
	rect.origin.x = 0;
  if (![rowHeaderView isHidden]) {
    rect.size.width += MBTableGridRowHeaderWidth;
  }
	
	return rect;
}

- (NSRect)frameOfCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
	return [self convertRect:[contentView frameOfCellAtColumn:columnIndex row:rowIndex] fromView:contentView];
}

- (NSRect)headerRectOfColumn:(NSUInteger)columnIndex
{
	return [self convertRect:[columnHeaderView headerRectOfColumn:columnIndex] fromView:columnHeaderView];
}

- (NSRect)headerRectOfRow:(NSUInteger)rowIndex
{
	return [self convertRect:[rowHeaderView headerRectOfColumn:rowIndex] fromView:rowHeaderView];
}

- (NSRect)headerRectOfCorner
{
	NSRect rect = NSMakeRect(0, 0, MBTableGridRowHeaderWidth, MBTableGridColumnHeaderHeight);
	return rect;
}

- (NSInteger)columnAtPoint:(NSPoint)aPoint
{
	NSUInteger column = 0;
	while(column < [self numberOfColumns]) {
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
	while(row < [self numberOfRows]) {
		NSRect rowFrame = [self rectOfRow:row];
		if(NSPointInRect(aPoint, rowFrame)) {
			return row;
		}
		row++;
	}
	return NSNotFound;
}

- (void)scrollRowToVisible: (NSInteger)rowIndex
{
  NSRect visibleRect = [contentScrollView documentVisibleRect];
  NSRect rowFrame = [self rectOfRow: rowIndex];
  if (![columnHeaderView isHidden]) {
    rowFrame.origin.y -= MBTableGridColumnHeaderHeight;
  }
  if (rowFrame.origin.y < 0) {
    // Row is above the visible area (keep in mind we are flipped).
		[[contentScrollView contentView] scrollToPoint:
     NSMakePoint(visibleRect.origin.x, visibleRect.origin.y + rowFrame.origin.y)];
    [contentScrollView reflectScrolledClipView: [contentScrollView contentView]];
  }
  if (NSMaxY(rowFrame) > visibleRect.size.height) {
    // Row is below the visible area.
		[[contentScrollView contentView] scrollToPoint:
     NSMakePoint(visibleRect.origin.x, visibleRect.origin.y + NSMaxY(rowFrame) - visibleRect.size.height)];
    [contentScrollView reflectScrolledClipView: [contentScrollView contentView]];
  }
}

- (void)scrollColumnToVisible: (NSInteger)columnIndex
{
  NSRect visibleRect = [contentScrollView documentVisibleRect];
  NSRect columnFrame = [self rectOfColumn: columnIndex];
  if (![rowHeaderView isHidden]) {
    columnFrame.origin.x -= MBTableGridRowHeaderWidth;
  }
  if (columnFrame.origin.x < 0) {
		[[contentScrollView contentView] scrollToPoint:
     NSMakePoint(visibleRect.origin.x + columnFrame.origin.x, visibleRect.origin.y)];
    [contentScrollView reflectScrolledClipView: [contentScrollView contentView]];
  }
  if (NSMaxX(columnFrame) > visibleRect.size.width) {
		[[contentScrollView contentView] scrollToPoint:
     NSMakePoint(visibleRect.origin.x + NSMaxX(columnFrame) - visibleRect.size.width, visibleRect.origin.y)];
    [contentScrollView reflectScrolledClipView: [contentScrollView contentView]];
  }
}

- (void)updateLayout
{
  NSRect frame = contentScrollView.frame;
  CGFloat contentWidth = frame.size.width;
  CGFloat contentHeight = frame.size.height;
  CGFloat leftOffset = frame.origin.x;
  CGFloat topOffset = frame.origin.y;

  BOOL horizontalChanged = NO;
  if ([rowHeaderView isHidden] != (leftOffset == 0)) {
    horizontalChanged = YES;
    if (leftOffset > 0) {
      contentWidth += MBTableGridRowHeaderWidth;
      leftOffset = 0;
    } else {
      contentWidth -= MBTableGridRowHeaderWidth;
      leftOffset = MBTableGridRowHeaderWidth;
    }
  }
  
  BOOL verticalChanged = NO; 
  if ([columnHeaderView isHidden] != (topOffset == 0)) {
    verticalChanged = YES;
    if (topOffset > 0) {
      contentHeight += MBTableGridColumnHeaderHeight;
      topOffset = 0;
    } else {
      contentHeight -= MBTableGridColumnHeaderHeight;
      topOffset = MBTableGridRowHeaderWidth;
    }
  }
  
  if (horizontalChanged || verticalChanged) {
    if (horizontalChanged) {
      NSRect columnHeaderFrame = NSMakeRect(leftOffset, 0, contentWidth, MBTableGridColumnHeaderHeight);
      [columnHeaderScrollView setFrame: columnHeaderFrame];
    }
    if (verticalChanged) {
      NSRect rowHeaderFrame = NSMakeRect(0, topOffset, MBTableGridRowHeaderWidth, contentHeight);
      [rowHeaderScrollView setFrame: rowHeaderFrame];
    }
    frame = NSMakeRect(leftOffset, topOffset, contentWidth, contentHeight);
    [contentScrollView setFrame: frame];
  }
}

#pragma mark Auxiliary Views

- (MBTableGridHeaderView *)columnHeaderView
{
	return columnHeaderView;
}

- (MBTableGridHeaderView *)rowHeaderView
{
	return rowHeaderView;
}

- (MBTableGridContentView *)contentView
{
	return contentView;
}

- (SynchronousScrollView *)contentScrollView
{
  return contentScrollView;
}

@end

@implementation MBTableGrid (OverriddenPropertyAccessors)
// ml: property setters defined here previously caused Apple Mach-O Linker warnings so
// they were moved to the main impl.
@end

@implementation MBTableGrid (Drawing)

- (void)_drawColumnHeaderBackgroundInRect:(NSRect)aRect
{
	if ([self needsToDrawRect:aRect]) {
		NSColor *topGradientTop = [NSColor colorWithDeviceWhite:0.91 alpha:1.0];
		NSColor *topGradientBottom = [NSColor colorWithDeviceWhite:0.89 alpha:1.0];
		NSColor *bottomGradientTop = [NSColor colorWithDeviceWhite:0.85 alpha:1.0];
		NSColor *bottomGradientBottom = [NSColor colorWithDeviceWhite:0.83 alpha:1.0];
		NSColor *topColor = [NSColor colorWithDeviceWhite:0.95 alpha:1.0];
		NSColor *borderColor = [NSColor colorWithDeviceWhite:0.65 alpha:1.0];
		
		NSGradient *topGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:topGradientTop, topGradientBottom, nil]];
		NSGradient *bottomGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:bottomGradientTop, bottomGradientBottom, nil]];
		
		NSRect topRect = NSMakeRect(NSMinX(aRect), 0, NSWidth(aRect), NSHeight(aRect)/2);
		NSRect bottomRect = NSMakeRect(NSMinX(aRect), NSMidY(aRect)-0.5, NSWidth(aRect), NSHeight(aRect)/2+0.5);
		
		// Draw the gradients
		[topGradient drawInRect:topRect angle:90.0];
		[bottomGradient drawInRect:bottomRect angle:90.0];
		
		// Draw the top bevel line
		NSRect topLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect), 1.0);
		[topColor set];
		NSRectFill(topLine);
		
		// Draw the bottom border
		[borderColor set];
		NSRect bottomLine = NSMakeRect(NSMinX(aRect), NSMaxY(aRect)-1.0, NSWidth(aRect), 1.0);
		NSRectFill(bottomLine);
		
		[topGradient release];
		[bottomGradient release];
	}
}

- (void)_drawRowHeaderBackgroundInRect:(NSRect)aRect
{
	if ([self needsToDrawRect:aRect]) {
		NSColor *topGradientTop = [NSColor colorWithDeviceWhite:0.91 alpha:1.0];
		NSColor *topGradientBottom = [NSColor colorWithDeviceWhite:0.89 alpha:1.0];
		NSColor *bottomGradientTop = [NSColor colorWithDeviceWhite:0.85 alpha:1.0];
		NSColor *bottomGradientBottom = [NSColor colorWithDeviceWhite:0.83 alpha:1.0];
		NSColor *sideColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.4];
		NSColor *borderColor = [NSColor colorWithDeviceWhite:0.65 alpha:1.0];
		
		NSGradient *topGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:topGradientTop, topGradientBottom, nil]];
		NSGradient *bottomGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:bottomGradientTop, bottomGradientBottom, nil]];
	
		NSRect leftRect = NSMakeRect(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect)/2, NSHeight(aRect));
		NSRect rightRect = NSMakeRect(NSMidX(aRect)-0.5, NSMinY(aRect), NSWidth(aRect)/2+0.5, NSHeight(aRect));
		
		// Draw the gradients
		[topGradient drawInRect:leftRect angle:0.0];
		[bottomGradient drawInRect:rightRect angle:0.0];
		
		// Draw the left bevel line
		NSRect leftLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), 1.0, NSHeight(aRect));
		[sideColor set];
		[[NSBezierPath bezierPathWithRect:leftLine] fill];
		
		// Draw the right border
		[borderColor set];
		NSRect rightLine = NSMakeRect(NSMaxX(aRect)-1, NSMinY(aRect), 1.0, NSHeight(aRect));
		NSRectFill(rightLine);
		
		[topGradient release];
		[bottomGradient release];
	}
}

- (void)_drawCornerHeaderBackgroundInRect:(NSRect)aRect
{
	if ([self needsToDrawRect:aRect]) {
		NSColor *topGradientTop = [NSColor colorWithDeviceWhite:0.91 alpha:1.0];
		NSColor *topGradientBottom = [NSColor colorWithDeviceWhite:0.89 alpha:1.0];
		NSColor *bottomGradientTop = [NSColor colorWithDeviceWhite:0.85 alpha:1.0];
		NSColor *bottomGradientBottom = [NSColor colorWithDeviceWhite:0.83 alpha:1.0];
		NSColor *topColor = [NSColor colorWithDeviceWhite:0.95 alpha:1.0];
		NSColor *sideColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.4];
		NSColor *borderColor = [NSColor colorWithDeviceWhite:0.65 alpha:1.0];
		
		NSGradient *topGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:topGradientTop, topGradientBottom, nil]];
		NSGradient *bottomGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:bottomGradientTop, bottomGradientBottom, nil]];
		
		// Divide the frame in two
		NSRect mainRect = aRect;
		NSRect bottomRightRect = NSMakeRect(NSMidX(aRect)-0.5, NSMidY(aRect)-0.5, NSWidth(aRect)/2, NSHeight(aRect)/2+0.5);
		
		// Draw the gradients
		[topGradient drawInRect:mainRect angle:90.0];
		[bottomGradient drawInRect:bottomRightRect angle:90.0];
		
		// Draw the top bevel line
		NSRect topLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect), 1.0);
		[topColor set];
		NSRectFill(topLine);
		
		// Draw the left bevel line
		NSRect leftLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), 1.0, NSHeight(aRect));
		[sideColor set];
		[[NSBezierPath bezierPathWithRect:leftLine] fill];
		
		// Draw the right border
		[borderColor set];
		NSRect borderLine = NSMakeRect(NSMaxX(aRect)-1, NSMinY(aRect), 1.0, NSHeight(aRect));
		NSRectFill(borderLine);
		
		// Draw the bottom border
		NSRect bottomLine = NSMakeRect(NSMinX(aRect), NSMaxY(aRect)-1.0, NSWidth(aRect), 1.0);
		NSRectFill(bottomLine);
		
		[topGradient release];
		[bottomGradient release];
	}
}

@end

@implementation MBTableGrid (DataAccessors)

- (NSString *)_headerStringForColumn:(NSUInteger)columnIndex
{
	// Ask the data source
	if([[self dataSource] respondsToSelector:@selector(tableGrid:headerStringForColumn:)]) {
		return [[self dataSource] tableGrid:self headerStringForColumn:columnIndex];
	}
	
	char alphabetChar = columnIndex + 'A';
	return [NSString stringWithFormat:@"%c", alphabetChar];
}

- (NSString *)_headerStringForRow:(NSUInteger)rowIndex
{
	// Ask the data source
	if([[self dataSource] respondsToSelector:@selector(tableGrid:headerStringForRow:)]) {
		return [[self dataSource] tableGrid:self headerStringForRow:rowIndex];
	}
	
	return [NSString stringWithFormat:@"%i", (rowIndex+1)];
}

- (id)_objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:objectValueForColumn:row:)]) {
		id value = [[self dataSource] tableGrid:self objectValueForColumn:columnIndex row:rowIndex];
		return value;
	} else {
		NSLog(@"WARNING: MBTableGrid data source does not implement tableGrid:objectValueForColumn:row:");
	}
	return nil;
}

- (void)_setObjectValue:(id)value forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:setObjectValue:forColumn:row:)]) {
		[[self dataSource] tableGrid:self setObjectValue:value forColumn:columnIndex row:rowIndex];
	}
}

- (BOOL)_canEditCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
	// Can't edit if the data source doesn't implement the method
	if (![[self dataSource] respondsToSelector:@selector(tableGrid:setObjectValue:forColumn:row:)]) {
		return NO;
	}
	
	// Ask the delegate if the cell is editable
	if ([[self delegate] respondsToSelector:@selector(tableGrid:shouldEditColumn:row:)]) {
		return [[self delegate] tableGrid:self shouldEditColumn:columnIndex row:rowIndex];
	}
	
	return YES;
}

@end

@implementation MBTableGrid (PrivateAccessors)

- (MBTableGridContentView *)_contentView
{
	return contentView;
}

- (void)_setStickyColumn:(MBTableGridEdge)stickyColumn row:(MBTableGridEdge)stickyRow
{
	stickyColumnEdge = stickyColumn;
	stickyRowEdge = stickyRow;
}

- (MBTableGridEdge)_stickyColumn
{
	return stickyColumnEdge;
}

- (MBTableGridEdge)_stickyRow
{
	return stickyRowEdge;
}

@end

@implementation MBTableGrid (DragAndDrop)

- (void)_dragColumnsWithEvent:(NSEvent *)theEvent
{
	NSImage *dragImage = [self _imageForSelectedColumns];
	
	NSRect firstSelectedColumn = [self rectOfColumn:[self.selectedColumnIndexes firstIndex]];
	NSPoint location = firstSelectedColumn.origin;
	location.y += [dragImage size].height;
	
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[pboard declareTypes:[NSArray arrayWithObjects:MBTableGridColumnDataType, nil] owner:self];
	
	BOOL shouldDrag = NO;
	if([[self dataSource] respondsToSelector:@selector(tableGrid:writeColumnsWithIndexes:toPasteboard:)]) {
		shouldDrag = [[self dataSource] tableGrid:self writeColumnsWithIndexes:self.selectedColumnIndexes toPasteboard:pboard];
	}
	
	if(shouldDrag) {
		// Set the column drag type
		[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:self.selectedColumnIndexes] forType:MBTableGridColumnDataType];
		
		[self dragImage:dragImage at:location offset:NSZeroSize event:theEvent pasteboard:pboard source:self slideBack:YES];
	}
}

- (void)_dragRowsWithEvent:(NSEvent *)theEvent
{
	NSImage *dragImage = [self _imageForSelectedRows];
	
	NSRect firstSelectedRow = [self rectOfRow:[self.selectedRowIndexes firstIndex]];
	NSPoint location = firstSelectedRow.origin;
	location.y += [dragImage size].height;
	
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[pboard declareTypes:[NSArray arrayWithObjects:MBTableGridRowDataType, nil] owner:self];
	
	BOOL shouldDrag = NO;
	if([[self dataSource] respondsToSelector:@selector(tableGrid:writeRowsWithIndexes:toPasteboard:)]) {
		shouldDrag = [[self dataSource] tableGrid:self writeRowsWithIndexes:self.selectedRowIndexes toPasteboard:pboard];
	}
	
	if(shouldDrag) {
		// Set the column drag type
		[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:self.selectedRowIndexes] forType:MBTableGridRowDataType];
		
		[self dragImage:dragImage at:location offset:NSZeroSize event:theEvent pasteboard:pboard source:self slideBack:YES];
	}
}

- (NSImage *)_imageForSelectedColumns
{
	NSRect firstColumnFrame = [self rectOfColumn:[self.selectedColumnIndexes firstIndex]];
	NSRect lastColumnFrame = [self rectOfColumn:[self.selectedColumnIndexes lastIndex]];
	NSRect columnsFrame = NSMakeRect(NSMinX(firstColumnFrame), NSMinY(firstColumnFrame), NSMaxX(lastColumnFrame) - NSMinX(firstColumnFrame), NSHeight(firstColumnFrame));
	// Extend the frame to show the left border
	columnsFrame.origin.x -= 1.0;
	columnsFrame.size.width += 1.0;

	// Take a snapshot of the view
	NSImage *opaqueImage = [[NSImage alloc] initWithData:[self dataWithPDFInsideRect:columnsFrame]];
	
	// Create the translucent drag image
	NSImage *finalImage = [[NSImage alloc] initWithSize:[opaqueImage size]];
	[finalImage lockFocus];
	[opaqueImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.7];
	[finalImage unlockFocus];
	[opaqueImage release];
	
	return [finalImage autorelease];
}

- (NSImage *)_imageForSelectedRows
{
	NSRect firstRowFrame = [self rectOfRow:[self.selectedRowIndexes firstIndex]];
	NSRect lastRowFrame = [self rectOfRow:[self.selectedRowIndexes lastIndex]];
	NSRect rowsFrame = NSMakeRect(NSMinX(firstRowFrame), NSMinY(firstRowFrame), NSWidth(firstRowFrame), NSMaxY(lastRowFrame) - NSMinY(firstRowFrame));
	// Extend the frame to show the top border
	rowsFrame.origin.y -= 1.0;
	rowsFrame.size.height += 1.0;
	
	// Take a snapshot of the view
	NSImage *opaqueImage = [[NSImage alloc] initWithData:[self dataWithPDFInsideRect:rowsFrame]];
	
	// Create the translucent drag image
	NSImage *finalImage = [[NSImage alloc] initWithSize:[opaqueImage size]];
	[finalImage lockFocus];
	[opaqueImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.7];
	[finalImage unlockFocus];
	[opaqueImage release];
	
	return [finalImage autorelease];
}

- (NSUInteger)_dropColumnForPoint:(NSPoint)aPoint
{
	NSUInteger column = [self columnAtPoint:aPoint];
	
	if(column == NSNotFound) {
		return NSNotFound;
	}
	
	// If we're in the right half of the column, we intent to drop on the right side
	NSRect columnFrame = [self rectOfColumn:column];
	columnFrame.size.width /= 2;
	if (!NSPointInRect(aPoint, columnFrame)) {
		column++;
	}
	
	return column;
}

- (NSUInteger)_dropRowForPoint:(NSPoint)aPoint
{
	NSUInteger row = [self rowAtPoint:aPoint];
	
	if(row == NSNotFound) {
		return NSNotFound;
	}
	
	// If we're in the bottom half of the row, we intent to drop on the bottom side
	NSRect rowFrame = [self rectOfRow:row];
	rowFrame.size.height /= 2;

	if (!NSPointInRect(aPoint, rowFrame)) {
		row++;
	}
	
	return row;
}

@end