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

@protocol StatementsListViewNotificationProtocol
- (void)cellActivationChanged: (BOOL)state forIndex: (NSUInteger)index;
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
    IBOutlet NSButton* checkbox;
    
    @private
    id<StatementsListViewNotificationProtocol> delegate;
    
    BOOL isNew;
    BOOL hasUnassignedValue;
    int  headerHeight;
    NSUInteger index;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, assign) BOOL hasUnassignedValue;

- (IBAction)activationChanged: (id)sender;

- (void)setHeaderHeight: (int) aHeaderHeight;

- (void)setDetailsDate: (NSString*) date
             turnovers: (NSString*) turnovers
            remoteName: (NSString*) name
               purpose: (NSString*) purpose
            categories: (NSString*) categories
                 value: (NSDecimalNumber*) value
                 saldo: (NSDecimalNumber*) saldo
              currency: (NSString*) currency
       transactionText: (NSString*) transactionText
                 index: (NSUInteger) theIndex;

- (void)setIsNew: (BOOL) flag;
- (void)showActivator: (BOOL)flag markActive: (BOOL)active;

- (void)setTextAttributesForPositivNumbers: (NSDictionary*) positiveAttributes
                           negativeNumbers: (NSDictionary*) negativeAttributes;

@end
