/*
 Copyright (c) 2008 Matthew Ball - http://www.mattballdesign.com
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

#import "MBTableGridCell.h"


@implementation MBTableGridCell

@synthesize isInSelectedColumn;
@synthesize isInSelectedRow;

@synthesize partiallyHighlightedGradient;
@synthesize fullyHighlightedGradient;

-(id)initTextCell: (NSString *)aString
{
  self = [super initTextCell: aString];
  if (self != nil) {
    isInSelectedRow = NO;
    isInSelectedColumn = NO;
    
    self.partiallyHighlightedGradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                         [NSColor colorWithCalibratedRed: 92 / 255.0 green: 168 / 255.0 blue: 234 / 255.0 alpha: 1], (CGFloat) 0,
                                         [NSColor colorWithCalibratedRed: 92 / 255.0 green: 168 / 255.0 blue: 234 / 255.0 alpha: 1], (CGFloat) 1,
                                         nil] autorelease];

    self.fullyHighlightedGradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                         [NSColor colorWithCalibratedRed: 28 / 255.0 green: 131 / 255.0 blue: 222 / 255.0 alpha: 1], (CGFloat) 0,
                                         [NSColor colorWithCalibratedRed: 28 / 255.0 green: 131 / 255.0 blue: 222 / 255.0 alpha: 1], (CGFloat) 1,
                                         nil] autorelease];
  }
  return self;
}

- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  [NSGraphicsContext saveGraphicsState];
  NSRect fillRect = cellFrame;
  if (isInSelectedColumn && isInSelectedRow) {
    fillRect = NSInsetRect(cellFrame, -2, -2);
    fillRect.origin.x -= 1;
    NSBezierPath *selectionOutline = [NSBezierPath bezierPathWithRoundedRect: fillRect xRadius: 4 yRadius: 4];

    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor: [NSColor colorWithCalibratedWhite: 0 alpha: 0.5]];
    [shadow setShadowBlurRadius: 2];
    //   [shadow setShadowOffset: NSMakeSize(1, -1)];
    [shadow set];
    [[NSColor whiteColor] set];
    [selectionOutline fill];
    
    [fullyHighlightedGradient drawInBezierPath: selectionOutline angle: 90];

  } else {
    if (isInSelectedColumn || isInSelectedRow) {
      [partiallyHighlightedGradient drawInRect: fillRect angle: 90];
    } else {
      [[NSColor whiteColor] set];
      NSRectFill(fillRect);
    }
  }

  if (!(isInSelectedColumn && isInSelectedRow)) {
    NSColor *borderColor = [NSColor colorWithDeviceWhite: 0.83 alpha: 0.25];
    [borderColor set];
    
    // Draw the right border
    NSRect rightLine = NSMakeRect(NSMaxX(cellFrame)-1.0, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
    NSRectFill(rightLine);
    
    // Draw the bottom border
    NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame)-1.0, NSWidth(cellFrame), 1.0);
    NSRectFill(bottomLine);
  }
  [NSGraphicsContext restoreGraphicsState];
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
