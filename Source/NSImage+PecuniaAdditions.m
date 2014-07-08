/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

#import "NSImage+PecuniaAdditions.h"

@implementation NSImage (PecuniaAdditions)

+ (NSImage *)imageNamed: (NSString *)name fromCollection: (NSUInteger)collection {
    NSString *path = [[NSBundle mainBundle] pathForResource: name
                                                     ofType: @"icns"
                                                inDirectory: [NSString stringWithFormat: @"Collections/%lu", collection]];
    if ([NSFileManager.defaultManager fileExistsAtPath: path]) {
        return [[NSImage alloc] initWithContentsOfFile: path];
    }
    return nil;
}

- (void)drawEtchedInRect: (NSRect)rect {
    NSSize  size = rect.size;
    CGFloat dropShadowOffsetY = size.width <= 64.0 ? -1.0 : -2.0;
    CGFloat innerShadowBlurRadius = size.width <= 32.0 ? 1.0 : 4.0;

    CGContextRef context = NSGraphicsContext.currentContext.graphicsPort;

    CGContextSaveGState(context);

    // Create mask image.
    NSRect     maskRect = rect;
    CGImageRef maskImage = [self CGImageForProposedRect: &maskRect context: [NSGraphicsContext currentContext] hints: nil];

    // Draw image and white drop shadow.
    CGContextSetShadowWithColor(context, CGSizeMake(0, dropShadowOffsetY), 0, CGColorGetConstantColor(kCGColorWhite));
    [self drawInRect: maskRect fromRect: NSMakeRect(0, 0, self.size.width, self.size.height)
           operation: NSCompositeSourceOver fraction: 1.0];

    // Clip drawing to mask.
    CGContextClipToMask(context, NSRectToCGRect(maskRect), maskImage);

    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceWhite: 0.5 alpha: 1.0]
                                                         endingColor: [NSColor colorWithDeviceWhite: 0.25 alpha: 1.0]];
    [gradient drawInRect: maskRect angle: 90.0];
    CGContextSetShadowWithColor(context, CGSizeMake(0, -1), innerShadowBlurRadius, CGColorGetConstantColor(kCGColorBlack));

    //Draw inner shadow with inverted mask:
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef    maskContext = CGBitmapContextCreate(NULL, CGImageGetWidth(maskImage), CGImageGetHeight(maskImage),
                                                        8, CGImageGetWidth(maskImage) * 4, colorSpace,
                                                        kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(maskContext, kCGBlendModeXOR);
    CGContextDrawImage(maskContext, maskRect, maskImage);
    CGContextSetRGBFillColor(maskContext, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(maskContext, maskRect);
    CGImageRef invertedMaskImage = CGBitmapContextCreateImage(maskContext);
    CGContextDrawImage(context, maskRect, invertedMaskImage);
    CGImageRelease(invertedMaskImage);
    CGContextRelease(maskContext);

    CGContextRestoreGState(context);
}

@end
