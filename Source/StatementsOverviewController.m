/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "StatementsOverviewController.h"

#import "BankingController.h"
#import "StatementsListview.h"

#import "MOAssistant.h"
#import "Category.h"
#import "StatCatAssignment.h"
#import "BankStatement.h"
#import "BankStatementPrintView.h"
#import "BankAccount.h"
#import "StatSplitController.h"
#import "PreferenceController.h"
#import "StatementDetails.h"
#import "PecuniaSplitView.h"
#import "AttachmentImageView.h"
#import "ShortDate.h"

#import "NSColor+PecuniaAdditions.h"

#import "Tag.h"
#import "TagView.h"

extern void *UserDefaultsBindingContext;
extern NSString *const CategoryColorNotification;
extern NSString *const CategoryKey;

//----------------------------------------------------------------------------------------------------------------------

@interface OverviewTransfersCellView : NSTableCellView
{
    NSDictionary *whiteAttributes;
    NSColor *categoryColor;
}

@end

@implementation OverviewTransfersCellView

#pragma mark Init/Dealloc

- (void)awakeFromNib
{
    whiteAttributes = @{NSForegroundColorAttributeName: [NSColor whiteColor]};
}

/**
 * Called when the user changes a color. We update here only those colors that are customizable.
 /
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
*/

- (void)applyUnselectedBackgroundToChildrenOf: (NSView *)parent
{
    NSDictionary *positiveAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]};
    NSDictionary *negativeAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]};
    NSColor *paleColor = [NSColor applicationColorForKey: @"Pale Text"];

    for (NSView *child in parent.subviews) {
        if ([child isKindOfClass: NSTextField.class]) {
            // Color depends on wether this is a number with a formatter or on its tag
            // which describes what text type we have.
            NSFormatter *formatter = [[(id)child cell] formatter];
            if ([formatter isKindOfClass: NSNumberFormatter.class]) {
                [(id)formatter setTextAttributesForPositiveValues: positiveAttributes];
                [(id)formatter setTextAttributesForNegativeValues: negativeAttributes];
            }
            switch (child.tag) {
                case 1: // Normal color.
                    [(id)child setTextColor: NSColor.controlTextColor];
                    break;

                case 2: // Pale color.
                    [(id)child setTextColor: paleColor];
                    break;

                default:
                    // Ignore anything else.
                    break;
            }
        }
        [self applyUnselectedBackgroundToChildrenOf: child];
    }

}

- (void)applySelectedBackgroundToChildrenOf: (NSView *)parent
{
    for (NSView *child in parent.subviews) {
        if ([child isKindOfClass: NSTextField.class]) {
            if (child.tag > 0) {
                [(id)child setTextColor: NSColor.whiteColor];

                NSFormatter *formatter = [[(id)child cell] formatter];
                if ([formatter isKindOfClass: NSNumberFormatter.class]) {
                    [(id)formatter setTextAttributesForPositiveValues: whiteAttributes];
                    [(id)formatter setTextAttributesForNegativeValues: whiteAttributes];
                }
            }
        }

        [self applySelectedBackgroundToChildrenOf: child];
    }
    
}

