//
//  main.m
//  Pecunia
//
//  Created by Frank Emminghaus on 12.06.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// 1. Argument: Quelle
// 2. Argument: Ziel

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];


	NSError *error = nil;
	NSString *s = [NSString stringWithContentsOfFile: [NSString stringWithUTF8String: argv[1] ] encoding:4 error: &error ];
	if(error) {
		NSLog(@"Error reading institutes file");
		[pool release ];
		return -1;
	}
	NSArray *institutes = [s componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet ] ];

	NSMutableArray *inst = [NSMutableArray arrayWithCapacity: 5000 ];
	NSArray *keys = [NSArray arrayWithObjects: @"bankCode", @"bankName", @"bankLocation", @"hbciVersion", @"bankURL", nil ];
	for(s in institutes) {
		NSArray *objs = [s componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\t" ] ];
		NSDictionary *dict = [NSDictionary dictionaryWithObjects: objs forKeys: keys ];
		[inst addObject: dict ];
	}
	
	BOOL result = [NSKeyedArchiver archiveRootObject: inst toFile: [NSString stringWithUTF8String: argv[2] ] ];
	if(result == NO) {
		NSLog(@"Error writing institutes file");
	}
	
	//check
	NSArray *check = [NSKeyedUnarchiver unarchiveObjectWithFile: [NSString stringWithUTF8String: argv[2] ] ];
	
	[pool release ];
	return 0;

}
