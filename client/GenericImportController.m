//
//  GenericImportController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 23.01.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

// This is AqBanking-specific !!

#ifdef AQBANKING
#import "GenericImportController.h"
#import "ABController.h"
#import "BankingController.h"
#import "ImExporter.h"
#import "ImExporterProfile.h"
#import "BankQueryResult.h"
#import "BankAccount.h"
#import "StatusBarController.h"
#import "MOAssistant.h"

@implementation GenericImportController

-(id)init
{
	self = [super initWithWindowNibName:@"GenericImportWindow"];
	isOk = NO;
	managedObjectContext = [[MOAssistant assistant ] context ];
	return self;
}

-(void)awakeFromNib
{
	NSArray *ies = [[ABController controller ] getImExporters ];
	[moduleController setContent:ies ];
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	if(isOk) [NSApp stopModalWithCode:1];
	else [NSApp stopModalWithCode:0];
}

-(IBAction)cancel: (id)sender
{
	[self close ];
}

-(IBAction)choseDataFile: (id)sender
{
	NSOpenPanel *op;
	int runResult;
	
	/* create or get the shared instance of NSSavePanel */
	op = [NSOpenPanel openPanel ];
	
	/* set up new attributes */
	[op setTitle: @"Importdatei wählen" ];
	//	[sp setRequiredFileType:@"txt"];
	
	/* display the NSSavePanel */
	runResult = [op runModalForDirectory:NSHomeDirectory() file:nil];
	
	if (runResult == NSOKButton) {
		[dataFileField setStringValue:[op filename ] ];
	}
}

-(IBAction)import: (id)sender
{
	int selectedModuleIndex = [moduleController selectionIndex ];
	int selectedProfileIndex = [profileController selectionIndex ];
	
	ImExporter *ie = [[moduleController arrangedObjects ] objectAtIndex:selectedModuleIndex ];
	ImExporterProfile *iep = [[profileController arrangedObjects ] objectAtIndex:selectedProfileIndex ];
	
	NSString *dataFileName = [dataFileField	stringValue ];
	
	// check if file exists
	NSFileManager *fm = [NSFileManager defaultManager ];
	if ([fm fileExistsAtPath: dataFileName ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"AP93", @""), 
						NSLocalizedString(@"AP94", @""),
						NSLocalizedString(@"ok", @"Ok"), 
						nil, 
						nil);
		return;
	}
	
	NSMutableArray *accounts = [NSMutableArray arrayWithCapacity:10 ];
	/*	
	 if (account) {
	 BankQueryResult *bqr = [[[BankQueryResult alloc ] init ] autorelease ];
	 bqr.accountNumber = account.accountNumber;
	 bqr.bankCode = account.bankCode;
	 bqr.account = account;
	 [accounts addObject:bqr ];
	 }
	 */ 
	StatusBarController *sc = [StatusBarController controller ];
	[sc startSpinning ];
	[sc setMessage: NSLocalizedString(@"AP95 ", @"Import statements...") removeAfter:0 ];
	
	
	[[ABController controller ] importForAccounts:accounts module:ie profile:iep dataFile:dataFileName ];
	// Check account assignment
	for(BankQueryResult *res in accounts) {
		res.isImport = YES;
		BOOL found = NO;
		if (res.accountNumber) {
			// find account object and assign it
			BankAccount *account = [BankAccount accountWithNumber:res.accountNumber bankCode:res.bankCode ];
			if (account) {
				res.account = account;
				found = YES;
			}
		}
		// no valid account found - take from UI
		if (found == NO) {
			int idx = [accountsController selectionIndex ];
			if (idx == NSNotFound) {
				[[BankingController controller ] statementsNotification: nil ];
				NSRunAlertPanel(NSLocalizedString(@"AP93", @""), 
								NSLocalizedString(@"AP96", @""),
								NSLocalizedString(@"ok", @"Ok"), 
								nil, 
								nil);
				return;
			} else {
				BankAccount *account = [[accountsController arrangedObjects ] objectAtIndex:idx ];
				if (account) {
					res.accountNumber = account.accountNumber;
					res.bankCode = account.bankCode;
					res.account = account;
					found = YES;
				}
			}
		}
		if (found == NO) {
			isOk = NO;
			[self close ];
			[[BankingController controller ] statementsNotification: nil ];
			return;
		}
	}
	
	isOk = YES;
	[self close ];
	[[BankingController controller ] statementsNotification: [accounts retain ] ];
}

@end

#endif