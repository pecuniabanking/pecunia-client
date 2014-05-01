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

@class SynchronousScrollView;

@class MBTableGridHeaderView, MBTableGridHeaderCell, MBTableGridContentView;
@protocol MBTableGridDelegate, MBTableGridDataSource;

/* Notifications */

/**
 * @brief		Posted after an MBTableGrid object's selection changes.
 *				The notification object is the table grid whose selection
 *				changed. This notification does not contain a userInfo
 *				dictionary.
 *
 * @details		This notification will often be posted twice for a single
 *				selection change (once for the column selection and once 
 *				for the row selection). As such, any methods called in
 *				response to this notification should be especially efficient.
 */
APPKIT_EXTERN NSString *MBTableGridDidChangeSelectionNotification;

/**
 * @brief		Posted after one or more columns are moved by user action
 *				in an MBTableGrid object. The notification object is
 *				the table grid in which the column(s) moved. The \c userInfo
 *				dictionary contains the following information:
 *				- \c @"OldColumns": An NSIndexSet containing the columns'
 *					original indices.
 *				- \c @"NewColumns": An NSIndexSet containing the columns'
 *					new indices.
 */
APPKIT_EXTERN NSString *MBTableGridDidMoveColumnsNotification;

/**
 * @brief		Posted after one or more rows are moved by user action
 *				in an MBTableGrid object. The notification object is
 *				the table grid in which the row(s) moved. The userInfo
 *				dictionary contains the following information:
 *				- \c @"OldRows": An NSIndexSet containing the rows'
 *					original indices.
 *				- \c @"NewRows": An NSIndexSet containing the rows'
 *					new indices.
 */
APPKIT_EXTERN NSString *MBTableGridDidMoveRowsNotification;

APPKIT_EXTERN NSString *MBTableGridColumnDataType;
APPKIT_EXTERN NSString *MBTableGridRowDataType;

typedef enum {
	MBTableGridLeftEdge		= 0,
	MBTableGridRightEdge	= 1,
	MBTableGridTopEdge		= 3,
	MBTableGridBottomEdge	= 4
} MBTableGridEdge;

/**
 * @brief		MBTableGrid (sometimes referred to as a table grid)
 *				is a means of displaying tabular data in a spreadsheet
 *				format.
 *
 * @details		An MBTableGrid object must have an object that acts
 *				as a data source and may optionally have an object which
 *				acts as a delegate. The data source must adopt the
 *				MBTableGridDataSource protocol, and the delegate must
 *				adopt the MBTableGridDelegate protocol. The data source
 *				provides information that MBTableGrid needs to construct
 *				the table grid and facillitates the insertion, deletion, and
 *				reordering of data within it. The delegate optionally provides
 *				formatting and validation information. For more information
 *				on these, see the MBTableGridDataSource and MBTableGridDelegate
 *				protocols.
 *
 *				MBTableGrid and its methods actually encompass
 *				several subviews, including MBTableGridContentView
 *				(which handles the display, selection, and editing of
 *				cells) and MBTableGridHeaderView (which handles
 *				the display, selection, and dragging of column and
 *				row headers). In general, however, it is not necessary
 *				to interact with these views directly.
 *
 * @author		Matthew Ball
 */
@interface MBTableGrid : NSControl {
	/* Headers */
	MBTableGridHeaderCell *headerCell;
	
	/* Data Source */
	IBOutlet id <MBTableGridDataSource> __weak dataSource;
	
	/* Delegate */
	IBOutlet id <MBTableGridDelegate> __weak delegate;
	
	/* Headers */
	NSScrollView *columnHeaderScrollView;
	MBTableGridHeaderView *columnHeaderView;
	NSScrollView *rowHeaderScrollView;
	MBTableGridHeaderView *rowHeaderView;
	
	/* Content */
	SynchronousScrollView *contentScrollView;
	MBTableGridContentView *contentView;
	
	/* Selections */
	NSIndexSet *selectedColumnIndexes;
	NSIndexSet *selectedRowIndexes;
	
	/* Behavior */
	BOOL allowsMultipleSelection;
	BOOL shouldOverrideModifiers;
	
	/* Sticky Edges (for Shift+Arrow expansions) */
	MBTableGridEdge stickyColumnEdge;
	MBTableGridEdge stickyRowEdge;
}

/**
 * Relayout the subviews of the grid. Call this after hiding/re-showing row or column headers.
 */
- (void)updateLayout;

#pragma mark -
#pragma mark Reloading the Grid

