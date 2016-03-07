/**
 * Copyright (c) 2010, 2014, Pecunia Project. All rights reserved.
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

#import "BankStatementPrintView.h"
#import "StatCatAssignment.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "SepaData.h"
#import "Tag.h"
#import "ShortDate.h"

#import "PreferenceController.h"
#import "SEPAMT94xPurposeParser.h"

#import "NSString+PecuniaAdditions.h"
#import "NSAttributedString+PecuniaAdditions.h"
#import "NSDecimalNumber+PecuniaAdditions.h"

@interface BankStatementPrintView () {
    CGFloat purposeWidth;
    CGFloat pageWidth;
    CGFloat titleHeight;

    NSUInteger totalPages;
    NSUInteger pageHeight;

    BOOL printUserInfo;
    BOOL printCategories;
    BOOL printTags;
    BOOL autoCasing;

    NSMutableAttributedString *title;
    NSMutableAttributedString *additionalText;

    NSMutableArray *entries;     // Dictionaries with attributed strings (date, client, account, amount) and a height (NSNumber).

    NSDateFormatter   *dateFormatter;
    NSDateFormatter   *dateTimeFormatter;
    NSNumberFormatter *numberFormatter;

    NSFont *normalFont;
    NSFont *boldFont;
    NSFont *smallFont;
    NSFont *smallBoldFont;

    NSDictionary *purposeMapping;
}

@end

#define SPACING              5  // The distance between two entries in the table.
#define PADDING              3  // Left and right padding within in a column.
#define HEADER_HEIGHT        25 // The height of the header on each page.
#define FOOTER_HEIGHT        16 // Ditto for the footer.
#define TOTAL_SUM_HEIGHT     16 // The height of the area after the last entry to print the total sums.

// Fixed column widths, except for the description column, which is computed from the overall width and these values.
// Values include padding.
#define DATE_COLUMN_WIDTH    45
#define AMOUNT_COLUMN_WIDTH  50
#define BALANCE_COLUMN_WIDTH 60

@implementation BankStatementPrintView

- (id)initWithStatements: (NSArray *)assignmentsToPrint
               printInfo: (NSPrintInfo *)pi
                   title: (NSString *)aTitle
                category: (BankingCategory *)category
          additionalText: (NSString *)addition {
    NSRect frame = NSMakeRect(0, 0, pi.paperSize.width - pi.leftMargin - pi.rightMargin,
                              pi.paperSize.height - pi.topMargin - pi.bottomMargin);

    // There's no sense in making the view larger than the possible printable area.
    NSRect imageableBounds = pi.imageablePageBounds;
    if (NSWidth(frame) > NSWidth(imageableBounds)) {
        frame.size.width = NSWidth(imageableBounds);
    }
    if (NSHeight(frame) > NSHeight(imageableBounds)) {
        // The -2 is a weird thing. Without that the pages are 2 points too tall, rendering so a small part
        // on the next page. Couldn't find out so far why's that.
        frame.size.height = NSHeight(imageableBounds) - 2;
    }

    self = [super initWithFrame: frame];
    if (self != nil) {
        pageHeight = NSHeight(frame);
        pageWidth = NSWidth(frame);
        purposeWidth = pageWidth - DATE_COLUMN_WIDTH - 2 * AMOUNT_COLUMN_WIDTH - BALANCE_COLUMN_WIDTH;

        normalFont = [NSFont fontWithName: PreferenceController.mainFontName size: 9];
        boldFont = [NSFont fontWithName: PreferenceController.mainFontNameBold size: 9];
        smallFont = [NSFont fontWithName: PreferenceController.mainFontName size: 8];
        smallBoldFont = [NSFont fontWithName: PreferenceController.mainFontNameBold size: 8];

        purposeMapping = SEPAMT94xPurposeParser.purposeCodeMap;

        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameBold size: 16],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.000 green: 0.405 blue: 0.819 alpha: 1.000]
        };
        if (aTitle.length > 0) {
            title = [[NSMutableAttributedString alloc] initWithString: aTitle attributes: attributes];
        } else {
            title = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"Pecunia %@", NSLocalizedString(@"AP139", nil)]
                                                           attributes: attributes];
        }

        NSDictionary *boldAttributes = @{
            NSFontAttributeName: boldFont,
            NSForegroundColorAttributeName: NSColor.blackColor
        };

        NSDictionary *normalAttributes = @{
            NSFontAttributeName: normalFont,
            NSForegroundColorAttributeName: NSColor.blackColor
        };
        if (addition.length > 0) {
            attributes = @{
                NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontName size: 7.5],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite: 0.302 alpha: 1.000]
            };
            additionalText = [[NSMutableAttributedString alloc] initWithString: NSLocalizedString(@"AP835", nil) attributes: boldAttributes];
            [additionalText appendAttributedString: [[NSMutableAttributedString alloc] initWithString: addition attributes: attributes]];
        }

        NSString *name = [NSString stringWithFormat: @"\n%@", category.localName.length > 0 ? category.localName: @""];

        NSString *accountTitle;
        NSString *bankCodeTitle;
        NSString *accountNumber;
        NSString *bankCode;

        if ([category isKindOfClass: [BankAccount class]]) {
            BankAccount *account = (BankAccount *)category;
            if (account.iban != nil) {
                accountTitle = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP409", nil)];
                bankCodeTitle = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP410", nil)];

                accountNumber = account.iban.length > 0 ? account.iban : @"";
                bankCode = account.bic.length > 0 ? account.bic : @"";
            } else {
                // No old type account display. If there's no IBAN then we may have a bank or the root category.
                /*
                   accountTitle = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP401", nil)];
                   bankCodeTitle = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP400", nil)];

                   accountNumber = account.accountNumber.length > 0 ? account.accountNumber : @"";
                   bankCode = account.bankCode.length > 0 ? account.bankCode : @"";
                 */
            }
        }

        [title appendAttributedString: [[NSAttributedString alloc] initWithString: name attributes: boldAttributes]];

        if (accountTitle.length > 0) {
            [title appendAttributedString: [[NSAttributedString alloc] initWithString: @"        " attributes: normalAttributes]];
            [title appendAttributedString: [[NSAttributedString alloc] initWithString: accountTitle attributes: normalAttributes]];
            [title appendAttributedString: [[NSAttributedString alloc] initWithString: accountNumber attributes: boldAttributes]];
        }

        if (bankCodeTitle.length > 0) {
            [title appendAttributedString: [[NSAttributedString alloc] initWithString: @"        " attributes: normalAttributes]];
            [title appendAttributedString: [[NSAttributedString alloc] initWithString: bankCodeTitle attributes: normalAttributes]];
            [title appendAttributedString: [[NSAttributedString alloc] initWithString: bankCode attributes: boldAttributes]];
        }

        titleHeight = title.size.height;

        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd.MM.yy";

        dateTimeFormatter = [NSDateFormatter new];
        dateTimeFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateTimeFormatter.timeStyle = NSDateFormatterMediumStyle;

        numberFormatter = [NSNumberFormatter new];
        numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
        numberFormatter.minimumFractionDigits = 2;

        // User defaults.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        printUserInfo = [defaults boolForKey: @"printUserInfo"];
        printCategories = [defaults boolForKey: @"printCategories"];
        printTags = [defaults boolForKey: @"printTags"];
        autoCasing = [defaults boolForKey: @"autoCasing"];

        NSMutableArray   *sortedAssignments = [assignmentsToPrint mutableCopy];
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"statement.date" ascending: YES];
        [sortedAssignments sortUsingDescriptors: @[sd]];

        NSUInteger height = [self computeEntriesFromAssignments: sortedAssignments];
        if (height > pageHeight) {
            frame.size.height = height;
            self.frame = frame;
        }
    }

    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (NSAttributedString *)textFromAssignment: (StatCatAssignment *)assignment {
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];

    BankStatement *statement = assignment.statement;

    numberFormatter.currencyCode = statement.currency;

    BOOL isCreditCardStatement = statement.type.intValue == StatementType_CreditCard;

    NSAttributedString *lineBreak = [@"\n" attributedStringWithFont : normalFont];

    NSDictionary *purposeAttributes = @{
        NSFontAttributeName: normalFont,
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.000 green: 0.405 blue: 0.819 alpha: 1.000]
    };

    NSString *detailedPurpose = purposeMapping[statement.sepa.purposeCode]; // Covers unknown codes.
    if (detailedPurpose.length > 0) {
        [s appendAttributedString: [NSAttributedString stringWithString: detailedPurpose attributes: purposeAttributes]];
    } else {
        if (statement.transactionText.length > 0) {
            if (autoCasing) {
                [s appendAttributedString: [NSAttributedString stringWithString: statement.transactionText.stringWithNaturalText attributes: purposeAttributes]];
            } else {
                [s appendAttributedString: [NSAttributedString stringWithString: statement.transactionText attributes: purposeAttributes]];
            }
        } else {
            if (isCreditCardStatement) {
                [s appendAttributedString: [NSAttributedString stringWithString: NSLocalizedString(@"AP131", nil) attributes: purposeAttributes]];
            } else {
                [s appendAttributedString: [NSAttributedString stringWithString: NSLocalizedString(@"AP130", nil) attributes: purposeAttributes]];
            }
        }
    }
    [s appendAttributedString: lineBreak];

    if (statement.remoteName.length > 0) {
        if (autoCasing) {
            [s appendAttributedString: [statement.remoteName.stringWithNaturalText attributedStringWithFont: boldFont]];
        } else {
            [s appendAttributedString: [statement.remoteName attributedStringWithFont: boldFont]];
        }
        [s appendAttributedString: lineBreak];
    }

    if (statement.sepa.purpose != nil) {
        if (autoCasing) {
            [s appendAttributedString: [statement.sepa.purpose.stringWithNaturalText attributedStringWithFont: normalFont]];
        } else {
            [s appendAttributedString: [statement.sepa.purpose attributedStringWithFont: normalFont]];
        }
        [s appendAttributedString: lineBreak];
    } else {
        if (statement.purpose.length > 0) {
            if (autoCasing) {
                [s appendAttributedString: [statement.purpose.stringWithNaturalText attributedStringWithFont: normalFont]];
            } else {
                [s appendAttributedString: [statement.purpose attributedStringWithFont: normalFont]];
            }
            [s appendAttributedString: lineBreak];
        }
    }

    NSAttributedString *bankText =  [self bankAddressTextFromStatement: statement];
    if (bankText.length > 0) {
        [s appendAttributedString: bankText];
    }

    NSAttributedString *sepaInfo =  [self sepaInfoFromStatement: statement];
    if (sepaInfo.length > 0) {
        [s appendAttributedString: sepaInfo];
    }

    // Additional notes.
    if (printUserInfo && assignment.userInfo.length > 0) {
        [s appendAttributedString: [[NSString stringWithFormat: @"\n%@: %@", NSLocalizedString(@"AP145", nil), assignment.userInfo]
                                    attributedStringWithFont: smallFont]];
    }

    // Categories
    if (printCategories) {
        NSString *categories = [statement categoriesDescription];
        if (categories.length > 0) {
            [s appendAttributedString: [[NSString stringWithFormat: @"\n%@: %@", NSLocalizedString(@"AP6", nil), categories]
                                        attributedStringWithFont: smallFont]];
        }
    }

    // Tags
    if (printTags && statement.tags.count > 0) {
        NSSet           *tags = statement.tags;
        NSMutableString *tagList;
        for (Tag *tag in tags) {
            if (tagList.length == 0) {
                tagList = [tag.caption mutableCopy];
            } else {
                [tagList appendFormat: @", %@", tag.caption];
            }
        }
        [s appendAttributedString: [[NSString stringWithFormat: @"\nTags: %@", tagList] attributedStringWithFont: smallFont]];
    }

    return s;
}

