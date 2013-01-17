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

#import "AccountMaintenanceController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "BankInfo.h"
#import "HBCIClient.h"
#import "BankingController.h"
#import "PecuniaError.h"

#import "BWGradientBox.h"

#import "BusinessTransactionsController.h"

extern NSString* const CategoryColorNotification;
extern NSString* const CategoryKey;

@implementation AccountMaintenanceController

- (id)initWithAccount: (BankAccount*)acc
{
	self = [super initWithWindowNibName: @"AccountMaintenance"];
	moc = MOAssistant.assistant.memContext;

	account = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount" inManagedObjectContext: moc];
	
	changedAccount = acc;
	account.bankCode = acc.bankCode;
	account.accountNumber = acc.accountNumber;
    account.accountSuffix = acc.accountSuffix;
	account.owner = acc.owner;
	account.bankName = acc.bankName;
	account.name = acc.name;
	account.bic = acc.bic;
	account.iban = acc.iban;
	account.currency = acc.currency;
	account.collTransferMethod = acc.collTransferMethod;
	account.isStandingOrderSupported = acc.isStandingOrderSupported;
    account.noAutomaticQuery = acc.noAutomaticQuery;
	account.userId = acc.userId;
    account.categoryColor = acc.categoryColor;

	return self;
}

- (void)awakeFromNib
{
	if ([changedAccount.isManual boolValue]) {
        manAccountAddView.frame = accountAddView.frame;
		[boxView replaceSubview: accountAddView with: manAccountAddView];

		[predicateEditor addRow:self ];
		NSString* s = changedAccount.rule;
		if(s) {
			NSPredicate* pred = [NSCompoundPredicate predicateWithFormat: s ];
			if([pred class ] != [NSCompoundPredicate class ]) {
				NSCompoundPredicate* comp = [[NSCompoundPredicate alloc ] initWithType: NSOrPredicateType subpredicates: @[pred]];
				pred = comp;
			}
			[predicateEditor setObjectValue: pred ];
		}
        
        // change window size
        int deltaHeight = [manAccountAddView frame ].size.height - [accountAddView frame ].size.height;
        NSRect frame = [[self window] frame];
        frame.size.height += deltaHeight;
        [[self window] setFrame:frame display:YES];
        frame = [manAccountAddView frame];
        frame.origin.y -= deltaHeight;
        [manAccountAddView setFrame:frame];
	} else {
        // no manual account
        // check if collective transfers are available - if not, disable collection transfer method popup
        BOOL collTransferSupported = [[HBCIClient hbciClient ] isTransferSupported:TransferTypeCollectiveCredit forAccount:changedAccount];
        if (collTransferSupported == NO) {
            NSMenuItem *item = [collTransferButton itemAtIndex:0];
            [item setTitle:NSLocalizedString(@"AP428",@"")];
            [collTransferButton setEnabled:NO ];
        }
    }

    // Manually set up properties which cannot be set via user defined runtime attributes
    // (Color type is not available pre 10.7).
    topGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    topGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];
    backgroundGradient.fillColor = [NSColor whiteColor];
}

-(IBAction)cancel:(id)sender 
{
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }
    [self close];
	[moc reset];
	[NSApp stopModalWithCode: 0];
}

-(IBAction)ok:(id)sender
{
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }

	[accountController commitEditing];
	if (![self check]) {
        return;
    }
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	
	// update common data
	changedAccount.iban = account.iban;
	changedAccount.bic = account.bic;
	changedAccount.owner = account.owner;
	changedAccount.name = account.name;
	changedAccount.collTransferMethod = account.collTransferMethod;
	changedAccount.isStandingOrderSupported = account.isStandingOrderSupported;
    changedAccount.noAutomaticQuery = account.noAutomaticQuery;
    changedAccount.catRepColor = account.catRepColor;
	
	if ([changedAccount.isManual boolValue] == YES) {
		NSPredicate* predicate = [predicateEditor objectValue];
		if(predicate) changedAccount.rule = [predicate description ];
	} else {        
        changedAccount.accountSuffix = account.accountSuffix;
    }

    NSDictionary *info = @{CategoryKey: changedAccount};
    [NSNotificationCenter.defaultCenter postNotificationName: CategoryColorNotification
                                                      object: self
                                                    userInfo: info];
    [self close];

	// save all
	NSError *error=nil;
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	
	if (changedAccount.userId) {
		[[HBCIClient hbciClient ] changeAccount:changedAccount ];
	}

	[moc reset];
	[NSApp stopModalWithCode: 1];
}

- (IBAction)predicateEditorChanged: (id)sender
{
    // If the user deleted the first row, then add it again - no sense leaving the user with no rows.
    if ([predicateEditor numberOfRows] == 0)
		[predicateEditor addRow:self];
}

-(BOOL)check
{	
	// check IBAN
	HBCIClient *hbciClient = [HBCIClient hbciClient ];	
	
	if([hbciClient checkIBAN: account.iban ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP26", @"IBAN is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}
	
    if (![changedAccount.accountSuffix isEqualToString:account.accountSuffix ]) {
        if (changedAccount.accountSuffix != nil || account.accountSuffix != nil) {
            int result = NSRunAlertPanel(NSLocalizedString(@"AP119", @""), 
                                         NSLocalizedString(@"AP179", @""),
                                         NSLocalizedString(@"no", @"No"), 
                                         NSLocalizedString(@"yes", @"Yes"), nil);
            if (result == NSAlertDefaultReturn) {
                account.accountSuffix = changedAccount.accountSuffix;
                return NO;
            }
        }
    }
    
	return YES;
}

- (IBAction)showSupportedBusinessTransactions: (id)sender
{
	NSArray* result = [[HBCIClient hbciClient] getSupportedBusinessTransactions: account];
	if (result != nil) {
        if (supportedTransactionsSheet == nil) {
            transactionsController = [[BusinessTransactionsController alloc] initWithTransactions: result];
            supportedTransactionsSheet = [transactionsController window];
        }
        
        [NSApp beginSheet: supportedTransactionsSheet
           modalForWindow: [self window]
            modalDelegate: nil
           didEndSelector: nil
              contextInfo: nil];
    }
}

@end
