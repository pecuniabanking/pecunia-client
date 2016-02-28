/**
 * Copyright (c) 2008, 2014, Pecunia Project. All rights reserved.
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

#import <QuartzCore/QuartzCore.h>

#import "BankingCategory.h"
#import "BankAccount.h"
#import "PreferenceController.h"
#import "MOAssistant.h"
#import "Keychain.h"
#import "BankingController.h"
#import "PasswordWindow.h"

#import "NSColor+PecuniaAdditions.h"
#import "NSImage+PecuniaAdditions.h"

#import "NewPasswordController.h"
#import "LocalSettingsController.h"
#import "ShortDate.h"

#import "YahooStockData.h"

static NSArray *exportFields = nil;

#define EXPORT_SEPARATOR @"exportSeparator"

#pragma mark - Helper routines

NSMenuItem* createItemForDateSelector(NSString *title, NSUInteger tag)
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: title action: nil keyEquivalent: @""];
    item.tag = tag;
    return item;
}

void prepareLoanDateSelectors(NSPopUpButton *monthSelector, NSPopUpButton *yearSelector,
                              ShortDate *selectedDate, NSUInteger startYear)
{
    [monthSelector removeAllItems];
    [yearSelector removeAllItems];

    if (selectedDate == nil) {
        selectedDate = ShortDate.currentDate;
    }

    NSArray *monthNames = [NSCalendar.currentCalendar monthSymbols];
    NSMenu *menu = monthSelector.menu;
    for (NSUInteger month = 0; month < monthNames.count; ++month) {
        NSMenuItem *item = createItemForDateSelector(monthNames[month], month + 1);
        [menu addItem: item];
        if (month + 1 == selectedDate.month) {
            [monthSelector selectItem: item];
        }
    }

    ShortDate *date = ShortDate.currentDate;
    menu = yearSelector.menu;
    if (startYear == 0) {
        startYear = date.year - 30;
    }
    for (NSUInteger year = startYear; year <= startYear + 50; ++year) {
        NSMenuItem *item = createItemForDateSelector([NSString stringWithFormat: @"%lu", year], year);
        [menu addItem: item];
        if (year == selectedDate.year) {
            [yearSelector selectItem: item];
        }
    }
}

#pragma mark - Class implementations

@interface PreferenceController ()

- (void)removeRedemption: (id)cell;
- (void)redemptionDateChanged: (ShortDate *)newDate cell: (id)cell;
- (void)redemptionAmountChanged: (NSNumber *)newAmount cell: (id)cell;

@end

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

@implementation ColorListViewCell

- (void)configureWithString: (NSString *)config
{
    NSArray *values = [config componentsSeparatedByString: @"|"];
    colorKey = values[1];
    colorWell.color = [NSColor applicationColorForKey: colorKey];
    [self updateColorText];

    if (values.count > 2) {
        showHeader = YES;
        headerText.stringValue = NSLocalizedString(values[2], nil);
    } else {
        showHeader = NO;
    }

    NSMutableAttributedString *captionString = [[NSMutableAttributedString alloc] initWithString: NSLocalizedString(values[0], nil)];
    NSMutableParagraphStyle   *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setMaximumLineHeight: 12];

    NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle};

    [captionString addAttributes: attributes range: NSMakeRange(0, [captionString length])];
    caption.attributedStringValue = captionString;
}

- (IBAction)resetToDefault: (id)sender
{
    [NSColor resetApplicationColorForKey: colorKey];
    colorWell.color = [NSColor applicationColorForKey: colorKey];
    [self updateColorText];
}

- (IBAction)colorChanged: (id)sender
{
    [NSColor setApplicationColor: colorWell.color forKey: colorKey];
    [self updateColorText];
}

- (void)updateColorText
{
    NSColor *color = [colorWell.color colorUsingColorSpace: [NSColorSpace deviceRGBColorSpace]];
    int     red = color.redComponent * 255;
    int     green = color.greenComponent * 255;
    int     blue = color.blueComponent * 255;

    rgbText.stringValue = [NSString stringWithFormat: @"R: %3i G: %3i B: %3i", red, green, blue];
    htmlText.stringValue = [NSString stringWithFormat: @"HTML: #%.2X%.2X%.2X", red, green, blue];
}

static NSGradient *headerGradient;

- (void)setupDrawStructures
{
    headerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                      [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 1], (CGFloat)0,
                      [NSColor colorWithDeviceWhite: 120 / 255.0 alpha: 1], (CGFloat)1,
                      nil];
}

- (void)drawRect: (NSRect)dirtyRect
{
    if (headerGradient == nil) {
        [self setupDrawStructures];
    }

    NSRect bounds = [self bounds];
    if (showHeader) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect: NSMakeRect(bounds.origin.x,
                                                                          bounds.size.height - 18,
                                                                          bounds.size.width,
                                                                          18)];
        [headerGradient drawInBezierPath: path angle: 90.0];
    }
}

@end

@interface RedemptionCellView : NSTableCellView
{
    IBOutlet NSPopUpButton *monthButton;
    IBOutlet NSPopUpButton *yearButton;
    IBOutlet NSTextField *amountField;
}

@property (weak) PreferenceController *delegate;

@end

@implementation RedemptionCellView

@synthesize delegate;

- (void)prepareForStartDate: (ShortDate *)date
{
    NSDictionary *values = self.objectValue;
    prepareLoanDateSelectors(monthButton, yearButton, values[@"date"], date.year);
    amountField.objectValue = values[@"amount"];
}

- (IBAction)remove: (id)sender
{
    [delegate removeRedemption: self];
}

- (IBAction)dateChanged: (id)sender
{
    ShortDate *date = [ShortDate dateWithYear: yearButton.selectedTag
                                        month: monthButton.selectedTag
                                          day: 1];
    [delegate redemptionDateChanged: date cell: self];
}

- (IBAction)amountChanged: (id)sender
{
    NSNumber *amount = @([sender floatValue]);
    [delegate redemptionAmountChanged: amount cell: self];
}

@end

@implementation PreferenceController

static NSDictionary *heightMappings;

@synthesize selectedSection;

+ (void)initialize
{
    heightMappings = @{@"general": @385,
                       @"home": @400,
                       @"security": @270,
                       @"persistence": @260,
                       @"display": @390,
                       @"colors": @450,
                       @"export": @375,
                       @"print": @220};
}

+ (void)showPreferencesWithOwner: (id)owner section: (NSString *)section
{
    static PreferenceController *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[PreferenceController alloc] init];
    });
    singleton.selectedSection = section;
    [singleton showWindow: owner];
}

- (id)init
{
    self = [super initWithWindowNibName: @"Preferences"];
    if (self != nil) {
        exportFields = @[@"valutaDate", @"date", @"value", @"saldo", @"currency", @"localAccount",
                         @"localBankCode", @"localName", @"localCountry",
                         @"localSuffix", @"remoteName", @"floatingPurpose", @"note", @"remoteAccount", @"remoteBankCode",
                         @"remoteBankName", @"remoteBankLocation", @"remoteIBAN", @"remoteBIC", @"remoteSuffix",
                         @"customerReference", @"bankReference", @"transactionText", @"primaNota",
                         @"transactionCode", @"categoriesDescription"];

        roundUp = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundUp
                                                                         scale: 2
                                                              raiseOnExactness: NO
                                                               raiseOnOverflow: NO
                                                              raiseOnUnderflow: NO
                                                           raiseOnDivideByZero: YES];

        roundDown = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundDown
                                                                           scale: 2
                                                                raiseOnExactness: NO
                                                                 raiseOnOverflow: NO
                                                                raiseOnUnderflow: NO
                                                             raiseOnDivideByZero: YES];

    }
    return self;
}

- (void)awakeFromNib
{
    [self prepareAccountSelectors];

    NSDate *dateToSelect = LocalSettingsController.sharedSettings[@"loanStartDate"];
    if (dateToSelect == nil) {
        dateToSelect = NSDate.date;
    }
    prepareLoanDateSelectors(monthSelector, yearSelector, [ShortDate dateWithDate: dateToSelect], 0);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray        *fields = [defaults objectForKey: @"Exporter.fields"];
    if (fields != nil) {
        NSTableColumn  *col = [fieldTable tableColumns][0];
        NSComboBoxCell *cell = [col dataCell];

        for (NSString *field in fields) {
            int                 idx = [exportFields indexOfObject: field];
            NSString            *name = [cell itemObjectValueAtIndex: idx];
            NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObject: name forKey: @"fieldName"];
            [fieldController addObject: item];
        }
    }
    MOAssistant *assistant = [MOAssistant sharedAssistant];
    encrypt = assistant.isEncrypted;
    [self setValue: @(assistant.isEncrypted) forKey: @"encrypt"];
    [dataFileField setStringValue: [assistant dataFilename]];

    // Select first tab.
    [toolBar setSelectedItemIdentifier: @"general"];
    [mainTab selectTabViewItemAtIndex: 0];
    [mainTab setTabViewType: NSNoTabsNoBorder];

    [self setHeight: heightMappings[@"general"]];

    // Load field separator.
    NSString *expSep = [defaults stringForKey: EXPORT_SEPARATOR];
    if (expSep) {
        if ([expSep isEqualToString: @"\t"]) {
            [expRadioMatrix setState: NSOnState atRow: 0 column: 0];
        }
        if ([expSep isEqualToString: @";"]) {
            [expRadioMatrix setState: NSOnState atRow: 1 column: 0];
        }
        if ([expSep isEqualToString: @"|"]) {
            [expRadioMatrix setState: NSOnState atRow: 2 column: 0];
        }
    }

    // Load icons in the toolbar. Those in subfolders of the Resources folder are not found automatically.
    for (NSToolbarItem *item in toolBar.items) {
        NSImage *image = [NSImage imageNamed: item.paletteLabel fromCollection: 1];
        if (image != nil) {
            item.image = image; // Leave alone images that do not come from the collection.
        }
    }

    colorListView.delegate = self;
    [colorListView reloadData];

    if (selectionPending ) {
        selectionPending = NO;
        [mainTab selectTabViewItemWithIdentifier: selectedSection];
        [toolBar setSelectedItemIdentifier: selectedSection];
        [self setHeight: heightMappings[selectedSection]];
    }

    [self percentValueChanged: nil];

    LocalSettingsController *settings = LocalSettingsController.sharedSettings;
    specialRedemptions = [settings[@"specialRedemptions"] mutableCopy];
    [redemptionTableView reloadData];
}

- (void)setSelectedSection: (NSString *)section
{
    selectedSection = section;
    if (selectedSection != nil) {
        if (mainTab == nil) {
            // Outlets not loaded yet.
            selectionPending = true;
        } else {
            [mainTab selectTabViewItemWithIdentifier: selectedSection];
            [toolBar setSelectedItemIdentifier: selectedSection];
            [self setHeight: heightMappings[selectedSection]];
        }
    }
}

- (NSMenuItem *)createItemForAccountSelector: (BankingCategory *)account
                                 indentation: (NSUInteger)indent
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: [account localName] action: nil keyEquivalent: @""];
    item.representedObject = account;
    item.indentationLevel = indent;
    return item;
}

- (void)prepareAccountSelectors
{
    [accountSelector1 removeAllItems];
    [accountSelector2 removeAllItems];

    NSMenu *sourceMenu1 = [accountSelector1 menu];
    NSMenu *sourceMenu2 = [accountSelector2 menu];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"localName" ascending: YES];

    LocalSettingsController *settings = LocalSettingsController.sharedSettings;
    NSString *account1 = settings[@"assetGraph1"];
    NSString *account2 = settings[@"assetGraph2"];

    // Create a top level item for all banks.
    BankingCategory *category = [BankingCategory bankRoot];
    NSMenuItem *item = [self createItemForAccountSelector: category indentation: 0];
    [sourceMenu1 addItem: item];
    if ([category.name isEqualToString: account1]) {
        [accountSelector1 selectItem: item];
    }
    item = [self createItemForAccountSelector: category indentation: 0];
    [sourceMenu2 addItem: item];
    if ([category.name isEqualToString: account2]) {
        [accountSelector2 selectItem: item];
    }

    NSArray *sortDescriptors = @[sortDescriptor];
    NSArray *institutes = [category.children sortedArrayUsingDescriptors: sortDescriptors];

    // Convert list of accounts in their institutes branches to a flat list
    // usable by the selector.
    for (BankingCategory *institute in institutes) {
        if (![institute isKindOfClass: [BankAccount class]]) {
            continue;
        }

        NSArray *accounts = [[institute children] sortedArrayUsingDescriptors: sortDescriptors];
        if (accounts.count > 0) {
            item = [self createItemForAccountSelector: (BankAccount *)institute indentation: 1];
            [sourceMenu1 addItem: item];
            if ([institute.localName isEqualToString: account1]) {
                [accountSelector1 selectItem: item];
            }

            item = [self createItemForAccountSelector: (BankAccount *)institute indentation: 1];
            [sourceMenu2 addItem: item];
            if ([institute.localName isEqualToString: account1]) {
                [accountSelector2 selectItem: item];
            }

            for (BankAccount *account in accounts) {
                item = [self createItemForAccountSelector: account indentation: 2];
                [sourceMenu1 addItem: item];
                if ([account.localName isEqualToString: account1]) {
                    [accountSelector1 selectItem: item];
                }

                item = [self createItemForAccountSelector: account indentation: 2];
                [sourceMenu2 addItem: item];
                if ([account.localName isEqualToString: account2]) {
                    [accountSelector2 selectItem: item];
                }
            }
        }
    }
}

#pragma mark - Action handling

- (void)windowWillClose: (NSNotification *)aNotification
{
    int            idx;
    NSArray        *content = [fieldController content];
    NSArray        *columns = [fieldTable tableColumns];
    NSMutableArray *fields = [NSMutableArray arrayWithCapacity: 25];

    NSTableColumn  *col = columns[0];
    NSComboBoxCell *cell = [col dataCell];

    for (NSDictionary *dict in content) {
        idx = [cell indexOfItemWithObjectValue: dict[@"fieldName"]];
        if (idx >= 0) {
            [fields addObject: exportFields[idx]];
        }
    }
    if (fields.count > 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject: fields forKey: @"Exporter.fields"];
    }
}

// remove keychain values of all accounts
- (IBAction)removePINs: (id)sender
{
    int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP165", nil),
                                      NSLocalizedString(@"AP166", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      nil
                                      );
    if (res != NSAlertAlternateReturn) {
        return;
    }

    [Keychain deletePasswordsForService: @"Pecunia PIN"];
}

- (IBAction)changePassword:(id)sender
{
    BOOL passwordStored = NO;
    
    NewPasswordController *pwController = [[NewPasswordController alloc] initWithText: NSLocalizedString(@"AP175", nil)
                                                                                title: nil];
    int res = [NSApp runModalForWindow: [pwController window]];
    if (res) {
        return;
    }
    NSString *newPassword = [pwController result];
    
    if ([MOAssistant.sharedAssistant changePassword:newPassword]) {
        // was the old password in key store?
        NSString *passwd = [Keychain passwordForService: @"Pecunia" account: @"DataFile"];
        if (passwd) {
            passwordStored = YES;
        }
        [Keychain setPassword: newPassword forService: @"Pecunia" account: @"DataFile" store: passwordStored];
        
        NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                        NSLocalizedString(@"AP176", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
    }
}


- (IBAction)changeFileLocation: (id)sender
{
    MOAssistant *assistant = [MOAssistant sharedAssistant];
    [assistant relocate];
}

- (IBAction)useFileLocation:(id)sender
{
    [[MOAssistant sharedAssistant] useExistingDataFile:nil];
}


- (IBAction)restoreFileLocation: (id)sender
{
    [[MOAssistant sharedAssistant] relocateToStandard];
}

- (IBAction)openFileLocation: (id)sender
{
    [NSWorkspace.sharedWorkspace openURL: MOAssistant.sharedAssistant.dataDirURL];
}

- (IBAction)encryptData: (id)sender
{
    if (encrypt) {
        // Backup reminder
        int res = NSRunAlertPanel(NSLocalizedString(@"AP173", nil),
                                  NSLocalizedString(@"AP174", nil),
                                  NSLocalizedString(@"AP3", nil),
                                  NSLocalizedString(@"AP4", nil),
                                  nil);
        if (res != NSAlertDefaultReturn) {
            [encryptButton setState:NSOffState];
            return;
        }
        
        // check if passwort is already defined. If yes, it must(!) be taken
        NSString *passwd = [Keychain passwordForService: @"Pecunia" account: @"DataFile"];
        if (passwd != nil) {
            [passw1Field setStringValue: passwd];
            [passw2Field setStringValue: passwd];
            [passw1Field setEnabled: NO];
            [passw2Field setEnabled: NO];
        }

        [NSApp  beginSheet: encryptionSheet
            modalForWindow: [self window]
             modalDelegate: self
            didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
               contextInfo: NULL];

    } else {
        // stop encryption
        NSError *error = nil;
        
        int res = NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                                  NSLocalizedString(@"AP161", nil),
                                  NSLocalizedString(@"AP4", nil),
                                  NSLocalizedString(@"AP3", nil),
                                  nil);
        if (res == NSAlertAlternateReturn) {
            MOAssistant *assistant = [MOAssistant sharedAssistant];

            BOOL           passwordOk = NO;
            PasswordWindow *pwWindow = [[PasswordWindow alloc] initWithText: NSLocalizedString(@"AP163", nil)
                                                                      title: NSLocalizedString(@"AP162", nil)];
            [pwWindow disablePasswordSave];
            while (passwordOk == NO) {
                [[self window] makeKeyAndOrderFront: self];
                int res = [NSApp runModalForWindow: [pwWindow window]];
                if (res) {
                    [pwWindow closeWindow];
                    [[self window] makeKeyAndOrderFront: self];
                    [self setValue: @YES forKey: @"encrypt"];
                    return;
                }

                NSString *passwd = [pwWindow result];
                if (passwd != nil) {
                    passwordOk = [assistant checkDataPassword: passwd];
                }
                if (passwordOk == NO) {
                    [pwWindow retry];
                }

            }
            [pwWindow closeWindow];
            
            [assistant.context save:&error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }

            if ([assistant stopEncryption]) {
                [Keychain deletePasswordForService: @"Pecunia" account: @"DataFile"];
                NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                                NSLocalizedString(@"AP154", nil),
                                NSLocalizedString(@"AP1", nil),
                                nil,
                                nil);
            }
        } else {
            [encryptButton setState:NSOnState];
        }
    }
}

- (void)sheetDidEnd: (NSWindow *)sheet
         returnCode: (int)code
        contextInfo: (void *)context
{
    if (code == 0) {
        // now create
        NSError *error = nil;
        MOAssistant *assistant = [MOAssistant sharedAssistant];
        [assistant.context save:&error];
        if (error) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return;
        }
        if ([assistant encryptDataWithPassword: password]) {
            [encryptButton setEnabled: NO];
            NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                            NSLocalizedString(@"AP155", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil,
                            nil);
            return;
        }
    }
    // No success
    [self setValue: @NO forKey: @"encrypt"];
}

- (IBAction)cancelSheet: (id)sender
{
    [encryptionSheet orderOut: sender];
    [NSApp endSheet: encryptionSheet returnCode: 1];
}

- (IBAction)endSheet: (id)sender
{
    NSString *passw1 = [passw1Field stringValue];
    NSString *passw2 = [passw2Field stringValue];
    if ([passw1 length] < 8) {
        NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                        NSLocalizedString(@"AP168", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil,
                        nil);
        return;
    }

    if ([passw1 isEqualToString: passw2] == NO) {
        NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                        NSLocalizedString(@"AP169", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil,
                        nil);
        return;
    }

    password = passw1;

    if (savePassword) {
        [Keychain setPassword: password forService: @"Pecunia" account: @"DataFile" store: savePassword];
    }

    [encryptionSheet orderOut: sender];
    [NSApp endSheet: encryptionSheet returnCode: 0];
}

- (IBAction)expSepTab: (id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: @"\t" forKey: EXPORT_SEPARATOR];
}

- (IBAction)expSepSemi: (id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: @";" forKey: EXPORT_SEPARATOR];
}

- (IBAction)expSepLine: (id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: @"|" forKey: EXPORT_SEPARATOR];
}

- (void)setHeight: (NSNumber *)value
{
    NSRect frame = self.window.frame;
    int    pos = frame.origin.y + frame.size.height;
    frame.size.height = value.intValue;
    frame.origin.y = pos - value.intValue;
    [self.window setFrame: frame display: YES animate: YES];
}

- (IBAction)toolbarClicked: (id)sender
{
    selectedSection = [sender itemIdentifier];
    [mainTab selectTabViewItemWithIdentifier: selectedSection];
    [self setHeight: heightMappings[selectedSection]];
}

- (IBAction)resetAllColors: (id)sender
{
    for (unsigned i = 0; i < sizeof(colorEntries) / sizeof(colorEntries[0]); i++) {
        NSArray *values = [@(colorEntries[i])componentsSeparatedByString : @"|"];
        [NSColor resetApplicationColorForKey: values[1]];
    }
    [colorListView reloadData];
}

- (IBAction)lookupSymbol: (id)sender
{
    NSString *value;
    NSProgressIndicator *indicator;
    NSButton *button;
    switch ([sender tag]) {
        case 0:
            value = stockField1.stringValue;
            indicator = progressIndicator1;
            button = lookupButton1;
            break;
        case 1:
            value = stockField2.stringValue;
            indicator = progressIndicator2;
            button = lookupButton2;
            break;
        case 2:
            value = stockField3.stringValue;
            indicator = progressIndicator3;
            button = lookupButton3;
            break;
    }

    NSMenu *menu = [button.cell menu];
    if (menu == nil) {
        menu = [[NSMenu alloc] init];
        [button.cell setMenu: menu];
    } else {
        [menu removeAllItems];
    }

    if (value.length == 0) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"AP733", nil)
                                                      action: nil
                                               keyEquivalent: @""];
        item.enabled = NO;
        [menu addItem: item];
    } else {
        [indicator startAnimation: self];
        NSError *error;
        NSDictionary *data = [YahooStockData lookupSymbol: value error: &error];
        for (NSString *key in data.allKeys) {
            NSArray *entries = data[key];

            // Exchange name.
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: key
                                                          action: nil
                                                   keyEquivalent: @""];
            item.enabled = NO;
            [menu addItem: item];

            // The symbols.
            for (NSDictionary *details in entries) {
                item = [[NSMenuItem alloc] initWithTitle: details[@"name"]
                                                  action: @selector(symbolSelected:)
                                           keyEquivalent: @""];
                item.representedObject = details[@"symbol"];
                item.indentationLevel = 1;
                item.tag = [sender tag]; // To indicate which field to update.
                [menu addItem: item];
            }
        }
        [indicator stopAnimation: self];
    }

    int windowNumber = [self.window windowNumber];
    NSRect frame = button.frame;

    NSPoint wp = {0, NSHeight(frame)};
    wp = [button convertPoint: wp toView: nil];
    NSEvent* event = [NSEvent otherEventWithType: NSApplicationDefined
                                        location: wp
                                   modifierFlags: NSApplicationDefined
                                       timestamp: 0
                                    windowNumber: windowNumber
                                         context: NSGraphicsContext.currentContext
                                         subtype: 0
                                           data1: 0
                                           data2: 0];
    
    [NSMenu popUpContextMenu: menu withEvent:event forView: button];
}

- (void)symbolSelected: (id)sender
{
    NSTextField *field;
    switch ([sender tag]) {
        case 0:
            field = stockField1;
            break;
        case 1:
            field = stockField2;
            break;
        case 2:
            field = stockField3;
            break;
    }

    field.stringValue = [sender representedObject];
    NSDictionary *bindingInfo = [field infoForBinding: NSValueBinding];
    [[bindingInfo valueForKey: NSObservedObjectKey] setValue: field.stringValue
                                                  forKeyPath: [bindingInfo valueForKey: NSObservedKeyPathKey]];
}

- (IBAction)assetGraphChanged: (id)sender
{
    LocalSettingsController *settings = LocalSettingsController.sharedSettings;
    settings[@"assetGraph1"] = [(BankingCategory *)accountSelector1.selectedItem.representedObject name];
    settings[@"assetGraph2"] = [(BankingCategory *)accountSelector2.selectedItem.representedObject name];
}

- (IBAction)percentValueChanged: (id)sender
{
    LocalSettingsController *settings = LocalSettingsController.sharedSettings;
    NSNumber *loan = settings[@"loanValue"];
    NSNumber *interest = settings[@"interestRate"];
    NSNumber *redemption = settings[@"redemptionRate"];

    NSDecimalNumber *thousandTwoHundered = [NSDecimalNumber decimalNumberWithDecimal: @(1200).decimalValue];

    NSDecimalNumber *initialInterest = [NSDecimalNumber decimalNumberWithDecimal: interest.decimalValue];
    NSDecimalNumber *borrowedAmount = [NSDecimalNumber decimalNumberWithDecimal: loan.decimalValue];
    NSDecimalNumber *initialRedemption = [NSDecimalNumber decimalNumberWithDecimal: redemption.decimalValue];

    initialInterest = [initialInterest decimalNumberByDividingBy: thousandTwoHundered];
    initialInterest = [initialInterest decimalNumberByMultiplyingBy: borrowedAmount];
    initialInterest = [initialInterest decimalNumberByRoundingAccordingToBehavior: roundUp];

    initialRedemption = [initialRedemption decimalNumberByDividingBy: thousandTwoHundered];
    initialRedemption = [initialRedemption decimalNumberByMultiplyingBy: borrowedAmount];
    initialRedemption = [initialRedemption decimalNumberByRoundingAccordingToBehavior: roundDown];

    NSDecimalNumber *monthlyRate = [initialInterest decimalNumberByAdding: initialRedemption];
    montlyRateLabel.objectValue = monthlyRate;
}

- (IBAction)loanDateChanged: (id)sender
{
    NSDate *date = [[ShortDate dateWithYear: yearSelector.selectedTag
                                      month: monthSelector.selectedTag
                                        day: 1] lowDate];
    LocalSettingsController.sharedSettings[@"loanStartDate"] = date;
}

- (IBAction)showSpecialRedemptionDatePopover: (id)sender
{
    if (!redemptionPopover.shown) {
        [redemptionPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinXEdge];
    }
}

- (IBAction)addRedemptionDate:(id)sender
{
    if (specialRedemptions == nil) {
        specialRedemptions = [[NSMutableArray alloc] init];
    }

    // Add another entry like the last one just one year later.
    NSDictionary *entry = specialRedemptions.lastObject;
    NSDictionary *newEntry;
    if (entry == nil) {
        newEntry = @{@"date": ShortDate.currentDate, @"amount": @0};
    } else {
        newEntry = @{@"date": [entry[@"date"] dateByAddingUnits: 1 byUnit: NSCalendarUnitYear],
                     @"amount": entry[@"amount"]};
    }
    [specialRedemptions addObject: newEntry];
    [redemptionTableView reloadData];
}

#pragma mark - Tabview delegate methods

- (void)tabView: (NSTabView *)tabView didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
    [[self window] setTitle: [tabViewItem label]];
}

#pragma mark - NSTableViewDataSource protocol

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return specialRedemptions.count;
}

- (NSView *)tableView: (NSTableView *)tableView
   viewForTableColumn: (NSTableColumn *)tableColumn
                  row: (NSInteger)row
{
    RedemptionCellView *cell = [tableView makeViewWithIdentifier: @"redemptionCellView" owner: nil];
    cell.delegate = self;
    cell.objectValue = specialRedemptions[row];
    [cell prepareForStartDate: [ShortDate dateWithDate: LocalSettingsController.sharedSettings[@"loanStartDate"]] ];
    return cell;
}

- (void)removeRedemption: (id)cell
{
    [specialRedemptions removeObject: [cell objectValue]];
    [redemptionTableView reloadData];

    LocalSettingsController.sharedSettings[@"specialRedemptions"] = specialRedemptions;
}

- (void)redemptionDateChanged: (ShortDate *)newDate cell: (id)cell
{
    NSDictionary *entry = [cell objectValue];
    NSInteger index = [redemptionTableView rowForView: cell];

    NSDictionary *newEntry = @{@"date":  newDate, @"amount": entry[@"amount"]};
    [specialRedemptions replaceObjectAtIndex: index withObject: newEntry];

    LocalSettingsController.sharedSettings[@"specialRedemptions"] = specialRedemptions;
}

- (void)redemptionAmountChanged: (NSNumber *)newAmount cell: (id)cell
{
    NSDictionary *entry = [cell objectValue];
    NSInteger index = [redemptionTableView rowForView: cell];

    NSDictionary *newEntry = @{@"date":  entry[@"date"], @"amount": newAmount};
    [specialRedemptions replaceObjectAtIndex: index withObject: newEntry];

    LocalSettingsController.sharedSettings[@"specialRedemptions"] = specialRedemptions;
}

#pragma mark - Convenience + constant preferences

+ (BOOL)showCategoryColorsInTree
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: @"showCatColorsInTree"];
}

+ (BOOL)showHiddenCategories
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: @"showHiddenCategories"];
}

static NSString *baseFontName = @"HelveticaNeue";

+ (NSString*)mainFontName
{
    return [baseFontName stringByAppendingString: @"-Light"];
}

+ (NSString*)mainFontNameMedium
{
    return [baseFontName stringByAppendingString: @"-Medium"];
}

+ (NSString*)mainFontNameBold
{
    return [baseFontName stringByAppendingString: @"-Bold"];
}

+ (NSString*)popoverFontName
{
    return [baseFontName stringByAppendingString: @"-Light"];
}

/**
 * Returns a font instance for the given font name and base size. The size is increased implictely depending
 * on user settings.
 */
