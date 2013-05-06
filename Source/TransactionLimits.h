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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BankAccount, BankUser;

@interface TransactionLimits : NSManagedObject

@property (nonatomic)           BOOL     allowChangeLastExecDate;
@property (nonatomic)           BOOL     allowChangeCycle;
@property (nonatomic)           BOOL     allowWeekly;
@property (nonatomic)           BOOL     allowChangeRemoteAccount;
@property (nonatomic)           BOOL     allowChangePurpose;
@property (nonatomic)           BOOL     allowChangeExecDay;
@property (nonatomic)           BOOL     allowChangePeriod;
@property (nonatomic)           BOOL     allowChangeValue;
@property (nonatomic)           BOOL     allowChangeFirstExecDate;
@property (nonatomic)           BOOL     allowMonthly;
@property (nonatomic)           BOOL     allowChangeRemoteName;
@property (nonatomic)           int16_t  maxLenPurpose;
@property (nonatomic)           int16_t  maxSetupTime;
@property (nonatomic)           int16_t  minSetupTime;
@property (nonatomic)           int16_t  maxLenRemoteName;
@property (nonatomic)           int16_t  maxLinesPurpose;
@property (nonatomic)           int16_t  maxLinesRemoteName;
@property (nonatomic, strong)   NSString *execDaysMonthString;
@property (nonatomic, strong)   NSString *monthCyclesString;
@property (nonatomic, strong)   NSString *jobName;
@property (nonatomic, strong)   NSString *allowedTextKeysString;
@property (nonatomic, strong)   NSString *execDaysWeekString;
@property (nonatomic, strong)   NSString *weekCyclesString;

@property (nonatomic)           double localLimit;
@property (nonatomic)           double      foreignLimit;
@property (nonatomic, strong)   BankAccount *account;
@property (nonatomic, strong)   BankUser    *user;

@property (nonatomic, readonly, strong)   NSArray *weekCycles;
@property (nonatomic, readonly, strong)   NSArray *monthCycles;
@property (nonatomic, readonly, strong)   NSArray *execDaysWeek;
@property (nonatomic, readonly, strong)   NSArray *execDaysMonth;
@property (nonatomic, readonly, strong)   NSArray *allowedTextKeys;

- (int)maxLengthRemoteName;
- (int)maxLengthPurpose;

- (void)setLimitsWithData: (NSDictionary *)limits;



@end
