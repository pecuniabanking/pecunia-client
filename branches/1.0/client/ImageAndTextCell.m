/*
 ImageAndTextCell.m
 Copyright © 2006, Apple Computer, Inc., all rights reserved.
 
 Subclass of NSTextFieldCell which can display text and an image simultaneously.
 */

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under AppleÕs copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ImageAndTextCell.h"

// Layout constants
#define MIN_BADGE_WIDTH           22.0 //The minimum badge width for each item (default 22.0)
#define BADGE_HEIGHT              14.0 //The badge height for each item (default 14.0)
#define BADGE_MARGIN              5.0  //The spacing between the badge and the cell for that row
#define ROW_RIGHT_MARGIN          5.0  //The spacing between the right edge of the badge and the edge of the table column
#define ICON_SPACING              3.0  //The spacing between the icon and it's adjacent cell
#define DISCLOSURE_TRIANGLE_SPACE 18.0 //The indentation reserved for disclosure triangles for non-group items
#define BADGE_SPACE               40

// Drawing constants
#define BADGE_BACKGROUND_COLOR              [NSColor colorWithCalibratedRed: (152 / 255.0) green: (168 / 255.0) blue: (202 / 255.0) alpha: 1]
#define BADGE_HIDDEN_BACKGROUND_COLOR       [NSColor colorWithDeviceWhite:(180 / 255.0) alpha: 1]
#define BADGE_SELECTED_TEXT_COLOR           [NSColor keyboardFocusIndicatorColor]
#define BADGE_SELECTED_UNFOCUSED_TEXT_COLOR [NSColor colorWithCalibratedRed: (153 / 255.0) green: (169 / 255.0) blue: (203/255.0) alpha: 1]
#define BADGE_SELECTED_HIDDEN_TEXT_COLOR    [NSColor colorWithCalibratedWhite: (170 / 255.0) alpha: 1]
#define BADGE_FONT                          [NSFont boldSystemFontOfSize: 11]

@implementation ImageAndTextCell

@synthesize image;
@synthesize currency;
@synthesize amount;
@synthesize amountFormatter;

/*
 - (id)init {
 if ((self = [super init])) {
 [self setLineBreakMode:NSLineBreakByTruncatingTail];
 [self setSelectable:YES];
 
 self.amountFormatter = [[[NSNumberFormatter alloc ] init ] autorelease ];
 [amountFormatter setNumberStyle: NSNumberFormatterCurrencyStyle ];
 [amountFormatter setLocale:[NSLocale currentLocale ] ];
 [amountFormatter setCurrencySymbol:@"" ];
 }
 return self;
 }
 
 - (id)initTextCell:(NSString*)text {
 if ((self = [super initTextCell:text])) {
 
 self.amountFormatter = [[NSNumberFormatter alloc ] init ];
 [amountFormatter setNumberStyle: NSNumberFormatterCurrencyStyle ];
 [amountFormatter setLocale:[NSLocale currentLocale ] ];
 [amountFormatter setCurrencySymbol:@"" ];
 }
 return self;
 }
 */

