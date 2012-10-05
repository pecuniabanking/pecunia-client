//
//  PreferenceController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 02.02.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "PreferenceController.h"
#import "MOAssistant.h"
#import "HDIWrapper.h"
#import "Keychain.h"
#import "BankingController.h"

#define _newStatementColor @"newStatementColor"
#define _notAssignedColor @"notAssignedColor"
#define _exportSeparator @"exportSeparator"

static NSMutableDictionary *statementColors = nil;
static NSArray *exportFields = nil;


void updateColorCache()
{
	if(statementColors == nil) statementColors = [[NSMutableDictionary dictionaryWithCapacity: 5 ] retain ];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	BOOL markNotAssigned = [defaults boolForKey: @"markNAStatements" ];
	if(markNotAssigned) {
		NSData *colorData = [defaults objectForKey: _notAssignedColor ];
		if(colorData == nil) [statementColors setObject: [NSColor colorWithDeviceRed: 0.918 green: 1.0 blue: 0.258 alpha: 1.0 ] forKey: _notAssignedColor ];
		else [statementColors setObject: [NSKeyedUnarchiver unarchiveObjectWithData: colorData ] forKey: _notAssignedColor ]; 
	} else [statementColors removeObjectForKey: _notAssignedColor ];
	BOOL markNewStatements = [defaults boolForKey: @"markNewStatements" ];
	if(markNewStatements) {
		NSData *colorData = [defaults objectForKey: _newStatementColor ];
		if(colorData == nil) [statementColors setObject: [NSColor colorWithDeviceRed: 0.207 green: 0.684 blue: 0.984 alpha: 1.0 ] forKey: _newStatementColor ];
		else [statementColors setObject: [NSKeyedUnarchiver unarchiveObjectWithData: colorData ] forKey: _newStatementColor ]; 
	} else [statementColors removeObjectForKey: _newStatementColor ];
}

@implementation PreferenceController

-(id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	mainWindow = nil;
	colorsChanged = NO;
	exportFields = [NSArray arrayWithObjects: @"valutaDate", @"date", @"value", @"saldo", @"currency", @"localAccount", 
					@"localBankCode", @"localName", @"localCountry",
					@"localSuffix", @"remoteName", @"floatingPurpose", @"note", @"remoteAccount", @"remoteBankCode", 
					@"remoteBankName", @"remoteBankLocation", @"remoteIBAN", @"remoteBIC", @"remoteSuffix",
					@"customerReference", @"bankReference", @"transactionText", @"primaNota",
					@"transactionCode", @"categoriesDescription", nil ];
	[exportFields retain ];
	return self;
}

-(void)awakeFromNib
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	NSArray	*fields = [defaults objectForKey: @"Exporter.fields" ];
	if(fields != nil) {
		NSTableColumn *col = [[fieldTable tableColumns ] objectAtIndex:0 ];
		NSComboBoxCell *cell = [col dataCell ];
		
		for(NSString *field in fields) {
			int idx = [exportFields indexOfObject:field ];
			NSString* name = [cell itemObjectValueAtIndex: idx ];
			NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObject:name forKey:@"fieldName" ];
			[fieldController addObject: item ];
		}
	}
	MOAssistant *assistant = [MOAssistant assistant ];
	encrypt = [assistant encrypted ];
	[self setValue: [NSNumber numberWithBool: [assistant encrypted ] ] forKey: @"encrypt" ];

//	if(encrypt)	[encryptButton setEnabled: NO ];
}