/**
 * @name		Reloading the Grid
 */
/**
 * @{
 */

/**
 * @brief		Marks the receiver as needing redisplay, so
 *				it will reload the data for visible cells and
 *				draw the new values.
 *
 * @details		This method forces redraw of all the visible
 *				cells in the receiver. If you want to update
 *				the value in a single cell, column, or row,
 *				it is more efficient to use \c frameOfCellAtColumn:row:,
 *				\c rectOfColumn:, or \c rectOfRow: in conjunction with
 *				\c setNeedsDisplayInRect:.
 *
 * @see			frameOfCellAtColumn:row:
 * @see			rectOfColumn:
 * @see			rectOfRow:
 */
- (void)reloadData;

/**
 * @}
 */

#pragma mark -
#pragma mark Selecting Columns and Rows

/**
 * @name		Selecting Columns and Rows
 */
/**
 * @{
 */

/**
 * @brief		Returns an index set containing the indexes of
 *				the selected columns.
 *
 * @return		An index set containing the indexes of the
 *				selected columns.
 *
 * @see			selectedRowIndexes
 * @see			selectCellsInColumns:rows:
 */
@property (nonatomic, strong) NSIndexSet *selectedColumnIndexes;

/**
 * @brief		Returns an index set containing the indexes of
 *				the selected rows.
 *
 * @return		An index set containing the indexes of the
 *				selected rows.
 *
 * @see			selectedColumnIndexes
 * @see			selectCellsInColumns:rows:
 */
@property (nonatomic, strong) NSIndexSet *selectedRowIndexes;

/**
 * @}
 */

#pragma mark -
#pragma mark Dimensions

/**
 * @name		Dimensions
 */
/**
 * @{
 */

/**
 * @brief		Returns the number of rows in the receiver.
 *
 * @return		The number of rows in the receiver.
 *
 * @see			numberOfColumns
 */
- (NSUInteger)numberOfRows;

/**
 * @brief		Returns the number of columns in the receiver.
 *
 * @return		The number of rows in the receiver.
 *
 * @see			numberOfRows
 */
- (NSUInteger)numberOfColumns;

/**
 * @}
 */

#pragma mark -
#pragma mark Configuring Behavior

/**
 * @name		Configuring Behavior
 */
/**
 * @{
 */

/**
 * @brief		Indicates whether the receiver allows
 *				the user to select more than one cell at
 *				a time.
 *
 * @details		The default is \c YES. You can select multiple
 *				cells programmatically regardless of this setting.
 *
 * @return		\c YES if the receiver allows the user
 *				to select more than one cell at a time.
 *				Otherwise, \c NO.
 */
@property(assign) BOOL allowsMultipleSelection;

/**
 * @brief		Indicates whether the receiver should draw the selection ring around selected cells.
 *
 */
@property(assign) BOOL showSelectionRing;

/**
 * @}
 */

#pragma mark -
#pragma mark Managing the Delegate and the Data Source
/**
 * @name		Managing the Delegate and the Data Source
 */
/**
 * @{
 */

/**
 * @brief		The object that provides the data displayed by
 *				the grid.
 *
 * @details		The data source must adopt the \c MBTableGridDataSource
 *				protocol. The data source is not retained.
 *
 * @see			delegate
 */
@property(weak) id <MBTableGridDataSource> dataSource;

/**
 * @brief		The object that acts as the delegate of the 
 *				receiving table grid.
 *
 * @details		The delegate must adopt the \c MBTableGridDelegate
 *				protocol. The delegate is not retained.
 *
 * @see			dataSource
 */
@property (nonatomic, weak) id <MBTableGridDelegate> delegate;

/**
 * @brief	The default size for a cell (which determines the width of columns and the height of rows.
 */
@property (nonatomic, assign) NSSize defaultCellSize;

/**
 * @brief	The default width for the row header and the height for the column header.
 */
@property (nonatomic, assign) NSSize defaultHeaderSize;

/**
 * @}
 */

#pragma mark -
#pragma mark Layout Support
/**
 * @name		Layout Support
 */
/**
 * @{
 */

/**
 * @brief		Returns the rectangle containing the column at
 *				a given index.
 *
 * @param		columnIndex	The index of a column in the receiver.
 *
 * @return		The rectangle containing the column at \c columnIndex.
 *				Returns \c NSZeroRect if \c columnIndex lies outside
 *				the range of valid column indices for the receiver.
 *
 * @see			frameOfCellAtColumn:row:
 * @see			rectOfRow:
 * @see			headerRectOfColumn:
 */
