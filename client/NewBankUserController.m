//
//  NewBankUserController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "NewBankUserController.h"
#import "BankingController.h"
#import "InstitutesController.h"
#import "Passport.h"
#import "HBCIClient.h"
#import "BankInfo.h"
#import "TanMethod.h"
#import "PecuniaError.h"
#import "MOAssistant.h"
#import "BankAccount.h"

static NewBankUserController *current = nil;

NSNumber *hbciVersionFromString(NSString* s)
{
	if([s isEqualToString: @"2.0.1" ]) return [NSNumber numberWithInt: 201 ];
	if([s isEqualToString: @"2.1" ]) return [NSNumber numberWithInt: 210 ];
	if([s isEqualToString: @"2.2" ]) return [NSNumber numberWithInt: 220 ];
	if([s isEqualToString: @"3.0" ]) return [NSNumber numberWithInt: 300 ];
	if([s isEqualToString: @"4.0" ]) return [NSNumber numberWithInt: 400 ];
	return [NSNumber numberWithInt: 220 ];
}


@implementation NewBankUserController

-(id)initForController: (BankingController*)con
{
	self = [super initWithWindowNibName:@"BankUser"];
	bankController = con;
	passports = [[NSMutableArray alloc ] initWithArray: [[HBCIClient hbciClient ] passports ] ];
	
	currentPassport = [[Passport alloc ] init ];
	currentPassport.version = @"plus";
	currentPassport.base64 = YES;
	currentPassport.checkCert = YES;
	
	NSString *path = [[NSBundle mainBundle ] resourcePath ];
	path = [path stringByAppendingString: @"/institutes" ];
	banks = [[NSKeyedUnarchiver unarchiveObjectWithFile: path ] retain ];
	
	current = self;
	return self;
}

- (IBAction)cancel:(id)sender
{
	[[self window] close];
}

-(void)startSpinning
{
//	[progressIndicator setHidden: NO ];
	[progressIndicator setUsesThreadedAnimation: YES];
	[progressIndicator startAnimation: self];
}

-(void)stopSpinning
{
	[progressIndicator stopAnimation: self ];
//	[progressIndicator setHidden: YES ];
}


- (IBAction)addEntry:(id)sender
{
	[NSApp beginSheet: passportSheet
	   modalForWindow: [self window ]
		modalDelegate: self
	   didEndSelector: @selector(userSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: NULL ];
}

- (void)userSheetDidEnd: (NSWindow*)sheet
			 returnCode: (int)code 
			contextInfo: (void*)context
{
	PecuniaError *error = nil;
	if(code == 0) {
		[self startSpinning ];
		[[HBCIClient hbciClient ] addPassport: currentPassport error: &error ]; 
		[self stopSpinning ];
		if(error) [error alertPanel ];
		else {
			[[self window ] makeKeyAndOrderFront:self];
			NSArray *newPassports = [[HBCIClient hbciClient ] passports ];
			[passports removeAllObjects ];
			[passports addObjectsFromArray:newPassports ];
			[passportController setContent: passports ];
			[bankController updateBankAccounts ];
		}
	}
}

- (IBAction)removeEntry:(id)sender
{
	NSManagedObjectModel *model = [[MOAssistant assistant ] model ];
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	BankAccount *account;
	PecuniaError *error=nil;
	NSArray	*sel = [passportController selectedObjects ];
	if(sel == nil || [sel count ] < 1) return;
	Passport* passport = [sel objectAtIndex: 0 ];

	// remove user-IDs from affected bank accounts
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"allBankAccounts"];
	NSArray *bankAccounts = [context executeFetchRequest:request error:&error];
	if( error != nil || bankAccounts == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	for(account in bankAccounts) {
		if ([account.userId isEqualToString: passport.userId ]) {
			account.userId = nil;
		}
	}
	
	[[HBCIClient hbciClient ] deletePassport: passport error:&error];
	if(error) {
		[error alertPanel ];
		return;
	}
	[passportController remove: self ];

	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}


- (void)cancelSheet:(id)sender
{
	[passportSheet orderOut: sender ];
	[NSApp endSheet: passportSheet returnCode: 1 ];
}

- (void)endSheet: (id)sender
{
	[objController commitEditing ];
	if([self check ] == NO) return;
	[passportSheet orderOut: sender ];
	[NSApp endSheet: passportSheet returnCode: 0 ];
}



-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	PecuniaError *error=nil;
	NSTextField	*te = [aNotification object ];
	NSString *bankCode = [te stringValue ];
	HBCIClient *client = [HBCIClient hbciClient ];
	BankInfo *bi = [client infoForBankCode: bankCode error:&error ];

	NSString *bankName = bi.name;
	if(bankName == nil) bankName = NSLocalizedString(@"unknown", "- unbekannt -");
	else currentPassport.bankName = bankName;
	
	if(bi.pinTanVersion) currentPassport.version = bi.pinTanVersion;
	
	if(bi.pinTanURL) currentPassport.host = bi.pinTanURL;
	else {
		NSDictionary *dict;
		for(dict in banks) {
			if([bankCode isEqualToString: [dict valueForKey: @"bankCode" ] ]) {
				currentPassport.host = [dict valueForKey: @"bankURL" ];
				// HBCI version
				currentPassport.version = [dict valueForKey: @"hbciVersion" ];
				break;
			}
		}
		
	}
}

