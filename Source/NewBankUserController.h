/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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
#import "BankUser.h"

@class BankingController;

@class BWGradientBox;

@interface NewBankUserController : NSWindowController
{
    IBOutlet NSArrayController   *bankUserController;
    IBOutlet NSArrayController   *tanSigningOptions;
    IBOutlet NSArrayController   *hbciVersions;
    IBOutlet NSPanel             *userSheet;
    IBOutlet NSMutableDictionary *bankUserInfo;
    IBOutlet NSMutableArray      *bankUsers;
    IBOutlet NSObjectController  *currentUserController;
    IBOutlet BWGradientBox       *topGradient;
    IBOutlet BWGradientBox       *backgroundGradient;
    IBOutlet NSBox               *groupBox;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSButton            *okButton;
    IBOutlet NSTextField         *msgField;
    IBOutlet NSBox               *secSelectBox;
    IBOutlet NSBox               *pinTanBox;
    IBOutlet NSBox               *ddvBox;
    IBOutlet NSPopUpButton       *secMethodPopup;
    IBOutlet NSPopUpButton       *ddvPortPopup;
    IBOutlet NSTextField         *ddvReaderIdx;

    NSManagedObjectContext *context;

@private
    BankingController *bankController;

    NSUInteger     step;
    SecurityMethod secMethod;
    NSBox          *currentBox;
    BOOL           triedFirst;
}

- (id)initForController: (BankingController *)con;
- (void)updateTanMethods;


- (IBAction)close: (id)sender;
- (IBAction)add: (id)sender;
- (IBAction)addEntry: (id)sender;
- (IBAction)removeEntry: (id)sender;
- (IBAction)updateBankParameter: (id)sender;
- (IBAction)changePinTanMethod: (id)sender;
- (IBAction)printBankParameter: (id)sender;
- (IBAction)allSettings: (id)sender;
- (IBAction)secMethodChanged: (id)sender;
- (IBAction)tanOptionChanged: (id)sender;
- (IBAction)ok: (id)sender;
- (IBAction)cancelSheet: (id)sender;

@end
