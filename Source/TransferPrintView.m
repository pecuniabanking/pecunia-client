/**
 * Copyright (c) 2012, 2015, Pecunia Project. All rights reserved.
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

#import "TransferPrintView.h"
#import "Transfer.h"
#import "BankAccount.h"
#import "PreferenceController.h"

#import "NSString+PecuniaAdditions.h"
#import "NS(Attributed)String+Geometrics.h"

#define SPACING       5  // The distance between two entries in the table.
#define PADDING       3  // Left and right padding within in a column.
#define HEADER_HEIGHT 25 // The height of the header on each page.

// Fixed column widths, except for the description column, which is computed from the overall width and these values.
// Values include padding.
#define DATE_COLUMN_WIDTH  40
#define AMOUNT_COLUMN_WIDTH  65
#define ACCOUNT_COLUMN_WIDTH 150

@interface TransferPrintView () {
    CGFloat topMargin;
    CGFloat bottomMargin;
    CGFloat leftMargin;
    CGFloat rightMargin;

    CGFloat purposeWidth;
    CGFloat pageWidth;

    NSUInteger totalPages;
    NSUInteger pageHeight;

    NSAttributedString *title;
    NSMutableArray     *entries; // Dictionaries with attributed strings (date, client, account, amount) and a height (NSNumber).

    NSDateFormatter *dateFormatter;
    NSDateFormatter *dateTimeFormatter;

    NSFont *normalFont;
    NSFont *smallFont;
    NSFont *boldFont;
}

@end

@implementation TransferPrintView

- (id)initWithTransfers: (NSArray *)transfersToPrint printInfo: (NSPrintInfo *)pi {
    NSRect frame = NSMakeRect(0, 0, pi.paperSize.width - pi.leftMargin - pi.rightMargin,
                              pi.paperSize.height - pi.topMargin - pi.bottomMargin);

    self = [super initWithFrame: frame];
    if (self != nil) {
        topMargin = pi.topMargin;
        bottomMargin = pi.bottomMargin;
        leftMargin = pi.leftMargin;
        rightMargin = pi.rightMargin;
        
        pageHeight = pi.paperSize.height - topMargin - bottomMargin;
        pageWidth = pi.paperSize.width - leftMargin - rightMargin;
        purposeWidth = pageWidth - DATE_COLUMN_WIDTH - AMOUNT_COLUMN_WIDTH - ACCOUNT_COLUMN_WIDTH;

        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameBold size: 16],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.000 green: 0.405 blue: 0.819 alpha: 1.000]
        };
        title = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"Pecunia %@", NSLocalizedString(@"AP435", nil)]
                                                attributes: attributes];

        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd.MM.yy";

        dateTimeFormatter = [NSDateFormatter new];
        dateTimeFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateTimeFormatter.timeStyle = NSDateFormatterMediumStyle;

        normalFont = [NSFont fontWithName: PreferenceController.mainFontName size: 9];
        smallFont = [NSFont fontWithName: PreferenceController.mainFontName size: 8];
        boldFont = [NSFont fontWithName: PreferenceController.mainFontNameBold size: 9];

        NSMutableArray   *sortedTransfers = [transfersToPrint mutableCopy];
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO];
        [sortedTransfers sortUsingDescriptors: @[sd]];

        NSUInteger height = [self computeEntriesFromTransfers: sortedTransfers];
        if (height > pageHeight) {
            frame.size.height = height;
            [self setFrame: frame];
        }
    }

    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (NSAttributedString *)textFromTransfer: (Transfer *)transfer {
    NSMutableAttributedString *result = [[transfer.remoteName attributedStringWithFont: boldFont] mutableCopy];

    // Purpose
    [result appendAttributedString: [[@"\n" stringByAppendingString : transfer.purpose] attributedStringWithFont: normalFont]];

    return result;
}

- (NSAttributedString *)bankAddressTextFromTransfer: (Transfer *)transfer {
    if ([transfer isSEPAorEU]) {
        NSString *s = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP409", nil)];
        NSMutableAttributedString *mas = [[s attributedStringWithFont : normalFont] mutableCopy];
        [mas appendAttributedString: [transfer.remoteIBAN attributedStringWithFont: boldFont]];

        s = [NSString stringWithFormat: @"\n%@: ", NSLocalizedString(@"AP410", nil)];
        [mas appendAttributedString: [s attributedStringWithFont : normalFont]];
        [mas appendAttributedString: [transfer.remoteBIC attributedStringWithFont: boldFont]];
        return mas;
    } else {
        NSString *s = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP401", nil)];
        NSMutableAttributedString *mas = [[s attributedStringWithFont : normalFont] mutableCopy];
        [mas appendAttributedString: [transfer.remoteAccount attributedStringWithFont: boldFont]];

        s = [NSString stringWithFormat: @"\n%@: ", NSLocalizedString(@"AP400", nil)];
        [mas appendAttributedString: [s attributedStringWithFont : normalFont]];
        [mas appendAttributedString: [transfer.remoteBankCode attributedStringWithFont: boldFont]];
        [mas appendAttributedString: [[@"\n" stringByAppendingString : transfer.remoteBankName] attributedStringWithFont: normalFont]];
        return mas;
    }
}

/**
 * Determines the text to be printed for each transfer, the height of that entry and the overall height.
 */
