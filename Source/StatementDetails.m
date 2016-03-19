/**
 * Copyright (c) 2008, 2015, Pecunia Project. All rights reserved.
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

#import "StatementDetails.h"
#import "StatementsListView.h"
#import "GraphicsAdditions.h"
#import "AttachmentImageView.h"
#import "StatCatAssignment.h"
#import "BankingCategory.h"
#import "TagView.h"
#import "PreferenceController.h"

#import "SEPAMT94xPurposeParser.h"
#import "BankStatement.h"
#import "SepaData.h"
#import "ShortDate.h"
#import "SliderView.h"

#import "NSView+PecuniaAdditions.h"
#import "NSColor+PecuniaAdditions.h"
#import "NSString+PecuniaAdditions.h"
#import "NSImage+PecuniaAdditions.h"

#import "MOAssistant.h"

extern void *UserDefaultsBindingContext;

@interface DetailsViewStepperCell : NSStepperCell
@end

@implementation DetailsViewStepperCell

- (void)drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView {
    [NSColor.blackColor set];

    cellFrame = NSInsetRect(cellFrame, 6, 0);
    NSBezierPath *path = [NSBezierPath new];
    [path moveToPoint: NSMakePoint(NSMinX(cellFrame), NSMidY(cellFrame) + 2)];
    [path lineToPoint: NSMakePoint(NSMaxX(cellFrame), NSMidY(cellFrame) + 2)];
    [path lineToPoint: NSMakePoint(NSMidX(cellFrame), NSMidY(cellFrame) + NSWidth(cellFrame) / 2 + 2)];
    [path closePath];
    [path fill];

    path = [NSBezierPath new];
    [path moveToPoint: NSMakePoint(NSMinX(cellFrame), NSMidY(cellFrame) - 2)];
    [path lineToPoint: NSMakePoint(NSMaxX(cellFrame), NSMidY(cellFrame) - 2)];
    [path lineToPoint: NSMakePoint(NSMidX(cellFrame), NSMidY(cellFrame) - NSWidth(cellFrame) / 2 - 2)];
    [path closePath];
    [path fill];
}

@end

@interface DateTextFieldCell : NSTextFieldCell
@end

@implementation DateTextFieldCell

- (void)drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView {
    [super drawInteriorWithFrame: cellFrame inView: controlView];
}

@end

@interface DateTextField : NSTextField
@end

@implementation DateTextField

- (void)resizeSubviewsWithOldSize: (NSSize)oldSize {
    // Adjust right alignment tab to always sit at the right border.
    NSMutableAttributedString *string = [self.attributedStringValue mutableCopy];
    [string removeAttribute: NSParagraphStyleAttributeName
                      range: NSMakeRange(0, string.length)];

    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSLeftTextAlignment;
    NSTextTab *tab = [[NSTextTab alloc] initWithTextAlignment: NSRightTextAlignment
                                                     location: NSWidth(self.frame) - 4
                                                      options: [NSDictionary new]];
    style.tabStops = @[tab];
    [string addAttribute: NSParagraphStyleAttributeName
                   value: style
                   range: NSMakeRange(0, string.length)];
    self.attributedStringValue = string;
}

@end

#pragma mark - Statement details implementation

@interface DetailsTagView : TagView
@end

@implementation DetailsTagView

@end

@interface StatementDetails () {
    NSDictionary *purposeMapping;
}

@property (weak) IBOutlet NSTextField *valueField;
@property (weak) IBOutlet NSTextField *nassValueField;
@property (weak) IBOutlet NSTextField *purposeTitle;

@property (weak) IBOutlet AttachmentImageView *attachment1;
@property (weak) IBOutlet AttachmentImageView *attachment2;
@property (weak) IBOutlet AttachmentImageView *attachment3;
@property (weak) IBOutlet AttachmentImageView *attachment4;

@property (weak) IBOutlet NSImageView *typeImage;
@property (weak) IBOutlet NSImageView *manualIndicator;
@property (weak) IBOutlet NSImageView *isReversalIndicator;
@property (weak) IBOutlet NSImageView *isNewIndicator;
@property (weak) IBOutlet NSImageView *isSettledIndicator;

@property (weak) IBOutlet NSButton    *tagButton;
@property (weak) IBOutlet NSBox       *colorBox;
@property (weak) IBOutlet NSTextField *currencyField;

@property (strong) IBOutlet NSTextView *notesTextView;
@property (strong) IBOutlet TagView    *tagView;
@property (strong) IBOutlet NSTextView *sepaInfoTextView;

@property (weak) IBOutlet NSImageView *sequenceTypeImage;
@property (weak) IBOutlet SliderView  *dateSlider;
@property (weak) IBOutlet NSStepper   *dateStepper;

@property (strong) IBOutlet TagView         *tagViewPopup;
@property (weak) IBOutlet NSView            *tagViewHost;
@property (weak) IBOutlet NSArrayController *tagsController;
@property (weak) IBOutlet NSArrayController *statementTags;

@property (weak) IBOutlet NSLayoutConstraint *verticalConstraintValueCurrency;
@property (weak) IBOutlet NSLayoutConstraint *dateFieldRightBorderConstraint;

@property (weak) IBOutlet NSView *bankStatementDetailsContainer;
@property (weak) IBOutlet NSView *creditCardDetailsContainer;

@end

@implementation StatementDetails

@synthesize sepaDetails;

@synthesize valueField;
@synthesize nassValueField;
@synthesize purposeTitle;

@synthesize attachment1;
@synthesize attachment2;
@synthesize attachment3;
@synthesize attachment4;
@synthesize tagButton;
@synthesize colorBox;
@synthesize notesTextView;
@synthesize currencyField;

@synthesize sequenceTypeImage;
@synthesize dateSlider;
@synthesize dateStepper;

@synthesize tagViewPopup;
@synthesize tagView;
@synthesize tagsController;
@synthesize statementTags;
@synthesize tagViewHost;
@synthesize sepaInfoTextView;

@synthesize typeImage;
@synthesize manualIndicator;
@synthesize isReversalIndicator;
@synthesize isNewIndicator;
@synthesize isSettledIndicator;

@synthesize verticalConstraintValueCurrency;
@synthesize dateFieldRightBorderConstraint;

@synthesize bankStatementDetailsContainer;
@synthesize creditCardDetailsContainer;

- (void)awakeFromNib {
    [super awakeFromNib];

    sepaInfoTextView.delegate = self;
    [NSNotificationCenter.defaultCenter addObserver: self
                                           selector: @selector(updateDisplayAfterLoading)
                                               name: WordMapping.pecuniaWordsLoadedNotification
                                             object: nil];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
    [defaults addObserver: self forKeyPath: @"autoCasing" options: 0 context: UserDefaultsBindingContext];

    purposeMapping = SEPAMT94xPurposeParser.purposeCodeMap;

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"order" ascending: YES];
    [statementTags setSortDescriptors: @[sd]];
    [tagsController setSortDescriptors: @[sd]];
    tagButton.bordered = NO;

    tagsController.managedObjectContext = MOAssistant.sharedAssistant.context;
    [tagsController prepareContent];

    tagViewPopup.datasource = tagsController;
    tagViewPopup.defaultFont = [PreferenceController mainFontOfSize: 11 bold: NO];
    tagViewPopup.canCreateNewTags = YES;

    tagView.datasource = statementTags;
    tagView.defaultFont = [PreferenceController mainFontOfSize: 11 bold: NO];
    tagView.canCreateNewTags = YES;

    notesTextView.editable = NO;

    isReversalIndicator.image = [NSImage imageNamed: @"icon66-1" fromCollection: 1];

    [self updateValueColors];

}

- (void)updateDisplayAfterLoading {
    [self updateCaseDependentTextInDetails: self.sepaDetails];
}

- (void)updateValueColors {
    NSDictionary *positiveAttributes = @{
        NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]
    };
    NSDictionary *negativeAttributes = @{
        NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]
    };

    NSNumberFormatter *formatter = [valueField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [valueField setNeedsDisplay];

    formatter = [nassValueField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [nassValueField setNeedsDisplay];
}

- (NSMutableAttributedString *)createCellStringWithString: (NSString *)string
                                                    table: (NSTextTable *)table
                                                alignment: (NSTextAlignment)textAlignment
                                                      row: (int)row
                                                   column: (int)column
                                                     font: (id)font
                                                    color: (NSColor *)color {
    NSTextTableBlock *block = [[NSTextTableBlock alloc] initWithTable: table
                                                          startingRow: row
                                                              rowSpan: 1
                                                       startingColumn: column
                                                           columnSpan: 1];
    [block setWidth: 0 type: NSTextBlockAbsoluteValueType forLayer: NSTextBlockBorder];
    [block setWidth: 2 type: NSTextBlockAbsoluteValueType forLayer: NSTextBlockPadding];
    if (column == 0) {
        [block setValue: 40 type: NSTextBlockPercentageValueType forDimension: NSTextBlockWidth];
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.textBlocks = @[block];
    paragraphStyle.alignment = textAlignment;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;

    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSParagraphStyleAttributeName: paragraphStyle,
        NSForegroundColorAttributeName: color
    };

    NSMutableAttributedString *cellString = [[NSMutableAttributedString alloc] initWithString: string attributes: attributes];

    return cellString;
}

- (BOOL)addRowToString: (NSMutableAttributedString *)text
                 table: (NSTextTable *)table
                   row: (NSUInteger)row
                forKey: (NSString *)key
                 value: (id)value {
    if (value == nil) {
        return NO;
    }
    NSDictionary *prefixes = SEPAMT94xPurposeParser.prefixMap;
    [text appendAttributedString: [self createCellStringWithString: [prefixes[key] stringByAppendingString: @": \n"]
                                                             table: table
                                                         alignment: NSRightTextAlignment
                                                               row: row
                                                            column: 0
                                                              font: [PreferenceController mainFontOfSize: 12 bold: NO]
                                                             color: [NSColor colorWithCalibratedWhite: 0.302 alpha: 1.000]]];
    [text appendAttributedString: [self createCellStringWithString: [[value description] stringByAppendingString: @"\n"]
                                                             table: table
                                                         alignment: NSLeftTextAlignment
                                                               row: row
                                                            column: 1
                                                              font: [PreferenceController mainFontOfSize: 12 bold: NO]
                                                             color: [NSColor colorWithCalibratedWhite: 0.302 alpha: 1.000]]];
    return YES;
}

- (BOOL)addRowToString: (NSMutableAttributedString *)text
                 table: (NSTextTable *)table
                   row: (NSUInteger)row
               caption: (NSString *)caption
                 value: (id)value {
    if (value == nil) {
        return NO;
    }
    [text appendAttributedString: [self createCellStringWithString: [caption stringByAppendingString: @": \n"]
                                                             table: table
                                                         alignment: NSRightTextAlignment
                                                               row: row
                                                            column: 0
                                                              font: [PreferenceController mainFontOfSize: 11 bold: NO]
                                                             color: [NSColor colorWithCalibratedWhite: 0.302 alpha: 1.000]]];
    [text appendAttributedString: [self createCellStringWithString: [[value description] stringByAppendingString: @"\n"]
                                                             table: table
                                                         alignment: NSLeftTextAlignment
                                                               row: row
                                                            column: 1
                                                              font: [PreferenceController mainFontOfSize: 12 bold: NO]
                                                             color: [NSColor colorWithCalibratedWhite: 0.302 alpha: 1.000]]];
    return YES;
}

- (void)createSEPAInfoTextInDetails: (NSMutableDictionary *)details forStatement: (BankStatement *)statement {
    SepaData *data = statement.sepa;
    if (data == nil) {
        return;
    }

    NSMutableAttributedString *text = [NSMutableAttributedString new];
    NSTextTable               *table = [NSTextTable new];
    table.numberOfColumns = 2;
    [table setContentWidth: 100 type: NSTextBlockPercentageValueType];

    int currentRow = 0;
    if ([self addRowToString: text table: table row: currentRow forKey: @"EREF" value: data.endToEndId]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow forKey: @"MREF" value: data.mandateId]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow forKey: @"KREF" value: statement.customerReference]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow forKey: @"ORCR" value: data.oldCreditorId]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow forKey: @"ORMR" value: data.oldMandateId]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow forKey: @"ABWA" value: data.ultimateDebitorId]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow forKey: @"ABWE" value: data.ultimateCreditorId]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow forKey: @"CRED" value: data.creditorId]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow forKey: @"DEBT" value: data.debitorId]) {
        ++currentRow;
    }
    if (statement.charge.doubleValue != 0) {
        NSString *value = [[valueField.formatter stringFromNumber: statement.charge] stringByAppendingString: currencyField.stringValue];
        if ([self addRowToString: text table: table row: currentRow forKey: @"COAM" value: value]) {
            ++currentRow;
        }
    }

    details[@"sepaInfo"] = text;
}

- (void)createCreditCardInfoTextInDetails: (NSMutableDictionary *)details forStatement: (BankStatement *)statement {
    NSMutableAttributedString *text = [NSMutableAttributedString new];
    NSTextTable               *table = [NSTextTable new];
    table.numberOfColumns = 2;
    [table setContentWidth: 100 type: NSTextBlockPercentageValueType];

    // Format the credit card number with spaces if it only contains digits.
    NSMutableString *number = statement.ccNumberUms.mutableCopy;
    if ([number rangeOfCharacterFromSet: [NSCharacterSet.decimalDigitCharacterSet invertedSet]].location == NSNotFound) {
        for (NSUInteger i = number.length - 4; i > 0; i -= 4) {
            [number insertString: @" " atIndex: i];
        }
    }
    int currentRow = 0;
    if ([self addRowToString: text table: table row: currentRow caption: NSLocalizedString(@"AP436", nil) value: number]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow caption: NSLocalizedString(@"AP437", nil) value: statement.ccChargeKey]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow caption: NSLocalizedString(@"AP438", nil) value: statement.ccChargeTerminal]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow caption: NSLocalizedString(@"AP439", nil) value: statement.ccChargeForeign]) {
        ++currentRow;
    }
    if ([self addRowToString: text table: table row: currentRow caption: NSLocalizedString(@"AP440", nil) value: statement.ccSettlementRef]) {
        ++currentRow;
    }

    details[@"creditCardInfo"] = text;
}

/**
 * Update text fields that depend on proper casing.
 */