- (NSRect)rectOfColumn:(NSUInteger)columnIndex;

/**
 * @brief		Returns the rectangle containing the row at a
 *				given index.
 *
 * @param		rowIndex	The index of a row in the receiver.
 *
 * @return		The rectangle containing the row at \c rowIndex.
 *				Returns \c NSZeroRect if \c rowIndex lies outside
 *				the range of valid column indices for the receiver.
 *
 * @see			frameOfCellAtColumn:row:
 * @see			rectOfColumn:
 * @see			headerRectOfRow:
 */
- (NSRect)rectOfRow:(NSUInteger)rowIndex;

/**
 * @brief		Returns a rectangle locating the cell that lies at
 *				the intersection of \c columnIndex and \c rowIndex.
 *
 * @param		columnIndex	The index of the column containing the cell
 *							whose rectangle you want.
 * @param		rowIndex	The index of the row containing the cell
 *							whose rectangle you want.
 *
 * @return		A rectangle locating the cell that lies at the intersection
 *				of \c columnIndex and \c rowIndex. Returns \c NSZeroRect if
 *				\c columnIndex or \c rowIndex is greater than the number of
 *				columns or rows in the receiver.
 *
 * @see			rectOfColumn:
 * @see			rectOfRow:
 * @see			headerRectOfColumn:
 * @see			headerRectOfRow:
 */
- (NSRect)frameOfCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @brief		Returns the rectangle containing the header tile for
 *				the column at \c columnIndex.
 *
 * @param		columnIndex	The index of the column containing the
 *							header whose rectangle you want.
 *
 * @return		A rectangle locating the header for the column at
 *				\c columnIndex. Returns \c NSZeroRect if \c columnIndex 
 *				lies outside the range of valid column indices for the 
 *				receiver.
 *
 * @see			headerRectOfRow:
 * @see			headerRectOfCorner
 */
- (NSRect)headerRectOfColumn:(NSUInteger)columnIndex;

/**
 * @brief		Returns the rectangle containing the header tile for
 *				the row at \c rowIndex.
 *
 * @param		rowIndex	The index of the row containing the
 *							header whose rectangle you want.
 *
 * @return		A rectangle locating the header for the row at
 *				\c rowIndex. Returns \c NSZeroRect if \c rowIndex 
 *				lies outside the range of valid column indices for the 
 *				receiver.
 *
 * @see			headerRectOfColumn:
 * @see			headerRectOfCorner
 */
- (NSRect)headerRectOfRow:(NSUInteger)rowIndex;

/**
 * @brief		Returns the rectangle containing the corner which
 *				divides the row headers from the column headers.
 *
 * @return		A rectangle locating the corner separating rows
 *				from columns.
 *
 * @see			headerRectOfColumn:
 * @see			headerRectOfRow:
 */
- (NSRect)headerRectOfCorner;

/**
 * @brief		Returns the index of the column a given point lies in.
 *
 * @param		aPoint		A point in the coordinate system of the receiver.
 *
 * @return		The index of the column \c aPoint lies in, or \c NSNotFound if \c aPoint
 *				lies outside the receiver's bounds.
 *
 * @see			rowAtPoint:
 */
- (NSInteger)columnAtPoint:(NSPoint)aPoint;

/**
 * @brief		Returns the index of the row a given point lies in.
 *
 * @param		aPoint		A point in the coordinate system of the receiver.
 *
 * @return		The index of the row \c aPoint lies in, or \c NSNotFound if \c aPoint
 *				lies outside the receiver's bounds.
 *
 * @see			columnAtPoint:
 */
- (NSInteger)rowAtPoint:(NSPoint)aPoint;

/**
 * If the given row/column is not in the visible area then scroll it so it becomes visible.
 */
- (void)scrollRowToVisible: (NSInteger)rowIndex;
- (void)scrollColumnToVisible: (NSInteger)columnIndex;

/**
 * @}
 */

#pragma mark -
#pragma mark Auxiliary Views
/**
 * @name		Auxiliary Views
 */
/**
 * @{
 */

/**
 * @brief		Returns the \c MBTableGridHeaderView object used
 *				to draw headers over columns.
 *
 * @return		The \c MBTableGridHeaderView object used to draw
 *				column headers.
 *
 * @see			rowHeaderView
 */
- (MBTableGridHeaderView *)columnHeaderView;

