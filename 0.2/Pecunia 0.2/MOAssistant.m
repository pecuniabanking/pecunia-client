//
//  MOAssistant.m
//  Pecunia
//
//  Created by Frank Emminghaus on 17.03.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "MOAssistant.h"
#import "Category.h"
#import "BankAccount.h"
#import "PasswordWindow.h"
#import "HDIWrapper.h"
#import "Keychain.h"
#import "PecuniaError.h"

#define CURRENT_BUILD 3

NSString* const MD_Build_Number = @"MD_BUILDNUMBER";

@implementation MOAssistant

static MOAssistant	*assistant = nil;
static NSString* oldFile = @"accounts_old.sqlite";
static NSString* newFile = @"accounts.sqlite";
static NSString* lDir = @"~/Library/Pecunia";


-(id)init
{
	self = [super init ];
	
	NSError *error = nil;
	encrypted = NO;
	NSFileManager *fm = [NSFileManager defaultManager ];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	dataDir = [defaults valueForKey: @"DataDir" ];
	if(dataDir == nil) {
		dataDir = [lDir stringByExpandingTildeInPath ];
		[dataDir retain ];
		if([fm fileExistsAtPath: dataDir] == NO) {
			[fm createDirectoryAtPath: dataDir withIntermediateDirectories: YES attributes: nil error: &error ];
			if(error) @throw error;
		}
		[defaults setValue: dataDir forKey: @"DataDir" ];
	}
	
	// check whether image or plain file has to be taken
	NSString *imagePath = [dataDir stringByAppendingString: @"/PecuniaData.sparseimage" ];
	NSDictionary *attrs = [fm attributesOfItemAtPath: imagePath error: NULL ];
	if(attrs) {
		BOOL forceEncryption = [defaults boolForKey: @"forceEncryption" ];
		if(forceEncryption) {
			encrypted = YES;
			[defaults setBool:NO forKey: @"forceEncryption" ];
		} else {
			// file exists
			NSDate *imageDate = [attrs objectForKey: NSFileModificationDate ];
			NSString *filePath = [dataDir stringByAppendingString: @"/accounts.sqlite" ];
			attrs = [fm attributesOfItemAtPath: filePath error: NULL ];
			if(attrs) {
				// accounts.sqlite exists
				NSDate *fileDate = [attrs objectForKey: NSFileModificationDate ];
				// if image is newer: take it
				if([fileDate compare: imageDate ] == NSOrderedAscending) {
					encrypted = YES;
				}
			} else {
				// accounts.sqlite does not exist but image exists
				encrypted = YES;
			}
		}
	}
	
	// Check for relocation
	NSString *relPath = [defaults valueForKey: @"RelocationPath" ];
	if(relPath) {
		BOOL res = [self relocateToPath: relPath ];
		if(res == NO) {
			NSRunAlertPanel(NSLocalizedString(@"AP42", @""), 
							NSLocalizedString(@"AP56", @""),
							NSLocalizedString(@"ok", @"OK"), 
							nil, nil);
		}
	}

	if(encrypted) {
		NSString *imagePath = [dataDir stringByAppendingString: @"/PecuniaData.sparseimage" ];
		[self openImageWithPath: imagePath ];
	} else {
	// no encryption
		newStorePath = [NSString stringWithFormat: @"%@/%@", dataDir, newFile ];
		oldStorePath = [NSString stringWithFormat: @"%@/%@", dataDir, oldFile ];
		[newStorePath retain ];
		[oldStorePath retain ];
	}
	accountsURL = [[NSURL fileURLWithPath: newStorePath] retain ];
	model = nil; 
	context = nil;
	return self;
}

