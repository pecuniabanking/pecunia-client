/**
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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
#import "Transfer.h"
#import "NSView+PecuniaAdditions.h"

@interface TransfersListViewCell : PXListViewCell
{
	IBOutlet NSTextField *dateLabel;
    IBOutlet NSTextField *accountLabel;
    IBOutlet NSTextField *bankNameLabel;
    IBOutlet NSTextField *remoteNameLabel;
    IBOutlet NSTextField *purposeLabel;
    IBOutlet NSTextField *valueLabel;
    IBOutlet NSTextField *currencyLabel;
    IBOutlet NSTextField *valueTitle;
    IBOutlet NSTextField *dateTitle;

@private
    NSColor *categoryColor;
    NSDictionary *positiveAttributes;
    NSDictionary *negativeAttributes;
    NSDictionary *whiteAttributes;
    
    // Need to keep these values from the details dictionary to rebuild the attributed string
    // for the account label depending on whether we are selected or not.
    NSString *remoteBankCode;
    NSString *remoteAccount;
    NSString *purpose;
    
    NSUInteger index;
    TransferType type;
}

- (void)setDetails: (NSDictionary *)details;

- (void)setTextAttributesForPositivNumbers: (NSDictionary*)positiveAttributes
                           negativeNumbers: (NSDictionary*)negativeAttributes;
- (void)selectionChanged;

@end