+ (NSFont *)fontNamed: (NSString *)name baseSize: (CGFloat)size
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults objectForKey: @"fontScale"] != nil) {
        double scale = [defaults doubleForKey: @"fontScale"];
        if (scale >= 0.75 && scale <= 1.5) {
            size *= scale;
        }
    }
    return [NSFont fontWithName: name size: size];
    //return [NSFont systemFontOfSize: size];
}

#pragma mark - Color ListView delegate protocol

static char *colorEntries[] = {
    "AP700|Positive Plot Gradient (high)|AP652",
    "AP701|Positive Plot Gradient (low)",
    "AP702|Negative Plot Gradient (high)",
    "AP703|Negative Plot Gradient (low)",
    "AP704|Turnovers Plot Gradient (high)",
    "AP705|Turnovers Plot Gradient (low)",
    "AP706|Selection Plot Gradient (high)",
    "AP707|Selection Plot Gradient (low)",
    "AP708|Selection Band",
    "AP709|Bank Account Trend Line",
    "AP710|Category Trend Line",
    "AP720|Positive Cash|AP653",
    "AP721|Negative Cash",
    "AP722|Disabled Tree Item",
    "AP723|Cell Selection Gradient (high)",
    "AP724|Cell Selection Gradient (low)",
    "AP725|Grid Partial Selection",
    "AP726|Selection Gradient (high)",
    "AP727|Selection Gradient (low)",
    "AP728|Small Background Gradient (high)",
    "AP729|Small Background Gradient (low)",
    "AP730|Pale Text",
    "AP731|Unread Transfer",
    "AP732|Uncategorized Transfer",
};

