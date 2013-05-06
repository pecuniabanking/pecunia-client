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

#import "GradientButtonCell.h"

#import "GraphicsAdditions.h"

@implementation GradientButtonCell

// Shared objects.
static NSGradient *blackGradient;


- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    [NSGraphicsContext saveGraphicsState];

    // Initialize shared objects.
    if (blackGradient == nil) {
        blackGradient = [[NSGradient alloc] initWithColorsAndLocations:
                         [NSColor colorWithDeviceWhite: 120 / 255.0 alpha: 1], 0.0,
                         [NSColor colorWithDeviceWhite: 91 / 255.0 alpha: 1], 0.25,
                         [NSColor colorWithDeviceWhite: 33 / 255.0 alpha: 1], 1.0,
                         nil
                         ];
    }

    // Outer bounds with shadow.
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect: cellFrame xRadius: 5 yRadius: 5];
    [blackGradient drawInBezierPath: borderPath angle: 90];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];

    // If there is an image left or right to the title then exclude its bounding rect from the
    // available space for the title. For now we don't support image above or below the title.
    if (self.image != nil) {
        NSPoint imageLocation = NSZeroPoint;
        switch (self.imagePosition) {
            case NSImageOnly:
            case NSImageOverlaps: {
                imageLocation = NSMakePoint((cellFrame.size.width - self.image.size.width) / 2,
                                            (cellFrame.size.height - self.image.size.height) / 2);
                break;
            }

            case NSImageLeft:
                imageLocation.x = 4;
                imageLocation.y = (cellFrame.size.height - self.image.size.height) / 2;
                cellFrame.origin.x -= self.image.size.width + 4;
                cellFrame.size.width -= self.image.size.width + 4;
                break;

            case NSImageRight:
                imageLocation.x = cellFrame.size.width - self.image.size.width - 4;
                imageLocation.y = (cellFrame.size.height - self.image.size.height) / 2;
                cellFrame.size.width -= self.image.size.width + 4;
                break;
        }
        if (imageLocation.x > 0) {
            NSRect targetRect;
            targetRect.origin = imageLocation;
            targetRect.size = self.image.size;
            [self.image drawInRect: targetRect
                          fromRect: NSZeroRect
                         operation: NSCompositeSourceOver
                          fraction: self.isEnabled ? 1.0: 0.5
                    respectFlipped: YES
                             hints: nil];
        }
    }

    if (self.imagePosition != NSImageOnly || self.image == nil) {
        [paragraphStyle setAlignment: NSCenterTextAlignment];
        NSColor *textColor = [NSColor whiteColor];
        if (!self.isEnabled) {
            textColor = [NSColor grayColor];
        }
        NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor,
                                     NSParagraphStyleAttributeName: paragraphStyle};
        NSAttributedString *cellStringWithFormat = [[NSAttributedString alloc] initWithString: [self title]
                                                                                   attributes: attributes];
        [cellStringWithFormat drawInRect: NSInsetRect(cellFrame, 10, 4)];
    }

    [NSGraphicsContext restoreGraphicsState];
}

@end
