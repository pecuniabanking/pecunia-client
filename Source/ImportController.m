/**
 * Copyright (c) 2011, 2015, Pecunia Project. All rights reserved.
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

#import "MessageLog.h"

#import "ImportController.h"
#import "MOAssistant.h"
#import "ImportSettings.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "ShortDate.h"

#import "NSString+PecuniaAdditions.h"
#import "NSAttributedString+PecuniaAdditions.h"

#import "BWGradientBox.h"

#define SAVE_AS_CONTEXT    (void *)1
#define PROCESSING_CONTEXT (void *)2

//----------------------------------------------------------------------------------------------------------------------

@interface LinkTextField : NSTextField
@end

@implementation LinkTextField

- (void)resetCursorRects {
    [self addCursorRect: [self bounds] cursor: [NSCursor pointingHandCursor]];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface FileEntry : NSObject

@property (copy) NSString  *name;
@property (copy) NSString  *path;
@property (assign) BOOL    isFolder;
@property (strong) NSImage *icon;

@property (strong) NSMutableArray *children;

@end

@implementation FileEntry

@synthesize children;

- (id)init {
    self = [super init];
    if (self != nil) {
        children = [NSMutableArray arrayWithCapacity: 10];
    }
    return self;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface ColumnToken : NSObject

@property (copy) NSString *caption;
@property (copy) NSString *property;

@end

@implementation ColumnToken

@end

//----------------------------------------------------------------------------------------------------------------------

@interface Encoding : NSObject

@property (copy) NSString   *caption;
@property (strong) NSNumber *value;

@end

@implementation Encoding

+ (Encoding *)encodingWithCaption: (NSString *)caption andValue: (NSStringEncoding)value {
    Encoding *result = [[Encoding alloc] init];
    result.caption = caption;
    result.value = @((int)value);
    return result;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface ProcessingPanel : NSPanel <NSWindowDelegate> {
@public
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField         *processingTaskLabel;
    IBOutlet NSButton            *startButton;
    IBOutlet NSView              *detailsView;
    IBOutlet NSTextField         *errorsLabel;
    IBOutlet NSTextField         *ignoreLabel;
    IBOutlet NSMatrix            *dateRadioGroup;
    IBOutlet NSDatePicker        *fromDatePicker;
    IBOutlet NSDatePicker        *toDatePicker;
    IBOutlet NSTextField         *dateWarnLabel;
    IBOutlet NSTextField         *toLabel;
    IBOutlet NSTextField         *noDataWarningLabel;

@private
    BOOL done;
}

@property (assign) ImportController *controller;

@end

@implementation ProcessingPanel

@synthesize controller;

- (void)prepare {
    done = NO;

    [detailsView removeFromSuperviewWithoutNeedingDisplay];
    NSRect frame = self.frame;
    frame.size.height = 160; // Original height without details view.
    self.contentSize = frame.size;

    processingTaskLabel.stringValue = NSLocalizedString(@"AP626", nil);
    processingTaskLabel.textColor = [NSColor textColor];
    [dateRadioGroup selectCellAtRow: 0 column: 0];

    fromDatePicker.enabled = NO;
    fromDatePicker.textColor = [NSColor disabledControlTextColor];
    toDatePicker.enabled = NO;
    toDatePicker.textColor = [NSColor disabledControlTextColor];

    noDataWarningLabel.stringValue = NSLocalizedString(@"AP629", nil);
}

- (void)becomeKeyWindow {
    [super becomeKeyWindow];

    if (!done) {
        done = YES;
        startButton.enabled = NO;
        [progressBar startAnimation: self];

        //[controller performSelectorInBackground: @selector(preprocessValues:) withObject: nil];
        [controller performSelector: @selector(preprocessValues:) withObject: nil];
    }
}

- (void)preprocessingDoneWithErrorCount: (NSUInteger)errors
                           ignoredCount: (NSUInteger)ignored
                                minDate: (NSDate *)minDate
                                maxDate: (NSDate *)maxDate
                            canContinue: (BOOL)flag {
    if (minDate == nil) { // If a min date is set then there's always also a max date.
        dateWarnLabel.hidden = NO;
        toLabel.hidden = YES;
        dateRadioGroup.hidden = YES;
        fromDatePicker.hidden = YES;
        toDatePicker.hidden = YES;

        startButton.enabled = NO;
        noDataWarningLabel.hidden = YES;
    } else {
        dateWarnLabel.hidden = YES;
        toLabel.hidden = NO;
        dateRadioGroup.hidden = NO;
        fromDatePicker.hidden = NO;
        toDatePicker.hidden = NO;

        fromDatePicker.minDate = minDate;
        fromDatePicker.maxDate = maxDate;
        fromDatePicker.dateValue = minDate;
        toDatePicker.minDate = minDate;
        toDatePicker.maxDate = maxDate;
        toDatePicker.dateValue = maxDate;

        startButton.enabled = flag;
        noDataWarningLabel.hidden = flag;
    }

    if (errors == 0) {
        errorsLabel.stringValue = NSLocalizedString(@"AP18", nil);
    } else {
        errorsLabel.stringValue = [NSString stringWithFormat: @"%lu", errors];
    }

    if (ignored == 0) {
        ignoreLabel.stringValue = NSLocalizedString(@"AP18", nil);
    } else {
        ignoreLabel.stringValue = [NSString stringWithFormat: @"%lu", ignored];
    }

    [progressBar stopAnimation: self];
    processingTaskLabel.stringValue = NSLocalizedString(@"AP627", nil);

    NSRect frame = self.frame;
    frame.size.height += detailsView.bounds.size.height;
    [self setFrame: frame display: YES animate: YES];

    CGFloat detailsPosition = progressBar.frame.origin.y + progressBar.frame.size.height + 10;

    [self.contentView addSubview: detailsView];
    detailsView.frame = NSMakeRect(0, detailsPosition, detailsView.frame.size.width, detailsView.frame.size.height);
}

- (void)preprocessingDoneWithFatalError {
    [progressBar stopAnimation: self];
    processingTaskLabel.stringValue = NSLocalizedString(@"AP628", nil);
    processingTaskLabel.textColor = [NSColor redColor];
}

- (IBAction)back: (id)sender {
    // Back from processing to settings page.
    [NSApp endSheet: self returnCode: NSRunAbortedResponse];
}

- (IBAction)readyForImport: (id)sender {
    // Everything has been checked. We can start importing.
    [NSApp endSheet: self returnCode: NSRunStoppedResponse];
}

- (IBAction)dateRangeChanged: (id)sender {
    BOOL customDateRange = dateRadioGroup.selectedColumn == 1;
    if (customDateRange) {
        fromDatePicker.enabled = YES;
        toDatePicker.enabled = YES;
        fromDatePicker.textColor = [NSColor controlTextColor];
        toDatePicker.textColor = [NSColor controlTextColor];
    } else {
        fromDatePicker.enabled = NO;
        toDatePicker.enabled = NO;
        fromDatePicker.textColor = [NSColor disabledControlTextColor];
        toDatePicker.textColor = [NSColor disabledControlTextColor];
    }
}

- (IBAction)dateChanged: (id)sender {
    if (sender == fromDatePicker) {
        toDatePicker.minDate = fromDatePicker.dateValue;
    } else {
        fromDatePicker.maxDate = toDatePicker.dateValue;
    }
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface ImportController ()  {
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

@end

@implementation ImportController

@synthesize backgroundGradient;
@synthesize topGradient;
@synthesize importValuesController;
@synthesize importValuesTable;
@synthesize fileTreeController;
@synthesize fileOutlineView;
@synthesize ignoredText;
@synthesize tokenField;
@synthesize importResult;
@synthesize importValues;
@synthesize currentSettings;
@synthesize importSettingsController;
@synthesize encodingsController;
@synthesize stopProcessing;

#pragma mark -
#pragma mark Initialization

- (id)init {
    self = [super initWithWindowNibName: @"ImportWindow"];
    if (self != nil) {
        importValues = [NSMutableArray arrayWithCapacity: 10];
        textFont = [NSFont fontWithName: @"AndaleMono" size: 11];

        managedObjectContext = MOAssistant.sharedAssistant.context; // For the accounts list.
        fileNames = [NSMutableSet setWithCapacity: 10];
    }
    return self;
}

- (void)dealloc {
    [importSettingsController removeObserver: self forKeyPath: @"selection.isDirty"];
}

- (void)awakeFromNib {
    processingSheet.controller = self;

    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
    dateFormatter.dateFormat = @"dd.MM.yyyy";

    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    [numberFormatter setLocale: [NSLocale currentLocale]];

    backgroundGradient.fillColor = [NSColor whiteColor];
    topGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    topGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];
    separatorGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    separatorGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];

    [[ignoredText textContainer] setContainerSize: NSMakeSize(FLT_MAX, FLT_MAX)];
    [[ignoredText textContainer] setWidthTracksTextView: NO];
    [ignoredText setHorizontallyResizable: YES];
    [ignoredText setFont: textFont];

    [self setupTokenField];
    [self setupEncodings];

    [importValuesTable registerForDraggedTypes: @[NSPasteboardTypeString]];
    [fileOutlineView registerForDraggedTypes: @[(NSString *)kUTTypeFileURL]];

    // Make the date format label a link to the format description. The following two settings are necessary to make this work.
    [dateFormatLinkLabel setAllowsEditingTextAttributes: YES];
    [dateFormatLinkLabel setSelectable: YES];
    NSString *help = NSLocalizedString(@"AP624", nil);
    [dateFormatLinkLabel setAttributedStringValue: [NSAttributedString stringFromHTML: help withFont: [dateFormatLinkLabel font]]];

    [self performSelector: @selector(initialSelection) withObject: nil afterDelay: 0.1 inModes: @[NSModalPanelRunLoopMode]];
}

/**
 * Initializes the token field with predefined tokens. These cannot be edited.
 */
