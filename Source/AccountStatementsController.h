/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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
#import <Quartz/Quartz.h>

@class BankAccount;

@interface AccountStatementsController : NSWindowController
{
    IBOutlet PDFView  *pdfView;
    IBOutlet NSButton *prevButton;
    IBOutlet NSButton *nextButton;
    IBOutlet NSTextField *numberField;
    IBOutlet NSTextField *yearField;

    BankAccount *account;
    NSArray     *statements;
    NSUInteger  currentIndex;
}

@property (nonatomic, strong) BankAccount *account;
@property (nonatomic, strong) NSArray     *statements;

- (IBAction)next: (id)sender;
- (IBAction)prev: (id)sender;
- (IBAction)updateStatements: (id)sender;

@end
