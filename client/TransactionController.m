//
//  TransactionController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "TransactionController.h"
#import "Category.h"
#import "Transfer.h"
#import "TransactionLimits.h"
#import "MOAssistant.h"
#import "BankAccount.h"
#import "HBCIClient.h"
#import "Country.h"
#import "TransferTemplate.h"

@implementation TransactionController

-(void)awakeFromNib
{
	// sort descriptor for transactions view
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[countryController setSortDescriptors: sds ];
}

-(void)setManagedObjectContext:(NSManagedObjectContext*)context
{
	[templateController setManagedObjectContext:context ];
	[templateController prepareContent ];
	[transferController setManagedObjectContext:context ];
}

-(void)updateLimits
{
	[limits release ]; limits = nil;
	limits = [[HBCIClient hbciClient ] limitsForType: transferType account: account country: selectedCountry ];
	if(limits) [limits retain ];
}

-(void)templateDoubleClicked: (id)sender
{
	int row = [sender clickedRow ];
	if(row<0) return;
	[self getDataFromTemplate: sender ];
}

-(void)prepareTransfer
{
	NSPredicate	*pred;

	// set template filter
	if(transferType == TransferTypeLocal || transferType == TransferTypeDated) pred = [NSPredicate predicateWithFormat: @"type = 0 OR type = 2" ];
	else pred = [NSPredicate predicateWithFormat: @"type = %d", transferType ];
	[templateController setFilterPredicate: [pred retain ] ];
	
	if(transferType == TransferTypeInternal) {
		int i;
		[internalAccounts release ];
		internalAccounts = [[[account siblings ] allObjects ] retain ];
		[accountBox removeAllItems ];
		for(i=0; i<[internalAccounts count ]; i++) {
			[accountBox addItemWithObjectValue: [[internalAccounts objectAtIndex: i ] valueForKey: @"name" ] ];
		}
		NSString* selectedAccount = [transfer valueForKey: @"remoteAccount" ];
		if(selectedAccount != nil) [accountBox selectItemWithObjectValue: selectedAccount ];
	}
	
	// update limits
	if(transferType != TransferTypeEU) {
		selectedCountry = nil;
		[self updateLimits ];
		transfer.remoteCountry = account.country;
	}

	if(transferType == TransferTypeEU) {
		NSArray *allowedCountries = [[HBCIClient hbciClient ] allowedCountriesForAccount: account ];
		[countryController setContent:allowedCountries ];
		// sort descriptor for transactions view
		[countryController rearrangeObjects ];

		if (selectedCountry) {
			int idx=0;
			BOOL found = NO;
			for (Country *country in [countryController arrangedObjects ]) {
				if (country.code == selectedCountry) {
					found = YES;
					break;
				} else idx = idx+1;
			}
			if (found) {
				[countryController setSelectionIndex:idx ];
			}
		} else {
			selectedCountry = [(Country*)[[countryController arrangedObjects ] objectAtIndex:0] code ];
			[countryController setSelectionIndex:0 ];
		}
		[self updateLimits ];
		transfer.remoteCountry = selectedCountry;

	}
	
	// set default values
	if(transferType == TransferTypeDated) {
		int setupTime;
		if(limits) setupTime = [limits minSetupTime ]; else setupTime = 2;
		NSDate	*date = [NSDate dateWithTimeIntervalSinceNow: setupTime*86400 ];
		NSDate	*transferDate = transfer.valutaDate;
		if(transferDate == nil || [transferDate compare: date ] == NSOrderedDescending) {
			//			[transfer setValue: date forKey: @"date" ];
			transfer.valutaDate = date;
		}
		[executionDatePicker setMinDate: date ];
		setupTime = [limits maxSetupTime ];
		if(setupTime > 0) {
			date = [NSDate dateWithTimeIntervalSinceNow: setupTime*86400 ];
			[executionDatePicker setMaxDate: date ];
		}
	}
	
	// set charged party
	if(transferType == TransferTypeEU) {
		int idx = [transfer.chargedBy intValue ];
		if(idx>0) [chargeBox selectItemAtIndex: idx-1 ]; else [chargeBox selectItemAtIndex: 0 ];
	}
	
	// set date
	transfer.date = [NSDate date ];
	
	// set right window
	switch(transferType) {
		case TransferTypeLocal: window = transferLocalWindow; break;
		case TransferTypeDated: window = transferLocalWindow; break;
		case TransferTypeEU: window = transferEUWindow; break;
		case TransferTypeInternal: window = transferInternalWindow; break;
	};
	
	if(transferType != TransferTypeEU) [self preparePurposeFields ];
	if(transferType == TransferTypeLocal) [self hideTransferDate: YES ];
	if(transferType == TransferTypeDated) [self hideTransferDate: NO ];
	
	if(donation) {
		transfer.remoteAccount = @"0853820165";
		transfer.remoteBankCode = @"50010517";
		NSString *bankName = [[HBCIClient hbciClient] bankNameForCode:  @"50010517" inCountry: @"de"];
		transfer.remoteBankName = bankName;
		transfer.remoteName = @"Frank Emminghaus";
		transfer.purpose1 = @"Spende fuer Pecunia";
		
		//hide "next"-button
		NSView	*cv = [window contentView ];
		NSView	*bv = [cv viewWithTag: 50 ];
		[bv setHidden: YES ];
	}
	
	if(/*transferType == TransferTypeEU || */donation) [window makeFirstResponder: [[window contentView ] viewWithTag: 11 ] ];
	
	[templatesView setDoubleAction: @selector(templateDoubleClicked:) ];
	
/*	
	// limits
	maxLenPurpose = 27;
	maxLenRemoteName = 52;
*/ 
}

