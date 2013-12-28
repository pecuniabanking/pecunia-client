/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

#define CELL_BOUNDS 3

extern void *UserDefaultsBindingContext;

@interface AmountCell ()
{
    NSDictionary *normalAttributes;
    NSDictionary *selectedAttributes;

    NSNumberFormatter *whiteFormatter;
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
        NSDictionary *whiteAttributes = @{NSForegroundColorAttributeName: NSColor.whiteColor};

        [formatter setTextAttributesForPositiveValues: whiteAttributes];
        [formatter setTextAttributesForNegativeValues: whiteAttributes];


        normalAttributes = @{NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontName size: 13]};
        selectedAttributes = @{NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameBold size: 13],
                               NSForegroundColorAttributeName: NSColor.whiteColor};

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];

        [self updateColors];
    }
    return self;
}

- (void)dealloc
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"colors"];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            [self updateColors];
        }
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

- (void)updateColors
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
        formatter = whiteFormatter;
    }
    [formatter setCurrencyCode: currency];
    NSAttributedString *string = [formatter attributedStringForObjectValue: self.objectValue withDefaultAttributes: attributes];
    if (string != nil) {
        NSSize size = string.size;

        if (self.alignment == NSRightTextAlignment) {
            cellFrame.origin.x += NSWidth(cellFrame) - size.width - CELL_BOUNDS;
        } else {
            cellFrame.origin.x += CELL_BOUNDS;
        }
        cellFrame.size.width -= 2 * CELL_BOUNDS;
        cellFrame.origin.y -= (cellFrame.size.height - size.height) / 2 + 1; // -1 for bottom line.
        [string drawInRect: cellFrame];
    }
}

@end
