//
//  ColumnLayoutCorePlotLayer.m
//  Pecunia
//
//  Created by Mike on 17.11.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "ColumnLayoutCorePlotLayer.h"

/**
 * This layer derivate is used to apply a custom layout for sublayers. In this case we use a simple
 * column layout.
 */

@implementation ColumnLayoutCorePlotLayer

// Determines the space between two sublayers.
@synthesize spacing;

-(void)layoutSublayers
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
	
    NSSet* excludedSublayers = [self sublayersExcludedFromAutomaticLayout];
	for (CALayer* subLayer in self.sublayers) {
		if (![excludedSublayers containsObject: subLayer] && [subLayer isKindOfClass: [CPTLayer class]] &&
            !subLayer.hidden) {
            subLayerFrame.size.height = subLayer.frame.size.height;
            subLayer.frame = subLayerFrame;
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
        int layoutedLayers = 0;
        NSSet* excludedSublayers = [self sublayersExcludedFromAutomaticLayout];
        for (CALayer* subLayer in self.sublayers) {
            if (![excludedSublayers containsObject: subLayer] && [subLayer isKindOfClass: [CPTLayer class]] &&
                !subLayer.hidden) {
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
    self.bounds = bounds;
}

@end
