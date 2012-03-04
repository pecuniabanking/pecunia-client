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

#import "NewBankUserController.h"
#import "ABController.h"
#import "User.h"
#import "BankingController.h"
#import "InstitutesController.h"
#import "HBCIClient.h"
#import "PecuniaError.h"
#import "LogController.h"
#import "BankParameter.h"
#import "BankInfo.h"
#import "BankAccount.h"
#import "MOAssistant.h"

#import "AnimationHelper.h"

NSString *hbciVersionFromString(NSString* s)
{
	if([s isEqualToString: @"2.2"]) return @"220";
	if([s isEqualToString: @"3.0"]) return @"300";
	if([s isEqualToString: @"4.0"]) return @"400";
	return @"220";
}

@interface NewBankUserController (Private)

- (void)readBanks;
- (BOOL)check;

@end

@implementation NewBankUserController

- (id)initForController: (BankingController*)con
{
	self = [super initWithWindowNibName:@"BankUser"];
	bankController = con;
	bankUsers = [[[HBCIClient hbciClient] users] mutableCopy];
    currentUser = [[User alloc ] init ];
	currentUser.hbciVersion = @"220";
	
	[self readBanks];
	return self;
}

- (void)dealloc
{
	[bankUsers release];
    [institutesController release];
	[banks release];
	[super dealloc];
}

- (void)awakeFromNib
{
	[hbciVersions setContent:[[HBCIClient hbciClient] supportedVersions]];
	[hbciVersions setSelectedObjects:[NSArray arrayWithObject:@"220"]];
}

#pragma mark -
#pragma mark Data handling

