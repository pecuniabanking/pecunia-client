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

#import "HomeScreenController.h"

@interface SaveAndRedeemCard : HomeScreenCard
{
}

- (void)updateInfoForDate: (ShortDate *)date
         principalBalance: (double)balance
        principalBalance2: (double)balance2
                  paidOff: (double)paidOff
                 paidOff2: (double)paidOff2
            remainingTime: (NSUInteger)time
           remainingTime2: (NSUInteger)time2; // Always in months.

- (void)updateInfoWithDebt: (double)debt
                     debt2: (double)debt2
                redemption: (double)redemption
               redemption2: (double)redemption2;

- (void)updateInfoWithBorrowedAmount: (double)amount
                           totalPaid: (double)total
                          totalPaid2: (double)total2
                        interestPaid: (double)interest
                       interestPaid2: (double)interest2;

@end
