/**
 * Copyright (c) 2012, 2013, Pecunia Project. All rights reserved.
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

#import "SigningOptionsViewCell.h"
#import "SigningOption.h"
#import "BankUser.h"

@implementation SigningOptionsViewCell

- (id)init
{
    return [super init];
}

static NSGradient *innerGradient;
static NSGradient *innerGradientSelected;

- (void)setupDrawStructures
{
    innerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithDeviceRed: 240 / 255.0 green: 240 / 255.0 blue: 240 / 255.0 alpha: 1], (CGFloat)0.2,
                     [NSColor whiteColor], (CGFloat)0.8,
                     nil];

    innerGradientSelected = [[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor colorWithDeviceRed: 1.0 green: 64764.0 / 65535 blue: 62194.0 / 65535 alpha: 1], (CGFloat) - 0.5,
                             [NSColor colorWithDeviceRed: 13621.0 / 65535 green: 30583.0 / 65535 blue: 49858.0 / 65535 alpha: 1], (CGFloat)0.8,
                             nil];

}

#define LINE1_Y 2
#define LINE2_Y 21

- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    NSAttributedString *as;
    NSColor            *textColor;
    NSColor            *labelColor;
    NSImage            *secImage;
    NSRect             drawRect;
    SecurityMethod     secMethod;

    secMethod = [(SigningOption *)self.objectValue secMethod];

    if (innerGradient == nil) {
        [self setupDrawStructures];
    }

    cellFrame.size.width = controlView.bounds.size.width;
    int width_TanMeth = cellFrame.size.width-360;
    if (width_TanMeth < 130) {
        width_TanMeth = 130;
    }
    NSBezierPath *path = [NSBezierPath bezierPathWithRect: cellFrame];
    if ([self isHighlighted]) {
        //        [innerGradientSelected drawInBezierPath: path angle: 90.0];
    } else {[innerGradient drawInBezierPath: path angle: 270.0]; }


    NSFont *txtFont10 = [NSFont fontWithName: @"Lucida Grande" size: 10];
    NSFont *txtFont12 = [NSFont fontWithName: @"Lucida Grande" size: 12];
    NSFont *txtFont13 = [NSFont fontWithName: @"Lucida Grande" size: 13];
    NSFont *txtFont14 = [NSFont fontWithName: @"Lucida Grande" size: 14];


    if ([self isHighlighted]) {
        textColor = [NSColor whiteColor];
        labelColor = [NSColor whiteColor];
    } else {
        textColor = [NSColor blackColor];
        labelColor = [NSColor disabledControlTextColor];
    }


    // Bankkennung
    NSDictionary *attributes = @{NSFontAttributeName: txtFont14, NSForegroundColorAttributeName: textColor};
    SigningOption *option = self.objectValue;
    as = [[NSMutableAttributedString alloc] initWithString: option.userName attributes: attributes];
    drawRect = NSMakeRect(80, cellFrame.origin.y + LINE1_Y, 150, 18);
    [as drawInRect: drawRect];

    // Sicherheitsverfahren
    attributes = @{NSFontAttributeName: txtFont12, NSForegroundColorAttributeName: textColor};

    if (secMethod == SecMethod_PinTan) {
        as = [[NSMutableAttributedString alloc] initWithString: @"HBCI PIN/TAN" attributes: attributes];
    } else {
        as = [[NSMutableAttributedString alloc] initWithString: @"HBCI Chipkarte" attributes: attributes];
    }
    drawRect = NSMakeRect(80, cellFrame.origin.y + LINE2_Y, 150, 16);
    [as drawInRect: drawRect];


    if (secMethod == SecMethod_PinTan) {
        // Medium verfügbar?
        NSString *medium = [[self objectValue] tanMediumName];

        // Label
        attributes = @{NSFontAttributeName: txtFont10, NSForegroundColorAttributeName: labelColor};
        as = [[NSMutableAttributedString alloc] initWithString: @"TAN-Methode:" attributes: attributes];
        drawRect = NSMakeRect(230, cellFrame.origin.y + LINE1_Y + 4, 80, 16);
        [as drawInRect: drawRect];

        if (medium) {
            as = [[NSMutableAttributedString alloc] initWithString: @"TAN-Medium:" attributes: attributes];
            drawRect = NSMakeRect(230, cellFrame.origin.y + LINE2_Y + 4, 80, 16);
            [as drawInRect: drawRect];
        }

        // TAN-Methode
        attributes = @{NSFontAttributeName: txtFont13, NSForegroundColorAttributeName: textColor};
        as = [[NSMutableAttributedString alloc] initWithString: [[self objectValue] tanMethodName] attributes: attributes];
        drawRect = NSMakeRect(310, cellFrame.origin.y + LINE1_Y, width_TanMeth, 16);
        [as drawInRect: drawRect];

        // TAN-Medium
        if (medium) {
            as = [[NSMutableAttributedString alloc] initWithString: medium attributes: attributes];
            drawRect = NSMakeRect(310, cellFrame.origin.y + LINE2_Y, width_TanMeth, 16);
            [as drawInRect: drawRect];
        }

        secImage = [NSImage imageNamed: @"PinTan.png"];
        NSString *category = [[self objectValue] tanMediumCategory];
        if (category != nil) {
            if ([category isEqualToString: @"M"]) {
                // Icon für Phone
                NSImage *phoneImage = [NSImage imageNamed: @"iPhone.png"];
                drawRect = NSMakeRect(325+width_TanMeth, cellFrame.origin.y + 3, 20, 36);
                [phoneImage drawInRect: drawRect
                              fromRect: NSZeroRect
                             operation: NSCompositeSourceOver
                              fraction: 1.0
                        respectFlipped: YES
                                 hints: nil];
            }
            if ([category isEqualToString: @"G"]) {
                // Icon für Generator
                NSImage *generatorImage = [NSImage imageNamed: @"Kobil.png"];
                drawRect = NSMakeRect(320+width_TanMeth, cellFrame.origin.y + 3, 30, 36);
                [generatorImage drawInRect: drawRect
                                  fromRect: NSZeroRect
                                 operation: NSCompositeSourceOver
                                  fraction: 1.0
                            respectFlipped: YES
                                     hints: nil];

            }
        }


    }

    if (secMethod == SecMethod_DDV) {
        // Label
        attributes = @{NSFontAttributeName: txtFont10, NSForegroundColorAttributeName: labelColor};
        as = [[NSMutableAttributedString alloc] initWithString: @"Kartennummer:" attributes: attributes];
        drawRect = NSMakeRect(230, cellFrame.origin.y + LINE1_Y + 4, 80, 16);
        [as drawInRect: drawRect];

        // Kartennummer
        attributes = @{NSFontAttributeName: txtFont13, NSForegroundColorAttributeName: textColor};
        as = [[NSMutableAttributedString alloc] initWithString: [[self objectValue] cardId] attributes: attributes];
        drawRect = NSMakeRect(310, cellFrame.origin.y + LINE1_Y, width_TanMeth, 16);
        [as drawInRect: drawRect];

        secImage = [NSImage imageNamed: @"Chipcard.png"];

    }

    // Icon für Sicherheitsverfahren
    drawRect = NSMakeRect(5, cellFrame.origin.y + 3, 64, 36);
    [secImage drawInRect: drawRect
                fromRect: NSZeroRect
               operation: NSCompositeSourceOver
                fraction: 1.0
          respectFlipped: YES
                   hints: nil];

}

@end
