/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#import <QuartzCore/QuartzCore.h>

#import "PXListView.h"
#import "StatementsListViewCell.h"

#import "NSColor+PecuniaAdditions.h"
#import "ValueTransformers.h"
#import "PreferenceController.h"
#import "Category.h"

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

extern NSString *const CategoryColorNotification;
extern NSString *const CategoryKey;

static void *SetRowBindingContext = (void *)@"SetRowContext";
extern void *UserDefaultsBindingContext;

@implementation StatementsListViewCell

@synthesize delegate;
@synthesize hasUnassignedValue;

+ (id)defaultAnimationForKey: (NSString *)key
{
    // No animations for the cells please. In a class where cells are constantly added and removed
    // this gets annoying quickly otherwise. This does only disable animations for the cell itself
    // not its content.
    return nil;
}

#pragma mark Init/Dealloc

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self != nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale: [NSLocale currentLocale]];
        [dateFormatter setDateStyle: kCFDateFormatterFullStyle];
        [dateFormatter setTimeStyle: NSDateFormatterNoStyle];

        whiteAttributes = @{NSForegroundColorAttributeName: [NSColor whiteColor]};
        [self addObserver: self forKeyPath: @"row" options: 0 context: SetRowBindingContext];
        [NSNotificationCenter.defaultCenter addObserverForName: CategoryColorNotification
                                                        object: nil
                                                         queue: nil
                                                    usingBlock:
         ^(NSNotification *notifictation) {
             Category *category = (notifictation.userInfo)[CategoryKey];
             categoryColor = category.categoryColor;
             [self setNeedsDisplay: YES];
         }

         ];

        // In addition listen to preference changes.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"markNAStatements" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"markNewStatements" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"showBalances" options: 0 context: UserDefaultsBindingContext];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver: self];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver: self forKeyPath: @"markNAStatements"];
    [defaults removeObserver: self forKeyPath: @"markNewStatements"];
    [defaults removeObserver: self forKeyPath: @"colors"];
    [defaults removeObserver: self forKeyPath: @"showBalances"];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == SetRowBindingContext) {
        [self selectionChanged];
        [self setNeedsDisplay: YES];
        return;
    }

    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            [self updateTextColors];
            [self updateDrawColors];
        }

        if ([keyPath isEqualToString: @"showBalances"]) {
            [self showBalance: [NSUserDefaults.standardUserDefaults boolForKey: @"showBalances"]];
        }

        if ([keyPath isEqualToString: @"markNewStatements"]) {
            if ([NSUserDefaults.standardUserDefaults boolForKey: @"markNewStatements"]) {
                [newImage setHidden: YES];
            } else {
                [newImage setHidden: !isNew];
            }
        }

        [self setNeedsDisplay: YES];
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

- (void)setHeaderHeight: (int)aHeaderHeight
{
    headerHeight = aHeaderHeight;
    if (headerHeight > 0) {
        [dateLabel setEnabled: YES];
        [turnoversLabel setEnabled: YES];
    } else {
        [dateLabel setEnabled: NO];
        [turnoversLabel setEnabled: NO];
    }

    [self setNeedsDisplay: YES];
}

static CurrencyValueTransformer *currencyTransformer;

- (void)setDetails: (NSDictionary *)details
{
    index = [details[StatementIndexKey] intValue];

    NSDate *date = details[StatementDateKey];
    dateFormatter.dateStyle = kCFDateFormatterFullStyle;

    [dateLabel setStringValue: [dateFormatter stringFromDate: date]];
    [turnoversLabel setStringValue: details[StatementTurnoversKey]];

    [remoteNameLabel setStringValue: details[StatementRemoteNameKey]];
    [remoteNameLabel setToolTip: details[StatementRemoteNameKey]];

    [purposeLabel setStringValue: details[StatementPurposeKey]];
    [purposeLabel setToolTip: details[StatementPurposeKey]];

    [noteLabel setStringValue: details[StatementNoteKey]];
    [noteLabel setToolTip: details[StatementNoteKey]];

    [categoriesLabel setStringValue: details[StatementCategoriesKey]];
    [categoriesLabel setToolTip: details[StatementCategoriesKey]];

    [valueLabel setObjectValue: details[StatementValueKey]];
    [saldoLabel setObjectValue: details[StatementSaldoKey]];

    [transactionTypeLabel setObjectValue: details[StatementTransactionTextKey]];
    [transactionTypeLabel setToolTip: details[StatementTransactionTextKey]];

    if (currencyTransformer == nil) {
        currencyTransformer = [[CurrencyValueTransformer alloc] init];
    }

    id       currency = details[StatementCurrencyKey];
    NSString *symbol = [currencyTransformer transformedValue: currency];
    [currencyLabel setStringValue: symbol];
    [[[valueLabel cell] formatter] setCurrencyCode: currency]; // Important for proper display of the value, even without currency.
    [saldoCurrencyLabel setStringValue: symbol];
    [[[saldoLabel cell] formatter] setCurrencyCode: currency];

    categoryColor = [details valueForKey: StatementColorKey];

    // Dynamically updated fields.
    dateFormatter.dateFormat = @"d";
    dayLabel.stringValue = [dateFormatter stringFromDate: date];
    dateFormatter.dateFormat = @"MMM";
    monthLabel.stringValue = [dateFormatter stringFromDate: date];
}

