//
//  ChipcardDataWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 21.08.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

#import "ChipcardDataWindowController.h"

@interface ChipcardDataWindowController ()

@end

@implementation ChipcardDataWindowController

- (void)awakeFromNib {
    
    if (self.fields == nil) {
        self.fields = [[NSMutableDictionary alloc] init];
    }
    self.fields[@"name"] = self.bankData.name;
    self.fields[@"bankCode"] = self.bankData.bankCode;
    self.fields[@"userId"] = self.bankData.userId;
    self.fields[@"host"] = self.bankData.host;
}

- (void)controlTextDidChange: (NSNotification *)aNotification {
    NSTextField *te = [aNotification object];
    NSUInteger  maxLen;
    
    switch(te.tag) {
        case 10: maxLen = 20; break;
        case 20: maxLen = 8; break;
        case 30: maxLen = 30; break;
        case 40: maxLen = 28; break;
        default: maxLen = 0;
    }

    if ([[te stringValue] length] > maxLen) {
        [te setStringValue:  [[te stringValue] substringToIndex: maxLen]];
        NSBeep();
        return;
    }
    return;
}


- (void)windowWillClose: (NSNotification *)aNotification {
    [NSApp stopModal];
}

- (void)close:(id)sender {
    [self.window close];
//    [NSApp stopModal];
}

- (void)write:(id)sender {
    [self.dataController commitEditing];
    
    self.bankData.name = self.fields[@"name"];
    self.bankData.bankCode = self.fields[@"bankCode"];
    self.bankData.userId = self.fields[@"userId"];
    self.bankData.host = self.fields[@"host"];
    
    NSInteger res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP11", nil),
                                            NSLocalizedString(@"AP370", nil),
                                            NSLocalizedString(@"AP2", nil),
                                            NSLocalizedString(@"AP3", nil), nil);
    
    if (res == NSAlertDefaultReturn) {
        return;
    }
    
    if ([self.manager writeBankData:self.bankData]) {
        NSRunAlertPanel(NSLocalizedString(@"AP71", nil),
                        NSLocalizedString(@"AP371", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
    } else {
        NSRunAlertPanel(NSLocalizedString(@"AP83", nil),
                        NSLocalizedString(@"AP372", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
    }
}


@end
