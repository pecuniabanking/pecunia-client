/** 
 * Copyright (c) 2012, 2013, Pecunia Project. All rights reserved.
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

#import "PXListView.h"

#import "TransferTemplateListViewCell.h"

#import "GraphicsAdditions.h"
#import "ValueTransformers.h"

extern NSString *StatementDateKey;
extern NSString *StatementTurnoversKey;
extern NSString *StatementRemoteNameKey;
extern NSString *StatementPurposeKey;
extern NSString *StatementCategoriesKey;
extern NSString *StatementValueKey;
extern NSString *StatementSaldoKey;
extern NSString *StatementCurrencyKey;
extern NSString *StatementTransactionTextKey;
extern NSString *StatementIndexKey;
extern NSString *StatementNoteKey;
extern NSString *StatementRemoteBankNameKey;
extern NSString *StatementColorKey;
extern NSString *StatementRemoteAccountKey;
extern NSString *StatementRemoteBankCodeKey;
extern NSString *StatementRemoteIBANKey;
extern NSString *StatementRemoteBICKey;
extern NSString *StatementTypeKey;
extern NSString *TemplateNameKey;

@implementation TransferTemplateListViewCell

+ (id)defaultAnimationForKey: (NSString *)key
{
    return nil;
}

#pragma mark Init/Dealloc

-(id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self != nil)
    {
        whiteAttributes = @{NSForegroundColorAttributeName: [NSColor whiteColor]};
        [self addObserver: self forKeyPath: @"row" options: 0 context: nil];
    }
    return self;
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    [self selectionChanged];
    [self setNeedsDisplay: YES];
}

- (void)setDetails: (NSDictionary *)details
{
    index = [details[StatementIndexKey] intValue];
    type = [details[StatementTypeKey] intValue];
    
    [templateName setStringValue: [details valueForKey: TemplateNameKey]];
    [remoteNameLabel setStringValue: [details valueForKey: StatementRemoteNameKey]];
    [remoteNameLabel setToolTip: [details valueForKey: StatementRemoteNameKey]];

    [purposeLabel setToolTip: [details valueForKey: StatementPurposeKey]];
    
    // For the remote bank code and account number we either use the german bank details or
    // IBAN/BIC, depending on the type.
    // TODO: support for SEPA normal/company single/consolidated debit transfers, standing/terminated debit tansfers.
    if (type == TransferTypeEU || type == TransferTypeSEPA) {
        remoteBankCode = [[details valueForKey: StatementRemoteBICKey] copy];
        remoteAccount = [[details valueForKey: StatementRemoteIBANKey] copy];
    } else {
        remoteBankCode = [[details valueForKey: StatementRemoteBankCodeKey] copy];
        remoteAccount = [[details valueForKey: StatementRemoteAccountKey] copy];
    }
    purpose = [[details valueForKey: StatementPurposeKey] copy];

    [self selectionChanged];
    [self setNeedsDisplay: YES];
}

#pragma mark -
#pragma mark Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];

    [accountLabel setStringValue: @""];
    [remoteNameLabel setStringValue: @""];
    [purposeLabel setStringValue: @""];
}

#pragma mark -
#pragma mark Drawing

- (void)selectionChanged
{
    // The internal row value might not be assigned yet (when the cell is reused), so
    // the normal check for selection fails. We use instead the index we get from the owning
    // listview (which will later be assigned to this cell anyway).
    BOOL isSelected = [self.listView.selectedRows containsIndex: index];
    
    NSColor *paleColor = [NSColor applicationColorForKey: @"Pale Text Color"];
    if (isSelected) {
        [templateName setTextColor: [NSColor whiteColor]];
        [remoteNameLabel setTextColor: [NSColor whiteColor]];
        [purposeLabel setTextColor: [NSColor whiteColor]];
        [accountLabel setTextColor: [NSColor whiteColor]];
    } else {
        [templateName setTextColor: [NSColor controlTextColor]];
        [remoteNameLabel setTextColor: [NSColor controlTextColor]];
        [accountLabel setTextColor: [NSColor controlTextColor]];
        [purposeLabel setTextColor: paleColor];
    }
    
    // The account label is constructed from two values and formatted.
    NSString *accountTitle;
    NSString *bankCodeTitle;
    if (type == TransferTypeEU || type == TransferTypeSEPA) {
        accountTitle = [NSString stringWithFormat: @"%@ ", NSLocalizedString(@"AP409", @"")];
        bankCodeTitle = [NSString stringWithFormat: @"\t%@ ", NSLocalizedString(@"AP410", @"")];
    } else {
        accountTitle = [NSString stringWithFormat: @"%@ ", NSLocalizedString(@"AP401", @"")];
        bankCodeTitle = [NSString stringWithFormat: @"\t%@ ", NSLocalizedString(@"AP400", @"")];
    }
    
    [accountLabel setToolTip: [NSString stringWithFormat: @"%@%@%@%@",
                               accountTitle, remoteAccount, bankCodeTitle, remoteBankCode]];

    // Construct a formatted string for the account label.
    NSMutableAttributedString *accountString = [[NSMutableAttributedString alloc] init];
    NSFont *normalFont = [NSFont fontWithName: @"LucidaGrande" size: 11];
    NSDictionary *normalAttributes = @{NSFontAttributeName: normalFont,
                                      NSForegroundColorAttributeName: isSelected ? [NSColor whiteColor] : paleColor};
    
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *boldFont = [fontManager convertFont: normalFont toHaveTrait: NSBoldFontMask];
    NSDictionary *boldAttributes = @{NSFontAttributeName: boldFont,
                                    NSForegroundColorAttributeName: isSelected ? [NSColor whiteColor] : [NSColor blackColor]};
    
    [accountString appendAttributedString: [[NSAttributedString alloc] initWithString: accountTitle
                                                                            attributes: normalAttributes]
     ];
    [accountString appendAttributedString: [[NSAttributedString alloc] initWithString: remoteAccount
                                                                            attributes: boldAttributes]
     ];
    [accountString appendAttributedString: [[NSAttributedString alloc] initWithString: bankCodeTitle
                                                                            attributes: normalAttributes]
     ];
    [accountString appendAttributedString: [[NSAttributedString alloc] initWithString: remoteBankCode
                                                                            attributes: boldAttributes]
     ];
    
    [accountLabel setAttributedStringValue: accountString];
    
    // The default line height for a multiline label is too large so we convert the given string
    // so it can have paragraph styles. At the same time we need to apply font size and color
    // explicitly as calling [s drawInRect] doesn't otherwise apply the same formatting as automatic drawing would.
    NSMutableAttributedString *purposeString = [[NSMutableAttributedString alloc] initWithString: purpose];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setMaximumLineHeight: 12];
    
    normalFont = [NSFont fontWithName: @"LucidaGrande" size: 10];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle,
                                NSFontAttributeName: normalFont,
                                NSForegroundColorAttributeName: isSelected ? [NSColor whiteColor] : paleColor};
    
    [purposeString addAttributes: attributes range: NSMakeRange(0, [purposeString length])];
    [purposeLabel setAttributedStringValue: purposeString];
}

- (void)refresh
{
    [self setNeedsDisplay: YES];
}

static NSGradient* innerGradient;
static NSGradient* innerGradientSelected;

- (void) setupDrawStructures
{
    innerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithDeviceRed: 240 / 255.0 green: 240 / 255.0 blue: 240 / 255.0 alpha: 1], (CGFloat) 0.2,
                     [NSColor whiteColor], (CGFloat) 0.8,
                     nil];
    innerGradientSelected = [[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor applicationColorForKey: @"Selection Gradient (low)"], (CGFloat) 0,
                             [NSColor applicationColorForKey: @"Selection Gradient (high)"], (CGFloat) 1,
                             nil];
}

#define DENT_SIZE 4

- (void)drawRect: (NSRect)dirtyRect
{
    if (innerGradient == nil)
        [self setupDrawStructures];
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRect: self.bounds];
    if ([self isSelected]) {
        [innerGradientSelected drawInBezierPath: path angle: 90.0];
    } else {
        [innerGradient drawInBezierPath: path angle: 90.0];
    }
    
    [context restoreGraphicsState];
}

@end
