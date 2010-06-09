/*!
    @header	SMPieChartView
    @discussion	NSView subclass that draws a pie chart with title.  The pie view works in a very similar
                fashion to NSTableView, NSOutlineView, and NSBrowser.

                A datasource object provides all of the slice data and attributes to display pie
                chart.  A delegate object can respond to some methods for more control
                over the display and behavior of the pie view.

    SMPieChartView Copyright 2002-2008 Snowmint Creative Solutions LLC.
    http://www.snowmintcs.com/
*/
#import <AppKit/AppKit.h>

/*!	@const		NSBackgroundColorAttributeName
    @discussion	This is a key to be used in the -pieChartView:attributesForSliceIndex: dictionary.  The value
                represents what color the slice will be drawn.  If this key is not present, a default color will
                be used based on the zero based slice index of the slice.

                The value should be an NSColor object.  For example, [ NSColor redColor ].
*/
extern NSString *NSBackgroundColorAttributeName;

/*!	@const		NSForegroundColorAttributeName
    @discussion	This is a key to be used in the -pieChartView:attributesForSliceIndex: dictionary.  The value
                represents what color the border of the slice will be drawn.  If this key is not present,
                the view's -borderColor will be used.

                The value should be an NSColor object.  For example, [ NSColor redColor ].
*/
extern NSString *NSForegroundColorAttributeName;

/*!	@enum	SMTitlePosition
    @discussion	Constants to use with the -setTitlePosition: and -titlePosition methods.
    @constant   SMTitlePositionBelow       Draw the title below the pie.
    @constant   SMTitlePositionAbove       Draw the title above the pie.
*/
typedef enum _SMTitlePosition {
    SMTitlePositionBelow = 0,
    SMTitlePositionAbove = 1,
} SMTitlePosition;

/*!	@enum	SMLabelPositionEnum
    @discussion	Constants to use with the -setLabelPosition: and -labelPosition methods.
    @constant   SMLabelPositionNone        Draw no labels.
    @constant   SMLabelPositionBelow       Draw the labels below the pie.
    @constant   SMLabelPositionAbove       Draw the labels above the pie.
    @constant   SMLabelPositionRight       Draw the labels to the right of the pie.
    @constant   SMLabelPositionLeft        Draw the labels to the left of the pie.
*/
typedef enum _SMLabelPosition {
    SMLabelPositionNone = 0,
    SMLabelPositionBelow = 1,
    SMLabelPositionAbove = 2,
    SMLabelPositionRight = 4,
    SMLabelPositionLeft = 8
} SMLabelPositionEnum;

/*!	@class	SMPieChartView
    @discussion	NSView subclass that conforms to the NSCoding protocol.

                Displays a pie chart.
                The pie view works in a very similar fashion to NSTableView, NSOutlineView, and NSBrowser.

                A datasource object provides all of the slice data and attributes to display the pie
                chart.  A delegate object can respond to some methods for more control
                over the display and behavior of the pie view.
*/
@interface SMPieChartView : NSView <NSCoding>
{
@public
    IBOutlet id		delegate;
    IBOutlet id		dataSource;

@private
    void		*_SMPieChartView_Private;
}

/*!	@method	setDataSource:
    @discussion Set the object that slice data is pulled from.  This works in exactly the same way that
                NSTableView and NSOutlineView have data source objects.

                The data source is checked to see if responds to methods in the SMPieChartDataSource category.
    @param	inDataSource	The new data source.
*/
- (void)setDataSource:(id)inDataSource;
/*!	@method	dataSource
    @discussion Returns the object that slice data is pulled from.
    @result	The data source object of the pie view.
*/
- (id)dataSource;

/*!	@method	setDelegate:
    @discussion Set the delegate object for the pie view.

                The delegate is checked to see if responds to any of the methods in the SMPieChartDelegate category.
    @param	inDelegate	The new delegate object.
*/
- (void)setDelegate:(id)inDelegate;
/*!	@method	delegate
    @discussion Returns the delegate object for the pie view.
    @result	The delegate object.
*/
- (id)delegate;

// -------- Basic settings that can be changed. --------------------

/*!	@method	setTag:
    @discussion	Sets the tag of the receiver to inTag.  This is an integer you can use for whatever you'd like.
    @param	inTag	The new tag of the receiver.
*/
- (void)setTag:(int)inTag;
/*!	@method	tag
    @discussion	Returns the tag of the receiver.  This is an integer you can use for whatever you'd like.
    @result	The tag of the receiver.
*/
- (int)tag;

/*!	@method	setBackgroundColor:
    @discussion	Sets the receiver's background color to aColor.  The default is white.  If set to nil, no
                background is drawn.

                <B>See Also:</B> -setDrawsGrid:, -drawsGrid, -setGridColor:, -gridColor, and -backgroundColor.
    @param	inColor	The new background color.
*/
- (void)setBackgroundColor:(NSColor *)inColor;
/*!	@method	backgroundColor
    @discussion Returns the color used to draw the background of the receiver. The default background color is white.
    @result	The color used to draw the background.
*/
- (NSColor *)backgroundColor;

