/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

#import "PreferenceController.h"
#import "MOAssistant.h"
#import "Keychain.h"
#import "BankingController.h"

#define _newStatementColor @"newStatementColor"
#define _notAssignedColor @"notAssignedColor"
#define _exportSeparator @"exportSeparator"

static NSMutableDictionary *statementColors = nil;
static NSArray *exportFields = nil;

#define SYNCH_HEIGHT 310
#define SEC_HEIGHT 280
#define COLORS_HEIGHT 240
#define EXP_HEIGHT 375
#define PRINT_HEIGHT 200

void updateColorCache()
{
	if(statementColors == nil) statementColors = [NSMutableDictionary dictionaryWithCapacity: 5 ];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	BOOL markNotAssigned = [defaults boolForKey: @"markNAStatements" ];
	if(markNotAssigned) {
		NSData *colorData = [defaults objectForKey: _notAssignedColor ];
		if(colorData == nil) statementColors[_notAssignedColor] = [NSColor colorWithDeviceRed: 0.918 green: 1.0 blue: 0.258 alpha: 1.0 ];
		else statementColors[_notAssignedColor] = [NSKeyedUnarchiver unarchiveObjectWithData: colorData ];
	} else [statementColors removeObjectForKey: _notAssignedColor ];
	BOOL markNewStatements = [defaults boolForKey: @"markNewStatements" ];
	if(markNewStatements) {
		NSData *colorData = [defaults objectForKey: _newStatementColor ];
		if(colorData == nil) statementColors[_newStatementColor] = [NSColor colorWithDeviceRed: 0.207 green: 0.684 blue: 0.984 alpha: 1.0 ];
		else statementColors[_newStatementColor] = [NSKeyedUnarchiver unarchiveObjectWithData: colorData ];
	} else [statementColors removeObjectForKey: _newStatementColor ];
}

@implementation PreferenceController

-(id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	mainWindow = nil;
	colorsChanged = NO;
	exportFields = @[@"valutaDate", @"date", @"value", @"saldo", @"currency", @"localAccount", 
					@"localBankCode", @"localName", @"localCountry",
					@"localSuffix", @"remoteName", @"floatingPurpose", @"note", @"remoteAccount", @"remoteBankCode", 
					@"remoteBankName", @"remoteBankLocation", @"remoteIBAN", @"remoteBIC", @"remoteSuffix",
					@"customerReference", @"bankReference", @"transactionText", @"primaNota",
					@"transactionCode", @"categoriesDescription"];
	return self;
}

-(void)awakeFromNib
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	NSArray	*fields = [defaults objectForKey: @"Exporter.fields" ];
	if(fields != nil) {
		NSTableColumn *col = [fieldTable tableColumns ][0];
		NSComboBoxCell *cell = [col dataCell ];
		
		for(NSString *field in fields) {
			int idx = [exportFields indexOfObject:field ];
			NSString* name = [cell itemObjectValueAtIndex: idx ];
			NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObject:name forKey:@"fieldName" ];
			[fieldController addObject: item ];
		}
	}
	MOAssistant *assistant = [MOAssistant assistant ];
	encrypt = [assistant encrypted];
	[self setValue: @([assistant encrypted ]) forKey: @"encrypt" ];
    
    // erstes Tab setzen
    [toolBar setSelectedItemIdentifier: @"synch" ];
    [mainTab selectTabViewItemAtIndex:0 ];
    [mainTab setTabViewType:NSNoTabsNoBorder ];
    
    [self setHeight: SYNCH_HEIGHT];
    
    // Export-Feldseparator
    NSString *expSep = [defaults stringForKey:_exportSeparator ];
    if (expSep) {
        if ([expSep isEqualToString:@"\t"]) {
            [expRadioMatrix setState:NSOnState atRow:0 column:0];
        }
        if ([expSep isEqualToString:@";"]) {
            [expRadioMatrix setState:NSOnState atRow:1 column:0];
        }
        if ([expSep isEqualToString:@"|"]) {
            [expRadioMatrix setState:NSOnState atRow:2 column:0];
        }
    }

    // Fix icons in the toolbar. Those in subfolders of the Resources folder are not found automatically.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSToolbarItem *item in toolBar.items) {
        NSString *path = [[NSBundle mainBundle] pathForResource: item.image.name
                                                         ofType: @"icns"
                                                    inDirectory: @"Collections/1"];
        if ([fileManager fileExistsAtPath: path]) {
            item.image = [[NSImage alloc] initWithContentsOfFile: path];
        }

    }
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	int idx;
	NSArray	*content = [fieldController content ];
	NSArray	*columns = [fieldTable tableColumns ];
	NSMutableArray	*fields = [NSMutableArray arrayWithCapacity: 25 ];
	
	NSTableColumn *col = columns[0];
	NSComboBoxCell *cell = [col dataCell ];
	
	for (NSDictionary *dict in content) {
		idx = [cell indexOfItemWithObjectValue: [dict valueForKey: @"fieldName" ] ];
		if(idx >=0) [fields addObject: exportFields[idx] ];
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
	MOAssistant *assistant = [MOAssistant assistant ];
    [assistant relocate];
}

