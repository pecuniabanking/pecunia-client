/** 
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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
#import "CurrencyValueTransformer.h"

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
        whiteAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSColor whiteColor], NSForegroundColorAttributeName, nil
                            ] retain
                           ];
    }
    return self;
}

- (void)dealloc
{
    [remoteBankCode release];
    [remoteAccount release];
    [positiveAttributes release];
    [negativeAttributes release];
    [whiteAttributes release];
	[super dealloc];
}

static CurrencyValueTransformer* currencyTransformer;

- (void)setDetails: (NSDictionary *)details
{
    index = [[details objectForKey: StatementIndexKey] intValue];
    type = [[details objectForKey: StatementTypeKey] intValue];
    
    [remoteNameLabel setStringValue: [details valueForKey: StatementRemoteNameKey]];
    [remoteNameLabel setToolTip: [details valueForKey: StatementRemoteNameKey]];

    // The default line height for a multiline label is too large so we convert the given string
    // so it can have paragraph styles.
    NSMutableAttributedString *purpose = [[[NSMutableAttributedString alloc] initWithString: [details valueForKey: StatementPurposeKey]] autorelease];
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setMaximumLineHeight: 12];
    [purpose addAttributes: [NSDictionary dictionaryWithObject: paragraphStyle forKey: NSParagraphStyleAttributeName] range: NSMakeRange(0, [purpose length])];
    [purposeLabel setAttributedStringValue: purpose];
    [purposeLabel setToolTip: [details valueForKey: StatementPurposeKey]];
    
    [valueLabel setObjectValue: [details valueForKey: StatementValueKey]];
    
    [remoteBankCode release];
    [remoteAccount release];
    
    // For the remote bank code and account number we either use the german bank details or
    // IBAN/BIC, depending on the type.
    // TODO: support for SEPA normal/company single/consolidated debit transfers, standing/terminated debit tansfers.
    if (type == TransferTypeEU || type == TransferTypeSEPA) {
        remoteBankCode = [[[details valueForKey: StatementRemoteBICKey] copy] retain];
        remoteAccount = [[[details valueForKey: StatementRemoteIBANKey] copy] retain];
    } else {
        remoteBankCode = [[[details valueForKey: StatementRemoteBankCodeKey] copy] retain];
        remoteAccount = [[[details valueForKey: StatementRemoteAccountKey] copy] retain];
    }
    
    if (currencyTransformer == nil)
        currencyTransformer = [[CurrencyValueTransformer alloc] init];
    
    NSString *currency = [details valueForKey: StatementCurrencyKey];
    NSString *symbol = [currencyTransformer transformedValue: currency];
    [currencyLabel setStringValue: symbol];
    [[[valueLabel cell] formatter] setCurrencyCode: currency]; // Important for proper display of the value, even without currency.

    [self selectionChanged];
    [self setNeedsDisplay: YES];
}

- (void)setTextAttributesForPositivNumbers: (NSDictionary*) _positiveAttributes
                           negativeNumbers: (NSDictionary*) _negativeAttributes
{
    if (positiveAttributes != _positiveAttributes) {
        [positiveAttributes release];
        positiveAttributes = [_positiveAttributes retain];
        [[[valueLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
    }
    if (negativeAttributes != _negativeAttributes) {
        [negativeAttributes release];
        negativeAttributes = [_negativeAttributes retain];
        [[[valueLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];
    }
}

#pragma mark -
#pragma mark Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];

    [accountLabel setStringValue: @""];
    [remoteNameLabel setStringValue: @""];
    [purposeLabel setStringValue: @""];
    [valueLabel setObjectValue: @""];
    [currencyLabel setObjectValue: @""];
}

#pragma mark -
#pragma mark Drawing

- (void)selectionChanged
{
    // The internal row value might not be assigned yet (when the cell is reused), so
    // the normal check for selection fails. We use instead the index we get from the owning
    // listview (which will later be assigned to this cell anyway).
    BOOL isSelected = [self.listView.selectedRows containsIndex: index];
    
    if (isSelected) {
        [[[valueLabel cell] formatter] setTextAttributesForPositiveValues: whiteAttributes];
        [[[valueLabel cell] formatter] setTextAttributesForNegativeValues: whiteAttributes];
        
        [remoteNameLabel setTextColor: [NSColor whiteColor]];
        [purposeLabel setTextColor: [NSColor whiteColor]];
        [valueLabel setTextColor: [NSColor whiteColor]]; // Need to set both the label itself as well as its cell formatter.
        [accountLabel setTextColor: [NSColor whiteColor]];
        [currencyLabel setTextColor: [NSColor whiteColor]];
        [valueTitle setTextColor: [NSColor whiteColor]];
    } else {
        [[[valueLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
        [[[valueLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];
        
        [remoteNameLabel setTextColor: [NSColor controlTextColor]];
        [accountLabel setTextColor: [NSColor controlTextColor]];
        [valueLabel setTextColor: [NSColor controlTextColor]];
        
        NSColor *paleColor = [NSColor colorWithDeviceRed: 124 / 255.0 green: 121 / 255.0 blue: 109 / 255.0 alpha: 1];
        [purposeLabel setTextColor: paleColor];
        [currencyLabel setTextColor: paleColor];
        [valueTitle setTextColor: paleColor];
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

    // Construct a formatted string for the accunt label.
    NSMutableAttributedString *accountString = [[[NSMutableAttributedString alloc] init] autorelease];
    NSFont *normalFont = [NSFont fontWithName: @"Helvetica Neue" size: 11];
    NSDictionary *normalAttributes = [NSDictionary dictionaryWithObjectsAndKeys: normalFont, NSFontAttributeName,
                                      isSelected ? [NSColor whiteColor] : [NSColor grayColor], NSForegroundColorAttributeName,
                                      nil];
    
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *boldFont = [fontManager convertFont: normalFont toHaveTrait: NSBoldFontMask];
    NSDictionary *boldAttributes = [NSDictionary dictionaryWithObject: boldFont forKey: NSFontAttributeName];
    
    [accountString appendAttributedString: [[[NSAttributedString alloc] initWithString: accountTitle
                                                                            attributes: normalAttributes]
                                            autorelease]
     ];
    [accountString appendAttributedString: [[[NSAttributedString alloc] initWithString: remoteAccount
                                                                            attributes: boldAttributes]
                                            autorelease]
     ];
    [accountString appendAttributedString: [[[NSAttributedString alloc] initWithString: bankCodeTitle
                                                                            attributes: normalAttributes]
                                            autorelease]
     ];
    [accountString appendAttributedString: [[[NSAttributedString alloc] initWithString: remoteBankCode
                                                                            attributes: boldAttributes]
                                            autorelease]
     ];
    
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setAlignment: NSRightTextAlignment];
    [accountString addAttributes: [NSDictionary dictionaryWithObject: paragraphStyle
                                                              forKey: NSParagraphStyleAttributeName]
                           range: NSMakeRange(0, [accountString length])];
    [accountLabel setAttributedStringValue: accountString];
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
