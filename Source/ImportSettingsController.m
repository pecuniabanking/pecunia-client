/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#import "ImportSettingsController.h"
#import "ImportSettings.h"
#import "MOAssistant.h"
#import "BankAccount.h"

@implementation ImportSettingsController

-(id)initWitSettings:(ImportSettings*)is
{
	self = [super initWithWindowNibName:@"ImportSettings"];
	if (is == nil) {
		settings = [[ImportSettings alloc ] init ];
		isNew = YES;
	} else {
		settings = is;
		isNew = NO;
	}
	
	importFields = [NSArray arrayWithObjects: @"date", @"localBankCode", @"localAccount", @"localName", @"localSuffix", @"localCountry", 
					@"remoteBankCode", @"remoteBankName", @"remoteBankLocation", @"remoteBIC", @"remoteIBAN", @"remoteAccount", 
					@"remoteSuffix", @"remoteCountry", @"remoteName1", @"remoteName2", @"saldo",
					@"debitCredit", @"transactionText", @"undefined", @"purpose1", @"purpose2", @"purpose3", @"purpose4",
					@"value", @"valutaDate", @"currency", nil ];
	
	managedObjectContext = [[MOAssistant assistant ] context ];
	return self;
}

-(void)awakeFromNib
{
	NSError *error = nil;
	
	if(settings.fields != nil) {
		NSTableColumn *col = [[fieldTable tableColumns ] objectAtIndex:0 ];
		NSComboBoxCell *cell = [col dataCell ];
		
		for(NSString *field in settings.fields) {
			int idx = [importFields indexOfObject:field ];
			NSString* name = [cell itemObjectValueAtIndex: idx ];
			NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObject:name forKey:@"fieldName" ];
			[fieldController addObject: item ];
		}
	}
	[accountsController fetchWithRequest:nil merge:NO error:&error];
	NSArray *accounts = [accountsController arrangedObjects ];
	NSUInteger idx = 0;
	if (isNew == NO) {
		for(BankAccount *account in accounts) {
			if([settings.accountNumber isEqualToString:account.accountNumber ] && [settings.bankCode isEqualToString:account.bankCode ]) {
				[accountsController setSelectionIndex:idx ];
				break;
			}
			idx++;
		}
	}
}



-(IBAction)save:(id)sender
{
	int idx;
	[settingsController commitEditing ];

	NSString *fileName = [NSString stringWithFormat:@"%@/%@.plist", [MOAssistant assistant ].importerDir, settings.name ];
	
	if (isNew) {
		// check if file already exists and issue warning
		if ([[NSFileManager defaultManager ] fileExistsAtPath:fileName ]) {
			int res = NSRunAlertPanel(NSLocalizedString(@"AP16", @""),
									  NSLocalizedString(@"AP122", @""), 
									  NSLocalizedString(@"no", @""), 
									  NSLocalizedString(@"yes", @""), 
									  nil,
									  settings.name);
			if (res == NSAlertDefaultReturn) {
				return;
			}
		}
	}
		
	NSArray	*content = [fieldController content ];
	NSArray	*columns = [fieldTable tableColumns ];
	NSMutableArray	*fields = [NSMutableArray arrayWithCapacity: 25 ];
	
	NSTableColumn *col = [columns objectAtIndex:0 ];
	NSComboBoxCell *cell = [col dataCell ];
	
	for (NSDictionary *dict in content) {
		idx = [cell indexOfItemWithObjectValue: [dict valueForKey: @"fieldName" ] ];
		if(idx >=0) [fields addObject: [importFields objectAtIndex:idx ] ];
	}
	if([fields count ]>0) {
		settings.fields = fields;
	}
	
	NSArray *sel = [accountsController selectedObjects ];
	BankAccount *account = [sel lastObject ];
	if (account) {
		settings.accountNumber = account.accountNumber;
		settings.bankCode = account.bankCode;
	} else {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @""),
						NSLocalizedString(@"AP125", @""), 
						NSLocalizedString(@"ok", @""), 
						nil, 
						nil);
		return;
	}
	
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject: settings ];
	BOOL success = [data writeToFile:fileName atomically:NO ];
	if (success == NO) {
		NSRunCriticalAlertPanel(NSLocalizedString(@"AP123", @""), 
								NSLocalizedString(@"AP124", @""), 
								NSLocalizedString(@"ok", @""), 
								nil,
								nil,
								fileName);
	}
	
	[[self window ] close ];
	[NSApp stopModalWithCode:0 ];
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
    [op setDirectoryURL: [NSURL URLWithString: NSHomeDirectory()]];
	runResult = [op runModal];
	
	if (runResult == NSOKButton) {
		settings.fileName = [[op URL] path];
	}
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	[NSApp stopModalWithCode:1 ];    
}


-(IBAction)cancel:(id)sender
{
	[[self window ] close ];
	[NSApp stopModalWithCode:1 ];
}

@end
