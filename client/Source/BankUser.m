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


@end