- (NSAttributedString *)bankAddressTextFromStatement: (BankStatement *)statement {
    if (statement.remoteIBAN != nil) {
        NSString                  *s = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP409", nil)];
        NSMutableAttributedString *mas = [[s attributedStringWithFont: normalFont] mutableCopy];
        [mas appendAttributedString: [statement.remoteIBAN attributedStringWithFont: boldFont]];

        s = [NSString stringWithFormat: @"\n%@: ", NSLocalizedString(@"AP410", nil)];
        [mas appendAttributedString: [s attributedStringWithFont: normalFont]];
        if (statement.remoteBIC != nil) {
            [mas appendAttributedString: [statement.remoteBIC attributedStringWithFont: boldFont]];
        }
        return mas;
    } else {
        if (statement.remoteAccount.length == 0) {
            return nil;
        }

        NSString                  *s = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP401", nil)];
        NSMutableAttributedString *mas = [[s attributedStringWithFont: normalFont] mutableCopy];
        if (statement.remoteAccount.length > 0) {
            [mas appendAttributedString: [statement.remoteAccount attributedStringWithFont: boldFont]];
        }

        if (statement.remoteBankCode.length > 0) {
            s = [NSString stringWithFormat: @"\n%@: ", NSLocalizedString(@"AP400", nil)];
            [mas appendAttributedString: [s attributedStringWithFont: normalFont]];
            [mas appendAttributedString: [statement.remoteBankCode attributedStringWithFont: boldFont]];
        }
        if (statement.remoteBankName.length > 0) {
            [mas appendAttributedString: [[@"\n" stringByAppendingString : statement.remoteBankName] attributedStringWithFont: normalFont]];
        }
        return mas;
    }
}