- (void)updateCaseDependentTextInDetails: (NSMutableDictionary *)details {
    StatCatAssignment *assignment = self.representedObject;
    BankStatement     *statement = assignment.statement;

    BOOL isCreditCardStatement = statement.type.intValue == StatementType_CreditCard;
    BOOL autoCasing = [NSUserDefaults.standardUserDefaults boolForKey: @"autoCasing"];

    NSString *detailedPurpose = purposeMapping[statement.sepa.purposeCode]; // Covers unknown codes.
    if (detailedPurpose.length > 0) {
        details[@"PURP"] = detailedPurpose;
    } else {
        NSString *transactionText = statement.transactionText;
        if (transactionText.length > 0) {
            details[@"PURP"] = autoCasing ? transactionText.stringWithNaturalText : transactionText;
        } else {
            if (isCreditCardStatement) {
                details[@"PURP"] = NSLocalizedString(@"AP131", nil);
            } else {
                details[@"PURP"] = NSLocalizedString(@"AP130", nil);
            }
        }
    }

    if (statement.sepa.purpose != nil) {
        details[@"description"] = statement.sepa.purpose;
    } else {
        details[@"description"] = statement.purpose == nil ? @"" : statement.purpose;
    }

    self.sepaDetails = details;
}

- (void)addDateField: (NSString *)name
             forDate: (ShortDate *)date
              normal: (NSDictionary *)normalAttributes
                bold: (NSDictionary *)boldAttributes {
    DateTextField *field = [[DateTextField alloc] initWithFrame: NSMakeRect(0, 0, 100, 20)];
    field.bordered = NO;
    field.editable = NO;
    field.selectable = NO;
    field.drawsBackground = NO;
    [field.cell setScrollable: YES];
    [field.cell setUsesSingleLineMode: YES];

    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    NSTextTab               *tab = [[NSTextTab alloc] initWithTextAlignment: NSRightTextAlignment
                                                                   location: NSWidth(dateSlider.frame) - 4
                                                                    options: [NSDictionary new]];
    style.tabStops = @[tab];

    NSMutableAttributedString *string = [NSMutableAttributedString new];
    [string appendAttributedString: [[NSAttributedString alloc] initWithString: name
                                                                    attributes: normalAttributes]
    ];
    [string appendAttributedString: [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"\t%@", date]
                                                                    attributes: boldAttributes]
    ];
    [string addAttribute: NSParagraphStyleAttributeName
                   value: style
                   range: NSMakeRange(0, string.length)];

    field.attributedStringValue = string;
    [dateSlider addSubview: field];

}

