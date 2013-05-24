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

#import "NewBankUserController.h"
#import "BankingController.h"
#import "HBCIClient.h"
#import "PecuniaError.h"
#import "LogController.h"
#import "BankParameter.h"
#import "BankInfo.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "BankSetupInfo.h"
#import "TanSigningOption.h"

#import "AnimationHelper.h"
#import "BWGradientBox.h"

@interface NewBankUserController (Private)

- (BOOL)check;
- (void)prepareUserSheet;
- (void)startProgressWithMessage: (NSString *)msg;
- (void)stopProgress;

@end

@implementation NewBankUserController

- (id)initForController: (BankingController *)con
{
    self = [super initWithWindowNibName: @"BankUser"];
    bankController = con;
    bankUsers = [[BankUser allUsers] mutableCopy];
    context = [[MOAssistant assistant] context];
    triedFirst = NO;
    return self;
}

- (void)awakeFromNib
{
    [hbciVersions setContent: [[HBCIClient hbciClient] supportedVersions]];
    [hbciVersions setSelectedObjects: @[@"220"]];

    // Manually set up properties which cannot be set via user defined runtime attributes (Color is not available pre XCode 4).
    topGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    topGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];
    backgroundGradient.fillColor = [NSColor whiteColor];

    // Sicherheitsverfahren
    currentBox = pinTanBox;
}

#pragma mark -
#pragma mark Data handling

- (BankUser *)selectedUser
{
    NSArray *selection = [bankUserController selectedObjects];
    if (selection == nil || [selection count] < 1) {
        return nil;
    }
    return [selection lastObject];
}

#pragma mark -
#pragma mark Window/sheet handling

- (void)startProgressWithMessage: (NSString *)msg
{
    [msgField setStringValue: msg];
    [msgField display];
    [progressIndicator setUsesThreadedAnimation: YES];
    [progressIndicator startAnimation: self];
}

- (void)stopProgress
{
    [progressIndicator stopAnimation: self];
    [msgField setStringValue: @""];

}

- (void)userSheetDidEnd: (NSWindow *)sheet
             returnCode: (int)code
            contextInfo: (void *)context
{
    if (code != 0) {
        [currentUserController remove: self];
    }
    [[self window] makeKeyAndOrderFront: self];
}

- (void)getBankSetupInfo
{
    BankUser *currentUser = [currentUserController content];

    BankSetupInfo *info = [[HBCIClient hbciClient] getBankSetupInfo: currentUser.bankCode];
    if (info != nil) {
        if (info.info_userid) {
            NSTextField *field = [[groupBox contentView] viewWithTag: 100];
            [field setStringValue: info.info_userid];
        }
        if (info.info_customerid) {
            NSTextField *field = [[groupBox contentView] viewWithTag: 120];
            [field setStringValue: info.info_customerid];
        }
    }
    [self stopProgress];
    step = 2;
    NSView *view = [[groupBox contentView] viewWithTag: 110];
    [userSheet makeFirstResponder: view];

    [self prepareUserSheet];
}

