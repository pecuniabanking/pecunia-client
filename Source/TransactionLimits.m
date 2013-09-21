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

#import "TransactionLimits.h"
#import "BankAccount.h"
#import "BankUser.h"

@implementation TransactionLimits

@dynamic maxLenPurpose;
@dynamic weekCyclesString;
@dynamic allowChangeLastExecDate;
@dynamic maxSetupTime;
@dynamic allowChangeCycle;
@dynamic execDaysMonthString;
@dynamic allowWeekly;
@dynamic monthCyclesString;
@dynamic allowChangeRemoteAccount;
@dynamic allowChangePurpose;
@dynamic localLimit;
@dynamic jobName;
@dynamic maxLinesRemoteName;
@dynamic foreignLimit;
@dynamic allowChangeExecDay;
@dynamic allowedTextKeysString;
@dynamic allowChangePeriod;
@dynamic minSetupTime;
@dynamic allowChangeValue;
@dynamic maxLenRemoteName;
@dynamic allowChangeFirstExecDate;
@dynamic maxLinesPurpose;
@dynamic execDaysWeekString;
@dynamic allowMonthly;
@dynamic allowChangeRemoteName;
@dynamic account;
@dynamic user;

- (int)maxLengthRemoteName
{
    return self.maxLenRemoteName * self.maxLinesRemoteName;
}

- (int)maxLengthPurpose
{
    return self.maxLenPurpose * self.maxLinesPurpose;
}

- (void)setLimitsWithData: (NSDictionary *)limits
{
    NSArray *textKeys = [limits valueForKey: @"textKeys"];
    if (textKeys) {
        self.allowedTextKeysString = [textKeys componentsJoinedByString: @":"];
    }

    NSString *s = [limits valueForKey: @"maxusage"];
    if (s) {
        self.maxLinesPurpose = [s intValue];
    } else {
        self.maxLinesPurpose = 2;
    }
    s = [limits valueForKey: @"minpreptime"];
    if (s) {
        self.minSetupTime = [s intValue];
    }
    s = [limits valueForKey: @"maxpreptime"];
    if (s) {
        self.maxSetupTime = [s intValue];
    }

    // now check all limits for Standing orders
    if ([self.jobName hasPrefix: @"Dauer"] == NO) {
        return;
    }

    s = [limits valueForKey: @"dayspermonth"];
    if (s) {
        self.execDaysMonthString = s;
    }

    s = [limits valueForKey: @"daysperweek"];
    if (s) {
        self.execDaysWeekString = s;
    }

    s = [limits valueForKey: @"turnusmonths"];
    if (s) {
        self.monthCyclesString = s;
    }

    s = [limits valueForKey: @"turnusweeks"];
    if (s) {
        self.weekCyclesString = s;
    }

    self.allowMonthly = YES;
    if (self.execDaysWeekString == nil || self.weekCyclesString == nil) {
        self.allowWeekly = NO;
    } else {
        self.allowWeekly = YES;
    }

    if ([self.jobName isEqualToString: @"DauerEdit"]) {
        s = [limits valueForKey: @"recktoeditable"];
        self.allowChangeRemoteAccount = NO;
        if (s) {
            if ([s isEqualToString: @"J"]) {
                self.allowChangeRemoteAccount = YES;
            }
        }
        s = [limits valueForKey: @"recnameeditable"];
        self.allowChangeRemoteName = NO;
        if (s) {
            if ([s isEqualToString: @"J"]) {
                self.allowChangeRemoteName = YES;
            }
        }
        s = [limits valueForKey: @"usageeditable"];
        self.allowChangePurpose = NO;
        if (s) {
            if ([s isEqualToString: @"J"]) {
                self.allowChangePurpose = YES;
            }
        }
        s = [limits valueForKey: @"firstexeceditable"];
        self.allowChangeFirstExecDate = NO;
        if (s) {
            if ([s isEqualToString: @"J"]) {
                self.allowChangeFirstExecDate = YES;
            }
        }
        s = [limits valueForKey: @"lastexeceditable"];
        self.allowChangeLastExecDate = NO;
        if (s) {
            if ([s isEqualToString: @"J"]) {
                self.allowChangeLastExecDate = YES;
            }
        }
        s = [limits valueForKey: @"timeuniteditable"];
        self.allowChangePeriod = NO;
        if (s) {
            if ([s isEqualToString: @"J"]) {
                self.allowChangePeriod = YES;
            }
        }
        s = [limits valueForKey: @"turnuseditable"];
        self.allowChangeCycle = NO;
        if (s) {
            if ([s isEqualToString: @"J"]) {
                self.allowChangeCycle = YES;
            }
        }
        s = [limits valueForKey: @"execdayeditable"];
        self.allowChangeExecDay = NO;
        if (s) {
            if ([s isEqualToString: @"J"]) {
                self.allowChangeExecDay = YES;
            }
        }
        s = [limits valueForKey: @"valueeditable"];
        self.allowChangeValue = NO;
        if (s) {
            if ([s isEqualToString: @"J"]) {
                self.allowChangeValue = YES;
            }
        }
    } else {
        self.allowChangeRemoteName = YES;
        self.allowChangeRemoteAccount = YES;
        self.allowChangePurpose = YES;
        self.allowChangeValue = YES;
        self.allowChangePeriod = YES;
        self.allowChangeLastExecDate = YES;
        self.allowChangeFirstExecDate = YES;
        self.allowChangeExecDay = YES;
        self.allowChangeCycle = YES;
    }
}

- (NSArray *)monthCycles
{
    NSMutableArray *cycles = [NSMutableArray arrayWithCapacity: 12];
    if (self.monthCyclesString != nil) {
        NSString *s = [self.monthCyclesString copy];
        while ([s length] > 0) {
            [cycles addObject: [s substringToIndex: 2]];
            s = [s substringFromIndex: 2];
        }
    }
    return cycles;
}

- (NSArray *)weekCycles
{
    NSMutableArray *cycles = [NSMutableArray arrayWithCapacity: 12];
    if (self.weekCyclesString != nil) {
        NSString *s = [self.weekCyclesString copy];
        while ([s length] > 0) {
            [cycles addObject: [s substringToIndex: 2]];
            s = [s substringFromIndex: 2];
        }
    }
    return cycles;
}

- (NSArray *)execDaysMonth
{
    NSMutableArray *execDays = [NSMutableArray arrayWithCapacity: 30];
    if (self.execDaysMonthString != nil) {
        NSString *s = [self.execDaysMonthString copy];
        while ([s length] > 0) {
            [execDays addObject: [s substringToIndex: 2]];
            s = [s substringFromIndex: 2];
        }
    }
    return execDays;
}

- (NSArray *)execDaysWeek
{
    NSMutableArray *execDays = [NSMutableArray arrayWithCapacity: 7];
    if (self.execDaysWeekString != nil) {
        NSString *s = [self.execDaysWeekString copy];
        while ([s length] > 0) {
            [execDays addObject: [s substringToIndex: 1]];
            s = [s substringFromIndex: 1];
        }
    }
    return execDays;
}

- (NSArray *)allowedTextKeys
{
    return [self.allowedTextKeysString componentsSeparatedByString: @":"];
}

@end
