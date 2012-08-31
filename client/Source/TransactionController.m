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

#import "TransactionController.h"
#import "Category.h"
#import "Transfer.h"
#import "TransactionLimits.h"
#import "MOAssistant.h"
#import "BankAccount.h"
#import "HBCIClient.h"
#import "Country.h"
#import "TransferTemplate.h"
#import "LogController.h"

/**
 * Transform zero-based selector indices to one-based chargedBy property values for transfers.
 */
@implementation ChargeByValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue: (id)value
{
    if (value == nil)
        return nil;
    
    if ([value intValue] == 0)
        return value;
    
    return [NSNumber numberWithInt: [value intValue] - 1];
}

- (id)reverseTransformedValue: (id)value
{
    if (value == nil)
        return nil;
    
    return [NSNumber numberWithInt: [value intValue] + 1];
}

@end

@implementation TransactionController

@synthesize currentTransfer;
@synthesize currentTransferController;
@synthesize templateController;

-(void)awakeFromNib
{
	// sort descriptor for transactions view
	NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	NSArray *sds = [NSArray arrayWithObject:sd];
	[countryController setSortDescriptors: sds];

	// sort descriptor for template view
	sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	sds = [NSArray arrayWithObject:sd];
	[templateController setSortDescriptors: sds];
}

-(void)setManagedObjectContext: (NSManagedObjectContext*)context
{
	[templateController setManagedObjectContext: context];
	[templateController prepareContent];
	[currentTransferController setManagedObjectContext: context];
}

- (void)updateLimits
{
	[limits release];
	limits = [[[HBCIClient hbciClient] limitsForType: transferType account: account country: selectedCountry] retain];
}

-(void)templateDoubleClicked: (id)sender
{
	int row = [sender clickedRow ];
	if(row<0) return;
	[self getDataFromTemplate: sender ];
}

