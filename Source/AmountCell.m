/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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
#import "GraphicsAdditions.h"

#define CELL_BOUNDS 3

@implementation AmountCell

@synthesize currency;
@synthesize formatter;

- (id)initTextCell: (NSString *)aString
{
    if ((self = [super initTextCell: aString])) {
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        [formatter setLocale: [NSLocale currentLocale]];
        [formatter setCurrencySymbol: @""];
        
        self.partiallyHighlightedGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                             [NSColor applicationColorForKey: @"Grid Partial Selection"], (CGFloat) 0,
                                             [NSColor applicationColorForKey: @"Grid Partial Selection"], (CGFloat) 1,
                                             nil
                                             ];
        self.fullyHighlightedGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                    [NSColor applicationColorForKey: @"Cell Selection Gradient (high)"], (CGFloat) 0,
                                    [NSColor applicationColorForKey: @"Cell Selection Gradient (low)"], (CGFloat) 1,
                                    nil
                                    ];
    }
    return  self;
}

- (id)initWithCoder: (NSCoder*)decoder {
    if ((self = [super initWithCoder: decoder])) {
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        [formatter setLocale: [NSLocale currentLocale]];
        [formatter setCurrencySymbol: @""];
    }
    return self;
}


- (id)copyWithZone:(NSZone *)zone
{
    AmountCell *cell = (AmountCell*)[super copyWithZone:zone];
    cell->formatter = formatter;
    cell->currency = currency;
    return cell;
}

- (void)drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    NSColor *textColor;
    if (self.isInSelectedRow || self.isInSelectedColumn) {
        textColor  = [NSColor whiteColor];
    } else {
        if ([self.objectValue compare: [NSDecimalNumber zero]] != NSOrderedAscending) {
            textColor = [NSColor applicationColorForKey: @"Positive Cash"];
        } else {
            textColor  = [NSColor applicationColorForKey: @"Negative Cash"];
        }
    }
    NSMutableDictionary *attrs = [[[self attributedStringValue] attributesAtIndex: 0 effectiveRange: NULL] mutableCopy];
    
    // If this cell is selected then make the text bold.
    if (self.isInSelectedRow || self.isInSelectedColumn) {
        NSFontManager *manager = [NSFontManager sharedFontManager];
        NSFont *font = [attrs objectForKey: NSFontAttributeName];
        font = [manager convertFont: font toHaveTrait: NSBoldFontMask];
        [attrs setObject: font forKey: NSFontAttributeName];
    }
    [attrs setObject: textColor forKey: NSForegroundColorAttributeName];
    [formatter setCurrencyCode: currency];
    NSString *str = [formatter stringFromNumber: self.objectValue];
    if (str != nil) {
        NSAttributedString *s = [[NSAttributedString alloc] initWithString: str attributes: attrs];
    
        cellFrame.origin.x += CELL_BOUNDS;
        cellFrame.size.width -= 2 * CELL_BOUNDS;
        cellFrame.origin.y += 2;
        [s drawInRect: cellFrame];
    }
}

@end
