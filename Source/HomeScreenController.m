/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "HomeScreenController.h"
#import "GraphicsAdditions.h"
#import "PreferenceController.h"

#import "StockCard.h"
#import "AssetsCard.h"
#import "RecentTransfersCard.h"
#import "NextTransfersCard.h"

NSString *const HomeScreenCardClickedNotification = @"HomeScreenCardClicked";

@interface HomeScreenController ()

@end

@implementation HomeScreenController

- (id)initWithNibName: (NSString *)nibNameOrNil bundle: (NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    if (self != nil) {
    }
    
    return self;
}

#pragma mark - PecuniaTabItem protocol

- (void)print
{

}

- (NSView *)mainView
{
    return self.view;
}

- (void)activate
{

}

- (void)deactivate
{

}

@end

#pragma mark - HomeScreenCard

@interface HomeScreenCard ()
{
    NSAttributedString *titleString;
    NSBezierPath *gripPath;
    NSBezierPath *borderFillPath;
    NSBezierPath *borderPath;

    NSTrackingArea *trackingArea;
}

@end

@implementation HomeScreenCard

@synthesize title;

+ (BOOL)clickable
{
    return NO;
}

- (id)initWithFrame: (NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self != nil) {
        title = @"No title";
        self.wantsLayer = YES;

        CGColorRef color = CGColorCreateFromNSColor([NSColor blackColor]);
        self.layer.shadowColor = color;
        CGColorRelease(color);

        self.layer.shadowRadius = 5;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowOpacity = 0.5;

        [self updateStoredStructures];

        if (self.class.clickable) {
            [self updateTrackingArea];
        }
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)setTitle: (NSString *)aTitle
{
    title = aTitle;
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.388 green: 0.382 blue: 0.363 alpha: 1.000],
                                 NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameMedium size: 14]};
    titleString = [[NSAttributedString alloc] initWithString: title attributes: attributes];

}

- (void)updateStoredStructures
{
    NSRect bounds = NSInsetRect(self.bounds, 10, 10);
    bounds.origin.y = bounds.size.height - 3;
    bounds.size.height = 10;

    NSBezierPath *shadowPath = [NSBezierPath bezierPathWithOvalInRect: bounds];
    self.layer.shadowPath = shadowPath.cgPath;

    gripPath = [NSBezierPath bezierPath];
    CGFloat x1 = (int)titleString.size.width + 25;
    CGFloat x2 = NSMaxX(bounds) - 10;
    CGFloat y = 20.5;
    [gripPath moveToPoint: NSMakePoint(x1, y)];
    [gripPath lineToPoint: NSMakePoint(x2, y)];
    y += 2;
    [gripPath moveToPoint: NSMakePoint(x1 + 2, y)];
    [gripPath lineToPoint: NSMakePoint(x2 - 2, y)];
    y += 2;
    [gripPath moveToPoint: NSMakePoint(x1, y)];
    [gripPath lineToPoint: NSMakePoint(x2, y)];

    [gripPath setLineWidth: 1];
    CGFloat lineDash[2] = {1, 3};
    [gripPath setLineDash: lineDash count: 2 phase: 0];

    CGFloat radius = 15;

    bounds = self.bounds;
    bounds.size.height -= 10;

    borderFillPath = [NSBezierPath bezierPath];
    [borderFillPath moveToPoint: NSMakePoint(NSMinX(bounds), NSMaxY(bounds))];
    [borderFillPath lineToPoint: NSMakePoint(NSMinX(bounds), NSMinY(bounds) + radius)];
    [borderFillPath appendBezierPathWithArcFromPoint: NSMakePoint(NSMinX(bounds), NSMinY(bounds))
                                             toPoint: NSMakePoint(NSMinX(bounds) + radius, NSMinY(bounds))
                                              radius: radius];
    [borderFillPath appendBezierPathWithArcFromPoint: NSMakePoint(NSMaxX(bounds), NSMinY(bounds))
                                             toPoint: NSMakePoint(NSMaxX(bounds), NSMinY(bounds) + radius)
                                              radius: radius];
    [borderFillPath lineToPoint: NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];
    [borderFillPath closePath];

    bounds.origin.x += 0.5;
    bounds.size.width -= 1;
    bounds.origin.y += 0.5;
    bounds.size.height--;

    borderPath = [NSBezierPath bezierPath];
    [borderPath moveToPoint: NSMakePoint(NSMinX(bounds), NSMaxY(bounds))];
    [borderPath lineToPoint: NSMakePoint(NSMinX(bounds), NSMinY(bounds) + radius)];
    [borderPath appendBezierPathWithArcFromPoint: NSMakePoint(NSMinX(bounds), NSMinY(bounds))
                                         toPoint: NSMakePoint(NSMinX(bounds) + radius, NSMinY(bounds))
                                          radius: radius];
    [borderPath appendBezierPathWithArcFromPoint: NSMakePoint(NSMaxX(bounds), NSMinY(bounds))
                                         toPoint: NSMakePoint(NSMaxX(bounds), NSMinY(bounds) + radius)
                                          radius: radius];
    [borderPath lineToPoint: NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];
    [borderPath closePath];
}