-(BOOL)openImageWithPath: (NSString*)path
{
	HDIWrapper *wrapper = [HDIWrapper wrapper ];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	BOOL browsable = [defaults boolForKey: @"BrowseImage" ];

	BOOL savePassword = NO;
	NSString* passwd = [Keychain passwordForService: @"Pecunia" account: @"DataFile" ];
	if(passwd == nil) {
		PasswordWindow *pwWindow = [[PasswordWindow alloc] initWithText: NSLocalizedString(@"AP54", @"")
																  title: NSLocalizedString(@"AP53", @"")];
		
		
		int res = [NSApp runModalForWindow: [pwWindow window]];
		if(res) [NSApp terminate: self ];
		
		passwd = [pwWindow result];
		savePassword = [pwWindow shouldSavePassword ];
	}
	
	BOOL success = [wrapper attachImage: path withPassword: passwd browsable: browsable ];
	
	if(success) {
		newStorePath = [NSString stringWithFormat: @"%@/%@", [wrapper volumePath ], newFile ];
		oldStorePath = [NSString stringWithFormat: @"%@/%@", [wrapper volumePath ], oldFile ];
		[newStorePath retain ];
		[oldStorePath retain ];
		if(savePassword) [Keychain setPassword: passwd forService: @"Pecunia" account: @"DataFile" ];
		
	} else {
		NSString *errorMsg = [wrapper errorMessage ];
		if(errorMsg == nil) errorMsg = NSLocalizedString(@"AP52", @"");
		NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionaryWithCapacity:1 ];
		[newUserInfo setObject:[NSString stringWithFormat: NSLocalizedString(@"AP51", @""), errorMsg ] forKey:NSLocalizedDescriptionKey];
		NSError *newError = [NSError errorWithDomain:@"Pecunia" code:2 userInfo:newUserInfo];
		@throw newError;
	}
	return YES;
}

-(void)shutdown
{
	NSError *error=nil;
	
	NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator ];
	NSArray *stores = [coord persistentStores ];
	NSPersistentStore *store;
	for(store in stores) {
		[coord removePersistentStore: store error: &error ];
	}
	if(error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	
	HDIWrapper *wrapper = [HDIWrapper wrapper ];
	[wrapper detachImage ];
}

-(BOOL)encrypted
{
	return encrypted;
}

-(BOOL)encryptDataWithPassword: password strong: (BOOL)strongEncryption
{
	// now create 
	HDIWrapper *wrapper = [HDIWrapper wrapper ];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSString *path = [defaults valueForKey: @"DataDir" ];
	BOOL browsable = [defaults boolForKey: @"BrowseImage" ];
	NSString *imagePath = [path stringByAppendingString: @"/PecuniaData" ];
	
	BOOL success = [wrapper createImage: imagePath withPassword: password strongEncryption: strongEncryption ];
	if(!success) {
		NSRunAlertPanel(NSLocalizedString(@"AP46", @""), 
						[NSString stringWithFormat: NSLocalizedString(@"AP49", @""), imagePath ],
						NSLocalizedString(@"ok", @"Ok"), 
						nil, nil);
		return NO;
	}
	// now attach it
	imagePath = [path stringByAppendingString: @"/PecuniaData.sparseimage" ];
	success = [wrapper attachImage: imagePath withPassword: password browsable: browsable ];
	if(!success) {
		NSString *errorMsg = [wrapper errorMessage ];
		if(errorMsg == nil) errorMsg = NSLocalizedString(@"AP52", @"");
		NSRunAlertPanel(NSLocalizedString(@"AP46", @""), 
						NSLocalizedString(@"AP51", @""),
						NSLocalizedString(@"ok", @"Ok"), 
						nil, nil, errorMsg);
		return NO;
	}
	// image is attached. Now move Pecunia Data File
	NSString *oldPath = [newStorePath copy ];
	if(![self relocateStoreToLocation: [wrapper volumePath ]]) {
		[oldPath release ];
		return NO;
	}
	// Success message
	NSRunAlertPanel(NSLocalizedString(@"AP81", @""), 
					NSLocalizedString(@"AP82", @""),
					NSLocalizedString(@"ok", @"Ok"), 
					nil, nil, oldPath);
	
	encrypted = YES;
	[oldPath release ];
	return YES;
}