- (void)setupTokenField {
    NSMutableArray *tokens = [NSMutableArray arrayWithCapacity: 20];
    ColumnToken    *token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP604", nil);
    token.property = @"valutaDate";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP605", nil);
    token.property = @"date";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP606", nil);
    token.property = @"value";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP607", nil);
    token.property = @"remoteName";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP608", nil);
    token.property = @"remoteIBAN";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP609", nil);
    token.property = @"remoteBIC";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP610", nil);
    token.property = @"remoteBankCode";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP611", nil);
    token.property = @"remoteBankName";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP612", nil);
    token.property = @"remoteAccount";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP613", nil);
    token.property = @"remoteCountry";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP614", nil);
    token.property = @"purpose";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP615", nil);
    token.property = @"remoteSuffix";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP616", nil);
    token.property = @"transactionText";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP617", nil);
    token.property = @"currency";
    [tokens addObject: token];

    token = [[ColumnToken alloc] init];
    token.caption = NSLocalizedString(@"AP618", nil);
    token.property = @"";
    [tokens addObject: token];

    [tokenField setObjectValue: tokens];
}

/**
 * Initializes the encodings list.
 */
- (void)setupEncodings {
    NSMutableArray *encodings = [NSMutableArray arrayWithCapacity: 20];

    [encodings addObject: [Encoding encodingWithCaption: @"ASCII" andValue: NSASCIIStringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"UTF-8" andValue: NSUTF8StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"ISO Latin 1" andValue: NSISOLatin1StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"ISO Latin 2" andValue: NSISOLatin2StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"Windows CP1251 (Cyrillic)" andValue: NSWindowsCP1251StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"Windows CP1252 (Latin 1)" andValue: NSWindowsCP1252StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"Windows CP1253 (Greek)" andValue: NSWindowsCP1253StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"Windows CP1254 (Turkish)" andValue: NSWindowsCP1254StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"Windows CP1250 (Latin 2)" andValue: NSWindowsCP1250StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"MacOS Roman" andValue: NSMacOSRomanStringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"UTF-16" andValue: NSUTF16StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"UTF-16 Big Endian" andValue: NSUTF16BigEndianStringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"UTF-16 Little Endian" andValue: NSUTF16LittleEndianStringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"UTF-32" andValue: NSUTF32StringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"UTF-32 Big Endian" andValue: NSUTF32BigEndianStringEncoding]];
    [encodings addObject: [Encoding encodingWithCaption: @"UTF-32 Little Endian" andValue: NSUTF32LittleEndianStringEncoding]];

    encodingsController.content = encodings;
}

