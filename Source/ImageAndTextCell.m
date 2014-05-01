/**
 * Copyright (c) 2008, 2014, Pecunia Project. All rights reserved.
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

/*
 Based on ImageAndTextCell.m, supplied by Apple as example code.
 Copyright (c) 2006, Apple Computer, Inc., all rights reserved.

 Subclass of NSTextFieldCell which can display text and an image simultaneously.
 */

#import "ImageAndTextCell.h"

#import "PreferenceController.h"
#import "NSColor+PecuniaAdditions.h"
#import "NSAttributedString+PecuniaAdditions.h"

// Layout constants
#define MIN_BADGE_WIDTH                     22.0 //The minimum badge width for each item (default 22.0)
#define BADGE_HEIGHT                        14.0 //The badge height for each item (default 14.0)
#define BADGE_MARGIN                        5.0 //The spacing between the badge and the cell for that row
#define ROW_RIGHT_MARGIN                    5.0 //The spacing between the right edge of the badge and the edge of the table column
#define ICON_SPACING                        3.0 //The spacing between the icon and it's adjacent cell
#define DISCLOSURE_TRIANGLE_SPACE           18.0 //The indentation reserved for disclosure triangles for non-group items
#define BADGE_SPACE                         40

// Drawing constants
#define BADGE_BACKGROUND_COLOR              [NSColor colorWithCalibratedRed: (152 / 255.0) green: (168 / 255.0) blue: (202 / 255.0) alpha: 1]
#define BADGE_HIDDEN_BACKGROUND_COLOR       [NSColor colorWithDeviceWhite: (180 / 255.0) alpha: 1]
#define BADGE_SELECTED_TEXT_COLOR           [NSColor keyboardFocusIndicatorColor]
#define BADGE_SELECTED_UNFOCUSED_TEXT_COLOR [NSColor colorWithCalibratedRed: (153 / 255.0) green: (169 / 255.0) blue: (203 / 255.0) alpha: 1]
#define BADGE_SELECTED_HIDDEN_TEXT_COLOR    [NSColor colorWithCalibratedWhite: (170 / 255.0) alpha: 1]
#define BADGE_FONT                          [NSFont boldSystemFontOfSize: 11]

#define SWATCH_SIZE                         14

extern void *UserDefaultsBindingContext;

@interface ImageAndTextCell()
{
    NSImage           *image;
    NSString          *currency;
    NSNumberFormatter *amountFormatter;
    NSDecimalNumber   *amount;

    NSInteger countUnread;
    NSInteger maxUnread;
    NSInteger badgeWidth;

    BOOL isRoot;
    BOOL isDisabled;
    BOOL isHidden;
    BOOL isIgnored; // Not included in overall computation.
}

@end

@implementation ImageAndTextCell

@synthesize swatchColor;
@synthesize image;
@synthesize currency;
@synthesize amount;
@synthesize amountFormatter;

- (id)initWithCoder: (NSCoder *)decoder
{
    self = [super initWithCoder: decoder];
    if (self != nil) {
        amountFormatter = [[NSNumberFormatter alloc] init];
        [amountFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        [amountFormatter setLocale: [NSLocale currentLocale]];
        [amountFormatter setCurrencySymbol: @""];
        maxUnread = 0;
        badgeWidth = BADGE_SPACE;

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
    }
    return self;
}

- (id)copyWithZone: (NSZone *)zone
{
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone: zone];
    cell.image = image;
    cell.amountFormatter = amountFormatter;
    cell.amount = amount;
    cell.currency = currency;
    return cell;
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            [self setupGradients];
            [[self controlView] setNeedsDisplay: YES];
        }
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

