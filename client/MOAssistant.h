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
	NSString					*ppDir;
	NSString					*importerDir;
	NSString					*dataStorePath;
	NSURL						*accountsURL;
	BOOL						encrypted;
	BOOL						imageAvailable;
}

@property (nonatomic, copy) NSString *dataDir;
@property (nonatomic, copy) NSString *ppDir;
@property (nonatomic, copy) NSString *importerDir;
@property (nonatomic, copy) NSString *dataStorePath;
@property (nonatomic, retain) NSURL *accountsURL;

-(void)loadModel;
-(BOOL)relocateStoreToLocation: (NSString*)path;
-(BOOL)openImage;
-(BOOL)relocateToPath: (NSString*)path;
-(void)shutdown;
-(BOOL)encrypted;
-(BOOL)encryptDataWithPassword: (NSString*)password;
-(BOOL)stopEncryption;
-(BOOL)isEncryptedImageAtPath:(NSString*)path;
-(NSString*)dataFileNameAtPath:(NSString*)path;
-(void)checkPaths;

-(void)migrateDataDirFrom02;
-(NSString*)passportDirectory;


-(NSManagedObjectContext*)context;
-(NSManagedObjectModel*)model;
-(NSManagedObjectContext*)memContext;
+(MOAssistant*)assistant;

@end