/**
 * Need to delay this for the managed object context to finish fetching.
 */
- (void)initialSelection {
    [self updateSettingsController];
    [importSettingsController addObserver: self forKeyPath: @"selection.isDirty" options: 0 context: nil];
}

#pragma mark - Application logic

- (void)updateSettingsController {
    NSError *error = nil;
    NSArray *files = [NSFileManager.defaultManager contentsOfDirectoryAtPath: MOAssistant.sharedAssistant.importerDir
                                                                       error: &error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    NSMutableArray *names = [NSMutableArray arrayWithCapacity: 10];
    for (NSString *file in files) {
        if ([file hasSuffix: @".plist"]) {
            [names addObject: [file substringToIndex: [file length] - 6]];
        }
    }
    if (names.count == 0) {
        // Create a default setting if none are stored yet.
        [names addObject: NSLocalizedString(@"AP621", nil)];
        NSString *fileName = [NSString stringWithFormat: @"%@/%@.plist", MOAssistant.sharedAssistant.importerDir, NSLocalizedString(@"AP621", nil)];
        currentSettings = importSettingsController.content;
        currentSettings.fileName = fileName;
        currentSettings.isDirty = YES;
        [storedSettingsController setContent: names];
    } else {
        [storedSettingsController setContent: names];
        [self settingSelectionChanged: nil];
    }
}

/**
 * Called when a new file was selected.
 */
- (void)updatePreview {
    // We might change some settings while updating the preview (to fix invalid entries), which
    // will cause a recursive call.
    if (updating) {
        return;
    }

    updating = YES;
    @try {
        NSString *separator = currentSettings.fieldSeparator;
        if (separator == nil) {
            separator = @",";
        }

        if ([NSFileManager.defaultManager fileExistsAtPath: currentFile]) {
            NSError  *error = nil;
            NSString *content = [NSString stringWithContentsOfFile: currentFile
                                                          encoding: currentSettings.encoding.integerValue
                                                             error: &error];
            if (error != nil) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
            } else {
                currentLines = [content csvRowsWithSeparator: separator];
            }
        } else {
            currentLines = nil;
        }

        NSString   *text = @"";
        NSUInteger ignoredLines = currentSettings.ignoreLines.intValue;
        for (NSUInteger i = 0; i < ignoredLines; i++) {
            if (i >= currentLines.count) {
                break;
            }
            text = [text stringByAppendingFormat: @"%@\n", [currentLines[i] componentsJoinedByString: separator]];
        }
        ignoredText.string = text;
        [ignoredText setTextColor: [NSColor grayColor]];

        NSUInteger columnCount = 0;
        importValues = [NSMutableArray arrayWithCapacity: (currentLines.count >= ignoredLines) ? currentLines.count - ignoredLines: 0];
        for (NSUInteger i = ignoredLines; i < currentLines.count; i++) {
            NSArray *fields = currentLines[i];

            BOOL                isEmpty = YES;
            NSMutableDictionary *entry = [NSMutableDictionary dictionary];
            for (NSUInteger j = 0; j < fields.count; j++) {
                isEmpty = isEmpty && [fields[j] length] == 0;
                entry[[NSString stringWithFormat: @"%lu", j]] = fields[j];
            }
            if (!isEmpty) {
                [importValues addObject: entry];
            }

            if (fields.count > columnCount) {
                columnCount = fields.count;
            }
        }
        importValuesController.content = importValues;

        // Columns setup.
        NSArray *columns = [importValuesTable.tableColumns copy];
        for (NSTableColumn *column in columns) {
            [importValuesTable removeTableColumn: column];
        }
        for (NSUInteger i = 0; i < columnCount; i++) {
            NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier: [NSString stringWithFormat: @"%lu", i]];

            NSString *heading = nil;
            if (i < currentSettings.fields.count) {
                // Translate field name to localized heading by looking up the tokens we set in the token field.
                NSArray *tokens = tokenField.objectValue;
                for (ColumnToken *token in tokens) {
                    if ([token.property isEqualToString: currentSettings.fields[i]]) {
                        heading = token.caption;
                        break;
                    }
                }
            }

            if (heading == nil) {
                // If no token was found then the current value in the fields array is not supported
                // (e.g. when using older settings).
                NSMutableArray *fields = [currentSettings.fields mutableCopy];
                fields[i] = @"";
                currentSettings.fields = fields;
                heading = NSLocalizedString(@"AP618", nil);
            }

            [column.headerCell setStringValue: heading];
            [column.dataCell setFont: textFont];
            [importValuesTable addTableColumn: column];
            [column    bind: @"value"
                   toObject: importValuesController
                withKeyPath: [NSString stringWithFormat: @"arrangedObjects.%lu", i]
                    options: nil];
        }
    }
    @finally {
        updating = NO;
    }
}

