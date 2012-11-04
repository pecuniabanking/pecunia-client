/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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

@interface Account : NSObject {
	NSString	*name;
	NSString	*bankName;
	NSString	*bankCode;
	NSString	*accountNumber;
	NSString	*ownerName;
	NSString	*currency;
	NSString	*country;
	NSString	*iban;
	NSString	*bic;
	NSString	*userId;
	NSString	*customerId;
	NSString	*subNumber;
    NSNumber    *type;
    NSArray     *supportedJobs;
	
	BOOL		collTransfer;
	BOOL		substInternalTransfers;
}

-(BOOL)isEqual: (id)obj;


@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *bankName;
@property (nonatomic, strong) NSString *bankCode;
@property (nonatomic, strong) NSString *accountNumber;
@property (nonatomic, strong) NSString *ownerName;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *iban;
@property (nonatomic, strong) NSString *bic;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *customerId;
@property (nonatomic, strong) NSString *subNumber;
@property (nonatomic, strong) NSNumber *type;
@property (nonatomic, strong) NSArray  *supportedJobs;

@property (nonatomic, assign) BOOL substInternalTransfers;
@property (nonatomic, assign) BOOL collTransfer;

@end