- (void)setBackgroundStyle: (NSBackgroundStyle)backgroundStyle
{
    switch (backgroundStyle) {
        case NSBackgroundStyleLight:
            [self applyUnselectedBackgroundToChildrenOf: self];
            break;

        case NSBackgroundStyleDark:
            [self applySelectedBackgroundToChildrenOf: self];
            break;
    }
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface OverviewTransfersHeaderView : NSTableCellView

@property NSString *dateString;
@property NSString *countString;

@end

@implementation OverviewTransfersHeaderView

+ (void)initialize
{
}

- (void)drawRect:(NSRect)dirtyRect
{
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface OverviewTransfersRowView : NSTableRowView
{
    NSBezierPath *selectionPath;
    NSBezierPath *accessoriePath;

    BOOL    hasUnassignedValue;
    NSColor *categoryColor;
}

@end

@implementation OverviewTransfersRowView

static NSGradient *background;
static NSGradient *innerGradientSelected;
static NSGradient *headerGradient;
static NSGradient *headerGradientFloating;

static NSImage    *stripeImage;

+ (void)initialize
{
    background = [[NSGradient alloc] initWithColorsAndLocations:
                  [NSColor colorWithDeviceRed: 240 / 255.0 green: 240 / 255.0 blue: 240 / 255.0 alpha: 1], 0.2,
                  [NSColor whiteColor], 0.8,
                  nil];
    headerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                      [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 1], 0.0,
                      [NSColor colorWithDeviceWhite: 120 / 255.0 alpha: 1], 1.0,
                      nil];
    headerGradientFloating = [[NSGradient alloc] initWithColorsAndLocations:
                              [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 0.75], 0.0,
                              [NSColor colorWithDeviceWhite: 120 / 255.0 alpha: 0.75], 1.0,
                              nil];
    stripeImage = [NSImage imageNamed: @"slanted_stripes.png"];
    [self updateColors];
}

+ (void)updateColors
{
    innerGradientSelected = [[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor applicationColorForKey: @"Selection Gradient (low)"], 0.0,
                             [NSColor applicationColorForKey: @"Selection Gradient (high)"], 1.0,
                             nil];
}

- (id)initWithFrame: (NSRect)frame assignment: (StatCatAssignment *)assignment
{
    self = [super initWithFrame: frame];
    if (self != nil) {
        hasUnassignedValue = [assignment.statement.nassValue compare: [NSDecimalNumber zero]] != NSOrderedSame;
        categoryColor = assignment.category.categoryColor;

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
/*
        // In addition listen to preference changes.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"markNAStatements" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"markNewStatements" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
        [defaults addObserver: self forKeyPath: @"showBalances" options: 0 context: UserDefaultsBindingContext];
 */
    }

    return self;
}

- (void)dealloc
{
    /*
    [NSNotificationCenter.defaultCenter removeObserver: self];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver: self forKeyPath: @"markNAStatements"];
    [defaults removeObserver: self forKeyPath: @"markNewStatements"];
    [defaults removeObserver: self forKeyPath: @"colors"];
    [defaults removeObserver: self forKeyPath: @"showBalances"];
     */
}

- (void)resizeSubviewsWithOldSize: (NSSize)oldSize
{
    [super resizeSubviewsWithOldSize: oldSize];
    [self updatePaths];
}

- (void)viewDidMoveToSuperview
{
    [self updatePaths];
}

#define DENT_SIZE 4

- (void)updatePaths
{
    selectionPath = [NSBezierPath bezierPath];

    NSRect bounds = self.bounds;
    [selectionPath moveToPoint: NSMakePoint(bounds.origin.x + 7, bounds.origin.y)];
    [selectionPath lineToPoint: NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y)];
    [selectionPath lineToPoint: NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height)];
    [selectionPath lineToPoint: NSMakePoint(bounds.origin.x + 7, bounds.origin.y + bounds.size.height)];

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
        [selectionPath lineToPoint: NSMakePoint(x + DENT_SIZE, y - dentHeight / 2)];
        [selectionPath lineToPoint: NSMakePoint(x, y - dentHeight)];
        y -= dentHeight;

        // Intermediate dents.
        for (i = 1; i < dentCount - 1; i++) {
            [selectionPath lineToPoint: NSMakePoint(x + DENT_SIZE, y - DENT_SIZE / 2)];
            [selectionPath lineToPoint: NSMakePoint(x, y - DENT_SIZE)];
            y -= DENT_SIZE;
        }
        // Last dent.
        dentHeight = DENT_SIZE + remaining;
        [selectionPath lineToPoint: NSMakePoint(x + DENT_SIZE, y - dentHeight / 2)];
        [selectionPath lineToPoint: NSMakePoint(x, y - dentHeight)];
    }

    // Separator lines in front of every text in the main part.
    accessoriePath = [NSBezierPath bezierPath];
    CGFloat left = 0;
    for (NSInteger column = 0; column < self.numberOfColumns - 1; ++column) {
        NSView *cellView = [self viewAtColumn: column];
        left += NSMaxX(cellView.bounds) + 0.5;
        [accessoriePath moveToPoint: NSMakePoint(left, 10)];
        [accessoriePath lineToPoint: NSMakePoint(left, 39)];
    }

    // Left, right and bottom lines.
    [accessoriePath moveToPoint: NSMakePoint(0.5, 0)];
    [accessoriePath lineToPoint: NSMakePoint(0.5, NSMaxY(bounds))];
    [accessoriePath moveToPoint: NSMakePoint(NSMaxX(bounds) - 0.5, NSMaxY(bounds))];
    [accessoriePath lineToPoint: NSMakePoint(NSMaxX(bounds) - 0.5, 0)];
    if (!self.isSelected) {
        [accessoriePath moveToPoint: NSMakePoint(0, NSMaxY(bounds))];
        [accessoriePath lineToPoint: NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];
    }
}

/**
 * Draws non-group rows parts.
 */
