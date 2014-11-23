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

@class BankingCategory;
@class BankStatement;

@interface StatCatAssignment : NSManagedObject {
}

@property (nonatomic) NSString                *userInfo;
@property (nonatomic, strong) NSDecimalNumber *value;
@property (nonatomic) BankingCategory                *category;
@property (nonatomic, strong) BankStatement   *statement;

- (NSString *)stringForFields: (NSArray *)fields
           usingDateFormatter: (NSDateFormatter *)dateFormatter
              numberFormatter: (NSNumberFormatter *)numberFormatter;
- (void)moveToCategory: (BankingCategory *)targetCategory;
- (void)moveAmount: (NSDecimalNumber *)amount toCategory: (BankingCategory *)tcat withInfo:(NSString*)info;
- (void)remove;

+ (void)removeAssignments: (NSArray *)assignments;

- (NSComparisonResult)compareDate: (StatCatAssignment *)stat;
- (NSComparisonResult)compareDateReverse: (StatCatAssignment *)stat;

@end

@interface StatCatAssignment (CoreDataGeneratedPrimitiveAccessors)

- (BankingCategory *)primitiveCategory;
- (void)setPrimitiveCategory: (BankingCategory *)value;

@end
