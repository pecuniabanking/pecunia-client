//
//  AmountCell.h
//  Pecunia
//
//  Created by Frank Emminghaus on 06.06.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AmountCell : NSTextFieldCell {
	NSDecimalNumber		*amount;
	NSString			*currency;
	NSNumberFormatter	*formatter;
}

@property(nonatomic, retain) NSDecimalNumber *amount;
@property(nonatomic, retain) NSString *currency;
@property(nonatomic, retain) NSNumberFormatter *formatter;

@end
