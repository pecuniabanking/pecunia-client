//
//  CategoryRepWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 19.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "CategoryRepWindowController.h"
#import "Category.h"
#import "MCEMOutlineViewLayout.h"
#import "ShortDate.h"
#import "TimeSliceManager.h"
#import "MOAssistant.h"
#import "AmountCell.h"

#import "GraphicsAdditions.h"

static NSString* const PecuniaHitNotification = @"PecuniaMouseHit";

@interface PecuniaGraphHost : CPTGraphHostingView
{
    NSTrackingArea* trackingArea; // To get mouse events, regardless of responder or key window state.
}

@end

@implementation PecuniaGraphHost

- (void)updateTrackingArea
{
    if (trackingArea != nil)
    {
        [self removeTrackingArea: trackingArea];
        [trackingArea release];
    }

    trackingArea = [[[NSTrackingArea alloc] initWithRect: NSRectFromCGRect(self.hostedGraph.plotAreaFrame.frame)
                                                 options: NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp
                                                   owner: self
                                                userInfo: nil]
                    retain];
    [self addTrackingArea: trackingArea];
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    [self updateTrackingArea];
    return self;
}

- (void)dealloc
{
    [self removeTrackingArea: trackingArea];
    [trackingArea release];
    [super dealloc];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    [self updateTrackingArea];
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (void)sendMouseNotification: (NSEvent*)theEvent withParameters: (NSMutableDictionary*)parameters
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    CGPoint mouseLocation = NSPointToCGPoint(location);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"x"];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.y] forKey: @"y"];
    [parameters setObject: [NSNumber numberWithInt: [theEvent buttonNumber]] forKey: @"button"];
    [center postNotificationName: PecuniaHitNotification object: nil userInfo: parameters];
}

- (void)mouseMoved: (NSEvent*)theEvent
{
    [super mouseMoved: theEvent];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject: @"mouseMoved" forKey: @"type"];
    [self sendMouseNotification: theEvent withParameters: parameters];
}

- (void)mouseDown: (NSEvent*)theEvent
{
    [super mouseDown: theEvent];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject: @"mouseDown" forKey: @"type"];
    [self sendMouseNotification: theEvent withParameters: parameters];
}

- (void)mouseDragged: (NSEvent*)theEvent
{
    [super mouseDragged: theEvent];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject: @"mouseDragged" forKey: @"type"];
    [self sendMouseNotification: theEvent withParameters: parameters];
}

- (void)mouseUp: (NSEvent*)theEvent
{
    [super mouseUp: theEvent];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject: @"mouseUp" forKey: @"type"];
    [self sendMouseNotification: theEvent withParameters: parameters];
}

@end;

//--------------------------------------------------------------------------------------------------

@interface CategoryRepWindowController(Private)
- (void)setupPieCharts;
-(void)updateValues;
@end

@implementation CategoryRepWindowController

@synthesize category = currentCategory;

- (id)init
{
    self = [super init];
    if (self != nil) {    
    }        
    return self;
}

-(void)dealloc
{
    [spendingsCategories release];
    [earningsCategories release];
    [fromDate release];
    fromDate = nil;
    [toDate release];
    toDate = nil;
    
    [super dealloc];
}

- (void)awakeFromNib
{
    earningsExplosionIndex = -1;
    spendingsExplosionIndex = -1;
    spendingsCategories = [[NSMutableArray arrayWithCapacity: 10] retain];
    earningsCategories = [[NSMutableArray arrayWithCapacity: 10] retain];

    
    [self setupPieCharts];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(mouseHit:)
                                                 name: PecuniaHitNotification
                                               object: nil];
}

- (void)setupPieCharts
{
    pieChartGraph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame: NSRectToCGRect(pieChartHost.bounds)];
    CPTTheme *theme = [CPTTheme themeNamed: kCPTPlainWhiteTheme];
    [pieChartGraph applyTheme: theme];
    pieChartHost.hostedGraph = pieChartGraph;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)pieChartGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO; // Disallow coreplot interaction (will do unwanted manipulations).
    plotSpace.delegate = self;
    
	CPTMutableTextStyle* textStyle = [CPTMutableTextStyle textStyle];
	textStyle.color = [CPTColor grayColor];
	textStyle.fontName = @"Helvetica-Bold";
	textStyle.fontSize = pieChartHost.bounds.size.height / 20.0f;
	pieChartGraph.titleTextStyle = textStyle;
	pieChartGraph.titleDisplacement = CGPointMake(0.0f, pieChartHost.bounds.size.height / 18.0f);
	pieChartGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    
