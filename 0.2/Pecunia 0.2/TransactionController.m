//
//  TransactionController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "TransactionController.h"
#import "BankingController.h"
#import "ABController.h"
#import "Category.h"
#import "Transfer.h"
#import "TransactionLimits.h"
#import "MOAssistant.h"
#import "ABAccount.h"
#import "BankAccount.h"

@implementation TransactionController

-(void)awakeFromNib
{
//	NSPredicate	*pred = [NSPredicate predicateWithFormat: @"isTemplate = YES" ];
//	[templateController setFetchPredicate: [pred retain ] ];
}

-(void)updateLimitsForCountry: (NSString*)country
{
	[limits release ]; limits = nil;
	limits = [[account abAccount ] limitsForType: transferType country: country ];
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
	if(transferType == TransferTypeLocal || transferType == TransferTypeDated) pred = [NSPredicate predicateWithFormat: @"isTemplate = YES AND (type = 0 OR type = 2)" ];
	else pred = [NSPredicate predicateWithFormat: @"isTemplate = YES AND type = %d", transferType ];
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

	// get allowed countries
	if(transferType == TransferTypeEU) {
		int i;
		
		[countryBox removeAllItems ];
		NSDictionary* allCountries = [[ABController abController ] countries ];
		NSArray* allowedCountries = [[account abAccount ] allowedCountries ];
		for(i=0; i<[allowedCountries count ]; i++) [countryBox addItemWithObjectValue: [[allCountries valueForKey: [allowedCountries objectAtIndex: i ] ] name ] ];
		if(selectedCountry != nil) {
			NSString *name = [[allCountries valueForKey: [selectedCountry uppercaseString ] ] name ];
			[countryBox selectItemWithObjectValue: name ];
		}
	}
	
	// update limits
	if(transferType != TransferTypeEU) {
		[self updateLimitsForCountry: nil ];
		selectedCountry = [account valueForKey: @"country" ];
	}
	
	// set default values
	if(transferType == TransferTypeDated) {
		int setupTime;
		if(limits) setupTime = [limits minSetupTime ]; else setupTime = 2;
		NSDate	*date = [NSDate dateWithTimeIntervalSinceNow: setupTime*86400 ];
		NSDate	*transferDate = [transfer valueForKey: @"valutaDate" ];
		if(transferDate == nil || [transferDate compare: date ] == NSOrderedDescending) {
//			[transfer setValue: date forKey: @"date" ];
			[transfer setValue: date forKey: @"valutaDate" ];
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
		int idx = [[transfer valueForKey: @"chargedBy" ] intValue ];
		if(idx>0) [chargeBox selectItemAtIndex: idx-1 ]; else [chargeBox selectItemAtIndex: 0 ];
	}
	
	// set date
	[transfer setValue: [NSDate date ] forKey: @"date" ];
		
	
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
		[transfer setValue: @"0853820165" forKey: @"remoteAccount" ];
		[transfer setValue: @"50010517" forKey: @"remoteBankCode" ];
		NSString *bankName = [[bankingController abController ] bankNameForCode:  @"50010517" inCountry: [account valueForKey: @"country" ] ];
		[transfer setValue: bankName forKey: @"remoteBankName" ];
		[transfer setValue: @"Frank Emminghaus" forKey: @"remoteName" ];
		[transfer setValue: @"Spende fuer Pecunia" forKey: @"purpose1" ];
		
		//hide "next"-button
		NSView	*cv = [window contentView ];
		NSView	*bv = [cv viewWithTag: 50 ];
		[bv setHidden: YES ];
	}
	
	if(/*transferType == TransferTypeEU || */donation) [window makeFirstResponder: [[window contentView ] viewWithTag: 11 ] ];
	
	[templatesView setDoubleAction: @selector(templateDoubleClicked:) ];
}

