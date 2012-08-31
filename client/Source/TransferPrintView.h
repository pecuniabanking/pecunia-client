//
//  TransferPrintView.h
//  Pecunia
//
//  Created by Frank Emminghaus on 31.08.12.
//  Copyright (c) 2012 Frank Emminghaus. All rights reserved.
//

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


@end
