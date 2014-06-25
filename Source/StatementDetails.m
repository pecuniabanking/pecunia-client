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

#import "StatementDetails.h"
#import "StatementsListView.h"
#import "GraphicsAdditions.h"
#import "AttachmentImageView.h"
#import "StatCatAssignment.h"
#import "Category.h"
#import "TagView.h"
#import "PreferenceController.h"

#import "SEPAMT94xPurposeParser.h"
#import "BankStatement.h"
#import "SepaData.h"
#import "ShortDate.h"

#import "NSView+PecuniaAdditions.h"
#import "NSColor+PecuniaAdditions.h"
#import "NSString+PecuniaAdditions.h"

#import "MOAssistant.h"

extern void     *UserDefaultsBindingContext;
extern NSString *PecuniaWordsLoadedNotification;

@interface DetailsTableView : NSTextView
@end

@implementation DetailsTableView

- (BOOL)canBecomeKeyView {
    return NO;
}

@end

@interface DetailsNotesView : NSTextView
@end

@implementation DetailsNotesView

- (BOOL)canBecomeKeyView {
    return NO; // Only called when the popover shows. So it can be NO all the time.
}

@end

@interface DetailsTagView : TagView
@end

@implementation DetailsTagView

- (BOOL)canBecomeKeyView {
    return NO;
}

@end

@interface StatementDetails () {
    NSDictionary *purposeMapping;
}

@property (weak) IBOutlet NSTextField *valueField;
@property (weak) IBOutlet NSTextField *nassValueField;

@property (weak) IBOutlet AttachmentImageView *attachment1;
@property (weak) IBOutlet AttachmentImageView *attachment2;
@property (weak) IBOutlet AttachmentImageView *attachment3;
@property (weak) IBOutlet AttachmentImageView *attachment4;

@property (weak) IBOutlet NSButton    *tagButton;
@property (weak) IBOutlet NSBox       *colorBox;
@property (weak) IBOutlet NSTextField *currencyField;

@property (strong) IBOutlet NSTextView *notesTextView;
@property (strong) IBOutlet TagView    *tagView;
@property (strong) IBOutlet NSTextView *sepaInfoTextView;

@property (weak) IBOutlet NSImageView *sequenceTypeImage;

@property (strong) IBOutlet TagView         *tagViewPopup;
@property (weak) IBOutlet NSView            *tagViewHost;
@property (weak) IBOutlet NSArrayController *tagsController;
@property (weak) IBOutlet NSArrayController *statementTags;

@property (weak) IBOutlet NSLayoutConstraint *verticalConstraintValueCurrency;

@end

@implementation StatementDetails

@synthesize sepaDetails;

@synthesize valueField;
@synthesize nassValueField;
@synthesize attachment1;
@synthesize attachment2;
@synthesize attachment3;
@synthesize attachment4;
@synthesize tagButton;
@synthesize colorBox;
@synthesize notesTextView;
@synthesize currencyField;

@synthesize sequenceTypeImage;

@synthesize tagViewPopup;
@synthesize tagView;
@synthesize tagsController;
@synthesize statementTags;
@synthesize tagViewHost;
@synthesize sepaInfoTextView;

@synthesize verticalConstraintValueCurrency;

- (void)awakeFromNib {
    [super awakeFromNib];

    sepaInfoTextView.delegate = self;
    [NSNotificationCenter.defaultCenter addObserver: self
                                           selector: @selector(updateDisplayAfterLoading)
                                               name: PecuniaWordsLoadedNotification
                                             object: nil];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];

    purposeMapping = SEPAMT94xPurposeParser.purposeCodeMap;

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"order" ascending: YES];
    [statementTags setSortDescriptors: @[sd]];
    [tagsController setSortDescriptors: @[sd]];
    tagButton.bordered = NO;

    tagsController.managedObjectContext = MOAssistant.assistant.context;
    [tagsController prepareContent];

    tagViewPopup.datasource = tagsController;
    tagViewPopup.defaultFont = [NSFont fontWithName: PreferenceController.popoverFontName size: 11];
    tagViewPopup.canCreateNewTags = YES;

    tagView.datasource = statementTags;
    tagView.defaultFont = [NSFont fontWithName: PreferenceController.popoverFontName size: 11];
    tagView.canCreateNewTags = YES;

    notesTextView.editable = NO;

    [self updateValueColors];
}