#pragma mark - Action messages

- (IBAction)settingSelectionChanged: (id)sender {
    NSString *settingName = [[storedSettingsController selectedObjects] lastObject];
    if (settingName == nil) {
        return;
    }

    NSString *fileName = [NSString stringWithFormat: @"%@/%@.plist", MOAssistant.sharedAssistant.importerDir, settingName];
    currentSettings = [NSKeyedUnarchiver unarchiveObjectWithFile: fileName];
    if (currentSettings == nil) {
        LogWarning(@"Import settings file not found: %@", fileName);
        NSRunAlertPanel(NSLocalizedString(@"AP619", nil),
                        NSLocalizedString(@"AP620", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil, nil, fileName);
    }

    // Ensure there are valid values if anything is missing.
    updating = YES;
    if (currentSettings.fields == nil) {
        currentSettings.fields = @[];
    }
    if (currentSettings.fieldSeparator == nil) {
        currentSettings.fieldSeparator = @",";
    }
    if (currentSettings.dateFormat == nil) {
        currentSettings.dateFormat = @"dd.MM.yyyy";
        dateFormatter.dateFormat = @"dd.MM.yyyy";
    }
    if (currentSettings.encoding == nil) {
        currentSettings.encoding = @(NSISOLatin1StringEncoding);
    }
    if (currentSettings.ignoreLines == nil) {
        currentSettings.ignoreLines = @0;
    }
    if (currentSettings.accountNumber == nil) {
        currentSettings.accountNumber = @"";
    }
    if (currentSettings.bankCode == nil) {
        currentSettings.bankCode = @"";
    }
    if (currentSettings.type == nil) {
        currentSettings.type = @(SettingsTypeCSV);
    }
    if (currentSettings.decimalSeparator == nil) {
        NSLocale *locale = NSLocale.currentLocale;
        currentSettings.decimalSeparator = [locale objectForKey: NSLocaleDecimalSeparator];
    }

    // Select the correct decimal separator. We only support comma and dot.
    if ([currentSettings.decimalSeparator isEqualToString: @"."]) {
        [decimalSeparatorPopupButton selectItemAtIndex: 1];
    } else {
        if (![currentSettings.decimalSeparator isEqualToString: @","]) {
            currentSettings.decimalSeparator = @",";
        }
        [decimalSeparatorPopupButton selectItemAtIndex: 0];
    }

    // Similar for the field separator.
    switch ([currentSettings.fieldSeparator characterAtIndex: 0]) {
        case ',' :
            [fieldSeparatorPopupButton selectItemAtIndex: 0];
            break;

        case ';':
            [fieldSeparatorPopupButton selectItemAtIndex: 1];
            break;

        case '\t':
            [fieldSeparatorPopupButton selectItemAtIndex: 2];
            break;

        default:
            [fieldSeparatorPopupButton selectItemAtIndex: 3];
            break;
    }
    [self fieldSeparatorChanged: nil];

    // Select the correct encoding.
    for (Encoding *encoding in encodingsController.arrangedObjects) {
        if ([encoding.value isEqualToNumber: currentSettings.encoding]) {
            [encodingsController setSelectedObjects: @[encoding]];
            break;
        }
    }
    // Select the correct account.
    BOOL found = NO;
    for (BankAccount *account in accountsController.arrangedObjects) {
        if ([account.accountNumber isEqualToString: currentSettings.accountNumber]) {
            found = YES;
            [accountsController setSelectedObjects: @[account]];
            break;
        }
    }
    if (!found) {
        // The specified account was not found in the list of available accounts, so explicitly select
        // the first available account.
        [accountsController setSelectionIndex: 0];
        [self accountChanged: nil];
    }

    updating = NO;

    dateFormatter.dateFormat = currentSettings.dateFormat;
    numberFormatter.decimalSeparator = currentSettings.decimalSeparator;

    currentSettings.isDirty = NO;
    currentSettings.fileName = fileName;
    importSettingsController.content = currentSettings;
}

- (IBAction)cancel: (id)sender {
    [[self window] close];
    [NSApp stopModalWithCode: 1];
}

- (void)windowWillClose: (NSNotification *)aNotification {
    [NSApp stopModalWithCode: 1];
}

/**
 * Runs on a background thread. Loads all files and parses the values. Once done the user gets a chance
 * to select a date range to be imported and can finally start the import.
 */
- (void)preprocessValues: (id)object {
    NSDate     *minDate = nil;
    NSDate     *maxDate = nil;
    NSUInteger errorCount = 0;

    @try {
        NSUInteger index = currentSettings.ignoreLines.intValue;
        NSString   *separator = currentSettings.fieldSeparator;
        if (separator == nil) {
            separator = @",";
        }

        NSUInteger nonImportedLineCount = 0;

        NSUInteger ignoredLines = currentSettings.ignoreLines.intValue;
        parsedValues = [NSMutableArray arrayWithCapacity: 1000];
        for (NSString *file in fileNames) {
            if (stopProcessing) {
                return;
            }

            NSArray *csvRows;
            if ([NSFileManager.defaultManager fileExistsAtPath: file]) {
                NSError  *error = nil;
                NSString *content = [NSString stringWithContentsOfFile: file
                                                              encoding: currentSettings.encoding.integerValue
                                                                 error: &error];
                if (error != nil) {
                    NSAlert *alert = [NSAlert alertWithError: error];
                    [alert runModal];
                    continue;
                } else {
                    csvRows = [content csvRowsWithSeparator: separator];
                }
            } else {
                csvRows = nil;
            }

            for (NSUInteger i = ignoredLines; i < csvRows.count; i++) {
                NSArray *fields = csvRows[i];
                if (stopProcessing) {
                    return;
                }

                BOOL isEmpty = YES;
                for (NSString *field in fields) {
                    isEmpty = isEmpty && field.length == 0;
                }
                if (isEmpty) {
                    ++nonImportedLineCount;
                    continue;
                }

                NSMutableDictionary *entry = [NSMutableDictionary dictionary];
                for (NSUInteger j = 0; j < fields.count; j++) {
                    if (stopProcessing) {
                        return;
                    }

                    // Ignore any field that goes beyond the defined fields.
                    if (j >= currentSettings.fields.count) {
                        break;
                    }

                    NSString *property = currentSettings.fields[j];
                    if (property.length == 0) {
                        continue; // An ignored field.
                    }

                    NSString *field = fields[j];
                    id       object = (field.length == 0) ? nil : field;
                    if ([property isEqualToString: @"date"] || [property isEqualToString: @"valutaDate"]) {
                        @synchronized(dateFormatter) {
                            NSDate *rawDate = [dateFormatter dateFromString:field];
                            if (rawDate != nil) {
                                if (minDate == nil || [minDate isGreaterThan: rawDate]) {
                                    minDate = rawDate;
                                }
                                if (maxDate == nil || [rawDate isGreaterThan: maxDate]) {
                                    maxDate = rawDate;
                                }
                                ShortDate *date = [ShortDate dateWithDate: rawDate];
                                if (date.year < 1970 || date.year > 2100) {
                                    LogError(@"Datei: %@\n\tZeile: %lu, Datum ist ungültig: %@", file, index, field);
                                    errorCount++;
                                    object = nil;
                                }
                                object = rawDate;
                            } else {
                                LogError(@"Datei: %@\n\tZeile: %lu, Datum ist ungültig: %@", file, index, field);
                                errorCount++;
                                object = nil;
                            }
                        }
                    } else {
                        if ([property isEqualToString: @"value"]) {
                            object = [NSDecimalNumber decimalNumberWithDecimal: [[numberFormatter numberFromString: field] decimalValue]];
                            if ([object isEqualTo: [NSDecimalNumber notANumber]]) {
                                LogError(@"Datei: %@\n\tZeile: %lu, Wert ist keine Nummer: %@", file, index, field);
                                errorCount++;
                                object = nil;
                            } else {
                                object = [object rounded];
                            }

                        }
                    }
                    if (object != nil) {
                        if (entry[property] == nil) {
                            entry[property] = object;
                        } else {
                            // If there's already a value then the user selected the same tag for different fields.
                            // This is sometimes necessary to collect split values, however both object types
                            // must be the same to be acceptable.
                            if ([entry[property] isKindOfClass: [object class]]) {
                                if ([object isKindOfClass: [NSString class]]) {
                                    entry[property] = [NSString stringWithFormat: @"%@ %@", entry[property], object];
                                } else if ([object isKindOfClass: [NSDecimalNumber class]]) {
                                    entry[property] = [entry[property] decimalNumberByAdding: object];
                                } else {
                                    errorCount++;
                                    LogError(@"Datei: %@\n\tZeile: %lu, mehrere Felder haben den gleichen Import-Typ, können aber nicht kombiniert werden: %@",
                                             file, index, property);
                                }
                            } else {
                                errorCount++;
                                LogError(@"Datei: %@\n\tZeile: %lu, mehrere Felder haben den gleichen Import-Typ aber verschiedene Datentypen: %@",
                                         file, index, property);
                            }
                        }
                    }
                }
                if (entry[@"date"] != nil || entry[@"valutaDate"] != nil) {
                    // Handle booking date and valuta date as equally adequate and fill the missing value (if there's any).
                    if (entry[@"date"] == nil) {
                        entry[@"date"] = entry[@"valutaDate"];
                    }
                    if (entry[@"valutaDate"] == nil) {
                        entry[@"valutaDate"] = entry[@"date"];
                    }

                    // Do a sanity check for the order of booking and valuta date.
                    if ([entry[@"date"] compare: entry[@"valutaDate"]] == NSOrderedDescending) {
                        entry[@"valutaDate"] = entry[@"date"];
                    }
                    [parsedValues addObject: entry];
                } else {
                    ++nonImportedLineCount;
                }
            }
        }
        [processingSheet preprocessingDoneWithErrorCount: errorCount
                                            ignoredCount: nonImportedLineCount
                                                 minDate: minDate
                                                 maxDate: maxDate
                                             canContinue: parsedValues.count > 0];
    }
    @catch (NSException *error) {
        LogError(@"%@", error.debugDescription);
        [processingSheet preprocessingDoneWithFatalError];
    }
}

- (void)startImport {
    BankAccount *account = [BankAccount findAccountWithNumber: currentSettings.accountNumber
                                                subNumber: currentSettings.accountSuffix
                                                 bankCode: currentSettings.bankCode];
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.memContext;

    BOOL customDateRange = processingSheet->dateRadioGroup.selectedColumn == 1;
    ShortDate *fromDate = [ShortDate dateWithDate: processingSheet->fromDatePicker.dateValue];
    ShortDate *toDate = [ShortDate dateWithDate: processingSheet->toDatePicker.dateValue];

    NSMutableArray *statements = [NSMutableArray arrayWithCapacity: parsedValues.count];
    for (NSDictionary *entry in parsedValues) {
        // Add new entry only if everything is allowed or its date value is within the allowed range.
        if (customDateRange) {
            ShortDate *date = [ShortDate dateWithDate: entry[@"date"]]; // Should always be valid.
            if (date == nil) {
                continue;
            }
            if (![date isBetween: fromDate and: toDate]) {
                continue;
            }
        }
        BankStatement *statement = [NSEntityDescription insertNewObjectForEntityForName: @"BankStatement"
                                                                 inManagedObjectContext: context];

        [entry enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
            [statement setValue: obj forKey: key];
        }

        ];

        statement.localBankCode = currentSettings.bankCode;
        statement.localAccount = currentSettings.accountNumber;

        if (statement.currency == nil) {
            statement.currency = account.currency;
        }

        [statements addObject: statement];
    }

    // Check sorting of statements and re-sort if necessary.
    if ([statements count] > 0) {
        BankStatement *first = statements[0];
        BankStatement *last = [statements lastObject];
        if ([first.date compare: last.date] == NSOrderedDescending) {
            NSMutableArray *newStats = [NSMutableArray arrayWithCapacity: 100];
            NSInteger j;
            for (j = [statements count] - 1; j >= 0; j--) {
                [newStats addObject: statements[j]];
            }
            statements = newStats;
        }
    }

    importResult = [BankQueryResult new];
    importResult.statements = statements;
    importResult.isImport = YES;
    importResult.account = account;
}