/**
 * @brief		Returns the \c MBTableGridHeaderView object used
 *				to draw headers beside rows.
 *
 * @return		The \c MBTableGridHeaderView object used to draw
 *				column headers.
 *
 * @see			columnHeaderView
 */
- (MBTableGridHeaderView *)rowHeaderView;

/**
 * @brief		Returns the receiver's content view.
 *
 * @details		An \c MBTableGrid object uses its content view to
 *				draw the individual cells. It is enclosed in a
 *				scroll view to allow for scrolling.
 *
 * @return		The receiver's content view.
 */
- (MBTableGridContentView *)contentView;

/**
 * @}
 */

- (SynchronousScrollView *)contentScrollView;
@end

#pragma mark -

/**
 * @brief		The \c MBTableGridDataSource protocol is adopted
 *				by an object that mediates the data model for an
 *				\c MBTableGrid object. 
 *
 * @details		As a representative of the data model, the data 
 *				source supplies no information about the grid's
 *				appearance or behavior. Rather, the grid's
 *				delegate (adopting the \c MBTableGridDelegate
 *				protocol) can provide that information.
 */
@protocol MBTableGridDataSource <NSObject>

@required

#pragma mark -
#pragma mark Dimensions

/**
 * @name		Dimensions
 */
/**
 * @{
 */

@required

/**
 * @brief		Returns the number of rows managed for \c aTableGrid
 *				by the data source object.
 *
 * @param		aTableGrid		The table grid that sent the message.
 *
 * @return		The number of rows in \c aTableGrid.
 *
 * @see			numberOfColumnsInTableGrid:
 */
- (NSUInteger)numberOfRowsInTableGrid:(MBTableGrid *)aTableGrid;

/**
 * @brief		Returns the number of rows managed for \c aTableGrid
 *				by the data source object.
 *
 * @param		aTableGrid		The table grid that sent the message.
 *
 * @return		The number of rows in \c aTableGrid.
 *
 * @see			numberOfRowsInTableGrid:
 */
- (NSUInteger)numberOfColumnsInTableGrid:(MBTableGrid *)aTableGrid;

/**
 * @}
 */

/**
 * @name		Accessing Cell Values
 */
/**
 * @{
 */

@required

/**
 * @brief		Returns the data object associated with the specified column and row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 * @param		rowIndex		A row in \c aTableGrid.
 *
 * @return		The object for the specified cell of the view.
 *
 * @see			tableGrid:setObjectValue:forColumn:row:
 */
- (id)tableGrid:(MBTableGrid *)aTableGrid objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

@optional

/**
 * @brief		Sets the sata object for an item in a given row in a given column.
 *
 * @details		Although this method is optional, it must be implemented in order
 *				to enable grid editing.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		anObject		The new value for the item.
 * @param		columnIndex		A column in \c aTableGrid.
 * @param		rowIndex		A row in \c aTableGrid.
 *
 * @see			tableGrid:objectValueForColumn:row:
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid setObjectValue:(id)anObject forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @}
 */

/**
 * @name		Header Values
 */
/**
 * @{
 */

@optional

/**
 * @brief		Returns the value which should be displayed in the header
 *				for the specified column.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		The index of the column.
 *
 * @return		The header value for the column.
 *
 * @see			tableGrid:headerStringForRow:
 */
- (NSString *)tableGrid:(MBTableGrid *)aTableGrid headerStringForColumn:(NSUInteger)columnIndex;

/**
 * @brief		Returns the value which should be displayed in the header
 *				for the specified row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndex		The index of the row.
 *
 * @return		The header value for the row.
 *
 * @see			tableGrid:headerStringForColumn:
 */
- (NSString *)tableGrid:(MBTableGrid *)aTableGrid headerStringForRow:(NSUInteger)rowIndex;

/**
 * @}
 */

#pragma mark -
#pragma mark Dragging

/**
 * @name		Dragging
 */
/**
 * @{
 */

@optional

#pragma mark Columns