-(IBAction)encryptData: (id)sender
{
    if (encrypt) {
        // check if passwort is already defined. If yes, it must(!) be taken
		NSString *passwd = [Keychain passwordForService:@"Pecunia" account:@"DataFile" ];
		if (passwd != nil) {
			[passw1Field setStringValue:passwd ];
			[passw2Field setStringValue:passwd ];
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
			if([assistant stopEncryption ])	{
                [[BankingController controller ] setEncrypted: NO ];
                [Keychain deletePasswordForService:@"Pecunia" account:@"DataFile"];
                NSRunAlertPanel(NSLocalizedString(@"AP46", @""),
                                NSLocalizedString(@"AP188", @""),
                                NSLocalizedString(@"ok", @"Ok"),
                                nil,
                                nil);

            }
		}
    }
}

- (void)sheetDidEnd: (NSWindow*)sheet
		 returnCode: (int)code
		contextInfo: (void*)context
{
	if(code == 0) {
		// now create 
		MOAssistant *assistant = [MOAssistant assistant];
		if([assistant encryptDataWithPassword: password]) {
			[encryptButton setEnabled: NO ];
			[[BankingController controller ] setEncrypted: YES ];
            NSRunAlertPanel(NSLocalizedString(@"AP46", @""),
                            NSLocalizedString(@"AP189", @""),
                            NSLocalizedString(@"ok", @"Ok"),
                            nil,
                            nil);
			return;
		}
	}
	// No success
	[self setValue: @NO forKey: @"encrypt" ];
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
	
	password = passw1;
	[encryptionSheet orderOut: sender ];
	[NSApp endSheet: encryptionSheet returnCode: 0 ];
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

-(void)setHeight:(int)h
{
    NSWindow *window = [self window ] ;
    NSRect frame = [window frame ];
    [contentView removeFromSuperview ];
    int pos = frame.origin.y + frame.size.height;
    frame.size.height = h;
    frame.origin.y = pos - h;
    [window setFrame:frame display:YES animate:YES ];
    [window setContentView:contentView ];
}

-(IBAction)synchSettings:(id)sender
{
    [mainTab selectTabViewItemAtIndex:0 ];
    [self setHeight: SYNCH_HEIGHT ];
}

-(IBAction)securitySettings:(id)sender
{
    [mainTab selectTabViewItemAtIndex:1 ];    
    [self setHeight: SEC_HEIGHT ];
}

- (IBAction)colorSettings:(id)sender {
    [mainTab selectTabViewItemAtIndex: 2];
    [self setHeight: COLORS_HEIGHT];
}

-(IBAction)exportSettings:(id)sender
{
    [mainTab selectTabViewItemAtIndex: 3];
    [self setHeight: EXP_HEIGHT ];
}

-(IBAction)printSettings:(id)sender
{
    [mainTab selectTabViewItemAtIndex: 4];
    [self setHeight: PRINT_HEIGHT ];
}

-(void)tabView:(NSTabView*)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window ] setTitle:[tabViewItem label ] ];
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
	return statementColors[_notAssignedColor];
}

+(NSColor*)newStatementRowColor
{
	if(statementColors == nil) updateColorCache();
	return statementColors[_newStatementColor];
}

+ (BOOL)showCategoryColorsInTree
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey: @"showCatColorsInTree"];
}

@end
