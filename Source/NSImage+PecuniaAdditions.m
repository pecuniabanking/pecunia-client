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

#import "NSImage+PecuniaAdditions.h"

@implementation NSImage (PecuniaAdditions)

+ (NSArray<NSDictionary *> *)defaultCategoryIcons {
    static NSMutableArray<NSDictionary *> *defaultIcons;
    if (defaultIcons == nil) {
        defaultIcons = [NSMutableArray arrayWithCapacity: 100];

        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *path = [mainBundle pathForResource: @"category-icon-defaults" ofType: @"txt"];
        NSError  *error = nil;
        NSString *s = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
        if (error) {
            LogError(@"Error reading default category icon assignments file at %@\n%@", path, [error localizedFailureReason]);
        } else {
            NSArray *lines = [s componentsSeparatedByString: @"\n"];
            for (__strong NSString *line in lines) {
                NSRange hashPosition = [line rangeOfString: @"#"];
                if (hashPosition.length > 0) {
                    line = [line substringToIndex: hashPosition.location];
                }
                line = [line stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                if (line.length == 0) {
                    continue;
                }

                NSArray *components = [line componentsSeparatedByString: @"="];
                if (components.count < 2) {
                    continue;
                }
                NSString *icon = [components[0] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                NSArray  *keywordArray = [components[1] componentsSeparatedByString: @","];

                NSMutableArray *keywords = [NSMutableArray arrayWithCapacity: keywordArray.count];
                for (__strong NSString *keyword in keywordArray) {
                    keyword = [keyword stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                    if (keyword.length == 0) {
                        continue;
                    }
                    [keywords addObject: keyword];
                }
                NSDictionary *entry = @{@"icon": icon, @"keywords": keywords};
                [defaultIcons addObject: entry];
            }
        }
    }

    return defaultIcons;
}

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
