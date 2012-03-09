//
//  BankUser.m
//  Pecunia
//
//  Created by Frank Emminghaus on 05.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import "BankUser.h"
#import "MOAssistant.h"
#import "TanMethod.h"
#import "TanMedium.h"
#import "TanSigningOption.h"
#import "MessageLog.h"

@implementation BankUser

@dynamic bankCode;
@dynamic bankName;
@dynamic bankURL;
@dynamic checkCert;
@dynamic country;
@dynamic customerId;
@dynamic hbciVersion;
@dynamic name;
@dynamic port;
@dynamic userId;
@dynamic preferredTanMethod;
@dynamic tanMedia;
@dynamic tanMethods;


-(void)updateTanMethods:(NSArray*)methods
{
    NSManagedObjectContext *context = [[MOAssistant assistant ] context];
    NSMutableSet *oldMethods = [self tanMethods ];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TanMethod" inManagedObjectContext:context ];
    NSArray *attributeKeys = [[entity attributesByName] allKeys];
    
    for (TanMethod *method in methods) {
        TanMethod *newMethod = [NSEntityDescription insertNewObjectForEntityForName:@"TanMethod" inManagedObjectContext:context];
        NSDictionary *attributeValues = [method dictionaryWithValuesForKeys:attributeKeys];
        [newMethod setValuesForKeysWithDictionary:attributeValues];
        newMethod.user = self;
        
        // Daten aus alten Methoden übernehmen
        for(TanMethod *oldMethod in oldMethods) {
            if ([method.method isEqualToString: oldMethod.method ]) {
                newMethod.preferredMedium = oldMethod.preferredMedium;
            }
        }
    }
    
    // alte TAN-Methoden löschen
    for (TanMethod *oldMethod in oldMethods) {
        [context deleteObject:oldMethod ];
    }
}

-(void)updateTanMedia:(NSArray*)media
{
    NSManagedObjectContext *context = [[MOAssistant assistant ] context];
    NSMutableSet *oldMedia = [self tanMedia ];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TanMedium" inManagedObjectContext:context ];
    NSArray *attributeKeys = [[entity attributesByName] allKeys];
    
    for (TanMedium *medium in media) {
        TanMedium *newMedium = [NSEntityDescription insertNewObjectForEntityForName:@"TanMedium" inManagedObjectContext:context];
        NSDictionary *attributeValues = [medium dictionaryWithValuesForKeys:attributeKeys];
        [newMedium setValuesForKeysWithDictionary:attributeValues];
        newMedium.user = self;
        
        // Daten aus altem Medium
        for (TanMethod *method in [self tanMethods ]) {
            if (method.preferredMedium != nil && [method.preferredMedium.name isEqualToString: newMedium.name ]) {
                method.preferredMedium = newMedium;
            }
        }
    }
    
    // alte TAN-Media löschen
    for (TanMedium *oldMedium in oldMedia) {
        [context deleteObject:oldMedium ];
    }
}

-(NSArray*)getTanSigningOptions
{
    NSSet *methods = [self tanMethods ];
    NSSet *media = [self tanMedia ];
    NSMutableArray *options = [NSMutableArray arrayWithCapacity:10 ];
    
    for (TanMethod *method in methods) {
        TanSigningOption *option = [[[TanSigningOption alloc ] init ] autorelease ];
        option.tanMethod = method.method;
        option.tanMethodName = method.name;
        NSString *zkamethod = method.zkaMethodName;
        
        // check which media fit
        for (TanMedium *medium in media) {
            BOOL added = NO;
            if ([zkamethod isEqualToString:@"mobileTAN" ] && [medium.category isEqualToString:@"M" ]) {
                option.tanMediumName = medium.name;
                option.mobileNumber = medium.mobileNumber;
                [options addObject:option ];
                added = YES;
            }
            if ([zkamethod isEqualToString:@"BestSign" ] && [medium.category isEqualToString:@"G" ] && [[medium.name substringToIndex:2 ] isEqualToString:@"oT"]) {
                // Spezialfall Postbank Bestsign
                option.tanMediumName = medium.name;
                [options addObject:option ];
                added = YES;
            }
            if ([[zkamethod substringToIndex:3] isEqualToString:@"HHD" ] && [medium.category isEqualToString:@"G" ]) {
                option.tanMediumName = medium.name;
                [options addObject:option ];
                added = YES;
            }
            if (added == YES) {
                option = [[[TanSigningOption alloc ] init ] autorelease ];
                option.tanMethod = method.method;
                option.tanMethodName = method.name;
            }
        }
    }
    return options;
}

-(BOOL)isEqual:(BankUser*)user
{
	return [self.userId isEqualToString:user.userId	] && [self.bankCode isEqualToString:user.bankCode ] &&
	(self.customerId == nil || [self.customerId isEqualToString:user.customerId ]);
}

+(NSArray*)allUsers
{
	NSError *error=nil;
	NSManagedObjectContext *context = [[MOAssistant assistant] context];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankUser" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSArray *bankUsers = [context executeFetchRequest:request error:&error];
	if(error) {
		[[MessageLog log ] addMessage:[error localizedDescription ] withLevel:LogLevel_Warning];
		return nil;
	}
	return bankUsers;
}

+(BankUser*)userWithId:(NSString*)userId bankCode:(NSString*)bankCode
{
	NSError *error=nil;
	NSManagedObjectContext *context = [[MOAssistant assistant] context];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankUser" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId = %@ AND bankCode = %@", userId, bankCode ];
	[request setPredicate:predicate ];
	NSArray *bankUsers = [context executeFetchRequest:request error:&error];
	if(error) {
		[[MessageLog log ] addMessage:[error localizedDescription ] withLevel:LogLevel_Warning];
		return nil;
	}
	return [bankUsers lastObject];
}



@end