- (void)addSepaRowToString: (NSMutableAttributedString *)text
                    forKey: (NSString *)key
                     value: (id)value {
    if (value == nil) {
        return;
    }
    NSDictionary *prefixes = SEPAMT94xPurposeParser.prefixMap;
    NSDictionary *attributes = @{
        NSFontAttributeName: smallFont,
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite: 0.302 alpha: 1.000]
    };

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString: [prefixes[key] stringByAppendingString: @": "]
                                                                               attributes: attributes];
    [text appendAttributedString: string];

    attributes = @{
        NSFontAttributeName: smallBoldFont,
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite: 0.302 alpha: 1.000]
    };

    string = [[NSMutableAttributedString alloc] initWithString: [[value description] stringByAppendingString: @"\n"]
                                                    attributes: attributes];
    [text appendAttributedString: string];

}

- (NSAttributedString *)sepaInfoFromStatement: (BankStatement *)statement {
    SepaData *data = statement.sepa;
    if (data == nil) {
        return nil;
    }

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString: @"\n" attributes: nil];
    [self addSepaRowToString: text forKey: @"EREF" value: data.endToEndId];
    [self addSepaRowToString: text forKey: @"MREF" value: data.mandateId];
    [self addSepaRowToString: text forKey: @"KREF" value: statement.customerReference];
    [self addSepaRowToString: text forKey: @"ORCR" value: data.oldCreditorId];
    [self addSepaRowToString: text forKey: @"ORMR" value: data.oldMandateId];
    [self addSepaRowToString: text forKey: @"ABWA" value: data.ultimateDebitorId];
    [self addSepaRowToString: text forKey: @"ABWE" value: data.ultimateCreditorId];
    [self addSepaRowToString: text forKey: @"CRED" value: data.creditorId];
    [self addSepaRowToString: text forKey: @"DEBT" value: data.debitorId];
    if (statement.charge.doubleValue != 0) {
        NSString *value = [[numberFormatter stringFromNumber: statement.charge] stringByAppendingString: statement.currency];
        [self addSepaRowToString: text forKey: @"COAM" value: value];
    }
    return text;
}