- (NSUInteger)computeEntriesFromTransfers: (NSArray *)transfers {
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.minimumFractionDigits = 2;

    NSUInteger totalHeight = 0;

    entries = [NSMutableArray new];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    attributes[NSFontAttributeName] = [NSFont fontWithName: PreferenceController.mainFontName size: 8];

    NSMutableParagraphStyle *style = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    style.alignment = NSRightTextAlignment;
    NSMutableDictionary *rightAlignAttributes = [attributes mutableCopy];
    rightAlignAttributes[NSParagraphStyleAttributeName] = style;

    style = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSMutableDictionary *centerAlignAttributes = [attributes mutableCopy];
    centerAlignAttributes[NSParagraphStyleAttributeName] = style;

    for (Transfer *transfer in transfers) {
        NSMutableDictionary *entry = [NSMutableDictionary new];

        NSAttributedString *s;
        if (transfer.valutaDate != nil) {
            s = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n%@",
                                                             [dateFormatter stringFromDate: transfer.date],
                                                             [dateFormatter stringFromDate: transfer.valutaDate]]
                                                attributes: centerAlignAttributes];
        } else {
            s = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@",
                                                             [dateFormatter stringFromDate: transfer.date]]
                                                attributes: centerAlignAttributes];
        }
        entry[@"date"] = s;

        NSRect r = [s boundingRectWithSize : NSMakeSize(DATE_COLUMN_WIDTH - 2 * PADDING, 0)
                                   options : NSStringDrawingUsesLineFragmentOrigin];
        NSUInteger entryHeight = r.size.height;

        s = [self textFromTransfer: transfer];
        entry[@"client"] = s;

        r = [s boundingRectWithSize: NSMakeSize(purposeWidth - 2 * PADDING, 0)
                            options: NSStringDrawingUsesLineFragmentOrigin];
        if (r.size.height > entryHeight) {
            entryHeight = r.size.height;
        }

        s = [self bankAddressTextFromTransfer: transfer];
        entry[@"account"] = s;

        r = [s boundingRectWithSize: NSMakeSize(ACCOUNT_COLUMN_WIDTH - 2 * PADDING, 0)
                            options: NSStringDrawingUsesLineFragmentOrigin];
        if (r.size.height > entryHeight) {
            entryHeight = r.size.height;
        }

        formatter.currencyCode = transfer.currency;
        s = [[NSAttributedString alloc] initWithString: [formatter stringFromNumber: transfer.value]
                                            attributes: rightAlignAttributes];
        entry[@"amount"] = s;

        r = [s boundingRectWithSize: NSMakeSize(AMOUNT_COLUMN_WIDTH - 2 * PADDING, 0)
                            options: NSStringDrawingUsesLineFragmentOrigin];
        if (r.size.height > entryHeight) {
            entryHeight = r.size.height;
        }

        entry[@"height"] = @(entryHeight);
        [entries addObject: entry];

        totalHeight += entryHeight + SPACING;
    }

    totalPages = ceil(totalHeight / (pageHeight - HEADER_HEIGHT - SPACING)) + 1;
    return totalPages * pageHeight;
}

