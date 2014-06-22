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

@class BankStatement;
@class Transfer;

@interface SepaData : NSManagedObject

@property (nonatomic, retain) NSString * purpose;
@property (nonatomic, retain) NSString * ultimateDebitorId;
@property (nonatomic, retain) NSString * ultimateCreditorId;
@property (nonatomic, retain) NSString * purposeCode;
@property (nonatomic, retain) NSString * mandateId;
@property (nonatomic, retain) NSDate   * mandateSignatureDate;
@property (nonatomic, retain) NSString * sequenceType;
@property (nonatomic, retain) NSString * oldCreditorId;
@property (nonatomic, retain) NSString * oldMandateId;
@property (nonatomic, retain) NSDate   * settlementDate;
@property (nonatomic, retain) NSString * debitorId;
@property (nonatomic, retain) NSString * endToEndId;
@property (nonatomic, retain) NSString * creditorId;
@property (nonatomic, retain) BankStatement *statement;
@property (nonatomic, retain) Transfer *transfer;

@end
