//
//  ABUser.h
//  Pecunia
//
//  Created by Frank Emminghaus on 31.08.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#ifdef AQBANKING
#import <Cocoa/Cocoa.h>

@class TanMethod;

@interface ABUser : NSObject {
	unsigned int	uid;
	NSString*		name;
	NSString*		country;
	NSString*		bankCode;
	NSString*		userId;
	NSString*		customerId;
	NSString*		mediumId;
	NSString*		bankURL;
	NSString*		bankName;
	BOOL			forceSSL3;
	BOOL			noBase64;
	int				hbciVersion;
	int				tanMethodNumber;
	NSMutableArray*	tanMethodList;	
}

@property (nonatomic, assign) unsigned int uid;
@property (nonatomic, retain) NSMutableArray *tanMethodList;
@property (nonatomic, assign) BOOL forceSSL3;
@property (nonatomic, assign) BOOL noBase64;
@property (nonatomic, assign) int hbciVersion;
@property (nonatomic, assign) int tanMethodNumber;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *customerId;
@property (nonatomic, copy) NSString *mediumId;
@property (nonatomic, copy) NSString *bankURL;
@property (nonatomic, copy) NSString *bankName;

-(BOOL)isEqual: (ABUser*)obj;

@end


#endif
