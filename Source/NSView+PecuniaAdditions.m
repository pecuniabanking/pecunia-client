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

#import "NSView+PecuniaAdditions.h"


@implementation NSView (PecuniaAdditions)


- (void)drawTextFields
{
    // Manually draw all text fields to avoid font problems with layer-backed views.
    NSArray *views = [self subviews];
    for (NSView *view in views) {
        if ([view isKindOfClass: [NSTextField class]]) {
            NSTextField *field = (NSTextField *)view;
            if ([field isEnabled] && [field isHidden]) {
                NSRect r = [view frame];
                NSAttributedString *as = [[field cell] attributedStringValue];
                [as drawInRect: r];
            }
        }
    }
}

/**
 * Returns an offscreen view containing all visual elements of this view for printing,
 * including CALayer content. Useful only for views that are layer-backed.
 */
- (NSView*)printViewForLayerBackedView;
{
    NSRect bounds = self.bounds;
    int bitmapBytesPerRow = 4 * bounds.size.width;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context = CGBitmapContextCreate (NULL,
                                                  bounds.size.width,
                                                  bounds.size.height,
                                                  8,
                                                  bitmapBytesPerRow,
                                                  colorSpace,
                                                  kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    if (context == NULL)
    {
        NSLog(@"getPrintViewForLayerBackedView: Failed to create context.");
        return nil;
    }
    
    [[self layer] renderInContext: context];
    CGImageRef img = CGBitmapContextCreateImage(context);
    NSImage* image = [[[NSImage alloc] initWithCGImage: img size: bounds.size] autorelease];
    
    NSImageView* canvas = [[NSImageView alloc] initWithFrame: bounds];
    [canvas setImage: image];
    
    CFRelease(img);
    CFRelease(context);
    return [canvas autorelease];
}

@end

@implementation CustomTextDrawingView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect: dirtyRect];
    [self drawTextFields];
}

@end