- (IBAction)ok: (id)sender
{
    [currentUserController commitEditing];

    BankUser *currentUser = [currentUserController content];

    if (step == 0) {
        NSInteger idx = [secMethodPopup indexOfSelectedItem];
        if (idx == 1) {
            secMethod = SecMethod_DDV;
            currentUser.ddvPortIdx = @1;
            currentUser.ddvReaderIdx = @0;
        } else {
            secMethod = SecMethod_PinTan;
        }
        currentUser.secMethod = @((int)secMethod);
    }

    // PinTan
    if (secMethod == SecMethod_PinTan) {
        if ([self check] == NO) {
            return;
        }

        if (step == 1) {
            [self startProgressWithMessage: NSLocalizedString(@"AP212", nil)];
            [self performSelector: @selector(getBankSetupInfo) withObject: nil afterDelay: 0];
            return;
        }

        if (step == 2) {
            // look if we have bank infos
            BankInfo *bi = [[HBCIClient hbciClient] infoForBankCode: currentUser.bankCode inCountry: @"DE"];
            if (bi) {
                currentUser.hbciVersion = bi.pinTanVersion;
                currentUser.bankURL = bi.pinTanURL;
            }
        }

        if (step >= 2 && currentUser.hbciVersion != nil && currentUser.bankURL != nil) {
            // create user
            [self startProgressWithMessage: NSLocalizedString(@"AP157", nil)];
            PecuniaError *error = [[HBCIClient hbciClient] addBankUser: currentUser];
            if (error) {
                [self stopProgress];
                [error alertPanel];
            } else {
                // update TAN options
                [self updateTanMethods];
                [self stopProgress];

                [userSheet orderOut: sender];
                [NSApp endSheet: userSheet returnCode: 0];
            }
        }
        if (step >= 3 && currentUser.hbciVersion == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP79", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return;
        }
        if (step >= 3 && currentUser.bankURL == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP80", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return;
        }
    }

    // DDV-Access
    if (secMethod == SecMethod_DDV) {
        if ([self check] == NO) {
            return;
        }
        
        if (step == 1) {
            // get bank infos
            BankInfo *bi = [[HBCIClient hbciClient] infoForBankCode: currentUser.bankCode inCountry: @"DE"];
            if (bi) {
                currentUser.hbciVersion = bi.hbciVersion;
                currentUser.bankURL = bi.host;
                if (currentUser.hbciVersion == nil || currentUser.bankURL == nil) {
                    step = 4;
                }
            } else {
                step = 4;
            }
        }


        if (step >= 2 && currentUser.hbciVersion != nil && currentUser.bankURL != nil) {
            // Create User
            [self startProgressWithMessage: NSLocalizedString(@"AP157", nil)];
            PecuniaError *error = [[HBCIClient hbciClient] addBankUser: currentUser];
            if (error) {
                [self stopProgress];
                if (step == 2) {
                } else {
                    [error alertPanel];
                }
            } else {
                [self stopProgress];
                [userSheet orderOut: sender];
                [NSApp endSheet: userSheet returnCode: 0];
                return;
            }
        }
        if (step >= 5 && currentUser.hbciVersion == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP79", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return;
        }
        if (step >= 5 && currentUser.bankURL == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP81", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return;
        }
    }

    if (step < 6) {
        step += 1;
    }
    [self prepareUserSheet];
}

- (IBAction)cancelSheet: (id)sender
{
    [userSheet orderOut: sender];
    [NSApp endSheet: userSheet returnCode: 1];
}

- (IBAction)secMethodChanged: (id)sender
{
    [self ok: sender];
}

- (IBAction)tanOptionChanged: (id)sender
{
    NSArray *sel = [tanSigningOptions selectedObjects];
    if ([sel count] != 1) {
        return;
    }
    SigningOption *option = [sel lastObject];
    BankUser      *user = [self selectedUser];
    if (user) {
        if ([user.secMethod intValue] == SecMethod_PinTan) {
            [user setpreferredSigningOption: option];
        }
    }
}

- (void)endSheet: (id)sender
{
    [currentUserController commitEditing];
    if ([self check] == NO) {
        return;
    }
    [userSheet orderOut: sender];
    [NSApp endSheet: userSheet returnCode: 0];
}

- (BOOL)windowShouldClose: (id)sender
{
    [NSApp stopModalWithCode: 1];
    return YES;
}

- (void)windowDidBecomeKey: (NSNotification *)notification
{
    NSArray *users = [BankUser allUsers];
    if ([users count] == 0 && triedFirst == NO) {
        [self addEntry: self];
        triedFirst = YES;
    }
}

#pragma mark -
#pragma mark Input handling