/**
 * @brief		Returns a Boolean value that indicates whether a column drag operation is allowed.
 *
 * @details		Invoked by \c aTableGrid after it has been determined that a drag should begin,
 *				but before the drag has been started.
 *
 *				To refuse the drag, return \c NO. To start a drag, return \c YES and place the
 *				drag data onto pboard.
 *
 *				If this method returns \c YES, the table grid will automatically place the
 *				relavent information onto the pasteboard for simply reordering columns. Therefore,
 *				you only need to place data onto the pasteboard if you want to enable some other
 *				kind of dragging behavior (such as dragging into the finder as a CSV file).
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndexes	An index set of column numbers that will be participating
 *								in the drag.
 * @param		pboard			The pasteboard to which to write the drag data.
 *
 * @return		\c YES if the drag operation is allowed, \c NO otherwise.
 *
 * @see			tableGrid:writeColumnsWithIndexes:toPasteboard:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid writeColumnsWithIndexes:(NSIndexSet *)columnIndexes toPasteboard:(NSPasteboard *)pboard;

/**
 * @brief		Returns a Boolean value indicating whether the proposed columns can be
 *				moved to the specified index.
 * 
 * @details		This method is invoked by \c MBTableGrid during drag operations. It allows
 *				the data source to define valid drop targets for columns.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndexes	An index set describing the columns which
 *								are currently being dragged.
 * @param		index			The proposed index where the columns should
 *								be moved.
 *
 * @return		\c YES if \c columnIndex is a valid drop target, \c NO otherwise.
 *
 * @see			tableGrid:moveColumns:toIndex:
 * @see			tableGrid:canMoveRows:toIndex:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid canMoveColumns:(NSIndexSet *)columnIndexes toIndex:(NSUInteger)index;

/**
 * @brief		Returns a Boolean value indicating whether the proposed columns
 *				were moved to the specified index.
 *
 * @details		The data source should take care of modifiying the data model to
 *				reflect the changed column order.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndexes	An index set describing the columns which were dragged.
 * @param		index			The index where the columns should be moved.
 *
 * @return		\c YES if the move was successful, otherwise \c NO.
 *
 * @see			tableGrid:canMoveColumns:toIndex:
 * @see			tableGrid:moveRows:toIndex:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid moveColumns:(NSIndexSet *)columnIndexes toIndex:(NSUInteger)index;

#pragma mark Rows

/**
 * @brief		Returns a Boolean value that indicates whether a row drag operation is allowed.
 *
 * @details		Invoked by \c aTableGrid after it has been determined that a drag should begin,
 *				but before the drag has been started.
 *
 *				To refuse the drag, return \c NO. To start a drag, return \c YES and place the
 *				drag data onto \c pboard.
 *
 *				If this method returns \c YES, the table grid will automatically place the
 *				relavent information onto the pasteboard for simply reordering rows. Therefore,
 *				you only need to place data onto the pasteboard if you want to enable some other
 *				kind of dragging behavior (such as dragging into the finder as a CSV).
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndexes		An index set of row numbers that will be participating
 *								in the drag.
 * @param		pboard			The pasteboard to which to write the drag data.
 *
 * @return		\c YES if the drag operation is allowed, \c NO otherwise.
 *
 * @see			tableGrid:writeColumnsWithIndexes:toPasteboard:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard;

/**
 * @brief		Returns a Boolean value indicating whether the proposed rows can be
 *				moved to the specified index.
 * 
 * @details		This method is invoked by \c MBTableGrid during drag operations. It allows
 *				the data source to define valid drop targets for rows.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndexes		An index set describing the rows which
 *								are currently being dragged.
 * @param		index			The proposed index where the rows should
 *								be moved.
 *
 * @return		\c YES if \c rowIndex is a valid drop target, \c NO otherwise.
 *
 * @see			tableGrid:moveRows:toIndex:
 * @see			tableGrid:canMoveColumns:toIndex:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid canMoveRows:(NSIndexSet *)rowIndexes toIndex:(NSUInteger)index;

/**
 * @brief		Returns a Boolean value indicating whether the proposed rows
 *				were moved to the specified index.
 *
 * @details		The data source should take care of modifiying the data model to
 *				reflect the changed row order.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndexes		An index set describing the rows which were dragged.
 * @param		index			The index where the rows should be moved.
 *
 * @return		\c YES if the move was successful, otherwise \c NO.
 *
 * @see			tableGrid:canMoveRows:toIndex:
 * @see			tableGrid:moveColumns:toIndex:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid moveRows:(NSIndexSet *)rowIndexes toIndex:(NSUInteger)index;

#pragma mark Other Values

/**
 * @brief		Used by \c aTableGrid to determine a valid drop target.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		info			An object that contains more information about
 *								this dragging operation.
 * @param		columnIndex		The index of the proposed target column.
 * @param		rowIndex		The index of the proposed target row.
 *
 * @return		The dragging operation the data source will perform.
 *
 * @see			tableGrid:acceptDrop:column:row:
 */
