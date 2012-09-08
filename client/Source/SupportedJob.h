/**
 * Copyright (c) 2007, 2012, Pecunia Project. All rights reserved.
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

#import <CoreData/CoreData.h>
@class BankAccount;
@class BankUser;

@interface SupportedJob : NSManagedObject {
    
}
@property (nonatomic, retain) NSNumber * allowsChange;
@property (nonatomic, retain) NSNumber * allowsCollective;
@property (nonatomic, retain) NSNumber * allowsDated;
@property (nonatomic, retain) NSNumber * allowsList;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * allowesDelete;

@property (nonatomic, retain) BankAccount *account;
@property (nonatomic, retain) BankUser *user;

@end