- (NSRect)imageFrameForCellFrame: (NSRect)cellFrame
{
    if (image != nil) {
        NSRect imageFrame;
        imageFrame.size = [image size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += 3;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    } else {
        return NSZeroRect;
    }
}

- (void)setValues: (NSDecimalNumber *)aAmount
         currency: (NSString *)aCurrency
           unread: (NSInteger)unread
         disabled: (BOOL)disabled
           isRoot: (BOOL)root
         isHidden: (BOOL)hidden
        isIgnored: (BOOL)ignored
{
    currency = aCurrency;
    amount = aAmount;
    countUnread = unread;
    isRoot = root;
    isDisabled = disabled;
    isHidden = hidden;
    isIgnored = ignored;
}

- (NSRect)titleRectForBounds: (NSRect)theRect
{
    NSRect titleFrame = [super titleRectForBounds: theRect];
    CGRect rect = [self.attributedStringValue boundingRectWithSize: NSMakeSize(FLT_MAX, NSHeight(titleFrame))
                                                           options: 0];
    titleFrame.origin.y -= NSHeight(rect) - floor(self.font.ascender);
    titleFrame.origin.y += floor((titleFrame.size.height - self.font.xHeight) / 2);
    return titleFrame;
}

- (void)drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    NSRect titleRect = [self titleRectForBounds: cellFrame];
    [self.attributedStringValue drawInRect: titleRect];
}

// Shared objects.
static NSGradient *headerGradient = nil;
static NSGradient *selectionGradient = nil;

- (void)setupGradients
{
    headerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                      [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 1], 0.0,
                      [NSColor colorWithDeviceWhite: 60 / 256.0 alpha: 1], 1.0,
                      nil];
    selectionGradient = [[NSGradient alloc] initWithColorsAndLocations:
                         [NSColor applicationColorForKey: @"Cell Selection Gradient (high)"], 0.0,
                         [NSColor applicationColorForKey: @"Cell Selection Gradient (low)"], 1.0,
                         nil
                         ];
}

- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    if (headerGradient == nil) {
        [self setupGradients];
    }

    // Draw selection rectangle.
    NSRect selectionRect = cellFrame;
    selectionRect.size.width = [controlView bounds].size.width;
    selectionRect.origin.x = 0;

    if ([self isHighlighted]) {
        // Fill selection rectangle for selected entries.
        [selectionGradient drawInRect: selectionRect angle: 90];
    } else
        if (isRoot) {
            // Fill constant background for unselected root entries.
            [headerGradient drawInRect: selectionRect angle: 90];
        }

    // Draw category color swatch.
    if (PreferenceController.showCategoryColorsInTree && swatchColor != nil) {
        NSRect  swatchRect = cellFrame;
        CGFloat swatchWidth = 3;
        swatchRect.size = NSMakeSize(swatchWidth, SWATCH_SIZE);
        swatchRect.origin.y += floor((cellFrame.size.height - SWATCH_SIZE) / 2);
        swatchRect.origin.x += 3;
        if (isHidden) {
            [[swatchColor colorWithAlphaComponent: 0.4] setFill];
        } else {
            [swatchColor setFill];
        }
        [NSBezierPath fillRect: swatchRect];

        // Draw a border for entries with a darker background.
        if ([self isHighlighted] || isRoot) {
            swatchRect.size.width++;
            swatchRect.size.height++;
            swatchRect.origin.x -= 0.5;
            swatchRect.origin.y -= 0.5;
            [[NSColor colorWithDeviceWhite: 1 alpha: (isHidden ? 0.4 : 0.75)] setStroke];
            [NSBezierPath strokeRect: swatchRect];
        }

        cellFrame.size.width -= swatchWidth  + 4;
        cellFrame.origin.x += swatchWidth + 4;
    }

    // Draw cell symbol if there is one.
    if (image != nil) {
        NSSize iconSize = NSMakeSize(16, 16);
        NSRect iconFrame;

        NSDivideRect(cellFrame, &iconFrame, &cellFrame, ICON_SPACING + iconSize.width + ICON_SPACING, NSMinXEdge);

        iconFrame.size = iconSize;

        iconFrame.origin.x += ICON_SPACING;
        iconFrame.origin.y += floor((cellFrame.size.height - iconFrame.size.height) / 2);

        [image  drawInRect: iconFrame
                  fromRect: NSZeroRect
                 operation: NSCompositeSourceOver
                  fraction: isHidden ? 0.4: 1.0
            respectFlipped: YES
                     hints: nil];

    } else {
        cellFrame.size.width -= ICON_SPACING;
        cellFrame.origin.x   += ICON_SPACING;
    }

    // Reserve space for badges.
    if (maxUnread > 0) {
        NSRect badgeFrame;
        NSDivideRect(cellFrame, &badgeFrame, &cellFrame, badgeWidth, NSMaxXEdge);

        // Number of unread entries.
        if (countUnread > 0) {
            // Draw Badge with number unread messages.
            NSSize badgeSize = [self sizeOfBadge: countUnread];

            NSRect badgeNumberFrame;
            NSDivideRect(badgeFrame, &badgeNumberFrame, &badgeFrame, badgeSize.width + ROW_RIGHT_MARGIN, NSMaxXEdge);

            badgeNumberFrame.origin.y += (badgeNumberFrame.size.height - badgeSize.height) / 2;
            badgeNumberFrame.size.width -= ROW_RIGHT_MARGIN;

            badgeNumberFrame.size.height = badgeSize.height;

            [self drawBadgeInRect: badgeNumberFrame];
        }
    }

    // Sum and currency text color.
    NSRect amountwithCurrencyFrame;

    NSColor *valueColor;
    if (self.isHighlighted || isRoot) {
        valueColor = [NSColor whiteColor];
    } else {
        if ([amount compare: [NSDecimalNumber zero]] != NSOrderedAscending) {
            valueColor = [NSColor applicationColorForKey: @"Positive Cash"];
        } else {
            valueColor = [NSColor applicationColorForKey: @"Negative Cash"];
        }
    }

    if (isIgnored) {
        valueColor = [valueColor colorWithAlphaComponent: 0.4];
    }

    NSDictionary *attributes = @{NSFontAttributeName: self.font,
                                 NSForegroundColorAttributeName: valueColor};

    [amountFormatter setCurrencyCode: currency];
    NSString *amountString = [amountFormatter stringFromNumber: amount];

    NSAttributedString *amountWithCurrency = [[NSMutableAttributedString alloc] initWithString: amountString attributes: attributes];

    // Draw sum only if the cell is large enough.
    if (cellFrame.size.width > 150) {
        CGRect rect = [amountWithCurrency boundingRectWithSize: CGSizeMake(FLT_MAX, NSHeight(cellFrame))
                                                       options: 0];
        NSDivideRect(cellFrame, &amountwithCurrencyFrame, &cellFrame, rect.size.width + ROW_RIGHT_MARGIN, NSMaxXEdge);

        amountwithCurrencyFrame.origin.y -= NSHeight(rect) - floor(self.font.ascender);
        amountwithCurrencyFrame.origin.y += floor((NSHeight(cellFrame) - self.font.xHeight) / 2);

        amountwithCurrencyFrame.size.width -= ROW_RIGHT_MARGIN;
        cellFrame.size.width -= ROW_RIGHT_MARGIN;

        [amountWithCurrency drawInRect: amountwithCurrencyFrame];
    }

    // Cell text color.
    NSAttributedString *cellStringWithFormat;
    NSColor            *textColor;

    // Setting the attributed string below will reset all paragraph settings to defaults.
    // So we have to add those we changed to this attributed string too.
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    if (isRoot || [self isHighlighted]) {
        // Selected and root items can never be disabled.
        textColor = [NSColor whiteColor];
        if (isHidden) {
            textColor = [textColor colorWithAlphaComponent: 0.4];
        }

        attributes = @{NSFontAttributeName: self.font,
                       NSForegroundColorAttributeName: textColor,
                       NSParagraphStyleAttributeName: paragraphStyle};
        cellStringWithFormat = [[NSAttributedString alloc] initWithString: [[self attributedStringValue] string]
                                                               attributes: attributes];
    } else {
        textColor = [NSColor colorWithCalibratedWhite: 40 / 255.0 alpha: 1];

        if (isDisabled) {
            textColor = [NSColor applicationColorForKey: @"Disabled Tree Item"];
        }
        if (isHidden) {
            textColor = [textColor colorWithAlphaComponent: 0.4];
        }

        attributes = @{NSFontAttributeName: self.font,
                       NSForegroundColorAttributeName: textColor,
                       NSParagraphStyleAttributeName: paragraphStyle};
        cellStringWithFormat = [[NSAttributedString alloc] initWithString: [[self attributedStringValue] string]
                                                               attributes: attributes];
    }
    [self setAttributedStringValue: cellStringWithFormat];

    [super drawWithFrame: cellFrame inView: controlView];
}

