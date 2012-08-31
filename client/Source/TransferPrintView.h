//
//  TransferPrintView.h
//  Pecunia
//
//  Created by Frank Emminghaus on 31.08.12.
//  Copyright (c) 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TransfersListViewCell;

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
	int		padding;
	int		minStatHeight;
	int		totalPages;
	int		currentPage;
    BOOL    printUserInfo;
    BOOL    printCategories;
    
	NSMutableArray  *transfers;
	int				*statHeights;
	
	NSDateFormatter *dateFormatter;
	NSNumberFormatter *numberFormatter;
	NSNumberFormatter *debitNumberFormatter;
    
    TransfersListViewCell   *cell;

}

@property(nonatomic, copy) NSMutableArray *transfers;


@end
