/**
 * Copyright (c) 2012, 2014, Pecunia Project. All rights reserved.
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
#import "NSString+PecuniaAdditions.h"

#define VERT_PADDING  5
#define HEADER_HEIGHT 25

@interface TransferPrintView (private)

- (int)getTransferHeights;

@end


@implementation TransferPrintView

@synthesize transfers;

- (id)initWithTransfers: (NSArray *)transfersToPrint printInfo: (NSPrintInfo *)pi
{
    paperSize = [pi paperSize];
    topMargin = [pi topMargin];
    bottomMargin = [pi bottomMargin];
    leftMargin = [pi leftMargin];
    rightMargin = [pi rightMargin];
    pageHeight = paperSize.height - topMargin - bottomMargin;
    pageWidth = paperSize.width - leftMargin - rightMargin;
    dateWidth = 37;
    amountWidth = 65;
    bankAddressWidth = 130;
    purposeWidth = pageWidth - dateWidth - amountWidth - bankAddressWidth;
    padding = 3;
    currentPage = 1;

    self.transfers = [transfersToPrint mutableCopy];
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO];
    NSArray          *sds = @[sd];
    [self.transfers sortUsingDescriptors: sds];

    statHeights = (int *)malloc([self.transfers count] * sizeof(int));

    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"dd.MM."];

    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    [numberFormatter setMinimumFractionDigits: 2];

    debitNumberFormatter = [numberFormatter copy];
    [debitNumberFormatter setMinusSign: @""];

    NSRect frame;

    frame.origin.x = 0;
    frame.origin.y = 0;
    frame.size.width = pageWidth;

    self = [super initWithFrame: frame];
    if (self) {
        int height = [self getTransferHeights];
        if (height > pageHeight) {
            frame.size.height = height;
        } else {frame.size.height = pageHeight; }
        [self setFrame: frame];
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (NSAttributedString *)textFromTransfer: (Transfer *)transfer
{
    // Receiver
    NSFont                    *font = [NSFont fontWithName: @"Lucida Grande Bold" size: 9];
    NSMutableAttributedString *result = [[transfer.remoteName attributedStringWithFont: font] mutableCopy];

    // Type
    TransferType type = [transfer.type intValue];
    NSString     *typeString = nil;
    switch (type) {
        case TransferTypeOldStandard:
            typeString = NSLocalizedString(@"AP404", nil);
            break;

        case TransferTypeOldStandardScheduled:
            typeString = NSLocalizedString(@"AP429", nil);
            break;

        case TransferTypeSEPA:
            typeString = NSLocalizedString(@"AP406", nil);
            break;

        case TransferTypeEU:
            typeString = NSLocalizedString(@"AP405", nil);
            break;

        case TransferTypeDebit:
            typeString = NSLocalizedString(@"AP407", nil);
            break;

        default:
            typeString = @"";
            break;
    }

    // Type
    typeString = [NSString stringWithFormat: @"\n(%@)", typeString];
    font = [NSFont fontWithName: @"Helvetica Oblique" size: 8];
    [result appendAttributedString: [typeString attributedStringWithFont: font]];

    // Purpose
    font = [NSFont fontWithName: @"Lucida Grande" size: 9];
    [result appendAttributedString: [[@"\n" stringByAppendingString : transfer.purpose] attributedStringWithFont: font]];

    return result;
}

- (NSAttributedString *)bankAddressTextFromTransfer: (Transfer *)transfer
{
    if ([transfer isSEPAorEU]) {
        NSFont                    *font1 = [NSFont fontWithName: @"Lucida Grande" size: 9];
        NSFont                    *font2 = [NSFont fontWithName: @"Lucida Grande Bold" size: 8];
        NSMutableAttributedString *mas = [[@"IBAN: " attributedStringWithFont : font1] mutableCopy];
        [mas appendAttributedString: [transfer.remoteIBAN attributedStringWithFont: font2]];
        [mas appendAttributedString: [@"\nBIC: " attributedStringWithFont : font1]];
        [mas appendAttributedString: [transfer.remoteBIC attributedStringWithFont: font2]];
        return mas;
    } else {
        NSFont                    *font1 = [NSFont fontWithName: @"Lucida Grande" size: 9];
        NSFont                    *font2 = [NSFont fontWithName: @"Lucida Grande Bold" size: 9];
        NSMutableAttributedString *mas = [[@"Konto: " attributedStringWithFont : font1] mutableCopy];
        [mas appendAttributedString: [transfer.remoteAccount attributedStringWithFont: font2]];
        [mas appendAttributedString: [@"\nBLZ: " attributedStringWithFont : font1]];
        [mas appendAttributedString: [transfer.remoteBankCode attributedStringWithFont: font2]];
        [mas appendAttributedString: [[@"\n" stringByAppendingString : transfer.remoteBankName] attributedStringWithFont: font1]];
        return mas;
    }
}

- (int)getTransferHeights
{
    NSSize purposeSize;
    NSSize addressSize;
    NSSize dateSize;
    purposeSize.width = purposeWidth - 2 * padding;
    purposeSize.height = 400;
    addressSize.width = bankAddressWidth - 2 * padding;
    addressSize.height = 400;
    dateSize.width = dateWidth - 2 * padding;
    dateSize.height = 400;
    int                 page = 0;
    int                 idx = 0;
    int                 h = 45;
    int                 height;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity: 1];
    attributes[NSFontAttributeName] = [NSFont userFontOfSize: 9];

    NSRect r = [@"01.01.\n10.10." boundingRectWithSize : dateSize options : NSStringDrawingUsesLineFragmentOrigin attributes : attributes];
    minStatHeight = r.size.height;

    for (Transfer *transfer in self.transfers) {
        NSAttributedString *s = [self textFromTransfer: transfer];
        r = [s boundingRectWithSize: purposeSize options: NSStringDrawingUsesLineFragmentOrigin];
        height = r.size.height;
        if (height < minStatHeight) {
            height = minStatHeight;
        }
        s = [self bankAddressTextFromTransfer: transfer];
        r = [s boundingRectWithSize: addressSize options: NSStringDrawingUsesLineFragmentOrigin];
        if (r.size.height > height) {
            height = r.size.height;
        }
        if (h + height + VERT_PADDING > pageHeight) {
            page++;
            h = HEADER_HEIGHT + VERT_PADDING;
        }
        h += height + VERT_PADDING;
        statHeights[idx++] = height;
    }
    totalPages = page + 1;
    return page * pageHeight + h + 18;
}

- (void)finalizePage: (int)page atPosition: (int)pos
{
    int baseHeight = page * pageHeight;
    int hBase = 0;
    [NSBezierPath strokeLineFromPoint: NSMakePoint(0, baseHeight + pos) toPoint: NSMakePoint(pageWidth, baseHeight + pos)];
    [NSBezierPath strokeLineFromPoint: NSMakePoint(hBase, baseHeight + HEADER_HEIGHT) toPoint: NSMakePoint(hBase, baseHeight + pos)];
    hBase += dateWidth;
    [NSBezierPath strokeLineFromPoint: NSMakePoint(hBase, baseHeight + HEADER_HEIGHT) toPoint: NSMakePoint(hBase, baseHeight + pos)];
    hBase += purposeWidth;
    [NSBezierPath strokeLineFromPoint: NSMakePoint(hBase, baseHeight + HEADER_HEIGHT) toPoint: NSMakePoint(hBase, baseHeight + pos)];
    hBase += bankAddressWidth;
    [NSBezierPath strokeLineFromPoint: NSMakePoint(hBase, baseHeight + HEADER_HEIGHT) toPoint: NSMakePoint(hBase, baseHeight + pos)];
    hBase += amountWidth;
    [NSBezierPath strokeLineFromPoint: NSMakePoint(hBase, baseHeight + HEADER_HEIGHT) toPoint: NSMakePoint(hBase, baseHeight + pos)];
}

- (void)drawHeaderForPage: (int)page
{
    int baseHeight = page * pageHeight;
    int hBase = 0;

    // Attributes for header text
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity: 1];
    attributes[NSFontAttributeName] = [NSFont fontWithName: @"Helvetica-Bold" size: 9];
    [NSBezierPath setDefaultLineWidth: 0.5];

    // first header rect
    NSRect headerFrame = NSMakeRect(0, baseHeight + 1, pageWidth, HEADER_HEIGHT);
    [[NSColor lightGrayColor] setFill];
    [NSBezierPath fillRect: headerFrame];
    [NSBezierPath strokeRect: headerFrame];
    //[NSBezierPath strokeLineFromPoint:NSMakePoint(0, baseHeight+20) toPoint:NSMakePoint(pageWidth, baseHeight+20) ];

    // dates
    hBase += dateWidth;
    headerFrame = NSMakeRect(0, baseHeight, dateWidth, HEADER_HEIGHT);
    [NSBezierPath strokeLineFromPoint: NSMakePoint(hBase, baseHeight) toPoint: NSMakePoint(hBase, baseHeight + HEADER_HEIGHT)];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString: @"Datum\nValuta" attributes: attributes];
    headerFrame.origin.y += 1;
    headerFrame.origin.x += padding;
    [as drawInRect: headerFrame];

    // purpose
    hBase += purposeWidth;
    headerFrame = NSMakeRect(dateWidth, baseHeight, purposeWidth, HEADER_HEIGHT);
    //	[NSBezierPath strokeRect:headerFrame ];
    [NSBezierPath strokeLineFromPoint: NSMakePoint(hBase, baseHeight) toPoint: NSMakePoint(hBase, baseHeight + HEADER_HEIGHT)];
    as = [[NSAttributedString alloc] initWithString: @"Empfänger\nBuchungshinweis" attributes: attributes];
    headerFrame.origin.y += 1;
    headerFrame.origin.x += padding;
    [as drawInRect: headerFrame];

    // bankAddress
    hBase += bankAddressWidth;
    headerFrame = NSMakeRect(dateWidth + purposeWidth, baseHeight, bankAddressWidth, HEADER_HEIGHT);
    //	[NSBezierPath strokeRect:headerFrame ];
    [NSBezierPath strokeLineFromPoint: NSMakePoint(hBase, baseHeight) toPoint: NSMakePoint(hBase, baseHeight + HEADER_HEIGHT)];
    as = [[NSAttributedString alloc] initWithString: @"Kontoverbindung" attributes: attributes];
    headerFrame.origin.y += 1;
    headerFrame.origin.x += padding;
    [as drawInRect: headerFrame];

    // amount
    hBase += amountWidth;
    headerFrame = NSMakeRect(dateWidth + purposeWidth + bankAddressWidth, baseHeight, amountWidth, HEADER_HEIGHT);
    //	[NSBezierPath strokeRect:headerFrame ];
    [NSBezierPath strokeLineFromPoint: NSMakePoint(hBase, baseHeight) toPoint: NSMakePoint(hBase, baseHeight + HEADER_HEIGHT)];
    as = [[NSAttributedString alloc] initWithString: @"Betrag" attributes: attributes];
    headerFrame.origin.y += 1;
    headerFrame.origin.x += padding;
    [as drawInRect: headerFrame];
}

- (void)drawPageBorderWithSize: (NSSize)borderSize
{
    NSString        *s;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle: NSDateFormatterMediumStyle];
    [df setTimeStyle: NSDateFormatterMediumStyle];

    NSParagraphStyle        *ps = [NSParagraphStyle defaultParagraphStyle];
    NSMutableParagraphStyle *mps = [ps mutableCopy];
    [mps setAlignment: NSRightTextAlignment];

    NSRect frame = [self frame];
    NSRect newFrame = NSMakeRect(0, 0, borderSize.width, borderSize.height);
    [self setFrame: newFrame];
    [self lockFocus];

    // Header
    NSMutableDictionary *headerAttributes = [NSMutableDictionary dictionaryWithCapacity: 1];
    headerAttributes[NSFontAttributeName] = [NSFont fontWithName: @"Helvetica Bold Oblique" size: 16];
    //[headerAttributes setObject:mps forKey:NSParagraphStyleAttributeName ];
    NSRect rect = NSMakeRect(leftMargin, topMargin - 30, pageWidth, 25);
    //rect.size.width-=10;
    [@"Überweisungsliste" drawInRect : rect withAttributes : headerAttributes];

    // Footer
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity: 1];
    attributes[NSFontAttributeName] = [NSFont fontWithName: @"Helvetica-Bold" size: 9];

    rect = NSMakeRect(leftMargin, topMargin + pageHeight + VERT_PADDING, pageWidth, 20);
    s = [NSString stringWithFormat: @"Erstellt am %@", [df stringFromDate: [NSDate date]]];
    [s drawInRect: rect withAttributes: attributes];

    attributes[NSParagraphStyleAttributeName] = mps;
    s = [NSString stringWithFormat: @"Seite %li von %i", [[NSPrintOperation currentOperation] currentPage], totalPages];
    [s drawInRect: rect withAttributes: attributes];


    [self unlockFocus];
    [self setFrame: frame];
}

- (void)drawRect: (NSRect)dirtyRect
{
    NSSize size;
    NSRect rect;
    int    page = 0;
    int    idx = 0;
    int    height;

    NSParagraphStyle        *ps = [NSParagraphStyle defaultParagraphStyle];
    NSMutableParagraphStyle *mps = [ps mutableCopy];
    [mps setAlignment: NSRightTextAlignment];

    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity: 1];
    attributes[NSFontAttributeName] = [NSFont userFontOfSize: 9];

    NSMutableDictionary *amountAttributes = [NSMutableDictionary dictionaryWithCapacity: 2];
    amountAttributes[NSFontAttributeName] = [NSFont fontWithName: @"Lucida Grande" size: 10];
    amountAttributes[NSParagraphStyleAttributeName] = mps;

    size.width = purposeWidth - 2 * padding;
    size.height = 400;
    int h = HEADER_HEIGHT + VERT_PADDING;

    [self drawHeaderForPage: 0];

    // draw statements
    for (Transfer *transfer in self.transfers) {
        int hBase = 0;
        height = statHeights[idx++];
        if (h + height + VERT_PADDING > pageHeight) {
            [self finalizePage: page atPosition: h];
            page++;
            h = HEADER_HEIGHT + VERT_PADDING;
            [self drawHeaderForPage: page];
        }
        rect.origin.x = hBase + padding;
        rect.origin.y = page * pageHeight + h;
        rect.size.height = height;

        // dates
        rect.size.width = dateWidth - 2 * padding;
        NSDate   *valutaDate = transfer.valutaDate;
        NSString *s;
        if (valutaDate) {
            s = [NSString stringWithFormat: @"%@\n%@", [dateFormatter stringFromDate: transfer.date], [dateFormatter stringFromDate: transfer.valutaDate]];
        } else {
            s = [dateFormatter stringFromDate: transfer.date];
        }
        rect.origin.y += 2;
        [s drawInRect: rect withAttributes: attributes];
        rect.origin.y -= 2;
        hBase += dateWidth;

        // receiver etc.
        rect.size.width = purposeWidth - 2 * padding;
        rect.origin.x = hBase + padding;
        NSAttributedString *as = [self textFromTransfer: transfer];
        [as drawInRect: rect];
        hBase += purposeWidth;

        rect.size.width = bankAddressWidth - 2 * padding;
        rect.origin.x = hBase + padding;
        as = [self bankAddressTextFromTransfer: transfer];
        [as drawInRect: rect];
        hBase += bankAddressWidth;

        // Amount
        rect.size.width = amountWidth - 2 * padding;
        rect.origin.x = hBase + padding;
        [numberFormatter setCurrencyCode: transfer.currency];
        [[numberFormatter stringFromNumber: transfer.value] drawInRect: rect withAttributes: amountAttributes];
        hBase += amountWidth;
        h += height + VERT_PADDING;
    }
    [self finalizePage: page atPosition: h];

    /*
     // draw final sum
     rect.origin.x = 0;
     rect.origin.y = page*pageHeight + h + 1;
     rect.size.width = pageWidth;
     rect.size.height = 16;
     [NSBezierPath strokeRect:rect ];
     rect.origin.x += padding;
     rect.size.width = 200;
     [@"Summe" drawInRect:rect withAttributes:attributes ];

     rect.origin.x = dateWidth+purposeWidth+padding;
     rect.size.width = amountWidth-2*padding;
     [[debitNumberFormatter stringFromNumber:debitSum ] drawInRect:rect withAttributes:amountAttributes ];

     rect.origin.x = dateWidth+purposeWidth+amountWidth+padding;
     rect.size.width = amountWidth-2*padding;
     [[numberFormatter stringFromNumber:creditSum ] drawInRect:rect withAttributes:amountAttributes ];

     rect.origin.x = dateWidth+purposeWidth+2*amountWidth+padding;
     rect.size.width = amountWidth-2*padding;
     [[numberFormatter stringFromNumber:currentSaldo ] drawInRect:rect withAttributes:amountAttributes ];
     */
}

@end
