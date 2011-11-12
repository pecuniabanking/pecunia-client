/*!
    @header	SM2DGraphView
    @discussion	NSView subclass that draws line and bar graphs.  The graph view works in a very similar
                fashion to NSTableView, NSOutlineView, and NSBrowser.

                A datasource object provides all of the line data and attributes to display the graphed
                lines, points, or bars.  A delegate object can respond to some methods for more control
                over the display and behavior of the graph view.

    SM2DGraphView Copyright 2002-2008 Snowmint Creative Solutions LLC.
    http://www.snowmintcs.com/
*/
#import <AppKit/AppKit.h>

/*!	@const		NSForegroundColorAttributeName
    @discussion	This is a key to be used in the -twoDGraphView:attributesForLineIndex: dictionary.  The value
                represents what color the line will be drawn.  If this key is not present, a default color will
                be used based on the zero based line index of the line.

                The value should be an NSColor object.  For example, [ NSColor redColor ].
*/
extern NSString *NSForegroundColorAttributeName;
/*!	@const		SM2DGraphLineSymbolAttributeName
    @discussion	This is a key to be used in the -twoDGraphView:attributesForLineIndex: dictionary.  The value
                represents the symbol that will be drawn at each data point.  If this key is not present, no
                symbol will be drawn at the data points.

                The value should be an NSNumber with an 'int' from the SM2DGraphSymbolTypeEnum enumeration.  For
                example, [ NSNumber numberWithInt:kSM2DGraph_Symbol_Diamond ].
*/
extern NSString *SM2DGraphLineSymbolAttributeName;
/*!	@const		SM2DGraphBarStyleAttributeName
    @discussion	This is a key to be used in the -twoDGraphView:attributesForLineIndex: dictionary.  If this
                key is present with any value, the line will be drawn as a series of bars instead of as a line.
*/
extern NSString *SM2DGraphBarStyleAttributeName;
/*!	@const		SM2DGraphLineWidthAttributeName
    @discussion	This is a key to be used in the -twoDGraphView:attributesForLineIndex: dictionary.  The value
                represents how thick the line will be drawn.  If this key is not present, a default value of
                kSM2DGraph_Width_Default is used.

                The value should be an NSNumber with an 'int' from the SM2DGraphLineWidthEnum enumeration.  For
                example, [ NSNumber numberWithInt:kSM2DGraph_Width_Normal ].
*/
extern NSString	*SM2DGraphLineWidthAttributeName;
/*!	@const		SM2DGraphDontAntialiasAttributeName
    @discussion	This is a key to be used in the -twoDGraphView:attributesForLineIndex: dictionary.  If this
                key is present with any value, the line will not be anti-aliased.  This does not affect lines
                with the bar style.

                This was added in v1.1 of the framework.
*/
extern NSString	*SM2DGraphDontAntialiasAttributeName;

