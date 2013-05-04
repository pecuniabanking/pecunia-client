//
//  BankStatementPrintView.h
//  Pecunia
//
//  Created by Frank Emminghaus on 17.10.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BankStatementPrintView : NSView {
    NSSize paperSize;
    int    purposeWidth;
    int    topMargin;
    int    bottomMargin;
    int    leftMargin;
    int    rightMargin;
    int    pageHeight;
    int    pageWidth;
    int    dateWidth;
    int    amountWidth;
    int    padding;
    int    minStatHeight;
    int    totalPages;
    int    currentPage;
    BOOL   printUserInfo;
    BOOL   printCategories;

    NSMutableArray *statements;
    int            *statHeights;

    NSDateFormatter   *dateFormatter;
    NSNumberFormatter *numberFormatter;
    NSNumberFormatter *debitNumberFormatter;
}

- (int)getStatementHeights;
- (id)initWithStatements: (NSArray *)stats printInfo: (NSPrintInfo *)pi;

@end
