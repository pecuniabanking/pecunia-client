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

#import "AccountDefController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "BankUser.h"
#import "BankInfo.h"
#import "HBCIClient.h"
#import "BankingController.h"

#include "BWGradientBox.h"

#define HEIGHT_MANUAL 545
#define HEIGHT_STANDARD 465

@implementation AccountDefController

-(id)init
{
	self = [super initWithWindowNibName:@"AccountCreate"];
	moc = [[MOAssistant assistant ] memContext ];

	account = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:moc ];
	account.currency = @"EUR";
	account.country = @"DE";
	account.name = @"Neues Konto";
    success = NO;
	return self;
}

- (void)setBankCode: (NSString*)code name: (NSString*)name
{
	account.bankCode = code;
	account.bankName = name;
}

-(void)setHeight:(int)h
{
    NSWindow *window = [self window ] ;
    NSRect frame = [window frame ];
    int pos = frame.origin.y + frame.size.height;
    frame.size.height = h;
    frame.origin.y = pos - h;
    [window setFrame:frame display:YES animate:YES ];
}

-(void)awakeFromNib
{
	[[self window ] center ];
	
	int i=0;
	NSMutableArray* hbciUsers = [NSMutableArray arrayWithArray: [BankUser allUsers ] ];
	// add special User
	BankUser *noUser  = [NSEntityDescription insertNewObjectForEntityForName:@"BankUser" inManagedObjectContext:moc ];
	noUser.name = NSLocalizedString(@"AP101", @"");
	[hbciUsers insertObject:noUser atIndex:0 ];
	
	[users setContent: hbciUsers ];
	// now find first user that fits bank code and change selection
	if(account.bankCode) {
		for(BankUser *user in hbciUsers) {
			if([user.bankCode isEqual: account.bankCode ]) {
				[dropDown selectItemAtIndex:i ];
				break;
			}
			i++;
		}
	}
	currentAddView = accountAddView;
	[predicateEditor addRow:self ];
	
	// fill proposal values
	[self dropChanged: self];
    [self setHeight: HEIGHT_STANDARD];

    // Manually set up properties which cannot be set via user defined runtime attributes
    // (Color type is not available pre 10.7).
    topGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    topGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];
    backgroundGradient.fillColor = [NSColor whiteColor];
}

-(IBAction)dropChanged: (id)sender
{
	int idx = [dropDown indexOfSelectedItem ];
	if(idx < 0) idx = 0;
	BankUser *user = [[users arrangedObjects ] objectAtIndex: idx];

	if(idx > 0) {
		account.bankName = user.bankName;
		account.bankCode = user.bankCode;
		BankInfo *info = [[HBCIClient hbciClient ] infoForBankCode: user.bankCode inCountry:account.country ];
		if (info) {
			account.bic = info.bic;
			account.bankName = info.name;
		}

		[bankCodeField setEditable: NO ];
		//[bankCodeField setBezeled: NO ];
		
		if (currentAddView != accountAddView) {
            [self setHeight: HEIGHT_STANDARD];
            NSRect frame = [manAccountAddView frame];
			[boxView replaceSubview:manAccountAddView with:accountAddView ];
			currentAddView = accountAddView;
            [currentAddView setFrame:frame];
		}
	} else {
		[bankCodeField setEditable: YES ];
		//[bankCodeField setBezeled: YES ];

		if (currentAddView != manAccountAddView) {
            [self setHeight: HEIGHT_MANUAL];
            NSRect frame = [accountAddView frame];
			[boxView replaceSubview:accountAddView with:manAccountAddView ];
			currentAddView = manAccountAddView;
            [currentAddView setFrame:frame];
		}
	}
}

- (void)windowWillClose:(NSNotification*)notification
{
    if (success) {
        [NSApp stopModalWithCode: 1];
    } else {
        [NSApp stopModalWithCode: 0];
    }
}

- (IBAction)cancel:(id)sender
{
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }

	[moc reset];
    [self close];
}

