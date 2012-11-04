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


#import "ImportController.h"
#import "MOAssistant.h"
#import "ImportSettingsController.h"
#import "ImportSettings.h"
#import "MessageLog.h"
#import "BankStatement.h"
#import "MCEMDecimalNumberAdditions.h"
#import "BankQueryResult.h"
#import "BankAccount.h"

@implementation ImportController

@synthesize importResult;


-(id)init
{
	self = [super initWithWindowNibName:@"ImportWindow"];
	return self;
}

-(void)updateSettingsController
{
	NSError *error = nil;
	
	NSString *importSettingsPath = [MOAssistant assistant ].importerDir;
	NSFileManager *fileManager = [NSFileManager defaultManager ];
	NSArray *files = [fileManager contentsOfDirectoryAtPath:importSettingsPath error:&error ];
	if (error == nil) {
		NSMutableArray *names = [NSMutableArray arrayWithCapacity:10 ];
		for(NSString *file in files) {
			if ([file hasSuffix:@".plist" ]) {
				[names addObject:[file substringToIndex:[file length ] - 6] ];
			}
		}
		[settingsController setContent:names ];
	}	
}
			
-(void)awakeFromNib
{
	[self updateSettingsController ];
}

-(IBAction)createSettings:(id)sender
{
	ImportSettingsController *controller = [[[ImportSettingsController alloc] initWitSettings: nil] autorelease];
	int res = [NSApp runModalForWindow:[controller window ] ];
	if (res) return;
	[self updateSettingsController ];	
}

-(ImportSettings*)selectedSettings
{
	NSArray *sel = [settingsController  selectedObjects ];
	if (sel == nil) return nil;
	NSString *name = [sel lastObject ];
	if(name == nil) return nil;
	NSString *fileName = [NSString stringWithFormat:@"%@/%@.plist" , [MOAssistant assistant ].importerDir, name ];
	ImportSettings *settings = [NSKeyedUnarchiver unarchiveObjectWithFile: fileName ];	
	if (settings == nil) {
        [[MessageLog log ] addMessage:[NSString stringWithFormat:@"Import settings file not found: %@", fileName ] withLevel:LogLevel_Warning];
	}
	return settings;
}

-(IBAction)changeSettings:(id)sender
{
	ImportSettings *settings = [self selectedSettings ];
	
	ImportSettingsController *controller = [[[ImportSettingsController alloc] initWitSettings: settings] autorelease];
	[NSApp runModalForWindow:[controller window ] ];
}

-(IBAction)cancel:(id)sender
{
	[[self window ] close ];
	[NSApp stopModalWithCode:1 ];
}

-(void)windowWillClose:(NSNotification*)aNotification
{
	[NSApp stopModalWithCode:1 ];    
}