- (void)readBanks
{
	banks = [[NSMutableArray arrayWithCapacity: 5000] retain];
	
	NSString *path = [[NSBundle mainBundle] resourcePath];
	path = [path stringByAppendingString: @"/Institute.csv"];
	
	NSError *error=nil;
	NSString *s = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error];
	if(error) {
        [[MessageLog log ] addMessage:@"Error reading institutes file" withLevel:LogLevel_Error];
	} else {
		NSArray *institutes = [s componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
		NSArray *keys = [NSArray arrayWithObjects: @"bankCode", @"bankName", @"bankLocation", @"hbciVersion", @"bankURL", nil];
		for(s in institutes) {
			NSArray *objs = [s componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\t"]];
			if ([objs count] != 5) continue;
			NSDictionary *dict = [NSDictionary dictionaryWithObjects: objs forKeys: keys];
			[banks addObject: dict];
		}
	}
}

-(User*)selectedUser
{
	NSArray	*selection = [bankUserController selectedObjects];
	if (selection == nil || [selection count] < 1) {
        return nil;
    }
	return [selection lastObject];
}

#pragma mark -
#pragma mark Window/sheet handling

- (void)bankUrlSheetDidEnd: (NSWindow*)sheet
                returnCode: (int)code 
               contextInfo: (void*)context
{
    /*
	int result = [NSApp runModalForWindow: [controller window]];
	if(result == 0) {
		NSDictionary *dict = [controller selectedBank];
		if(dict) {
			[currentUser setBankURL: [dict valueForKey: @"bankURL"]];
			// HBCI version
			currentUser.hbciVersion = hbciVersionFromString([dict valueForKey: @"hbciVersion"]);
		}
	}
	[[self window] makeKeyAndOrderFront: self];
     */
    
}

- (void)userSheetDidEnd: (NSWindow*)sheet
			 returnCode: (int)code 
			contextInfo: (void*)context
{
	HBCIClient *hbciClient = [HBCIClient hbciClient];
	if(code == 0) {
		currentUser.hbciVersion = [[hbciVersions selectedObjects] lastObject];
		PecuniaError *error = [hbciClient addBankUser: currentUser];
		if (error) {
			[error alertPanel];
		}
		else {
			[bankUserController addObject:currentUser];
			[bankController updateBankAccounts: [hbciClient getAccountsForUser:currentUser]];

			[currentUser autorelease];
			currentUser = [[User alloc ] init];
			currentUser.hbciVersion = @"220";
			[objController setContent:currentUser];
		}
	}
}

- (void)cancelSheet:(id)sender
{
	[userSheet orderOut: sender];
	[NSApp endSheet: userSheet returnCode: 1];
}

- (void)endSheet: (id)sender
{
	[objController commitEditing];
	if([self check] == NO) return;
	[userSheet orderOut: sender];
	[NSApp endSheet: userSheet returnCode: 0];
}

- (BOOL)windowShouldClose:(id)sender
{
	[NSApp stopModalWithCode: 1];
	return YES;
}

#pragma mark -
#pragma mark Input handling

- (BOOL)check
{
	if ([currentUser bankCode] == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
						NSLocalizedString(@"AP2", @"Please enter bank code"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	if ([currentUser userId] == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
						NSLocalizedString(@"AP3", @"Please enter user id"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
    /*
	if ([currentUser bankURL] == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP6", @"Please enter bank server URL"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
     */
	return YES;
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextField	*te = [aNotification object];
	NSString *bankCode = [te stringValue];
	
	BankInfo *bi = [[HBCIClient hbciClient] infoForBankCode: bankCode inCountry: @"DE"];
	if (bi) {
		[currentUser setValue: bi.name forKey: @"bankName"];
		[currentUser setBankURL:bi.pinTanURL];
	}
	if (bi.pinTanURL == nil) {
		NSDictionary* dict;
		for(dict in banks) {
			if ([bankCode isEqualToString: [dict valueForKey: @"bankCode"]]) {
				[currentUser setBankURL: [dict valueForKey: @"bankURL"]];
				currentUser.hbciVersion = hbciVersionFromString([dict valueForKey: @"hbciVersion" ]);
				break;
			}
		}
	}
}

#pragma mark -
#pragma mark IB action section

- (IBAction)close:(id)sender
{
    [[self window] orderOut: self];
}

- (IBAction)add:(id)sender
{
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

- (IBAction)selectBankUrl: (id)sender
{
    if (selectBankUrlSheet == nil) {
        institutesController = [[InstitutesController alloc] init];
        [institutesController setBankData: banks];
        selectBankUrlSheet = [institutesController window];
    }
    
	[NSApp beginSheet: selectBankUrlSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(bankUrlSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: NULL];

}

- (IBAction)removeEntry:(id)sender
{
	User* user = [self selectedUser];
	if (user == nil) return;
	
	if([[HBCIClient hbciClient] deleteBankUser: user] == TRUE) {
        // remove userId from all related bank accounts
        NSError *error=nil;
        NSManagedObjectContext *context = [[MOAssistant assistant] context];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:context];
        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"bankCode = %@ AND userId = %@", user.bankCode, user.userId];
        [request setPredicate:predicate];
        NSArray *accounts = [context executeFetchRequest:request error:&error];
        if (error == nil) {
            for (BankAccount *account in accounts) {
                account.userId = nil;
                account.customerId = nil;
            }
        }
		[bankUserController remove: self];
	}
}

- (IBAction)getUserAccounts: (id)sender
{
	User *user = [self selectedUser];
	if(user == nil) return;

	[bankController updateBankAccounts: [[HBCIClient hbciClient] getAccountsForUser:user]];

	NSRunAlertPanel(NSLocalizedString(@"AP27", @""),
					NSLocalizedString(@"AP107", @""),
					NSLocalizedString(@"ok", @"Ok"), 
					nil, nil,
					user.userId);
	
}

-(IBAction)changePinTanMethod:(id)sender
{
	User *user = [self selectedUser];
	if(user == nil) return;
	 PecuniaError *error = [[HBCIClient hbciClient] changePinTanMethodForUser:user];
	if (error) {
		[error alertPanel];
	}
}

-(IBAction)printBankParameter:(id)sender
{
	User *user = [self selectedUser];
	if (user == nil) return;
	LogController *logController = [LogController logController];
	MessageLog *messageLog = [MessageLog log];
//	[[logController window] makeKeyAndOrderFront:self];
	[logController showWindow:self];
	[logController setLogLevel:LogLevel_Info];
	BankParameter *bp = [[HBCIClient hbciClient] getBankParameterForUser: user];
	if (bp == nil) {
		[messageLog addMessage:@"Bankparameter konnten nicht ermittelt werden" withLevel:LogLevel_Error];
		return;
	}
	[messageLog addMessage:@"Bankparameterdaten:" withLevel:LogLevel_Info];
    [messageLog addMessage: bp.bpd_raw withLevel:LogLevel_Notice];
    
	[messageLog addMessage:@"Anwenderparameterdaten:" withLevel:LogLevel_Info];
    [messageLog addMessage: bp.upd_raw withLevel:LogLevel_Notice];
}


- (IBAction)updateBankParameter: (id)sender
{
	User *user = [self selectedUser];
	if(user == nil) return;
	
	PecuniaError *error = [[HBCIClient hbciClient] updateBankDataForUser: user];
	if(error) [error alertPanel];
	else NSRunAlertPanel(NSLocalizedString(@"AP27", @"Success"), 
						 NSLocalizedString(@"AP28", @"Bank parameter have been updated successfully"), 
						 NSLocalizedString(@"ok", @"Ok"), nil, nil);
}

@end