- (IBAction)startProcessing: (id)sender {
    [processingSheet prepare];

    stopProcessing = NO;
    [NSApp  beginSheet: processingSheet
        modalForWindow: [self window]
         modalDelegate: self
        didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
           contextInfo: PROCESSING_CONTEXT];
}

/**
 * Recursively called to add files and folders to the file outline.
 */
- (void)addFileEntryForPath: (NSString *)path atParent: (FileEntry *)parent {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isFolder;
    [fileManager fileExistsAtPath: path isDirectory: &isFolder];

    FileEntry *entry = nil;

    // Add a file only once.
    if (![fileNames containsObject: path]) {
        entry = [[FileEntry alloc] init];
        entry.name = [path lastPathComponent];
        entry.path = path;
        entry.isFolder = isFolder;
        entry.icon = [[NSWorkspace sharedWorkspace] iconForFile: entry.path];
    }

    if (isFolder) {
        NSError *error = nil;
        NSArray *fileList = [fileManager contentsOfDirectoryAtPath: path error: &error];
        if (error != nil) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
        } else {
            for (NSString *file in fileList) {
                if (![file hasPrefix: @"."]) {
                    [self addFileEntryForPath: [NSString stringWithFormat: @"%@/%@", path, file] atParent: entry];
                }
            }
        }
    }

    if (entry != nil) {
        [fileNames addObject: path];
        if (parent == nil) {
            [fileTreeController addObject: entry];
        } else {
            [parent.children addObject: entry];
        }
    }
}

