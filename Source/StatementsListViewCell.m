/** 
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#import "GraphicsAdditions.h"
#import "ValueTransformers.h"
#import "PreferenceController.h"
#import "GraphicsAdditions.h"
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

extern NSString* const CategoryColorNotification;
extern NSString* const CategoryKey;

@implementation NoAnimationTextField

+ (id)defaultAnimationForKey: (NSString *)key
{
    return nil;
}

@end

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
    if (self != nil)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale: [NSLocale currentLocale]];
        [dateFormatter setDateStyle: kCFDateFormatterFullStyle];
        [dateFormatter setTimeStyle: NSDateFormatterNoStyle];

        whiteAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSColor whiteColor], NSForegroundColorAttributeName, nil
                           ];
        [self addObserver: self forKeyPath: @"row" options: 0 context: nil];
        [NSNotificationCenter.defaultCenter addObserverForName: CategoryColorNotification
                                                        object: nil
                                                         queue: nil
                                                    usingBlock: ^(NSNotification *notifictation)
           {
               Category *category = [notifictation.userInfo objectForKey: CategoryKey];
               categoryColor = category.categoryColor;
               [self setNeedsDisplay: YES];
           }
         ];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver: self];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    [self selectionChanged];
    [self setNeedsDisplay: YES];
}

- (void)setHeaderHeight: (int) aHeaderHeight
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

static CurrencyValueTransformer* currencyTransformer;

- (void)setDetails: (NSDictionary*) details
{
    index = [[details objectForKey: StatementIndexKey] intValue];

    NSDate *date = [details objectForKey: StatementDateKey];
    dateFormatter.dateStyle = kCFDateFormatterFullStyle;

    [dateLabel setStringValue: [dateFormatter stringFromDate: date]];
    [turnoversLabel setStringValue: [details objectForKey: StatementTurnoversKey]];
    
    [remoteNameLabel setStringValue: [details objectForKey: StatementRemoteNameKey]];
    [remoteNameLabel setToolTip: [details objectForKey: StatementRemoteNameKey]];
    
    [purposeLabel setStringValue: [details objectForKey: StatementPurposeKey]];
    [purposeLabel setToolTip: [details objectForKey: StatementPurposeKey]];
    
    [noteLabel setStringValue: [details objectForKey: StatementNoteKey]];
    [noteLabel setToolTip: [details objectForKey: StatementNoteKey]];
    
    [categoriesLabel setStringValue: [details objectForKey: StatementCategoriesKey]];
    [categoriesLabel setToolTip: [details objectForKey: StatementCategoriesKey]];
    
    [valueLabel setObjectValue: [details objectForKey: StatementValueKey]];
    [saldoLabel setObjectValue: [details objectForKey: StatementSaldoKey]];
    
    [transactionTypeLabel setObjectValue: [details objectForKey: StatementTransactionTextKey]];
    [transactionTypeLabel setToolTip: [details objectForKey: StatementTransactionTextKey]];
    
    if (currencyTransformer == nil)
        currencyTransformer = [[CurrencyValueTransformer alloc] init];
    
    id currency = [details objectForKey: StatementCurrencyKey];
    NSString* symbol = [currencyTransformer transformedValue: currency];
    [currencyLabel setStringValue: symbol];
    [[[valueLabel cell] formatter] setCurrencyCode: currency]; // Important for proper display of the value, even without currency.
    [saldoCurrencyLabel setStringValue: symbol];
    [[[saldoLabel cell] formatter] setCurrencyCode: currency];

    categoryColor = [details valueForKey: StatementColorKey];

    // Dynamically updated fields.
    dateFormatter.dateFormat = @"eee";
    self.weekdayLabel.stringValue = [dateFormatter stringFromDate: date];
    dateFormatter.dateFormat = @"d";
    self.dayLabel.stringValue = [dateFormatter stringFromDate: date];
    dateFormatter.dateFormat = @"MMM";
    self.monthLabel.stringValue = [dateFormatter stringFromDate: date];
}

- (void)setTextAttributesForPositivNumbers: (NSDictionary*) _positiveAttributes
                           negativeNumbers: (NSDictionary*) _negativeAttributes
{
    if (positiveAttributes != _positiveAttributes) {
        positiveAttributes = _positiveAttributes;
        [[[valueLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
        [[[saldoLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
    }
    
    if (negativeAttributes != _negativeAttributes) {
        negativeAttributes = _negativeAttributes;
        [[[valueLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];
        [[[saldoLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];
    }
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
    [newImage setHidden: !flag];
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
        [valueLabel setTextColor: [NSColor whiteColor]]; // Need to set both the label itself as well as its cell formatter.
        [saldoLabel setTextColor: [NSColor whiteColor]];
        [currencyLabel setTextColor: [NSColor whiteColor]];
        [saldoCurrencyLabel setTextColor: [NSColor whiteColor]];

        [transactionTypeLabel setTextColor: [NSColor whiteColor]];
        [noteLabel setTextColor: [NSColor whiteColor]];
        [saldoCaption setTextColor: [NSColor whiteColor]];

        [self.weekdayLabel setTextColor: [NSColor whiteColor]];
        [self.dayLabel setTextColor: [NSColor whiteColor]];
        [self.monthLabel setTextColor: [NSColor whiteColor]];
    } else {
        [[[valueLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
        [[[valueLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];
        [[[saldoLabel cell] formatter] setTextAttributesForPositiveValues: positiveAttributes];
        [[[saldoLabel cell] formatter] setTextAttributesForNegativeValues: negativeAttributes];

        [remoteNameLabel setTextColor: [NSColor controlTextColor]];
        [purposeLabel setTextColor: [NSColor controlTextColor]];
        [categoriesLabel setTextColor: [NSColor controlTextColor]];
        [valueLabel setTextColor: [NSColor controlTextColor]];
        [saldoLabel setTextColor: [NSColor controlTextColor]];
        
        NSColor *paleColor = [NSColor applicationColorForKey: @"Pale Text Color"];
        [transactionTypeLabel setTextColor: paleColor];
        [noteLabel setTextColor: paleColor];
        [saldoCaption setTextColor: paleColor];
        [currencyLabel setTextColor: paleColor];
        [saldoCurrencyLabel setTextColor: paleColor];

        [self.weekdayLabel setTextColor: paleColor];
        [self.dayLabel setTextColor: paleColor];
        [self.monthLabel setTextColor: paleColor];
    }
}

- (void)showActivator: (BOOL)flag markActive: (BOOL)active
{
    [checkbox setHidden: !flag];
    [checkbox setState: active ? NSOnState : NSOffState];
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

static NSGradient* innerGradient;
static NSGradient* innerGradientSelected;
static NSGradient* headerGradient;
static NSImage* stripeImage;

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
    headerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                      [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 1], (CGFloat) 0,
                      [NSColor colorWithDeviceWhite: 120 / 255.0 alpha: 1], (CGFloat) 1,
                      nil];
    stripeImage = [NSImage imageNamed: @"slanted_stripes.png"];
}

#define DENT_SIZE 4

- (void)drawRect:(NSRect)dirtyRect
{
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

        if (hasUnassignedValue) {
            NSColor *color = [PreferenceController notAssignedRowColor];
            if (color) {
                isUnassignedColored = YES;
            }
        }
    } else {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect: bounds];

        [innerGradient drawInBezierPath: path angle: 90.0];
		if (hasUnassignedValue) {
            NSColor *color = [PreferenceController notAssignedRowColor];
            if (color) {
                NSGradient* aGradient = [[NSGradient alloc]
                                          initWithColorsAndLocations:color, (CGFloat)-0.1, [NSColor whiteColor], (CGFloat)1.1,
                                          nil];
                
                [aGradient drawInBezierPath:path angle:90.0];
                isUnassignedColored = YES;
            }
        }
        if (isNew) {
            NSColor *color = [PreferenceController newStatementRowColor];
            if (color) {
                NSGradient* aGradient = [[NSGradient alloc]
                                          initWithColorsAndLocations:color, (CGFloat)-0.1, [NSColor whiteColor], (CGFloat)1.1,
                                          nil];
                
                [aGradient drawInBezierPath:path angle:90.0];
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
    if (hasUnassignedValue && !isUnassignedColored)
    {
        NSRect area = [categoriesLabel frame];
        area.origin.y = 2;
        area.size.height = bounds.size.height - 4;
        area.size.width = stripeImage.size.width;
        CGFloat fraction = [self isSelected] ? 0.2 : 1;
        
        // Tile the image into the area.
        NSRect imageRect = NSMakeRect(0, 0, stripeImage.size.width, stripeImage.size.height);
        while (area.origin.x < bounds.size.width - 4)
        {
            [stripeImage drawInRect: area fromRect: imageRect operation: NSCompositeSourceOver fraction: fraction];
            area.origin.x += stripeImage.size.width;
        }
    }
    
    [context restoreGraphicsState];
}

@end
