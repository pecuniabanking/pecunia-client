/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

typedef NS_ENUM (NSUInteger, AccountStatementFormat) {
    AccountStatement_MT940 = 1,
    AccountStatement_ISO8583,
    AccountStatement_PDF
};

@class BankAccount, BankStatement;

@interface AccountStatementParameters : NSObject

@property (nonatomic, retain) NSNumber *canIndex;
@property (nonatomic, retain) NSString *formats;
@property (nonatomic, retain) NSNumber *needsReceipt;

- (BOOL)supportsFormat: (AccountStatementFormat)format;

@end


@interface AccountStatement : NSManagedObject

@property (nonatomic, retain) NSData      *document;
@property (nonatomic, retain) NSNumber    *format;
@property (nonatomic, retain) NSDate      *startDate;
@property (nonatomic, retain) NSDate      *endDate;
@property (nonatomic, retain) NSString    *info;
@property (nonatomic, retain) NSString    *conditions;
@property (nonatomic, retain) NSString    *advertisement;
@property (nonatomic, retain) NSString    *iban;
@property (nonatomic, retain) NSString    *bic;
@property (nonatomic, retain) NSString    *name;
@property (nonatomic, retain) NSString    *confirmationCode;
@property (nonatomic, retain) BankAccount *account;
@property (nonatomic, retain) NSArray     *statements;
@property (nonatomic, retain) NSNumber    *number;           // The running number of this statement within its year.

- (void)convertStatementsToPDFForAccount: (BankAccount *)acct;

@end
