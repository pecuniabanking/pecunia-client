//
//  CreditCardSettlementController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 31.01.13.
//  Copyright (c) 2013 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@class BankAccount;

@interface CreditCardSettlementController : NSWindowController
{
    IBOutlet PDFView  *pdfView;
    IBOutlet NSButton *prevButton;
    IBOutlet NSButton *nextButton;

    BankAccount *account;
    NSArray     *settlements;
    NSUInteger  currentIndex;
}

@property (nonatomic, strong) BankAccount *account;
@property (nonatomic, strong) NSArray     *settlements;

- (IBAction)next: (id)sender;
- (IBAction)prev: (id)sender;
- (IBAction)updateSettlements: (id)sender;

@end
