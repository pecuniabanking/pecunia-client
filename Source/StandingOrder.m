/**
 * Copyright (c) 2010, 2013, Pecunia Project. All rights reserved.
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

#import "StandingOrder.h"

@implementation StandingOrder
@dynamic changeDate;
@dynamic currency;
@dynamic cycle;
@dynamic executionDay;
@dynamic firstExecDate;
@dynamic toDelete;
@dynamic isSent;
@dynamic lastExecDate;
@dynamic nextExecDate;
@dynamic orderKey;
@dynamic period;
@dynamic purpose1;
@dynamic purpose2;
@dynamic purpose3;
@dynamic purpose4;
@dynamic remoteAccount;
@dynamic remoteBankCode;
@dynamic remoteBankName;
@dynamic remoteBIC;
@dynamic remoteIBAN;
@dynamic remoteName;
@dynamic remoteSuffix;
@dynamic status;
@dynamic subType;
@dynamic type;
@dynamic isChanged;
@dynamic value;
@dynamic account;
@dynamic localAccount;
@dynamic localBankCode;

- (NSString *)purpose
{
    NSMutableString *s = [NSMutableString stringWithCapacity: 100];
    if (self.purpose1) {
        [s appendString: self.purpose1];
    }
    if (self.purpose2) {
        [s appendString: @" "]; [s appendString: self.purpose2];
    }
    if (self.purpose3) {
        [s appendString: @" "]; [s appendString: self.purpose3];
    }
    if (self.purpose4) {
        [s appendString: @" "]; [s appendString: self.purpose4];
    }

    return s;
}

- (NSString *)periodDescription
{
    NSString *timeFrame;
    NSString *day;
    if (self.period.intValue == stord_weekly) {
        if (self.cycle.intValue == 1) {
            timeFrame = NSLocalizedString(@"AP451", nil);
        } else {
            timeFrame = [NSString stringWithFormat: NSLocalizedString(@"AP453", nil), self.cycle.intValue];
        }

        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSArray *weekDays = formatter.weekdaySymbols;
        day = weekDays[self.executionDay.intValue];
    } else {
        if (self.cycle.intValue == 1) {
            timeFrame = NSLocalizedString(@"AP450", nil);
        } else {
            timeFrame = [NSString stringWithFormat: NSLocalizedString(@"AP452", nil), self.cycle.intValue];
        }
        switch (self.executionDay.intValue)
        {
            case 99:
                day = NSLocalizedString(@"AP466", nil);
                break;
            case 98:
                day = NSLocalizedString(@"AP467", nil);
                break;
            case 97:
                day = NSLocalizedString(@"AP468", nil);
                break;
            default:
                day = [NSString stringWithFormat: @"%i.", self.executionDay.intValue];
                break;
        }
    }

    NSMutableString *result = [NSMutableString stringWithFormat: NSLocalizedString(@"AP465", nil), timeFrame, day];

    return result;
}

- (void)setJobId: (unsigned int)jid
{
    jobId = jid;
}

- (unsigned int)jobId
{
    return jobId;
}

@end
