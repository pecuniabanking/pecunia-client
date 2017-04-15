/**
 * Copyright (c) 2011, 2015, Pecunia Project. All rights reserved.
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

#import "StatementsListViewCell.h"
#import "StatementsListView.h"

#import "NSColor+PecuniaAdditions.h"

#import "ValueTransformers.h"
#import "PreferenceController.h"
#import "BankingCategory.h"
#import "StatCatAssignment.h"

#import "BankStatement.h"
#import "BankAccount.h"

extern NSString *const CategoryColorNotification;
extern NSString *const CategoryKey;

extern void *UserDefaultsBindingContext;

extern NSDateFormatter *dateFormatter;
extern NSDictionary    *whiteAttributes;

@interface StatementsListViewCell ()
{
    @private
    IBOutlet NSTextField *dateLabel;
    IBOutlet NSTextField *turnoversLabel;
    IBOutlet NSTextField *remoteNameLabel;
    IBOutlet NSTextField *purposeLabel;
    IBOutlet NSTextField *noteLabel;
    IBOutlet NSTextField *categoriesLabel;
    IBOutlet NSTextField *valueLabel;
    IBOutlet NSImageView *newImage;
    IBOutlet NSImageView *preliminaryImage;
    IBOutlet NSTextField *currencyLabel;
    IBOutlet NSTextField *saldoLabel;
    IBOutlet NSTextField *saldoCurrencyLabel;
    IBOutlet NSTextField *transactionTypeLabel;
    IBOutlet NSButton    *checkbox;
    IBOutlet NSTextField *dayLabel;
    IBOutlet NSTextField *monthLabel;

    int headerHeight;

    NSColor *categoryColor;
}
@end

@implementation StatementsListViewCell

@synthesize delegate;
@synthesize hasUnassignedValue;
@synthesize isNew;
@synthesize turnovers;

#pragma mark - Init/Dealloc

- (id)initWithFrame: (NSRect)frame {
    self = [super initWithFrame: frame];
    if (self != nil) {
        [NSNotificationCenter.defaultCenter addObserverForName: CategoryColorNotification
                                                        object: nil
                                                         queue: nil
                                                    usingBlock:
         ^(NSNotification *notification) {
            BankingCategory *category = (notification.userInfo)[CategoryKey];
            categoryColor = category.categoryColor;
            [self setNeedsDisplay: YES];
        }

        ];

        // In addition listen to certain preference changes.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"markNAStatements" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"markNewStatements" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"showBalances" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"autoCasing" options: 0 context: UserDefaultsBindingContext];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver: self];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver: self forKeyPath: @"markNAStatements"];
    [defaults removeObserver: self forKeyPath: @"markNewStatements"];
    [defaults removeObserver: self forKeyPath: @"showBalances"];
    [defaults removeObserver: self forKeyPath: @"autoCasing"];

    [self.representedObject removeObserver: self forKeyPath: @"userInfo"];
}

- (void)awakeFromNib {
    [self registerStandardLabel: remoteNameLabel];
    [self registerStandardLabel: purposeLabel];
    [self registerStandardLabel: categoriesLabel];

    [self registerNumberLabel: saldoLabel];
    [self registerNumberLabel: valueLabel];

    [self registerPaleLabel: currencyLabel];
    [self registerPaleLabel: saldoCurrencyLabel];
    [self registerPaleLabel: transactionTypeLabel];
    [self registerPaleLabel: noteLabel];
    [self registerPaleLabel: dayLabel];
    [self registerPaleLabel: monthLabel];

    [self adjustLabelsAndSize];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context {
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"showBalances"]) {
            [self showBalance: [NSUserDefaults.standardUserDefaults boolForKey: @"showBalances"]];

            [self setNeedsDisplay: YES];
            return;
        }

        if ([keyPath isEqualToString: @"markNewStatements"]) {
            if ([NSUserDefaults.standardUserDefaults boolForKey: @"markNewStatements"]) {
                [newImage setHidden: YES];
            } else {
                [newImage setHidden: !isNew];
            }

            [self setNeedsDisplay: YES];
            return;
        }

        if ([keyPath isEqualToString: @"markNAStatements"]) {
            [self setNeedsDisplay: YES];
            return;
        }
        
        if ([keyPath isEqualToString: @"autoCasing"]) {
            [self updateLabelsWithCasing: [NSUserDefaults.standardUserDefaults boolForKey: @"autoCasing"]];
            return;
        }

    }

    if ([keyPath isEqualToString: @"userInfo"]) {
        StatCatAssignment *assignment = self.representedObject;
        id                value = [self formatValue: assignment.userInfo capitalize: NO];
        noteLabel.stringValue = value;
        noteLabel.toolTip = value;

        return;
    }

    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

- (void)setHeaderHeight: (int)aHeaderHeight {
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

- (void)setRepresentedObject: (id)object {
    [self.representedObject removeObserver: self forKeyPath: @"userInfo"];

    [super setRepresentedObject: object];
    [object addObserver: self forKeyPath: @"userInfo" options: 0 context: nil];

    StatCatAssignment *assignment = object;
    NSUserDefaults    *defaults = NSUserDefaults.standardUserDefaults;

    [self updateLabelsWithCasing: [defaults boolForKey: @"autoCasing"]];

    if (assignment.statement == nil) {
        return;
    }

    NSDate *currentDate = assignment.statement.date;
    if (currentDate == nil) {
        currentDate = assignment.statement.valutaDate; // Should not be necessary, but still...
    }

    dateFormatter.dateStyle = kCFDateFormatterFullStyle;
    if (currentDate == nil) {
        dateLabel.stringValue = @"";
    } else {
        dateLabel.stringValue = [dateFormatter stringFromDate: currentDate];
    }

    static CurrencyValueTransformer *currencyTransformer;
    if (currencyTransformer == nil) {
        currencyTransformer = [[CurrencyValueTransformer alloc] init];
    }

    id value = [self formatValue: assignment.statement.categoriesDescription capitalize: NO];
    categoriesLabel.stringValue = value;
    categoriesLabel.toolTip = value;

    value = [self formatValue: assignment.userInfo capitalize: NO];
    noteLabel.stringValue = value;
    noteLabel.toolTip = value;

    valueLabel.objectValue = [self formatValue: assignment.value capitalize: NO];
    saldoLabel.objectValue = [self formatValue: assignment.statement.saldo capitalize: NO];

    value = [self formatValue: assignment.statement.currency capitalize: NO];
    NSString *symbol = [currencyTransformer transformedValue: value];
    currencyLabel.stringValue = symbol;
    [[valueLabel.cell formatter] setCurrencyCode: value]; // Important for proper display of the value, even without currency.
    saldoCurrencyLabel.stringValue = symbol;
    [[saldoLabel.cell formatter] setCurrencyCode: value];

    categoryColor = assignment.category.categoryColor;

    // Dynamically updated fields.
    dateFormatter.dateFormat = @"d";
    dayLabel.stringValue = [dateFormatter stringFromDate: currentDate];
    dateFormatter.dateFormat = @"MMM";
    monthLabel.stringValue = [dateFormatter stringFromDate: currentDate];

    [self showBalance: [defaults boolForKey: @"showBalances"]];
    self.isNew = [assignment.statement.isNew boolValue];
    [self bind: @"isNew" toObject: self.representedObject withKeyPath: @"statement.isNew.boolValue" options: 0];

    NSDecimalNumber *nassValue = assignment.statement.nassValue;
    self.hasUnassignedValue =  [nassValue compare: [NSDecimalNumber zero]] != NSOrderedSame;
    self.blendFactor = assignment.statement.isPreliminary.boolValue ? 0.5 : 1;
    [preliminaryImage setHidden: !assignment.statement.isPreliminary.boolValue];
}

- (void)updateLabelsWithCasing: (BOOL)autoCasing {
    StatCatAssignment *assignment = self.representedObject;

    id value = [self formatValue: assignment.statement.remoteName capitalize: autoCasing];
    remoteNameLabel.stringValue = value;
    remoteNameLabel.toolTip = value;

    value = [self formatValue: assignment.statement.floatingPurpose capitalize: autoCasing];
    purposeLabel.stringValue = value;
    purposeLabel.toolTip = value;

    value =  [self formatValue: assignment.statement.transactionText capitalize: autoCasing];
    transactionTypeLabel.objectValue = value;
    transactionTypeLabel.toolTip = value;
}

#pragma mark - Reuse

- (void)prepareForReuse {
    [super prepareForReuse];

    hasUnassignedValue = NO;
    isNew = NO;
    [self unbind: @"isNew"];
}

#pragma mark - Properties

- (void)setIsNew: (BOOL)flag {
    StatCatAssignment *assignment = self.representedObject;
    if (assignment.statement.isPreliminary.boolValue) {
        [newImage setHidden: YES];
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           newStatementsWithGradient = [defaults boolForKey: @"markNewStatements"];
    if (newStatementsWithGradient) {
        [newImage setHidden: YES];
    } else {
        [newImage setHidden: !flag];
    }
    isNew = flag;
}

- (void)showActivator: (BOOL)flag markActive: (BOOL)active {
    [checkbox setHidden: !flag];
    [checkbox setState: active ? NSOnState: NSOffState];
}

- (void)showBalance: (BOOL)flag {
    StatCatAssignment *assignment = self.representedObject;
    if (!assignment.category.isBankAccount) {
        flag = NO;
    }
    [saldoLabel setHidden: !flag || assignment.statement.isPreliminary.boolValue];
    [saldoCurrencyLabel setHidden: !flag || assignment.statement.isPreliminary.boolValue];
}

- (void)setTurnovers: (NSUInteger)value {
    turnovers = value;
    if (turnovers != 1) {
        turnoversLabel.stringValue = [NSString stringWithFormat: NSLocalizedString(@"AP207", nil), turnovers];
    } else {
        turnoversLabel.stringValue = NSLocalizedString(@"AP206", nil);
    }
}

- (void)rightMouseDown: (NSEvent *)theEvent {
    // Select cell on right click to have a context for the menu, if it isn't already selected.
    if (![[self.listView selectedRows] containsIndex: self.row]) {
        NSIndexSet *clickedIndexSet = [NSIndexSet indexSetWithIndex: self.row];
        [self.listView selectRowIndexes: clickedIndexSet byExtendingSelection: NO];
    }

    [super rightMouseDown: theEvent];
}

- (NSMenu *)menuForEvent: (NSEvent *)theEvent {
    if ([self.delegate conformsToProtocol: @protocol(StatementsListViewNotificationProtocol)]) {
        if (![self.delegate canHandleMenuActions]) {
            return nil;
        }
    }

    StatCatAssignment *assignment = self.representedObject;
    BOOL              isManualAccount = NO;

    if (assignment.category.isBankAccount) {
        isManualAccount = [(BankAccount *)assignment.category isManual].boolValue;
    }

    StatementsListView *listView = (StatementsListView *)self.listView;

    BOOL   singleSelection = listView.selectedRows.count == 1;
    NSMenu *menu = [[NSMenu alloc] initWithTitle: @"Statement List Context menu"];

    NSMenuItem *item;

    if (isManualAccount) {
        item = [menu addItemWithTitle: NSLocalizedString(@"AP238", nil)
                               action: @selector(menuAction:)
                        keyEquivalent: @"n"];
        item.keyEquivalentModifierMask = NSCommandKeyMask;
        item.tag = MenuActionAddStatement;

        [menu addItem: NSMenuItem.separatorItem];
    }
    item = [menu addItemWithTitle: NSLocalizedString(@"AP240", nil)
                           action: @selector(menuAction:)
                    keyEquivalent: @" "];
    item.keyEquivalentModifierMask = 0;
    item.tag = MenuActionShowDetails;

    item = [menu addItemWithTitle: NSLocalizedString(@"AP233", nil)
                           action: singleSelection ? @selector(menuAction:) : nil
                    keyEquivalent: @"s"];
    item.tag = MenuActionSplitStatement;

    item = [menu addItemWithTitle: NSLocalizedString(@"AP234", nil)
                           action: @selector(menuAction:)
                    keyEquivalent: [NSString stringWithFormat: @"%c", NSBackspaceCharacter]];
    item.tag = MenuActionDeleteStatement;

    [menu addItem: NSMenuItem.separatorItem];

    __block BOOL allRead = YES;
    [listView.selectedRows enumerateIndexesUsingBlock: ^(NSUInteger index, BOOL *stop) {
        if ([listView.dataSource[index] statement].isNew.boolValue) {
            allRead = NO;
            *stop = YES;
        }
    }];
    item = [menu addItemWithTitle: allRead ? NSLocalizedString(@"AP235", nil): NSLocalizedString(@"AP239", nil)
                           action: @selector(menuAction:)
                    keyEquivalent: @""];
    item.tag = allRead ? MenuActionMarkUnread : MenuActionMarkRead;

    BankStatement *statement = [self.representedObject statement];
    if (!statement.account.isManual.boolValue) {
        [menu addItem: [NSMenuItem separatorItem]];
        item = [menu addItemWithTitle: NSLocalizedString(@"AP236", nil)
                               action: singleSelection ? @selector(menuAction:) : nil
                        keyEquivalent: @""];
        item.tag = MenuActionStartTransfer;
    }

    item = [menu addItemWithTitle: NSLocalizedString(@"AP237", nil)
                           action: singleSelection ? @selector(menuAction:) : nil
                    keyEquivalent: @""];
    item.tag = MenuActionCreateTemplate;

    return menu;
}

- (void)menuAction: (id)sender {
    if ([self.delegate conformsToProtocol: @protocol(StatementsListViewNotificationProtocol)]) {
        [self.delegate menuActionForCell: self action: [sender tag]];
    }
}

- (IBAction)activationChanged: (id)sender {
    if ([self.delegate conformsToProtocol: @protocol(StatementsListViewNotificationProtocol)]) {
        [self.delegate cellActivationChanged: ([checkbox state] == NSOnState ? YES : NO) forIndex: self.row];
    }
}

- (void)selectionChanged {
    [super selectionChanged];

    newImage.image = [NSImage imageNamed: self.isSelected ? @"new-small-white": @"new-small"];

}

#pragma mark - Drawing

static NSGradient *headerGradient;
static NSImage    *stripeImage;

- (void)setupDrawStructures {
    headerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                      [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 1], (CGFloat)0,
                      [NSColor colorWithDeviceWhite: 120 / 255.0 alpha: 1], (CGFloat)1,
                      nil];
    stripeImage = [NSImage imageNamed: @"slanted_stripes.png"];
}

#define DENT_SIZE 4

- (void)drawRect: (NSRect)dirtyRect {
    // Old style gradient drawing for unassigned and new statements.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL preliminary = [self.representedObject statement].isPreliminary.boolValue;
    BOOL drawNotAssignedGradient = !preliminary && [defaults boolForKey: @"markNAStatements"];
    BOOL drawNewStatementsGradient = !preliminary && [defaults boolForKey: @"markNewStatements"];
    BOOL isUnassignedColored = NO;
    
    // check if assigned or not on redraw
    StatCatAssignment *assignment = self.representedObject;
    NSDecimalNumber *nassValue = assignment.statement.nassValue;
    self.hasUnassignedValue =  [nassValue compare: [NSDecimalNumber zero]] != NSOrderedSame;

    if (headerGradient == nil) {
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

    CGFloat alpha = 1;
    if (preliminary) {
        alpha = 0.5;
        if (!self.isSelected) {
            [[NSColor colorWithCalibratedWhite: 0.95 alpha: alpha] set];
            NSRectFill(bounds);
        }
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

            if (preliminary) {
                [self.selectionPaleGradient drawInBezierPath: path angle: 90.0];
            } else {
                [self.selectionGradient drawInBezierPath: path angle: 90.0];
            }
        }

        if (hasUnassignedValue) {
            NSColor *color = drawNotAssignedGradient ? [NSColor applicationColorForKey: @"Uncategorized Transfer"] : nil;
            if (color) {
                isUnassignedColored = YES;
            }
        }
    } else {
        if (!preliminary) {
            NSBezierPath *path = [NSBezierPath bezierPathWithRect: bounds];

            if (hasUnassignedValue) {
                NSColor *color = drawNotAssignedGradient ? [NSColor applicationColorForKey: @"Uncategorized Transfer"] : nil;
                if (color) {
                    NSGradient *aGradient = [[NSGradient alloc]
                                             initWithColorsAndLocations: color, (CGFloat) - 0.1, NSColor.whiteColor, (CGFloat)1.1,
                                             nil];

                    [aGradient drawInBezierPath: path angle: 90.0];
                    isUnassignedColored = YES;
                }
            }
            if (isNew) {
                NSColor *color = drawNewStatementsGradient ? [NSColor applicationColorForKey: @"Unread Transfer"] : nil;
                if (color) {
                    NSGradient *aGradient = [[NSGradient alloc]
                                             initWithColorsAndLocations: color, (CGFloat) - 0.1, NSColor.whiteColor, (CGFloat)1.1,
                                             nil];
                    
                    [aGradient drawInBezierPath: path angle: 90.0];
                }
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
    if (hasUnassignedValue && !isUnassignedColored && !preliminary) {
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
