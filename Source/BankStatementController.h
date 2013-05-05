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
@class BankStatement;

@interface BankStatementController : NSWindowController {
    IBOutlet NSObjectController *statementController;
    IBOutlet NSObjectController *accountController;
    IBOutlet NSArrayController  *categoriesController;
    IBOutlet NSDatePicker       *dateField;
    IBOutlet NSDatePicker       *valutaField;
    IBOutlet NSTextField        *saldoField;
    IBOutlet NSTextField        *valueField;

    BankAccount            *account;
    NSManagedObjectContext *memContext;
    NSManagedObjectContext *context;
    BankStatement          *currentStatement;
    NSString               *bankName;
    BOOL                   firstStatement;
    NSDate                 *lastDate;
    BankStatement          *lastStatement;
    NSArray                *accountStatements;
    int                    actionResult;
    BOOL                   negateValue;
    BOOL                   valueChanged;
}

@property (nonatomic, copy) NSArray *accountStatements;

- (id)initWithAccount: (BankAccount *)acc statement: (BankStatement *)stat;


- (IBAction)cancel: (id)sender;
- (IBAction)next: (id)sender;
- (IBAction)done: (id)sender;
- (IBAction)dateChanged: (id)sender;
- (IBAction)negateValueChanged: (id)sender;

- (BOOL)check;
- (void)arrangeStatements;
- (void)updateSaldo;

@end