- (void)updateDisplayAfterLoading {
    self.representedObject = self.representedObject; // Reassign to update values.
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
                                                              font: [PreferenceController fontNamed: PreferenceController.mainFontName baseSize: 12]
                                                             color: [NSColor colorWithCalibratedRed: 0.582 green: 0.572 blue: 0.544 alpha: 1.000]]];
    [text appendAttributedString: [self createCellStringWithString: [[value description] stringByAppendingString: @"\n"]
                                                             table: table
                                                         alignment: NSLeftTextAlignment
                                                               row: row
                                                            column: 1
                                                              font: [PreferenceController fontNamed: PreferenceController.mainFontNameBold baseSize: 12]
                                                             color: [NSColor colorWithCalibratedRed: 0.497 green: 0.488 blue: 0.461 alpha: 1.000]]];
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

- (void)setRepresentedObject: (id)value {
    [super setRepresentedObject: value];

    colorBox.fillColor = [[value category] categoryColor];

    // Construct certain values out of the available data.
    StatCatAssignment *assignment = value;
    BankStatement     *statement = assignment.statement;

    NSMutableDictionary *details = [NSMutableDictionary new];
    NSString            *detailedPurpose = purposeMapping[statement.sepa.purposeCode]; // Covers unknown codes.
    if (detailedPurpose.length > 0) {
        details[@"PURP"] = detailedPurpose;
    } else {
        NSString *transactionText = statement.transactionText;
        if (transactionText.length > 0) {
            details[@"PURP"] = transactionText.stringWithNaturalText;
        } else {
            if (statement.ccNumberUms != nil) {
                details[@"PURP"] = NSLocalizedString(@"AP131", nil);
            } else {
                details[@"PURP"] = NSLocalizedString(@"AP130", nil);
            }
        }
    }

    if (statement.ccNumberUms != nil) {
        details[@"receiver"] = statement.ccNumberUms;
    } else {
        if (statement.remoteName != nil) {
            details[@"receiver"] = statement.remoteName;
        } else {
            details[@"receiver"] = @"";
        }
    }

    if (statement.sepa.purpose != nil) {
        details[@"description"] = statement.sepa.purpose;
    } else {
        details[@"description"] = statement.purpose == nil ? @"" : statement.purpose;
    }

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

    NSDictionary *normalAttributes = @{
        NSFontAttributeName: [PreferenceController fontNamed: PreferenceController.mainFontName baseSize: 12],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.497 green: 0.488 blue: 0.461 alpha: 1.000]
    };
    NSDictionary *boldAttributes = @{
        NSFontAttributeName: [PreferenceController fontNamed: PreferenceController.mainFontNameBold baseSize: 12],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.497 green: 0.488 blue: 0.461 alpha: 1.000]
    };

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

    [self createSEPAInfoTextInDetails: details forStatement: statement];
    details[@"userInfo"] = [[NSAttributedString alloc] initWithString: assignment.userInfo == nil ? @"": assignment.userInfo
                                                           attributes: normalAttributes];

    [verticalConstraintValueCurrency.animator setConstant: statement.isAssigned.boolValue ? 15 : 39];

    details[@"documentNumber"] = @"";
    
    self.sepaDetails = details; // Triggers KVO.

    // Update sequence type image. We use the SEPA sequence type, if given. Otherwise we try to derive the correct
    // image from the transfer type.
    NSDictionary *sequenceTypeMap = SEPAMT94xPurposeParser.sequenceTypeMap;
    NSString *sequenceType;
    if (statement.sepa.sequenceType.length > 0) {
        sequenceType = statement.sepa.sequenceType;
    } else {
        sequenceType = [SEPAMT94xPurposeParser sequenceTypeFromString: statement.transactionText];
    }

    // Compose sequence type image from background and type image. Background determines future transactions.
    BOOL futureTransaction;
    NSImage *background;
    if ([ShortDate.currentDate compare: [ShortDate dateWithDate: statement.valutaDate]] == NSOrderedAscending) {
        futureTransaction = YES;
        background = [NSImage imageNamed: @"sequence-type-red"];
    } else {
        futureTransaction = NO;
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
    if (futureTransaction) {
        tooltip = [tooltip stringByAppendingString: NSLocalizedString(@"AP1549", nil)];
    }
    sequenceTypeImage.toolTip = tooltip;
    NSImage *overlay = [NSImage imageNamed: sequenceTypeMap[sequenceType][@"image"]];
    [sequenceImage lockFocus];
    [overlay drawAtPoint: NSMakePoint(0, 0) fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1];
    [sequenceImage unlockFocus];
    sequenceTypeImage.image = sequenceImage;

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

#pragma mark - KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context {
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            [self updateValueColors];
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
