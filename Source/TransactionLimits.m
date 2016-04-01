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
#import "NSString+PecuniaAdditions.h"

@implementation TransactionLimits

@synthesize maxLenPurpose;
@synthesize weekCyclesString;
@synthesize allowChangeLastExecDate;
@synthesize maxSetupTime;
@synthesize allowChangeCycle;
@synthesize execDaysMonthString;
@synthesize allowWeekly;
@synthesize monthCyclesString;
@synthesize allowChangeRemoteAccount;
@synthesize allowChangePurpose;
@synthesize jobName;
@synthesize maxLinesRemoteName;
@synthesize allowChangeExecDay;
@synthesize allowedTextKeysString;
@synthesize allowChangePeriod;
@synthesize minSetupTime;
@synthesize allowChangeValue;
@synthesize maxLenRemoteName;
@synthesize allowChangeFirstExecDate;
@synthesize maxLinesPurpose;
@synthesize execDaysWeekString;
@synthesize allowMonthly;
@synthesize allowChangeRemoteName;

- (int)maxLengthRemoteName
{
    return self.maxLenRemoteName * self.maxLinesRemoteName;
}

- (int)maxLengthPurpose
{
    return self.maxLenPurpose * self.maxLinesPurpose;
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