//	pieChartGraph.plotAreaFrame.masksToBorder = NO;
    
	// Graph padding
    pieChartGraph.paddingLeft = 0;
    pieChartGraph.paddingTop = 0;
    pieChartGraph.paddingRight = 0;
    pieChartGraph.paddingBottom = 0;
    pieChartGraph.fill = nil;
    
    CPTPlotAreaFrame* frame = pieChartGraph.plotAreaFrame;
    frame.paddingLeft = 10;
    frame.paddingRight = 10;
    frame.paddingTop = 10;
    frame.paddingBottom = 10;
    
    // Border style.
    CPTMutableLineStyle* frameStyle = [CPTMutableLineStyle lineStyle];
    frameStyle.lineWidth = 1;
    frameStyle.lineColor = [[CPTColor colorWithGenericGray: 0] colorWithAlphaComponent: 0.5];
    
    frame.cornerRadius = 10;
    frame.borderLineStyle = frameStyle;

    frame.shadowColor = CGColorCreateGenericGray(0, 1);
    frame.shadowRadius = 2.0;
    frame.shadowOffset = CGSizeMake(1, -1);
    frame.shadowOpacity = 0.25;
//    frame.fill = nil;
  
	pieChartGraph.axisSet = nil;
    
	CPTMutableLineStyle* pieLineStyle = [CPTMutableLineStyle lineStyle];
	pieLineStyle.lineColor = [CPTColor colorWithGenericGray: 1];
    pieLineStyle.lineWidth = 2;
    
	// Add pie chart
	earningsPlot = [[[CPTPieChart alloc] init] autorelease];
	earningsPlot.dataSource = self;
	earningsPlot.delegate = self;
	earningsPlot.pieRadius = 130;
	earningsPlot.pieInnerRadius = 30;
	earningsPlot.identifier = @"earnings";
	earningsPlot.borderLineStyle = pieLineStyle;
	earningsPlot.startAngle = 0;
	earningsPlot.sliceDirection = CPTPieDirectionClockwise;
    earningsPlot.centerAnchor = CGPointMake(0.2, 0.6);
    earningsPlot.alignsPointsToPixels = YES;
    earningsPlot.labelOffset = 10;
	
    earningsPlot.shadowColor = CGColorCreateGenericGray(0, 1);
    earningsPlot.shadowRadius = 5.0;
    earningsPlot.shadowOffset = CGSizeMake(3, -3);
    earningsPlot.shadowOpacity = 0.3;

	[pieChartGraph addPlot: earningsPlot];
    
	// Add another pie chart
	spendingsPlot = [[[CPTPieChart alloc] init] autorelease];
	spendingsPlot.dataSource = self;
	spendingsPlot.delegate = self;
	spendingsPlot.pieRadius = 130;
	spendingsPlot.pieInnerRadius = 30;
	spendingsPlot.identifier = @"spendings";
	spendingsPlot.borderLineStyle = pieLineStyle;
	spendingsPlot.startAngle = 0;
	spendingsPlot.sliceDirection = CPTPieDirectionClockwise;
    spendingsPlot.centerAnchor = CGPointMake(0.7, 0.6);
    spendingsPlot.alignsPointsToPixels = YES;
    spendingsPlot.labelOffset = 10;
	
    spendingsPlot.shadowColor = CGColorCreateGenericGray(0, 1);
    spendingsPlot.shadowRadius = 5.0;
    spendingsPlot.shadowOffset = CGSizeMake(3, -3);
    spendingsPlot.shadowOpacity = 0.3;

	[pieChartGraph addPlot: spendingsPlot];
}

#pragma mark -
#pragma mark Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot: (CPTPlot*)plot
{
	if (plot == spendingsPlot) {
        return [spendingsCategories count];
    } else {
        return [earningsCategories count];
    }
}

- (NSNumber*)numberForPlot: (CPTPlot*)plot field: (NSUInteger)fieldEnum recordIndex: (NSUInteger)index
{
	if (fieldEnum == CPTPieChartFieldSliceWidth) {
        if (plot == spendingsPlot) {
            return [[spendingsCategories objectAtIndex: index] objectForKey: @"value"];
        } else {
            return [[earningsCategories objectAtIndex: index] objectForKey: @"value"];
        }
    }

	return (id)[NSNull null];
}

