/**
 * Copyright (c) 2012, 2013, Pecunia Project. All rights reserved.
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

#import "SigningOptionsController.h"
#import "SigningOptionsViewCell.h"
#import "SigningOption.h"
#import "BankAccount.h"
#import "User.h"

@implementation SigningOptionsController

- (id)initWithSigningOptions: (NSArray *)opts forAccount: (BankAccount *)acc
{
    self = [super initWithWindowNibName: @"SigningOptions"];

    options = opts;
    accountNumber = acc.accountNumber;
    return self;
}

- (void)awakeFromNib
{
    NSTableColumn          *column = [optionsView tableColumns][0];
    SigningOptionsViewCell *cell = [[SigningOptionsViewCell alloc] init];
    [column setDataCell: cell];
    /*
     NSMutableArray *options = [NSMutableArray arrayWithCapacity:10 ];
     SigningOption *option = [[[SigningOption alloc ] init ] autorelease ];
     option.userName = @"User 1";
     option.secMethod = SecMethod_PinTan;
     option.tanMethodName = @"SmartTan optisch";
     option.tanMediumCategory = @"G";
     option.tanMediumName = @"Frank1";
     [options addObject:option ];
     option = [[[SigningOption alloc ] init ] autorelease ];
     option.userName = @"User 2";
     option.secMethod = SecMethod_PinTan;
     option.tanMethodName = @"mTAN";
     option.tanMediumCategory = @"M";
     option.tanMediumName = @"47998092342";
     [options addObject:option ];
     option = [[[SigningOption alloc ] init ] autorelease ];
     option.userName = @"User 2";
     option.secMethod = SecMethod_DDV;
     option.cardId = @"4562348875234";
     [options addObject:option ];
     */
    [optionsController setContent: options];
}

- (SigningOption *)selectedOption
{
    NSArray *sel = [optionsController selectedObjects];
    return [sel lastObject];
}

- (IBAction)ok: (id)sender
{
    [[self window] close];
    [NSApp stopModalWithCode: 0];
}

- (IBAction)cancel: (id)sender
{
    [[self window] close];
    [NSApp stopModalWithCode: 1];
}

@end