- (void)transferOfType: (TransferType)tt forAccount: (BankAccount*)acc
{
	NSError *error = nil;
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context];
	
	// save changed done with previous actions
	if ([context  hasChanges ]) {
		// save updates
		if([context save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}	

	// check for availability
	if([[HBCIClient hbciClient ] isTransferSupported: tt forAccount: acc ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"AP18", @"Job is not supported"), 
						NSLocalizedString(@"AP19", @"This kind of transfer is not supported by your bank for the selected account"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return;
	}

	transferType = tt;
	account = acc;
	
	transfer = [NSEntityDescription insertNewObjectForEntityForName:@"Transfer" inManagedObjectContext: context];
	
	[self prepareTransfer ];

	transfer.account = account;
	transfer.currency = account.currency;
	if([transfer.currency isEqualToString: @"" ]) transfer.currency = @"EUR";
	transfer.type = [NSNumber numberWithInt: transferType ];
	
	// prepare container
	transfers = [[NSMutableArray alloc ] initWithCapacity: 5 ];
	[transferController setContent: transfer ];
	
	switch(transferType) {
		case TransferTypeLocal: window = transferLocalWindow; break;
		case TransferTypeDated: window = transferLocalWindow; break;
		case TransferTypeEU: window = transferEUWindow; break;
		case TransferTypeInternal: window = transferInternalWindow; break;
	};
	
	[self preparePurposeFields ];
	if(transferType == TransferTypeLocal) [self hideTransferDate: YES ];
	else [self hideTransferDate: NO ];
	
	int res = [NSApp runModalForWindow: window ];
	if(res == 1) {
		if([context hasChanges ]) [context rollback ];
		return;
	}
	
	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

- (void)donateWithAccount: (BankAccount*)acc
{
	donation = YES;
	[self transferOfType: TransferTypeLocal forAccount: acc ];
}


-(void)hideTransferDate: (BOOL)hide
{
	NSView*	cView = [window contentView ];
	NSView* p;
	
	p = [cView viewWithTag: 20 ];
	[p setHidden: hide ];
	p = [cView viewWithTag: 21 ];
	[p setHidden: hide ];
}

- (void)changeTransfer:(Transfer*)tf
{
	NSError		*error=nil;
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context];

	// save changed done with previous actions
	if ([context  hasChanges ]) {
		// save updates
		if([context save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}	
	
	transferType = [tf.type intValue ];
	account = tf.account;
	
	if (transferType == TransferTypeEU) {
		[self setValue: tf.remoteCountry forKey:@"selectedCountry" ];
	}
	
	transfer = tf;
	[self prepareTransfer ];
	
	[transferController setContent: tf ];
	transfers = nil;
	
	//hide "next"-button
	NSView	*cv = [window contentView ];
	NSView	*bv = [cv viewWithTag: 50 ];
	[bv setHidden: YES ];
	
	int res = [NSApp runModalForWindow: window ];
	[bv setHidden: NO ];
	if(res == 1) {
		if([context hasChanges ]) [context rollback ];
		return;
	}
	
	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

-(void)saveTemplate
{
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	TransferTemplate *template;
	
	NSTextField *templateField = (NSTextField*)[[window contentView ] viewWithTag:200 ];

	NSString *name = [templateField stringValue ];
	if (name == nil || [name length ] == 0) return;
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet ] ];
	if (name == nil || [name length ] == 0) return;

	template = [NSEntityDescription insertNewObjectForEntityForName:@"TransferTemplate" inManagedObjectContext: context];
	template.name = name;
    template.type = transfer.type;
	template.remoteAccount = transfer.remoteAccount;
	template.remoteBankCode = transfer.remoteBankCode;
	template.remoteName = transfer.remoteName;
	template.purpose1 = transfer.purpose1;
	template.purpose2 = transfer.purpose2;
	template.purpose3 = transfer.purpose3;
	template.purpose4 = transfer.purpose4;
	template.remoteIBAN = transfer.remoteIBAN;
	template.remoteBIC = transfer.remoteBIC;
	template.remoteCountry = transfer.remoteCountry;
	template.value = transfer.value;
	template.currency = transfer.currency;
	
	[templateField setStringValue:@"" ];
}


- (IBAction)transferFinished:(id)sender
{
	if(transferType == TransferTypeInternal) {
		// get account from combo
		int idx = [accountBox indexOfSelectedItem ];
		if(idx < 0) { NSBeep(); return; }
		transfer.remoteAccount = [[internalAccounts objectAtIndex: idx ] accountNumber ];
		transfer.remoteBankCode = [[internalAccounts objectAtIndex: idx ] bankCode ];
	}
	if(transferType == TransferTypeEU) {
		int idx = [countryButton indexOfSelectedItem ];
		if(idx < 0) { NSBeep(); return; }
		transfer.chargedBy = [NSNumber numberWithInt: [chargeBox indexOfSelectedItem ] + 1 ];
	}
	[transferController commitEditing ];
	if([self check ] == NO) return;

	// save as template (if name given)
	[self saveTemplate ];

	[templatesDraw close: self ];
	[window close ];
	[transferController setContent:nil ];	
	[NSApp stopModalWithCode:0];
}

- (IBAction)nextTransfer:(id)sender
{
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	NSError *error;
	
	if(transferType == TransferTypeInternal) {
		// get account from combo
		int idx = [accountBox indexOfSelectedItem ];
		if(idx < 0) { NSBeep(); return; }
		transfer.remoteAccount = [[internalAccounts objectAtIndex: idx ] accountNumber ];
		transfer.remoteBankCode = [[internalAccounts objectAtIndex: idx ] bankCode ];
		transfer.remoteBankName = account.bankName;
	}
	if(transferType == TransferTypeEU) {
		int idx = [countryButton indexOfSelectedItem ];
		if(idx < 0) { NSBeep(); return; }
		transfer.chargedBy = [NSNumber numberWithInt: [chargeBox indexOfSelectedItem ] + 1 ];
	}
	
	[transferController commitEditing ];
	if([self check ] == NO) return;
	
	[transfers addObject: transfer ];

	// save as template (if name given)
	[self saveTemplate ];
	
	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	
	transfer = [NSEntityDescription insertNewObjectForEntityForName:@"Transfer"
											 inManagedObjectContext: context];
	
	// defaults
	if(transferType == TransferTypeDated) {
		int setupTime;
		if(limits) setupTime = [limits minSetupTime ]; else setupTime = 2;
		NSDate	*date = [NSDate dateWithTimeIntervalSinceNow: setupTime*86400 ];
		transfer.date = date;
	}
	
	// set date
	transfer.date = [NSDate date ];

	transfer.account = account;
	transfer.currency = account.currency;
	if([transfer.currency isEqualToString: @"" ]) transfer.currency = @"EUR";
	
	if(transferType == TransferTypeEU) transfer.remoteCountry = selectedCountry; else transfer.remoteCountry = account.country;

	[transferController setContent: transfer ];

	[window makeFirstResponder: [[window contentView ] viewWithTag: 10 ] ];
}

- (IBAction)cancel:(id)sender
{
	[templatesDraw close: self ];
	[window close ];
	[transferController setContent:nil ];	
	[NSApp stopModalWithCode:1];
}

-(BOOL)windowShouldClose:(id)sender
{
	[NSApp stopModalWithCode:1];
	[transfers release ];
	[transferController setContent:nil ];	
	return YES;
}


-(BOOL)check
{
	BOOL			res;
	NSNumber		*value;

	if(transfer.remoteName == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP8", @"Please enter a receiver"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	// do not check remote account for EU transfers, instead IBAN
	if(transferType != TransferTypeEU) {
		if(transfer.remoteAccount == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
							NSLocalizedString(@"AP9", @"Please enter an account number"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	} else {
		// EU transfer
		if(transfer.remoteIBAN == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
							NSLocalizedString(@"AP24", @"Please enter a valid IBAN"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
		// check IBAN
		if([[HBCIClient hbciClient ] checkIBAN: transfer.remoteIBAN ] == NO) {
			NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
							NSLocalizedString(@"AP26", @"IBAN is not valid"),
							NSLocalizedString(@"retry", @"Retry"), nil, nil);
			return NO;
		}
	}
	
	if(transferType == TransferTypeLocal ||  transferType == TransferTypeDated) {
		if(transfer.remoteBankCode == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
							NSLocalizedString(@"AP10", @"Please enter a bank code"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	}
	
	if(transferType == TransferTypeEU) {
		if(transfer.remoteBIC == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
							NSLocalizedString(@"AP25", @"Please enter valid bank identification code (BIC)"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	}
	
	if( (value = transfer.value) == nil ) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP11", @"Please enter a value"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	if([value doubleValue ] <= 0) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP12", @"Please enter a value greater 0"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	// purpose?
	if (transfer.purpose1 == nil || [transfer.purpose1 length ] == 0) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP121", @"Please enter a purpose"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	if(transferType == TransferTypeEU) {
		NSString	*foreignCurr = [[[countryController selectedObjects ] lastObject ] currency ];
		NSString	*curr = transfer.currency;
		double		limit = 0.0;
		
		if(![curr isEqual: foreignCurr ] && ![curr isEqual: @"EUR" ] && ![curr isEqual: account.currency ]) {
			NSRunAlertPanel(NSLocalizedString(@"AP22", @"Currency not allowed"), 
							[NSString stringWithFormat: NSLocalizedString(@"AP23", @"The transfer currency is not allowed"), [limits localLimit ] ], 
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
		
		if([curr isEqual: foreignCurr ] && limits) limit = [limits foreignLimit ]; else limit = [limits localLimit ];
		if(limit > 0 && [value doubleValue ] > limit) {
			NSRunAlertPanel(NSLocalizedString(@"AP20", @"Amount too high"), 
							[NSString stringWithFormat: NSLocalizedString(@"AP21", @"The transfer amount must not be higher than %.2f"), [limits localLimit ] ], 
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	}
	
	
	// verify account and bank information
	if(transferType != TransferTypeEU) {
		// verify accounts, but only for available countries
		if([transfer.remoteCountry caseInsensitiveCompare: @"de" ] == NSOrderedSame ||
		   [transfer.remoteCountry caseInsensitiveCompare: @"at" ] == NSOrderedSame ||
		   [transfer.remoteCountry caseInsensitiveCompare: @"ch" ] == NSOrderedSame ||
		   [transfer.remoteCountry caseInsensitiveCompare: @"ca" ] == NSOrderedSame) {

			res = [[HBCIClient hbciClient ] checkAccount: transfer.remoteAccount 
												 forBank: transfer.remoteBankCode 
											   inCountry: transfer.remoteCountry ];

			if(res == NO) {
				NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
								NSLocalizedString(@"AP13", @"Account number is not valid"),
								NSLocalizedString(@"retry", @"Retry"), nil, nil);
				return NO;
			}
		}
	}
	return YES;
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	donation = NO;
/*	
	if([transactions count ] == 0)	{
		[NSApp stopModalWithCode:1];
		[transactions release ];
	}
*/ 
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextField	*te = [aNotification object ];
	NSString	*bankName;
	
	if([te tag ] != 100) return;
	
	if(transferType == TransferTypeEU) {
		bankName = [[HBCIClient hbciClient  ] bankNameForBIC: [te stringValue ] inCountry: transfer.remoteCountry ];
	} else {
		bankName = [[HBCIClient hbciClient  ] bankNameForCode: [te stringValue ] inCountry: transfer.remoteCountry ];
 	}
	if(bankName) transfer.remoteBankName = bankName;
}

-(void)controlTextDidChange: (NSNotification*)aNotification
{
	NSTextField	*te = [aNotification object ];
	int			maxLen;
	
	if([te tag ] < 10) maxLen = [limits maxLenPurpose ];
	else if([te tag ] == 10) maxLen = [limits maxLengthRemoteName ];
	else if([te tag ] == 20) maxLen = 52;
	else return;
	
	if([[te stringValue ] length ] > maxLen) { 
		[te setStringValue:  [[te stringValue ] substringToIndex: maxLen ] ];
		NSBeep();
		return; 
	};
	return;
}

- (IBAction)getDataFromTemplate:(id)sender
{
	NSArray	*selection = [templateController selectedObjects ];
	NSString *bankName = nil;
	
	if(selection && [selection count ] > 0) {
		TransferTemplate*	template = (TransferTemplate*)[selection objectAtIndex: 0 ];
		[transfer copyFromTemplate: template withLimits: limits ];
		
		// get Bank Name
		if(transferType == TransferTypeEU) {
			bankName = [[HBCIClient hbciClient  ] bankNameForBIC: transfer.remoteBIC inCountry: transfer.remoteCountry ];
		} else {
			bankName = [[HBCIClient hbciClient  ] bankNameForCode: transfer.remoteBankCode inCountry: transfer.remoteCountry ];
		}
		if(bankName) transfer.remoteBankName = bankName;		
	}
}

-(void)preparePurposeFields
{
	int t;
	if(limits == nil) return;
	NSView*	cView = [window contentView ];
	
	int num = (t = limits.maxLinesPurpose)?t:2;
	NSView* p;
	
	p = [cView viewWithTag: 4 ];
	if(num < 4) [p setHidden: TRUE ]; else [p setHidden: FALSE ];
	p = [cView viewWithTag: 3 ];
	if(num < 3) [p setHidden: TRUE ]; else [p setHidden: FALSE ];
	p = [cView viewWithTag: 2 ];
	if(num < 2) [p setHidden: TRUE ]; else [p setHidden: FALSE ];
}


- (IBAction)countryDidChange:(id)sender
{
	selectedCountry = [(Country*)[[countryController selectedObjects] lastObject ] code ];
	[self updateLimits ];
	[self preparePurposeFields ];
	transfer.remoteCountry = selectedCountry;
}

-(void)dealloc
{
	[limits release ];
	[internalAccounts release ];
	[super dealloc ];
}


@end
