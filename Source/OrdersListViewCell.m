/** 
 * Copyright (c) 2012, 2013 Pecunia Project. All rights reserved.
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

#import "OrdersListViewCell.h"

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

extern NSString *OrderFirstExecDateKey;
extern NSString *OrderLastExecDateKey;
extern NSString *OrderIsChangedKey;
extern NSString *OrderPendingDeletionKey;
extern NSString *OrderIsSentKey;

extern void *UserDefaultsBindingContext;

@interface NoAnimationImageView : NSImageView

@end

@implementation NoAnimationImageView

+ (id)defaultAnimationForKey: (NSString *)key
{
    return nil;
}

@end

@implementation OrdersListViewCell

@synthesize delegate;

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
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
    }
    return self;
}

- (void)dealloc
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"colors"];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            [self updateTextColors];
            [self updateDrawColors];

            BOOL isSelected = [self.listView.selectedRows containsIndex: index];
            if (!isSelected) {
                [self constructAccountAndPurposeText];
            }
            
            [self setNeedsDisplay: YES];
        }
    }
}

- (IBAction)cancelDeletion: (id)sender
{
    if ([self.delegate conformsToProtocol: @protocol(OrdersListViewNotificationProtocol)]) {
        [self.delegate cancelDeletionForIndex: index];
    }
}

static CurrencyValueTransformer* currencyTransformer;

- (void)setDetails: (NSDictionary *)details
{
    index = [details[StatementIndexKey] intValue];
    
    [firstDateLabel setStringValue: [details valueForKey: OrderFirstExecDateKey]];
    [nextDateLabel setStringValue: [details valueForKey: StatementDateKey]];
    [lastDateLabel setStringValue: [details valueForKey: OrderLastExecDateKey]];
    
    [remoteNameLabel setStringValue: [details valueForKey: StatementRemoteNameKey]];
    [remoteNameLabel setToolTip: [details valueForKey: StatementRemoteNameKey]];

    [purposeLabel setToolTip: [details valueForKey: StatementPurposeKey]];
    
    [valueLabel setObjectValue: [details valueForKey: StatementValueKey]];
    
    [bankNameLabel setStringValue: [details valueForKey: StatementRemoteBankNameKey]];
    [bankNameLabel setToolTip: [details valueForKey: StatementRemoteBankNameKey]];
    
    
    remoteBankCode = [[details valueForKey: StatementRemoteBankCodeKey] copy];
    remoteAccount = [[details valueForKey: StatementRemoteAccountKey] copy];
    purpose = [[details valueForKey: StatementPurposeKey] copy];

    id color = [details valueForKey: StatementColorKey];
    categoryColor = (color == [NSNull null] ? nil : color);
    
    if (currencyTransformer == nil)
        currencyTransformer = [[CurrencyValueTransformer alloc] init];
    
    NSString *currency = [details valueForKey: StatementCurrencyKey];
    NSString *symbol = [currencyTransformer transformedValue: currency];
    [currencyLabel setStringValue: symbol];
    [[[valueLabel cell] formatter] setCurrencyCode: currency]; // Important for proper display of the value, even without currency.

    [editImage setHidden: ![[details valueForKey: OrderIsChangedKey] boolValue]];
    [sendImage setHidden: ![[details valueForKey: OrderIsSentKey] boolValue]];
    [deleteButton setHidden: ![[details valueForKey: OrderPendingDeletionKey] boolValue]];
    
    [self selectionChanged];
    [self setNeedsDisplay: YES];
}

#pragma mark -
#pragma mark Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];

    [firstDateLabel setStringValue: @""];
    [accountLabel setStringValue: @""];
    [remoteNameLabel setStringValue: @""];
    [purposeLabel setStringValue: @""];
    [bankNameLabel setStringValue: @""];
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
        [accountLabel setTextColor: [NSColor whiteColor]];
        [bankNameLabel setTextColor: [NSColor whiteColor]];
        [currencyLabel setTextColor: [NSColor whiteColor]];
        [firstDateLabel setTextColor: [NSColor whiteColor]];
        [nextDateLabel setTextColor: [NSColor whiteColor]];
        [lastDateLabel setTextColor: [NSColor whiteColor]];
        [valueTitle setTextColor: [NSColor whiteColor]];
        [firstDateTitle setTextColor: [NSColor whiteColor]];
        [nextDateTitle setTextColor: [NSColor whiteColor]];
        [lastDateTitle setTextColor: [NSColor whiteColor]];
    } else {
        [remoteNameLabel setTextColor: [NSColor controlTextColor]];
        [accountLabel setTextColor: [NSColor controlTextColor]];
        [firstDateLabel setTextColor: [NSColor controlTextColor]];
        [nextDateLabel setTextColor: [NSColor controlTextColor]];
        [lastDateLabel setTextColor: [NSColor controlTextColor]];

        [self updateTextColors];
    }

    [self constructAccountAndPurposeText];
}

/**
 * Called when the user changes a color. We update here only those colors that are customizable.
 */
- (void)updateTextColors
{
    BOOL isSelected = [self.listView.selectedRows containsIndex: index];

    if (!isSelected) {
        NSDictionary *positiveAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]};
        NSDictionary *negativeAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]};

        [[[valueLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
        [[[valueLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];

        NSColor *paleColor = [NSColor applicationColorForKey: @"Pale Text"];
        [bankNameLabel setTextColor: paleColor];
        [purposeLabel setTextColor: paleColor];
        [currencyLabel setTextColor: paleColor];
        [valueTitle setTextColor: paleColor];
        [firstDateTitle setTextColor: paleColor];
        [nextDateTitle setTextColor: paleColor];
        [lastDateTitle setTextColor: paleColor];
    }
}

/**
 * The account label is constructed from several values and includes different formatting.
 */
- (void)constructAccountAndPurposeText
{
    NSColor *paleColor = [NSColor applicationColorForKey: @"Pale Text"];
    BOOL isSelected = [self.listView.selectedRows containsIndex: index];

    // The account label is constructed from two values and formatted.
    NSString *accountTitle;
    NSString *bankCodeTitle;
    accountTitle = [NSString stringWithFormat: @"%@ ", NSLocalizedString(@"AP401", @"")];
    bankCodeTitle = [NSString stringWithFormat: @"\t%@ ", NSLocalizedString(@"AP400", @"")];

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

- (void)updateDrawColors
{
    innerGradientSelected = [[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor applicationColorForKey: @"Selection Gradient (low)"], 0.0,
                             [NSColor applicationColorForKey: @"Selection Gradient (high)"], 1.0,
                             nil];
}

- (void)setupDrawStructures
{
    innerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithDeviceRed: 240 / 255.0 green: 240 / 255.0 blue: 240 / 255.0 alpha: 1], (CGFloat) 0.2,
                     [NSColor whiteColor], (CGFloat) 0.8,
                     nil];
    [self updateDrawColors];
}

#define DENT_SIZE 4

- (void)drawRect:(NSRect)dirtyRect
{
    if (innerGradient == nil)
        [self setupDrawStructures];
    
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
        CGFloat y = bounds.origin.y + bounds.size.height - 0.5;
        CGFloat x = bounds.origin.x + 7.5;
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
            
            [innerGradientSelected drawInBezierPath: path angle: 90.0];
        }
    } else {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect: bounds];
        [innerGradient drawInBezierPath: path angle: 90.0];
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
    CGFloat left = [valueTitle frame].origin.x + 0.5;
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