/*!	@enum	SM2DGraphSymbolTypeEnum
    @discussion	Symbols that can be used on line style graphs.  Does nothing for bar style lines.
    @constant	kSM2DGraph_Symbol_None			Plain lines - no symbol marking points.
    @constant	kSM2DGraph_Symbol_Triangle		Open triangle marking line points.
    @constant	kSM2DGraph_Symbol_Diamond		Open diamond marking line points.
    @constant	kSM2DGraph_Symbol_Circle		Open circle marking line points.
    @constant	kSM2DGraph_Symbol_X				X marking line points.
    @constant	kSM2DGraph_Symbol_Plus			Plus symbol marking line points.
    @constant	kSM2DGraph_Symbol_FilledCircle	Filled circle marking line points.
	@constant	kSM2DGraph_Symbol_Square		Square marking line points.
	@constant	kSM2DGraph_Symbol_Star			Star marking line points.
	@constant	kSM2DGraph_Symbol_InvertedTriangle	Down-pointing triangle marking line points.
	@constant	kSM2DGraph_Symbol_FilledSquare		Filled square marking line points.
	@constant	kSM2DGraph_Symbol_FilledTriangle	Filled triangle marking line points.
	@constant	kSM2DGraph_Symbol_FilledDiamond		Filled diamond marking line points.
	@constant	kSM2DGraph_Symbol_FilledInvertedTriangle	Filled down-pointing triangle marking line points.
	@constant	kSM2DGraph_Symbol_FilledStar		Filled star marking line points.
	@constant	kSM2DGraph_Symbol_Default		Default symbol for lines - equal to kSM2DGraph_Symbol_None.
*/
typedef enum
{
    kSM2DGraph_Symbol_None = 0,
    kSM2DGraph_Symbol_Triangle,
    kSM2DGraph_Symbol_Diamond,
    kSM2DGraph_Symbol_Circle,
    kSM2DGraph_Symbol_X,
    kSM2DGraph_Symbol_Plus,
    kSM2DGraph_Symbol_FilledCircle,
    kSM2DGraph_Symbol_Square,
    kSM2DGraph_Symbol_Star,
    kSM2DGraph_Symbol_InvertedTriangle,
    kSM2DGraph_Symbol_FilledSquare,
    kSM2DGraph_Symbol_FilledTriangle,
    kSM2DGraph_Symbol_FilledDiamond,
    kSM2DGraph_Symbol_FilledInvertedTriangle,
    kSM2DGraph_Symbol_FilledStar,

    kSM2DGraph_Symbol_Default = kSM2DGraph_Symbol_None
} SM2DGraphSymbolTypeEnum;

/*!	@enum	SM2DGraphLineWidthEnum
    @discussion	Width of lines in the graph.
    @constant	kSM2DGraph_Width_None		No line is drawn; symbols may still be drawn.
    @constant	kSM2DGraph_Width_Fine		Lines are drawn a half pixel wide.
    @constant	kSM2DGraph_Width_Normal		Lines are drawn one pixel wide.
    @constant	kSM2DGraph_Width_Wide		Lines are drawn two pixels wide.
    @constant	kSM2DGraph_Width_3D			Lines are drawn with a fake 3D look; lighter line above
                                            and darker line below main line.
    @constant	kSM2DGraph_Width_Default	Default width of lines - equal to kSM2DGraph_Width_3D.
*/
typedef enum 
{
    kSM2DGraph_Width_None = 0,
    kSM2DGraph_Width_Fine = 1,
    kSM2DGraph_Width_Normal,
    kSM2DGraph_Width_Wide,
    kSM2DGraph_Width_3D,

    kSM2DGraph_Width_Default = kSM2DGraph_Width_3D
} SM2DGraphLineWidthEnum;

/*!	@enum	SM2DGraphAxisEnum
    @discussion	When dealing with various properties of graph axis, these constants should be used.
    @constant	kSM2DGraph_Axis_Y		The Y axis of the graph.
    @constant	kSM2DGraph_Axis_X		The X axis of the graph.
    @constant	kSM2DGraph_Axis_Y_Right	Y axis on the right side of the graph.
    @constant	kSM2DGraph_Axis_Y_Left	Y axis on left side of graph - equal to kSM2DGraph_Axis_Y.
*/
typedef enum
{
    kSM2DGraph_Axis_Y = 0,
    kSM2DGraph_Axis_X = 1,

    kSM2DGraph_Axis_Y_Right = 2,
    kSM2DGraph_Axis_Y_Left = kSM2DGraph_Axis_Y
} SM2DGraphAxisEnum;

/*!	@class	SM2DGraphView
    @discussion	NSView subclass that conforms to the NSCoding protocol.

                Displays graph paper, axis labels, and line and/or bar graphs.
                The graph view works in a very similar fashion to NSTableView, NSOutlineView, and NSBrowser.

                A datasource object provides all of the line data and attributes to display the graphed
                lines, points, or bars.  A delegate object can respond to some methods for more control
                over the display and behavior of the graph view.
*/
@interface SM2DGraphView : NSView <NSCoding>
{
@public
    IBOutlet id		delegate;
    IBOutlet id		dataSource;

@private
    void		*_SM2DGraphView_Private;
}

