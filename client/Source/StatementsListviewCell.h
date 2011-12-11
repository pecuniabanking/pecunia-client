//
//  StatementsListviewCell.h
//  Pecunia
//
//  Created by Mike Lischke on 01.10.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PXListViewCell.h"

@interface NonAnimatedCellTextField : NSTextField
{
}
@end

@interface StatementsListViewCell : PXListViewCell
{
	IBOutlet NSTextField* dateLabel;
    IBOutlet NSTextField* turnoversLabel;
    IBOutlet NSTextField* remoteNameLabel;
    IBOutlet NSTextField* purposeLabel;
    IBOutlet NSTextField* categoriesLabel;
    IBOutlet NSTextField* valueLabel;
    IBOutlet NSImageView* newImage;
    IBOutlet NSTextField* currencyLabel;
    IBOutlet NSTextField* saldoLabel;
    IBOutlet NSTextField* saldoCurrencyLabel;
    IBOutlet NSTextField* transactionTypeLabel;
    
    BOOL isNew;
    BOOL hasNotAssignedValue;
    int  headerHeight;
}

- (void)setHeaderHeight: (int) aHeaderHeight;

- (void)setDetailsDate: (NSString*) date
             turnovers: (NSString*) turnovers
            remoteName: (NSString*) name
               purpose: (NSString*) purpose
            categories: (NSString*) categories
                 value: (NSDecimalNumber*) value
                 saldo: (NSDecimalNumber*) saldo
              currency: (NSString*) currency
       transactionText: (NSString*) transactionText;

- (void)setIsNew: (BOOL) flag;
- (void)setHasNotAssignedValue: (BOOL) flag;

- (void)setTextAttributesForPositivNumbers: (NSDictionary*) positiveAttributes
                           negativeNumbers: (NSDictionary*) negativeAttributes;

@end
