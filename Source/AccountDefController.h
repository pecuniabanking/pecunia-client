/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

#import <Cocoa/Cocoa.h>

@class BankAccount;
@class BWGradientBox;

@interface AccountDefController : NSWindowController {
    IBOutlet NSObjectController *accountController;
    IBOutlet BWGradientBox      *backgroundGradient;
    IBOutlet BWGradientBox      *topGradient;
    IBOutlet NSPopUpButton      *dropDown;
    IBOutlet NSArrayController  *users;
    IBOutlet NSTextField        *bicField;
    IBOutlet NSTextField        *bankCodeField;
    IBOutlet NSTextField        *bankNameField;
    IBOutlet NSTextField        *balanceField;
    IBOutlet NSTextField        *balanceLabel;
    IBOutlet NSPredicateEditor  *predicateEditor;

    IBOutlet NSBox  *boxView;
    IBOutlet NSView *manAccountAddView;
    IBOutlet NSView *accountAddView;

    NSView *currentAddView;

    NSManagedObjectContext *moc;
    BankAccount            *account;
    BankAccount            *newAccount;
    BOOL                   success;
}

- (id)init;
- (BOOL)check;
- (void)setBankCode: (NSString *)code name: (NSString *)name;

- (IBAction)cancel: (id)sender;
- (IBAction)ok: (id)sender;
- (IBAction)dropChanged: (id)sender;
- (IBAction)predicateEditorChanged: (id)sender;

@end