-(BOOL)stopEncryption
{
	if(!encrypted) return NO;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSString *path = [defaults valueForKey: @"DataDir" ];
	NSFileManager *fm = [NSFileManager defaultManager ];
	NSError *error;
	
	// relocate back to standard Data Path
	if(![self relocateStoreToLocation: path ]) {
		return NO;
	}
	// from now on, we work on the unencrypted store again
	encrypted = NO;
	
	// now rename image file so that it is not taken at next startup
	HDIWrapper *wrapper = [HDIWrapper wrapper ];
	[wrapper detachImage ];
	NSString *imagePath = [path stringByAppendingString: @"/PecuniaData.sparseimage" ];
	NSString *oldImagePath = [path stringByAppendingString: @"/PecuniaData_old.sparseimage" ];

	if([fm fileExistsAtPath: oldImagePath ]) {
		BOOL success = [fm removeItemAtPath: oldImagePath error: &error ];
		if(!success) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return NO;
		}
	}
	// then rename the file
	BOOL success = [fm moveItemAtPath: imagePath toPath: oldImagePath error: &error ];
	if(!success) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return NO;
	}
	
	encrypted = NO;
	return YES;
}



-(void)loadModel
{
	BOOL storeExists = YES;
	NSError	*error = nil;
	
	NSDictionary *metadata;
	
	NSLog(@"URL is: %@", accountsURL);
	metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:accountsURL error:&error];
	if(metadata == nil) {
		// try to restore file
		error = nil;
		NSFileManager *fm = [NSFileManager defaultManager ];
		if([fm fileExistsAtPath: oldStorePath ]) {
			[fm copyItemAtPath: oldStorePath toPath: newStorePath error: &error ];
			if(error) @throw error;
		}
		metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:accountsURL error:&error];
		if( error != nil ) {
/*			
			// check if it is a /Volume directory
			NSRange r = [newStorePath rangeOfString: @"/Volumes" ];
			if(r.location == 0) {
				NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionaryWithCapacity:[[[error userInfo] allKeys] count]];
				[newUserInfo setDictionary:[error userInfo]];
				NSString *errorDesc = [NSString stringWithFormat: NSLocalizedString(@"AP45", @""), newStorePath ];
				[newUserInfo setObject:errorDesc forKey:NSLocalizedDescriptionKey];
				NSError *newError = [NSError errorWithDomain:[error domain] code:[error code] userInfo:newUserInfo];
				@throw newError;
 
			}
 */
			storeExists = NO;
			error = nil;
		}
	}
	
	if(storeExists == YES) {
		NSNumber	*build = [metadata valueForKey: MD_Build_Number ];
		if(!build) build = [NSNumber numberWithInt:0 ];
		if([build intValue ] != CURRENT_BUILD) [self migrateModel: build ];
	}
	
	if(model) [model release ];
	if(context) [context release ];
	
	NSURL *momURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Accounts" ofType:@"mom"]];
	model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];

	NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	id store = [coord addPersistentStoreWithType: NSSQLiteStoreType 
								   configuration: nil 
											 URL: accountsURL
										 options: nil 
										   error: &error];

	if( error != nil ) @throw error;
	
	if(storeExists == NO) {
		NSMutableDictionary *newStoreMetadata = [[NSMutableDictionary alloc] init];
		[newStoreMetadata setValue:[NSNumber numberWithInt:CURRENT_BUILD] forKey:MD_Build_Number ];
		[coord setMetadata:newStoreMetadata forPersistentStore:store];
	}
		
	context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator: coord ];
	
	// save new context
	if(storeExists == NO) {
		if([context save: &error ] == NO) {
			@throw error;
		}
	}
	
//	[coord release ];
}

-(NSManagedObjectContext*)memContext
{
	NSError *error = nil;
	if(memContext) return memContext;
	if(model == nil) return nil;
	
	NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	[coord addPersistentStoreWithType: NSInMemoryStoreType configuration: nil URL: nil options: nil error: &error];
	if( error != nil ) @throw error;
	memContext = [[NSManagedObjectContext alloc] init];
	[memContext setPersistentStoreCoordinator: coord ];
	return memContext;
}