/*!	@method	barWidth
    @discussion Returns the pixel width of a bar for bar graphs.  Useful for calculating graph insets if
                multiple line bar graphs are going to be displayed.
    @result	The width (in pixels) of a bar for bar graphs.
*/
+ (float)barWidth;

/*!	@method	setDataSource:
    @discussion Set the object that line data is pulled from.  This works in exactly the same way that
                NSTableView and NSOutlineView have data source objects.

                The data source is checked to see if responds to methods in the SM2DGraphDataSource category.
    @param	inDataSource	The new data source.
*/
- (void)setDataSource:(id)inDataSource;
/*!	@method	dataSource
    @discussion Returns the object that line data is pulled from.
    @result	The data source object of the graph view.
*/
- (id)dataSource;

/*!	@method	setDelegate:
    @discussion Set the delegate object for the graph view.

                The delegate is checked to see if responds to any of the methods in the SM2DGraphDelegate category.
    @param	inDelegate	The new delegate object.
*/
- (void)setDelegate:(id)inDelegate;
/*!	@method	delegate
    @discussion Returns the delegate object for the graph view.
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

/*!	@method	setDrawsGrid:
    @discussion	Controls whether the receiver draws grid lines on the graph. The default is NO.

                <B>See Also:</B> -drawsGrid, -setGridColor:, -gridColor, -setBackgroundColor: and -backgroundColor.
    @param	inFlag	If YES the receiver draws grid lines; if NO it doesn't.
*/
- (void)setDrawsGrid:(BOOL)inFlag;
/*!	@method	drawsGrid
    @discussion Returns YES if the receiver draws grid lines on the graph, NO if it doesn't. The default is NO.
    @result	YES if the receiver draws grid lines, NO if it doesn't.
*/
- (BOOL)drawsGrid;
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

/*!	@method	setGridColor:
    @discussion	Sets the color used to draw grid lines. The default color is blue.

                <B>See Also:</B> -setDrawsGrid:, -drawsGrid, -gridColor, -setBackgroundColor:, and -backgroundColor.
    @param	inColor	The color to draw grid lines.
*/
- (void)setGridColor:(NSColor *)inColor;
/*!	@method	gridColor
    @discussion Returns the color used to draw grid lines. The default color is blue.
    @result	The color used to draw grid lines.
*/
- (NSColor *)gridColor;

/*!	@method	setBorderColor:
    @discussion	Sets the color used to draw the border of the graph area. The default color is black.

                <B>See Also:</B> -setDrawsGrid:, -drawsGrid, -gridColor, -setBackgroundColor:, and -backgroundColor.
    @param	inColor	The color to draw grid lines.
*/
- (void)setBorderColor:(NSColor *)inColor;
/*!	@method	borderColor
    @discussion Returns the color used to draw the border of the graph area. The default color is black.
    @result	The color used to draw the border of the graph area.
*/
- (NSColor *)borderColor;

/*!	@method	setTitle:
    @discussion Set the title drawn at the top of the graph.  The default title is blank.
    @param	inTitle		The title of the graph.  If nil, any existing title is removed.
*/
- (void)setTitle:(NSString *)inTitle;
/*!	@method	title
    @discussion Returns the title drawn at the top of the graph.  The default title is blank.
    @result	The title of the graph.
*/
- (NSString *)title;

/*!	@method	setAttributedTitle:
    @discussion Set the title as an attributed string drawn at the top of the graph.  The default title is blank.
    @param	inTitle		The title of the graph.  If nil, any existing title is removed.
*/
- (void)setAttributedTitle:(NSAttributedString *)inTitle;
/*!	@method	attributedTitle
    @discussion Returns the attributed string title drawn at the top of the graph.  The default title is blank.
    @result	The title of the graph as an attributed string.
*/
- (NSAttributedString *)attributedTitle;

