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

#import <Cocoa/Cocoa.h>

#define MBTableGridDefaultColumnHeaderHeight 19.0
#define MBTableGridDefaultRowHeaderWidth 40.0

@class MBTableGrid, MBTableGridCell;

/**
 * @brief		\c MBTableGridContentView provides the actual display
 *				and editing capabilities of MBTableGrid. It is designed
 *				to be placed inside a scroll view.
 */
@interface MBTableGridContentView : NSView {
	NSInteger mouseDownColumn;
	NSInteger mouseDownRow;
	
	NSInteger editedColumn;
	NSInteger editedRow;
	
	NSImage *cursorImage;
	
	NSInteger dropColumn;
	NSInteger dropRow;
	
	NSTimer *autoscrollTimer;
	
	BOOL isDraggingColumnOrRow;
}

/**
 * @name		The Grid View
 */
/**
 * @{
 */

/**
 * @brief		Returns the \c MBTableGrid the receiver 
 *				belongs to.
 */
- (MBTableGrid *)tableGrid;

/**
 * @}
 */

/**
 * @name		Editing Values
 */
/**
 * @{
 */

/**
 * @brief		Begin editing the currently-selected
 *				cell. If multiple cells are selected,
 *				selects the top-left one and begins
 *				editing its value.
 */
- (void)editSelectedCell:(id)sender;

- (void)cancelEditing;

/**
 * @}
 */

/**
 * @name		Layout Support
 */
/**
 * @{
 */

/**
 * @brief		Returns the rectangle containing the column at
 *				a given index.
 * @param		columnIndex	The index of a column in the receiver.
 * @return		The rectangle containing the column at \c columnIndex.
 *				Returns \c NSZeroRect if \c columnIndex lies outside
 *				the range of valid column indices for the receiver.
 * @see			frameOfCellAtColumn:row:
 * @see			rectOfRow:
 */
- (NSRect)rectOfColumn:(NSInteger)columnIndex;

/**
 * @brief		Returns the rectangle containing the row at a
 *				given index.
 * @param		rowIndex	The index of a row in the receiver.
 * @return		The rectangle containing the row at \c rowIndex.
 *				Returns \c NSZeroRect if \c rowIndex lies outside
 *				the range of valid column indices for the receiver.
 * @see			frameOfCellAtColumn:row:
 * @see			rectOfColumn:
 */
- (NSRect)rectOfRow:(NSInteger)rowIndex;

/**
 * @brief		Returns a rectangle locating the cell that lies at
 *				the intersection of \c columnIndex and \c rowIndex.
 * @param		columnIndex	The index of the column containing the cell
 *							whose rectangle you want.
 * @param		rowIndex	The index of the row containing the cell
 *							whose rectangle you want.
 * @return		A rectangle locating the cell that lies at the intersection
 *				of \c columnIndex and \c rowIndex. Returns \c NSZeroRect if
 *				\c columnIndex or \c rowIndex is greater than the number of
 *				columns or rows in the receiver.
 * @see			rectOfColumn:
 * @see			rectOfRow:
 */
- (NSRect)frameOfCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @brief		Returns the index of the column a given point lies in.
 * @param		aPoint		A point in the coordinate system of the receiver.
 * @return		The index of the column \c aPoint lies in, or \c NSNotFound if \c aPoint
 *				lies outside the receiver's bounds.
 * @see			rowAtPoint:
 */
- (NSInteger)columnAtPoint:(NSPoint)aPoint;

/**
 * @brief		Returns the index of the row a given point lies in.
 * @param		aPoint		A point in the coordinate system of the receiver.
 * @return		The index of the row \c aPoint lies in, or \c NSNotFound if \c aPoint
 *				lies outside the receiver's bounds.
 * @see			columnAtPoint:
 */
- (NSInteger)rowAtPoint:(NSPoint)aPoint;

/**
 * @}
 */

@end
