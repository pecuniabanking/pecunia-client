//
//  Country.h
//  Pecunia
//
//  Created by Frank Emminghaus on 15.11.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "aqbanking/country.h"

@interface Country : NSObject {
	NSString	*name;
	NSString	*currency;
	NSString	*code;
}

-(id)initWithAB: (const AB_COUNTRY*)cnty;

-(NSString*)name;
-(NSString*)currency;
-(NSString*)code;


@end