/*!	@method	setLabel:forAxis:
    @discussion Sets the axis label for an axis.  The default is no label (nil).
    @param	inNewLabel	The new label.  If nil, any existing label is removed.
    @param	inAxis		The axis to label.
*/
- (void)setLabel:(NSString *)inNewLabel forAxis:(SM2DGraphAxisEnum)inAxis;
/*!	@method	labelForAxis:
    @discussion Returns the axis label for an axis.  The default is no label (nil).
    @param	inAxis		The axis to return.
    @result	An autoreleased string or nil.
*/
- (NSString *)labelForAxis:(SM2DGraphAxisEnum)inAxis;

/*!	@method	setNumberOfTickMarks:forAxis:
    @discussion Sets the number of major tick marks for an axis.  The default is no tick marks.
    @param	count		The number of major tick marks.  Should not be one.
    @param	inAxis		The axis to change.
*/
- (void)setNumberOfTickMarks:(int)count forAxis:(SM2DGraphAxisEnum)inAxis;
/*!	@method	numberOfTickMarksForAxis:
    @discussion Returns the number of major tick marks for an axis.  The default is no tick marks.
    @param	inAxis		The axis to count.
    @result	The number of major tick marks for an axis.
*/
- (int)numberOfTickMarksForAxis:(SM2DGraphAxisEnum)inAxis;

/*!	@method	setNumberOfMinorTickMarks:forAxis:
    @discussion Sets the number of minor tick marks between each major tick mark for an axis.
                The default is no minor tick marks.
    @param	count		The number of minor tick marks between major tick marks.
    @param	inAxis		The axis to change.
*/
- (void)setNumberOfMinorTickMarks:(int)count forAxis:(SM2DGraphAxisEnum)inAxis;
/*!	@method	numberOfMinorTickMarksForAxis:
    @discussion Returns the number of minor tick marks between each major tick mark for an axis.
                The default is no minor tick marks.
    @param	inAxis		The axis to count.
    @result	The number of minor tick marks for an axis.
*/
- (int)numberOfMinorTickMarksForAxis:(SM2DGraphAxisEnum)inAxis;

/*!	@method	setTickMarkPosition:forAxis:
    @discussion Sets the position to draw tick marks for an axis.
                The default is NSTickMarkBelow and NSTickMarkRight.
                <b>Note</b>: Currently, this setting is remembered but does nothing.
    @param	position	The position to draw tick marks.
    @param	inAxis		The axis to change.
*/
- (void)setTickMarkPosition:(NSTickMarkPosition)position forAxis:(SM2DGraphAxisEnum)inAxis;
/*!	@method	tickMarkPositionForAxis:
    @discussion Returns the position to draw tick marks for an axis.
                The default is NSTickMarkBelow and NSTickMarkRight.
                <b>Note</b>: Currently, this setting is remembered but does nothing.
    @param	inAxis		The axis to return.
    @result	The position to draw tick marks for an axis.
*/
- (NSTickMarkPosition)tickMarkPositionForAxis:(SM2DGraphAxisEnum)inAxis;

/*!	@method	setAxisInset:forAxis:
    @discussion Sets the pixel inset from the edge of the graph paper area to start the axis range.
                The default is zero.
    @param	inInset		The number of pixels to inset the line range.
    @param	inAxis		The axis to change.
*/
- (void)setAxisInset:(float)inInset forAxis:(SM2DGraphAxisEnum)inAxis;
/*!	@method	axisInsetForAxis:
    @discussion Returns the pixel inset from the edge of the graph paper area to start the axis range.
                The default is zero.
    @param	inAxis		The axis to return.
    @result The number of pixels to inset the line range.
*/
- (float)axisInsetForAxis:(SM2DGraphAxisEnum)inAxis;

/*!	@method	setDrawsLineAtZero:forAxis:
    @discussion Can draw a straight line at zero for the first line.  This is useful if your range goes both
                above and below zero, and zero does not land on a standard grid line.
                The default is NO.
    @param	inNewValue	Set to YES if you want to draw a straight line at zero for the first line.
    @param	inAxis		The axis to change.
*/
- (void)setDrawsLineAtZero:(BOOL)inNewValue forAxis:(SM2DGraphAxisEnum)inAxis;
/*!	@method	drawsLineAtZeroForAxis:
    @discussion Can draw a straight line at zero for the first line.  This is useful if your range goes both
                above and below zero, and zero does not land on a standard grid line.
                The default is NO.
    @param	inAxis		The axis to return.
    @result	YES if drawing a straight line at zero for the first line.
*/
- (BOOL)drawsLineAtZeroForAxis:(SM2DGraphAxisEnum)inAxis;

