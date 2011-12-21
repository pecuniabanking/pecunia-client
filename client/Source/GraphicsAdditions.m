//
//  GraphicsAdditions.m
//  Pecunia
//
//  Created by Mike Lischke on 29.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "GraphicsAdditions.h"

@implementation NSColor (PecuniaAdditions)

static NSMutableArray* defaultAccountColors;
static NSMutableArray* defaultCategoryColors;

+ (void)loadDefaultColors
{
    // Generate our random seed.
    srandom(time(NULL));
	
    defaultAccountColors = [[NSMutableArray arrayWithCapacity: 10] retain];
    defaultCategoryColors = [[NSMutableArray arrayWithCapacity: 10] retain];
	
	NSString* path = [[NSBundle mainBundle] resourcePath];
	path = [path stringByAppendingString: @"/Colors.acf"];
	
	NSError* error = nil;
	NSString* s = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
	if (error) {
		NSLog(@"Error reading default colors file at %@\n%@", path, [error localizedFailureReason]);
	} else {
		NSArray* lines = [s componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
        NSEnumerator* enumerator = [lines objectEnumerator];
        NSString* line = [enumerator nextObject];
        if (([lines count] > 3) && [line isEqualToString: @"ACF 1.0"]) {
            
            // Scan for data start.
            while (line = [enumerator nextObject]) {
                if ([line isEqualToString: @"Data:"])
                    break;
            }
            
            // Read color values.
            while (line = [enumerator nextObject]) {
                NSArray* components = [line componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                line = [enumerator nextObject];
                if (line == nil || [components count] < 3) {
                    break;
                }
                
                NSColor* color = [NSColor colorWithDeviceRed: [[components objectAtIndex: 0] intValue] / 65535.0
                                                       green: [[components objectAtIndex: 1] intValue] / 65535.0
                                                        blue: [[components objectAtIndex: 2] intValue] / 65535.0
                                                       alpha: 1];
                if ([line hasPrefix: @"Default Account Color"]) {
                    [defaultAccountColors addObject: color];
                } else {
                    if ([line hasPrefix: @"Default Category Color"]) {
                        [defaultCategoryColors addObject: color];
                    }
                }
            }
        }
	}
}

/**
 * Returns the next available default color for accounts. These colors are taken from a list
 * of default colors. If this list is exhausted random colors are returned.
 */
+ (NSColor*)nextDefaultAccountColor
{
    if (defaultAccountColors == nil) {
        [self loadDefaultColors];
    }

    if ([defaultAccountColors count] > 0) {
        NSColor* result = [defaultAccountColors objectAtIndex: 0];
        [defaultAccountColors removeObjectAtIndex: 0];
        
        return result;
    }

    // No colors left. Generate a random one with components between 128 and 255 (0.5 - 1).
    return [NSColor colorWithDeviceRed: (128 + random() % 127) / 256
                                 green: (128 + random() % 127) / 256
                                  blue: (128 + random() % 127) / 256
                                 alpha: 1];
}

/**
 * Like nextDefaultAccountColor but for categories.
 */
+ (NSColor*)nextDefaultCategoryColor
{
    if (defaultCategoryColors == nil) {
        [self loadDefaultColors];
    }

    if ([defaultCategoryColors count] > 0) {
        NSColor* result = [defaultCategoryColors objectAtIndex: 0];
        [defaultCategoryColors removeObjectAtIndex: 0];
        
        return result;
    }

    // No colors left. Generate a random one with components between 128 and 255 (0.5 - 1).
    return [NSColor colorWithDeviceRed: (32 + random() % 200) / 255.0
                                 green: (32 + random() % 200) / 255.0
                                  blue: (32 + random() % 200) / 255.0
                                 alpha: 1];
}

- (CGColorRef) CGColor
{
    CGColorSpaceRef colorspace = [[self colorSpace] CGColorSpace];
    const NSInteger nComponents = [self numberOfComponents];
    
    CGFloat components[nComponents];
    
    [self getComponents: components];
    
    CGColorRef c = CGColorCreate(colorspace, components);
        
    return (CGColorRef)[(id)c autorelease];
}

@end


@implementation NSShadow (PecuniaAdditions)

/**
 * Simplify shadow creation.
 */
- (id)initWithColor: (NSColor *)color offset: (NSSize)offset blurRadius: (CGFloat)blur
{
    self = [self init];
    
    if (self != nil)
    {
        self.shadowColor = color;
        self.shadowOffset = offset;
        self.shadowBlurRadius = blur;
    }
    
    return self;
}

@end

// Remove/comment out this line of you don't want to use undocumented functions.
#define MCBEZIER_USE_PRIVATE_FUNCTION

#ifdef MCBEZIER_USE_PRIVATE_FUNCTION
extern CGPathRef CGContextCopyPath(CGContextRef context);
#endif

static void CGPathCallback(void *info, const CGPathElement *element)
{
    NSBezierPath *path = info;
    CGPoint *points = element->points;
    
    switch (element->type)
    {
        case kCGPathElementMoveToPoint:
        {
            [path moveToPoint:NSMakePoint(points[0].x, points[0].y)];
            break;
        }
        case kCGPathElementAddLineToPoint:
        {
            [path lineToPoint:NSMakePoint(points[0].x, points[0].y)];
            break;
        }
        case kCGPathElementAddQuadCurveToPoint:
        {
            // NOTE: This is untested.
            NSPoint currentPoint = [path currentPoint];
            NSPoint interpolatedPoint = NSMakePoint((currentPoint.x + 2 * points[0].x) / 3, (currentPoint.y + 2 * points[0].y) / 3);
            [path curveToPoint:NSMakePoint(points[1].x, points[1].y) controlPoint1:interpolatedPoint controlPoint2:interpolatedPoint];
            break;
        }
        case kCGPathElementAddCurveToPoint:
        {
            [path curveToPoint:NSMakePoint(points[2].x, points[2].y) controlPoint1:NSMakePoint(points[0].x, points[0].y) controlPoint2:NSMakePoint(points[1].x, points[1].y)];
            break;
        }
        case kCGPathElementCloseSubpath:
        {
            [path closePath];
            break;
        }
    }
}

@implementation NSBezierPath (PecuniaAdditions)

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    CGPathApply(pathRef, path, CGPathCallback);
    
    return path;
}

// Method borrowed from Google's Cocoa additions
- (CGPathRef)cgPath
{
    CGMutablePathRef thePath = CGPathCreateMutable();
    if (!thePath) return nil;
    
    unsigned int elementCount = [self elementCount];
    
    // The maximum number of points is 3 for a NSCurveToBezierPathElement.
    // (controlPoint1, controlPoint2, and endPoint)
    NSPoint controlPoints[3];
    
    unsigned int i;
    for (i = 0; i < elementCount; i++)
    {
        switch ([self elementAtIndex:i associatedPoints:controlPoints])
        {
            case NSMoveToBezierPathElement:
                CGPathMoveToPoint(thePath, &CGAffineTransformIdentity, controlPoints[0].x, controlPoints[0].y);
                break;
            case NSLineToBezierPathElement:
                CGPathAddLineToPoint(thePath, &CGAffineTransformIdentity, controlPoints[0].x, controlPoints[0].y);
                break;
            case NSCurveToBezierPathElement:
                CGPathAddCurveToPoint(thePath, &CGAffineTransformIdentity, 
                                      controlPoints[0].x, controlPoints[0].y,
                                      controlPoints[1].x, controlPoints[1].y,
                                      controlPoints[2].x, controlPoints[2].y);
                break;
            case NSClosePathBezierPathElement:
                CGPathCloseSubpath(thePath);
                break;
            default:
                NSLog(@"Unknown element at [NSBezierPath (GTMBezierPathCGPathAdditions) cgPath]");
                break;
        };
    }
    return thePath;
}

- (NSBezierPath *)pathWithStrokeWidth: (CGFloat)strokeWidth
{
#ifdef MCBEZIER_USE_PRIVATE_FUNCTION
    NSBezierPath *path = [self copy];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGPathRef pathRef = [path cgPath];
    [path release];
    
    CGContextSaveGState(context);
    
    CGContextBeginPath(context);
    CGContextAddPath(context, pathRef);
    CGContextSetLineWidth(context, strokeWidth);
    CGContextReplacePathWithStrokedPath(context);
    CGPathRef strokedPathRef = CGContextCopyPath(context);
    CGContextBeginPath(context);
    NSBezierPath *strokedPath = [NSBezierPath bezierPathWithCGPath:strokedPathRef];
    
    CGContextRestoreGState(context);
    
    CFRelease(pathRef);
    CFRelease(strokedPathRef);
    
    return strokedPath;
#else
    return nil;
#endif//MCBEZIER_USE_PRIVATE_FUNCTION
}

- (void)fillWithInnerShadow: (NSShadow *)shadow borderOnly: (BOOL) borderOnly
{
    [NSGraphicsContext saveGraphicsState];
    
    NSSize offset = shadow.shadowOffset;
    NSSize originalOffset = offset;
    CGFloat radius = shadow.shadowBlurRadius;
    NSRect bounds = NSInsetRect(self.bounds, -(ABS(offset.width) + radius), -(ABS(offset.height) + radius));
    offset.height += bounds.size.height;
    shadow.shadowOffset = offset;
    NSAffineTransform *transform = [NSAffineTransform transform];
    if ([[NSGraphicsContext currentContext] isFlipped])
        [transform translateXBy: 0 yBy: bounds.size.height];
    else
        [transform translateXBy: 0 yBy: -bounds.size.height];
    
    NSBezierPath *drawingPath = [NSBezierPath bezierPathWithRect: bounds];
    [drawingPath setWindingRule: NSEvenOddWindingRule];
    [drawingPath appendBezierPath: self];
    [drawingPath transformUsingAffineTransform: transform];
    
    [self addClip];
    [shadow set];
    [[NSColor blackColor] set];
    if (borderOnly)
        [drawingPath stroke];
    else
        [drawingPath fill];
    
    shadow.shadowOffset = originalOffset;
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawBlurWithColor:(NSColor *)color radius:(CGFloat)radius
{
    NSRect bounds = NSInsetRect(self.bounds, -radius, -radius);
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = NSMakeSize(0, bounds.size.height);
    shadow.shadowBlurRadius = radius;
    shadow.shadowColor = color;
    NSBezierPath *path = [self copy];
    NSAffineTransform *transform = [NSAffineTransform transform];
    if ([[NSGraphicsContext currentContext] isFlipped])
        [transform translateXBy:0 yBy:bounds.size.height];
    else
        [transform translateXBy:0 yBy:-bounds.size.height];
    [path transformUsingAffineTransform:transform];
    
    [NSGraphicsContext saveGraphicsState];
    
    [shadow set];
    [[NSColor blackColor] set];
    NSRectClip(bounds);
    [path fill];
    
    [NSGraphicsContext restoreGraphicsState];
    
    [path release];
    [shadow release];
}

// Credit for the next two methods goes to Matt Gemmell
- (void)strokeInside
{
    /* Stroke within path using no additional clipping rectangle. */
    [self strokeInsideWithinRect: NSZeroRect];
}

- (void)strokeInsideWithinRect:(NSRect)clipRect
{
    NSGraphicsContext *thisContext = [NSGraphicsContext currentContext];
    float lineWidth = [self lineWidth];
    
    /* Save the current graphics context. */
    [thisContext saveGraphicsState];
    
    /* Double the stroke width, since -stroke centers strokes on paths. */
    [self setLineWidth:(lineWidth * 2.0)];
    
    /* Clip drawing to this path; draw nothing outwith the path. */
    [self setClip];
    
    /* Further clip drawing to clipRect, usually the view's frame. */
    if (clipRect.size.width > 0.0 && clipRect.size.height > 0.0)
        [NSBezierPath clipRect:clipRect];
    
    /* Stroke the path. */
    [self stroke];
    
    /* Restore the previous graphics context. */
    [thisContext restoreGraphicsState];
    [self setLineWidth:lineWidth];
}

@end

@implementation NSView (PecuniaAdditions)

/**
 * Returns an offscreen view containing all visual elements of this view for printing,
 * including CALayer content. Useful only for views that are layer-backed.
 */
- (NSView*)getPrintViewForLayerBackedView;
{
    NSRect bounds = self.bounds;
    int bitmapBytesPerRow = 4 * bounds.size.width;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context = CGBitmapContextCreate (NULL,
                                                  bounds.size.width,
                                                  bounds.size.height,
                                                  8,
                                                  bitmapBytesPerRow,
                                                  colorSpace,
                                                  kCGImageAlphaPremultipliedLast);
    if (context == NULL)
    {
        NSLog(@"getPrintViewForLayerBackedView: Failed to create context.");
        return nil;
    }
    
    CGColorSpaceRelease(colorSpace);

    [[self layer] renderInContext: context];
    CGImageRef img = CGBitmapContextCreateImage(context);
    NSImage* image = [[NSImage alloc] initWithCGImage: img size: bounds.size];
    
    NSImageView* canvas = [[NSImageView alloc] initWithFrame: bounds];
    [canvas setImage: image];

    CFRelease(img);
    CFRelease(context);
    return [canvas autorelease];
}

@end