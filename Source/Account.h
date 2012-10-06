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


@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *bankName;
@property (nonatomic, retain) NSString *bankCode;
@property (nonatomic, retain) NSString *accountNumber;
@property (nonatomic, retain) NSString *ownerName;
@property (nonatomic, retain) NSString *currency;
@property (nonatomic, retain) NSString *country;
@property (nonatomic, retain) NSString *iban;
@property (nonatomic, retain) NSString *bic;
@property (nonatomic, retain) NSString *userId;
@property (nonatomic, retain) NSString *customerId;
@property (nonatomic, retain) NSString *subNumber;
@property (nonatomic, retain) NSNumber *type;
@property (nonatomic, retain) NSArray  *supportedJobs;

@property (nonatomic, assign) BOOL substInternalTransfers;
@property (nonatomic, assign) BOOL collTransfer;

@end