/*!	@method	setLiveRefresh:
    @discussion Sets the state of the <i>liveRefresh</i> flag.  This flag is only used in the
                <b>-addDataPoint:toLineIndex:</b> method to determine if the graph should be automatically
                redrawn or not.  The default value is NO.
    @param	inFlag	The desired state of the <i>liveRefresh</i> flag.
*/
- (void)setLiveRefresh:(BOOL)inFlag;
/*!	@method	liveRefresh
    @discussion Returns the state of the <i>liveRefresh</i> flag.  This flag is only used in the
                <b>-addDataPoint:toLineIndex:</b> method to determine if the graph should be automatically
                redrawn or not.  The default value is NO.
    @result	The state of the <i>liveRefresh</i> flag.
*/
- (BOOL)liveRefresh;

/*!	@method	refreshDisplay:
    @discussion Simple cover method that calls -reloadData, then -reloadAttributes.
    @param	sender		Any object or nil; unused.
*/
- (IBAction)refreshDisplay:(id)sender;

/*!	@method	reloadData
    @discussion Reloads all line data from the datasource and schedules the graph for redrawing.
*/
- (void)reloadData;
/*!	@method	reloadDataForLineIndex:
    @discussion Reloads a specific line's data from the datasource and schedules the graph for redrawing.
    @param	inLineIndex	The zero based index of the line to reload.
*/
- (void)reloadDataForLineIndex:(unsigned int)inLineIndex;

/*!	@method	addDataPoint:toLineIndex:
    @discussion Adds a point to the end of a specific line's data.  The data must have either been nil previously,
                returned as a NSMutableArray by the dataSources -twoDGraphView:dataForLineIndex: method, or returned as
                a NSMutableData by the dataSources -twoDGraphView:dataObjectForLineIndex: method.  The graph is
                scheduled for redrawing if the <i>liveRefresh</i> flag is set for the view.  This can be used for
                incremental graphing, such as when each point requires significant calculation.

                See also, the <b>-liveRefresh</b> and <b>-setLiveRefresh:</b> methods for additional information.
    @param	inPoint		A point to add to the end of the line's data.
    @param	inLineIndex	The zero based index of the line to add to.
*/
- (void)addDataPoint:(NSPoint)inPoint toLineIndex:(unsigned int)inLineIndex;

/*!	@method	reloadAttributes
    @discussion Reloads all line attributes from the datasource and schedules the graph for redrawing.
                The line data points are <b>not</b> reloaded.
*/
- (void)reloadAttributes;
/*!	@method	reloadAttributesForLineIndex:
    @discussion Reloads a specific line's attributes from the datasource and schedules the graph for redrawing.
                The line data points are <b>not</b> reloaded.
    @param	inLineIndex	The zero based index of the line to reload.
*/
- (void)reloadAttributesForLineIndex:(unsigned int)inLineIndex;

/*!	@method	imageOfView
    @discussion Returns an autoreleased image of the entire graph view.  This image is filled with a white
                background first, so it should not have any transparent parts.
    @result	An NSImage object of the entire graph view.
*/
- (NSImage *)imageOfView;

/*!	@method	graphPaperRect
    @discussion Returns the area the will be taken up by the graph itself.  Labels will be drawn outside of this rectangle, but within the view's area.
    @result	An NSRect in the receivers coordinates which is contains the actual graph area.
*/
- (NSRect)graphPaperRect;