#pragma mark -
#pragma mark Badge with numbers

- (NSSize)sizeOfBadge: (NSInteger)unread
{
    NSAttributedString *badgeAttrString = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%li", unread]
                                                                          attributes: @{NSFontAttributeName: BADGE_FONT}];

    NSSize stringSize = [badgeAttrString size];

    // Calculate the width needed to display the text or the minimum width if it's smaller.
    CGFloat width = stringSize.width + (2 * BADGE_MARGIN);

    if (width < MIN_BADGE_WIDTH) {
        width = MIN_BADGE_WIDTH;
    }

    return NSMakeSize(width, BADGE_HEIGHT);
}

- (void)drawBadgeInRect: (NSRect)badgeFrame
{
    NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect: badgeFrame
                                                              xRadius: (BADGE_HEIGHT / 2.0)
                                                              yRadius: (BADGE_HEIGHT / 2.0)];

    //Set the attributes based on the row state
    NSDictionary *attributes;
    NSColor      *backgroundColor;
    NSColor      *textColor;

    if ([self isHighlighted]) {
        backgroundColor = [NSColor whiteColor];
        textColor       = BADGE_SELECTED_TEXT_COLOR;
    } else {
        backgroundColor = BADGE_BACKGROUND_COLOR;
        textColor       = [NSColor whiteColor];
    }


    attributes = @{NSFontAttributeName: BADGE_FONT,
                   NSForegroundColorAttributeName: textColor};


    [backgroundColor set];
    [badgePath fill];

    //Draw the badge text
    NSAttributedString *badgeAttrString = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%li", countUnread]
                                                                          attributes: attributes];
    NSSize  stringSize = [badgeAttrString size];
    NSPoint badgeTextPoint = NSMakePoint(NSMidX(badgeFrame) - (stringSize.width / 2.0),             //Center in the badge frame
                                         NSMidY(badgeFrame) - (stringSize.height / 2.0));   //Center in the badge frame
    [badgeAttrString drawAtPoint: badgeTextPoint];

}

- (void)setMaxUnread: (NSInteger)n
{
    maxUnread = n;
    if (n > 0) {
        NSSize badgeSize = [self sizeOfBadge: n];
        badgeWidth = badgeSize.width + ROW_RIGHT_MARGIN;
    } else {badgeWidth = 0; }
}

- (NSText *)setUpFieldEditorAttributes: (NSText *)textObj
{
    NSText *result = [super setUpFieldEditorAttributes: textObj];
    [result setDrawsBackground: YES];
    result.font = self.font;

    return result;
}

- (void)selectWithFrame: (NSRect)aRect
                 inView: (NSView *)controlView
                 editor: (NSText *)textObj
               delegate: (id)anObject
                  start: (NSInteger)selStart
                 length: (NSInteger)selLength
{
	aRect = [self titleRectForBounds: aRect];

    NSRect textFrame, imageFrame;
    NSDivideRect(aRect, &imageFrame, &textFrame, image == nil ? 0 : 20, NSMinXEdge);
	[super selectWithFrame: textFrame
                    inView: controlView
                    editor: textObj
                  delegate: anObject
                     start: selStart
                    length: selLength];
}

@end
