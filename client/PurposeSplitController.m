//
//  PurposeSplitController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 04.08.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "PurposeSplitController.h"
#import "MOAssistant.h"
#import "BankAccount.h"
#import "BankStatement.h"
#import  "PurposeSplitData.h"

@implementation PurposeSplitController

-(id)initWithAccount:(BankAccount*)acc;
{
	self = [super initWithWindowNibName:@"PurposeSplitWindow"];
	context = [[MOAssistant assistant ] context];
	account = acc;
	return self;
}

-(void)awakeFromNib
{
	int idx = 0;
	NSError *error;
    [accountsController fetchWithRequest:nil merge:NO error:&error]; 

	if (account) {
		for (BankAccount *acc in [accountsController arrangedObjects ]) {
			if (acc == account) {
				[comboBox selectItemAtIndex:idx ];
				break;
			} else idx++;
		}
		[self getStatements ];
	}
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	[NSApp stopModalWithCode: actionResult ];
}

-(IBAction)cancel:(id)sender
{
	actionResult = 0;
	[self close ];
}

-(IBAction)ok:(id)sender
{
	NSError *error = nil;
	
	int res = NSRunAlertPanel(NSLocalizedString(@"AP102", @""), 
							  NSLocalizedString(@"AP103", @""),
							  NSLocalizedString(@"no", @"No"), 
							  NSLocalizedString(@"yes", @"Yes"), 
							  nil);

	if(res == NSAlertAlternateReturn) {
		for (PurposeSplitData *data in [purposeController arrangedObjects ]) {
			if (data.purposeNew) data.statement.purpose = data.purposeNew;
			if (data.remoteName) data.statement.remoteName = data.remoteName;
			if (data.remoteAccount) data.statement.remoteAccount = data.remoteAccount;
			if (data.remoteBankCode) data.statement.remoteBankCode = data.remoteBankCode;
		}
		
		// save updates
		if([context save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
		
		actionResult = 0;
		[self close ];
	}
}

-(IBAction)comboChanged:(id)sender
{
	int idx = [comboBox indexOfSelectedItem ];
	if(idx < 0) idx = 0;
	BankAccount *acc = [[accountsController arrangedObjects ] objectAtIndex: idx];
	if (acc) {
		account = acc;
		// fetch new statements
		[self getStatements ];
	}
}

-(void)getStatements
{
	if (account) {
		[purposeController removeObjects:[purposeController arrangedObjects ]];
		for (BankStatement *stat in [account mutableSetValueForKey:@"statements"]) {
			PurposeSplitData *data = [[[PurposeSplitData alloc ] init ] autorelease ];
			data.purposeOld = stat.purpose;
			data.statement = stat;
			[purposeController addObject:data ];
		}
	}
}

-(void)calculate:(id)sender
{
	NSRange eRange;
	NSRange kRange;
	NSRange bRange;
	int     vPos=0;
	
	NSString *s;
	s = [ePosField stringValue ];
	if (s) eRange.location = [s intValue ]; else eRange.location = 0;
	s = [eLenField stringValue ];
	if (s) eRange.length = [s intValue ]; else eRange.length = 0;
	
	s = [kPosField stringValue ];
	if (s) kRange.location = [s intValue ]; else kRange.location = 0;
	s = [kLenField stringValue ];
	if (s) kRange.length = [s intValue ]; else kRange.length = 0;

	s = [bPosField stringValue ];
	if (s) bRange.location = [s intValue ]; else bRange.location = 0;
	s = [bLenField stringValue ];
	if (s) bRange.length = [s intValue ]; else bRange.length = 0;

	s = [vPosField stringValue ];
	if (s) vPos = [s intValue ];
	
	for (PurposeSplitData *data in [purposeController arrangedObjects ]) {
		if (eRange.length) {
			data.remoteName = [[data.purposeOld substringWithRange:eRange ] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet ]];
		}
		if (kRange.length) {
			data.remoteAccount = [[data.purposeOld substringWithRange:kRange ] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet ]];
		}
		if (bRange.length) {
			data.remoteBankCode = [[data.purposeOld substringWithRange:bRange ] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet ]];
		}
		if(vPos) data.purposeNew = [data.purposeOld substringFromIndex:vPos ];
	}
}

@end