/*!	@method	setBorderColor:
    @discussion	Sets the color used to draw the border of each slice. The default color is black.

                <B>See Also:</B> -setBackgroundColor:, and -backgroundColor.
    @param	inColor	The color to draw the border of each slice.
*/
- (void)setBorderColor:(NSColor *)inColor;
/*!	@method	borderColor
    @discussion Returns the color used to draw the border of each slice. The default color is black.
    @result	The color used to draw the border of each slice.
*/
- (NSColor *)borderColor;

/*!	@method	setTitle:
    @discussion Sets the title of the pie chart.  The default is no title (nil).
    @param	inNewTitle	The new title.  If nil, any existing title is removed.
*/
- (void)setTitle:(NSString *)inNewTitle;
/*!	@method	title
    @discussion Returns the title of the pie chart.  The default is no title (nil).
    @result	An autoreleased string or nil.
*/
- (NSString *)title;

/*!	@method	setAttributedTitle:
    @discussion Sets the attributed title of the pie chart.  The default is no title (nil).
    @param	inNewTitle	The new title.  If nil, any existing title is removed.
*/
- (void)setAttributedTitle:(NSAttributedString *)inNewTitle;
/*!	@method	attributedTitle
    @discussion Returns the attributed title of the pie chart.  The default is no title (nil).
    @result	An autoreleased string or nil.
*/
- (NSAttributedString *)attributedTitle;

/*!	@method	setLabelPosition:
    @discussion Sets the position of labels for the pie chart.  The default is no labels.
    @param	inNewValue	The new label position value.
*/
- (void)setLabelPosition:(SMLabelPositionEnum)inNewValue;
/*!	@method	labelPosition
    @discussion Returns the position of labels for the pie chart.  The default is no labels.
    @result The position of labels.
*/
- (SMLabelPositionEnum)labelPosition;


/*!	@method	setTitlePosition:
    @discussion Sets the position of the title.  The default is SMTitlePositionBelow.
    @param	inPosition		The position to draw the title in.
*/
- (void)setTitlePosition:(SMTitlePosition)inPosition;
/*!	@method	titlePosition
    @discussion Returns the position of the title.  The default is SMTitlePositionBelow.
    @result The number of position to draw the title in.
*/
- (SMTitlePosition)titlePosition;

/*!	@method	setExplodeDistance:
    @discussion Sets the pixel offset from the center of the chart to draw exploded slices of the pie.
                The default is zero.
    @param	inDistance		The number of pixels to offset exploded parts of the pie.
*/
- (void)setExplodeDistance:(float)inDistance;
/*!	@method	explodeDistance
    @discussion Returns the pixel offset from the center of the chart to draw exploded slices of the pie.
                The default is zero.
    @result The number of pixels to offset exploded parts of the pie.
*/
- (float)explodeDistance;

/*!	@method	refreshDisplay:
    @discussion Simple cover method that calls -reloadData, then -reloadAttributes.
    @param	sender		Any object or nil; unused.
*/
- (IBAction)refreshDisplay:(id)sender;

/*!	@method	reloadData
    @discussion Reloads all slice data from the datasource and schedules the chart for redrawing.
*/
- (void)reloadData;

/*!	@method	reloadAttributes
    @discussion Reloads all slice attributes from the datasource and schedules the chart for redrawing.
                The slice data is <b>not</b> reloaded.
*/
- (void)reloadAttributes;
/*!	@method	reloadAttributesForSliceIndex:
    @discussion Reloads a specific slice's attributes from the datasource and schedules the chart for redrawing.
                The slice data is <b>not</b> reloaded.
    @param	inSliceIndex	The zero based index of the slice to reload.
*/
- (void)reloadAttributesForSliceIndex:(unsigned int)inSliceIndex;

/*!	@method	imageOfView
    @discussion Returns an autoreleased image of the entire chart view.  This image is filled with a white
                background first, so it should not have any transparent parts.
    @result	An NSImage object of the entire chart view.
*/
- (NSImage *)imageOfView;

/*!	@method	convertToSliceFromPoint:fromView:
    @discussion Converts a point from a given window/view coordinate system to a slice of the pie, or
                -1 if the click was not on a slice of the pie.
                For example, if there are two slices of the pie (left half and right half) and the
                user clicks on the left half, this would return 0.

                This is very useful when called from the -pieChartView:didClickPoint: delegate method.
    @param	inPoint		The point to be converted.
    @param	inView		The inPoint parameter is in this view's coordinate system.
                        A value of nil means the window's coordinate system.
    @result	The slice of the pie that was clicked on.  If the point is not on a slice of pie, returns -1.
*/
- (int)convertToSliceFromPoint:(NSPoint)inPoint fromView:(NSView *)inView;

@end

/*!	@category	NSObject(SMPieChartDataSource)
    @discussion	An object should implement most of the methods in this category to return data to be
                displayed on a pie chart. These methods are optional:
                -pieChartView:attributesForSliceIndex:, -numberOfExplodedPartsInPieChartView:, and
                -pieChartView:rangeOfExplodedPartIndex:.
*/
@interface NSObject(SMPieChartDataSource)