/**
 * Determines the text to be printed for each transfer, the height of that entry and the overall height.
 */
- (NSUInteger)computeEntriesFromAssignments: (NSArray *)assignments {
    entries = [NSMutableArray new];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    attributes[NSFontAttributeName] = normalFont;

    NSMutableParagraphStyle *style = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    style.alignment = NSRightTextAlignment;
    NSMutableDictionary *rightAlignAttributes = [attributes mutableCopy];
    rightAlignAttributes[NSParagraphStyleAttributeName] = style;

    style = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSMutableDictionary *centerAlignAttributes = [attributes mutableCopy];
    centerAlignAttributes[NSParagraphStyleAttributeName] = style;

    // The last statement in the list is most current one with the current balance (even if it is preliminary).
    // If there's more than one account participating here then sum up the balances of the last statement in each account.
    // After that subtract all statement values to compute the starting balance.
    NSDecimalNumber *balance = NSDecimalNumber.zero;
    NSMutableSet    *accounts = [NSMutableSet new];
    for (StatCatAssignment *assignment in assignments.reverseObjectEnumerator) {
        // First appearance of an account?
        if (![accounts containsObject: assignment.statement.account]) {
            balance = [balance decimalNumberByAdding: assignment.statement.saldo];
            [accounts addObject: assignment.statement.account];
        }
        if (!assignment.statement.isPreliminary.boolValue) {
            balance = [balance decimalNumberBySubtracting: assignment.value];
        }
    }
    NSUInteger currentPageHeight = HEADER_HEIGHT + titleHeight + FOOTER_HEIGHT + 2 * SPACING;
    totalPages = 1;

    for (StatCatAssignment *assignment in assignments) {
        BankStatement *statement = assignment.statement;
        if (statement.isPreliminary.boolValue) {
            continue;
        }

        NSMutableDictionary *entry = [NSMutableDictionary new];

        NSAttributedString *s;

        ShortDate *date = [ShortDate dateWithDate: statement.date];
        BOOL      printValuta = NO;
        if (statement.valutaDate != nil) {
            ShortDate *valuta = [ShortDate dateWithDate: statement.valutaDate];
            if (![date isEqual: valuta]) {
                printValuta = YES;
            }
        }

        if (printValuta) {
            s = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n%@",
                                                             [dateFormatter stringFromDate: statement.date],
                                                             [dateFormatter stringFromDate: statement.valutaDate]]
                                                attributes: centerAlignAttributes];
        } else {
            s = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@",
                                                             [dateFormatter stringFromDate: statement.date]]
                                                attributes: centerAlignAttributes];
        }
        entry[@"date"] = s;

        NSRect r = [s boundingRectWithSize: NSMakeSize(DATE_COLUMN_WIDTH - 2 * PADDING, 0)
                                   options: NSStringDrawingUsesLineFragmentOrigin];
        CGFloat entryHeight = r.size.height;

        s = [self textFromAssignment: assignment]; // Sets currency code in numberFormatter for that statement.
        entry[@"text"] = s;

        r = [s boundingRectWithSize: NSMakeSize(purposeWidth - 2 * PADDING, 0)
                            options: NSStringDrawingUsesLineFragmentOrigin];
        if (r.size.height > entryHeight) {
            entryHeight = r.size.height;
        }

        if (assignment.value.isNegative) {
            s = [[NSAttributedString alloc] initWithString: [numberFormatter stringFromNumber: assignment.value.abs]
                                                attributes: rightAlignAttributes];
            entry[@"debit"] = s;
        } else {
            s = [[NSAttributedString alloc] initWithString: [numberFormatter stringFromNumber: assignment.value]
                                                attributes: rightAlignAttributes];
            entry[@"credit"] = s;
        }

        r = [s boundingRectWithSize: NSMakeSize(AMOUNT_COLUMN_WIDTH - 2 * PADDING, 0)
                            options: NSStringDrawingUsesLineFragmentOrigin];
        if (r.size.height > entryHeight) {
            entryHeight = r.size.height;
        }

        // We want the balance *after* the statement was booked.
        balance = [balance decimalNumberByAdding: assignment.value];
        s = [[NSAttributedString alloc] initWithString: [numberFormatter stringFromNumber: balance]
                                            attributes: rightAlignAttributes];
        entry[@"balance"] = s;

        r = [s boundingRectWithSize: NSMakeSize(AMOUNT_COLUMN_WIDTH - 2 * PADDING, 0)
                            options: NSStringDrawingUsesLineFragmentOrigin];
        if (r.size.height > entryHeight) {
            entryHeight = r.size.height;
        }

        entry[@"height"] = @(entryHeight);
        entry[@"value"] = assignment.value;
        [entries addObject: entry];

        // Add another page if the current entry would exceed the current page height.
        // It will then be rendered later at the beginning of the next page.
        if (currentPageHeight + entryHeight > pageHeight) {
            ++totalPages;
            currentPageHeight = HEADER_HEIGHT + titleHeight + FOOTER_HEIGHT + SPACING;
        }
        currentPageHeight += entryHeight + SPACING;
    }
    // Sum up and additional text may need a new page.
    int additionalSpace = TOTAL_SUM_HEIGHT;
    if (additionalText.length > 0) {
        additionalSpace += additionalText.size.height;
    }
    if (currentPageHeight + additionalSpace > pageHeight) {
        ++totalPages;
    }
    return totalPages * pageHeight;
}