- (void)removeFileEntries: (NSArray *)entries {
    for (FileEntry *file in entries) {
        [self removeFileEntries: file.children];
        [fileNames removeObject: file.path];
    }
}

- (IBAction)addRemoveFile: (id)sender {
    NSInteger clickedSegment = [sender selectedSegment];
    switch (clickedSegment) {
        case 0: {
            // Add new files.
            NSOpenPanel *panel = [NSOpenPanel openPanel];
            panel.title = NSLocalizedString(@"AP625", nil);
            panel.canChooseDirectories = YES;
            panel.canChooseFiles = YES;
            panel.allowsMultipleSelection = YES;

            NSModalResponse runResult = [panel runModal];
            if (runResult == NSOKButton) {
                for (NSURL *url in panel.URLs) {
                    [self addFileEntryForPath: url.path atParent: nil];
                }
            }
            break;
        }

        case 1: {
            NSArray *selection = fileTreeController.selectedObjects;
            [self removeFileEntries: selection];

            NSArray *entries = [fileTreeController.selectionIndexPaths copy];
            [fileTreeController removeObjectsAtArrangedObjectIndexPaths: entries];
            break;
        }
    }

}

- (IBAction)saveSettings: (id)sender {
    [importSettingsController commitEditing];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: currentSettings];
    BOOL   successful = [data writeToFile: currentSettings.fileName atomically: YES];
    if (!successful) {
        NSRunCriticalAlertPanel(NSLocalizedString(@"AP110", nil),
                                NSLocalizedString(@"AP111", nil),
                                NSLocalizedString(@"AP1", nil),
                                nil, nil,
                                currentSettings.fileName);
    } else {
        currentSettings.isDirty = NO;
    }
}

