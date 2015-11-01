/**
 * Copyright (c) 2012, 2015 Pecunia Project. All rights reserved.
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
#import "StandingOrder.h"
#import "BankingCategory.h"
#import "BankAccount.h"

#import "NSColor+PecuniaAdditions.h"
#import "ValueTransformers.h"

extern void *UserDefaultsBindingContext;

extern NSString *const CategoryColorNotification;
extern NSString *const CategoryKey;

extern NSDateFormatter *dateFormatter; // From PecuniaListViewCell.
extern NSDictionary    *whiteAttributes;

@interface OrdersListViewCell ()
{
    IBOutlet NSTextField *nextDateLabel;
    IBOutlet NSTextField *lastDateLabel;
    IBOutlet NSTextField *bankNameLabel;
    IBOutlet NSTextField *remoteNameLabel;
    IBOutlet NSTextField *purposeLabel;
    IBOutlet NSTextField *valueLabel;
    IBOutlet NSTextField *currencyLabel;
    IBOutlet NSTextField *lastDateTitle;
    IBOutlet NSTextField *nextDateTitle;
    IBOutlet NSImageView *editImage;
    IBOutlet NSImageView *sendImage;
    IBOutlet NSButton    *deleteButton;

    IBOutlet NSTextField *ibanCaption;
    IBOutlet NSTextField *ibanLabel;
    IBOutlet NSTextField *bicCaption;
    IBOutlet NSTextField *bicLabel;

    NSColor   *categoryColor;
}

@end

@implementation OrdersListViewCell

#pragma mark - Init/Dealloc

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self != nil) {
        [NSNotificationCenter.defaultCenter addObserverForName: CategoryColorNotification
                                                        object: nil
                                                         queue: nil
                                                    usingBlock:
         ^(NSNotification *notification) {
             BankingCategory *category = (notification.userInfo)[CategoryKey];
             BankAccount *account = [self.representedObject account];
             if (category == (id)account) { // Weird warning without cast.
                 categoryColor = category.categoryColor;
                 [self setNeedsDisplay: YES];
             }
         }
        ];

        // In addition listen to certain preference changes.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"autoCasing" options: 0 context: UserDefaultsBindingContext];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver: self];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver: self forKeyPath: @"autoCasing"];
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

    [self adjustLabelsAndSize];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context {
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"autoCasing"]) {
            [self updateLabelsWithCasing: [NSUserDefaults.standardUserDefaults boolForKey: @"autoCasing"]];
            return;
        }

    }

    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

- (IBAction)cancelDeletion: (id)sender
{
    StandingOrder *order = self.representedObject;
    order.toDelete = @NO;
    deleteButton.hidden = YES;
}

- (void)setRepresentedObject: (id)object
{
    [super setRepresentedObject: object];

    StandingOrder *order = object;

    [self updateLabelsWithCasing: [NSUserDefaults.standardUserDefaults boolForKey: @"autoCasing"]];

    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    nextDateLabel.stringValue = [dateFormatter stringFromDate: order.firstExecDate];

    static NSDate *farAway = nil;
    if (farAway == nil) {
        farAway = [[NSDate alloc] initWithString: @"1.1.2900"];
    }
    if (order.lastExecDate > farAway) {
        lastDateLabel.stringValue = @"--";
    } else {
        lastDateLabel.stringValue = [dateFormatter stringFromDate: order.lastExecDate];
    }

    valueLabel.objectValue = order.value;

    bankNameLabel.stringValue = [self formatValue: order.remoteBankName capitalize: NO];
    bankNameLabel.toolTip = bankNameLabel.stringValue;

    // By now all standing orders are SEPA orders. No traditional type anymore.
    bicLabel.stringValue = [self formatValue: order.remoteBIC capitalize: NO];
    if (bicLabel.stringValue.length == 0) {
        bicLabel.stringValue = NSLocalizedString(@"AP35", nil);
    }
    bicLabel.toolTip = bicLabel.stringValue;

    ibanLabel.stringValue = [self formatValue: order.remoteIBAN capitalize: NO];
    if (ibanLabel.stringValue.length == 0) {
        ibanLabel.stringValue = NSLocalizedString(@"AP35", nil);
    }
    ibanLabel.toolTip = ibanLabel.stringValue;

    categoryColor = order.account.categoryColor;

    static CurrencyValueTransformer *currencyTransformer;
    if (currencyTransformer == nil) {
        currencyTransformer = [[CurrencyValueTransformer alloc] init];
    }

    NSString *currency = [self formatValue: order.currency capitalize: NO];
    NSString *symbol = [currencyTransformer transformedValue: currency];
    currencyLabel.stringValue = symbol;
    [[[valueLabel cell] formatter] setCurrencyCode: currency]; // Important for proper display of the value, even without currency.

    editImage.hidden = !order.isChanged.boolValue;
    sendImage.hidden = !order.isSent.boolValue;
    deleteButton.hidden = !order.toDelete.boolValue;

    [self adjustLabelsAndSize];
}

- (void)updateLabelsWithCasing: (BOOL)autoCasing {
    StandingOrder *order = self.representedObject;

    id value = [self formatValue: order.remoteName capitalize: autoCasing];
    remoteNameLabel.stringValue = value;
    remoteNameLabel.toolTip = value;

    value = [self formatValue: order.purpose capitalize: autoCasing];
    purposeLabel.stringValue = value;
    purposeLabel.toolTip = value;
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