/*
-(IBAction) ok: (id) sender
{
	int i, idx;
	NSArray	*content = [fieldController content ];
	NSArray	*columns = [fieldTable tableColumns ];
	NSMutableArray	*indxs = [NSMutableArray arrayWithCapacity: 25 ];
	
	NSTableColumn *col = [columns objectAtIndex:0 ];
	NSComboBoxCell *cell = [col dataCell ];
	
	for(i=0; i<[content count ]; i++) {
		NSDictionary	*dict = [content objectAtIndex:i ];
		idx = [cell indexOfItemWithObjectValue: [dict valueForKey: @"fieldName" ] ];
		if(idx >=0) [indxs addObject: [NSNumber numberWithInt:idx ] ];
	}
	if([indxs count ]>0) {
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
		[defaults setObject: indxs forKey: @"Exporter.fields.indices" ];
	}
	[[self window] close];
}
*/
-(void)windowWillClose:(NSNotification *)aNotification
{
	int i, idx;
	NSArray	*content = [fieldController content ];
	NSArray	*columns = [fieldTable tableColumns ];
	NSMutableArray	*fields = [NSMutableArray arrayWithCapacity: 25 ];
	
	NSTableColumn *col = [columns objectAtIndex:0 ];
	NSComboBoxCell *cell = [col dataCell ];
	
	for(i=0; i<[content count ]; i++) {
		NSDictionary	*dict = [content objectAtIndex:i ];
		idx = [cell indexOfItemWithObjectValue: [dict valueForKey: @"fieldName" ] ];
		if(idx >=0) [fields addObject: [exportFields objectAtIndex:idx ] ];
	}
	if([fields count ]>0) {
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
		[defaults setObject: fields forKey: @"Exporter.fields" ];
	}
	if(colorsChanged) {
		updateColorCache();
		[[mainWindow contentView ] display ];
		colorsChanged = NO;
	}
}

-(IBAction)colorButtonsChanged: (id)sender
{
	colorsChanged = YES;
}

/*
-(IBAction) cancel: (id) sender;
{
	[[self window] close];
}
*/
// remove keychain values of all accounts
-(IBAction)removePINs: (id)sender
{
	int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP33", @"Remove PINs from Keychain"),
									  NSLocalizedString(@"AP34", @"All PINs are removed from the Keychain. Do you want to continue?"),
									  NSLocalizedString(@"no", @"No"),
									  NSLocalizedString(@"yes", @"Yes"), nil
									  );
	if(res != NSAlertAlternateReturn) return;
	
	[Keychain deletePasswordsForService:@"Pecunia PIN" ];
}

-(IBAction)changeFileLocation: (id)sender
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	NSString *path = [defaults valueForKey: @"DataDir" ];
	if(path == nil) return; // should not happen

	NSFileManager *fm = [NSFileManager defaultManager ];
	NSOpenPanel *panel = [NSOpenPanel openPanel ];
	[panel setCanChooseFiles: NO ];
	[panel setCanChooseDirectories: YES ];
	
	int result = [panel runModalForDirectory: path file:nil types:nil ];
	
	MOAssistant *assistant = [MOAssistant assistant ];
	BOOL encrypted = [assistant encrypted ];
	if(result == NSOKButton) {
		NSString *oldFilePath, *filePath;
		
		// we assume that encrypt is correct(!)
		if(encrypted)	oldFilePath = [path stringByAppendingString: @"/PecuniaData.sparseimage" ];
		else oldFilePath = [path stringByAppendingString: @"/accounts.sqlite" ];
		
		if(encrypted)	filePath = [[panel filename ] stringByAppendingString: @"/PecuniaData.sparseimage" ];
		else filePath = [[panel filename ] stringByAppendingString: @"/accounts.sqlite" ];
		
		// check if file exists at target
		NSDictionary *attrs = [fm attributesOfItemAtPath: filePath error: NULL ];
		if(attrs) {
			NSDate *date = [attrs objectForKey: NSFileModificationDate ];
			NSDateFormatter *df = [[[NSDateFormatter alloc ] init ] autorelease ];
			[df setDateStyle: NSDateFormatterMediumStyle ];
			[df setTimeStyle: NSDateFormatterMediumStyle ];
			
			// issue a confirmation
			int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP42", @""),
											  NSLocalizedString(@"AP59", @""),
											  NSLocalizedString(@"cancel", @""),
											  NSLocalizedString(@"AP61", @""),
											  NSLocalizedString(@"AP60", @""), 
											  filePath,
											  [df stringFromDate: date  ]
											  );
			
			switch(res) {
				case NSAlertDefaultReturn: return;
				case NSAlertAlternateReturn: {
					// remove existing file
					NSError *error;
					if(![fm removeItemAtPath: filePath error: &error ]) {
						NSAlert *alert = [NSAlert alertWithError:error];
						[alert runModal];
						return;
					}
				}
				default: break;
			}
		}
		
		// now relocation can start
		[defaults setValue: [panel filename ] forKey: @"RelocationPath" ];
		int res = NSRunAlertPanel(NSLocalizedString(@"AP42", @""), 
								  NSLocalizedString(@"AP57", @""),
								  NSLocalizedString(@"yes", @"Yes"), 
								  NSLocalizedString(@"no", @"No"), 
								  nil);
		if(res == NSAlertDefaultReturn) {
			[[BankingController controller ] setRestart ];
			[NSApp terminate: self ];
		}
	}
}