-(BOOL)check
{
	if(currentPassport.bankCode == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", "Missing data"),
						NSLocalizedString(@"AP2", "Please enter bank code"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	if(currentPassport.userId == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", "Missing data"),
						NSLocalizedString(@"AP3", "Please enter user id"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
/* seems that customer id is not always needed	
	if([currentUser customerId ] == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", "Missing data"), 
						NSLocalizedString(@"AP4", "Please enter customer id"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
*/
	if(currentPassport.host == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", "Missing data"), 
						NSLocalizedString(@"AP6", "Please enter bank server URL"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	return YES;
}

- (IBAction)getSystemID: (id)sender
{
	NSArray *sel = [passportController selectedObjects ];
	if(sel == nil || [sel count ] == 0) return;
	Passport *passport = [sel objectAtIndex: 0 ];
	if(passport == nil) return;
	NSString *err = nil;
	if(err) NSRunAlertPanel(NSLocalizedString(@"AP7", @"HBCI error occured!"), err, NSLocalizedString(@"cancel", @"Cancel"), nil, nil);
	else NSRunAlertPanel(NSLocalizedString(@"AP27", @"Success"), 
						 NSLocalizedString(@"AP28", @"SystemID has been transfered successfully"), 
						 NSLocalizedString(@"ok", @"Ok"), nil, nil);
}

-(IBAction)showBanks: (id)sender
{
	InstitutesController *controller = [[InstitutesController alloc ] init ];
	[controller setBankData: banks ];
	NSRect frame = [[self window ] frame ];
	NSPoint pos = frame.origin;
	pos.y += frame.size.height - 100;
	[controller setPosition: pos ];
	int result = [NSApp runModalForWindow: [controller window]];
	if(result == 0) {
		NSDictionary *dict = [controller selectedBank ];
		if(dict) {
			currentPassport.host = [dict valueForKey: @"bankURL" ];
			// HBCI version
			NSString *version = [dict valueForKey: @"hbciVersion" ];
			if([version hasPrefix: @"2" ]) currentPassport.version = @"plus";
			else currentPassport.version = version;
		}
	}
	[controller release ];
	[[self window ] makeKeyAndOrderFront: self ];
}

- (void)dealloc
{
	if(currentPassport) [currentPassport release ];
	[banks release ];
	[passports release ];
	[super dealloc ];
}

+(NewBankUserController*)currentController
{
	return current;
}


@end