- (void)drawPageDetails: (int)page includingHeader: (BOOL)withHeader {
    // Drawing coordinates are within page bounds. The set page margins are implicitly applied
    // and don't need to be considered by us.
    int baseOffset = page * pageHeight + 1;

    // Page title.
    [title drawInRect: NSMakeRect(0, baseOffset, pageWidth, titleHeight)];
    int headerOffset = baseOffset + titleHeight + SPACING;

    if (withHeader) {
        // Attributes for header text.
        NSMutableParagraphStyle *style = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
        style.maximumLineHeight = 9;
        style.alignment = NSCenterTextAlignment;
        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontName size: 8],
            NSParagraphStyleAttributeName: style
        };

        // The header with column headings.
        NSRect headerFrame = NSMakeRect(0, headerOffset, pageWidth, HEADER_HEIGHT);
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
        [NSBezierPath strokeLineFromPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, headerOffset)
                                  toPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, headerOffset + HEADER_HEIGHT)];

        // Main text.
        headerFrame.origin.x += DATE_COLUMN_WIDTH;
        headerFrame.size.width = purposeWidth - 2 * PADDING;
        text = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"AP138", nil)
                                               attributes: attributes];
        [text drawInRect: headerFrame];
        [lineColor setStroke];
        [NSBezierPath strokeLineFromPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, headerOffset)
                                  toPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, headerOffset + HEADER_HEIGHT)];

        // Debit.
        headerFrame.origin.x += purposeWidth;
        headerFrame.size.width = AMOUNT_COLUMN_WIDTH - 2 * PADDING;
        text = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"AP141", nil)
                                               attributes: attributes];
        [text drawInRect: headerFrame];
        [lineColor setStroke];
        [NSBezierPath strokeLineFromPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, headerOffset)
                                  toPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, headerOffset + HEADER_HEIGHT)];

        // Credit.
        headerFrame.origin.x += AMOUNT_COLUMN_WIDTH;
        text = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"AP142", nil)
                                               attributes: attributes];
        [text drawInRect: headerFrame];
        [lineColor setStroke];
        [NSBezierPath strokeLineFromPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, headerOffset)
                                  toPoint: NSMakePoint(NSMaxX(headerFrame) + PADDING, headerOffset + HEADER_HEIGHT)];

        // Balance.
        headerFrame.origin.x += AMOUNT_COLUMN_WIDTH;
        headerFrame.size.width = BALANCE_COLUMN_WIDTH - 2 * PADDING;
        text = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"AP143", nil)
                                               attributes: attributes];
        [text drawInRect: headerFrame];
    }
    // Footer
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameMedium size: 8],
        NSForegroundColorAttributeName: NSColor.blackColor,
    };

    NSRect   rect = NSMakeRect(0, baseOffset + pageHeight - 20, pageWidth, 20);
    NSString *s = [NSString stringWithFormat: NSLocalizedString(@"AP133", nil), [dateTimeFormatter stringFromDate: NSDate.date]];
    [s drawInRect: rect withAttributes: attributes];

    NSMutableParagraphStyle *style = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    style.alignment = NSRightTextAlignment;
    attributes = @{
        NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameMedium size: 8],
        NSForegroundColorAttributeName: NSColor.blackColor,
        NSParagraphStyleAttributeName: style
    };

    s = [NSString stringWithFormat: NSLocalizedString(@"AP134", nil), page + 1, totalPages];
    [s drawInRect: rect withAttributes: attributes];
}

