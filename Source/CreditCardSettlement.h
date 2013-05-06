/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BankAccount;

@interface CreditCardSettlement : NSManagedObject

@property (nonatomic, strong) NSDecimalNumber *endBalance;
@property (nonatomic, strong) NSString        *ccNumber;
@property (nonatomic, strong) NSString        *ccAccount;
@property (nonatomic, strong) NSDecimalNumber *startBalance;
@property (nonatomic, strong) NSDate          *settleDate;
@property (nonatomic, strong) NSDecimalNumber *value;
@property (nonatomic, strong) NSString        *text;
@property (nonatomic, strong) NSString        *settleID;
@property (nonatomic, strong) NSDate          *nextSettleDate;
@property (nonatomic, strong) NSString        *currency;
@property (nonatomic, strong) NSDate          *firstReceive;
@property (nonatomic, strong) NSData          *document;
@property (nonatomic, strong) NSData          *ackCode;
@property (nonatomic, strong) BankAccount     *account;

@end