- (void)setRepresentedObject: (id)value {
    [super setRepresentedObject: value];

    StatCatAssignment *assignment = value;
    colorBox.fillColor = assignment.category.categoryColor;

    // Construct certain values out of the available data.
    BankStatement     *statement = assignment.statement;

    BOOL isCreditCardStatement = statement.type.intValue == StatementType_CreditCard;

    NSMutableDictionary *details = [NSMutableDictionary new];
    [self updateCaseDependentTextInDetails: (NSMutableDictionary *)details];

    [verticalConstraintValueCurrency.animator setConstant: statement.isAssigned.boolValue ? 15: 39];

    // Update sequence type image. We use the SEPA sequence type, if given. Otherwise we try to derive the correct
    // image from the transfer type.
    NSDictionary *sequenceTypeMap = SEPAMT94xPurposeParser.sequenceTypeMap;
    NSString     *sequenceType;
    if (statement.sepa.sequenceType.length > 0) {
        sequenceType = statement.sepa.sequenceType;
    } else {
        sequenceType = [SEPAMT94xPurposeParser sequenceTypeFromString: statement.transactionText];
    }

    // Compose sequence type image from background and type image. Background determines future transactions.
    NSImage *background;
    if (statement.isPreliminary.boolValue) {
        background = [NSImage imageNamed: @"sequence-type-red"];
    } else {
        background = [NSImage imageNamed: @"sequence-type-blue"];
    }
    NSImage *sequenceImage = [[NSImage alloc] initWithSize: background.size];
    [sequenceImage lockFocus];
    [background drawAtPoint: NSMakePoint(0, 0) fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1];
    [sequenceImage unlockFocus];

    if (sequenceType.length == 0) {
        sequenceType = @"OOFF";
    }
    NSString *tooltip = sequenceTypeMap[sequenceType][@"description"];
    if (tooltip.length == 0) {
        tooltip = NSLocalizedString(@"AP1215", nil);
    }
    if (statement.isPreliminary.boolValue) {
        tooltip = [tooltip stringByAppendingString: NSLocalizedString(@"AP1550", nil)];
    }
    sequenceTypeImage.toolTip = tooltip;
    NSImage *overlay = [NSImage imageNamed: sequenceTypeMap[sequenceType][@"image"]];
    [sequenceImage lockFocus];
    [overlay drawAtPoint: NSMakePoint(0, 0) fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1];
    [sequenceImage unlockFocus];
    sequenceTypeImage.image = sequenceImage;

    NSDictionary *normalAttributes = @{
        NSFontAttributeName : [PreferenceController mainFontOfSize: 13 bold: NO],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite: 0.302 alpha: 1.000]
    };
    NSDictionary *boldAttributes = @{
        NSFontAttributeName: [PreferenceController mainFontOfSize: 13 bold: NO],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite: 0.302 alpha: 1.000]
    };

    dateSlider.subviews = @[];
    ShortDate *date = [ShortDate dateWithDate: statement.date];
    [self addDateField: NSLocalizedString(@"AP605", nil) forDate: date normal: normalAttributes bold: boldAttributes];
    if (statement.valutaDate != nil) {
        ShortDate *valuta = [ShortDate dateWithDate: statement.valutaDate];
        if (![date isEqual: valuta] || [valuta compare: ShortDate.currentDate] == NSOrderedDescending) {
            [self addDateField: NSLocalizedString(@"AP604", nil) forDate: valuta normal: normalAttributes bold: boldAttributes];
        }
    }

    if (statement.docDate != nil) {
        date = [ShortDate dateWithDate: statement.docDate];
        [self addDateField: NSLocalizedString(@"AP632", nil) forDate: date normal: normalAttributes bold: boldAttributes];
    }

    if (statement.sepa.mandateSignatureDate != nil) {
        date = [ShortDate dateWithDate: statement.sepa.mandateSignatureDate];
        [self addDateField: NSLocalizedString(@"AP630", nil) forDate: date normal: normalAttributes bold: boldAttributes];
    }

    if (statement.sepa.settlementDate != nil) {
        date = [ShortDate dateWithDate: statement.sepa.settlementDate];
        [self addDateField: NSLocalizedString(@"AP631", nil) forDate: date normal: normalAttributes bold: boldAttributes];
    }

    BOOL hideStepper = dateSlider.subviews.count < 2;
    [dateStepper.animator setHidden: hideStepper];
    dateFieldRightBorderConstraint.constant = hideStepper ? 21 : 35;

    dateSlider.slide = SlideVertical;
    dateSlider.fade = NO;
    dateSlider.wrap = YES;

    bankStatementDetailsContainer.hidden = isCreditCardStatement;
    creditCardDetailsContainer.hidden = !isCreditCardStatement;
    if (isCreditCardStatement) {
        typeImage.image = [NSImage imageNamed: @"icon87-1" fromCollection: 1];
        typeImage.toolTip = NSLocalizedString(@"AP1552", nil);

        isSettledIndicator.alphaValue = statement.isSettled.boolValue ? 1 : 0.25;

        [self createCreditCardInfoTextInDetails: details forStatement: statement];
    } else {
        typeImage.image = [NSImage imageNamed: @"icon95-1" fromCollection: 1];
        typeImage.toolTip = NSLocalizedString(@"AP1551", nil);

        manualIndicator.alphaValue = statement.isManual.boolValue ? 1 : 0.25;
        isReversalIndicator.alphaValue = statement.isStorno.boolValue ? 1 : 0.25;
        isNewIndicator.alphaValue = statement.isNew.boolValue ? 1 : 0.25;

        NSString *accountTitle;
        NSString *bankCodeTitle;
        NSString *accountNumber;
        NSString *bankCode;
        if (statement.remoteIBAN != nil) {
            accountTitle = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP409", nil)];
            bankCodeTitle = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP410", nil)];

            accountNumber = statement.remoteIBAN;
            bankCode = statement.remoteBIC == nil ? @"--" : statement.remoteBIC;
        } else {
            accountTitle = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP401", nil)];
            bankCodeTitle = [NSString stringWithFormat: @"%@: ", NSLocalizedString(@"AP400", nil)];

            accountNumber = statement.remoteAccount == nil ? @"--" : statement.remoteAccount;
            bankCode = statement.remoteBankCode == nil ? @"--" : statement.remoteBankCode;
        }

        NSMutableAttributedString *string = [NSMutableAttributedString new];
        [string appendAttributedString: [[NSAttributedString alloc] initWithString: accountTitle
                                                                        attributes: normalAttributes]
        ];
        [string appendAttributedString: [[NSAttributedString alloc] initWithString: accountNumber
                                                                        attributes: boldAttributes]
        ];
        details[@"accountNumber"] = string;

        string = [NSMutableAttributedString new];

        [string appendAttributedString: [[NSAttributedString alloc] initWithString: bankCodeTitle
                                                                        attributes: normalAttributes]
        ];
        [string appendAttributedString: [[NSAttributedString alloc] initWithString: bankCode
                                                                        attributes: boldAttributes]
        ];
        details[@"bankCode"] = string;

    }

    [self createSEPAInfoTextInDetails: details forStatement: statement];
    self.sepaDetails = details; // Triggers KVO.
}

