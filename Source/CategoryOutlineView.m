/**
 * Copyright (c) 2008, 2015, Pecunia Project. All rights reserved.
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

#import "CategoryOutlineView.h"
#import "BankingCategory.h"

#import "BankingController.h"
#import "HBCIController.h"
#import "BankAccount.h"

#import "PreferenceController.h"

extern void *UserDefaultsBindingContext;

@interface CategoryTableCellView : NSTableCellView {
    IBOutlet NSLayoutConstraint *colorWellWidthConstraint;
    IBOutlet NSLayoutConstraint *badgeWidthConstraint;

}
@end

@implementation CategoryTableCellView

- (void)awakeFromNib {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults addObserver: self forKeyPath: @"showCatColorsInTree" options: 0 context: UserDefaultsBindingContext];

    if ([userDefaults boolForKey: @"showCatColorsInTree"]) {
        colorWellWidthConstraint.constant = 13;
    } else {
        colorWellWidthConstraint.constant = 0;
    }
}

- (void)dealloc {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"showCatColorsInTree"];

    [self.objectValue removeObserver: self forKeyPath: @"unreadEntries"];
}

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context {
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"showCatColorsInTree"]) {
            if ([NSUserDefaults.standardUserDefaults boolForKey: @"showCatColorsInTree"]) {
                colorWellWidthConstraint.constant = 13;
            } else {
                colorWellWidthConstraint.constant = 0;
            }
            return;
        }
    }

    if ([keyPath isEqualToString: @"unreadEntries"]) {
        if ([[self.objectValue valueForKey: @"unreadEntries"] intValue] == 0) {
            badgeWidthConstraint.constant = 0;
        } else {
            badgeWidthConstraint.constant = 27;
        }
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

- (void)setObjectValue: (id)objectValue {
    [self.objectValue removeObserver: self forKeyPath: @"unreadEntries"];
    [objectValue addObserver: self forKeyPath: @"unreadEntries" options: 0 context: nil];
    [super setObjectValue: objectValue];

    if ([[self.objectValue valueForKey: @"unreadEntries"] intValue] == 0) {
        badgeWidthConstraint.constant = 0;
    } else {
        badgeWidthConstraint.constant = 27;
    }
}

@end

@implementation CategoryOutlineView

- (NSMenu *)menuForEvent: (NSEvent *)theEvent {
    NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    int     row = [self rowAtPoint: location];
    if (row < 0) {
        return nil;
    }
    [self selectRowIndexes: [NSIndexSet indexSetWithIndex: row] byExtendingSelection: NO];

    NSMenu          *menu = [[NSMenu alloc] initWithTitle: @"Category Context menu"];
    BankingCategory *category = [[self itemAtRow: row] representedObject];

    NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithCapacity: 1];
    titleAttributes[NSFontAttributeName] = [PreferenceController mainFontOfSize: 14 bold: NO];
    titleAttributes[NSForegroundColorAttributeName] = [NSColor colorWithCalibratedRed: 0.177
                                                                                green: 0.413
                                                                                 blue: 0.809
                                                                                alpha: 1.000];
    if (category.isBankAccount) {
        BankAccount *account = (id)category;
        NSMenuItem  *item = [menu addItemWithTitle: @""
                                            action: nil
                                     keyEquivalent: @""];
        item.attributedTitle = [[NSAttributedString alloc] initWithString: category.localName
                                                               attributes: titleAttributes];

        if (category == BankingCategory.bankRoot) {
            item = [menu addItemWithTitle: NSLocalizedString(@"AP228", nil)
                                   action: category.canSynchronize ? @selector(synchronizeAccount:) : nil
                            keyEquivalent: @""];
            item.indentationLevel = 1;

            [menu addItem: NSMenuItem.separatorItem];

            item = [menu addItemWithTitle: NSLocalizedString(@"AP232", nil)
                                   action: @selector(createAccount:)
                            keyEquivalent: @""];
            item.indentationLevel = 1;
        } else {
            BOOL canDelete = NO;
            if ([category.children count] > 0) {
                item = [menu addItemWithTitle: NSLocalizedString(@"AP229", nil)
                                       action: category.canSynchronize ? @selector(synchronizeAccount:) : nil
                                keyEquivalent: @""];
                item.indentationLevel = 1;
            } else {
                canDelete = YES;
                item = [menu addItemWithTitle: NSLocalizedString(@"AP224", nil)
                                       action: category.canSynchronize ? @selector(synchronizeAccount:) : nil
                                keyEquivalent: @""];
                item.indentationLevel = 1;

                [menu addItem: NSMenuItem.separatorItem];
                item = [menu addItemWithTitle: NSLocalizedString(@"AP230", nil)
                                       action: @selector(startTransfer:)
                                keyEquivalent: @""];
                item.indentationLevel = 1;

                // Check if the account supports SEPA transfers or at least internal transfers.
                BOOL flag = [[HBCIController controller] isTransferSupported: TransferTypeSEPA forAccount: account]
                    || [[HBCIController controller] isTransferSupported: TransferTypeInternalSEPA forAccount: account];
                if (!flag) {
                    [item setAction: nil];
                }

                if (account.type.intValue == AccountType_CreditCart) {
                    [menu addItem: NSMenuItem.separatorItem];
                    item = [menu addItemWithTitle: NSLocalizedString(@"AP1210", nil)
                                           action: @selector(getCreditCardSettlements:)
                                    keyEquivalent: @""];
                    item.indentationLevel = 1;
                }

            }

            [menu addItem: NSMenuItem.separatorItem];
            item = [menu addItemWithTitle: NSLocalizedString(@"AP232", nil)
                                   action: @selector(createAccount:)
                            keyEquivalent: @""];
            item.indentationLevel = 1;

            if (canDelete) {
                item = [menu addItemWithTitle: NSLocalizedString(@"AP231", nil)
                                       action: @selector(deleteAccount:)
                                keyEquivalent: @""];
                item.indentationLevel = 1;
            }

            [menu addItem: NSMenuItem.separatorItem];
            item = [menu addItemWithTitle: NSLocalizedString(@"AP227", nil)
                                   action: @selector(editCategory:)
                            keyEquivalent: @""];
            item.indentationLevel = 1;

        }
    } else {
        if (!category.isNotAssignedCategory) {
            NSMenuItem *item = [menu addItemWithTitle: @""
                                               action: nil
                                        keyEquivalent: @""];

            item.attributedTitle = [[NSAttributedString alloc] initWithString: category.localName
                                                                   attributes: titleAttributes];

            item = [menu addItemWithTitle: NSLocalizedString(@"AP225", nil)
                                   action: @selector(createCategory:)
                            keyEquivalent: @""];
            item.indentationLevel = 1;

            if (!category.isCategoryRoot) {
                item = [menu addItemWithTitle: NSLocalizedString(@"AP226", nil)
                                       action: @selector(deleteCategory:)
                                keyEquivalent: @""];
                item.indentationLevel = 1;

                // Show properties. This is the default action (also happens on double click).
                // So, make it bold to indicate this fact.
                [menu addItem: NSMenuItem.separatorItem];
                item = [menu addItemWithTitle: NSLocalizedString(@"AP227", nil)
                                       action: @selector(editCategory:)
                                keyEquivalent: @""];
                item.indentationLevel = 1;
            }
        }
    }

    return menu;
}

- (void)synchronizeAccount: (id)sender {
    id item = [self itemAtRow: self.selectedRow];
    if ([self.delegate respondsToSelector: @selector(synchronizeAccount:)]) {
        [(id)self.delegate synchronizeAccount : [item representedObject]];
    }
}

- (void)editCategory: (id)sender {
    if ([self.delegate respondsToSelector: @selector(showProperties:)]) {
        [(id)self.delegate showProperties : sender];
    }
}

- (void)startTransfer: (id)sender {
    id          item = [self itemAtRow: self.selectedRow];
    BankAccount *account = [item representedObject];
    if ([[HBCIController controller] isTransferSupported: TransferTypeSEPA forAccount: account]) {
        if ([self.delegate respondsToSelector: @selector(startSepaTransfer:)]) {
            [(id)self.delegate startSepaTransfer : sender];
        }
    } else {
        if ([self.delegate respondsToSelector: @selector(startInternalTransfer:)]) {
            [(id)self.delegate startInternalTransfer : sender];
        }
    }
}

- (void)getCreditCardSettlements: (id)sender {
    if ([self.delegate respondsToSelector: @selector(creditCardSettlements:)]) {
        [(id)self.delegate creditCardSettlements : sender];
    }
}

- (void)createAccount: (id)sender {
    if ([self.delegate respondsToSelector: @selector(addAccount:)]) {
        [(id)self.delegate addAccount : sender];
    }
}

- (void)deleteAccount: (id)sender {
    if ([self.delegate respondsToSelector: @selector(deleteAccount:)]) {
        [(id)self.delegate deleteAccount : sender];
    }
}

- (void)createCategory: (id)sender {
    if ([self.delegate respondsToSelector: @selector(insertCategory:)]) {
        [(id)self.delegate insertCategory : sender];
    }
}

- (void)deleteCategory: (id)sender {
    if ([self.delegate respondsToSelector: @selector(deleteCategory:)]) {
        [(id)self.delegate deleteCategory : sender];
    }
}

- (void)editSelectedCell {
    [self editColumn: 0 row: [self selectedRow] withEvent: nil select: YES];
}

- (BOOL)becomeFirstResponder {
    // This is a hack because I cannot find a good way to let the outline tell us when editing finishes.
    return [super becomeFirstResponder];
}

@end