-(void)copyStore
{
	NSError *error = nil;
	NSFileManager *fm = [NSFileManager defaultManager ];

	if([fm fileExistsAtPath: newStorePath ]) {
		if([fm fileExistsAtPath: oldStorePath ]) {
			[fm removeItemAtPath:oldStorePath error: &error ];
			if(error) {
				NSLog(@"Could not remove file %@", oldStorePath);
				@throw error;
			}
		}
		[fm copyItemAtPath: newStorePath toPath: oldStorePath error: &error ];
		if(error) {
			NSLog(@"Could not copy file %@ to %@", newStorePath, oldStorePath); 
			@throw error;	
		}
		if([fm fileExistsAtPath: oldStorePath ]) {
			[fm removeItemAtPath:newStorePath error: NULL ];
			if(error) {
				NSLog(@"Could not remove file %@", newStorePath);
				@throw error;	
			}
		}
	}
}

-(BOOL)relocateToPath: (NSString*)path
{
	NSFileManager *fm = [NSFileManager defaultManager ];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	NSString *filePath;
	NSString *oldFilePath;
	BOOL fileExists = NO;
	
	// check if files exist at target position
	if(encrypted) filePath = [path stringByAppendingString: @"/PecuniaData.sparseimage" ];
	else filePath = [path stringByAppendingString: @"/accounts.sqlite" ];
	
	if(encrypted) oldFilePath = [dataDir stringByAppendingString: @"/PecuniaData.sparseimage"  ];
	else oldFilePath = [dataDir stringByAppendingString: @"/accounts.sqlite"  ];
	
	fileExists = [fm fileExistsAtPath: filePath ];
	if(fileExists) {
		int res;
		res = NSRunAlertPanel(NSLocalizedString(@"AP42", @""), 
							  NSLocalizedString(@"AP55", @""),
							  NSLocalizedString(@"yes", @"Yes"), 
							  NSLocalizedString(@"no", @"No"), 
							  nil, filePath);
		if(res != NSAlertDefaultReturn) return NO;
	} else {
		// now, file does not exist yet, copy it
		NSError *error;
		if([fm copyItemAtPath: oldFilePath toPath: filePath error:&error ] == NO) {
			// file cannot be copied
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return NO;
		}
	}
	
	// now, file is copied / or existent
	[dataDir release ];
	dataDir = [path retain ];
	[defaults setValue: dataDir forKey: @"DataDir" ];
	[defaults setValue: nil forKey: @"RelocationPath" ];
	return YES;
}


-(BOOL)relocateStoreToLocation: (NSString*)path
{
	NSError *error;
	
	// save updates first
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return NO;
	}
	
	// copy data file to new location
	NSString *newPath = [NSString stringWithFormat: @"%@/%@", path, newFile ];
	NSFileManager *fm = [NSFileManager defaultManager ];

	if([fm fileExistsAtPath: newPath ]) {
		int i;
		i = NSRunAlertPanel(NSLocalizedString(@"AP42", @"Change Pecunia Data Location"), 
							NSLocalizedString(@"AP43", @"There already is a pecunia data file in directory %@. Overwrite it?"),
							NSLocalizedString(@"no", @"No"), 
							NSLocalizedString(@"yes", @"Yes"), 
							nil, path);
		if(i != NSAlertAlternateReturn) return NO;
		if([fm removeItemAtPath:newPath error:&error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return NO;
		}
	}

	if([fm copyItemAtPath: newStorePath toPath: newPath error:&error ] == NO) {
		// file cannot be copied
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return NO;
	};
	
	// now file is copied to new location
	[dataDir release ];
	dataDir = [path retain ];
	
	[newStorePath release ];
	[oldStorePath release ];
	newStorePath = [NSString stringWithFormat: @"%@/%@", dataDir, newFile ];
	oldStorePath = [NSString stringWithFormat: @"%@/%@", dataDir, oldFile ];
	[newStorePath retain ];
	[oldStorePath retain ];
	accountsURL = [NSURL fileURLWithPath: newStorePath];
	
	// set coordinator and stores
	NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator ];
	NSArray *stores = [coord persistentStores ];
	NSPersistentStore *store;
	for(store in stores) {
		[coord setURL: accountsURL forPersistentStore: store ];
	}
	return YES;
}