- (void)drawInteriorSelected: (BOOL)selected
{
    // Old style gradient drawing for unassigned and new statements.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL drawNotAssignedGradient = [defaults boolForKey: @"markNAStatements"];
    BOOL drawNewStatementsGradient = [defaults boolForKey: @"markNewStatements"];
    BOOL isUnassignedColored = NO;

    NSRect bounds = self.bounds;

    if (selected) {
        [innerGradientSelected drawInBezierPath: selectionPath angle: -90.0];
    } else {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect: bounds];

        if (hasUnassignedValue) {
            NSColor *color = drawNotAssignedGradient ? [NSColor applicationColorForKey: @"Uncategorized Transfer"] : nil;
            if (color) {
                NSGradient *aGradient = [[NSGradient alloc]
                                         initWithColorsAndLocations: color, -0.1, [NSColor whiteColor], 1.1,
                                         nil];

                [aGradient drawInBezierPath: path angle: -90.0];
                isUnassignedColored = YES;
            }
        }

        if (!isUnassignedColored) {
            //[background drawInBezierPath: path angle: -90.0];
        }
    }

    [[NSColor colorWithDeviceWhite: 210 / 255.0 alpha: 1] set];
    [accessoriePath stroke];

    if (categoryColor != nil) {
        [categoryColor set];
        NSRect colorRect = bounds;
        colorRect.size.width = 5;
        [NSBezierPath fillRect: colorRect];
    }

    if (hasUnassignedValue) {
        NSColor *color = drawNotAssignedGradient ? [NSColor applicationColorForKey: @"Uncategorized Transfer"] : nil;
        if (color) {
            isUnassignedColored = YES;
        }
    }

    // Mark the value area if there is an unassigned value remaining.
    if (hasUnassignedValue && !isUnassignedColored && (self.numberOfColumns > 3)) {
        NSRect area = [[self viewAtColumn: 3] frame];
        area.origin.y = 2;
        area.size.height = bounds.size.height - 4;
        area.size.width = stripeImage.size.width;
        CGFloat fraction = self.isSelected ? 0.2 : 1;

        // Tile the image into the area.
        NSRect imageRect = NSMakeRect(0, 0, stripeImage.size.width, stripeImage.size.height);
        while (area.origin.x < bounds.size.width - 4) {
            [stripeImage drawInRect: area
                           fromRect: imageRect
                          operation: NSCompositeSourceOver
                           fraction: fraction
                     respectFlipped: YES
                              hints: nil];
            area.origin.x += stripeImage.size.width;
        }
    }

}

- (void)drawSelectionInRect: (NSRect)dirtyRect
{
    if (!self.isGroupRowStyle) {
        [self drawInteriorSelected: YES];
    }
}

- (void)drawBackgroundInRect: (NSRect)dirtyRect
{
    if (self.isGroupRowStyle) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect: self.bounds];
        if (self.isFloating) {
            [headerGradientFloating drawInBezierPath: path angle: -90.0];
        } else {
            [headerGradient drawInBezierPath: path angle: -90.0];
        }
    } else {
        [self drawInteriorSelected: NO];
    }
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            [self setNeedsDisplay: YES];
            return;
        }

        if ([keyPath isEqualToString: @"showBalances"]) {
            //[self showBalance: [NSUserDefaults.standardUserDefaults boolForKey: @"showBalances"]];
        }

        if ([keyPath isEqualToString: @"markNewStatements"]) {
            NSImageView *newImage = [self viewWithTag: @"isNewImage"];
            if ([NSUserDefaults.standardUserDefaults boolForKey: @"markNewStatements"]) {
                //[newImage setHidden: YES];
            } else {
                //[newImage setHidden: ![self.objectValue isNew]];
            }
        }

        [self setNeedsDisplay: YES];
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface StatementsOverviewController ()
{
    NSDecimalNumber *saveValue;
    NSUInteger      lastSplitterPosition; // Last position of the splitter between list and details.
    NSDateFormatter *dateFormatter;

    // Sorting statements.
    int  sortIndex;
    BOOL sortAscending;
}

@end

@implementation StatementsOverviewController

@synthesize mainView;
@synthesize selectedCategory;
@synthesize toggleDetailsButton;

- (void)dealloc
{
    free(entryMapping);
}

