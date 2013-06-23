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

#import <Cocoa/Cocoa.h>

#import "PXListView.h"

@class BWGradientBox;

@interface ColorListViewCell : PXListViewCell
{
@private
    IBOutlet NSTextField *caption;
    IBOutlet NSColorWell *colorWell;
    IBOutlet NSTextField *htmlText;
    IBOutlet NSTextField *rgbText;
    IBOutlet NSTextField *headerText;

    NSString *colorKey;
    BOOL     showHeader;
}

- (void)configureWithString: (NSString *)config;

@end

@interface PreferenceController : NSWindowController <PXListViewDelegate> {
@private
    IBOutlet NSArrayController *fieldController;
    IBOutlet NSTableView       *fieldTable;
    IBOutlet NSWindow          *encryptionSheet;
    IBOutlet NSButton          *encryptButton;
    IBOutlet NSSecureTextField *passw1Field;
    IBOutlet NSSecureTextField *passw2Field;
    IBOutlet NSTabView         *mainTab;
    IBOutlet NSToolbar         *toolBar;
    IBOutlet NSMatrix          *expRadioMatrix;
    IBOutlet NSView            *contentView;
    IBOutlet PXListView        *colorListView;
    IBOutlet NSTextField       *dataFileField;

    // encryption sheet
    NSString *password;
    BOOL     savePassword;
    BOOL     encrypt;
}

- (IBAction)changeFileLocation: (id)sender;
- (IBAction)restoreFileLocation: (id)sender;
- (IBAction)openFileLocation: (id)sender;

- (IBAction)encryptData: (id)sender;
- (IBAction)cancelSheet: (id)sender;
- (IBAction)endSheet: (id)sender;

- (IBAction)expSepTab: (id)sender;
- (IBAction)expSepSemi: (id)sender;
- (IBAction)expSepLine: (id)sender;

- (IBAction)synchSettings: (id)sender;
- (IBAction)securitySettings: (id)sender;
- (IBAction)locationSettings: (id)sender;
- (IBAction)exportSettings: (id)sender;
- (IBAction)printSettings: (id)sender;
- (IBAction)colorSettings: (id)sender;
- (IBAction)displaySettings: (id)sender;

- (IBAction)removePINs: (id)sender;

- (void)setHeight: (int)h;

// Query settings + related values.
+ (BOOL)showCategoryColorsInTree;
+ (BOOL)showHiddenCategories;
+ (NSString*)mainFontName;
+ (NSString*)mainFontNameBold;
+ (NSString*)mainFontNameLight;
+ (NSString*)popoverFontName;

@end