- (void)transferOfType: (TransferType)tt forAccount: (BankAccount*)acc
{
	NSError		*error = nil;
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];

	// check for availability
	if([[acc abAccount ] isTransferSupportedForType: tt ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"AP18", @"Job is not supported"), 
						NSLocalizedString(@"AP19", @"This kind of transfer is not supported by your bank for the selected account"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return;
	}
	
	transferType = tt;
	account = acc;
	
	transfer = [NSEntityDescription insertNewObjectForEntityForName:@"Transfer"
											 inManagedObjectContext: context];
	
	[self prepareTransfer ];

	[transfer setValue: account forKey: @"account" ];
	[transfer setValue: [account valueForKey: @"currency" ] forKey: @"currency" ];
	if([[transfer valueForKey: @"currency" ] isEqual: @"" ]) [transfer setValue: @"EUR" forKey: @"currency" ];
	[transfer setValue: [NSNumber numberWithInt: transferType ] forKey: @"type" ];
	
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
	
	[transfers autorelease ];
	
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
	NSError		*error;
	NSManagedObjectContext	*context = [bankingController managedObjectContext ];

	transferType = [[tf valueForKey: @"type" ] intValue ];
	account = [tf valueForKey: @"account" ];
	[self setValue: [tf valueForKey: @"remoteCountry" ] forKey: @"selectedCountry" ];
	
	transfer = tf;
	[self prepareTransfer ];
	
	if(transferType == TransferTypeEU) {
		[self updateLimitsForCountry: selectedCountry ];
		[self preparePurposeFields ];
	}
	
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


- (IBAction)transferFinished:(id)sender
{
	if(transferType == TransferTypeInternal) {
		// get account from combo
		int idx = [accountBox indexOfSelectedItem ];
		if(idx < 0) { NSBeep(); return; }
		[transfer setValue: [[internalAccounts objectAtIndex: idx ] accountNumber ] forKey: @"remoteAccount" ];
		[transfer setValue: [[internalAccounts objectAtIndex: idx ] bankCode ] forKey: @"remoteBankCode" ];
		[transfer setValue: [account valueForKey: @"bankName" ] forKey: @"remoteBankName" ];
	}
	if(transferType == TransferTypeEU) {
		int idx = [countryBox indexOfSelectedItem ];
		if(idx < 0) { NSBeep(); return; }
		[transfer setValue: [NSNumber numberWithInt: [chargeBox indexOfSelectedItem ] + 1 ] forKey: @"chargedBy" ];
	}
	[transferController commitEditing ];
	if([self check ] == NO) return;

	[templatesDraw close: self ];
	[window close ];
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
		[transfer setValue: [[internalAccounts objectAtIndex: idx ] accountNumber ] forKey: @"remoteAccount" ];
		[transfer setValue: [[internalAccounts objectAtIndex: idx ] bankCode ] forKey: @"remoteBankCode" ];
		[transfer setValue: [account valueForKey: @"bankName" ] forKey: @"remoteBankName" ];
	}
	if(transferType == TransferTypeEU) {
		int idx = [countryBox indexOfSelectedItem ];
		if(idx < 0) { NSBeep(); return; }
		[transfer setValue: [NSNumber numberWithInt: [chargeBox indexOfSelectedItem ] + 1 ] forKey: @"chargedBy" ];
	}
	
	[transferController commitEditing ];
	if([self check ] == NO) return;
	
	[transfers addObject: transfer ];
	
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
		[transfer setValue: date forKey: @"valutaDate" ];
	}
	
	// set date
	[transfer setValue: [NSDate date ] forKey: @"date" ];

	[transfer setValue: account forKey: @"account" ];
	[transfer setValue: [account valueForKey: @"currency" ] forKey: @"currency" ];
	if([[transfer valueForKey: @"currency" ] isEqual: @"" ]) [transfer setValue: @"EUR" forKey: @"currency" ];
	[transfer setValue: selectedCountry forKey: @"remoteCountry" ];

	[transferController setContent: transfer ];

	[window makeFirstResponder: [[window contentView ] viewWithTag: 10 ] ];
}

- (IBAction)cancel:(id)sender
{
	[templatesDraw close: self ];
	[window close ];
	[NSApp stopModalWithCode:1];
}

-(BOOL)windowShouldClose:(id)sender
{
	[NSApp stopModalWithCode:1];
	[transfers release ];
	return YES;
}