-(void)migrateModel: (NSNumber*)buildNumber
{
	NSError		*error = nil;
	NSURL		*oldStoreURL = [NSURL fileURLWithPath: [NSString stringWithFormat: @"%@/%@", dataDir, oldFile ] ];
	NSString	*oldModelName = [NSString stringWithFormat:@"Accounts%u", [buildNumber intValue]];
	
	[self copyStore ];
	
	// get current MOM
	NSURL *momURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Accounts" ofType:@"mom"]];
	NSManagedObjectModel *newMoM = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
	
	// get older MOM
	momURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:oldModelName ofType:@"mom"]];
	NSManagedObjectModel *oldMoM = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
	
	[newMoM autorelease ];
	[oldMoM autorelease ];
	
	// init coordinators
	NSPersistentStoreCoordinator *oldCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:oldMoM] autorelease ];
	NSPersistentStoreCoordinator *newCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:newMoM] autorelease ];
	
	id store = [oldCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
											configuration:nil 
													  URL:oldStoreURL
												  options:nil 
													error:&error];
	if( error != nil ) @throw error;
	
	store = [newCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
										 configuration:nil 
												   URL:accountsURL 
											   options:nil 
												 error:&error];
	if( error != nil ) @throw error;
	
	NSMutableDictionary *newStoreMetadata = [[NSMutableDictionary alloc] init];
	[newStoreMetadata setValue:[NSNumber numberWithInt:CURRENT_BUILD] forKey:MD_Build_Number ];
	[newCoordinator setMetadata:newStoreMetadata forPersistentStore:store];

	NSManagedObjectContext *oldMOC = [[[NSManagedObjectContext alloc] init] autorelease ];
	NSManagedObjectContext *newMOC = [[[NSManagedObjectContext alloc] init] autorelease ];
	
	[oldMOC setPersistentStoreCoordinator:oldCoordinator];
	[newMOC setPersistentStoreCoordinator:newCoordinator];
	
	NSDictionary *oldEntityDict = [oldMoM entitiesByName];
	[self migrate: oldEntityDict from: oldMOC to:newMOC ];
	
	[self processAfterMigration: newMOC fromVersion: buildNumber ];
	
	// save new context
	if([newMOC save: &error ] == NO) {
		@throw error;
	}
}

-(void)migrate: (NSDictionary*)oldEntityDict from:(NSManagedObjectContext*)oldMOC to:(NSManagedObjectContext*)newMOC
{
	NSError	*error = nil;
	NSEnumerator *entityNamesEnum = [[oldEntityDict allKeys] objectEnumerator];
	NSString* entity;
	
	migRefs = [NSMutableDictionary dictionaryWithCapacity: 100 ];
	
	while ((entity = [entityNamesEnum nextObject])) {
		NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
		[request setEntity: [oldEntityDict valueForKey: entity ]];
		
		NSArray *oldEntities = [oldMOC executeFetchRequest:request error:&error];
		if(error) @throw error;
		if(oldEntities)	{
			int i;
			for(i=0; i< [oldEntities count ]; i++) {
		        NSManagedObject	*oldObj = [oldEntities objectAtIndex: i ];
				// filter out objects which do not belong to current entity (inheritance)
				if([[[oldObj entity ] name ] compare: entity ] != 0) continue;
				
				NSManagedObject *newObj = [NSEntityDescription insertNewObjectForEntityForName: entity
																		inManagedObjectContext: newMOC ];
				[self copyManagedObject: [oldEntities objectAtIndex: i ] to: newObj ];
			}
			
		}
	}
}