#pragma mark - User Actions

- (void)cancelOperation: (id)sender {
    [self.owner toggleStatementDetails];
}

- (IBAction)attachmentClicked: (id)sender {
    AttachmentImageView *image = sender;

    if (image.reference == nil) {
        // No attachment yet. Allow adding one if editing is possible.
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.title = NSLocalizedString(@"AP118", nil);
        panel.canChooseDirectories = NO;
        panel.canChooseFiles = YES;
        panel.allowsMultipleSelection = NO;

        int runResult = [panel runModal];
        if (runResult == NSOKButton) {
            [image processAttachment: panel.URL];
        }
    } else {
        [image openReference];
    }
}

- (IBAction)showTagPopup: (id)sender {
    [tagViewPopup showTagPopupAt: tagView.bounds forView: tagView host: tagViewHost preferredEdge: NSMinYEdge];
}

- (IBAction)stepDate: (id)sender {
    if ([sender intValue] > 0) {
        [dateSlider showPrevious];
    } else {
        [dateSlider showNext];
    }
    [sender setIntValue: 0];
}

#pragma mark - KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context {
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            [self updateValueColors];
            return;
        }

        if ([keyPath isEqualToString: @"autoCasing"]) {
            [self updateCaseDependentTextInDetails: self.sepaDetails];
            [purposeTitle display];
            return;
        }

        return;
    }

    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

#pragma mark - delegates

- (BOOL)textView: (NSTextView *)textView shouldChangeTextInRange: (NSRange)affectedCharRange replacementString: (NSString *)replacementString {
    return NO;
}

@end