- (void)drawHeaderForPage: (int)page {
    int baseHeight = page * pageHeight;

    // Attributes for header text.
    NSMutableParagraphStyle *style = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    style.maximumLineHeight = 9;
    style.alignment = NSCenterTextAlignment;
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontName size: 8],
        NSParagraphStyleAttributeName: style
    };

    // The header with column headings.
    NSRect headerFrame = NSMakeRect(0, baseHeight + 1, pageWidth, HEADER_HEIGHT);
    [[NSColor colorWithCalibratedWhite: 0.895 alpha: 1.000] setFill];
    [NSBezierPath fillRect: headerFrame];

    NSColor *lineColor = [NSColor colorWithCalibratedRed: 0.497 green: 0.488 blue: 0.461 alpha: 1.000];
    [lineColor setStroke];
    [NSBezierPath strokeRect: headerFrame];

    headerFrame.origin.y += 3;
    headerFrame.origin.x += PADDING;

    // Dates.
    headerFrame.size.width = DATE_COLUMN_WIDTH - 2 * PADDING;
    NSAttributedString *text = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"AP135", nil)
                                                               attributes: attributes];
    [text drawInRect: headerFrame];
    [lineColor setStroke];
    [NSBezierPath strokeLineFromPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, baseHeight)
                              toPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, baseHeight + HEADER_HEIGHT)];

    // Purpose.
    headerFrame.origin.x += DATE_COLUMN_WIDTH;
    headerFrame.size.width = purposeWidth - 2 * PADDING;
    text = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"AP136", nil)
                                           attributes: attributes];
    [text drawInRect: headerFrame];
    [lineColor setStroke];
    [NSBezierPath strokeLineFromPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, baseHeight)
                              toPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, baseHeight + HEADER_HEIGHT)];

    // Address.
    headerFrame.origin.x += purposeWidth;
    headerFrame.size.width = ACCOUNT_COLUMN_WIDTH - 2 * PADDING;
    text = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"AP137", nil)
                                           attributes: attributes];
    [text drawInRect: headerFrame];
    [lineColor setStroke];
    [NSBezierPath strokeLineFromPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, baseHeight)
                              toPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, baseHeight + HEADER_HEIGHT)];

    // Amount.
    headerFrame.origin.x += ACCOUNT_COLUMN_WIDTH;
    headerFrame.size.width = AMOUNT_COLUMN_WIDTH - 2 * PADDING;
    text = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"AP606", nil)
                                           attributes: attributes];
    [text drawInRect: headerFrame];
}

- (void)drawPageBorderWithSize: (NSSize)borderSize {
    NSRect origionalFrame = self.frame;
    self.frame = NSMakeRect(0, 0, borderSize.width, borderSize.height);
    [self lockFocus];

    // Header
    [title drawInRect: NSMakeRect(leftMargin, topMargin - 30, pageWidth, 25)];

    // Footer
    NSDictionary *attributes = @{
        NSFontAttributeName: [PreferenceController mainFontOfSize: 9 bold: false],
        NSForegroundColorAttributeName: NSColor.blackColor,
    };

    NSRect rect = NSMakeRect(leftMargin, topMargin + pageHeight + SPACING, pageWidth, 20);
    NSString *s = [NSString stringWithFormat: NSLocalizedString(@"AP133", nil), [dateTimeFormatter stringFromDate: NSDate.date]];
    [s drawInRect: rect withAttributes: attributes];

    NSMutableParagraphStyle *style = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    style.alignment = NSRightTextAlignment;
    attributes = @{
        NSFontAttributeName: [PreferenceController mainFontOfSize: 9 bold: false],
        NSForegroundColorAttributeName: NSColor.blackColor,
        NSParagraphStyleAttributeName: style
    };

    s = [NSString stringWithFormat: NSLocalizedString(@"AP134", nil), NSPrintOperation.currentOperation.currentPage, totalPages];
    [s drawInRect: rect withAttributes: attributes];

    [self unlockFocus];
    self.frame = origionalFrame;
}

- (void)drawRect: (NSRect)dirtyRect {
    NSUInteger page = -1;
    NSUInteger currentPageHeight = pageHeight + 1;

    for (NSDictionary *entry in entries) {
        NSUInteger height = [entry[@"height"] integerValue];
        if (currentPageHeight + height > pageHeight) {
            [self drawHeaderForPage: ++page];
            currentPageHeight = HEADER_HEIGHT + SPACING;
        }

        NSRect rect = NSMakeRect(PADDING, page * pageHeight + currentPageHeight, DATE_COLUMN_WIDTH - 2 * PADDING, height);
        NSAttributedString *s = entry[@"date"];
        [s drawInRect: rect];
        rect.origin.x += DATE_COLUMN_WIDTH;

        rect.size.width = purposeWidth - 2 * PADDING;
        s = entry[@"client"];
        [s drawInRect: rect];
        rect.origin.x += purposeWidth;

        rect.size.width = ACCOUNT_COLUMN_WIDTH - 2 * PADDING;
        s = entry[@"account"];
        [s drawInRect: rect];
        rect.origin.x += ACCOUNT_COLUMN_WIDTH;

        rect.size.width = AMOUNT_COLUMN_WIDTH - 2 * PADDING;
        s = entry[@"amount"];
        [s drawInRect: rect];

        currentPageHeight += height + SPACING;
    }
}

@end