- (CPTLayer*)dataLabelForPlot: (CPTPlot*)plot recordIndex: (NSUInteger)index
{
	static CPTMutableTextStyle* labelStyle = nil;

    if (!labelStyle) {
        labelStyle = [[CPTMutableTextStyle alloc] init];
        labelStyle.color = [CPTColor blackColor];
        labelStyle.fontName = @"Lucida Grande";
        labelStyle.fontSize = 10;
    }
    
    CPTTextLayer* newLayer = nil;

	if (plot == spendingsPlot) {
		newLayer = [[[CPTTextLayer alloc] initWithText: [[spendingsCategories objectAtIndex: index] objectForKey: @"name"] style: labelStyle] autorelease];
	} else {
		newLayer = [[[CPTTextLayer alloc] initWithText: [[earningsCategories objectAtIndex: index] objectForKey: @"name"] style: labelStyle] autorelease];
    }

	return newLayer;
}

-(CGFloat)radialOffsetForPieChart:(CPTPieChart *)pieChart recordIndex: (NSUInteger)index
{
    CGFloat result = 0.0;
    
    if (pieChart == spendingsPlot) {
        if (index == spendingsExplosionIndex) {
            result = 20.0;
        }
    } else {
        if (index == earningsExplosionIndex) {
            result = 20.0;
        }
    }

    return result;
}

- (CPTFill*)sliceFillForPieChart: (CPTPieChart*)pieChart recordIndex: (NSUInteger)index
{
    NSColor* color;
    
   if (pieChart == spendingsPlot) {
       color = [[spendingsCategories objectAtIndex: index] objectForKey: @"color"];
   } else {
       color = [[earningsCategories objectAtIndex: index] objectForKey: @"color"];
   }

    CPTGradient* gradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithCGColor: [[color highlightWithLevel: 0.5] CGColor]]
                                                        endingColor: [CPTColor colorWithCGColor: [color CGColor]]
                             ];
    gradient.angle = -45.0;
    CPTFill* gradientFill = [CPTFill fillWithGradient: gradient];

    return gradientFill;
}

#pragma mark -
#pragma mark Controller logic

- (void)pieChart: (CPTPieChart*)plot sliceWasSelectedAtRecordIndex: (NSUInteger)index
{
    currentPlot = plot;
    
    if (plot == earningsPlot) {
        if ((earningsExplosionIndex == index) || ([earningsCategories count] < 2)) {
            earningsExplosionIndex = -1;
        } else {
            earningsExplosionIndex = index;
        }
        [earningsPlot repositionAllLabelAnnotations];
    } else {
        if ((spendingsExplosionIndex == index) || ([spendingsCategories count] < 2)) {
            spendingsExplosionIndex = -1;
        } else {
            spendingsExplosionIndex = index;
        }
        [spendingsPlot repositionAllLabelAnnotations];
    }
    [pieChartGraph setNeedsLayout];
    
    CGRect bounds = plot.plotArea.bounds;
    currentPlotCenter = CGPointMake(bounds.origin.x + bounds.size.width * plot.centerAnchor.x,
                                    bounds.origin.y + bounds.size.height * plot.centerAnchor.y);
}

/**
 * Handler method for notifications sent from the graph host windows if something in the graphs need
 * adjustment, mostly due to user input.
 */
- (void)mouseHit: (NSNotification*)notification
{
    if ([[notification name] isEqualToString: PecuniaHitNotification]) {
        NSDictionary* parameters = [notification userInfo];
        NSString* type = [parameters objectForKey: @"type"];
        BOOL isMouseDown = [type isEqualToString: @"mouseDown"];
        if (currentPlot == nil) {
            if (isMouseDown) {
                earningsExplosionIndex = -1;
                spendingsExplosionIndex = -1;
                [earningsPlot repositionAllLabelAnnotations];
                [spendingsPlot repositionAllLabelAnnotations];
                [pieChartGraph setNeedsLayout];
            }
        } else {
            NSNumber* x = [parameters objectForKey: @"x"];
            NSNumber* y = [parameters objectForKey: @"y"];
            
            if (isMouseDown) {
                lastMousePosition = NSMakePoint([x floatValue], [y floatValue]);
                lastMouseDistance = sqrt(pow(lastMousePosition.x - currentPlotCenter.x, 2) + pow(lastMousePosition.y - currentPlotCenter.y, 2));
                lastAngle = atan2(lastMousePosition.y - currentPlotCenter.y, lastMousePosition.x - currentPlotCenter.x);
            } else {
                if ([type isEqualToString: @"mouseUp"]) {
                    currentPlot = nil;
                } else {
                    if ([type isEqualToString: @"mouseDragged"]) {
                        CGFloat distance = sqrt(pow([x floatValue] - currentPlotCenter.x, 2) + pow([y floatValue] - currentPlotCenter.y, 2));
                        CGFloat newRadius = currentPlot.pieRadius + (distance - lastMouseDistance);
                        if (newRadius < 130) {
                            newRadius = 130;
                        }
                        currentPlot.pieRadius = newRadius;
                        lastMousePosition = NSMakePoint([x floatValue], [y floatValue]);
                        lastMouseDistance = sqrt(pow(lastMousePosition.x - currentPlotCenter.x, 2) + pow(lastMousePosition.y - currentPlotCenter.y, 2));
                        
                        CGFloat newAngle = atan2(lastMousePosition.y - currentPlotCenter.y, lastMousePosition.x - currentPlotCenter.x);
                        currentPlot.startAngle += newAngle - lastAngle;
                        lastAngle = newAngle;
                    }
                }
            }
        }
    }
}