-(void)copyManagedObject: (NSManagedObject*)oldObj to: (NSManagedObject*)newObj
{
	NSEntityDescription *entity = [oldObj entity];
	
	NSArray *attributeKeys = [[entity attributesByName] allKeys];
	NSDictionary *attributeValues = [oldObj dictionaryWithValuesForKeys:attributeKeys];
	[newObj setValuesForKeysWithDictionary:attributeValues];
	
	[self copyManagedObjectRelations:oldObj to: newObj];
	//Add myself to the relationship dictionary
	[migRefs setValue:newObj forKey:[[[oldObj objectID] URIRepresentation] absoluteString]];
}

-(void)copyManagedObjectRelations: (NSManagedObject*)oldObj to: (NSManagedObject*)newObj
{
	NSEntityDescription *entity = [oldObj entity];
	NSDictionary *relationships = [entity relationshipsByName];
	
	NSEnumerator *relationshipEnum = [[relationships allKeys] objectEnumerator];
	NSString *relationshipName;
	while (relationshipName = [relationshipEnum nextObject]) {
		NSRelationshipDescription *relationshipDescription = [relationships valueForKey:relationshipName];
		if ([relationshipDescription isToMany]) {
			//To many relationship
			NSEnumerator *toManyEnum = [[oldObj valueForKey:relationshipName] objectEnumerator];
			NSManagedObject *toMany;
			NSMutableSet *toManySet = [newObj mutableSetValueForKey:relationshipName];
			while (toMany = [toManyEnum nextObject]) {
				NSString *uid = [[[toMany objectID] URIRepresentation] absoluteString];
				NSManagedObject *toManyNew = [migRefs valueForKey:uid];
				if (toManyNew) {
					[toManySet addObject:toManyNew];
				}
			}
		} else {
			//To one relationship
			//see if the receiver has already been copied, if so link
			NSString *uid = [[[[oldObj valueForKey:relationshipName] objectID] URIRepresentation] absoluteString];
			if (uid) {
				NSManagedObject *toOne = [migRefs valueForKey:uid];
				if (toOne) [newObj setValue:toOne forKey:relationshipName];
			}
			
		}
	}
}

-(void)processAfterMigration: (NSManagedObjectContext*)moc fromVersion: (NSNumber*)buildNum
{
	NSError *error = nil;
	int i;

	switch([buildNum intValue ]) {
		case 0:
		case 1: {
			NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:moc];
			NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
			[request setEntity:entityDescription];
			
			NSArray *cats = [moc executeFetchRequest:request error:&error];
			if(error) @throw error;
			for(i = 0; i < [cats count ]; i++) {
				Category* cat = [cats objectAtIndex: i ];
				[cat setValue: [NSNumber numberWithBool: YES ] forKey: @"isBankAcc" ];
				if([cat valueForKey: @"parent" ] == nil) [cat setValue: @"++bankroot" forKey: @"name" ];
				if([(BankAccount*)cat accountNumber] == nil || [(BankAccount*)cat accountNumber] == @"") [cat setValue: [NSDecimalNumber zero ] forKey: @"balance" ];
			}
			// create category root
			Category *cat = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:moc];
			[cat setValue: @"++catroot" forKey: @"name" ];
		}
	}
}

-(NSManagedObjectContext*)context
{ 
	if(context == nil) [self loadModel ];
	return context; 
}
-(NSManagedObjectModel*)model 
{ 
	if(model == nil) [self loadModel ];
	return model; 
}


+(MOAssistant*)assistant
{
	if(assistant) return assistant;
	assistant = [[MOAssistant alloc ] init ];
	return assistant;
}

-(void)dealloc
{
	[accountsURL release ];
	[newStorePath release ];
	[oldStorePath release ];
	if(model) [model release ];
	if(context) [context release ];
	[memContext release ];
	assistant = nil;
	[super dealloc ];
}

@end