- (void)awakeFromNib
{
    sortAscending = NO;
    sortIndex = 0;

    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterFullStyle;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey: @"mainSortIndex"]) {
        sortIndex = [[userDefaults objectForKey: @"mainSortIndex"] intValue];
        if (sortIndex < 0 || sortIndex >= sortControl.segmentCount) {
            sortIndex = 0;
        }
        sortControl.selectedSegment = sortIndex;
    }

    if ([userDefaults objectForKey: @"mainSortAscending"]) {
        sortAscending = [[userDefaults objectForKey: @"mainSortAscending"] boolValue];
    }
    
    [userDefaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];

    lastSplitterPosition = [[userDefaults objectForKey: @"rightSplitterPosition"] intValue];
    if (lastSplitterPosition > 0) {
        // The details pane was collapsed when Pecunia closed last time.
        [statementDetails setHidden: YES];
        [mainView adjustSubviews];
    }

    mainView.fixedIndex = 1;

    [self updateSorting];
    [self updateValueColors];

    statementsView.floatsGroupRows = YES;

    // Setup statements listview.
    [statementsListView bind: @"dataSource" toObject: categoryAssignments withKeyPath: @"arrangedObjects" options: nil];

    // Bind controller to selectedRow property and the listview to the controller's
    // selectedIndex property to get notified about selection changes.
    [categoryAssignments bind: @"selectionIndexes" toObject: statementsListView withKeyPath: @"selectedRows" options: nil];
    [statementsListView bind: @"selectedRows" toObject: categoryAssignments withKeyPath: @"selectionIndexes" options: nil];

    [statementsListView setCellSpacing: 0];
    [statementsListView setAllowsEmptySelection: YES];
    [statementsListView setAllowsMultipleSelection: YES];

    [categoryAssignments addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: nil];

    NSString * path = [[NSBundle mainBundle] pathForResource: @"icon14-1"
                                                      ofType: @"icns"
                                                 inDirectory: @"Collections/1"];
    if ([NSFileManager.defaultManager fileExistsAtPath: path]) {
        tagButton.image = [[NSImage alloc] initWithContentsOfFile: path];
    }

    [attachment1 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref1" options: nil];
    [attachment2 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref2" options: nil];
    [attachment3 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref3" options: nil];
    [attachment4 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref4" options: nil];

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"order" ascending: YES];
    [statementTags setSortDescriptors: @[sd]];
    [tagsController setSortDescriptors: @[sd]];
    tagButton.bordered = NO;
    
    categoryAssignments.managedObjectContext = MOAssistant.assistant.context;
    tagsController.managedObjectContext = MOAssistant.assistant.context;
    [tagsController prepareContent];

    tagViewPopup.datasource = tagsController;
    tagViewPopup.defaultFont = [NSFont fontWithName: PreferenceController.popoverFontName size: 10];
    tagViewPopup.canCreateNewTags = YES;

    tagsField.datasource = statementTags;
    tagsField.defaultFont = [NSFont fontWithName: PreferenceController.popoverFontName size: 10];
    tagsField.canCreateNewTags = YES;

}

- (IBAction)showTagPopup: (id)sender
{
    NSButton *button = sender;
    [tagViewPopup showTagPopupAt: button.bounds forView: button host: tagViewHost];
}

#pragma mark - Sorting and searching statements

- (IBAction)filterStatements: (id)sender
{
    NSTextField *te = sender;
    NSString    *searchName = [te stringValue];

    if ([searchName length] == 0) {
        [categoryAssignments setFilterPredicate:nil];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithFormat: @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or userInfo contains[c] %@ or value = %@",
                             searchName, searchName, searchName, [NSDecimalNumber decimalNumberWithString: searchName locale: [NSLocale currentLocale]]];
        if (pred != nil) {
            [categoryAssignments setFilterPredicate: pred];
        }
    }
}

- (IBAction)sortingChanged: (id)sender
{
    if ([sender selectedSegment] == sortIndex) {
        sortAscending = !sortAscending;
    } else {
        sortAscending = NO; // Per default entries are sorted by date in decreasing order.
    }

    [self updateSorting];
}

#pragma mark - Other actions

- (IBAction)attachmentClicked: (id)sender
{
    AttachmentImageView *image = sender;

    if (image.reference == nil) {
        // No attachment yet. Allow adding one if editing is possible.
        if (self.canEditAttachment) {
            NSOpenPanel *panel = [NSOpenPanel openPanel];
            panel.title = NSLocalizedString(@"AP118", nil);
            panel.canChooseDirectories = NO;
            panel.canChooseFiles = YES;
            panel.allowsMultipleSelection = NO;

            int runResult = [panel runModal];
            if (runResult == NSOKButton) {
                [image processAttachment: panel.URL];
            }
        }
    } else {
        [image openReference];
    }
}

#pragma mark - General logic

- (BOOL)canEditAttachment
{
    return categoryAssignments.selectedObjects.count == 1;
}

- (void)controlTextDidBeginEditing: (NSNotification *)aNotification
{
    if ([aNotification object] == valueField) {
        NSArray *sel = [categoryAssignments selectedObjects];
        if (sel && [sel count] == 1) {
            StatCatAssignment *stat = sel[0];
            saveValue = stat.value;
        }
    }
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    // Value field changed (todo: replace by key value observation).
    if ([aNotification object] == valueField) {
        NSArray *sel = [categoryAssignments selectedObjects];
        if (sel && [sel count] == 1) {
            StatCatAssignment *stat = sel[0];

            // do some checks
            // amount must have correct sign
            NSDecimal d1 = [stat.statement.value decimalValue];
            NSDecimal d2 = [stat.value decimalValue];
            if (d1._isNegative != d2._isNegative) {
                NSBeep();
                stat.value = saveValue;
                return;
            }

            // amount must not be higher than original amount
            if (d1._isNegative) {
                if ([stat.value compare: stat.statement.value] == NSOrderedAscending) {
                    NSBeep();
                    stat.value = saveValue;
                    return;
                }
            } else {
                if ([stat.value compare: stat.statement.value] == NSOrderedDescending) {
                    NSBeep();
                    stat.value = saveValue;
                    return;
                }
            }

            // [Category updateCatValues] invalidates the selection we got. So re-set it first and then update.
            [categoryAssignments setSelectedObjects: sel];

            [stat.statement updateAssigned];
            [selectedCategory invalidateBalance];
            [Category updateCatValues];
            [statementsListView updateVisibleCells];
        }
    }
}

- (BOOL)validateMenuItem: (NSMenuItem *)item
{
    if ([item action] == @selector(deleteStatement:)) {
        if (!selectedCategory.isBankAccount || categoryAssignments.selectedObjects.count == 0) {
            return NO;
        }
    }
    if ([item action] == @selector(splitStatement:)) {
        if (categoryAssignments.selectedObjects.count != 1) {
            return NO;
        }
    }
    return YES;
}

- (void)updateSorting
{
    [sortControl setImage: nil forSegment: sortIndex];
    sortIndex = [sortControl selectedSegment];
    if (sortIndex < 0) {
        sortIndex = 0;
    }
    NSImage *sortImage = sortAscending ? [NSImage imageNamed: @"sort-indicator-inc"] : [NSImage imageNamed: @"sort-indicator-dec"];
    [sortControl setImage: sortImage forSegment: sortIndex];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue: @((int)sortIndex) forKey: @"mainSortIndex"];
    [userDefaults setValue: @(sortAscending) forKey: @"mainSortAscending"];

    NSString *key;
    switch (sortIndex) {
        case 1:
            statementsListView.canShowHeaders = NO;
            key = @"statement.remoteName";
            break;

        case 2:
            statementsListView.canShowHeaders = NO;
            key = @"statement.purpose";
            break;

        case 3:
            statementsListView.canShowHeaders = NO;
            key = @"statement.categoriesDescription";
            break;

        case 4:
            statementsListView.canShowHeaders = NO;
            key = @"value";
            break;

        default: {
            statementsListView.canShowHeaders = YES;
            key = @"statement.date";
            break;
        }
    }
    [categoryAssignments setSortDescriptors: @[[[NSSortDescriptor alloc] initWithKey: key ascending: sortAscending]]];
    [self updateListMappingForceRecreation: NO];
}