- (void)setCategory: (Category*)newCategory
{
    currentCategory = newCategory;
    [self updateValues];
}

- (void)updateValues
{
    [spendingsCategories removeAllObjects];
    [earningsCategories removeAllObjects];
    
    if (currentCategory == nil) {
        return;
    }
    
    NSMutableSet* childs = [currentCategory mutableSetValueForKey: @"children"];
    
    if([childs count] > 0) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL balance = [userDefaults boolForKey: @"balanceCategories"];
        
        NSEnumerator* enumerator = [childs objectEnumerator];
        NSDecimalNumber* zero = [NSDecimalNumber zero];
        Category* childCategory;
        NSDecimalNumber* result;

        while ((childCategory = [enumerator nextObject])) {
            if (balance) {
                result = [childCategory valuesOfType: cat_all from: fromDate to: toDate];

                NSMutableDictionary* pieData = [NSMutableDictionary dictionaryWithCapacity: 4];
                [pieData setObject: [childCategory localName ] forKey: @"name"];
                [pieData setObject: result forKey: @"value"];
                [pieData setObject: currentCategory.currency forKey:@"currency"];
                [pieData setObject: childCategory.categoryColor forKey: @"color"];

                if ([result compare: zero] == NSOrderedAscending) {
                    [spendingsCategories addObject: pieData];
                } else {
                    [earningsCategories addObject: pieData];
                }
            } else {
                result = [childCategory valuesOfType: cat_spendings from: fromDate to: toDate];

                if ([result compare: zero] != NSOrderedSame) {
                    NSMutableDictionary* pieData = [NSMutableDictionary dictionaryWithCapacity: 4];
                    [pieData setObject: [childCategory localName ] forKey: @"name"];
                    [pieData setObject: result forKey: @"value"];
                    [pieData setObject: currentCategory.currency forKey:@"currency"];
                    [pieData setObject: childCategory.categoryColor forKey: @"color"];
                    
                    [spendingsCategories addObject: pieData];
                }
                
                result = [childCategory valuesOfType: cat_earnings from: fromDate to: toDate];
                if ([result compare: zero] != NSOrderedSame) {
                    NSMutableDictionary* pieData = [NSMutableDictionary dictionaryWithCapacity: 4];
                    [pieData setObject: [childCategory localName ] forKey: @"name"];
                    [pieData setObject: result forKey: @"value"];
                    [pieData setObject: currentCategory.currency forKey:@"currency"];
                    [pieData setObject: childCategory.categoryColor forKey: @"color"];
                    
                    [earningsCategories addObject: pieData];
                }
            }
        }
    }
    
    earningsExplosionIndex = -1;
    spendingsExplosionIndex = -1;
    earningsPlot.startAngle = 0;
    earningsPlot.pieRadius = 130;
    spendingsPlot.startAngle = 0;
    spendingsPlot.pieRadius = 130;

    [pieChartGraph reloadData];
}

- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to
{
    [fromDate release];
    fromDate = [from retain];
    [toDate release];
    toDate = [to retain];
    [self updateValues];
}

-(NSView*)mainView
{
    return mainView;
}

-(void)print
{
    NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo ];
    [printInfo setTopMargin:45 ];
    [printInfo setBottomMargin:45 ];
    [printInfo setHorizontalPagination:NSFitPagination ];
    [printInfo setVerticalPagination:NSFitPagination ];
    NSPrintOperation *printOp;
    printOp = [NSPrintOperation printOperationWithView: mainView printInfo: printInfo ];
    [printOp setShowsPrintPanel:YES ];
    [printOp runOperation ];	
}


-(IBAction)balancingRuleChanged: (id)sender
{
    [self updateValues ];
}

- (IBAction)showHelp: (id)sender
{
}

@end