- (BOOL)check
{
    BankUser *currentUser = [currentUserController content];

    if (step == 1) {
        if (currentUser.bankCode == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP51", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }
        if (currentUser.name == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP214", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }
    }


    if (step >= 2) {
        if ([currentUser userId] == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP52", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }
    }
    return YES;
}

- (void)controlTextDidChange: (NSNotification *)aNotification
{
    NSTextField *te = [aNotification object];
    NSString    *s = [te stringValue];
    BankUser    *currentUser = [currentUserController content];

    if ([te tag] == 10) {
        NSString *bankCode = [s stringByReplacingOccurrencesOfString: @" " withString: @""];
        if ([bankCode length] == 8) {
            BankInfo *bi = [[HBCIClient hbciClient] infoForBankCode: bankCode inCountry: @"DE"];
            if (bi) {
                currentUser.name = bi.name;
                [okButton setKeyEquivalent: @"\r"];
            }
        }
    }
    if ([te tag] == 110) {
        if ([s length] > 0) {
            NSString *k = [okButton keyEquivalent];
            if ([k isEqualToString: @"\r"] == NO) {
                [okButton setKeyEquivalent: @"\r"];
            }
        }
    }

}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    /*
     NSTextField	*te = [aNotification object];
     NSString *bankCode = [te stringValue];
     BankUser *currentUser = [currentUserController content ];

     BankInfo *bi = [[HBCIClient hbciClient] infoForBankCode: bankCode inCountry: @"DE"];
     if (bi) {
     currentUser.bankName = bi.name;
     currentUser.bankURL = bi.pinTanURL;
     currentUser.hbciVersion = bi.pinTanVersion;
     }
     */
}

- (void)updateTanMethods
{
    BankUser *user = [self selectedUser];
    if (user) {
        if ([user.secMethod intValue] == SecMethod_PinTan) {
            NSMutableArray *options = [[user getSigningOptions] mutableCopy];

            if ([options count] > 1) {
                // Add virtual method "Beim Senden festlegen"
                SigningOption *option = [[SigningOption alloc] init];
                option.secMethod = SecMethod_PinTan;
                option.userId = user.userId;
                option.userName = user.name;
                option.tanMethod = @"100";
                option.tanMethodName = @"Beim Senden festlegen";
                [options addObject: option];
            }
            [tanSigningOptions setContent: options];
        } else {
            [tanSigningOptions setContent: [user getSigningOptions]];
        }
        [tanSigningOptions setSelectionIndex: [user getpreferredSigningOptionIdx]];
    }
}

- (void)tableViewSelectionDidChange: (NSNotification *)aNotification
{
    [self updateTanMethods];
}

#pragma mark -
#pragma mark IB action section

- (IBAction)close: (id)sender
{
    [[self window] orderOut: self];
}

- (IBAction)add: (id)sender
{
    [[self window] close];
}

- (IBAction)allSettings: (id)sender
{
    if (step > 3) {
        return;
    }

    BankUser *currentUser = [currentUserController content];
    if (currentUser.hbciVersion == nil) {
        currentUser.hbciVersion = @"220";
    }

    NSArray *views = [[groupBox contentView] subviews];
    for (NSView *view in views) {
        if ([view tag] >= 100) {
            [[view animator] setHidden: NO];
        }
    }
    NSRect frame = [userSheet frame];
    if (step == 2) {
        frame.size.height += 119; frame.origin.y -= 119;
    } else {
        frame.size.height += 183; frame.origin.y -= 183;
    }
    [[userSheet animator] setFrame: frame display: YES];


    step = 4;
}

- (void)prepareUserSheet_PinTan
{
    NSArray *views = [[pinTanBox contentView] subviews];

    if (step == 1) {
        NSView *contentView = [userSheet contentView];
        [contentView replaceSubview: currentBox with: pinTanBox];
        currentBox = pinTanBox;
        [pinTanBox setFrame: [secSelectBox frame]];

        for (NSView *view in views) {
            if ([view tag] >= 100) {
                [view setHidden: YES];
            }
        }
        NSRect frame = [userSheet frame];
        //		frame.size.height = 406;
        //		frame.size.height -= 183; frame.origin.y += 183;
        frame.size.height += 17; frame.origin.y -= 17;
        [[userSheet animator] setFrame: frame display: YES];

        [userSheet makeFirstResponder: [contentView viewWithTag: 10]];
    }
    if (step == 2) {
        for (NSView *view in views) {
            if ([view tag] >= 100 && [view tag] <= 110) {
                [[view animator] setHidden: NO];
            }
        }
        NSRect frame = [userSheet frame];
        frame.size.height += 32; frame.origin.y -= 32;
        [[userSheet animator] setFrame: frame display: YES];

        [userSheet makeFirstResponder: [[userSheet contentView] viewWithTag: 110]];
    }
    if (step == 3) {
        for (NSView *view in views) {
            if ([view tag] > 110) {
                [[view animator] setHidden: NO];
            }
        }
        NSRect frame = [userSheet frame];
        frame.size.height += 151; frame.origin.y -= 151;
        [[userSheet animator] setFrame: frame display: YES];
    }

}

- (void)prepareUserSheet_DDV
{
    NSArray *views = [[ddvBox contentView] subviews];

    if (step == 1) {
        // switch to DDV box
        NSView *contentView = [userSheet contentView];
        [contentView replaceSubview: currentBox with: ddvBox];
        currentBox = ddvBox;
        [ddvBox setFrame: [secSelectBox frame]];

        // set default values
        BankUser *user = [currentUserController content];
        user.ddvPortIdx = @1;
        user.ddvReaderIdx = @0;

        for (NSView *view in views) {
            if ([view tag] >= 100) {
                [view setHidden: YES];
            }
        }
        // set size
        NSRect frame = [userSheet frame];
        frame.size.height += 20; frame.origin.y -= 20;
        [[userSheet animator] setFrame: frame display: YES];
        [userSheet makeFirstResponder: [contentView viewWithTag: 10]];
    }
    if (step == 2) {
        for (NSView *view in views) {
            if ([view tag] >= 100 && [view tag] <= 110) {
                [[view animator] setHidden: NO];
            }
        }
        NSRect frame = [userSheet frame];
        frame.size.height += 32; frame.origin.y -= 32;
        [[userSheet animator] setFrame: frame display: YES];
        [userSheet makeFirstResponder: [[userSheet contentView] viewWithTag: 110]];
    }
    if (step == 3) {
        for (NSView *view in views) {
            if ([view tag] > 110 && [view tag] <= 130) {
                [[view animator] setHidden: NO];
            }
        }
        NSRect frame = [userSheet frame];
        frame.size.height += 64; frame.origin.y -= 64;
        [[userSheet animator] setFrame: frame display: YES];
    }
    if (step == 4) {
        for (NSView *view in views) {
            if ([view tag] > 110) {
                [[view animator] setHidden: NO];
            }
        }
        NSRect frame = [userSheet frame];
        frame.size.height += 87; frame.origin.y -= 87;
        [[userSheet animator] setFrame: frame display: YES];
    }
    if (step == 5) {
        for (NSView *view in views) {
            if ([view tag] >= 100) {
                [[view animator] setHidden: NO];
            }
        }
        NSRect frame = [userSheet frame];
        frame.size.height += 183; frame.origin.y -= 183;
        [[userSheet animator] setFrame: frame display: YES];
    }


}

- (void)prepareUserSheet
{
    //[okButton setKeyEquivalent:@"\r" ];
    if (step == 0) {
        NSRect frame = [userSheet frame];
        frame.size.height = 406;
        frame.size.height -= 200; frame.origin.y += 200;
        [userSheet setFrame: frame display: YES];

        NSView *contentView = [userSheet contentView];
        if (currentBox != secSelectBox) {
            [contentView replaceSubview: currentBox with: secSelectBox];
            currentBox = secSelectBox;
            [secSelectBox setFrame: NSMakeRect(110, 60, 549, 120)];
        }

        return;
    }

    if (secMethod == SecMethod_PinTan) {
        [self prepareUserSheet_PinTan];
    }
    if (secMethod == SecMethod_DDV) {
        [self prepareUserSheet_DDV];
    }
}

- (IBAction)addEntry: (id)sender
{
    BankUser *user = [NSEntityDescription insertNewObjectForEntityForName: @"BankUser" inManagedObjectContext: context];
    [currentUserController setContent: user];

    step = 0;

    [self prepareUserSheet];

    [NSApp  beginSheet: userSheet
        modalForWindow: [self window]
         modalDelegate: self
        didEndSelector: @selector(userSheetDidEnd:returnCode:contextInfo:)
           contextInfo: NULL];
}

- (IBAction)removeEntry: (id)sender
{
    NSError *error = nil;

    BankUser *user = [self selectedUser];
    if (user == nil) {
        return;
    }

    if (user.userId == nil) {
        [bankUserController remove: self];
        return;
    }

    if ([[HBCIClient hbciClient] deleteBankUser: user] == TRUE) {
        // remove user from all related bank accounts
        NSMutableSet *accounts = [user mutableSetValueForKey: @"accounts"];
        for (BankAccount *account in accounts) {
            // check if userId must be deleted or changed
            if ([account.userId isEqualToString: user.userId]) {
                NSMutableSet *users = [account mutableSetValueForKey: @"users"];
                account.userId = nil;
                account.customerId = nil;
                for (BankUser *accUser in users) {
                    if ([accUser.userId isEqualToString: user.userId] == NO) {
                        account.userId = accUser.userId;
                        account.customerId = accUser.customerId;
                    }
                }
            }
        }
        [bankUserController remove: self];
        [self updateTanMethods];

        // save updates
        if ([context save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return;
        }
    }
}

- (IBAction)changePinTanMethod: (id)sender
{
    BankUser *user = [self selectedUser];
    if (user == nil) {
        return;
    }
    PecuniaError *error = [[HBCIClient hbciClient] changePinTanMethodForUser: user];
    if (error) {
        [error alertPanel];
        return;
    }
}

- (IBAction)printBankParameter: (id)sender
{
    BankUser *user = [self selectedUser];
    if (user == nil) {
        return;
    }
    LogController *logController = [LogController logController];
    MessageLog    *messageLog = [MessageLog log];
    //	[[logController window] makeKeyAndOrderFront:self];
    [logController showWindow: self];
    [logController setLogLevel: LogLevel_Info];
    BankParameter *bp = [[HBCIClient hbciClient] getBankParameterForUser: user];
    if (bp == nil) {
        [messageLog addMessage: @"Bankparameter konnten nicht ermittelt werden" withLevel: LogLevel_Error];
        return;
    }
    [messageLog addMessage: @"Bankparameterdaten:" withLevel: LogLevel_Info];
    [messageLog addMessage: bp.bpd_raw withLevel: LogLevel_Notice];

    [messageLog addMessage: @"Anwenderparameterdaten:" withLevel: LogLevel_Info];
    [messageLog addMessage: bp.upd_raw withLevel: LogLevel_Notice];
}

- (IBAction)updateBankParameter: (id)sender
{
    BankUser *user = [self selectedUser];
    if (user == nil) {
        return;
    }

    PecuniaError *error = [[HBCIClient hbciClient] updateBankDataForUser: user];
    if (error) {
        [error alertPanel];
        return;
    }

    // update TAN methods list
    if ([user.secMethod intValue] == SecMethod_PinTan) {
        [self updateTanMethods];
    }
    NSRunAlertPanel(NSLocalizedString(@"AP71", nil),
                    NSLocalizedString(@"AP100", nil),
                    NSLocalizedString(@"AP1", nil), nil, nil);
}

- (IBAction)callHelp:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://www.pecuniabanking.de/index.php/beschreibung/bankkennungen"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
