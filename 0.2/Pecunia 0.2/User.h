//
//  User.h
//  MacBanking
//
//  Created by Frank Emminghaus on 17.03.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <aqbanking/banking.h>

@class TanMethod;

@interface User : NSObject {
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
	int				tanMethod;
	NSMutableArray*	tanMethodList;
	
	AB_USER*		user;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *customerId;
@property (nonatomic, copy) NSString *mediumId;
@property (nonatomic, copy) NSString *bankURL;
@property (nonatomic, copy) NSString *bankName;

-(NSArray*)tanMethodList;
-(BOOL)forceSSL3;
-(BOOL)noBase64;
-(unsigned int)uid;
-(NSNumber*)hbciVersion;
-(void)setHbciVersion:(NSNumber*)version;

-(TanMethod*)tanMethod;
-(void)setTanMethod: (TanMethod*)tm;

-(id)initWithAB: (AB_USER*)usr;
-(BOOL)isEqual: (User*)obj;
-(void)retrieveTanMethods;

-(void)setUser:(AB_USER*)usr;

@end

