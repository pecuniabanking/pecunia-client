//
//  AccountStatementsWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 08.04.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountStatementsWindowController.h"

@implementation AccountStatementsWindowController

@synthesize selectedCategory;
@synthesize mainView;
@synthesize account;

- (void)awakeFromNib {
    dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;

    boldFont = [NSFont fontWithName: PreferenceController.mainFontNameBold size: 13];
    normalFont = [NSFont fontWithName: PreferenceController.mainFontName size: 13];

    rightAlignParagraphStyle = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
    rightAlignParagraphStyle.alignment = NSRightTextAlignment;
    
    title.stringValue = [NSString stringWithFormat: @"%@ - %@", account.bankName, account.name];
    //bankImage.image = [NSImage imageNamed: @"icon95-1" fromCollection: 1];
    //clearButton.image = [NSImage imageNamed: @"icon66-1" fromCollection: 1];

    [self readStatements];
    [self updateDisplayIncludingStatus: YES];
}

- (void)timedUpdate {
    [self updateDisplayIncludingStatus: YES];
}

- (void)updateDisplayIncludingStatus: (BOOL)withStatus {
    if (statements.count > 0) {
        AccountStatement *statement = statements[currentIndex];

        PDFDocument *document = [[PDFDocument alloc] initWithData: statement.document];
        [pdfView setDocument: document];

        if (withStatus) {
            NSString *startDate = [dateFormatter stringFromDate: statement.startDate];
            NSString *endDate = [dateFormatter stringFromDate: statement.endDate];
            unsigned year = [ShortDate dateWithDate: statement.startDate].year;

            NSDictionary *attributes = @{
                NSFontAttributeName: normalFont,
                NSParagraphStyleAttributeName: rightAlignParagraphStyle
            };

            NSString *text = [NSString stringWithFormat: NSLocalizedString(@"AP832", nil), statement.number.intValue, year, startDate, endDate];
            statusField.attributedStringValue = [[NSAttributedString alloc] initWithString: text attributes: attributes];
        }
    } else {
        NSString *path = [NSBundle.mainBundle pathForResource: @"nostatements" ofType: @"pdf"];

        NSData      *data = [NSData dataWithContentsOfFile: path];
        PDFDocument *document = [[PDFDocument alloc] initWithData: data];
        [pdfView setDocument: document];

        if (withStatus) {
            statusField.stringValue = @"";
        }
    }
    [self updateNavigationButtons];
}

- (void)readStatements {
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];

    // fetch all existing statements for this account
    NSFetchRequest      *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"AccountStatement" inManagedObjectContext: context];
    [fetchRequest setEntity: entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"account = %@", account];
    [fetchRequest setPredicate: predicate];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"startDate" ascending: NO];
    [fetchRequest setSortDescriptors: @[sortDescriptor]];

    NSError *error = nil;
    statements = [context executeFetchRequest: fetchRequest error: &error];
    currentIndex = 0;
}

- (void)removeAllStatements {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

    for (AccountStatement *statement in statements) {
        [context deleteObject: statement];
    }
    [context save: nil];
    statements = nil;

    NSString *path = [NSBundle.mainBundle pathForResource: @"nostatements" ofType: @"pdf"];

    NSData      *data = [NSData dataWithContentsOfFile: path];
    PDFDocument *document = [[PDFDocument alloc] initWithData: data];
    [pdfView setDocument: document];
    statusField.stringValue = @"";

    [self updateNavigationButtons];
    currentIndex = -1;
}

- (void)updateNavigationButtons {
    [toggleButton setEnabled: (currentIndex + 1 < statements.count) forSegment: 0];
    [toggleButton setEnabled: (currentIndex > 0) forSegment: 1];
}

- (void)windowWillClose: (NSNotification *)aNotification {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [NSApp stopModalWithCode: 0];
}