/*!	@method	convertPoint:fromView:toLineIndex:
    @discussion Converts a point from a given window/view coordinate system to a point in the coordinate system
                of a given line on the graph.  For example, if the x range values for a line are from -10.0 to +10.0
                the returned point will be in this range.

                This is very useful when calling it from the -twoDGraphView:didClickPoint: delegate method.
    @param	inPoint		The point to be converted.
    @param	inView		The inPoint parameter is in this view's coordinate system.
                        A value of nil means the window's coordinate system.
    @param	inLineIndex	Zero based index of a line displayed on the graph.
    @result	The point after conversion to the appropriate line's scale.
*/
- (NSPoint)convertPoint:(NSPoint)inPoint fromView:(NSView *)inView toLineIndex:(unsigned int)inLineIndex;

@end

/*!	@category	NSObject(SM2DGraphDataSource)
    @discussion	An object should implement most of the methods in this category to return data to be
                displayed on a graph view.  Only -twoDGraphView:attributesForLineIndex: is optional.
*/
@interface NSObject(SM2DGraphDataSource)

/*!	@method	numberOfLinesInTwoDGraphView:
    @discussion Asks the datasource to report the number of data lines to be drawn in a particular graph view.
    @param	inGraphView	The graph view making the call.
    @result	Should return the number of data lines to graph.
*/
- (unsigned int)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView;

/*!	@method	twoDGraphView:dataForLineIndex:
    @discussion <b>Either this method or -twoDGraphView:dataObjectForLineIndex: must be implemented.</b>  You can
                implement one or the other, or both if you want a mix of data types.

                Asks the datasource to report the actual data points for a particular line.  The points should
                be returned as an NSArray of NSPoints as strings; you can use the function NSStringFromPoint
                to do the conversion.
    @param	inGraphView	The graph view making the call.
    @param	inLineIndex	The zero based data line index to return.
    @result	An NSArray (or NSMutableArray) of NSPoints as strings.  Can be <b>nil</b> if no points are on this line.
*/
- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(unsigned int)inLineIndex;

/*!	@method	twoDGraphView:dataObjectForLineIndex:
    @discussion <b>Either this method or -twoDGraphView:dataForLineIndex: must be implemented.</b>  You can implement one
                or the other, or both if you want a mix of data types.

                This method asks the datasource to report the actual data points for a particular line.
                The points should be returned as an NSData containing an array of NSPoints
                (or CGPoints since they're the same thing).  The length of the NSData object should be an exact multiple
                of sizeof(NSPoint).
    @param	inGraphView	The graph view making the call.
    @param	inLineIndex	The zero based data line index to return.
    @result	An NSData (or NSMutableData) of NSPoints (or CGPoints).  Can be <b>nil</b> if no points are on this line.
*/
- (NSData *)twoDGraphView:(SM2DGraphView *)inGraphView dataObjectForLineIndex:(unsigned int)inLineIndex;