-(BOOL)check
{
	BOOL		res;
	NSNumber	*value;

	if([transfer valueForKey: @"remoteName" ] == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP8", @"Please enter a receiver"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	// do not check remote account for EU transfers, instead IBAN
	if(transferType != TransferTypeEU) {
		if([transfer valueForKey: @"remoteAccount" ] == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
							NSLocalizedString(@"AP9", @"Please enter an account number"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	} else {
		// EU transfer
		if([transfer valueForKey: @"remoteIBAN" ] == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
							NSLocalizedString(@"AP24", @"Please enter a valid IBAN"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
		// check IBAN
		if([[ABController abController ] checkIBAN: [transfer valueForKey: @"remoteIBAN" ] ] == NO) {
			NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
							NSLocalizedString(@"AP26", @"IBAN is not valid"),
							NSLocalizedString(@"retry", @"Retry"), nil, nil);
			return NO;
		}
	}
	
	if(transferType == TransferTypeLocal ||  transferType == TransferTypeDated) {
		if([transfer valueForKey: @"remoteBankCode" ] == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
							NSLocalizedString(@"AP10", @"Please enter a bank code"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	}
	
	if(transferType == TransferTypeEU) {
		if([transfer valueForKey: @"remoteBIC" ] == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
							NSLocalizedString(@"AP25", @"Please enter valid bank identification code (BIC)"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	}
	
	if( (value = [transfer valueForKey: @"value" ]) == nil ) {
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
	
	if(transferType == TransferTypeEU) {
		NSString	*foreignCurr = [[[[ABController abController ] countries ] valueForKey: selectedCountry ] currency ];
		NSString	*curr = [transfer valueForKey: @"currency" ];
		double		limit = 0.0;
		
		if(![curr isEqual: foreignCurr ] && ![curr isEqual: @"EUR" ] && ![curr isEqual: [account valueForKey: @"currency" ] ]) {
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
	if(transferType != TransferTypeEU && transferType != TransferTypeInternal) {
		// verify accounts, but only for available countries
		if([selectedCountry caseInsensitiveCompare: @"de" ] == NSOrderedSame ||
		   [selectedCountry caseInsensitiveCompare: @"at" ] == NSOrderedSame ||
		   [selectedCountry caseInsensitiveCompare: @"ch" ] == NSOrderedSame ||
		   [selectedCountry caseInsensitiveCompare: @"ca" ] == NSOrderedSame) {
			res = [[bankingController abController ] checkAccount: [transfer valueForKey: @"remoteAccount" ]
														  forBank: [transfer valueForKey: @"remoteBankCode" ]
														inCountry: [account valueForKey: @"country" ] ];
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
		bankName = [[bankingController abController ] bankNameForBic: [te stringValue ]
														   inCountry: selectedCountry ];
	} else {
		bankName = [[bankingController abController ] bankNameForCode: [te stringValue ]
															inCountry: [account valueForKey: @"country" ] ];
	}
	[transfer setValue: bankName forKey: @"remoteBankName" ];
}

-(void)controlTextDidChange: (NSNotification*)aNotification
{
	NSTextField	*te = [aNotification object ];
	int			maxLen;
	
	if([te tag ] < 10) maxLen = [limits maxLenPurpose ];
	else if([te tag ] == 10) maxLen = [limits maxLenRemoteName ] * [limits maxLinesRemoteName ];
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
	NSArray*	selection = [templateController selectedObjects ];
	
	if(selection && [selection count ] > 0) {
		Transfer*	template = (Transfer*)[selection objectAtIndex: 0 ];
		[transfer copyFromTemplate: template withLimits: limits ];
	}
}

-(void)preparePurposeFields
{
	NSView*	cView = [window contentView ];
	int num = [limits maxLinesPurpose ];
	NSView* p;
	
	p = [cView viewWithTag: 4 ];
	if(num < 4) [p setHidden: TRUE ]; else [p setHidden: FALSE ];
	p = [cView viewWithTag: 3 ];
	if(num < 3) [p setHidden: TRUE ]; else [p setHidden: FALSE ];
	p = [cView viewWithTag: 2 ];
	if(num < 2) [p setHidden: TRUE ]; else [p setHidden: FALSE ];
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
	NSComboBox	*combo = [notification object ];
	if(combo == countryBox) {
		NSArray	*allowedCountries = [[account abAccount ] allowedCountries ];
		int idx = [countryBox indexOfSelectedItem ];
		if(idx<0) return;
		NSString	*country = [allowedCountries objectAtIndex: idx];
		
		[self updateLimitsForCountry: country ];
		[self preparePurposeFields ];
		[self setValue: country forKey: @"selectedCountry" ];
		[transfer setValue: country forKey: @"remoteCountry" ];
	}
}

-(void)dealloc
{
	[limits release ];
	[internalAccounts release ];
	[super dealloc ];
}


@end
