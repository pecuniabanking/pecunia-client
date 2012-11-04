//
//  ImportSettings.h
//  Pecunia
//
//  Created by Frank Emminghaus on 27.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImportSettings : NSObject <NSCoding> {
	NSString	*name;
	NSArray		*fields;
	NSNumber	*sepRadioIndex;
	NSString	*sepChar;
	NSNumber	*dateFormatIndex;
	NSString	*dateFormatString;
	NSNumber	*charEncodingIndex;
	NSNumber	*ignoreLines;
	NSString	*accountNumber;
	NSString	*bankCode;
    NSString    *accountSuffix;
	NSString	*fileName;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *fields;
@property (nonatomic, strong) NSNumber *sepRadioIndex;
@property (nonatomic, copy) NSString *sepChar;
@property (nonatomic, strong) NSNumber *dateFormatIndex;
@property (nonatomic, copy) NSString *dateFormatString;
@property (nonatomic, strong) NSNumber *charEncodingIndex;
@property (nonatomic, strong) NSNumber *ignoreLines;
@property (nonatomic, copy) NSString *accountNumber;
@property (nonatomic, copy) NSString *accountSuffix;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *fileName;

@end