/**
 * Create the mapping array that helps us identify what group rows are and what normal entries in the
 * statement list. Create a new mapping only if none exists yet or force is YES.
 */
- (void)updateListMappingForceRecreation: (BOOL)force
{
    if (mappingCount == 0 || force) {
        free(entryMapping);
        if (sortIndex != 0) {
            // Currently not sorted by date. So just reset the mapping and recreate next time the user
            // switches to sorting by date.
            entryMapping = nil;
            mappingCount = 0;
            return;
        }
        mappingCount = [categoryAssignments.arrangedObjects count];
        NSArray *assignments = categoryAssignments.arrangedObjects;
        NSArray* distinctDates = [assignments valueForKeyPath: @"@distinctUnionOfObjects.dayOfExecution"];
        distinctDates = [distinctDates sortedArrayUsingSelector: @selector(compareReversed:)];
        mappingCount += distinctDates.count;
        entryMapping = malloc(mappingCount * sizeof(NSInteger));

        // Encode the number of entries under a specific date as negative number in the mappings array.
        NSUInteger lastIndex = 0; // The first (top) entry is always a group row.
        NSUInteger countForDate = 0;
        for (NSUInteger mappingIndex = 1, distinctIndex = 0, assignmentIndex = 0; mappingIndex < mappingCount; ++mappingIndex) {
            if (![[assignments[assignmentIndex] dayOfExecution] isEqual: distinctDates[distinctIndex]]) {
                entryMapping[lastIndex] = -countForDate;
                lastIndex = mappingIndex;
                countForDate = 0;
                ++distinctIndex;
            } else {
                entryMapping[mappingIndex] = assignmentIndex++;
                ++countForDate;
            }
        }
        entryMapping[lastIndex] = -countForDate; // Update the last header entry in the list.
    }
    [statementsView reloadData];
}

