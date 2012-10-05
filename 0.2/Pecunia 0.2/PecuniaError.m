//
//  PecuniaError.m
//  Pecunia
//
//  Created by Frank Emminghaus on 15.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "PecuniaError.h"


@implementation PecuniaError


+(NSError*)errorWithText: (NSString*)msg
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1 ];
	[userInfo setObject: msg forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:@"Pecunia" code:1 userInfo:userInfo];
}

@end