/*!	@method	twoDGraphView:maximumValueForLineIndex:forAxis:
    @discussion Asks the datasource to report the maximum axis value to use for a particular line.  For example, if
                your line data points y value ranges from 1 to 9, you may want to graph from 0 to 10; in that case,
                you would return 10 as a maximum.
                
                This sets the scale to be used to display the line.
    @param	inGraphView	The graph view making the call.
    @param	inLineIndex	The zero based data line index to return.
    @param	inAxis		The axis requested.
    @result	A number to use for the maximum value of the scale.
*/
- (double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis;
/*!	@method	twoDGraphView:minimumValueForLineIndex:forAxis:
    @discussion Asks the datasource to report the minimum axis value to use for a particular line.  For example, if
                your line data points y value ranges from 1 to 9, you may want to graph from 0 to 10; in that case,
                you would return 0 as a minimum.
                
                This sets the scale to be used to display the line.
    @param	inGraphView	The graph view making the call.
    @param	inLineIndex	The zero based data line index to return.
    @param	inAxis		The axis requested.
    @result	A number to use for the minimum value of the scale.
*/
- (double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis;

/*!	@method	twoDGraphView:attributesForLineIndex:
    @discussion <b>Implementing this method is optional.</b>  Asks the datasource for the drawing attributes to use
                when drawing a particular line.  If the datasource does not respond to this message, or returns nil,
                default values are used.  See the constants section of the documentation for keys that can be used.
    @param	inGraphView	The graph view making the call.
    @param	inLineIndex	The zero based data line index to return.
    @result	A dictionary of attributes to use to draw the line; can return nil if default values are wanted.
*/
- (NSDictionary *)twoDGraphView:(SM2DGraphView *)inGraphView attributesForLineIndex:(unsigned int)inLineIndex;

@end

/*!	@category	NSObject(SM2DGraphDelegate)
    @discussion	An object can implement any of the optional methods in this category to gain greater control over a
                particular graph view.
*/
@interface NSObject(SM2DGraphDelegate)

/*!	@method	twoDGraphView:labelForTickMarkIndex:forAxis:defaultLabel:
    @discussion <b>Implementing this method is optional.</b>  The delegate has a chance to change the tick mark
                labels drawn on each axis of the graph.  If the delegate does not respond to this message the
                default label is used.  If nil is returned, no label is drawn.

                The default label is a number based on the position of the tick mark and the scale reported by the
                datasource for the first data line.
    @param	inGraphView		The graph view making the call.
    @param	inTickMarkIndex	The zero based data line index to return.
    @param	inAxis			The axis the tick mark is on.
    @param	inDefault		The default value of the label; will always be a number based on the position of the
                            tick mark and the scale of the first line.
    @result	A string to draw at the tick mark location; can return nil if no label is wanted.
*/
- (NSString *)twoDGraphView:(SM2DGraphView *)inGraphView labelForTickMarkIndex:(unsigned int)inTickMarkIndex
             forAxis:(SM2DGraphAxisEnum)inAxis defaultLabel:(NSString *)inDefault;

/*!
    @method     twoDGraphView:willDisplayBarIndex:forLineIndex:withAttributes:
    @abstract   Allows the delegate to change the way individual bars of a bar graph are drawn.
    @discussion <b>Implementing this method is optional.</b>  Informs the delegate that <i>inGraphView</i> will
                display the bar <i>inBarIndex</i> of the <i>inLineIndex</i> line using the attributes in
                <i>attr</i>.  The delegate can modify the attributes contained in <i>attr</i> to change alter
                the appearance of the bar.  Because the <i>attr</i> is reused for every bar in the line, the
                delegate must reset the display attributes after drawing special bars.
    @param      inGraphView     The graph view making the call.
    @param      inBarIndex      The zero based bar (data point) index that will be drawn.
    @param      inLineIndex     The zero based data line index that will be drawn.
    @param      attr            A dictionary containing the current attributes the bar will be drawn with.
                                This can be modified so individual bars will display differently.
*/
- (void)twoDGraphView:(SM2DGraphView *)inGraphView willDisplayBarIndex:(unsigned int)inBarIndex forLineIndex:(unsigned int)inLineIndex withAttributes:(NSMutableDictionary *)attr;

/*!	@method	twoDGraphView:didClickPoint:
    @discussion <b>Implementing this method is optional.</b>  The delegate has a chance to respond to the user
                clicking the mouse in the graph paper area of the view.

                You may want to use -convertPoint:fromView:toLineIndex: to get the point into the coordinate
                system of a particular data line.
    @param	inGraphView		The graph view making the call.
    @param	inPoint			The clicked position in the graph view coordinate system.
*/
- (void)twoDGraphView:(SM2DGraphView *)inGraphView didClickPoint:(NSPoint)inPoint;

/*!	@method	twoDGraphView:doneDrawingLineIndex:
    @discussion <b>Implementing this method is optional.</b>  The delegate can be notified when each of the lines
                completes drawing.  This is called from the -drawRect: method of the view.  This could be useful
                for a progress bar or timing information.
    @param	inGraphView	The graph view making the call.
    @param	inLineIndex	The zero based data line index that just got done drawing.
*/
- (void)twoDGraphView:(SM2DGraphView *)inGraphView doneDrawingLineIndex:(unsigned int)inLineIndex;

@end
