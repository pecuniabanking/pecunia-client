//
//  ImportSettings.m
//  Pecunia
//
//  Created by Frank Emminghaus on 27.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "ImportSettings.h"


@implementation ImportSettings

@synthesize name;
@synthesize fields;
@synthesize sepRadioIndex;
@synthesize sepChar;
@synthesize dateFormatIndex;
@synthesize dateFormatString;
@synthesize charEncodingIndex;
@synthesize ignoreLines;
@synthesize accountNumber;
@synthesize accountSuffix;
@synthesize bankCode;
@synthesize fileName;


-(id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init ];
	self.name = [aDecoder decodeObjectForKey:@"name" ];
	self.fields = [aDecoder decodeObjectForKey:@"fields" ];
	self.sepRadioIndex = [aDecoder decodeObjectForKey:@"sepRadioIndex" ];
	self.sepChar = [aDecoder decodeObjectForKey:@"sepChar" ];
	self.dateFormatIndex = [aDecoder decodeObjectForKey:@"dateFormatIndex" ];
	self.dateFormatString = [aDecoder decodeObjectForKey:@"dateFormatString" ];
	self.charEncodingIndex = [aDecoder decodeObjectForKey:@"charEncodingIndex" ];
	self.ignoreLines = [aDecoder decodeObjectForKey:@"ignoreLines" ];
	self.accountNumber = [aDecoder decodeObjectForKey:@"accountNumber" ];
	self.bankCode = [aDecoder decodeObjectForKey:@"bankCode" ];
	self.fileName = [aDecoder decodeObjectForKey:@"fileName" ];
	self.accountSuffix = [aDecoder decodeObjectForKey:@"accountSuffix" ];
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:name forKey: @"name" ];
	[aCoder encodeObject:fields forKey:@"fields" ];
	[aCoder encodeObject:sepRadioIndex forKey:@"sepRadioIndex" ];
	[aCoder encodeObject:sepChar forKey:@"sepChar" ];
	[aCoder encodeObject:dateFormatIndex forKey:@"dateFormatIndex" ];
	[aCoder encodeObject:dateFormatString forKey:@"dateFormatString" ];
	[aCoder encodeObject:charEncodingIndex forKey:@"charEncodingIndex" ];
	[aCoder encodeObject:ignoreLines forKey:@"ignoreLines" ];
	[aCoder encodeObject:accountNumber forKey:@"accountNumber" ];
	[aCoder encodeObject:bankCode forKey:@"bankCode" ];
	[aCoder encodeObject:fileName forKey:@"fileName" ];
    [aCoder encodeObject:accountSuffix forKey: @"accountSuffix" ];
}


- (void)dealloc
{
	[name release], name = nil;
	[fields release], fields = nil;
	[sepRadioIndex release], sepRadioIndex = nil;
	[sepChar release], sepChar = nil;
	[dateFormatIndex release], dateFormatIndex = nil;
	[dateFormatString release], dateFormatString = nil;
	[charEncodingIndex release], charEncodingIndex = nil;
	[ignoreLines release], ignoreLines = nil;
	[accountNumber release], accountNumber = nil;
    [accountSuffix release ], accountSuffix = nil;
	[bankCode release], bankCode = nil;
	[fileName release], fileName = nil;

	[super dealloc];
}

@end

