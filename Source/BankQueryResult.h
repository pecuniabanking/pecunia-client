/**
 * Copyright (c) 2009, 2013, Pecunia Project. All rights reserved.
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

typedef enum {
    BankQueryType_BankStatement = 0,
    BankQueryType_StandingOrder,
} BankQueryType;

@class BankAccount;

@interface BankQueryResult : NSObject {
}

@property (assign) BankQueryType type;
@property (copy) NSString        *accountNumber;
@property (copy) NSString        *accountSubnumber;
@property (copy) NSString        *bankCode;
@property (copy) NSString        *currency;
@property (copy) NSString        *userId;
@property (copy) NSString        *ccNumber;
@property (copy) NSDate          *lastSettleDate;
@property (copy) NSDecimalNumber *balance;
@property (copy) NSDecimalNumber *oldBalance;
@property (copy) NSMutableArray  *statements;
@property (copy) NSMutableArray  *standingOrders;
@property (weak) BankAccount     *account;
@property (assign) BOOL          isImport;



@end
