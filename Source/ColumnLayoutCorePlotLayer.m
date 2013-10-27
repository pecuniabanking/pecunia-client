/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#import "ColumnLayoutCorePlotLayer.h"

/**
 * This layer derivate is used to apply a custom layout for sublayers. In this case we use a simple
 * column layout.
 */

@implementation ColumnLayoutCorePlotLayer

// Determines the space between two sublayers.
@synthesize spacing;

- (void)layoutSublayers
{
    // The row layout is simple. Let all sublayers fill the entire width of this layer (minus padding)
    // and stack them vertically with a spacing given by the same-named property using their current height.
    CGFloat leftPadding, topPadding, rightPadding, bottomPadding;
    [self sublayerMarginLeft: &leftPadding top: &topPadding right: &rightPadding bottom: &bottomPadding];

    CGRect selfBounds = self.bounds;
    CGSize subLayerSize = selfBounds.size;
    subLayerSize.width -= leftPadding + rightPadding;
    subLayerSize.width = MAX(subLayerSize.width, 0.0f);
    subLayerSize.height = 0;

    CGRect subLayerFrame;
    subLayerFrame.origin = CGPointMake(round(leftPadding), round(bottomPadding));
    subLayerFrame.size = subLayerSize;

    NSSet *excludedSublayers = [self sublayersExcludedFromAutomaticLayout];
    for (CPTLayer *subLayer in self.sublayers) {
        if (![excludedSublayers containsObject: subLayer] && !subLayer.hidden) {
            if ([subLayer isKindOfClass: CPTTextLayer.class]) {
                [(id)subLayer sizeToFit];
            }
            subLayerFrame.size.height = subLayer.frame.size.height;
            subLayer.frame = subLayerFrame;
            [subLayer pixelAlign];
            [subLayer setNeedsLayout];
            [subLayer setNeedsDisplay];
            subLayerFrame.origin.y += spacing + subLayerFrame.size.height;
        }
    }
}

/**
 * Resizes the layer so that it fits all sub layers.
 */
- (void)sizeToFit
{
    CGFloat leftPadding, topPadding, rightPadding, bottomPadding;
    [self sublayerMarginLeft: &leftPadding top: &topPadding right: &rightPadding bottom: &bottomPadding];

    CGRect bounds = CGRectMake(0, 0,
                               leftPadding + rightPadding,
                               topPadding + bottomPadding);

    if (self.sublayers.count > 0) {
        CGFloat maxWidth = 0;
        int     layoutedLayers = 0;
        NSSet   *excludedSublayers = [self sublayersExcludedFromAutomaticLayout];
        for (CPTLayer *subLayer in self.sublayers) {
            if (![excludedSublayers containsObject: subLayer] && !subLayer.hidden) {
                if ([subLayer isKindOfClass: CPTTextLayer.class]) {
                    [(id)subLayer sizeToFit];
                }
                if (subLayer.bounds.size.width > maxWidth) {
                    maxWidth = subLayer.bounds.size.width;
                }
                bounds.size.height += subLayer.bounds.size.height;
                layoutedLayers++;
            }
        }
        bounds.size.height += (layoutedLayers - 1) * spacing;
        bounds.size.width += maxWidth;
    }

    // Make bounds integral and size/width even to avoid half pixel coordinates
    // (especially important for text layers).
    bounds = NSIntegralRect(bounds);
    if (((int)bounds.size.width & 1) != 0) {
        bounds.size.width++;
    }
    if (((int)bounds.size.height & 1) != 0) {
        bounds.origin.y += 0.5f;
    }
    self.bounds = bounds;
}

@end
