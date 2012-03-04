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

@class User;
@class BankingController;
@class InstitutesController;

@interface NewBankUserController : NSWindowController
{
	IBOutlet NSObjectController		*objController;
	IBOutlet NSArrayController		*bankUserController;
	IBOutlet NSArrayController		*tanMethods;
	IBOutlet NSArrayController		*hbciVersions;
	IBOutlet NSWindow				*userSheet;
    IBOutlet User					*currentUser;
	IBOutlet NSMutableDictionary	*bankUserInfo;
	IBOutlet NSMutableArray			*bankUsers;
    
    @private
	BankingController* bankController;
    InstitutesController* institutesController;
	NSMutableArray* banks;
    NSWindow* selectBankUrlSheet;
}

- (id)initForController: (BankingController*)con;

- (IBAction)close:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)addEntry:(id)sender;
- (IBAction)selectBankUrl: (id)sender;
- (IBAction)removeEntry:(id)sender;
- (IBAction)updateBankParameter: (id)sender;
- (IBAction)getUserAccounts: (id)sender;
- (IBAction)changePinTanMethod: (id)sender;
- (IBAction)printBankParameter: (id)sender;

@end
