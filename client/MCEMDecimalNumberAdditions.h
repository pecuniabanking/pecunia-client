//
//  MCEMDecimalNumberAdditions.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.07.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDecimalNumber (MCEMDecimalNumberAdditions)

	-(NSDecimalNumber*)abs;
	-(NSDecimalNumber*)rounded;

@end
