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

#import <Cocoa/Cocoa.h>

@interface PreferenceController : NSWindowController {
	IBOutlet NSArrayController	*fieldController;
	IBOutlet NSTableView		*fieldTable;
	IBOutlet NSWindow			*encryptionSheet;
	IBOutlet NSButton			*encryptButton;
	IBOutlet NSSecureTextField	*passw1Field;
	IBOutlet NSSecureTextField	*passw2Field;
    IBOutlet NSTabView          *mainTab;
    IBOutlet NSToolbar          *toolBar;
    IBOutlet NSMatrix           *expRadioMatrix;
    IBOutlet NSView             *contentView;
	NSWindow					*mainWindow;
	
	// encryption sheet
	NSString	*password;
	BOOL		savePassword;
	BOOL		encrypt;
	BOOL		colorsChanged;
}

-(IBAction)changeFileLocation: (id)sender;

-(IBAction)encryptData: (id)sender;
-(IBAction)cancelSheet:(id)sender;
-(IBAction)endSheet: (id)sender;

-(IBAction)expSepTab:(id)sender;
-(IBAction)expSepSemi:(id)sender;
-(IBAction)expSepLine:(id)sender;

-(IBAction)synchSettings:(id)sender;
-(IBAction)securitySettings:(id)sender;
-(IBAction)exportSettings:(id)sender;
-(IBAction)printSettings:(id)sender;
- (IBAction)colorSettings:(id)sender;

-(IBAction)removePINs: (id)sender;
-(IBAction)colorButtonsChanged: (id)sender;

-(void)setMainWindow: (NSWindow*)main;
-(void)setHeight:(int)h;

+(NSColor*)notAssignedRowColor;
+(NSColor*)newStatementRowColor;

+ (BOOL)showCategoryColorsInTree;

@end
