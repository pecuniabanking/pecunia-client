//
//  User.m
//  MacBanking
//
//  Created by Frank Emminghaus on 17.03.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "User.h"
#import "TanMethod.h"
#include <aqbanking/banking.h>
#include <aqhbci/user.h>
#include <gwenhywfar/url.h>

@implementation User

-(id)initWithAB: (AB_USER*) usr
{
	const char* c;
	
	[super init ];
	name		= [[NSString stringWithUTF8String: (c = AB_User_GetUserName(usr)) ? c: ""] retain];
	userId		= [[NSString stringWithUTF8String: (c = AB_User_GetUserId(usr)) ? c: ""] retain];
	customerId	= [[NSString stringWithUTF8String: (c = AB_User_GetCustomerId(usr)) ? c: ""] retain];
	bankCode	= [[NSString stringWithUTF8String: (c = AB_User_GetBankCode(usr)) ? c: ""] retain];
	country		= [[NSString stringWithUTF8String: (c = AB_User_GetCountry(usr)) ? c: ""] retain];
	uid         = AB_User_GetUniqueId(usr);
	mediumId	= [[NSString stringWithUTF8String: (c = AH_User_GetTokenName(usr)) ? c: ""] retain];
	hbciVersion = AH_User_GetHbciVersion(usr);

    const GWEN_URL *url = AH_User_GetServerUrl(usr);
	GWEN_BUFFER *buf = GWEN_Buffer_new(NULL, 200, 0, 0);
	GWEN_Url_toString(url, buf);
	
	bankURL = [[NSString stringWithUTF8String: (c = GWEN_Buffer_GetStart(buf)) ? c: ""] retain];
	
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


- (NSString *)name {
    return [[name retain] autorelease];
}

- (void)setName:(NSString *)value {
    if (name != value) {
        [name release];
        name = [value copy];
		if(user) AB_User_SetUserName(user, [name UTF8String ]);
    }
}

- (NSString *)country {
    return [[country retain] autorelease];
}

- (void)setCountry:(NSString *)value {
    if (country != value) {
        [country release];
        country = [value copy];
		if(user) AB_User_SetCountry(user, [value UTF8String ]);
    }
}

- (NSString *)bankCode {
    return [[bankCode retain] autorelease];
}

- (void)setBankCode:(NSString *)value {
    if (bankCode != value) {
        [bankCode release];
        bankCode = [value copy];
		if(user) AB_User_SetBankCode(user, [value UTF8String ]);
    }
}

- (NSString *)userId {
    return [[userId retain] autorelease];
}

- (void)setUserId:(NSString *)value {
    if (userId != value) {
        [userId release];
        userId = [value copy];
		if(user) AB_User_SetUserId(user, [value UTF8String ]);
    }
}

- (NSString *)customerId {
    return [[customerId retain] autorelease];
}

- (void)setCustomerId:(NSString *)value {
    if (customerId != value) {
        [customerId release];
        customerId = [value copy];
		if(user) AB_User_SetCustomerId(user, [value UTF8String ]);
    }
}

- (NSString *)mediumId {
    return [[mediumId retain] autorelease];
}

- (void)setMediumId:(NSString *)value {
    if (mediumId != value) {
        [mediumId release];
        mediumId = [value copy];
		if(user) AH_User_SetTokenName(user, [mediumId UTF8String ]);
    }
}

- (NSString *)bankURL {
    return [[bankURL retain] autorelease];
}

- (void)setBankURL:(NSString *)value {
    if (bankURL != value) {
        [bankURL release];
        bankURL = [value copy];
		if(user) {
			GWEN_URL *g_url = GWEN_Url_fromString([bankURL UTF8String ]);
			AH_User_SetServerUrl(user, g_url);
		}
		
    }
}

- (NSString *)bankName {
    return [[bankName retain] autorelease];
}

- (void)setBankName:(NSString *)value {
    if (bankName != value) {
        [bankName release];
        bankName = [value copy];
    }
}


-(void)setForceSSL3: (BOOL)flg
{
	if(user) {
		uint32_t flags = AH_User_GetFlags(user);
		if(flg != forceSSL3) flags = flags ^ AH_USER_FLAGS_FORCE_SSL3;
		AH_User_SetFlags(user, flags);
	}
	forceSSL3 = flg;
}

-(void)setNoBase64:(BOOL)flag
{
	if(user) {
		uint32_t flags = AH_User_GetFlags(user);
		if(flag) flags |= AH_USER_FLAGS_NO_BASE64; else flags &= (0xFFFF ^ AH_USER_FLAGS_NO_BASE64);
		AH_User_SetFlags(user, flags);
	}
	noBase64 = flag;
}

-(void)setHbciVersion: (NSNumber*)version
{
	hbciVersion = [version intValue ];
	if(user) AH_User_SetHbciVersion(user, hbciVersion);
}

-(void)setTanMethod: (TanMethod*)tm
{
	tanMethod = tm.function;
	if(user) AH_User_SetSelectedTanMethod(user, tanMethod);
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
	[name release ];
	[userId release ];
	[bankCode release ];
	[country release ];
	[customerId release ];
	[mediumId release ];
	[bankURL release ];
	[bankName release ];
	[tanMethodList release ];
	[super dealloc ];
}

@end
