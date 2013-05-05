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

#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface PurposeSplitController : NSWindowController {
    NSManagedObjectContext     *context;
    IBOutlet NSTableView       *purposeView;
    IBOutlet NSArrayController *purposeController;
    IBOutlet NSArrayController *accountsController;
    IBOutlet NSTextField       *ePosField;
    IBOutlet NSTextField       *eLenField;
    IBOutlet NSTextField       *kPosField;
    IBOutlet NSTextField       *kLenField;
    IBOutlet NSTextField       *bPosField;
    IBOutlet NSTextField       *bLenField;
    IBOutlet NSTextField       *vPosField;
    IBOutlet NSComboBox        *comboBox;

    int         actionResult;
    int         ePos, eLen;
    int         kPos, kLen;
    int         bPos, bLen;
    int         vPos;
    BOOL        processConvertedStats;
    BankAccount *account;
    NSString    *conversionInfo;

}

- (IBAction)ok: (id)sender;
- (IBAction)cancel: (id)sender;
- (IBAction)calculate: (id)sender;
- (IBAction)comboChanged: (id)sender;

- (id)initWithAccount: (BankAccount *)acc;
- (void)getStatements;

@end
