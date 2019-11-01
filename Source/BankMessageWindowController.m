//
//  BankMessageWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 13.08.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

#import "BankMessageWindowController.h"
#import "MOAssistant.h"
#import "BankMessage.h"
#import "PreferenceController.h"
#import "BankUser.h"

/*
@interface BankMessageWindowController ()

@end
*/
@implementation BankMessageWindowController

- (id)init
{
    self = [super initWithWindowNibName: @"BankMessageWindow"];
    return self;
}

- (void)windowDidLoad {
    NSError *error = nil;
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankMessage" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    [request setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO]]];
    NSArray *messages = [context executeFetchRequest: request error: &error];
    if (error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateIntervalFormatterLongStyle;
    
    NSFont *boldFont = [NSFont fontWithName: PreferenceController.mainFontNameBold size: 12];
    NSDictionary *boldAttributes = @{
                                     NSFontAttributeName: boldFont,
                                     NSForegroundColorAttributeName: NSColor.blackColor
                                     };

    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];
    NSAttributedString *ret = [[NSAttributedString alloc] initWithString:@"\n"];
    for (BankMessage *message in messages) {
        NSString *bankName = nil;
        NSArray *users = [BankUser allUsers];
        for (BankUser *user in users) {
            if ([user.bankCode isEqualToString:message.bankCode] && user.bankName != nil) {
                bankName = user.bankName;
                break;
            }
        }
        
        if (bankName == nil) {
            BankInfo *bankInfo = [[HBCIBackend backend] infoForBankCode: message.bankCode];
            if (bankInfo.name == nil) {
                bankName = message.bankCode;
            }
        }
        
        NSString *hdString = [NSString stringWithFormat:@"%@ vom %@", bankName, [df stringFromDate:message.date]];
        NSAttributedString *header = [[NSAttributedString alloc] initWithString:hdString attributes:boldAttributes];
        NSAttributedString *info = [[NSAttributedString alloc] initWithString:message.message];
        [s appendAttributedString:header];
        [s appendAttributedString:ret];
        [s appendAttributedString: info];
        [s appendAttributedString:ret];
        [s appendAttributedString:ret];
    }
    
    self.content = s;
}

@end