/*!	@method	numberOfSlicesInPieChartView:
    @discussion Asks the datasource to report the number of slices to be drawn in a particular pie view.
    @param	inPieChartView	The pie view making the call.
    @result	Should return the number of slices to draw.
*/
- (unsigned int)numberOfSlicesInPieChartView:(SMPieChartView *)inPieChartView;

/*!	@method	pieChartView:dataForSliceIndex:
    @discussion <b>Either this method or -pieChartViewArrayOfSliceData: must be implemented.</b>

                Asks the datasource to report the actual data for a particular slice.  The data should
                be returned as a double. Any scale can be used, but all slices should use the same scale.
    @param	inPieChartView	The pie view making the call.
    @param	inSliceIndex	The zero based slice index to return.
    @result	A double.
*/
- (double)pieChartView:(SMPieChartView *)inPieChartView dataForSliceIndex:(unsigned int)inSliceIndex;

/*!	@method	pieChartViewArrayOfSliceData:
    @discussion <b>Either this method or -pieChartView:dataForSliceIndex: must be implemented.</b>

                This method asks the datasource to report all slice data in an NSArray.  The slice
                data should be an array of objects that respond to -doubleValue (like NSNumber).
    @param	inPieChartView	The pie view making the call.
    @result	An NSArray of objects.  Should not be nil.
*/
- (NSArray *)pieChartViewArrayOfSliceData:(SMPieChartView *)inPieChartView;

/*!	@method	pieChartView:attributesForSliceIndex:
    @discussion <b>Implementing this method is optional.</b>  Asks the datasource for the drawing attributes to use
                when drawing a particular slice.  If the datasource does not respond to this message, or returns nil,
                default values are used.  See the constants section of the documentation for keys that can be used.
    @param	inPieChartView	The pie view making the call.
    @param	inSliceIndex	The zero based slice index to return.
    @result	A dictionary of attributes to use to draw the slice; can return nil if default values are wanted.
*/
- (NSDictionary *)pieChartView:(SMPieChartView *)inPieChartView attributesForSliceIndex:(unsigned int)inSliceIndex;

/*!	@method	numberOfExplodedPartsInPieChartView:
    @discussion <b>This method is optional.  However, if this is implemented
                -pieChartView:rangeOfExplodedPartIndex: must also be implemented.</b>

                Asks the datasource to report the number of groups of exploded slices
                in a particular pie view.  Exploded slices are moved out from the center of the chart
                by the explodeDistance.
    @param	inPieChartView	The pie view making the call.
    @result	Should return the number of exploded groups of slices.
*/
- (unsigned int)numberOfExplodedPartsInPieChartView:(SMPieChartView *)inPieChartView;

/*!	@method	pieChartView:rangeOfExplodedPartIndex:
    @discussion <b>This method is optional.  However, if this is implemented
                -numberOfExplodedPartsInPieChartView: must also be implemented.</b>

                Asks the datasource to report the range of slices of an exploded group.  Exploded slices
                are moved out from the center of the chart by the explodeDistance.  For example,
                if the first two slices should be exploded, this should return a range with location
                equal to 0 and length equal to two.
    @param	inPieChartView	The pie view making the call.
    @param	inIndex     The zero based slice index to return.
    @result	A range of an exploded group of slices.
*/
- (NSRange)pieChartView:(SMPieChartView *)inPieChartView rangeOfExplodedPartIndex:(unsigned int)inIndex;

@end

/*!	@category	NSObject(SMPieChartDelegate)
    @discussion	An object can implement any of the optional methods in this category to gain greater control over a
                particular chart view.
*/
@interface NSObject(SMPieChartDelegate)

/*!	@method	pieChartView:labelForSliceIndex:
    @discussion <b>Implementing this method is optional.</b>  The delegate has a chance to change the slice
                labels drawn for each part of the graph.  If the delegate does not respond to this message
                no label is drawn.
    @param	inPieChartView		The pie view making the call.
    @param	inSliceIndex        The zero based slice index to return.
    @result	A string to draw for the slice; can return nil if no label is wanted.
*/
- (NSString *)pieChartView:(SMPieChartView *)inPieChartView labelForSliceIndex:(unsigned int)inSliceIndex;

/*!	@method	pieChartView:didClickPoint:
    @discussion <b>Implementing this method is optional.</b>  The delegate has a chance to respond to
                the user clicking the mouse in the area of the view.

                You may want to use -convertToSliceFromPoint:fromView: to get the slice of the pie
                the user clicked on.
    @param	inPieChartView		The pie view making the call.
    @param	inPoint             The clicked position in the pie view coordinate system.
*/
- (void)pieChartView:(SMPieChartView *)inPieChartView didClickPoint:(NSPoint)inPoint;

/*!	@method	pieChartViewCompletedDrawing:
    @discussion <b>Implementing this method is optional.</b>  The delegate can be notified when the view
                completes drawing.  This is called at the end of the -drawRect: method of the view.
                This could be useful for a progress bar or timing information.
    @param	inPieChartView	The pie view making the call.
*/
- (void)pieChartViewCompletedDrawing:(SMPieChartView *)inPieChartView;

@end