- (void)drawRect: (NSRect)dirtyRect {
    NSUInteger page = -1;
    NSUInteger currentPageHeight = pageHeight + 1; // Larger than the page height to trigger first page details drawing.

    NSDecimalNumber *debitSum = [NSDecimalNumber zero];
    NSDecimalNumber *creditSum = [NSDecimalNumber zero];

    NSUInteger verticalOffset = HEADER_HEIGHT + titleHeight + 2 * SPACING; // Header part that always takes a part of the page.
    for (NSDictionary *entry in entries) {
        NSUInteger height = [entry[@"height"] integerValue];
        if (currentPageHeight + height + FOOTER_HEIGHT > pageHeight) {
            [self drawPageDetails: ++page includingHeader: YES];
            currentPageHeight = verticalOffset;
        }

        NSRect rect = NSMakeRect(0 + PADDING, page * pageHeight + currentPageHeight, DATE_COLUMN_WIDTH - 2 * PADDING, height);

        NSAttributedString *s = entry[@"date"];
        [s drawInRect: rect];
        rect.origin.x += DATE_COLUMN_WIDTH;

        rect.size.width = purposeWidth - 2 * PADDING;
        s = entry[@"text"];
        [s drawInRect: rect];
        rect.origin.x += purposeWidth;

        rect.size.width = AMOUNT_COLUMN_WIDTH - 2 * PADDING;
        s = entry[@"debit"];
        [s drawInRect: rect];
        rect.origin.x += AMOUNT_COLUMN_WIDTH;

        s = entry[@"credit"];
        [s drawInRect: rect];
        rect.origin.x += AMOUNT_COLUMN_WIDTH;

        rect.size.width = BALANCE_COLUMN_WIDTH - 2 * PADDING;
        s = entry[@"balance"];
        [s drawInRect: rect];

        currentPageHeight += height + SPACING;

        NSDecimalNumber *value = entry[@"value"];
        if (value.isNegative) {
            creditSum = [creditSum decimalNumberByAdding: value];
        } else {
            debitSum = [debitSum decimalNumberByAdding: value];
        }
    }
    // Draw total sums. Start a new page if that doesn't fit on the current one anymore (bad, but no other choice).
    if (currentPageHeight + TOTAL_SUM_HEIGHT + FOOTER_HEIGHT > pageHeight) {
        [self drawPageDetails: ++page includingHeader: NO];
        currentPageHeight = verticalOffset;
    }
    NSRect  rect = NSMakeRect(0, page * pageHeight + currentPageHeight + 0.5, pageWidth, TOTAL_SUM_HEIGHT);
    NSColor *lineColor = [NSColor colorWithCalibratedRed: 0.497 green: 0.488 blue: 0.461 alpha: 1.000];
    [lineColor setStroke];
    [NSBezierPath strokeRect: rect];

    NSDictionary *boldAttributes = @{
        NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameBold size: 8],
        NSForegroundColorAttributeName: NSColor.blackColor
    };

    NSDictionary *normalAttributes = @{
        NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontName size: 8],
        NSForegroundColorAttributeName: NSColor.blackColor
    };

    rect.origin.x += PADDING;
    rect.size.width = 200;
    NSString *s = NSLocalizedString(@"AP144", nil);
    [s drawInRect: rect withAttributes: normalAttributes];

    NSMutableParagraphStyle *style = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    style.alignment = NSRightTextAlignment;
    NSMutableDictionary *rightAlignAttributes = [boldAttributes mutableCopy];
    rightAlignAttributes[NSParagraphStyleAttributeName] = style;

    rect.origin.x += DATE_COLUMN_WIDTH + purposeWidth;
    rect.size.width = AMOUNT_COLUMN_WIDTH - 2 * PADDING;

    [[numberFormatter stringFromNumber: creditSum.abs] drawInRect: rect withAttributes: rightAlignAttributes];

    rect.origin.x += AMOUNT_COLUMN_WIDTH;
    [[numberFormatter stringFromNumber: debitSum] drawInRect: rect withAttributes: rightAlignAttributes];
    currentPageHeight += TOTAL_SUM_HEIGHT + SPACING;

    // Finally any additional info.
    if (additionalText.length > 0) {
        if (currentPageHeight + additionalText.size.height  + FOOTER_HEIGHT > pageHeight) {
            [self drawPageDetails: ++page includingHeader: NO];
            currentPageHeight = titleHeight + SPACING;
        }
        rect = NSMakeRect(0, page * pageHeight + currentPageHeight, pageWidth, additionalText.size.height);
        [additionalText drawInRect: rect];
    }
}

@end
