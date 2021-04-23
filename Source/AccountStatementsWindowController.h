//
//  AccountStatementsWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 08.04.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

#ifndef AccountStatementsWindowController_h
#define AccountStatementsWindowController_h

#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface AccountStatementsWindowController : NSObject <PecuniaSectionItem>
{
    IBOutlet NSView   *topView;
    IBOutlet PDFView  *pdfView;

    IBOutlet NSTextField *statusField;
    IBOutlet NSTextField *title;
    IBOutlet NSImageView *bankImage;
    IBOutlet NSButton    *clearButton;

    IBOutlet NSSegmentedControl  *toggleButton;
    IBOutlet NSProgressIndicator *spinner;

    NSUInteger currentIndex;
    BOOL       messagesShown;
    NSArray    *statements;
    NSFont     *boldFont;
    NSFont     *normalFont;

    NSDateFormatter         *dateFormatter;
    NSMutableParagraphStyle *rightAlignParagraphStyle;

}

@property(nonatomic, retain) BankAccount *account;

// PecuniaSectionItem protocol.
- (NSView *)mainView;
- (void)print;
- (void)prepare;
- (void)activate;
- (void)deactivate;


@end



#endif /* AccountStatementsWindowController_h */
