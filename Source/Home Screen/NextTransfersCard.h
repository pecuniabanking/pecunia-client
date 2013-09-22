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

#import "HomeScreenController.h"

@class ShortDate;

@interface OrderTableCellView : NSTableCellView
{
}

@property (strong) IBOutlet NSTextField *receiverField;
@property (strong) IBOutlet NSTextField *currencyField;
@property (strong) IBOutlet NSTextField *valueField;
@property (strong) IBOutlet NSTextField *purposeField;

@end

@interface NextTransfersCard : HomeScreenCard <NSTableViewDataSource, NSTableViewDelegate>
{
}

- (void)showValuePopupForDate: (ShortDate *)date
                       values: (NSArray *)values
               relativeToRect: (NSRect)area
                      forView: (NSView *)view;

- (void)cancelPopover;

@end