- (IBAction)saveSettingsAs: (id)sender {
    [NSApp  beginSheet: newSettingsNameSheet
        modalForWindow: [self window]
         modalDelegate: self
        didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
           contextInfo: SAVE_AS_CONTEXT];
}

- (void)sheetDidEnd: (NSWindow *)sheet returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo {
    [sheet orderOut: nil];

    if (contextInfo == SAVE_AS_CONTEXT) {
        if (returnCode == NSRunStoppedResponse) {
            [importSettingsController commitEditing];

            NSString *fileName = [NSString stringWithFormat: @"%@/%@.plist", MOAssistant.sharedAssistant.importerDir, settingsNameField.stringValue];

            // Check if file already exists and issue warning.
            if ([[NSFileManager defaultManager] fileExistsAtPath: fileName]) {
                NSInteger res = NSRunAlertPanel(NSLocalizedString(@"AP84", nil),
                                                NSLocalizedString(@"AP600", nil),
                                                NSLocalizedString(@"AP4", nil),
                                                NSLocalizedString(@"AP3", nil),
                                                nil,
                                                fileName);
                if (res == NSAlertDefaultReturn) {
                    return;
                }
            }
            currentSettings.fileName = fileName;
            [self saveSettings: nil];

            [self updateSettingsController];
            NSUInteger index = 0;
            for (NSString *entry in storedSettingsController.arrangedObjects) {
                if ([entry isEqualToString: settingsNameField.stringValue]) {
                    storedSettingsController.selectionIndex = index;
                    [self settingSelectionChanged: nil];
                    break;
                }
                index++;
            }
        }
    }

    if (contextInfo == PROCESSING_CONTEXT) {
        if (returnCode == NSRunStoppedResponse) {
            [self startImport];
            [[self window] close];
            [NSApp stopModalWithCode: 0];
        }
    }
}

- (IBAction)saveTemplate: (id)sender {
    NSString *name = settingsNameField.stringValue;
    if (name.length == 0) {
        NSBeep();
        return;
    }
    [NSApp endSheet: newSettingsNameSheet returnCode: NSRunStoppedResponse];
}

- (IBAction)cancelNewNameTemplate: (id)sender {
    [NSApp endSheet: newSettingsNameSheet returnCode: NSRunAbortedResponse];
}

- (IBAction)removeSettingEntry: (id)sender {
    NSString *settingName = [[storedSettingsController selectedObjects] lastObject];
    if (settingName == nil) {
        return;
    }

    NSString *fileName = [NSString stringWithFormat: @"%@/%@.plist", MOAssistant.sharedAssistant.importerDir, settingName];

    NSInteger res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP622", nil),
                                            NSLocalizedString(@"AP623", nil),
                                            NSLocalizedString(@"AP2", nil),
                                            NSLocalizedString(@"AP10", nil),
                                            nil, nil
                                            );
    if (res != NSAlertAlternateReturn) {
        return;
    }

    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath: fileName error: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    } else {
        [self updateSettingsController];
    }
}

- (IBAction)encodingChanged: (id)sender {
    Encoding *encoding = [encodingsController.selectedObjects lastObject];
    currentSettings.encoding = encoding.value;
}

- (IBAction)accountChanged: (id)sender {
    updating = YES; // Avoid two refreshs for the two changes here.
    BankAccount *account = [accountsController.selectedObjects lastObject];
    currentSettings.accountNumber = account.accountNumber;
    updating = NO;
    currentSettings.bankCode = account.bankCode;
}

- (IBAction)decimalSeparatorChanged: (id)sender {
    NSMenuItem *item = [sender selectedItem];
    if (item.tag == 0) {
        currentSettings.decimalSeparator = @",";
        numberFormatter.decimalSeparator = @",";
    } else {
        currentSettings.decimalSeparator = @".";
        numberFormatter.decimalSeparator = @".";
    }
}

- (IBAction)fieldSeparatorChanged: (id)sender {
    NSInteger tag = fieldSeparatorPopupButton.selectedTag;
    switch (tag) {
        case 0:
            currentSettings.fieldSeparator = @",";
            break;

        case 1:
            currentSettings.fieldSeparator = @";";
            break;

        case 2:
            currentSettings.fieldSeparator = @"\t";
            break;

        case 3:
            // No modification.
            break;
    }
    customFieldSeparator.hidden = tag != 3;
    customFieldSeparatorLabel.hidden = tag != 3;
}

#pragma mark -
#pragma mark Outline view delegate methods

- (void)outlineView: (NSOutlineView *)outlineView
    willDisplayCell: (id)cell
     forTableColumn: (NSTableColumn *)tableColumn
               item: (id)item {
    [cell setImage: [(FileEntry *)[item representedObject] icon]];
}

- (void)outlineViewSelectionDidChange: (NSNotification *)aNotification {
    FileEntry *entry = [[fileOutlineView itemAtRow: [fileOutlineView selectedRow]] representedObject];
    if (!entry.isFolder) {
        currentFile = entry.path;
        [self updatePreview];
    }
}

