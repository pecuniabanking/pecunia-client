//
//  User.h
//  MacBanking
//
//  Created by Frank Emminghaus on 17.03.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <aqbanking/banking.h>

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

-(id)initWithAB: (AB_USER*)usr;
-(BOOL)isEqual: (User*)obj;
-(void)retrieveTanMethods;
-(void)dealloc;
-(NSString*)name;
-(NSString*)bankCode;
-(NSString*)userId;
-(NSString*)mediumId;
-(NSString*)customerId;
-(NSString*)bankURL;
-(NSString*)bankName;
-(NSString*)country;
-(NSArray*)tanMethodList;
-(BOOL)forceSSL3;
-(BOOL)noBase64;

-(NSNumber*)hbciVersion;
//-(NSString*)tanMethod;
-(unsigned int)uid;

-(void)setBankName: (NSString*)name;
-(void)setMediumId: (NSString*)mId;
-(void)setBankURL: (NSString*)url;
-(void)setHbciVersion: (NSNumber*)version;
//-(void)setTanMethod: (NSString*)tm;
-(void)setUser:(AB_USER*)usr;

@end