- (void)deleteSelectedStatements
{
    // Process all selected assignments. If only a single assignment is selected then do an extra round
    // regarding duplication check and confirmation from the user. Otherwise just confirm the delete operation as such.
    NSArray *assignments = [categoryAssignments selectedObjects];
    BOOL    doDuplicateCheck = assignments.count == 1;

    if (!doDuplicateCheck) {
        int result = NSRunAlertPanel(NSLocalizedString(@"AP806", nil),
                                     NSLocalizedString(@"AP809", nil),
                                     NSLocalizedString(@"AP3", nil),
                                     NSLocalizedString(@"AP4", nil),
                                     nil, assignments.count);
        if (result != NSAlertDefaultReturn) {
            return;
        }
    }

    NSManagedObjectContext *context = MOAssistant.assistant.context;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSMutableSet *affectedAccounts = [[NSMutableSet alloc] init];
    for (StatCatAssignment *assignment in assignments) {
        BankStatement *statement = assignment.statement;

        NSError *error = nil;
        BOOL    deleteStatement = NO;

        if (doDuplicateCheck) {
            // Check if this statement is a duplicate. Select all statements with same date.
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date = %@)", statement.account, statement.date];
            [request setPredicate: predicate];

            NSArray *possibleDuplicates = [context executeFetchRequest: request error: &error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }

            BOOL hasDuplicate = NO;
            for (BankStatement *possibleDuplicate in possibleDuplicates) {
                if (possibleDuplicate != statement && [possibleDuplicate matches: statement]) {
                    hasDuplicate = YES;
                    break;
                }
            }
            int res;
            if (hasDuplicate) {
                res = NSRunAlertPanel(NSLocalizedString(@"AP805", nil),
                                      NSLocalizedString(@"AP807", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      nil);
                if (res == NSAlertDefaultReturn) {
                    deleteStatement = YES;
                }
            } else {
                res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP805", nil),
                                              NSLocalizedString(@"AP808", nil),
                                              NSLocalizedString(@"AP4", nil),
                                              NSLocalizedString(@"AP3", nil),
                                              nil);
                if (res == NSAlertAlternateReturn) {
                    deleteStatement = YES;
                }
            }
        } else {
            deleteStatement = YES;
        }

        if (deleteStatement) {
            BOOL isManualAccount = [statement.account.isManual boolValue];
            BankAccount *account = statement.account;
            [affectedAccounts addObject: account]; // Automatically ignores duplicates.

            [context deleteObject: statement];

            // Rebuild balances - only for manual accounts.
            if (isManualAccount) {
                NSPredicate *balancePredicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date > %@)", account, statement.date];
                request.predicate = balancePredicate;
                NSArray *remainingStatements = [context executeFetchRequest: request error: &error];
                if (error != nil) {
                    NSAlert *alert = [NSAlert alertWithError: error];
                    [alert runModal];
                    return;
                }

                for (BankStatement *remainingStatement in remainingStatements) {
                    remainingStatement.saldo = [remainingStatement.saldo decimalNumberBySubtracting: statement.value];
                }
                account.balance = [account.balance decimalNumberBySubtracting: statement.value];
            }
        }
    }

    for (BankAccount *account in affectedAccounts) {
        // Special behaviour for top bank accounts.
        if (account.accountNumber == nil) {
            [context processPendingChanges];
        }
        [account updateBoundAssignments];
    }

    [[Category bankRoot] rollupRecursive: YES];
    [categoryAssignments prepareContent];
}

- (void)splitSelectedStatement
{
    NSArray *sel = [categoryAssignments selectedObjects];
    if (sel != nil && [sel count] == 1) {
        StatSplitController *splitController = [[StatSplitController alloc] initWithStatement: [sel[0] statement]];
        [NSApp runModalForWindow: [splitController window]];
    }
}

/**
 * Shows or hides the statement details pane and returns YES if the pane is now visible, NO otherwise.
 */
