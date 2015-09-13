/**
 * Copyright (c) 2012, 2014 Pecunia Project. All rights reserved.
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

#import "OrdersListViewCell.h"
#import "PreferenceController.h"

#import "NSColor+PecuniaAdditions.h"
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

extern NSString *OrderFirstExecDateKey;
extern NSString *OrderLastExecDateKey;
extern NSString *OrderIsChangedKey;
extern NSString *OrderPendingDeletionKey;
extern NSString *OrderIsSentKey;

extern void *UserDefaultsBindingContext;

@interface OrdersListViewCell ()
{
    NSColor   *categoryColor;
}

@end

@implementation OrdersListViewCell

@synthesize delegate;

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

    [self registerStandardLabel: remoteNameLabel];
    [self registerStandardLabel: ibanLabel];
    [self registerStandardLabel: bicLabel];
    [self registerStandardLabel: nextDateLabel];
    [self registerStandardLabel: lastDateLabel];

    [self registerNumberLabel: valueLabel];

    [self registerPaleLabel: bankNameLabel];
    [self registerPaleLabel: purposeLabel];
    [self registerPaleLabel: currencyLabel];
    [self registerPaleLabel: ibanCaption];
    [self registerPaleLabel: bicCaption];
    [self registerPaleLabel: nextDateTitle];
    [self registerPaleLabel: lastDateTitle];
}

- (IBAction)cancelDeletion: (id)sender
{
    if ([self.delegate conformsToProtocol: @protocol(OrdersListViewNotificationProtocol)]) {
        [self.delegate cancelDeletionForIndex: index];
    }
}

static CurrencyValueTransformer *currencyTransformer;

- (void)setDetails: (NSDictionary *)details
{
    nextDateLabel.stringValue = [details valueForKey: OrderFirstExecDateKey];
    lastDateLabel.stringValue = [details valueForKey: OrderLastExecDateKey];

    remoteNameLabel.stringValue = [details valueForKey: StatementRemoteNameKey];
    remoteNameLabel.toolTip = [details valueForKey: StatementRemoteNameKey];

    valueLabel.objectValue = [details valueForKey: StatementValueKey];

    bankNameLabel.stringValue = [details valueForKey: StatementRemoteBankNameKey];
    bankNameLabel.toolTip = [details valueForKey: StatementRemoteBankNameKey];

    // By now all standing orders are SEPA orders. No traditional type anymore.
    bicLabel.stringValue = [details valueForKey: StatementRemoteBICKey];
    bicLabel.toolTip = [details valueForKey: StatementRemoteBICKey];

    ibanLabel.stringValue = [details valueForKey: StatementRemoteIBANKey];
    ibanLabel.toolTip = [details valueForKey: StatementRemoteIBANKey];

    purposeLabel.stringValue = [details valueForKey: StatementPurposeKey];
    purposeLabel.toolTip = [details valueForKey: StatementPurposeKey];

    id color = [details valueForKey: StatementColorKey];
    categoryColor = (color == [NSNull null] ? nil : color);

    if (currencyTransformer == nil) {
        currencyTransformer = [[CurrencyValueTransformer alloc] init];
    }

    NSString *currency = [details valueForKey: StatementCurrencyKey];
    NSString *symbol = [currencyTransformer transformedValue: currency];
    currencyLabel.stringValue = symbol;
    [[[valueLabel cell] formatter] setCurrencyCode: currency]; // Important for proper display of the value, even without currency.

    [editImage setHidden: ![[details valueForKey: OrderIsChangedKey] boolValue]];
    [sendImage setHidden: ![[details valueForKey: OrderIsSentKey] boolValue]];
    [deleteButton setHidden: ![[details valueForKey: OrderPendingDeletionKey] boolValue]];

    [self adjustLabelsAndSize];
}

#pragma mark - Drawing

- (void)refresh
{
    [self setNeedsDisplay: YES];
}

#define DENT_SIZE 4

- (void)drawRect: (NSRect)dirtyRect
{
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];

    NSRect bounds = [self bounds];
    if ([self isSelected]) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint: NSMakePoint(bounds.origin.x + 7, bounds.origin.y)];
        [path lineToPoint: NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y)];
        [path lineToPoint: NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height)];
        [path lineToPoint: NSMakePoint(bounds.origin.x + 7, bounds.origin.y + bounds.size.height)];

        // Add a number of dents (triangles) to the left side of the path. Since our height might not be a multiple
        // of the dent height we distribute the remaining pixels to the first and last dent.
        CGFloat    y = bounds.origin.y + bounds.size.height - 0.5;
        CGFloat    x = bounds.origin.x + 7.5;
        NSUInteger dentCount = bounds.size.height / DENT_SIZE;
        if (dentCount > 0) {
            NSUInteger remaining = bounds.size.height - DENT_SIZE * dentCount;

            NSUInteger i = 0;
            NSUInteger dentHeight = DENT_SIZE + remaining / 2;
            remaining -= remaining / 2;

            // First dent.
            [path lineToPoint: NSMakePoint(x + DENT_SIZE, y - dentHeight / 2)];
            [path lineToPoint: NSMakePoint(x, y - dentHeight)];
            y -= dentHeight;

            // Intermediate dents.
            for (i = 1; i < dentCount - 1; i++) {
                [path lineToPoint: NSMakePoint(x + DENT_SIZE, y - DENT_SIZE / 2)];
                [path lineToPoint: NSMakePoint(x, y - DENT_SIZE)];
                y -= DENT_SIZE;
            }
            // Last dent.
            dentHeight = DENT_SIZE + remaining;
            [path lineToPoint: NSMakePoint(x + DENT_SIZE, y - dentHeight / 2)];
            [path lineToPoint: NSMakePoint(x, y - dentHeight)];

            [self.selectionGradient drawInBezierPath: path angle: 90.0];
        }
    }

    if (categoryColor != nil) {
        [categoryColor set];
        NSRect colorRect = bounds;
        colorRect.size.width = 5;
        [NSBezierPath fillRect: colorRect];
    }

    [[NSColor colorWithDeviceWhite: 0 / 255.0 alpha: 1] set];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth: 1];

    // Separator line between main text part and the rest.
    CGFloat left = valueLabel.frame.origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 6, 10)];
    [path lineToPoint: NSMakePoint(left - 6, bounds.size.height - 10)];

    // Left, right and bottom lines.
    [path moveToPoint: NSMakePoint(0, 0)];
    [path lineToPoint: NSMakePoint(0, bounds.size.height)];
    [path moveToPoint: NSMakePoint(bounds.size.width, 0)];
    [path lineToPoint: NSMakePoint(bounds.size.width, bounds.size.height)];
    [path moveToPoint: NSMakePoint(0, 0)];
    [path lineToPoint: NSMakePoint(bounds.size.width, 0)];
    [[NSColor colorWithDeviceWhite: 210 / 255.0 alpha: 1] set];
    [path stroke];

    [context restoreGraphicsState];
}

@end
