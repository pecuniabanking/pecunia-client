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

#import <QuartzCore/QuartzCore.h>

#import "BWGradientBox.h"

#import "PreferenceController.h"
#import "MOAssistant.h"
#import "Keychain.h"
#import "BankingController.h"
#import "PasswordWindow.h"
#import "GraphicsAdditions.h"

#import "YahooStockData.h"

static NSArray *exportFields = nil;

#define EXPORT_SEPARATOR @"exportSeparator"

#define GENERAL_HEIGHT    310
#define HOMESCREEN_HEIGHT 310
#define SEC_HEIGHT        260
#define LOC_HEIGHT        260
#define DISPLAY_HEIGHT    320
#define COLOR_HEIGHT      450
#define EXP_HEIGHT        375
#define PRINT_HEIGHT      200

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

@implementation PreferenceController

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
    }
    return self;
}

- (void)awakeFromNib
{
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
    MOAssistant *assistant = [MOAssistant assistant];
    encrypt = [assistant encrypted];
    [self setValue: @([assistant encrypted]) forKey: @"encrypt"];
    [dataFileField setStringValue: [assistant dataFilename]];

    // Select first tab.
    [toolBar setSelectedItemIdentifier: @"general"];
    [mainTab selectTabViewItemAtIndex: 0];
    [mainTab setTabViewType: NSNoTabsNoBorder];

    [self setHeight: GENERAL_HEIGHT];

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
    colorListView.delegate = self;
    [colorListView reloadData];

}

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

- (IBAction)changeFileLocation: (id)sender
{
    MOAssistant *assistant = [MOAssistant assistant];
    [assistant relocate];
}

- (IBAction)useFileLocation:(id)sender
{
    [[MOAssistant assistant] useExistingDataFile];
}


- (IBAction)restoreFileLocation: (id)sender
{
    [[MOAssistant assistant] relocateToStandard];
}

- (IBAction)openFileLocation: (id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [MOAssistant assistant].dataDirURL];
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
        int res = NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                                  NSLocalizedString(@"AP161", nil),
                                  NSLocalizedString(@"AP4", nil),
                                  NSLocalizedString(@"AP3", nil),
                                  nil);
        if (res == NSAlertAlternateReturn) {
            MOAssistant *assistant = [MOAssistant assistant];

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
        MOAssistant *assistant = [MOAssistant assistant];
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

- (void)setHeight: (int)h
{
    NSWindow *window = [self window];
    NSRect   frame = window.frame;
    int      pos = frame.origin.y + frame.size.height;
    frame.size.height = h;
    frame.origin.y = pos - h;
    [window setFrame: frame display: YES animate: YES];
}

- (IBAction)synchSettings: (id)sender
{
    [mainTab selectTabViewItemAtIndex: 0];
    [self setHeight: GENERAL_HEIGHT];
}

- (IBAction)homeScreenSettings: (id)sender
{
    [mainTab selectTabViewItemAtIndex: 1];
    [self setHeight: HOMESCREEN_HEIGHT];
}

- (IBAction)securitySettings: (id)sender
{
    [mainTab selectTabViewItemAtIndex: 2];
    [self setHeight: SEC_HEIGHT];
}

- (IBAction)locationSettings: (id)sender
{
    [mainTab selectTabViewItemAtIndex: 3];
    [self setHeight: LOC_HEIGHT];
}

- (IBAction)displaySettings: (id)sender
{
    [mainTab selectTabViewItemAtIndex: 4];
    [self setHeight: DISPLAY_HEIGHT];
}

- (IBAction)colorSettings: (id)sender
{
    [mainTab selectTabViewItemAtIndex: 5];
    [self setHeight: COLOR_HEIGHT];
}

- (IBAction)exportSettings: (id)sender
{
    [mainTab selectTabViewItemAtIndex: 6];
    [self setHeight: EXP_HEIGHT];
}

- (IBAction)printSettings: (id)sender
{
    [mainTab selectTabViewItemAtIndex: 7];
    [self setHeight: PRINT_HEIGHT];
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

- (void)tabView: (NSTabView *)tabView didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
    [[self window] setTitle: [tabViewItem label]];
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

+ (NSString*)mainFontName
{
    return @"HelveticaNeue-Light";
}

+ (NSString*)mainFontNameMedium
{
    return @"HelveticaNeue-Medium";
}

+ (NSString*)mainFontNameBold
{
    return @"HelveticaNeue-Bold";
}

+ (NSString*)mainFontNameLight
{
    return @"HelveticaNeue-UltraLight";
}

+ (NSString*)popoverFontName
{
    return @"HelveticaNeue-Light";
}

#pragma mark -
#pragma mark ListView delegate protocol

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
    "AP709|Bank Account Average Line",
    "AP710|Category Average Line",
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
