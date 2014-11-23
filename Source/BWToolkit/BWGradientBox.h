//
//  BWGradientBox.h
//  BWToolkit
//
//  Created by Brandon Walkin (www.brandonwalkin.com)
//  All code is provided under the New BSD license.
//

#import <Cocoa/Cocoa.h>

@interface BWGradientBox : NSView 
{
	NSColor *fillStartingColor, *fillEndingColor, *fillColor;
	NSColor *topBorderColor, *bottomBorderColor;
	float topInsetAlpha, bottomInsetAlpha;
	
	BOOL hasTopBorder, hasBottomBorder, hasGradient, hasFillColor;
}

@property (nonatomic, strong) NSColor *fillStartingColor, *fillEndingColor, *fillColor, *topBorderColor, *bottomBorderColor;
@property float topInsetAlpha, bottomInsetAlpha;
@property (nonatomic, assign) BOOL hasTopBorder, hasBottomBorder, hasGradient, hasFillColor;

@property (nonatomic, assign) float cornerRadius;
@property (copy) NSShadow *shadow;
@end
