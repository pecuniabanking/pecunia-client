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

#import <Cocoa/Cocoa.h>

#import "PXListViewCell.h"
#import "StandingOrder.h"
#import "NSView+PecuniaAdditions.h"

@protocol OrdersListViewNotificationProtocol
- (void)cancelDeletionForIndex: (NSUInteger)index;
@end

@interface OrdersListViewCell : PXListViewCell
{
	IBOutlet NSTextField *firstDateLabel;
    IBOutlet NSTextField *nextDateLabel;
    IBOutlet NSTextField *lastDateLabel;
    IBOutlet NSTextField *accountLabel;
    IBOutlet NSTextField *bankNameLabel;
    IBOutlet NSTextField *remoteNameLabel;
    IBOutlet NSTextField *purposeLabel;
    IBOutlet NSTextField *valueLabel;
    IBOutlet NSTextField *currencyLabel;
    IBOutlet NSTextField *valueTitle;
    IBOutlet NSTextField *firstDateTitle;
    IBOutlet NSTextField *lastDateTitle;
    IBOutlet NSTextField *nextDateTitle;
    IBOutlet NSImageView *editImage;
    IBOutlet NSImageView *sendImage;
    IBOutlet NSButton    *deleteButton;

@private
    NSColor *categoryColor;
    NSDictionary *whiteAttributes;
    
    // Need to keep these values from the details dictionary to rebuild the attributed string
    // for different labels depending on whether we are selected or not.
    NSString *remoteBankCode;
    NSString *remoteAccount;
    NSString *purpose;
    
    NSUInteger index;
}

@property (nonatomic, strong) id delegate;

- (void)setDetails: (NSDictionary *)details;
- (void)selectionChanged;

@end
