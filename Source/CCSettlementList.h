/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

@interface CCSettlementList : NSObject
{
    NSString    *ccNumber;
    NSString    *ccAccount;
    NSArray     *settlementInfos;
}

@property(nonatomic) NSString *ccNumber;
@property(nonatomic) NSString *ccAccount;
@property(nonatomic) NSArray *settlementInfos;

@end

@interface CCSettlementInfo : NSObject
{
    NSString        *settleID;
    NSNumber        *received;
    NSDate          *settleDate;
    NSDate          *firstReceive;
    NSDecimalNumber *value;
    NSString        *currency;
}

@property(nonatomic) NSString *settleID;
@property(nonatomic) NSNumber *received;
@property(nonatomic) NSDate *settleDate;
@property(nonatomic) NSDate *firstReceive;
@property(nonatomic) NSDecimalNumber *value;
@property(nonatomic) NSString *currency;

@end
