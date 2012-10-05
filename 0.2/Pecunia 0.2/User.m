//
//  User.m
//  MacBanking
//
//  Created by Frank Emminghaus on 17.03.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "User.h"
#import "TanMethod.h"
#import "ABController.h"
#include <aqbanking/banking.h>
#include <aqhbci/user.h>
#include <gwenhywfar/url.h>

@implementation User

@synthesize name;
@synthesize country;
@synthesize bankCode;
@synthesize userId;
@synthesize customerId;
@synthesize mediumId;
@synthesize bankURL;
@synthesize bankName;

-(id)initWithAB: (AB_USER*) usr
{
	const char* c;
	
	[super init ];
	self.name		= [NSString stringWithUTF8String: (c = AB_User_GetUserName(usr)) ? c: ""];
	self.userId		= [NSString stringWithUTF8String: (c = AB_User_GetUserId(usr)) ? c: ""];
	self.customerId	= [NSString stringWithUTF8String: (c = AB_User_GetCustomerId(usr)) ? c: ""];
	self.bankCode	= [NSString stringWithUTF8String: (c = AB_User_GetBankCode(usr)) ? c: ""];
	self.country	= [NSString stringWithUTF8String: (c = AB_User_GetCountry(usr)) ? c: ""];
	uid				= AB_User_GetUniqueId(usr);
	self.mediumId	= [NSString stringWithUTF8String: (c = AH_User_GetTanMediumId(usr)) ? c: ""];
	hbciVersion		= AH_User_GetHbciVersion(usr);

    const GWEN_URL *url = AH_User_GetServerUrl(usr);
	GWEN_BUFFER *buf = GWEN_Buffer_new(NULL, 200, 0, 0);
	GWEN_Url_toString(url, buf);
	
	self.bankURL = [NSString stringWithUTF8String: (c = GWEN_Buffer_GetStart(buf)) ? c: ""];
	
	uint32_t flags = AH_User_GetFlags(usr);
	if(flags & AH_USER_FLAGS_FORCE_SSL3) forceSSL3 = TRUE;
	if(flags & AH_USER_FLAGS_NO_BASE64) noBase64 = TRUE;

	user = usr;

	tanMethodList = [[NSMutableArray arrayWithCapacity: 10 ] retain ];
	[self retrieveTanMethods ];
	tanMethod = AH_User_GetSelectedTanMethod(usr);
	
	return self;
}

-(BOOL)forceSSL3		{ return forceSSL3; }
-(BOOL)noBase64			{ return noBase64; }
-(unsigned int)uid		{ return uid; }
-(NSNumber*)hbciVersion	{ return [NSNumber numberWithInt: hbciVersion ]; }

-(BOOL)isEqual: (User*)obj
{
	return (uid == obj->uid);
}

-(void)setHbciVersion:(NSNumber*)version
{
	hbciVersion = [version intValue ];
}

-(void)setTanMethod: (TanMethod*)tm
{
	tanMethod = tm.function;
	if(user) {
		int rv = AB_Banking_BeginExclUseUser([[ABController abController ] handle], user );
		if (rv == 0) {
			AH_User_SetSelectedTanMethod(user, tanMethod);
			AB_Banking_EndExclUseUser([[ABController abController ] handle], user, NO);
		} else return;
	}
}

-(TanMethod*)tanMethod
{ 
	TanMethod *method;
	for(method in tanMethodList) {
		if(method.function == tanMethod) return method;
	}
	return [tanMethodList objectAtIndex:0 ];
}

-(NSArray*)tanMethodList
{
	return tanMethodList;
}


-(void)retrieveTanMethods
{
	//tanMethodList
	const AH_TAN_METHOD_LIST *ml = AH_User_GetTanMethodDescriptions(user);
	if(ml) {
		[tanMethodList removeAllObjects ];
		
		int n = AH_User_GetTanMethodCount(user);
		if(n>0) {
			const int *mList = AH_User_GetTanMethodList(user);
			
			const AH_TAN_METHOD *tm = AH_TanMethod_List_First(ml);
			while(tm) {
				int function = AH_TanMethod_GetFunction(tm);
				int i;
				for(i=0; i<n;i++) {
					if(mList[i] == function) {
						TanMethod *tanM = [[TanMethod alloc ] initWithAB: tm ];
						[tanMethodList addObject: tanM ];
						break;
					}
				}
				tm = AH_TanMethod_List_Next(tm);
			}
		}
	}
	tanMethod = AH_User_GetSelectedTanMethod(user);
	if([tanMethodList count ] == 0) {
		TanMethod *tanM = [[TanMethod alloc ] initDefault: tanMethod ];
		[tanMethodList addObject: tanM ];
	}
}

-(void)setUser:(AB_USER*)usr
{
	if(usr) user = usr;
}


-(void)dealloc
{
	[tanMethodList release ];
	[name release], name = nil;
	[country release], country = nil;
	[bankCode release], bankCode = nil;
	[userId release], userId = nil;
	[customerId release], customerId = nil;
	[mediumId release], mediumId = nil;
	[bankURL release], bankURL = nil;
	[bankName release], bankName = nil;

	[super dealloc ];
}

@end

