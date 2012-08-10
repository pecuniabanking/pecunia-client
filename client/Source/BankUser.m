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
#import "SigningOption.h"
#import "MessageLog.h"
#import "HBCIClient.h"

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
@dynamic noBase64;
@dynamic tanMediaFetched;
@dynamic ddvPortIdx;
@dynamic ddvReaderIdx;
@dynamic secMethod;
@dynamic chipCardId;

@synthesize regResult;

-(id)copyWithZone: (NSZone *)zone
{
	return [self retain ];
}

-(void)updateTanMethods:(NSArray*)methods
{
    NSManagedObjectContext *context = [[MOAssistant assistant ] context];
    NSMutableSet *oldMethods = [[[self tanMethods ] copy ] autorelease ];
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
    NSMutableSet *oldMedia = [[[self tanMedia ] copy ] autorelease];
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
    if ([self.secMethod intValue ] != SecMethod_PinTan) return nil;
    // first get TAN Media if not already fetched
    //if ([self.tanMediaFetched boolValue ] == NO) [[HBCIClient hbciClient ] updateTanMediaForUser:self ];
    
    NSSet *methods = [self tanMethods ];
    NSSet *media = [self tanMedia ];
    NSMutableArray *options = [NSMutableArray arrayWithCapacity:10 ];
    
    for (TanMethod *method in methods) {
        SigningOption *option = [[[SigningOption alloc ] init ] autorelease ];
        option.secMethod = SecMethod_PinTan;
        option.tanMethod = method.method;
        option.userId = self.userId;
        option.userName = self.name;
        option.tanMethodName = method.name;
        NSString *zkamethod = method.zkaMethodName;
        
        if ([method.needTanMedia isEqualToString: @"1"] || [method.needTanMedia isEqualToString: @"2"]) {
            // check which media fit
            for (TanMedium *medium in media) {
                BOOL added = NO;
                if ([zkamethod isEqualToString:@"mobileTAN" ] && [medium.category isEqualToString:@"M" ]) {
                    option.tanMediumName = medium.name;
                    option.mobileNumber = medium.mobileNumber;
                    option.tanMediumCategory = medium.category;
                    [options addObject:option ];
                    added = YES;
                }
                if ([zkamethod isEqualToString:@"BestSign" ] && [medium.category isEqualToString:@"G" ] && [[medium.name substringToIndex:3 ] isEqualToString:@"SO:"]) {
                    // Spezialfall Postbank Bestsign
                    option.tanMediumName = medium.name;
                    option.tanMediumCategory = medium.category;
                    [options addObject:option ];
                    added = YES;
                }
                if ([[zkamethod substringToIndex:3] isEqualToString:@"HHD" ] && [medium.category isEqualToString:@"G" ] && ![[medium.name substringToIndex:3 ] isEqualToString:@"SO:"]) {
                    option.tanMediumName = medium.name;
                    option.tanMediumCategory = medium.category;
                    [options addObject:option ];
                    added = YES;
                }
                if (added == YES) {
                    option = [[[SigningOption alloc ] init ] autorelease ];
                    option.secMethod = SecMethod_PinTan;
                    option.tanMethod = method.method;
                    option.tanMethodName = method.name;
                    option.userId = self.userId;
                    option.userName = self.name;
                }
            }
        } else {
            [options addObject:option ];
        }
    }

    // sortieren
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey: @"tanMethodName" ascending: YES] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
    return [options sortedArrayUsingDescriptors:sortDescriptors ];
}

-(NSArray*)getSigningOptions
{
    if (self.userId == nil) return nil;
    if ([self.secMethod intValue ] == SecMethod_PinTan) return [self getTanSigningOptions ];
    
    // DDV
    NSMutableArray *options = [NSMutableArray arrayWithCapacity:10 ];
    SigningOption *option = [[[SigningOption alloc ] init ] autorelease ];
    option.secMethod = SecMethod_DDV;
    option.userId = self.userId;
    option.userName = self.name;
    option.cardId = self.chipCardId;
    [options addObject:option ];
    return options;
}


-(void)setpreferredSigningOption:(SigningOption*)option
{
    if (option == nil) {
        self.preferredTanMethod = nil;
        return;
    }
    NSSet *methods = [self tanMethods ];
    for(TanMethod *method in methods) {
        if ([method.method isEqualToString: option.tanMethod ]) {
            self.preferredTanMethod = method;
            NSSet *media = [self tanMedia ];
            for(TanMedium *medium in media) {
                if ([medium.name isEqualToString:option.tanMediumName ]) {
                    method.preferredMedium = medium;
                    break;
                }
            }
            break;
        }
    }
}

-(SigningOption*)preferredSigningOption
{
    TanMethod *method = self.preferredTanMethod;
    if (method == nil) return nil;
    TanMedium *medium = method.preferredMedium;
    
    SigningOption *option = [[[SigningOption alloc ] init ] autorelease ];
    option.tanMethod = method.method;
    option.tanMethodName = method.name;
    option.userId = self.userId;
    option.userName = self.name;
    option.secMethod = SecMethod_PinTan;
    if (medium) {
        option.tanMediumName = medium.name;
        option.mobileNumber = medium.mobileNumber;
    }
    return option;
}

-(int)getpreferredSigningOptionIdx
{
    if ([self.secMethod intValue ] == SecMethod_DDV) {
        return 0;
    }
    
    NSArray *options = [self getTanSigningOptions ];
    SigningOption *option = [self preferredSigningOption ];
    
    // Wenn nichts voreingestellt ist, Index des letzten Eintrags +1 zurückgeben, der zeigt dann automatisch auf den virtuellen Eintrag
    if (option == nil) {
        return [options count ];
    }
    
    int idx = 0;
    for(SigningOption *opt in options) {
        if ([opt.tanMethod isEqualToString: option.tanMethod ] && ((opt.tanMediumName == nil && option.tanMediumName == nil) || [opt.tanMediumName isEqualToString:option.tanMediumName ])) {
            return idx;
        } else idx++;
    }
    return [options count ];
}

-(void)setpreferredSigningOptionIdx:(NSIndexSet*)iSet
{
    int idx = [iSet firstIndex ];
    if (idx < 0) return;
    NSArray *options = [self getTanSigningOptions ];
    
    [self setpreferredSigningOption:[options objectAtIndex:idx ] ];
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
