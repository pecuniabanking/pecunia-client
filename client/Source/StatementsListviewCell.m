/** 
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#import "StatementsListViewCell.h"
#import "GraphicsAdditions.h"
#import "CurrencyValueTransformer.h"

#import "GraphicsAdditions.h"

@implementation StatementsListViewCell

@synthesize delegate;
@synthesize hasUnassignedValue;

+ (id)defaultAnimationForKey: (NSString *)key
{
    // No animations for the cells please. In a class where cells are constantly added and removed
    // this gets annoying quickly otherwise. This does only disable animations for the cell itself
    // not its content.
    return nil;
}

#pragma mark Init/Dealloc

-(id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self != nil)
    {
    }
    return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void) setHeaderHeight: (int) aHeaderHeight
{
    headerHeight = aHeaderHeight;
    if (headerHeight > 0) {
        [dateLabel setHidden: NO];
        [turnoversLabel setHidden: NO];
    } else {
        [dateLabel setHidden: YES];
        [turnoversLabel setHidden: YES];
    }

    [self setNeedsDisplay: YES];
}

static CurrencyValueTransformer* currencyTransformer;

- (void)setDetailsDate: (NSString*) date
             turnovers: (NSString*) turnovers
            remoteName: (NSString*) name
               purpose: (NSString*) purpose
            categories: (NSString*) categories
                 value: (NSDecimalNumber*) value
                 saldo: (NSDecimalNumber*) saldo
              currency: (NSString*) currency
       transactionText: (NSString*) transactionText
                 index: (NSUInteger) theIndex
{
    index = theIndex;
    
    [dateLabel setStringValue: date];
    [turnoversLabel setStringValue: turnovers];
    
    [remoteNameLabel setStringValue: name];
    [remoteNameLabel setToolTip: name];
    
    [purposeLabel setStringValue: purpose];
    [purposeLabel setToolTip: purpose];
    
    [categoriesLabel setStringValue: categories];
    [categoriesLabel setToolTip: categories];
    
    [valueLabel setObjectValue: value];
    [saldoLabel setObjectValue: saldo];
    
    [transactionTypeLabel setObjectValue: transactionText];
    [transactionTypeLabel setToolTip: transactionText];
    
    if (currencyTransformer == nil)
        currencyTransformer = [[[CurrencyValueTransformer alloc] init] retain];
    
    NSString* symbol = [currencyTransformer transformedValue: currency];
    [currencyLabel setStringValue: symbol];
    [[[valueLabel cell] formatter] setCurrencyCode: currency]; // Important for proper display of the value, even without currency.
    [saldoCurrencyLabel setStringValue: symbol];
    [[[saldoLabel cell] formatter] setCurrencyCode: currency];

    [self setNeedsDisplay: YES];
}

- (void)setTextAttributesForPositivNumbers: (NSDictionary*) positiveAttributes
                           negativeNumbers: (NSDictionary*) negativeAttributes
{
    [[[valueLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
    [[[valueLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];
    [[[saldoLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
    [[[saldoLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];
}

#pragma mark Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];

    [dateLabel setStringValue: @""];
    [turnoversLabel setStringValue: @""];
    [remoteNameLabel setStringValue: @""];
    [purposeLabel setStringValue: @""];
    [categoriesLabel setStringValue: @""];
    [valueLabel setObjectValue: @""];
    [saldoLabel setObjectValue: @""];
    [transactionTypeLabel setObjectValue: @""];
    [transactionTypeLabel setObjectValue: @""];
    hasUnassignedValue = NO;
    isNew = NO;
    index = -1;
}

#pragma mark Drawing

- (void)setIsNew: (BOOL)flag
{
    [newImage setHidden: !flag];
}

- (void)showActivator: (BOOL)flag markActive: (BOOL)active
{
    [checkbox setHidden: !flag];
    [checkbox setState: active ? NSOnState : NSOffState];
}

- (void)refresh
{
    [self setNeedsDisplay: YES];
}
- (IBAction)activationChanged: (id)sender
{
    if ([self.delegate conformsToProtocol: @protocol(StatementsListViewNotificationProtocol)]) {
        [self.delegate cellActivationChanged: ([checkbox state] == NSOnState ? YES : NO) forIndex: index];
    }
}

static NSGradient* innerGradient;
static NSGradient* innerGradientSelected;
static NSGradient* headerGradient;
static NSShadow* innerShadow;
static NSImage* stripeImage;

- (void) setupDrawStructures
{
    innerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithDeviceRed: 240 / 255.0 green: 240 / 255.0 blue: 240 / 255.0 alpha: 1], (CGFloat) 0.2,
                     [NSColor whiteColor], (CGFloat) 0.8,
                     nil];
    innerGradientSelected = [[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor colorWithDeviceWhite: 234 / 255.0 alpha: 1], (CGFloat) 0,
                             [NSColor colorWithDeviceWhite: 245 / 255.0 alpha: 1], (CGFloat) 1,
                             nil];
    headerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                      [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 1], (CGFloat) 0,
                      //[NSColor applicationColorForKey: @"Positive Gradient (low)"], (CGFloat) 0,
                      [NSColor colorWithDeviceWhite: 120 / 255.0 alpha: 1], (CGFloat) 1,
                      //[NSColor applicationColorForKey: @"Positive Gradient (high)"], (CGFloat) 1,
                      nil];
    innerShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithCalibratedWhite: 0.0 alpha: .75]
                                           offset: NSMakeSize(0, -1)
                                       blurRadius: 3.0];
    stripeImage = [NSImage imageNamed: @"slanted_stripes.png"];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (innerGradient == nil)
        [self setupDrawStructures];
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    
    NSBezierPath* path;
    NSRect bounds = [self bounds];
    if (headerHeight > 0)
    {
        path = [NSBezierPath bezierPathWithRect: NSMakeRect(bounds.origin.x,
                                                            bounds.size.height - headerHeight,
                                                            bounds.size.width,
                                                            headerHeight)];
        [headerGradient drawInBezierPath: path angle: 90.0];
        bounds.size.height -= headerHeight;
    }
	path = [NSBezierPath bezierPathWithRect: bounds];
    
    if ([self isSelected])
    {
        [innerGradientSelected drawInBezierPath: path angle: 90.0];
        [path fillWithInnerShadow: innerShadow borderOnly: NO];
    }
    else
    {
        [innerGradient drawInBezierPath: path angle: 90.0];
    }
    
    [[NSColor colorWithDeviceWhite: 0 / 255.0 alpha: 1] set];
    path = [NSBezierPath bezierPath];
    [path setLineWidth: 1];
    
    // Separator lines in front of every text in the main part.
    CGFloat left = [remoteNameLabel frame].origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 4, 10)];
    [path lineToPoint: NSMakePoint(left - 4, 39)];
    left = [purposeLabel frame].origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 4, 10)];
    [path lineToPoint: NSMakePoint(left - 4, 39)];
    left = [categoriesLabel frame].origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 4, 10)];
    [path lineToPoint: NSMakePoint(left - 4, 39)];
    left = [valueLabel frame].origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 4, 10)];
    [path lineToPoint: NSMakePoint(left - 4, 39)];
    
    // Left, right and bottom lines.
    [path moveToPoint: NSMakePoint(0, 0)];
    [path lineToPoint: NSMakePoint(0, bounds.size.height + headerHeight)];
    [path moveToPoint: NSMakePoint(bounds.size.width, 0)];
    [path lineToPoint: NSMakePoint(bounds.size.width, bounds.size.height + headerHeight)];
    [path moveToPoint: NSMakePoint(0, 0)];
    [path lineToPoint: NSMakePoint(bounds.size.width, 0)];
    [[NSColor colorWithDeviceWhite: 210 / 255.0 alpha: 1] set];
    [path stroke];
    
    // Mark the value area if there is an unassigned value remaining.
    if (hasUnassignedValue)
    {
        NSRect area = [valueLabel frame];
        area.origin.y = 2;
        area.size.height = bounds.size.height - 4;
        area.size.width = stripeImage.size.width;
        
        // Tile the image into the area.
        NSRect imageRect = NSMakeRect(0, 0, stripeImage.size.width, stripeImage.size.height);
        while (area.origin.x < bounds.size.width - 4)
        {
            [stripeImage drawInRect: area fromRect: imageRect operation: NSCompositeSourceOver fraction: 1];
            area.origin.x += stripeImage.size.width;
        }
    }
    
    [context restoreGraphicsState];
    
}

@end
