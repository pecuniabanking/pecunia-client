//
//  TransactionController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "TransactionController.h"
#import "BankingController.h"
#import "Category.h"
#import "Transfer.h"
#import "TransactionLimits.h"
#import "MOAssistant.h"
#import "Account.h"
#import "BankAccount.h"
#import "HBCIClient.h"

@implementation TransactionController

-(void)awakeFromNib
{
	// sort descriptor for transactions view
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"country" ascending:YES] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[countryController setSortDescriptors: sds ];
}

-(void)updateLimits
{
	if(selectedCountry == nil) return;
	NSArray *countryInfo = [limits valueForKey: @"countryInfos" ];
	NSString *s;
	for(s in countryInfo) {
		NSArray *comps = [s componentsSeparatedByString: @";" ];
		if ([selectedCountry isEqualToString: [comps objectAtIndex:0 ] ]) {
			maxLenRemoteName = [[comps objectAtIndex:3 ] intValue];
			maxLenBankName = [[comps objectAtIndex:4 ] intValue];
			maxLenPurpose = [[comps objectAtIndex:5 ] intValue];
			break;
		}
	}

}

-(void)templateDoubleClicked: (id)sender
{
	int row = [sender clickedRow ];
	if(row<0) return;
	[self getDataFromTemplate: sender ];
}

-(NSString*)jobNameForType: (TransferType)tt
{
	switch(tt) {
		case TransferTypeLocal: return @"Ueb"; break;
		case TransferTypeDated: return @"TermUeb"; break;
		case TransferTypeEU: return @"UebForeign"; break;
	};
	return nil;
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

	// update limits
	[limits release ];
	limits = [[HBCIClient hbciClient ] getRestrictionsForJob: [self jobNameForType:transferType ] account: account ];
	[limits retain ];
	
	if(transferType == TransferTypeEU) {
		NSArray *countryInfo = [limits valueForKey: @"countryInfos" ];
		NSString *s;
		[countryController removeObjects: [countryController arrangedObjects ] ];
		// available countries
		NSDictionary *cInfos = [[HBCIClient hbciClient ] countryInfos ];
		
		// get texts for allowed countries - build up PopUpButton data
		for(s in countryInfo) {
			NSArray *comps = [s componentsSeparatedByString: @";" ];
			NSArray *info = [cInfos valueForKey:[comps objectAtIndex:0 ] ];
			if(info == nil) continue;
			
			NSMutableDictionary *ci = [NSMutableDictionary dictionaryWithCapacity: 2 ];
			[ci setValue: [info objectAtIndex:0 ] forKey: @"country" ];
			[ci setValue: [info objectAtIndex:1 ] forKey: @"number" ];
			[ci setValue: [info objectAtIndex:2 ] forKey: @"id" ];
			// no no amount limits are regarded at the moment
			
			[countryController addObject:ci ];
		}
		// sort descriptor for transactions view
		[countryController rearrangeObjects ];
		
		// select country
		if (selectedCountry) {
			NSArray *allowedCountries = [countryController arrangedObjects ];
			NSDictionary *ci;
			for(ci in allowedCountries) {
				if([[ci valueForKey:@"id" ] isEqualToString: selectedCountry ]) {
					[self setValue: ci forKey: @"selCountryInfo" ];
					break;
				}
			}
			[self updateLimits ];
		} else [self setValue: [[countryController arrangedObjects ] objectAtIndex:0] forKey: @"selCountryInfo" ];
	}
	
	// set default values
	if(transferType == TransferTypeDated) {
		int setupTime;
		NSString *t;
		if(limits) setupTime = (t = [limits valueForKey:@"minpretime" ])?[t intValue ]:2; else setupTime = 2;
		NSDate	*date = [NSDate dateWithTimeIntervalSinceNow: setupTime*86400 ];
		NSDate	*transferDate = [transfer valueForKey: @"valutaDate" ];
		if(transferDate == nil || [transferDate compare: date ] == NSOrderedAscending) {
			[transfer setValue: date forKey: @"valutaDate" ];
		}
		[executionDatePicker setMinDate: date ];
		if(limits) setupTime = (t = [limits valueForKey:@"maxpretime" ])?[t intValue ]:2; else setupTime = 90;
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
		NSString *bankName = [[HBCIClient hbciClient] bankNameForCode:  @"50010517" ];
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
	
	// limits
	maxLenPurpose = 27;
	maxLenRemoteName = 52;
}

- (void)transferOfType: (TransferType)tt forAccount: (BankAccount*)acc
{
	NSError		*error = nil;
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];

	// check for availability
	if([[HBCIClient hbciClient ] isJobSupported: [self jobNameForType:tt ] forAccount: acc ] == NO) {
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
	}
	if(transferType == TransferTypeEU) {
		int idx = [countryButton indexOfSelectedItem ];
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
		int idx = [countryButton indexOfSelectedItem ];
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
		NSString *t;
		if(limits) setupTime = (t = [limits valueForKey:@"minpretime" ])?[t intValue ]:2; else setupTime = 2;
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
	[transfers release ];
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
	BOOL			res;
	NSNumber		*value;
	PecuniaError	*error = nil;

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
		if([[HBCIClient hbciClient ] checkIBAN: [transfer valueForKey: @"remoteIBAN" ] error: &error ] == NO) {
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
	
	
	// verify account and bank information
	if(transferType != TransferTypeEU) {
		// verify accounts, but only for available countries
		if([selectedCountry caseInsensitiveCompare: @"de" ] == NSOrderedSame) {

			res = [[HBCIClient hbciClient ] checkAccount: [transfer valueForKey: @"remoteAccount" ] 
												bankCode:[transfer valueForKey: @"remoteBankCode" ] 
												   error: &error ];

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
	
	if(transferType != TransferTypeEU) {
		bankName = [[HBCIClient hbciClient  ] bankNameForCode: [te stringValue ] ];
		if(bankName) [transfer setValue: bankName forKey: @"remoteBankName" ];
 	}
}

-(void)controlTextDidChange: (NSNotification*)aNotification
{
	NSTextField	*te = [aNotification object ];
	int			maxLen;
	
	if([te tag ] < 10) maxLen = maxLenPurpose;
	else if([te tag ] == 10) maxLen = maxLenRemoteName;
	else if([te tag ] == 20) maxLen = maxLenBankName;
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
		[transfer copyFromTemplate: template ];
	}
}

-(void)preparePurposeFields
{
	NSString *t;
	if(limits == nil) return;
	NSView*	cView = [window contentView ];
	
	int num = (t = [limits valueForKey:@"maxusage" ])?[t intValue ]:2;
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
	selectedCountry = [selCountryInfo valueForKey:@"id"];
	[self updateLimits ];
}

-(void)dealloc
{
	[limits release ];
	[internalAccounts release ];
	[super dealloc ];
}


@end