#pragma mark Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];

    [dateLabel setStringValue: @""];
    [turnoversLabel setStringValue: @""];
    [remoteNameLabel setStringValue: @""];
    [purposeLabel setStringValue: @""];
    [categoriesLabel setStringValue: @""];
    [valueLabel setObjectValue: @""];
    [saldoLabel setObjectValue: @""];
    [transactionTypeLabel setObjectValue: @""];
    [noteLabel setObjectValue: @""];
    hasUnassignedValue = NO;
    isNew = NO;
    index = -1;
}

#pragma mark -
#pragma mark Properties

- (void)setIsNew: (BOOL)flag
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL newStatementsWithGradient = [defaults boolForKey: @"markNewStatements"];
    if (newStatementsWithGradient) {
        [newImage setHidden: YES];
    } else {
        [newImage setHidden: !flag];
    }
    isNew = flag;
}

- (void)selectionChanged
{
    // The internal row value might not be assigned yet (when the cell is reused), so
    // the normal check for selection fails. We use instead the index we get from the owning
    // listview (which will later be assigned to this cell anyway).
    BOOL isSelected = [self.listView.selectedRows containsIndex: index];

    if (isSelected) {
        [[[valueLabel cell] formatter] setTextAttributesForPositiveValues: whiteAttributes];
        [[[valueLabel cell] formatter] setTextAttributesForNegativeValues: whiteAttributes];
        [[[saldoLabel cell] formatter] setTextAttributesForPositiveValues: whiteAttributes];
        [[[saldoLabel cell] formatter] setTextAttributesForNegativeValues: whiteAttributes];

        [remoteNameLabel setTextColor: [NSColor whiteColor]];
        [purposeLabel setTextColor: [NSColor whiteColor]];
        [categoriesLabel setTextColor: [NSColor whiteColor]];
        [saldoLabel setTextColor: [NSColor whiteColor]];
        [currencyLabel setTextColor: [NSColor whiteColor]];
        [saldoCurrencyLabel setTextColor: [NSColor whiteColor]];

        [transactionTypeLabel setTextColor: [NSColor whiteColor]];
        [noteLabel setTextColor: [NSColor whiteColor]];
        [saldoCaption setTextColor: [NSColor whiteColor]];

        [dayLabel setTextColor: [NSColor whiteColor]];
        [monthLabel setTextColor: [NSColor whiteColor]];
    } else {
        [remoteNameLabel setTextColor: [NSColor controlTextColor]];
        [purposeLabel setTextColor: [NSColor controlTextColor]];
        [categoriesLabel setTextColor: [NSColor controlTextColor]];

        [self updateTextColors];
    }
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
        [[[saldoLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
        [[[saldoLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];

        NSColor *paleColor = [NSColor applicationColorForKey: @"Pale Text"];
        [transactionTypeLabel setTextColor: paleColor];
        [noteLabel setTextColor: paleColor];
        [saldoCaption setTextColor: paleColor];
        [currencyLabel setTextColor: paleColor];
        [saldoCurrencyLabel setTextColor: paleColor];

        [dayLabel setTextColor: paleColor];
        [monthLabel setTextColor: paleColor];
    }
}

- (void)showActivator: (BOOL)flag markActive: (BOOL)active
{
    [checkbox setHidden: !flag];
    [checkbox setState: active ? NSOnState: NSOffState];
}

- (void)showBalance: (BOOL)flag
{
    [saldoCaption setHidden: !flag];
    [saldoLabel setHidden: !flag];
    [saldoCurrencyLabel setHidden: !flag];
}

- (void)refresh
{
    [self setNeedsDisplay: YES];
}

- (IBAction)activationChanged: (id)sender
{
    if ([self.delegate conformsToProtocol: @protocol(StatementsListViewNotificationProtocol)]) {
        [self.delegate cellActivationChanged: ([checkbox state] == NSOnState ? YES : NO) forIndex: index];
    }
}

#pragma mark -
#pragma mark Drawing

static NSGradient *innerGradient;
static NSGradient *innerGradientSelected;
static NSGradient *headerGradient;
static NSImage    *stripeImage;

- (void)updateDrawColors
{
    innerGradientSelected = [[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor applicationColorForKey: @"Selection Gradient (low)"], (CGFloat)0,
                             [NSColor applicationColorForKey: @"Selection Gradient (high)"], (CGFloat)1,
                             nil];
}

- (void)setupDrawStructures
{
    innerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithDeviceRed: 240 / 255.0 green: 240 / 255.0 blue: 240 / 255.0 alpha: 1], (CGFloat)0.2,
                     [NSColor whiteColor], (CGFloat)0.8,
                     nil];
    headerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                      [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 1], (CGFloat)0,
                      [NSColor colorWithDeviceWhite: 120 / 255.0 alpha: 1], (CGFloat)1,
                      nil];
    stripeImage = [NSImage imageNamed: @"slanted_stripes.png"];
    [self updateDrawColors];
}

#define DENT_SIZE 4

- (void)drawRect: (NSRect)dirtyRect
{
    // Old style gradient drawing for unassigned and new statements.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL drawNotAssignedGradient = [defaults boolForKey: @"markNAStatements"];
    BOOL drawNewStatementsGradient = [defaults boolForKey: @"markNewStatements"];
    BOOL isUnassignedColored = NO;

    if (innerGradient == nil) {
        [self setupDrawStructures];
    }

    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];

    NSRect bounds = [self bounds];
    if (headerHeight > 0) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect: NSMakeRect(bounds.origin.x,
                                                                          bounds.size.height - headerHeight,
                                                                          bounds.size.width,
                                                                          headerHeight)];
        [headerGradient drawInBezierPath: path angle: 90.0];
        bounds.size.height -= headerHeight;
    }

    if (self.isSelected) {
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

            [innerGradientSelected drawInBezierPath: path angle: 90.0];
        }

        if (hasUnassignedValue) {
            NSColor *color = drawNotAssignedGradient ? [NSColor applicationColorForKey: @"Uncategorized Transfer"] : nil;
            if (color) {
                isUnassignedColored = YES;
            }
        }
    } else {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect: bounds];

        //[innerGradient drawInBezierPath: path angle: 90.0];
        if (hasUnassignedValue) {
            NSColor *color = drawNotAssignedGradient ? [NSColor applicationColorForKey: @"Uncategorized Transfer"] : nil;
            if (color) {
                NSGradient *aGradient = [[NSGradient alloc]
                                         initWithColorsAndLocations: color, (CGFloat) - 0.1, [NSColor whiteColor], (CGFloat)1.1,
                                         nil];

                [aGradient drawInBezierPath: path angle: 90.0];
                isUnassignedColored = YES;
            }
        }
        if (isNew) {
            NSColor *color = drawNewStatementsGradient ? [NSColor applicationColorForKey: @"Unread Transfer"] : nil;
            if (color) {
                NSGradient *aGradient = [[NSGradient alloc]
                                         initWithColorsAndLocations: color, (CGFloat) - 0.1, [NSColor whiteColor], (CGFloat)1.1,
                                         nil];

                [aGradient drawInBezierPath: path angle: 90.0];
            }
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

    // Separator lines in front of every text in the main part.
    CGFloat left = [remoteNameLabel frame].origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 5, 10)];
    [path lineToPoint: NSMakePoint(left - 5, 39)];
    left = [purposeLabel frame].origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 5, 10)];
    [path lineToPoint: NSMakePoint(left - 5, 39)];
    left = [categoriesLabel frame].origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 5, 10)];
    [path lineToPoint: NSMakePoint(left - 5, 39)];
    left = [valueLabel frame].origin.x + 0.5;
    [path moveToPoint: NSMakePoint(left - 5, 10)];
    [path lineToPoint: NSMakePoint(left - 5, 39)];

    // Left, right and bottom lines.
    [path moveToPoint: NSMakePoint(0, 0)];
    [path lineToPoint: NSMakePoint(0, bounds.size.height + headerHeight)];
    [path moveToPoint: NSMakePoint(bounds.size.width, 0)];
    [path lineToPoint: NSMakePoint(bounds.size.width, bounds.size.height + headerHeight)];
    if (![self isSelected]) {
        [path moveToPoint: NSMakePoint(0, 0)];
        [path lineToPoint: NSMakePoint(bounds.size.width, 0)];
    }
    [[NSColor colorWithDeviceWhite: 210 / 255.0 alpha: 1] set];
    [path stroke];

    // Mark the value area if there is an unassigned value remaining.
    if (hasUnassignedValue && !isUnassignedColored) {
        NSRect area = [categoriesLabel frame];
        area.origin.y = 2;
        area.size.height = bounds.size.height - 4;
        area.size.width = stripeImage.size.width;
        CGFloat fraction = [self isSelected] ? 0.2 : 1;

        // Tile the image into the area.
        NSRect imageRect = NSMakeRect(0, 0, stripeImage.size.width, stripeImage.size.height);
        while (area.origin.x < bounds.size.width - 4) {
            [stripeImage drawInRect: area fromRect: imageRect operation: NSCompositeSourceOver fraction: fraction];
            area.origin.x += stripeImage.size.width;
        }
    }

    [context restoreGraphicsState];
}

@end