- (id)initWithCoder: (NSCoder*)decoder
{
    if ((self = [super initWithCoder:decoder]))
    {    
        self.amountFormatter = [[[NSNumberFormatter alloc] init] retain];
        [amountFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        [amountFormatter setLocale: [NSLocale currentLocale]];
        [amountFormatter setCurrencySymbol: @""];
        maxUnread = 0;
        badgeWidth = BADGE_SPACE;
    }
    return self;
}

- (void)dealloc
{
    [image release], image = nil;
    [currency release], currency = nil;
    [amountFormatter release ], amountFormatter = nil;
    
    [super dealloc];
}

- (id)copyWithZone: (NSZone *)zone
{
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone: zone];
    cell->image = [image retain];
    cell->amountFormatter = [amountFormatter retain];
    cell->amount = [amount retain];
    cell->currency = [currency retain];
    return cell;
}

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame
{
    if (image != nil)
    {
        NSRect imageFrame;
        imageFrame.size = [image size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += 3;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
        return NSZeroRect;
}

- (void)setValues: (NSDecimalNumber*)aAmount currency: (NSString*)aCurrency unread: (NSInteger)unread
         selected: (BOOL)selected root: (BOOL)root
{
    self.currency	= aCurrency;
    self.amount		= aAmount;
    countUnread		= unread;
    //	isSelected		= selected;
    isRoot			= root;
    
    return;
}

- (NSRect)titleRectForBounds: (NSRect)theRect
{
    NSRect titleFrame = [super titleRectForBounds: theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    titleFrame.origin.y = theRect.origin.y + (theRect.size.height - titleSize.height) / 2.0;
    return titleFrame;
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength
{
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

// Shared objects.
static NSGradient* headerGradient = nil;
static NSGradient* selectionGradient = nil;

- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    // Draw selection rectangle.
    NSRect selectionRect = cellFrame;
    selectionRect.size.width = [controlView bounds].size.width;
    selectionRect.origin.x = 0;
    
    NSBezierPath* selectionOutline = [NSBezierPath bezierPathWithRoundedRect: selectionRect xRadius: 4 yRadius: 4];
    if ([self isHighlighted])
    {
        if (selectionGradient == nil)
        {
            headerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                              [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 1], (CGFloat) 0,
                              [NSColor colorWithDeviceWhite: 60 / 256.0 alpha: 1], (CGFloat) 1,
                              nil];
            selectionGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedRed: 1 / 255.0 green: 115 / 255.0 blue: 244 / 255.0 alpha: 1], (CGFloat) 0,
                                 [NSColor colorWithCalibratedRed: 0 / 255.0 green: 65 / 255.0 blue: 225 / 255.0 alpha: 1], (CGFloat) 1,
                                 nil
                                 ];
        }
        
        // Fill selection rectangle for selected entries.
        [selectionGradient drawInBezierPath: selectionOutline angle: 90];
    }
    else
        if (isRoot)
        {
            // Fill constant background for unselected root entries.
            [headerGradient drawInBezierPath: selectionOutline angle: 90];
        }
    
    // Draw cell symbol if there is one.
    if (image != nil)
    {
        NSSize iconSize;
        NSRect iconFrame;
        
        iconSize = [image size];
        NSDivideRect(cellFrame, &iconFrame, &cellFrame, ICON_SPACING + iconSize.width + ICON_SPACING, NSMinXEdge);
        
        iconFrame.size = iconSize;
        
        iconFrame.origin.x += ICON_SPACING;
        iconFrame.origin.y += floor((cellFrame.size.height + iconFrame.size.height) / 2);
        
        [image compositeToPoint:iconFrame.origin operation:NSCompositeSourceOver];
        
    }
    else
    {
        cellFrame.size.width -= ICON_SPACING;
        cellFrame.origin.x   += ICON_SPACING;
    }
    
    // Reserve space for badges.
    if (maxUnread > 0)
    {
        NSRect badgeFrame;
        NSDivideRect(cellFrame, &badgeFrame, &cellFrame, badgeWidth, NSMaxXEdge);
        
        // Number of unread entries.
        if (countUnread > 0)
        {	
            // Draw Badge with number unread messages.
            NSSize badgeSize = [self sizeOfBadge: countUnread];
            
            NSRect badgeNumberFrame;
            NSDivideRect(badgeFrame, &badgeNumberFrame, &badgeFrame, badgeSize.width + ROW_RIGHT_MARGIN, NSMaxXEdge);
            
            badgeNumberFrame.origin.y += (badgeNumberFrame.size.height - badgeSize.height)/2;
            badgeNumberFrame.size.width -= ROW_RIGHT_MARGIN;
            
            badgeNumberFrame.size.height = badgeSize.height;
            
            [self drawBadgeInRect: badgeNumberFrame];
        }
    }
    
    // Sum and currency. Set cell text color at the same time.
    NSRect amountwithCurrencyFrame;
    
    NSColor* valueColor;
    if ([self isHighlighted] || isRoot)
    {
        valueColor = [NSColor whiteColor];
        [self setTextColor: [NSColor whiteColor]];
    }
    else
    {
        NSDictionary* fontAttributes;
        if ([amount compare: [NSDecimalNumber zero]] != NSOrderedAscending)
            fontAttributes = [amountFormatter textAttributesForPositiveValues];
        else
            fontAttributes = [amountFormatter textAttributesForNegativeValues];
        valueColor = (NSColor*) [fontAttributes objectForKey: NSForegroundColorAttributeName];
        [self setTextColor: [NSColor colorWithCalibratedWhite: 64 / 255 alpha: 1]];
    }
    
    NSFont *txtFont = [NSFont fontWithName: @"Lucida Grande" size: 13];
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                txtFont, NSFontAttributeName,
                                valueColor, NSForegroundColorAttributeName,
                                nil
                                ];
    
    [amountFormatter setCurrencyCode: currency];
    NSString *amountString = [amountFormatter stringFromNumber:amount ];
    
    NSAttributedString *amountWithCurrency = [[NSMutableAttributedString alloc] initWithString: amountString attributes: attributes];
    NSSize stringSize = [amountWithCurrency size];	
    
    // Draw sum only if the cell is large enough.
    if (cellFrame.size.width > 150)
    {
        NSDivideRect(cellFrame, &amountwithCurrencyFrame, &cellFrame, stringSize.width + ROW_RIGHT_MARGIN, NSMaxXEdge);
        
        amountwithCurrencyFrame.origin.y += (cellFrame.size.height - stringSize.height) / 2;	
        amountwithCurrencyFrame.size.height = stringSize.height;
        amountwithCurrencyFrame.size.width -= ROW_RIGHT_MARGIN;
        
        [amountWithCurrency	drawInRect:amountwithCurrencyFrame];    
    }
    
    [attributes release];
    [amountWithCurrency release];
    
    // Tree section headers.
    if (isRoot)
    {
        NSColor *textColor = [NSColor whiteColor];
        
        NSFont *textFont = [NSFont fontWithName: @"Lucida Grande Bold" size: 12];
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                      textFont, NSFontAttributeName,
                      textColor, NSForegroundColorAttributeName,
                      nil
                      ];
        NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString: [[self attributedStringValue] string]
                                                                       attributes: attributes] autorelease];
        [self setAttributedStringValue: attrStr];
    }
    
    [super drawWithFrame: cellFrame inView: controlView];
}

