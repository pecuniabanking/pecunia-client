/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

@class BankQueryResult;
@class BWGradientBox;

@class ImportSettings;
@class ProcessingPanel;

@interface LinkTextField : NSTextField
@end

@interface FileEntry : NSObject

@property (copy) NSString  *name;
@property (copy) NSString  *path;
@property (assign) BOOL    isFolder;
@property (strong) NSImage *icon;

@property (strong) NSMutableArray *children;

@end

@interface ImportController : NSWindowController {
    IBOutlet NSArrayController *storedSettingsController;
    IBOutlet NSPanel           *newSettingsNameSheet;
    IBOutlet ProcessingPanel   *processingSheet;
    IBOutlet NSTextField       *settingsNameField;
    IBOutlet NSTextField       *dateFormatLinkLabel;
    IBOutlet BWGradientBox     *separatorGradient;
    IBOutlet NSArrayController *accountsController;
    IBOutlet NSPopUpButton     *decimalSeparatorPopupButton;
    IBOutlet NSPopUpButton     *fieldSeparatorPopupButton;
    IBOutlet NSTextField       *customFieldSeparator;
    IBOutlet NSTextField       *customFieldSeparatorLabel;

@private
    NSManagedObjectContext *managedObjectContext;
    NSMutableSet           *fileNames;

    NSFont            *textFont;
    NSString          *currentFile;
    NSArray           *currentLines;
    NSDateFormatter   *dateFormatter;
    NSNumberFormatter *numberFormatter;

    NSMutableArray *parsedValues;
    BOOL           updating;
}

@property (strong) IBOutlet BWGradientBox *backgroundGradient;
@property (strong) IBOutlet BWGradientBox *topGradient;

@property (strong) IBOutlet NSObjectController *importSettingsController;
@property (strong) IBOutlet NSArrayController  *importValuesController;
@property (strong) IBOutlet NSTableView        *importValuesTable;

@property (strong) IBOutlet NSTreeController *fileTreeController;
@property (strong) IBOutlet NSOutlineView    *fileOutlineView;
@property (strong) IBOutlet NSTextView       *ignoredText;
@property (strong) IBOutlet NSTokenField     *tokenField;

@property (strong) IBOutlet NSArrayController *encodingsController;

@property (strong) ImportSettings  *currentSettings;
@property (strong) BankQueryResult *importResult;
@property (strong) NSMutableArray  *importValues;
@property (assign) BOOL            stopProcessing;

- (IBAction)cancel: (id)sender;
- (IBAction)startProcessing: (id)sender;

- (IBAction)addRemoveFile: (id)sender;
- (IBAction)settingSelectionChanged: (id)sender;

@end