- (void)resizeWithOldSuperviewSize: (NSSize)oldSize
{
    [super resizeWithOldSuperviewSize: oldSize];
    [self updateStoredStructures];
}

- (void)drawRect: (NSRect)dirtyRect
{
    [[NSColor colorWithCalibratedRed: 0.945 green: 0.927 blue: 0.883 alpha: 1.000] setFill];
    [borderFillPath fill];

    [[NSColor colorWithCalibratedWhite: 0.3 alpha: 0.3] setStroke];
    [borderPath stroke];

    // Title and grip.
    [titleString drawAtPoint: NSMakePoint(15, 10)];

    [[NSColor colorWithCalibratedWhite: 0.3 alpha: 0.5] setStroke];
    [gripPath stroke];
}

- (void)updateTrackingArea
{
    if (trackingArea != nil) {
        [self removeTrackingArea: trackingArea];
    }

    trackingArea = [[NSTrackingArea alloc] initWithRect: self.bounds
                                                options: NSTrackingCursorUpdate | NSTrackingActiveInActiveApp
                                                  owner: self
                                               userInfo: nil];
    [self addTrackingArea: trackingArea];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];

    [self updateTrackingArea];
}

-(void)cursorUpdate: (NSEvent *)theEvent

{
    if (self.class.clickable) {
        [[NSCursor pointingHandCursor] set];
    } else {
        [super cursorUpdate: theEvent];
    }

}

- (void)cardClicked: (id)object
{
    [NSNotificationCenter.defaultCenter postNotificationName: HomeScreenCardClickedNotification
                                                      object: object];
}

@end

#pragma mark - HomeScreenContent

@interface HomeScreenContent : NSView
{
@private
    NSColor  *background;
    NSImage  *flow;
    NSImage  *pecuniaVertical;
    NSShadow *borderShadow;
    NSDateFormatter* formatter;
    NSDictionary *mainDateAttributes;
    NSDictionary *largeDateAttributes;
}

@end

@implementation HomeScreenContent

- (id)initWithFrame: (NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self != nil) {
        NSImage *image = [NSImage imageNamed: @"background-pattern"];
        if (image != nil) {
            background = [NSColor colorWithPatternImage: image];
        } else {
            background = [NSColor colorWithDeviceWhite: 110.0 / 255.0 alpha: 1];
        }

        flow = [NSImage imageNamed: @"flow"];
        pecuniaVertical = [NSImage imageNamed: @"pecunia-vertical"];
        borderShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 0 alpha: 0.5]
                                                offset: NSMakeSize(1, -1)
                                            blurRadius: 5.0];

        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle: NSDateFormatterMediumStyle];
        [formatter setDateFormat: @"MMM\ndd\nYYYY"];
        [formatter setTimeZone: [NSTimeZone systemTimeZone]];

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSCenterTextAlignment;
        [paragraphStyle setMaximumLineHeight: 15];
        mainDateAttributes = @{NSForegroundColorAttributeName: [NSColor whiteColor],
                               NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameMedium size: 18],
                               NSParagraphStyleAttributeName: paragraphStyle};

        paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSCenterTextAlignment;
        [paragraphStyle setMaximumLineHeight: 38];
        largeDateAttributes = @{NSForegroundColorAttributeName: [NSColor whiteColor],
                                NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameBold size: 36],
                                NSParagraphStyleAttributeName: paragraphStyle};

        [self setUpCards];

    }
    return self;
}

