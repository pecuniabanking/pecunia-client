/** 
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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

#import "TransfersListViewCell.h"

#import "GraphicsAdditions.h"
#import "CurrencyValueTransformer.h"

@implementation TransfersListViewCell

+ (id)defaultAnimationForKey: (NSString *)key
{
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
    [categoryColor release];
	[super dealloc];
}

static CurrencyValueTransformer* currencyTransformer;

- (void)setDetails: (NSDictionary *)details
{
    [dateLabel setStringValue: [details valueForKey: @"date"]];
    
    [remoteNameLabel setStringValue: [details valueForKey: @"remoteName"]];
    [remoteNameLabel setToolTip: [details valueForKey: @"remoteName"]];

    // The default line height for a multiline label is too large so we convert the given string
    // so it can have paragraph styles.
    NSMutableAttributedString *purpose = [[[NSMutableAttributedString alloc] initWithString: [details valueForKey: @"purpose"]] autorelease];
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setMaximumLineHeight: 12];
    [purpose addAttributes: [NSDictionary dictionaryWithObject: paragraphStyle forKey: NSParagraphStyleAttributeName] range: NSMakeRange(0, [purpose length])];
    [purposeLabel setAttributedStringValue: purpose];
    [purposeLabel setToolTip: [details valueForKey: @"purpose"]];
    
    [valueLabel setObjectValue: [details valueForKey: @"value"]];
    
    [bankNameLabel setStringValue: [details valueForKey: @"remoteBankName"]];
    [bankNameLabel setToolTip: [details valueForKey: @"remoteBankName"]];
    
    NSMutableAttributedString *account = [details valueForKey: @"account"];

    // Since we use an attributed string for the account label we have to set the alignment explicitly.
    paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setAlignment: NSRightTextAlignment];
    [account addAttributes: [NSDictionary dictionaryWithObject: paragraphStyle forKey: NSParagraphStyleAttributeName] range: NSMakeRange(0, [account length])];
    [accountLabel setAttributedStringValue: account];
    [accountLabel setToolTip: [[details valueForKey: @"account"] string]];
    
    categoryColor = [[details valueForKey: @"color"] retain];
    
    if (currencyTransformer == nil)
        currencyTransformer = [[CurrencyValueTransformer alloc] init];
    
    NSString *currency = [details valueForKey: @"currency"];
    NSString *symbol = [currencyTransformer transformedValue: currency];
    [currencyLabel setStringValue: symbol];
    [[[valueLabel cell] formatter] setCurrencyCode: currency]; // Important for proper display of the value, even without currency.

    [self setNeedsDisplay: YES];
}

- (void)setTextAttributesForPositivNumbers: (NSDictionary*) positiveAttributes
                           negativeNumbers: (NSDictionary*) negativeAttributes
{
    [[[valueLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
    [[[valueLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];
}

#pragma mark Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];

    [dateLabel setStringValue: @""];
    [accountLabel setStringValue: @""];
    [remoteNameLabel setStringValue: @""];
    [purposeLabel setStringValue: @""];
    [bankNameLabel setStringValue: @""];
    [valueLabel setObjectValue: @""];
    [currencyLabel setObjectValue: @""];
}

#pragma mark Drawing

- (void)refresh
{
    [self setNeedsDisplay: YES];
}

static NSGradient* innerGradient;
static NSGradient* innerGradientSelected;
static NSShadow* innerShadow;

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
    innerShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithCalibratedWhite: 0.0 alpha: .75]
                                           offset: NSMakeSize(0, -1)
                                       blurRadius: 3.0];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (innerGradient == nil)
        [self setupDrawStructures];
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    
    NSBezierPath* path;
    NSRect bounds = [self bounds];
	path = [NSBezierPath bezierPathWithRect: bounds];
    
    if ([self isSelected]) {
        [innerGradientSelected drawInBezierPath: path angle: 90.0];
    } else {
        [innerGradient drawInBezierPath: path angle: 90.0];
    }
    
    if (categoryColor != nil) {
        [categoryColor set];
        NSRect colorRect = bounds;
        colorRect.size.width = 5;
        [NSBezierPath fillRect: colorRect];
    }
    
    if ([self isSelected]) {
        [path fillWithInnerShadow: innerShadow borderOnly: NO];
    }
    
    [[NSColor colorWithDeviceWhite: 0 / 255.0 alpha: 1] set];
    path = [NSBezierPath bezierPath];
    [path setLineWidth: 1];
    
    // Separator line between main text part and the rest.
    CGFloat left = [bankNameLabel frame].origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 4, 10)];
    [path lineToPoint: NSMakePoint(left - 4, 39)];
    
    // Left, right and bottom lines.
    [path moveToPoint: NSMakePoint(0, 0)];
    [path lineToPoint: NSMakePoint(0, bounds.size.height)];
    [path moveToPoint: NSMakePoint(bounds.size.width, 0)];
    [path lineToPoint: NSMakePoint(bounds.size.width, bounds.size.height)];
    [path moveToPoint: NSMakePoint(0, 0)];
    [path lineToPoint: NSMakePoint(bounds.size.width, 0)];
    [[NSColor colorWithDeviceWhite: 210 / 255.0 alpha: 1] set];
    [path stroke];
    
    [context restoreGraphicsState];
}

@end
