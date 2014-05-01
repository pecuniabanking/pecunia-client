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

#import "TransferTemplateListViewCell.h"

#import "Transfer.h"
#import "PreferenceController.h"
#import "ValueTransformers.h"

#import "NSColor+PecuniaAdditions.h"

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

extern void *UserDefaultsBindingContext;

@interface TransferTemplateListViewCell ()
{
    TransferType type;
}
@end

@implementation TransferTemplateListViewCell

#pragma mark - Init/Dealloc

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self != nil) {
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self registerStandardLabel: templateNameLabel];
    [self registerStandardLabel: remoteNameLabel];
    [self registerStandardLabel: ibanLabel];
    [self registerStandardLabel: bicLabel];

    [self registerPaleLabel: bankNameLabel];
    [self registerPaleLabel: purposeLabel];
    [self registerPaleLabel: ibanCaption];
    [self registerPaleLabel: bicCaption];
}

- (void)setDetails: (NSDictionary *)details
{
    [super setDetails: details];

    type = [details[StatementTypeKey] intValue];

    templateNameLabel.stringValue = [details valueForKey: TemplateNameKey];
    templateNameLabel.toolTip = [details valueForKey: TemplateNameKey];

    remoteNameLabel.stringValue = [details valueForKey: StatementRemoteNameKey];
    remoteNameLabel.toolTip = [details valueForKey: StatementRemoteNameKey];

    purposeLabel.stringValue = [details valueForKey: StatementPurposeKey];
    purposeLabel.toolTip = [details valueForKey: StatementPurposeKey];

    bankNameLabel.stringValue = [details valueForKey: StatementRemoteBankNameKey];
    bankNameLabel.toolTip = [details valueForKey: StatementRemoteBankNameKey];

    // For the remote bank code and account number we either use the german bank details or
    // IBAN/BIC, depending on the type.
    // TODO: support for SEPA normal/company single/consolidated debit transfers, standing/terminated debit tansfers.
    if (type == TransferTypeEU || type == TransferTypeSEPA) {
        bicLabel.stringValue = [details valueForKey: StatementRemoteBICKey];
        ibanLabel.stringValue = [details valueForKey: StatementRemoteIBANKey];
    } else {
        bicLabel.stringValue = [details valueForKey: StatementRemoteBankCodeKey];
        ibanLabel.stringValue = [details valueForKey: StatementRemoteAccountKey];
    }
}

- (void)refresh
{
    [self setNeedsDisplay: YES];
}

#define DENT_SIZE 4

- (void)drawRect: (NSRect)dirtyRect
{
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];

    NSRect bounds = self.bounds;
    NSBezierPath *path = [NSBezierPath bezierPathWithRect: bounds];
    if ([self isSelected]) {
        [self.selectionGradient drawInBezierPath: path angle: 90.0];
    }

    // Left, right and bottom lines.
    path = [NSBezierPath new];
    [path moveToPoint: NSMakePoint(0.5, 0)];
    [path lineToPoint: NSMakePoint(0.5, bounds.size.height + 0.5)];
    [path moveToPoint: NSMakePoint(bounds.size.width - 0.5, 0.5)];
    [path lineToPoint: NSMakePoint(bounds.size.width - 0.5, bounds.size.height + 0.5)];
    [path moveToPoint: NSMakePoint(0.5, 0.5)];
    [path lineToPoint: NSMakePoint(bounds.size.width - 0.5, 0.5)];
    [[NSColor colorWithDeviceWhite: 230 / 255.0 alpha: 1] set];
    [path stroke];

    [context restoreGraphicsState];
}

@end