/**
 * Reads stored settings and creates the homescreen cards. If there are no settings a default set
 * is created.
 */
- (void)setUpCards
{
    // Layouting these cards is done explicitly.
    HomeScreenCard *card = [[RecentTransfersCard alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
    card.title =  NSLocalizedString(@"AP952", nil);
    [self addSubview: card];

    card = [[AssetsCard alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
    card.title =  NSLocalizedString(@"AP953", nil);
    [self addSubview: card];

    card = [[NextTransfersCard alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
    card.title =  NSLocalizedString(@"AP954", nil);
    [self addSubview: card];

    card = [[StockCard alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
    card.title =  NSLocalizedString(@"AP950", nil);
    [self addSubview: card];

    card = [[HomeScreenCard alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
    card.title =  NSLocalizedString(@"AP955", nil);
    [self addSubview: card];

}

- (BOOL)isFlipped
{
    return YES;
}

/**
 * Layouts all child views in a specific tile format.
 */
- (void)resizeSubviewsWithOldSize: (NSSize)oldSize
{
    // Children are laid out as they are listed in the subview collection.
    // The base layout is a 3 columns, 2 rows grid which is filled from top left to bottom right.
    // But only 5 subviews are actually used. The last space is not used by cards.
    // The middle column has 40% while the others have 30% of the total width.
    NSUInteger baseWidth = (NSWidth(self.bounds) - 100) / 10;
    NSUInteger baseHeight = (NSHeight(self.bounds) - 60) / 2;
    NSUInteger x = 30;
    NSUInteger y = 30;

    NSUInteger i = 0;
    while (i < 5) {
        NSView *child = self.subviews[i];
        NSUInteger width = i % 3 == 1 ? 4 * baseWidth : 3 * baseWidth;
        child.frame = NSMakeRect(x, y, width, baseHeight);
        x += width + 20;
        if (++i % 3 == 0) {
            x = 30;
            y += baseHeight + 10;
        }

        [child resizeWithOldSuperviewSize: oldSize];
    }
}

- (void)drawRect: (NSRect)rect
{
    [NSGraphicsContext saveGraphicsState];

    // Background.
    [background setFill];
    [NSBezierPath fillRect: [self bounds]];

    // Outer bounds with shadow.
    NSRect bounds = [self bounds];
    bounds.size.width -= 20;
    bounds.size.height -= 20;
    bounds.origin.x += 10;
    bounds.origin.y += 10;

    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect: bounds xRadius: 5 yRadius: 5];
    [borderShadow set];
    [[NSColor colorWithCalibratedRed: 0.825 green: 0.808 blue: 0.760 alpha: 1.000] set];
    [borderPath fill];

    // Date background. Use the still active shadow.
    borderPath = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect((int)NSWidth(bounds) - 100, NSHeight(bounds) - 350, 95, 95)];
    [[NSColor blackColor] set];
    [borderPath fill];

    [NSGraphicsContext restoreGraphicsState];

    // Background images.
    CGFloat x = NSWidth(bounds) - flow.size.width - 130;
    [flow drawInRect: NSMakeRect(x, NSHeight(bounds) - flow.size.height + 20, flow.size.width, flow.size.height)
            fromRect: NSZeroRect
           operation: NSCompositeSourceOver
            fraction: 1
      respectFlipped: YES
               hints: nil];

    x = NSWidth(bounds) - 75;
    [pecuniaVertical drawInRect: NSMakeRect(x, NSHeight(bounds) - pecuniaVertical.size.height - 10,
                                            pecuniaVertical.size.width, pecuniaVertical.size.height)
                       fromRect: NSZeroRect
                      operation: NSCompositeSourceOver
                       fraction: 1
                 respectFlipped: YES
                          hints: nil];

    NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString: [formatter stringFromDate: [NSDate date]]];
    [dateString addAttributes: mainDateAttributes range: NSMakeRange(0, dateString.length)];

    // Set a larger font for the day part.
    NSString *simpleString = dateString.string;
    NSRange range = [simpleString rangeOfString: @"\n"];
    [dateString addAttributes: largeDateAttributes range: NSMakeRange(range.location + 1, 2)];
    [dateString drawInRect: NSMakeRect(bounds.size.width - 78, NSHeight(bounds) - 335, 54, 70)];
}

@end
