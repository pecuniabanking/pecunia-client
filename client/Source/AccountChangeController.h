/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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
@class BusinessTransactionsController;
@class BWGradientBox;

@interface AccountChangeController : NSWindowController {
    IBOutlet NSObjectController		*accountController;
    IBOutlet NSPopUpButton			*dropDown;
	IBOutlet NSTextField			*bicField;
	IBOutlet NSTextField			*bankCodeField;
	IBOutlet NSTextField			*bankNameField;
	IBOutlet NSButton				*collTransferCheck;
	IBOutlet NSButton				*stordCheck;
	IBOutlet NSPredicateEditor		*predicateEditor;
	
	IBOutlet NSBox					*boxView;
	IBOutlet NSView					*manAccountAddView;
	IBOutlet NSView					*accountAddView;
    IBOutlet BWGradientBox          *topGradient;
    IBOutlet BWGradientBox          *backgroundGradient;

    @private
	NSManagedObjectContext			*moc;
	BankAccount						*account;
	BankAccount						*changedAccount;
	
    BusinessTransactionsController* transactionsController;
    NSWindow* supportedTransactionsSheet;
}

- (id)initWithAccount: (BankAccount*)acc;
- (BOOL)check;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)predicateEditorChanged:(id)sender;
- (IBAction)showSupportedBusinessTransactions: (id)sender;

@end
