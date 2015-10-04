/**
 * Copyright (c) 2011, 2015, Pecunia Project. All rights reserved.
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

#import "AmountCell.h"
#import "NSColor+PecuniaAdditions.h"
#import "PreferenceController.h"

#define CELL_BOUNDS 5

extern void *UserDefaultsBindingContext;

@interface AmountCell ()
{
    NSDictionary *normalAttributes;
    NSDictionary *selectedAttributes;

    NSNumberFormatter *whiteFormatter; // not really using the value formmating (we have dedicated attributes above).
}
@end

@implementation AmountCell

@synthesize currency;

- (id)initTextCell: (NSString *)aString
{
    self = [super initTextCell: aString];
    if (self != nil) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        [formatter setLocale: [NSLocale currentLocale]];
        [formatter setCurrencySymbol: @""];
        self.formatter = formatter;

        whiteFormatter = [formatter copy];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"fontScale" options: 0 context: UserDefaultsBindingContext];

        [self updateColorsAndFonts];
    }
    return self;
}

- (void)dealloc
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"colors"];
    [userDefaults removeObserver: self forKeyPath: @"fontScale"];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"] || [keyPath isEqualToString: @"fontScale"]) {
            [self updateColorsAndFonts];
            [[(id)self.controlView contentView] setNeedsDisplay: YES];
        }
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

- (void)updateColorsAndFonts
{
    NSColor *color = [NSColor applicationColorForKey: @"Grid Partial Selection"];
    self.partiallyHighlightedGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                         color, 0.0,
                                         color, 1.0,
                                         nil
                                         ];

    color = [color colorWithChangedBrightness: 0.5];
    self.fullyHighlightedGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                     color, 0.0,
                                     color, 1.0,
                                     nil
                                     ];

    normalAttributes = @{NSFontAttributeName: [PreferenceController mainFontOfSize: 13 bold: NO]};
    selectedAttributes = @{NSFontAttributeName: [PreferenceController mainFontOfSize: 13 bold: NO],
                           NSForegroundColorAttributeName: NSColor.whiteColor};


    NSDictionary *positiveAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]};
    NSDictionary *negativeAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]};

    NSNumberFormatter *formatter = self.formatter;
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
}

- (void)drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    NSDictionary *attributes = normalAttributes;
    NSNumberFormatter *formatter = self.formatter;
    if (self.isInSelectedRow || self.isInSelectedColumn) {
        attributes = selectedAttributes;
        formatter = whiteFormatter; // Just to have a formatter without attributes for negative/positive values.
    }
    [formatter setCurrencyCode: currency];
    NSAttributedString *string = [formatter attributedStringForObjectValue: self.objectValue withDefaultAttributes: attributes];
    if (string != nil) {
        NSRect rect = [string boundingRectWithSize: CGSizeMake(FLT_MAX, NSHeight(cellFrame)) options: 0];

        // Always right-align money values.
        rect.origin.x = cellFrame.origin.x + NSWidth(cellFrame) - NSWidth(rect) - CELL_BOUNDS;

        NSFont *font = attributes[NSFontAttributeName];
        rect.origin.y = cellFrame.origin.y - NSHeight(rect) + floor(font.ascender);
        rect.origin.y += floor((NSHeight(cellFrame) - font.xHeight) / 2);

        [string drawInRect: rect];
    }
}

@end