-(IBAction)test: (id) sender
{
/*
	HDIWrapper *wrapper = [HDIWrapper wrapper ];
	
	//[wrapper createImageWithPassword: @"test" ];
	NSString *dataDir = [@"~/Library/Pecunia/PecuniaData.sparseimage" stringByExpandingTildeInPath ];
	[wrapper attachImage: dataDir withPassword: @"test" ];
 */
}

-(IBAction)encryptData: (id)sender
{
	NSFileManager *fm = [NSFileManager defaultManager ];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	NSString *path = [defaults valueForKey: @"DataDir" ];
	path = [path stringByAppendingString: @"/PecuniaData.sparseimage" ];
	BOOL fileExists = [fm fileExistsAtPath: path ];
	
//	BOOL encrypt = ([sender state ] == NSOnState);
	if(encrypt) {
		//  check if there is already an image
		if(fileExists) {
			NSError *error;
			NSDictionary *attrs = [fm attributesOfItemAtPath: path error: &error ];
			NSDate *date = [attrs objectForKey: NSFileModificationDate ];
			NSDateFormatter *df = [[[NSDateFormatter alloc ] init ] autorelease ];
			[df setDateStyle: NSDateFormatterMediumStyle ];
			[df setTimeStyle: NSDateFormatterMediumStyle ];
			int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP46", @""), 
									  NSLocalizedString(@"AP58", @""),
									  NSLocalizedString(@"AP62", @""),
									  NSLocalizedString(@"cancel", @"Cancel"),
									  NSLocalizedString(@"AP60", @""), 
									  path,
									  [df stringFromDate: date  ]
									  );
			
			
			if(res == NSAlertDefaultReturn) {
				// create new file. First rename old file
				NSString *destPath = [[defaults valueForKey: @"DataDir" ] stringByAppendingString: @"/PecuniaData_old.sparseimage" ];
				// if file exists first remove it
				if([fm fileExistsAtPath: destPath ]) {
					BOOL success = [fm removeItemAtPath: destPath error: &error ];
					if(!success) {
						NSAlert *alert = [NSAlert alertWithError:error];
						[alert runModal];
						[sender setState: NO ];
						return;
					}
				}
				// then rename the file
				BOOL success = [fm moveItemAtPath: path toPath: destPath error: &error ];
				if(!success) {
					NSAlert *alert = [NSAlert alertWithError:error];
					[alert runModal];
					[sender setState: NO ];
					return;
				}
			}
			if(res == NSAlertOtherReturn) {
				[defaults setBool: YES forKey: @"forceEncryption" ];
				int res = NSRunAlertPanel(NSLocalizedString(@"AP46", @""), 
										  NSLocalizedString(@"AP63", @""),
										  NSLocalizedString(@"yes", @"Yes"), 
										  NSLocalizedString(@"no", @"No"), 
										  nil);
				if(res == NSAlertDefaultReturn) {
					[[BankingController controller ] setRestart ];
					[NSApp terminate: self ];
				}
				return;
			}
			if(res == NSAlertAlternateReturn) {
				[sender setState: NO ];
				return;
			}
		}
		// check if passwort is already defined. If yes, it must(!) be taken
		NSString *passwd = [Keychain passwordForService:@"Pecunia" account:@"DataFile" ];
		if (passwd != nil) {
			[passw1Field setValue:passwd ];
			[passw2Field setValue:passwd ];
			[passw1Field setEnabled:NO ];
			[passw2Field setEnabled:NO ];
		}
		
		[NSApp beginSheet: encryptionSheet
		   modalForWindow: [self window ]
			modalDelegate: self
		   didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo: NULL ];
	} else {
		int res = NSRunAlertPanel(NSLocalizedString(@"AP46", @""), 
								  NSLocalizedString(@"AP79", @""),
								  NSLocalizedString(@"no", @"No"), 
								  NSLocalizedString(@"yes", @"Yes"), 
								  nil);
		if(res == NSAlertAlternateReturn) {
			MOAssistant *assistant = [MOAssistant assistant ];
			if([assistant stopEncryption ])	[[BankingController controller ] setEncrypted: NO ];
			return;
		} else {
			[self setValue: [NSNumber numberWithBool: YES ] forKey: @"encrypt" ];
		}
	}
}

