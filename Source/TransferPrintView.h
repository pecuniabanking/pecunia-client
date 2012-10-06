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

@interface TransferPrintView : NSView
{
    NSSize	paperSize;
	int		purposeWidth;
	int		topMargin;
	int		bottomMargin;
	int		leftMargin;
	int		rightMargin;
	int		pageHeight;
	int		pageWidth;
	int		dateWidth;
	int		amountWidth;
    int     bankAddressWidth;
	int		padding;
	int		minStatHeight;
	int		totalPages;
	int		currentPage;
    
	NSMutableArray  *transfers;
	int				*statHeights;
	
	NSDateFormatter *dateFormatter;
	NSNumberFormatter *numberFormatter;
	NSNumberFormatter *debitNumberFormatter;
    
}

@property(nonatomic, retain) NSMutableArray *transfers;

- (id)initWithTransfers: (NSArray *)transfersToPrint printInfo: (NSPrintInfo *)pi;

@end
