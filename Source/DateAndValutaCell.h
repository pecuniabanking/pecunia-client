//
//  DateAndValutaCell.h
//  Pecunia
//
//  Created by Frank Emminghaus on 06.06.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DateAndValutaCell : NSTextFieldCell {
	NSDate			*valuta;
	NSDateFormatter	*formatter;
}

@property(nonatomic, strong) NSDate *valuta;
@property(nonatomic, strong) NSDateFormatter *formatter;


@end
