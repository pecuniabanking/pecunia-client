//
//  SigningOption.m
//  Pecunia
//
//  Created by Frank Emminghaus on 04.08.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import "SigningOption.h"


@implementation SigningOption

@synthesize userId;
@synthesize userName;
@synthesize cardId;
@synthesize tanMethod;
@synthesize tanMethodName;
@synthesize tanMediumName;
@synthesize tanMediumCategory;
@synthesize mobileNumber;
@synthesize secMethod;

- (void)dealloc
{
	userId = nil;
	userName = nil;
	cardId = nil;
	tanMethod = nil;
	tanMethodName = nil;
	tanMediumName = nil;
    tanMediumCategory = nil;
	mobileNumber = nil;    
}

-(id)copyWithZone:(NSZone*)zone
{
    return self;
}

- (NSString*)description
{
    if (secMethod == SecMethod_PinTan) {
        if (tanMediumName) {
            return [NSString stringWithFormat:@"%@ (%@)", tanMethodName, tanMediumName ];
        } else {
            return tanMethodName;
        }
    } else {
        return [NSString stringWithFormat:@"Chipkarte: %@", cardId ];
    }

}


@end