- (BOOL)toggleDetailsPane
{
    BOOL result;
    NSView *firstChild = (mainView.subviews)[0];
    if (lastSplitterPosition == 0) {
        [statementDetails setHidden: YES];
        lastSplitterPosition = NSHeight(firstChild.frame);
        [mainView adjustSubviews];
        result = NO;
    } else {
        [statementDetails setHidden: NO];
        NSRect frame = firstChild.frame;
        frame.size.height = lastSplitterPosition;
        firstChild.frame = frame;
        [mainView adjustSubviews];
        lastSplitterPosition = 0;
        result = YES;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue: @((int)lastSplitterPosition) forKey: @"rightSplitterPosition"];

    return result;
}

- (void)reloadList
{
    // Updating the assignments (statements) list kills the current selection, so we preserve it here.
    // Reassigning it after the update has the neat side effect that the details pane is properly updated too.
    NSUInteger selection = categoryAssignments.selectionIndex;
    categoryAssignments.selectionIndex = NSNotFound;
    [statementsListView reloadData];
    [statementsView reloadData];
    categoryAssignments.selectionIndex = selection;
}

- (void)updateValueColors
{
    NSDictionary *positiveAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]};
    NSDictionary *negativeAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]};

    NSNumberFormatter *formatter = [valueField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [valueField setNeedsDisplay];

    formatter = [nassValueField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [nassValueField setNeedsDisplay];
}

#pragma mark - Splitview delegate methods

- (CGFloat)splitView: (NSSplitView *)splitView constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainView) {
        return 240;
    }
    return proposedMin;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainView) {
        return NSHeight([mainView frame]) - 300;
    }
    return proposedMax;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainSplitPosition: (CGFloat)proposedPosition ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainView) {
        // This function is called only when dragging the divider with the mouse. If the details pane is currently collapsed
        // then it is automatically shown when dragging the divider. So we have to reset our interal state.
        if (lastSplitterPosition > 0) {
            lastSplitterPosition = 0;
            [toggleDetailsButton setImage: [NSImage imageNamed: @"hide"]];
        }
    }

    return proposedPosition;
}

#pragma mark - NSTableViewDataSource protocol

- (NSInteger)numberOfRowsInTableView: (NSTableView *)tableView
{
    if (sortIndex == 0) {
        return mappingCount;
    }
    return [categoryAssignments.arrangedObjects count];
}

- (NSView *)tableView: (NSTableView *)tableView
   viewForTableColumn: (NSTableColumn *)tableColumn
                  row: (NSInteger)row
{
    if (sortIndex != 0 || entryMapping[row] > -1) {
        NSString *identifier = [NSString stringWithFormat: @"%@CellView", tableColumn.identifier];
        OverviewTransfersCellView *cell = [tableView makeViewWithIdentifier: identifier owner: tableView];
        cell.objectValue = sortIndex == 0 ? categoryAssignments.arrangedObjects[entryMapping[row]] :
                                            categoryAssignments.arrangedObjects[row];
        return cell;
    } else {
        if (tableColumn == nil) {
            // We arrive here only if sorting is by date and we hit a header row. There's always at least
            // one further entry we can use for certain information.
            OverviewTransfersHeaderView *cell = [tableView makeViewWithIdentifier: @"HeaderCellView" owner: tableView];
            StatCatAssignment *assignment = categoryAssignments.arrangedObjects[entryMapping[row + 1]];

            NSDate *currentDate = assignment.statement.date;
            if (currentDate == nil) {
                currentDate = assignment.statement.valutaDate; // Should not be necessary, but still...
            }
            cell.dateString = [dateFormatter stringFromDate: currentDate];

            NSUInteger turnovers = -entryMapping[row];
            if (turnovers != 1) {
                cell.countString = [NSString stringWithFormat: NSLocalizedString(@"AP207", nil), turnovers];
            } else {
                cell.countString = NSLocalizedString(@"AP206", nil);
            }
            return cell;
        } else {
            return nil;
        }
    }
}