- (NSUInteger)numberOfRowsInListView: (PXListView *)listView
{
    return sizeof(colorEntries) / sizeof(colorEntries[0]);
}

- (CGFloat)listView: (PXListView *)aListView heightOfRow: (NSUInteger)row forDragging: (BOOL)forDragging
{
    return (row == 0 || row == 11) ? 50 : 40;
}

- (NSRange)listView: (PXListView *)aListView rangeOfDraggedRow: (NSUInteger)row
{
    return NSMakeRange(0, 0);
}

- (PXListViewCell *)listView: (PXListView *)aListView cellForRow: (NSUInteger)row
{
    ColorListViewCell *cell = (ColorListViewCell *)[aListView dequeueCellWithReusableIdentifier: @"colorcell"];

    if (!cell) {
        cell = [ColorListViewCell cellLoadedFromNibNamed: @"Preferences" reusableIdentifier: @"colorcell"];
    }

    [cell configureWithString: @(colorEntries[row])];
    return cell;
}

- (bool)listView: (PXListView *)aListView shouldSelectRows: (NSIndexSet *)rows byExtendingSelection: (BOOL)shouldExtend
{
    return NO;
}

- (BOOL)listView: (PXListView *)aListView writeRowsWithIndexes: (NSIndexSet *)rowIndexes
    toPasteboard: (NSPasteboard *)dragPasteboard
       slideBack: (BOOL *)slideBack
{
    return NO; // No dragging please.
}

@end
