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

#import "ShadowedTextField.h"

#import "NSAttributedString+PecuniaAdditions.h"

@implementation ShadowedTextField

@synthesize shadowDistance;
@synthesize shadowDirection;
@synthesize shadowBlur;
@synthesize shadowColor;

@synthesize shadowDistanceOuter;
@synthesize shadowDirectionOuter;
@synthesize shadowBlurOuter;
@synthesize shadowColorOuter;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaults];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setDefaults];
}

- (void)setDefaults
{
    shadowDistance = @2;
    shadowDirection = @135;
    shadowBlur = @3;
    shadowColor = [NSColor colorWithCalibratedWhite: 0.000 alpha: 0.750];

    shadowDistanceOuter = @3;
    shadowDirectionOuter = @135;
    shadowBlurOuter = @6;
    shadowColorOuter  = [NSColor colorWithCalibratedWhite: 0.000 alpha: 0.250];
}

- (NSImage*)blackSquareOfSize:(CGSize)size {
    NSImage *blackSquare = [[NSImage alloc] initWithSize:size];
    [blackSquare lockFocus];

    [[NSColor blackColor] setFill];
    CGContextFillRect([[NSGraphicsContext currentContext] graphicsPort], CGRectMake(0, 0, size.width, size.height));

    [blackSquare unlockFocus];
    return blackSquare;
}

- (CGImageRef)createMaskWithSize:(CGSize)size shape:(void (^)(void))block {
    NSImage *newMask = [[NSImage alloc] initWithSize:size];
    CGImageRef mask;

    CGContextSetShadow([[NSGraphicsContext currentContext] graphicsPort], CGSizeZero, 0.0);

    [newMask lockFocus];
    block();
    [newMask unlockFocus];

    struct CGImage *newMaskRef = [newMask CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil];

    mask = CGImageMaskCreate(CGImageGetWidth(newMaskRef),
                             CGImageGetHeight(newMaskRef),
                             CGImageGetBitsPerComponent(newMaskRef),
                             CGImageGetBitsPerPixel(newMaskRef),
                             CGImageGetBytesPerRow(newMaskRef),
                             CGImageGetDataProvider(newMaskRef), NULL, false);
    return mask;
}

- (NSSize)intrinsicContentSize
{
    if (![self.cell wraps]) {
        return [super intrinsicContentSize];
    }

    NSRect frame = [self frame];
    CGFloat width = frame.size.width;

    // Make the frame very high, while keeping the width.
    frame.size.height = CGFLOAT_MAX;

    // Calculate new height within the frame with practically infinite height.
    CGFloat height = [self.cell cellSizeForBounds: frame].height;

    return NSMakeSize(width, height);
}

- (void)drawRect: (NSRect)dirtyRect
{
    float shadowY = shadowDistance.floatValue * cos(shadowDirection.intValue * M_PI / 180.0);
    float shadowX = shadowDistance.floatValue * sin(shadowDirection.intValue * M_PI / 180.0);

    float shadowYOuter = shadowDistanceOuter.floatValue * cos(shadowDirectionOuter.intValue * M_PI / 180.0);
    float shadowXOuter = shadowDistanceOuter.floatValue * sin(shadowDirectionOuter.intValue * M_PI / 180.0);

    NSAttributedString *text = self.attributedStringValue;
    NSMutableAttributedString *maskText = [text mutableCopy];

    CGPoint textLocation = CGPointMake(0, 0);
    NSSize size = self.intrinsicContentSize;
    NSRect textRect = NSMakeRect(textLocation.x, textLocation.y, size.width, size.height);

    NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [textStyle setAlignment: [self.cell alignment]];

    NSDictionary* blackFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         self.font, NSFontAttributeName,
                                         [NSColor blackColor], NSForegroundColorAttributeName,
                                         textStyle, NSParagraphStyleAttributeName, nil];

    NSDictionary* whiteFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         self.font, NSFontAttributeName,
                                         [NSColor whiteColor], NSForegroundColorAttributeName,
                                         textStyle, NSParagraphStyleAttributeName, nil];

    // Create initial mask of white text on black background.
    CGImageRef mask = [self createMaskWithSize: textRect.size shape: ^{
        [[NSColor blackColor] setFill];
        CGContextFillRect([[NSGraphicsContext currentContext] graphicsPort], textRect);
        [[NSColor whiteColor] setFill];
        [maskText setAttributes: whiteFontAttributes range: NSMakeRange(0, maskText.length)];
        [maskText drawInRect: textRect];
    }];

    NSImage *cutoutImage = [self blackSquareOfSize: textRect.size];
    CGImageRef cutoutRawRef = [cutoutImage CGImageForProposedRect: NULL
                                                          context: [NSGraphicsContext currentContext]
                                                            hints:  nil];

    CGImageRef cutoutRef = CGImageCreateWithMask(cutoutRawRef, mask);
    CGImageRelease(mask);

    NSImage *cutout = [[NSImage alloc] initWithCGImage:cutoutRef size: textRect.size];

    CGImageRelease(cutoutRef);

    CGImageRef shadedMask = [self createMaskWithSize: textRect.size shape: ^{
        [[NSColor whiteColor] setFill];
        CGContextFillRect([[NSGraphicsContext currentContext] graphicsPort], textRect);
        CGContextSetShadowWithColor([[NSGraphicsContext currentContext] graphicsPort],
                                    CGSizeMake(shadowX, shadowY),
                                    [shadowBlur floatValue],
                                    [shadowColor CGColor]);
        [cutout drawAtPoint: CGPointZero
                   fromRect: NSZeroRect
                  operation: NSCompositeSourceOver
                   fraction: 0.9];
    }];

    NSImage *negativeImage = [[NSImage alloc] initWithSize: textRect.size];
    [negativeImage lockFocus];
    [[NSColor blackColor] setFill];
    [maskText setAttributes: blackFontAttributes range: NSMakeRange(0, maskText.length)];
    [maskText drawInRect: textRect];
    [negativeImage unlockFocus];

    struct CGImage *negativeImageRef = [negativeImage CGImageForProposedRect: NULL
                                                                     context: [NSGraphicsContext                                                                              currentContext]
                                                                       hints: nil];

    CGImageRef innerShadowRef = CGImageCreateWithMask(negativeImageRef, shadedMask);
    CGImageRelease(shadedMask);

    NSImage *innerShadow = [[NSImage alloc] initWithCGImage: innerShadowRef size: textRect.size];

    CGImageRelease(innerShadowRef);

    if (shadowColorOuter != nil) {
        CGContextSetShadowWithColor([[NSGraphicsContext currentContext] graphicsPort],
                                    CGSizeMake(shadowXOuter, shadowYOuter),
                                    [shadowBlurOuter floatValue],
                                    [shadowColorOuter CGColor]);
        [text drawInRect: textRect];
        CGContextSetShadow([[NSGraphicsContext currentContext] graphicsPort], CGSizeZero, 0.0);
    }
    [text drawInRect: textRect];

    [innerShadow drawInRect: textRect
                   fromRect: NSZeroRect
                  operation: NSCompositeSourceOver
                   fraction: 0.8
             respectFlipped: YES
                      hints: nil];
}

@end