#pragma mark -
#pragma mark Badge mit Zahlen

- (NSSize)sizeOfBadge:(NSInteger)unread
{
    
    NSAttributedString *badgeAttrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", unread ]																	  attributes:[NSDictionary dictionaryWithObjectsAndKeys:BADGE_FONT, NSFontAttributeName, nil]];
    
    NSSize stringSize = [badgeAttrString size];
    
    // Calculate the width needed to display the text or the minimum width if it's smaller.
    CGFloat width = stringSize.width+(2*BADGE_MARGIN);
    
    if(width < MIN_BADGE_WIDTH)
    {
        width = MIN_BADGE_WIDTH;
    }
    
    [badgeAttrString release];
    
    return NSMakeSize(width, BADGE_HEIGHT);
}



- (void)drawBadgeInRect:(NSRect)badgeFrame
{
    //id rowItem = [self itemAtRow:rowIndex];
    
    NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
                                                              xRadius:(BADGE_HEIGHT/2.0)
                                                              yRadius:(BADGE_HEIGHT/2.0)];
    
    //Set the attributes based on the row state
    NSDictionary *attributes;
    NSColor *backgroundColor;
    NSColor *textColor;
    
    if([self isHighlighted ])
    {
        backgroundColor = [NSColor whiteColor];
        textColor       = BADGE_SELECTED_TEXT_COLOR;
    }
    else {
        backgroundColor = BADGE_BACKGROUND_COLOR;
        textColor       = [NSColor whiteColor];
    }
    
    
    attributes = [[NSDictionary alloc] initWithObjectsAndKeys:BADGE_FONT, NSFontAttributeName,
                  textColor, NSForegroundColorAttributeName, nil];
    
    
    [backgroundColor set];
    [badgePath fill];
    
    //Draw the badge text
    NSAttributedString *badgeAttrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", countUnread ] 
                                                                          attributes:attributes];
    NSSize stringSize = [badgeAttrString size];
    NSPoint badgeTextPoint = NSMakePoint(NSMidX(badgeFrame)-(stringSize.width/2.0),		//Center in the badge frame
                                         NSMidY(badgeFrame)-(stringSize.height/2.0));	//Center in the badge frame
    [badgeAttrString drawAtPoint:badgeTextPoint];
    
    [attributes release];
    [badgeAttrString release];
}

- (void)setMaxUnread:(NSInteger)n
{
    maxUnread = n;
    if (n > 0) {
        NSSize badgeSize = [self sizeOfBadge:n ];
        badgeWidth = badgeSize.width + ROW_RIGHT_MARGIN;
    } else badgeWidth = 0;
}


- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + 3;
    return cellSize;
}

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj
{
    NSText* result = [super setUpFieldEditorAttributes: textObj];
    [result setDrawsBackground: YES];
    
    return result;
}

@end
