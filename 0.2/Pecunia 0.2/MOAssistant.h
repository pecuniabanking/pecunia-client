//
//  MOAssistant.h
//  Pecunia
//
//  Created by Frank Emminghaus on 17.03.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// ManagedObjectAssistant
@interface MOAssistant : NSObject {
	NSManagedObjectContext		*context;
	NSManagedObjectContext		*memContext;
	NSManagedObjectModel		*model;
	NSMutableDictionary			*migRefs;
	
	NSString					*dataDir;
	NSString					*newStorePath;
	NSString					*oldStorePath;
	NSURL						*accountsURL;
	BOOL						encrypted;
}

-(void)loadModel;
-(void)copyStore;
-(void)migrateModel: (NSNumber*)buildNumber;
-(void)migrate: (NSDictionary*)oldEntityDict from:(NSManagedObjectContext*)oldMOC to:(NSManagedObjectContext*)newMOC;
-(void)copyManagedObject: (NSManagedObject*)oldObj to: (NSManagedObject*)newObj;
-(void)copyManagedObjectRelations: (NSManagedObject*)oldObj to: (NSManagedObject*)newObj;
-(void)processAfterMigration: (NSManagedObjectContext*)moc fromVersion: (NSNumber*)buildNum;
-(BOOL)relocateStoreToLocation: (NSString*)path;
-(BOOL)openImageWithPath: (NSString*)path;
-(BOOL)relocateToPath: (NSString*)path;
-(void)shutdown;
-(BOOL)encrypted;
-(BOOL)encryptDataWithPassword: password strong: (BOOL)strongEncryption;
-(BOOL)stopEncryption;

-(NSManagedObjectContext*)context;
-(NSManagedObjectModel*)model;
-(NSManagedObjectContext*)memContext;
+(MOAssistant*)assistant;

@end