-(IBAction)start:(id)sender
{
	NSError		*error = nil;
	MessageLog	*log = [MessageLog log ];
	BankAccount	*account;
	NSManagedObjectContext *context = [[MOAssistant assistant ] memContext ];
	
	// get settings
	ImportSettings *settings = [self selectedSettings ];
	
	// data file
	NSString *dataFilename = [dataFileField stringValue ];
	if (dataFilename == nil || [dataFilename length ] == 0) {
		dataFilename = settings.fileName;
	}
	if (dataFilename == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP127", @""),
						NSLocalizedString(@"AP126", @""), 
						NSLocalizedString(@"ok", @""), 
						nil, 
						nil);
		return;
	}
	
	if ([[NSFileManager defaultManager ] fileExistsAtPath:dataFilename ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"AP127", @""),
						NSLocalizedString(@"AP128", @""), 
						NSLocalizedString(@"ok", @""), 
						nil, 
						nil,
						dataFilename);
		return;
	}
	
	// get bank account
	account = [BankAccount accountWithNumber:settings.accountNumber subNumber: settings.accountSuffix bankCode:settings.bankCode ];
	
	// Load data file into array
	NSStringEncoding enc = NSISOLatin1StringEncoding;
	if ([settings.charEncodingIndex intValue ] == 1) {
		enc = NSUTF8StringEncoding;
	}
	NSString *content = [NSString stringWithContentsOfFile:dataFilename encoding: enc error: &error ];
	NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet ] ];

    // TODO: check error and show message if needed!
    
	int ignoreLines = 0;
	if (settings.ignoreLines) {
		ignoreLines = [settings.ignoreLines intValue ];
	}
	
	NSMutableArray *statStrings = [NSMutableArray arrayWithCapacity:100 ];
	for (NSUInteger i = ignoreLines; i < [lines count]; i++) {
		[statStrings addObject:[lines objectAtIndex:i ] ];
	}
	
	NSString *sep = @"\t";
	if (settings.sepRadioIndex) {
		int idx = [settings.sepRadioIndex intValue ];
		switch (idx) {
			case 1: sep = @";"; break;
			case 2: sep = @"|"; break;
			case 3: sep = settings.sepChar; break;
		}
		if (sep == nil) sep = @"\t";
	}
	
	NSString *dateFormat = @"dd.MM.yyyy";
	if (settings.dateFormatIndex) {
		int idx = [settings.dateFormatIndex intValue ];
		switch (idx) {
			case 1: dateFormat = @"dd.MM.yy"; break;
			case 2: dateFormat = settings.dateFormatString; break;
		}
		if (dateFormat == nil) dateFormat = @"dd.MM.yyyy";
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc ] init ];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4 ];
	[dateFormatter setDateFormat:dateFormat ];
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc ] init ];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4 ];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle ];
	[numberFormatter setLocale:[NSLocale currentLocale ] ];
	
	NSMutableArray *statements = [NSMutableArray arrayWithCapacity:100 ];
	for(NSString *statString in statStrings) {
		NSArray * fields = [statString componentsSeparatedByString:sep ];
		if ([fields count] < [settings.fields count]) {
			[log addMessage:[NSString stringWithFormat:@"Zeile übersprungen: %@", statString ] withLevel: LogLevel_Warning ];
			continue;
		}
		
		BankStatement *stmt = [NSEntityDescription insertNewObjectForEntityForName:@"BankStatement" inManagedObjectContext:context ];
		
		NSString *debitCredit = nil;
		NSString *remoteName1 = nil;
		NSString *remoteName2 = nil;
		NSString *purpose1 = nil;
		NSString *purpose2 = nil;
		NSString *purpose3 = nil;
		NSString *purpose4 = nil;
		BOOL skipLine = NO;
		
		id value = nil;
		
        // Go through all defined fields. Ignore anything that goes beyond those defined.
		for (NSUInteger i = 0; i < [settings.fields count]; i++) {
			
			NSString *fieldName = [settings.fields objectAtIndex:i ];
			NSString *valueString = [fields objectAtIndex:i ];
			
			if ([valueString hasPrefix:@"\"" ]) {
				valueString = [valueString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"" ] ];
			}

			if ([fieldName isEqualToString:@"undefined" ]) continue;
			if ([fieldName isEqualToString:@"debitCredit" ]) {
				debitCredit = valueString;
				continue;
			}
			if ([fieldName isEqualToString:@"remoteName1" ]) {
				remoteName1 = valueString;
				continue;
			}
			if ([fieldName isEqualToString:@"remoteName2" ]) {
				remoteName2 = valueString;
				continue;
			}
			if ([fieldName isEqualToString:@"purpose1" ]) {
				purpose1 = valueString;
				continue;
			}
			if ([fieldName isEqualToString:@"purpose2" ]) {
				purpose2 = valueString;
				continue;
			}
			if ([fieldName isEqualToString:@"purpose3" ]) {
				purpose3 = valueString;
				continue;
			}
			if ([fieldName isEqualToString:@"purpose4" ]) {
				purpose4 = valueString;
				continue;
			}
			
			if ([fieldName isEqualToString:@"date" ] || [fieldName isEqualToString:@"valutaDate" ]) {
				value = [dateFormatter dateFromString:valueString ];			
				if (value == nil) {
					[log addMessage:[NSString stringWithFormat:@"Datum kann nicht ermittelt werden: %@", valueString ] withLevel: LogLevel_Error ];
					skipLine = YES;
					continue;
				}
			} else if ([fieldName isEqualToString:@"value" ] || [fieldName isEqualToString:@"saldo" ]) {
				value = [numberFormatter numberFromString:valueString ];
				if (value == nil) {
					[log addMessage:[NSString stringWithFormat:@"Wert kann nicht ermittelt werden: %@", valueString ] withLevel: LogLevel_Error ];
					skipLine = YES;
					continue;
				}
				value = [NSDecimalNumber decimalNumberWithDecimal:[value decimalValue ] ];
				value = [value rounded ];
			} else value = valueString;
			
			// Wert setzen
			[stmt setValue:value forKey:fieldName ];
		}
		
		if (skipLine == YES) continue;
		
		// RemoteName
		if (remoteName1) {
			if (remoteName2) {
				stmt.remoteName = [remoteName1 stringByAppendingString:remoteName2 ];
			} else {
				stmt.remoteName = remoteName1;
			}
		}
		
		// Purpose
		if (purpose1) {
			if (purpose2) {
				purpose1 = [purpose1 stringByAppendingString:@"\n" ];
				purpose1 = [purpose1 stringByAppendingString:purpose2 ];
			}
			if (purpose3) {
				purpose1 = [purpose1 stringByAppendingString:@"\n" ];
				purpose1 = [purpose1 stringByAppendingString:purpose3 ];
			}
			if (purpose4) {
				purpose1 = [purpose1 stringByAppendingString:@"\n" ];
				purpose1 = [purpose1 stringByAppendingString:purpose4 ];
			}
			stmt.purpose = purpose1;
		}
		
		// S/H
		if (debitCredit != nil && [debitCredit isEqualToString:@"S" ]) {
			stmt.value = [[NSDecimalNumber zero ] decimalNumberBySubtracting:stmt.value ];
		}

		stmt.localBankCode = settings.bankCode;
		stmt.localAccount = settings.accountNumber;
		
		if (stmt.currency == nil) {
			stmt.currency = account.currency;
		}
		
		[statements addObject:stmt ];
	}
	
	// check sorting of statements and re-sort if necessary
	if ([statements count ] > 0) {
		BankStatement *first = [statements objectAtIndex:0 ];
		BankStatement *last = [statements lastObject ];
		if ([first.date compare: last.date ] == NSOrderedDescending) {
			// resort
			NSMutableArray *newStats = [NSMutableArray arrayWithCapacity:100 ];
			int j;
			for(j = [statements count ]-1; j>=0; j--) {
				[newStats addObject: [statements objectAtIndex:j ] ];
			} 
			statements = newStats;
		}
	}
	
	
	self.importResult = [[[BankQueryResult alloc ] init ] autorelease ];
	self.importResult.statements = statements;
	self.importResult.accountNumber = settings.accountNumber;
	self.importResult.bankCode = settings.bankCode;
	self.importResult.isImport = YES;
	self.importResult.account = account;
	
	[dateFormatter release ];
	[numberFormatter release ];
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
    [op setDirectoryURL: [NSURL fileURLWithPath: NSHomeDirectory() isDirectory: YES]];
	runResult = [op runModal];
	
	if (runResult == NSOKButton) {
		[dataFileField setStringValue: [[op URL] path]];
	}
}

- (void)dealloc
{
	[importResult release], importResult = nil;
	[super dealloc];
}


@end