- (NSDragOperation)outlineView: (NSOutlineView *)outlineView
                  validateDrop: (id < NSDraggingInfo >)info
                  proposedItem: (id)item
            proposedChildIndex: (NSInteger)index {
    if (item == nil) { // Accept drop only on free areas, since we don't drop on existing entries.
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView: (NSOutlineView *)outlineView
         acceptDrop: (id <NSDraggingInfo>)info
               item: (id)item
         childIndex: (NSInteger)index {
    NSPasteboard *pasteboard = info.draggingPasteboard;
    NSArray      *urls = [pasteboard readObjectsForClasses: @[[NSURL class]]
                                                   options: @{NSPasteboardURLReadingFileURLsOnlyKey: @YES}
        ];

    for (NSURL *url in urls) {
        [self addFileEntryForPath: url.path atParent: nil];
    }
    return YES;
}

#pragma mark -
#pragma mark Table view delegate methods

- (void)  tableView: (NSTableView *)aTableView
    willDisplayCell: (id)aCell
     forTableColumn: (NSTableColumn *)aTableColumn
                row: (NSInteger)rowIndex {
    [aCell setEditable: NO];

    BOOL       hasError = NO;
    BOOL       hasAssignedContent = NO;
    NSUInteger columnIndex = aTableColumn.identifier.integerValue;
    if (columnIndex < currentSettings.fields.count) {
        NSString *field = currentSettings.fields[columnIndex];
        if (field.length > 0 && ![field isEqualToString: @"undefined"]) {
            // We have a valid and assigned column. Check content now.
            hasAssignedContent = YES;
            NSString *value = [aCell stringValue];
            if ([field isEqualToString: @"value"]) {
                NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithDecimal: [[numberFormatter numberFromString: value] decimalValue]];
                [aCell setObjectValue: [number rounded]];
                if ([number isEqualTo: [NSDecimalNumber notANumber]]) {
                    hasError = YES;
                }
            } else {
                if ([field isEqualToString: @"date"] || [field isEqualToString: @"valutaDate"]) {
                    @synchronized(dateFormatter) {
                        NSDate *rawDate = [dateFormatter dateFromString:value];
                        if (rawDate != nil) {
                            ShortDate *date = [ShortDate dateWithDate: rawDate];
                            hasError = date.year < 1970 || date.year > 2100;
                        } else {
                            hasError = YES;
                        }
                    }
                }
            }
        }
    }

    if (!hasAssignedContent) {
        [aCell setDrawsBackground: NO];
        [aCell setTextColor: NSColor.grayColor];
    } else {
        if (hasError) {
            [aCell setDrawsBackground: YES];
            [aCell setBackgroundColor: NSColor.redColor];
            [aCell setTextColor: NSColor.whiteColor];
        } else {
            [aCell setDrawsBackground: NO];
            [aCell setTextColor: NSColor.blackColor];
        }
    }
}

- (NSDragOperation)tableView: (NSTableView *)aTableView
                validateDrop: (id <NSDraggingInfo>)info
                 proposedRow: (NSInteger)row
       proposedDropOperation: (NSTableViewDropOperation)operation {
    NSPoint localPoint = [aTableView convertPoint: info.draggingLocation fromView: nil];
    localPoint.y = 10; // Higher values cause the hit test to return no valid column <sigh>.
    NSInteger columnIndex = [aTableView.headerView columnAtPoint: localPoint];
    [aTableView selectColumnIndexes: [NSIndexSet indexSetWithIndex: columnIndex] byExtendingSelection: NO];
    return NSDragOperationLink;
}

- (BOOL)tableView: (NSTableView *)aTableView
       acceptDrop: (id <NSDraggingInfo>)info
              row: (NSInteger)row
    dropOperation: (NSTableViewDropOperation)operation {
    if (aTableView.selectedColumn > -1) {
        NSPasteboard *pasteboard = info.draggingPasteboard;

        NSString       *tokenText = [pasteboard stringForType: NSPasteboardTypeString];
        NSArray        *entries = [tokenText componentsSeparatedByString: @":"];
        NSUInteger     index = aTableView.selectedColumn;
        NSMutableArray *newFields = [currentSettings.fields mutableCopy];
        if (newFields == nil) {
            newFields = [NSMutableArray arrayWithCapacity: 10];
        }
        while (index >= newFields.count) {
            [newFields addObject: @""];
        }
        newFields[index] = entries[1];
        updating = YES;
        currentSettings.fields = newFields;
        NSTableColumn *column = aTableView.tableColumns[index];
        [column.headerCell setStringValue: entries[0]];
        [aTableView setNeedsDisplay];
        [aTableView.headerView setNeedsDisplay: YES];
        updating = NO;

        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark Token field delegate methods

- (NSString *)tokenField: (NSTokenField *)tokenField displayStringForRepresentedObject: (id)representedObject {
    return [representedObject caption];
}

/**
 * Writes tokens to the pasteboard. Ensures only one token is actually written, regardless of the selected amount
 * as we can only assign one token per column in the input table.
 */
- (BOOL)tokenField: (NSTokenField *)tokenField writeRepresentedObjects: (NSArray *)objects toPasteboard: (NSPasteboard *)pboard {
    ColumnToken *token = [objects lastObject];
    NSString    *data = [NSString stringWithFormat: @"%@:%@", token.caption, token.property];
    [pboard setString: data forType: NSPasteboardTypeString];
    return true;
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context {
    if ([keyPath isEqualToString: @"selection.isDirty"]) {
        [self updatePreview];
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

@end
