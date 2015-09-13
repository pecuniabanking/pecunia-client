/**
 * Copyright (c) 2014, 2015, Pecunia Project. All rights reserved.
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

#import "PecuniaListViewCell.h"
#import "PXListView.h"

#import "PreferenceController.h"
#import "NSColor+PecuniaAdditions.h"
#import "NSString+PecuniaAdditions.h"

extern void *UserDefaultsBindingContext;
static void *SetRowBindingContext = @"SetRowContext";

// Objects shared between all cell instances.
static NSGradient *innerGradientSelected;  // Gradient via property to better control recreation on color changes.
static NSGradient *innerGradientPaleSelected;

NSDateFormatter *dateFormatter;
NSDictionary    *whiteAttributes;

@interface PecuniaListViewCell ()
{
@private
    NSMutableArray *standardLabels;
    NSMutableArray *numberLabels;
    NSMutableArray *paleLabels;
}

@end

@implementation PecuniaListViewCell

@synthesize representedObject;
@synthesize selectionGradient;
@synthesize selectionPaleGradient;
@synthesize blendFactor;

+ (void)initialize
{
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = NSLocale.currentLocale;
    dateFormatter.dateStyle = kCFDateFormatterFullStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;

    whiteAttributes = @{NSForegroundColorAttributeName: NSColor.whiteColor};
}

+ (id)defaultAnimationForKey: (NSString *)key
{
    // No animations for the cells please. In a class where cells are constantly added and removed
    // this gets annoying quickly otherwise. This does only disable animations for the cell itself
    // not its content.
    return nil;
}

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self != nil) {
        standardLabels = [NSMutableArray new];
        numberLabels = [NSMutableArray new];
        paleLabels = [NSMutableArray new];
        blendFactor = 1;

        [self addObserver: self forKeyPath: @"row" options: 0 context: SetRowBindingContext];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"fontScale" options: 0 context: UserDefaultsBindingContext];
    }
    return self;
}

- (void)dealloc
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver: self forKeyPath: @"colors"];
    [defaults removeObserver: self forKeyPath: @"fontScale"];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == SetRowBindingContext) {
        [self selectionChanged];
        [self setNeedsDisplay: YES];
        return;
    }

    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            [self updateTextColors];
            innerGradientSelected = nil; // Reset the gradient. It will be created on next draw call.
            innerGradientPaleSelected = nil;

            [self setNeedsDisplay: YES];
            return;
        }

        if ([keyPath isEqualToString: @"fontScale"]) {
            [self adjustLabelsAndSize];
            return;
        }
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

- (NSGradient *)selectionGradient
{
    if (innerGradientSelected == nil) {
        innerGradientSelected = [[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor applicationColorForKey: @"Selection Gradient (low)"], (CGFloat)0,
                                 [NSColor applicationColorForKey: @"Selection Gradient (high)"], (CGFloat)1,
                                 nil];
    }
    return innerGradientSelected;
}

- (NSGradient *)selectionPaleGradient
{
    if (innerGradientPaleSelected == nil) {
        innerGradientPaleSelected = [[NSGradient alloc] initWithColorsAndLocations:
                                 [[NSColor applicationColorForKey: @"Selection Gradient (low)"] colorWithAlphaComponent: 0.5], (CGFloat)0,
                                 [[NSColor applicationColorForKey: @"Selection Gradient (high)"] colorWithAlphaComponent: 0.5], (CGFloat)1,
                                 nil];
    }
    return innerGradientPaleSelected;
}

- (void)selectionChanged
{
    if (self.isSelected) {
        for (NSDictionary* entry  in numberLabels) {
            [[[entry[@"field"] cell] formatter] setTextAttributesForPositiveValues: whiteAttributes];
            [[[entry[@"field"] cell] formatter] setTextAttributesForNegativeValues: whiteAttributes];
        }

        for (NSDictionary* entry in standardLabels) {
            [entry[@"field"] setTextColor: NSColor.whiteColor];
        }

        for (NSDictionary* entry in paleLabels) {
            [entry[@"field"] setTextColor: NSColor.whiteColor];
        }
    } else {
        for (NSDictionary* entry in standardLabels) {
            [entry[@"field"] setTextColor: [NSColor.controlTextColor colorWithAlphaComponent: blendFactor]];
        }
        [self updateTextColors];
    }
}

- (id)formatValue: (id)value capitalize: (BOOL)capitalize
{
    if (value == nil || [value isKindOfClass: [NSNull class]]) {
        value = @"";
    } else {
        if ([value isKindOfClass: [NSDate class]]) {
            value = [dateFormatter stringFromDate: value];
        } else {
            if (capitalize) {
                return [value stringWithNaturalText];
            }
        }
    }

    return value;
}

/**
 * Called when the user changes a color. We update here only those colors that are customizable.
 */
- (void)updateTextColors
{
    if (!self.isSelected) {
        NSDictionary *positiveAttributes = @{NSForegroundColorAttributeName: [[NSColor applicationColorForKey: @"Positive Cash"] colorWithAlphaComponent: blendFactor]};
        NSDictionary *negativeAttributes = @{NSForegroundColorAttributeName: [[NSColor applicationColorForKey: @"Negative Cash"] colorWithAlphaComponent: blendFactor]};

        for (NSDictionary* entry in numberLabels) {
            [[[entry[@"field"] cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
            [[[entry[@"field"] cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];
        }

        NSColor *paleColor = [[NSColor applicationColorForKey: @"Pale Text"] colorWithAlphaComponent: blendFactor];
        for (NSDictionary* entry in paleLabels) {
            [entry[@"field"] setTextColor: paleColor];
        }
    }
}

- (void)updateEntry: (NSDictionary *)entry
{
    NSTextField *field = entry[@"field"];

    // For now we ignore the stored font name, as a control should usually use the system font.
    // If needed we can later take it into account again, hence I leave it in the dict.
    field.font = [PreferenceController mainFontOfSize: [entry[@"size"] intValue] bold: false];

    NSRect frame = field.frame;
    CGRect rect = [field.attributedStringValue boundingRectWithSize: CGSizeMake(NSWidth(frame), FLT_MAX)
                                                            options: 0];
    frame.size.height = NSHeight(rect);
    field.frame = frame;
}

- (void)adjustLabelsAndSize
{
    for (NSDictionary* entry in standardLabels) {
        [self updateEntry: entry];
    }

    for (NSDictionary* entry in paleLabels) {
        [self updateEntry: entry];
    }

    for (NSDictionary* entry in numberLabels) {
        [self updateEntry: entry];
    }
}

- (void)registerStandardLabel: (NSTextField *)field
{
    if (![standardLabels containsObject: field]) {
        // Store current font name + size for automatic adjustments.
        [standardLabels addObject: @{@"field": field, @"font": field.font.fontName, @"size": @(field.font.pointSize)}];
    }
}

- (void)registerNumberLabel: (NSTextField *)field
{
    if (![numberLabels containsObject: field]) {
        [numberLabels addObject: @{@"field": field, @"font": field.font.fontName, @"size": @(field.font.pointSize)}];
    }
}

- (void)registerPaleLabel: (NSTextField *)field
{
    if (![paleLabels containsObject: field]) {
        [paleLabels addObject: @{@"field": field, @"font": field.font.fontName, @"size": @(field.font.pointSize)}];
    }
}

@end