-(void)prepareTransfer
{
	//NSPredicate	*pred;

    // set drawer content
    switch (transferType) {
        case TransferTypeStandard:
        case TransferTypeDated: {
            [templatesDraw setContentView: standardHelpView ];
            [templatesDraw setParentWindow: transferLocalWindow ];
            break;
        }
        case TransferTypeEU: {
            [templatesDraw setContentView: foreignHelpView ];
            [templatesDraw setParentWindow: transferEUWindow ];
            break;
        }
        case TransferTypeSEPA: {
            [templatesDraw setContentView: foreignHelpView ];
            [templatesDraw setParentWindow: transferSEPAWindow ];
            break;            
        }
        default:
            break;
    }
        
    /*
	// set template filter
	if(transferType == TransferTypeStandard || transferType == TransferTypeDated) pred = [NSPredicate predicateWithFormat: @"type = 0 OR type = 2" ];
	else pred = [NSPredicate predicateWithFormat: @"type = 1 or type = 5" ];
	[templateController setFilterPredicate: pred];
	*/
    
	if(transferType == TransferTypeInternal) {
		[internalAccounts release ];
		internalAccounts = [[[account siblings ] allObjects ] retain ];
		[accountBox removeAllItems ];
		for (BankAccount *acc in internalAccounts) {
			[accountBox addItemWithObjectValue: acc.name ];
		}
		NSString* selectedAccount = currentTransfer.remoteAccount;
		if(selectedAccount != nil) [accountBox selectItemWithObjectValue: selectedAccount ];
	}
	
	// update limits
	if(transferType != TransferTypeEU) {
		selectedCountry = nil;
		[self updateLimits ];
		currentTransfer.remoteCountry = account.country;
	} else {
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
		currentTransfer.remoteCountry = selectedCountry;

	}
	
	// set default values
	if(transferType == TransferTypeDated) {
		int setupTime;
		if(limits) setupTime = [limits minSetupTime ]; else setupTime = 2;
		NSDate	*date = [NSDate dateWithTimeIntervalSinceNow: setupTime*86400 ];
		NSDate	*transferDate = currentTransfer.valutaDate;
		if(transferDate == nil || [transferDate compare: date ] == NSOrderedAscending) {
			//			[transfer setValue: date forKey: @"date" ];
			currentTransfer.valutaDate = date;
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
		int idx = [currentTransfer.chargedBy intValue ];
		if(idx>0) [chargeBox selectItemAtIndex: idx-1 ]; else [chargeBox selectItemAtIndex: 0 ];
	}
	
	// set date
	currentTransfer.date = [NSDate date ];
	
	// set right window
	switch(transferType) {
		case TransferTypeStandard: window = transferLocalWindow; break;
		case TransferTypeDated: window = transferLocalWindow; break;
		case TransferTypeEU: window = transferEUWindow; break;
        case TransferTypeSEPA: window = transferSEPAWindow; break;
		case TransferTypeInternal: window = transferInternalWindow; break;
        case TransferTypeDebit: break; // TODO
        case TransferTypeCollectiveCredit: break; // TODO
        case TransferTypeCollectiveDebit: break; // TODO
	};
	
	if(transferType != TransferTypeEU && transferType != TransferTypeSEPA) [self preparePurposeFields ];
	if(transferType == TransferTypeStandard) [self hideTransferDate: YES ];
	if(transferType == TransferTypeDated) [self hideTransferDate: NO ];
	
    //	if(/*transferType == TransferTypeEU || */donation) [window makeFirstResponder: [[window contentView ] viewWithTag: 11 ] ];
	
    [[[templatesDraw contentView ] viewWithTag:10 ] setDoubleAction:@selector(templateDoubleClicked:) ];
}

- (BOOL)newTransferOfType: (TransferType)type
{
    NSError *error = nil;
    NSManagedObjectContext *context = [[MOAssistant assistant] context];

    // Save any previous change.
    if ([context  hasChanges]) {
        if([context save: &error ] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return NO;
        }
    }

    account = nil;
	transferType = type;
    currentTransfer = [NSEntityDescription insertNewObjectForEntityForName: @"Transfer" inManagedObjectContext: context];
    currentTransfer.type = [NSNumber numberWithInt: transferType];
    currentTransfer.changeState = TransferChangeNew;
    [self prepareTransfer];
    [currentTransferController setContent: currentTransfer];

    return YES;
}

- (BOOL)editExistingTransfer: (Transfer*)transfer
{
    NSError *error = nil;
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    
    // Save any previous change.
    if ([context  hasChanges]) {
        if ([context save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return NO;
        }
    }
	
	transferType = [transfer.type intValue];
	account = transfer.account;
	
	if (transferType == TransferTypeEU) {
		[self setValue: transfer.remoteCountry forKey: @"selectedCountry"];
	}
	
	currentTransfer = transfer;
	[self prepareTransfer];
    currentTransfer.changeState = TransferChangeEditing;
	
	[currentTransferController setContent: transfer];
    
    return YES;
}

- (BOOL)newTransferFromExistingTransfer: (Transfer*)transfer
{
    if (![self newTransferOfType: [transfer.type intValue]]) {
        return NO;
    }
        
	transferType = [transfer.type intValue];
	account = transfer.account;
	
	if (transferType == TransferTypeEU) {
		[self setValue: transfer.remoteCountry forKey: @"selectedCountry"];
	}
	
	[self prepareTransfer];
    [currentTransfer copyFromTransfer: transfer withLimits: limits];
    currentTransfer.changeState = TransferChangeNew;
    
    // Determine the remote bank name again.
    NSString *bankName;
    if (transferType == TransferTypeEU) {
        bankName = [[HBCIClient hbciClient] bankNameForBIC: currentTransfer.remoteBIC inCountry: currentTransfer.remoteCountry];
    } else {
        bankName = [[HBCIClient hbciClient] bankNameForCode: currentTransfer.remoteBankCode inCountry: currentTransfer.remoteCountry];
    }
    if (bankName != nil) {
        currentTransfer.remoteBankName = bankName;		   
    }
    return YES;
}

- (BOOL)newTransferFromTemplate: (TransferTemplate*)template
{
    if (![self newTransferOfType: [template.type intValue]]) {
        return NO;
    }
    
	transferType = [template.type intValue];
	
	[self prepareTransfer];
    [currentTransfer copyFromTemplate: template withLimits: nil];
    currentTransfer.changeState = TransferChangeNew;
    
    // Determine the remote bank name again.
    NSString *bankName;
    if (transferType == TransferTypeEU) {
        bankName = [[HBCIClient hbciClient] bankNameForBIC: currentTransfer.remoteBIC inCountry: currentTransfer.remoteCountry];
    } else {
        bankName = [[HBCIClient hbciClient] bankNameForCode: currentTransfer.remoteBankCode inCountry: currentTransfer.remoteCountry];
    }
    if (bankName != nil) {
        currentTransfer.remoteBankName = bankName;		   
    }
    return YES;
}

- (void)saveTransfer: (Transfer*)transfer asTemplateWithName: (NSString *)name
{
    if (name == nil) {
        return;
    }
    name = [name stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length == 0) {
        return;
    }
    
	NSManagedObjectContext	*context = templateController.managedObjectContext;
	TransferTemplate *template = [NSEntityDescription insertNewObjectForEntityForName: @"TransferTemplate" inManagedObjectContext: context];
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
    
    // TODO: Save the context?
}

- (BOOL)editingInProgress
{
    return currentTransferController.content != nil;
}

- (void)cancelCurrentTransfer
{
    if ([self editingInProgress]) {
        if (currentTransfer.changeState != TransferChangeNew) {
            currentTransfer.changeState = TransferChangeUnchanged;
        }
        currentTransferController.content = nil;
        if (currentTransferController.managedObjectContext.hasChanges) {
            [currentTransferController.managedObjectContext rollback];
        }
        currentTransfer = nil;
    }
}

/**
 * Validates the values entered for the current transfer and if everything seems correct
 * commits the changes.
 * Returns YES if the current transfer could be finished, otherwise (e.g. for validation errors) NO.
 */
- (BOOL)finishCurrentTransfer
{
    if (![self validateCurrentTransfer]) {
        return NO;
    }
    
    // Change the transfer's type to a terminated transfer if a valuta date is given.
    // TODO: solve terminated transfers differently. There are too many combinations possible as that
    //       a single transfer type could cover all of them.
    //       Should probably either just use the valuta date too in the server or add a new flag.
    if (currentTransfer.valutaDate != nil) {
        currentTransfer.type = [NSNumber numberWithInt: TransferTypeDated];
    }
    
	[currentTransferController commitEditing];
    
    NSError *error = nil;
	NSManagedObjectContext	*context = MOAssistant.assistant.context;
	if (![context save: &error]) {
		NSAlert *alert = [NSAlert alertWithError: error];
		[alert runModal];
		return NO;
	}
	
    currentTransfer.changeState = TransferChangeUnchanged;
    currentTransferController.content = nil;
    
	return YES;
}

/**
 * Checks if the given string contains any character that is not allowed and alerts the
 * user if so.
 */
- (BOOL)validateCharacters: (NSString*)s
{
    NSCharacterSet *cs = [NSCharacterSet characterSetWithCharactersInString: NSLocalizedString(@"AP0", @"")];
    
    if (s == nil || [s length] == 0) {
        return YES;
    }
    
    for (NSUInteger i = 0; i < [s length]; i++) {
        if ([cs characterIsMember: [s characterAtIndex: i]] == NO) {
            NSRunAlertPanel(NSLocalizedString(@"AP170", @""), 
                            NSLocalizedString(@"AP171", @""), 
                            NSLocalizedString(@"ok", @"Ok"), 
                            nil,
                            nil,
                            [s characterAtIndex:i ]);
            return NO;
        }
    }
    return YES;    
}

/**
 * Validation of the entered values. Checks for empty or invalid entries.
 * Returns YES if all entries are ok, otherwise NO.
 */
- (BOOL)validateCurrentTransfer
{
	BOOL res;
	NSNumber *value;
    TransferType activeType = transferType;
    if (currentTransfer.valutaDate != nil) {
        activeType = TransferTypeDated;
    }
    
    if (![self validateCharacters: currentTransfer.purpose1]) {
        return NO;
    }
    if (![self validateCharacters: currentTransfer.purpose2]) {
        return NO;
    }
    if (![self validateCharacters: currentTransfer.purpose3]) {
        return NO;
    }
    if (![self validateCharacters: currentTransfer.purpose4]) {
        return NO;
    }
    if (![self validateCharacters: currentTransfer.remoteName]) {
        return NO;
    }
    
	if(currentTransfer.remoteName == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP8", @"Please enter a receiver"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	// do not check remote account for EU transfers, instead IBAN
	if (activeType != TransferTypeEU && activeType != TransferTypeSEPA) {
		if(currentTransfer.remoteAccount == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
							NSLocalizedString(@"AP9", @"Please enter an account number"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	} else {
		// EU or SEPA transfer
		if(currentTransfer.remoteIBAN == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
							NSLocalizedString(@"AP24", @"Please enter a valid IBAN"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
		// check IBAN
		if([[HBCIClient hbciClient ] checkIBAN: currentTransfer.remoteIBAN ] == NO) {
			NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
							NSLocalizedString(@"AP26", @"IBAN is not valid"),
							NSLocalizedString(@"retry", @"Retry"), nil, nil);
			return NO;
		}
	}
	
	if(activeType == TransferTypeStandard || activeType == TransferTypeDated || activeType == TransferTypeDebit) {
		if(currentTransfer.remoteBankCode == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
							NSLocalizedString(@"AP10", @"Please enter a bank code"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	}
	
	if(activeType == TransferTypeSEPA) {
		if(currentTransfer.remoteBIC == nil) {
			NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
							NSLocalizedString(@"AP25", @"Please enter valid bank identification code (BIC)"),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
		}
	}
	
	if( (value = currentTransfer.value) == nil ) {
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
	if (currentTransfer.purpose1 == nil || [currentTransfer.purpose1 length ] == 0) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP121", @"Please enter a purpose"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
    
    // Prüfen, ob das Zieldatum auf ein Wochenende fällt
    if(transferType == TransferTypeDated) {
        NSCalendar *gregorian = [[NSCalendar alloc]
                                 initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *weekdayComponents =
        [gregorian components:NSWeekdayCalendarUnit fromDate:currentTransfer.valutaDate ];
        int weekday = [weekdayComponents weekday];
        if (weekday == 1 || weekday == 7) {
			NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
							NSLocalizedString(@"AP425", @""),
							NSLocalizedString(@"ok", @"Ok"), nil, nil);
			return NO;
        }
    }
	
	if (activeType == TransferTypeEU) {
		NSString	*foreignCurr = [[[countryController selectedObjects ] lastObject ] currency ];
		NSString	*curr = currentTransfer.currency;
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
	if(activeType != TransferTypeEU) {
		// verify accounts, but only for available countries
		if([currentTransfer.remoteCountry caseInsensitiveCompare: @"de" ] == NSOrderedSame ||
		   [currentTransfer.remoteCountry caseInsensitiveCompare: @"at" ] == NSOrderedSame ||
		   [currentTransfer.remoteCountry caseInsensitiveCompare: @"ch" ] == NSOrderedSame ||
		   [currentTransfer.remoteCountry caseInsensitiveCompare: @"ca" ] == NSOrderedSame) {
            
			res = [[HBCIClient hbciClient ] checkAccount: currentTransfer.remoteAccount 
												 forBank: currentTransfer.remoteBankCode 
											   inCountry: currentTransfer.remoteCountry ];
            
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

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Old transfer handling code

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
	
	currentTransfer = [NSEntityDescription insertNewObjectForEntityForName:@"Transfer" inManagedObjectContext: context];
	
	[self prepareTransfer];

	currentTransfer.account = account;
	currentTransfer.currency = account.currency;
	if([currentTransfer.currency isEqualToString: @"" ]) currentTransfer.currency = @"EUR";
	currentTransfer.type = [NSNumber numberWithInt: transferType ];
	
	[currentTransferController setContent: currentTransfer];

/*
	[self preparePurposeFields ];
	if(transferType == TransferTypeLocal) [self hideTransferDate: YES ];
	else [self hideTransferDate: NO ];
*/	
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
	
	if (res == 2) {
		// show log if wanted
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
		BOOL showLog = [defaults boolForKey: @"logForTransfers" ];
		if (showLog) {
			LogController *logController = [LogController logController ];
			[logController showWindow:self ];
			[[logController window ] orderFront:self ];
		}
		
		[[HBCIClient hbciClient ] sendTransfers: [NSArray arrayWithObject: currentTransfer ] ];
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
	[self transferOfType: TransferTypeStandard forAccount: acc ];
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
	
	currentTransfer = tf;
	[self prepareTransfer];
	
	[currentTransferController setContent: tf ];
	
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
    template.type = currentTransfer.type;
	template.remoteAccount = currentTransfer.remoteAccount;
	template.remoteBankCode = currentTransfer.remoteBankCode;
	template.remoteName = currentTransfer.remoteName;
	template.purpose1 = currentTransfer.purpose1;
	template.purpose2 = currentTransfer.purpose2;
	template.purpose3 = currentTransfer.purpose3;
	template.purpose4 = currentTransfer.purpose4;
	template.remoteIBAN = currentTransfer.remoteIBAN;
	template.remoteBIC = currentTransfer.remoteBIC;
	template.remoteCountry = currentTransfer.remoteCountry;
	template.value = currentTransfer.value;
	template.currency = currentTransfer.currency;
	
	[templateField setStringValue:@"" ];
}

-(BOOL)finalizeTransfer
{
	if(transferType == TransferTypeInternal) {
		// get account from combo
		int idx = [accountBox indexOfSelectedItem ];
		if(idx < 0) { NSBeep(); return NO; }
		currentTransfer.remoteAccount = [[internalAccounts objectAtIndex: idx ] accountNumber ];
		currentTransfer.remoteBankCode = [[internalAccounts objectAtIndex: idx ] bankCode ];
		currentTransfer.remoteBankName = account.bankName;
	}
	if(transferType == TransferTypeEU) {
		int idx = [countryButton indexOfSelectedItem ];
		if(idx < 0) { NSBeep(); return NO; }
		currentTransfer.chargedBy = [NSNumber numberWithInt: [chargeBox indexOfSelectedItem ] + 1 ];
	}
	[currentTransferController commitEditing ];
	if([self validateCurrentTransfer ] == NO) return NO;
	
	// save as template (if name given)
	[self saveTemplate ];
	
	return YES;
}

- (IBAction)sendTransfer:(id)sender
{	
	if ([self finalizeTransfer ] == NO) return;
	
	[templatesDraw close: self ];
	[window close ];
	[currentTransferController setContent:nil ];	
	[NSApp stopModalWithCode:2];
}

- (IBAction)transferFinished:(id)sender
{
	if ([self finalizeTransfer ] == NO) return;

	[templatesDraw close: self ];
	[window close ];
	[currentTransferController setContent:nil ];	
	[NSApp stopModalWithCode:0];
}

- (IBAction)nextTransfer:(id)sender
{
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	NSError *error=nil;
	
	if ([self finalizeTransfer ] == NO) return;
	
	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	
	currentTransfer = [NSEntityDescription insertNewObjectForEntityForName:@"Transfer"
											 inManagedObjectContext: context];
	
	// defaults
	if(transferType == TransferTypeDated) {
		int setupTime;
		if(limits) setupTime = [limits minSetupTime ]; else setupTime = 2;
		NSDate	*date = [NSDate dateWithTimeIntervalSinceNow: setupTime*86400 ];
		currentTransfer.date = date;
	}
	
	// set date
	currentTransfer.date = [NSDate date ];

	currentTransfer.account = account;
	currentTransfer.currency = account.currency;
	if([currentTransfer.currency isEqualToString: @"" ]) currentTransfer.currency = @"EUR";
	
	if(transferType == TransferTypeEU) currentTransfer.remoteCountry = selectedCountry; else currentTransfer.remoteCountry = account.country;

	[currentTransferController setContent: currentTransfer ];

	[window makeFirstResponder: [[window contentView ] viewWithTag: 10 ] ];
}

- (IBAction)cancel:(id)sender
{
	[templatesDraw close: self ];
	[window close ];
	[currentTransferController setContent:nil ];	
	[NSApp stopModalWithCode:1];
}

-(BOOL)windowShouldClose:(id)sender
{
    [templatesDraw close ];
	[NSApp stopModalWithCode:1];
	[currentTransferController setContent:nil ];	
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
	
	if([te tag] != 100) return;
	
	if(transferType == TransferTypeEU) {
		bankName = [[HBCIClient hbciClient] bankNameForBIC: [te stringValue] inCountry: currentTransfer.remoteCountry];
	} else {
		bankName = [[HBCIClient hbciClient] bankNameForCode: [te stringValue] inCountry: currentTransfer.remoteCountry];
 	}
	if(bankName) currentTransfer.remoteBankName = bankName;
}

-(void)controlTextDidChange: (NSNotification*)aNotification
{
	NSTextField	*te = [aNotification object ];
	NSUInteger maxLen;
	
	if([te tag ] < 10) maxLen = [limits maxLenPurpose ];
	else if([te tag ] == 10) maxLen = [limits maxLengthRemoteName ];
	else if([te tag ] == 20) maxLen = 52;
	else return;
	
	if ([[te stringValue ] length ] > maxLen) { 
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
		[currentTransfer copyFromTemplate: template withLimits: limits ];
		
		// get Bank Name
		if(transferType == TransferTypeEU) {
			bankName = [[HBCIClient hbciClient  ] bankNameForBIC: currentTransfer.remoteBIC inCountry: currentTransfer.remoteCountry ];
		} else {
			bankName = [[HBCIClient hbciClient  ] bankNameForCode: currentTransfer.remoteBankCode inCountry: currentTransfer.remoteCountry ];
		}
		if(bankName) currentTransfer.remoteBankName = bankName;		
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
	currentTransfer.remoteCountry = selectedCountry;
}

-(void)dealloc
{
	[limits release ];
	[internalAccounts release ];
	[super dealloc ];
}


@end