- (void)sheetDidEnd: (NSWindow*)sheet
		 returnCode: (int)code
		contextInfo: (void*)context
{
	if(code == 0) {
		// now create 
		MOAssistant *assistant = [MOAssistant assistant ];
		if([assistant encryptDataWithPassword: password ]) {
			if(savePassword) [Keychain setPassword: password forService: @"Pecunia" account: @"DataFile" store: YES];
			[encryptButton setEnabled: NO ];
			[[BankingController controller ] setEncrypted: YES ];
			return;
		} 
	}
	// No success
	[self setValue: [NSNumber numberWithBool: NO ] forKey: @"encrypt" ];
}

-(IBAction)cancelSheet:(id)sender
{
	[encryptionSheet orderOut: sender ];
	[NSApp endSheet: encryptionSheet returnCode: 1 ];
}

-(IBAction)endSheet: (id)sender
{
	NSString *passw1 = [passw1Field stringValue ];
	NSString *passw2 = [passw2Field stringValue ];
	if([passw1 length ] < 8) {
		NSRunAlertPanel(NSLocalizedString(@"AP46", @""), 
						NSLocalizedString(@"AP47", @""),
						NSLocalizedString(@"ok", @"Ok"), 
						nil,
						nil);
		return;
	}
	
	if([passw1 isEqualToString: passw2] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"AP46", @""), 
						NSLocalizedString(@"AP48", @""),
						NSLocalizedString(@"ok", @"Ok"), 
						nil,
						nil);
		return;
	}
	
	[password release ];
	password = [passw1 retain ];
	[encryptionSheet orderOut: sender ];
	[NSApp endSheet: encryptionSheet returnCode: 0 ];
}

-(NSColor*)notAssignedColor
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSData *colorData = [defaults objectForKey: _notAssignedColor ];
	if(!colorData) return [NSColor colorWithDeviceRed: 0.918 green: 1.0 blue: 0.258 alpha: 1.0 ];
	return [NSKeyedUnarchiver unarchiveObjectWithData: colorData ];
}

-(void)setNotAssignedColor: (NSColor*)color
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject: color ];
	[defaults setObject: colorData forKey: _notAssignedColor ];
	colorsChanged = YES;
}

-(NSColor*)newStatementColor
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSData *colorData = [defaults objectForKey: _newStatementColor ];
	if(!colorData) return [NSColor colorWithDeviceRed: 0.207 green: 0.684 blue: 0.984 alpha: 1.0 ];
	return [NSKeyedUnarchiver unarchiveObjectWithData: colorData ];
}

-(void)setNewStatementColor: (NSColor*)color
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject: color ];
	[defaults setObject: colorData forKey: _newStatementColor ];
	colorsChanged = YES;
}

+(NSColor*)notAssignedRowColor
{
	if(statementColors == nil) updateColorCache();
	return [statementColors objectForKey: _notAssignedColor ];
}

+(NSColor*)newStatementRowColor
{
	if(statementColors == nil) updateColorCache();
	return [statementColors objectForKey: _newStatementColor ];
}

-(void)setMainWindow: (NSWindow*)main
{
	mainWindow = main;
}

-(IBAction)expSepTab:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	[defaults setObject:@"\t" forKey:_exportSeparator ];
}

-(IBAction)expSepSemi:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	[defaults setObject:@";" forKey:_exportSeparator ];
}

-(IBAction)expSepLine:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	[defaults setObject:@"|" forKey:_exportSeparator ];
}




@end