- (void)setProgress: (NSString *)message number: (int)number year: (int)year {
    NSDictionary *attributes = @{
        NSFontAttributeName: boldFont,
    };

    NSString *text = [NSString stringWithFormat: message, number, year];
    statusField.attributedStringValue = [[NSAttributedString alloc] initWithString: text attributes: attributes];
    [statusField display];
}

- (void)retrieveStatements {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;
    
    [[BankingController controller] startRefreshAnimation];
    
    AccountStatementsHandler *handler = [[AccountStatementsHandler alloc] init:account context:context];
    if (handler != nil) {
        [handler getAccountStatementsNoException];
    }
    
    // Show the latest document.
    [self readStatements];
    [self updateDisplayIncludingStatus: YES];

    [[BankingController controller] stopRefreshAnimation];

    BOOL suppressSound = [NSUserDefaults.standardUserDefaults boolForKey: @"noSoundAfterSync"];
    if (!suppressSound) {
        NSSound *doneSound = [NSSound soundNamed: @"done.mp3"];
        if (doneSound != nil) {
            [doneSound play];
        }
    }

}

- (IBAction)clear: (id)sender {
    NSInteger res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP833", nil),
                                            NSLocalizedString(@"AP827", nil),
                                            NSLocalizedString(@"AP4", nil),
                                            NSLocalizedString(@"AP3", nil),
                                            nil
                                            );
    if (res != NSAlertAlternateReturn) {
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [self removeAllStatements];
}

- (IBAction)togglePage: (id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    if ([sender isSelectedForSegment: 0]) {
        // One page back.
        if (currentIndex < statements.count - 1) {
            currentIndex++;
            [self updateDisplayIncludingStatus: YES];
        }
    } else {
        // One page forward.
        if (currentIndex > 0) {
            currentIndex--;
            [self updateDisplayIncludingStatus: YES];
        }
    }
}

- (IBAction)updateStatements: (id)sender {
    
    // which format?
    AccountStatementParameters *params = [HBCIBackend.backend getAccountStatementParametersForUser:account.defaultBankUser];
    if (params == nil) {
        return;
    }
    if ([params supportsFormat:AccountStatement_PDF] || [params supportsFormat:AccountStatement_MT940]) {
        [self performSelector: @selector(retrieveStatements) withObject: nil afterDelay: 0.1 inModes: @[NSDefaultRunLoopMode]];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedString(@"AP83", nil)
                                         defaultButton: NSLocalizedString(@"AP1", nil)
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"AP840", nil) ];
        [alert runModal];
    }
    
}

- (IBAction)zoomIn: (id)sender {
    pdfView.scaleFactor *= 1.2;
}

- (IBAction)zoomOut: (id)sender {
    pdfView.scaleFactor /= 1.2;
}


#pragma mark -
#pragma mark PecuniaSectionItem protocol

- (void)print
{
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    [printInfo setHorizontalPagination: NSFitPagination];
    [printInfo setVerticalPagination: NSFitPagination];
    NSPrintOperation *printOp;

    printOp = [NSPrintOperation printOperationWithView: pdfView printInfo: printInfo];

    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];
}

- (void)setSelectedCategory:(BankingCategory *)selectedCategory {
    statements = [NSArray array];
    if ([selectedCategory isBankAccount] && selectedCategory.accountNumber != nil) {
        self.account = (BankAccount*)selectedCategory;
        if ([HBCIBackend.backend isTransactionSupportedForAccount:TransactionType_AccountStatements account:account]) {
            title.stringValue = [NSString stringWithFormat: @"%@ - %@", account.bankName, account.name];
            [self readStatements];
            [self updateDisplayIncludingStatus: YES];
            return;
        }
    }
    self.account = nil;
    [self updateDisplayIncludingStatus: YES];
}

- (NSView *)mainView
{
    return topView;
}

- (void)prepare
{
}

- (void)activate;
{
}

- (void)deactivate
{
}

- (void)setTimeRangeFrom:(ShortDate *)from to:(ShortDate *)to {

}

@end
