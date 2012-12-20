/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#import <Cocoa/Cocoa.h>

#import "PXListViewCell.h"
#import "NSView+PecuniaAdditions.h"

// Key names for the fields passed in via the value dictionary.
extern NSString *StatementDateKey;
extern NSString *StatementTurnoversKey;
extern NSString *StatementRemoteNameKey;
extern NSString *StatementPurposeKey;
extern NSString *StatementCategoriesKey;
extern NSString *StatementValueKey;
extern NSString *StatementSaldoKey;
extern NSString *StatementCurrencyKey;
extern NSString *StatementTransactionTextKey;
extern NSString *StatementIndexKey;
extern NSString *StatementNoteKey;

@interface NoAnimationTextField : NSTextField
@end

@protocol StatementsListViewNotificationProtocol
- (void)cellActivationChanged: (BOOL)state forIndex: (NSUInteger)index;
@end

@interface StatementsListViewCell : PXListViewCell
{
	IBOutlet NSTextField *dateLabel;
    IBOutlet NSTextField *turnoversLabel;
    IBOutlet NSTextField *remoteNameLabel;
    IBOutlet NSTextField *purposeLabel;
    IBOutlet NSTextField *noteLabel;
    IBOutlet NSTextField *categoriesLabel;
    IBOutlet NSTextField *valueLabel;
    IBOutlet NSImageView *newImage;
    IBOutlet NSTextField *currencyLabel;
    IBOutlet NSTextField *saldoCaption;
    IBOutlet NSTextField *saldoLabel;
    IBOutlet NSTextField *saldoCurrencyLabel;
    IBOutlet NSTextField *transactionTypeLabel;
    IBOutlet NSButton *checkbox;

@private
    id<StatementsListViewNotificationProtocol> delegate;
    
    BOOL isNew;
    BOOL hasUnassignedValue;
    int  headerHeight;
    NSUInteger index;

    NSDateFormatter *dateFormatter;
    NSDictionary *positiveAttributes;
    NSDictionary *negativeAttributes;
    NSDictionary *whiteAttributes;
    NSColor *categoryColor;
}
@property (strong) IBOutlet NSTextField *weekdayLabel;
@property (strong) IBOutlet NSTextField *dayLabel;
@property (strong) IBOutlet NSTextField *monthLabel;

@property (nonatomic, strong) id delegate;
@property (nonatomic, assign) BOOL hasUnassignedValue;

- (IBAction)activationChanged: (id)sender;

- (void)setDetails: (NSDictionary*) details;

- (void)setHeaderHeight: (int) aHeaderHeight;
- (void)setDetails: (NSDictionary*) details;
- (void)setIsNew: (BOOL) flag;
- (void)showActivator: (BOOL)flag markActive: (BOOL)active;
- (void)showBalance: (BOOL)flag;
- (void)selectionChanged;

- (void)setTextAttributesForPositivNumbers: (NSDictionary*) positiveAttributes
                           negativeNumbers: (NSDictionary*) negativeAttributes;

@end
