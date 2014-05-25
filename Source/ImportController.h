/**
 * Copyright (c) 2011, 2014, Pecunia Project. All rights reserved.
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

@class BankQueryResult;
@class BWGradientBox;

@class ImportSettings;

@interface ImportController : NSWindowController

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

@end