- (NSDragOperation)tableGrid:(MBTableGrid *)aTableGrid validateDrop:(id <NSDraggingInfo>)info proposedColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @brief		Invoked by \c aTableGrid when the mouse button is released over
 *				a table grid that previously decided to allow a drop.
 *
 * @details		The data source should incorporate the data from the dragging
 *				pasteboard in the implementation of this method. You can get the
 *				data for the drop operation from \c info using the \c draggingPasteboard
 *				method.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		info			An object that contains more information about
 *								this dragging operation.
 * @param		columnIndex		The index of the proposed target column.
 * @param		rowIndex		The index of the proposed target row.
 *
 * @return		\c YES if the drop was successful, otherwise \c NO.
 *
 * @see			tableGrid:validateDrop:proposedColumn:row:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid acceptDrop:(id <NSDraggingInfo>)info column:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @}
 */

@end

#pragma mark -

/**
 * @brief		The delegate of an \c MBTableGrid object must adopt the
 *				\c MBTableGridDelegate protocol. Optional methods of the
 *				protocol allow the delegate to validate selections and data
 *				modifications and provide formatting information.
 */
@protocol MBTableGridDelegate <NSObject>

// Being a delegate, the entire protocol is optional
@optional

#pragma mark -
#pragma mark Managing Selections
/**
 * @name		Managing Selections
 */
/**
 * @{
 */

/**
 * @brief		Tells the delegate that the specified columns are about to be
 *				selected.
 *
 * @param		aTableGrid		The table grid object informing the delegate
 *								about the impending selection.
 * @param		indexPath		An index path locating the columns in \c aTableGrid.
 *
 * @return		An index path which confirms or alters the impending selection.
 *				Return an \c NSIndexPath object other than \c indexPath if you want
 *				different columns to be selected.
 *
 * @see			tableGrid:willSelectRowsAtIndexPath:
 */
- (NSIndexSet *)tableGrid:(MBTableGrid *)aTableGrid willSelectColumnsAtIndexPath:(NSIndexSet *)indexPath;

/**
 * @brief		Tells the delegate that the specified rows are about to be
 *				selected.
 *
 * @param		aTableGrid		The table grid object informing the delegate
 *								about the impending selection.
 * @param		indexPath		An index path locating the rows in \c aTableGrid.
 *
 * @return		An index path which confirms or alters the impending selection.
 *				Return an \c NSIndexPath object other than \c indexPath if you want
 *				different rows to be selected.
 *
 * @see			tableGrid:willSelectColumnsAtIndexPath:
 */
- (NSIndexSet *)tableGrid:(MBTableGrid *)aTableGrid willSelectRowsAtIndexPath:(NSIndexSet *)indexPath;

/**
 * @brief		Informs the delegate that the table grid's selection has changed.
 *
 * @details		\c aNotification is an \c MBTableGridDidChangeSelectionNotification.
 */
- (void)tableGridDidChangeSelection:(NSNotification *)aNotification;

/**
 * @}
 */

#pragma mark -
#pragma mark Moving Columns and Rows

/**
 * @name		Moving Columns and Rows
 */
/**
 * @{
 */

/**
 * @brief		Informs the delegate that columns were moved by user action in
 *				the table grid.
 *
 * @details		\c aNotification is an \c MBTableGridDidMoveColumnsNotification.
 *
 * @see			tableGridDidMoveRows:
 */
- (void)tableGridDidMoveColumns:(NSNotification *)aNotification;

/**
 * @brief		Informs the delegate that rows were moved by user action in
 *				the table grid.
 *
 * @details		\c aNotification is an \c MBTableGridDidMoveRowsNotification.
 *
 * @see			tableGridDidMoveColumns:
 */
- (void)tableGridDidMoveRows:(NSNotification *)aNotification;

/**
 * @}
 */

#pragma mark -
#pragma mark Editing Cells

/**
 * @name		Editing Cells
 */
/**
 * @{
 */

/**
 * @brief		Asks the delegate if the specified cell can be edited.
 *
 * @details		The delegate can implement this method to disallow editing of
 *				specific cells.
 *
 * @param		aTableGrid		The table grid which will edit the cell.
 * @param		columnIndex		The column of the cell.
 * @param		rowIndex		The row of the cell.
 *
 * @return		\c YES to permit \c aTableGrid to edit the specified cell, \c NO to deny permission.
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid shouldEditColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

- (void) cancelEditForTableGrid:(MBTableGrid *)aTableGrid;

/**
 * @}
 */

@end