- (IBAction)ok: (id)sender
{
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }

	[accountController commitEditing];
	if (![self check]) {
        return;
    }
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];

	BankUser *user = nil;
	int idx = [dropDown indexOfSelectedItem ];
	if(idx > 0) user = [[users arrangedObjects ] objectAtIndex:idx ];

	// account is new - create entity in productive context
	BankAccount *bankRoot = [BankAccount bankRootForCode: account.bankCode ];
	if(bankRoot == nil) {
		Category *root = [Category bankRoot ];
		if(root != nil) {
			// create root for bank
			bankRoot = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:context];
			bankRoot.bankName = account.bankName;
			bankRoot.name = account.bankName;
			bankRoot.bankCode = account.bankCode;
			bankRoot.currency = account.currency;
			bankRoot.country = account.country;
			bankRoot.bic = account.bic;
			bankRoot.isBankAcc = [NSNumber numberWithBool: YES ];
			// parent
			bankRoot.parent = root;
		} else bankRoot = nil;
	}
	// insert account into hierarchy
	if(bankRoot) {
		// account is new - create entity in productive context
		newAccount = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:context ];
		newAccount.bankCode = account.bankCode;
		newAccount.bankName = account.bankName;
		if(user) {
			newAccount.isManual = [NSNumber numberWithBool:NO ];
			newAccount.userId = user.userId;
			newAccount.customerId = user.customerId;
			newAccount.collTransferMethod = account.collTransferMethod;
			newAccount.isStandingOrderSupported = account.isStandingOrderSupported;
		} else {
			newAccount.isManual = [NSNumber numberWithBool:YES ];	
			newAccount.balance = account.balance;
			NSPredicate* predicate = [predicateEditor objectValue];
			if(predicate) newAccount.rule = [predicate description ];
		}
		
		newAccount.parent = bankRoot;
		newAccount.isBankAcc = [NSNumber numberWithBool:YES ];
	}
	
	if(newAccount) {
		// update common data
		newAccount.iban = account.iban;
		newAccount.bic = account.bic;
		newAccount.owner = account.owner;
		newAccount.accountNumber = account.accountNumber; //?
		newAccount.name = account.name;
		newAccount.currency = account.currency;
		newAccount.country = account.country;
        newAccount.catRepColor = account.catRepColor;
	}

    [self close ];

	// save all
	NSError *error=nil;
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	
	if (newAccount.userId) {
		[[HBCIClient hbciClient ] addAccount:newAccount forUser:user ];
	}

	[moc reset ];
    success = YES;
    [self close ];
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextField	*te = [aNotification object ];
	
	if([te tag ] == 100) {
		BOOL wasEditable = [bankNameField isEditable ];
		BankAccount *bankRoot = [BankAccount bankRootForCode:[te stringValue ] ];
		[bankNameField setEditable:NO ];
		[bankNameField setBezeled:NO ];
		if (bankRoot == nil) {
			NSString *name = [[HBCIClient hbciClient  ] bankNameForCode: [te stringValue ] inCountry: account.country ];
			if ([name isEqualToString:NSLocalizedString(@"unknown",@"") ]) {
				[bankNameField setEditable:YES ];
				[bankNameField setBezeled:YES ];
				if (wasEditable == NO) account.bankName = name;
			} else account.bankName = name;
		} else {
			account.bankName = bankRoot.name;
		}
	}
}

- (IBAction)predicateEditorChanged:(id)sender
{	
	//	if(awaking) return;
	// check NSApp currentEvent for the return key
    NSEvent* event = [NSApp currentEvent];
    if ([event type] == NSKeyDown)
	{
		NSString* characters = [event characters];
		if ([characters length] > 0 && [characters characterAtIndex:0] == 0x0D)
		{
			/*			
			 [self calculateCatAssignPredicate ];
			 ruleChanged = YES;
			 */ 
		}
    }
    // if the user deleted the first row, then add it again - no sense leaving the user with no rows
    if ([predicateEditor numberOfRows] == 0)
		[predicateEditor addRow:self];
}

-(BOOL)check
{
	if(account.accountNumber == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
						NSLocalizedString(@"AP9", @"Please enter an account number"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	if(account.bankCode == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP10", @"Please enter a bank code"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	// default currency
	if([account.currency isEqual: @"" ]) account.currency = @"EUR";
	
	
	// check IBAN
	BOOL res;
	HBCIClient *hbciClient = [HBCIClient hbciClient ];
	
	
	if([hbciClient checkIBAN: account.iban ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP26", @"IBAN is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}
	
	// check account number
	res = [hbciClient checkAccount: account.accountNumber forBank: account.bankCode inCountry:account.country ];
	if(res == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP13", @"Account number is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}

	return YES;
}




@end