- (NSTableRowView *)tableView: (NSTableView *)tableView rowViewForRow: (NSInteger)row
{
    StatCatAssignment *assignment;
    if (sortIndex != 0 || entryMapping[row] > -1) {
        assignment = sortIndex == 0 ? categoryAssignments.arrangedObjects[entryMapping[row]] :
                                      categoryAssignments.arrangedObjects[row];
    }
    OverviewTransfersRowView *view = [[OverviewTransfersRowView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                                                          assignment: assignment];
    return view;
}

- (CGFloat)tableView: (NSTableView *)tableView heightOfRow: (NSInteger)row
{
    if (sortIndex != 0 || entryMapping[row] > -1) {
        return 49;
    } else {
        return 20;
    }
}

- (BOOL)tableView: (NSTableView *)tableView isGroupRow:( NSInteger)row
{
    if (sortIndex == 0 && entryMapping[row] < 0) {
        return YES;
    }
    return NO;
}

- (BOOL)tableView: (NSTableView *)tableView shouldSelectRow: (NSInteger)row
{
    return (sortIndex != 0 || entryMapping[row] > -1);
}

#pragma mark - KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
         if ([keyPath isEqualToString: @"colors"]) {
            [self updateValueColors];
            return;
        }

        return;
    }

    if (object == categoryAssignments) {
        static NSIndexSet *oldIdx;

        if ([keyPath isEqualToString: @"selectionIndexes"]) {
            // Selection did change.
            // Check if selection really changed
            NSIndexSet *selIdx = categoryAssignments.selectionIndexes;
            if (oldIdx == nil && selIdx == nil) {
                return;
            }
            if (oldIdx != nil && selIdx != nil) {
                if ([oldIdx isEqualTo:selIdx]) {
                    return;
                }
            }
            oldIdx = selIdx;

            // If the currently selected entry is a new one remove the "new" mark.
            NSDecimalNumber *firstValue = nil;
            BankStatementType firstStatementType = StatementType_Standard;
            for (StatCatAssignment *stat in [categoryAssignments selectedObjects]) {
                if (firstValue == nil) {
                    firstValue = stat.statement.value;
                    firstStatementType = stat.statement.type.intValue;
                }
                if ([stat.statement.isNew boolValue]) {
                    stat.statement.isNew = @NO;
                    BankAccount *account = stat.statement.account;
                    account.unread = account.unread - 1;
                    if (account.unread == 0) {
                        [BankingController.controller updateUnread];
                    }
                }
            }
            [(id)BankingController.controller.accountsView setNeedsDisplay: YES];

            // Check for the type of transaction and adjust remote name display accordingly.
            if (firstStatementType == StatementType_CreditCard) {
                [remoteNameLabel setStringValue: NSLocalizedString(@"AP221", nil)];
            } else {
                if ([firstValue compare: [NSDecimalNumber zero]] == NSOrderedAscending) {
                    [remoteNameLabel setStringValue: NSLocalizedString(@"AP208", nil)];
                } else {
                    [remoteNameLabel setStringValue: NSLocalizedString(@"AP209", nil)];
                }
            }

            [statementDetails setNeedsDisplay: YES];
            [BankingController.controller updateStatusbar];
        }
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

#pragma mark - PecuniaSectionItem protocol

- (void)activate
{

}

- (void)deactivate
{

}

- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to
{

}

- (void)print
{
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    NSPrintOperation *printOp;
    NSView           *view = [[BankStatementPrintView alloc] initWithStatements: [categoryAssignments arrangedObjects] printInfo: printInfo];
    printOp = [NSPrintOperation printOperationWithView: view printInfo: printInfo];
    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];
}

- (void)setSelectedCategory: (Category *)newCategory
{
    if (selectedCategory != newCategory) {
        selectedCategory = newCategory;
        categoryAssignments.content = [selectedCategory boundAssignments];

        BOOL editable = NO;
        if (!newCategory.isBankAccount && newCategory != Category.nassRoot && newCategory != Category.catRoot) {
            editable = categoryAssignments.selectedObjects.count == 1;
        }

        // value field
        [valueField setEditable: editable];
        if (editable) {
            [valueField setDrawsBackground: YES];
            [valueField setBackgroundColor: [NSColor whiteColor]];
        } else {
            [valueField setDrawsBackground: NO];
        }

        [self updateListMappingForceRecreation: YES];
    }
}

- (void)terminate
{
    selectedCategory = nil;
    [statementsListView unbind: @"dataSource"];
    [categoryAssignments unbind: @"selectionIndexes"];
    [statementsListView unbind: @"selectedRows"];
    [categoryAssignments removeObserver: self forKeyPath: @"selectionIndexes"];

    [attachment1 unbind: @"reference"];
    [attachment2 unbind: @"reference"];
    [attachment3 unbind: @"reference"];
    [attachment4 unbind: @"reference"];

    tagViewPopup.datasource = nil;
    tagsField.datasource = nil;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"colors"];
    [userDefaults setValue: @((int)lastSplitterPosition) forKey: @"rightSplitterPosition"];
}

@end
