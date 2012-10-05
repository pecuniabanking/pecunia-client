//
//  NewBankUserController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "NewBankUserController.h"
#import "ABController.h"
#import "User.h"
#import "BankingController.h"
#import "InstitutesController.h"
#include <aqhbci/user.h>

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
	bankUsers = [[bankController abController ] users ];
	currentUser = [[User alloc ] init ];
	[currentUser setValue: [NSNumber numberWithInt: 220 ] forKey: @"hbciVersion" ];
	
	[self readBanks ];
	return self;
}

-(void)readBanks
{
	banks = [[NSMutableArray arrayWithCapacity: 5000 ] retain ];
	
	NSString *path = [[NSBundle mainBundle ] resourcePath ];
	path = [path stringByAppendingString: @"/Institute.csv" ];
	
	NSError *error=nil;
	NSString *s = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error ];
	if(error) {
		NSLog(@"Error reading institutes file");
	} else {
		NSArray *institutes = [s componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet ] ];
		NSArray *keys = [NSArray arrayWithObjects: @"bankCode", @"bankName", @"bankLocation", @"hbciVersion", @"bankURL", nil ];
		for(s in institutes) {
			NSArray *objs = [s componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\t" ] ];
			if ([objs count ] != 5) continue;
			NSDictionary *dict = [NSDictionary dictionaryWithObjects: objs forKeys: keys ];
			[banks addObject: dict ];
		}
	}
}

- (IBAction)cancel:(id)sender
{
	[[self window] close];
}

- (IBAction)add:(id)sender
{
	[[ABController abController ] save ];
	[[self window] close];
}

- (IBAction)addEntry:(id)sender
{
	[NSApp beginSheet: userSheet
	   modalForWindow: [self window ]
		modalDelegate: self
	   didEndSelector: @selector(userSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: NULL ];
}

- (void)userSheetDidEnd: (NSWindow*)sheet
			 returnCode: (int)code 
			contextInfo: (void*)context
{
	if(code == 0) {
		NSString* err = [[bankController abController ] addBankUser: currentUser ]; 
		if(err) NSRunAlertPanel(NSLocalizedString(@"AP7", @"HBCI error occured!"), 
								NSLocalizedString(@"AP73", @""), 
								NSLocalizedString(@"cancel", @"Cancel"), nil, nil);
		else {
			bankUsers = [[bankController abController ] getUsers ];
			[bankUserController setContent: bankUsers ];
			[bankController updateBankAccounts ];
		}
	}
}

- (IBAction)removeEntry:(id)sender
{
	NSArray	*sel = [bankUserController selectedObjects ];
	if(sel == nil || [sel count ] < 1) return;
	User* user = [sel objectAtIndex: 0 ];
	
	if([[ABController abController ] removeBankUser: user] == TRUE) {
		[bankUserController remove: self ];
	}
}


- (void)cancelSheet:(id)sender
{
	[userSheet orderOut: sender ];
	[NSApp endSheet: userSheet returnCode: 1 ];
}

- (void)endSheet: (id)sender
{
	[objController commitEditing ];
	if([self check ] == NO) return;
	[userSheet orderOut: sender ];
	[NSApp endSheet: userSheet returnCode: 0 ];
}



-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextField	*te = [aNotification object ];
	NSString *bankCode = [te stringValue ];
	NSString *bankName = [[ABController abController ] bankNameForCode: bankCode
															 inCountry: @"DE" 
		];
	[currentUser setValue: bankName forKey: @"bankName" ];
	NSDictionary *dict;
	for(dict in banks) {
		if([bankCode isEqualToString: [dict valueForKey: @"bankCode" ] ]) {
			[currentUser setBankURL: [dict valueForKey: @"bankURL" ] ];
			// HBCI version
			NSNumber *hbciVersion = hbciVersionFromString([dict valueForKey: @"hbciVersion" ]);
			[currentUser setHbciVersion: hbciVersion ];
			break;
		}
	}
	
/*
	GWEN_BUFFER *tbuf;
	tbuf=GWEN_Buffer_new(0, 256, 0, 1);
	getBankUrl([[ABController abController ] abBankingHandle ], AH_CryptMode_Pintan, [[te stringValue] UTF8String ], tbuf);
	GWEN_Buffer_free(tbuf);	
*/ 
}

-(BOOL)check
{
	if([currentUser bankCode ] == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", "Missing data"),
						NSLocalizedString(@"AP2", "Please enter bank code"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	if([currentUser userId ] == nil) {
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
/*	seems that mediumId is no longer needed
	if([currentUser mediumId ] == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", "Missing data"), 
						NSLocalizedString(@"AP5", "Please enter PIN/TAN id"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
*/
	if([currentUser bankURL ] == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", "Missing data"), 
						NSLocalizedString(@"AP6", "Please enter bank server URL"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	return YES;
}

- (IBAction)getSystemID: (id)sender
{
	NSArray *sel = [bankUserController selectedObjects ];
	if(sel == nil || [sel count ] == 0) return;
	User *user = [sel objectAtIndex: 0 ];
	if(user == nil) return;
	NSString* err = [[ABController abController ] getSystemIDForUser: user ];
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
			[currentUser setBankURL: [dict valueForKey: @"bankURL" ] ];
			// HBCI version
			NSNumber *hbciVersion = hbciVersionFromString([dict valueForKey: @"hbciVersion" ]);
			[currentUser setHbciVersion: hbciVersion ];
		}
	}
	[controller release ];
	[[self window ] makeKeyAndOrderFront: self ];
}


-(BOOL)windowShouldClose:(id)sender
{
	[[ABController abController ] save ];
	[NSApp stopModalWithCode:1];
	return YES;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	User *user;
	// set content of TanMethod ArrayController before selection changes - otherwise it does not work
	@try {
		user = [[bankUserController arrangedObjects ] objectAtIndex: rowIndex ];
	}
	@catch(NSException *xcp) {
		return YES;
	}
	if(user) {
		[tanMethods setContent: [user tanMethodList ] ];
	}
	return YES;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = [aTableColumn identifier ];
	if ([identifier isEqualToString:@"noBase64"]) {
		[aCell setEnabled:NO ];
	}
}

- (void)dealloc
{
	if(currentUser) [currentUser release ];
	[banks release ];
	[super dealloc ];
}

@end
