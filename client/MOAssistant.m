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
#import "MigrationManagerWorkaround.h"

#define CURRENT_BUILD 3

NSString* const MD_Build_Number = @"MD_BUILDNUMBER";

@implementation MOAssistant

static MOAssistant	*assistant = nil;
//static NSString* oldFile = @"accounts_old.sqlite";
static NSString *dataFile = @"accounts.sqlite";
static NSString *imageFile = @"PecuniaData.sparseimage";
static NSString *_dataFile = @"/accounts.sqlite";
static NSString *_imageFile = @"/PecuniaData.sparseimage";

static NSString* lDir = @"~/Library/Application Support/Pecunia/Data";
static NSString* pDir = @"~/Library/Application Support/Pecunia/Passports";


-(id)init
{
	self = [super init ];
	
	[NSMigrationManager addRelationshipMigrationMethodIfMissing ];
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults ];

	encrypted = NO;
	
	// create default directories if necessary
	[self checkPaths ];
	
	[self migrateDataDirFrom02 ];
	
	encrypted = [self isEncryptedImageAtPath: dataDir ];
	
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
		NSString *imagePath = [dataDir stringByAppendingString: _imageFile ];
		[self openImageWithPath: imagePath ];
	} else {
	// no encryption
		dataStorePath = [NSString stringWithFormat: @"%@/%@", dataDir, dataFile ];
		[dataStorePath retain ];
	}
	accountsURL = [[NSURL fileURLWithPath: dataStorePath] retain ];
	model = nil; 
	context = nil;
	return self;
}

-(BOOL)isEncryptedImageAtPath:(NSString*)path
{
	NSFileManager	*fm = [NSFileManager defaultManager ];
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults ];

	NSString *imagePath = [path stringByAppendingString: _imageFile ];
	NSDictionary *attrs = [fm attributesOfItemAtPath: imagePath error: NULL ];
	
	if(attrs) {
		BOOL forceEncryption = [defaults boolForKey: @"forceEncryption" ];
		if(forceEncryption) {
			[defaults setBool:NO forKey: @"forceEncryption" ];
			return YES;
		} else {
			// file exists
			NSDate *imageDate = [attrs objectForKey: NSFileModificationDate ];
			NSString *filePath = [path stringByAppendingString: _dataFile ];
			attrs = [fm attributesOfItemAtPath: filePath error: NULL ];
			if(attrs) {
				// accounts.sqlite exists
				NSDate *fileDate = [attrs objectForKey: NSFileModificationDate ];
				// if image is newer: take it
				if([fileDate compare: imageDate ] == NSOrderedAscending) {
					return YES;
				}
			} else {
				// accounts.sqlite does not exist but image exists
				return YES;
			}
		}
	}
	return NO;
}

-(NSString*)dataFileNameAtPath:(NSString*)path
{
	if ([self isEncryptedImageAtPath: path ]) {
		return imageFile;
	} else {
		return dataFile;
	}
}

-(void)checkPaths
{
	// create default paths
	NSFileManager	*fm = [NSFileManager defaultManager ];
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults ];
	NSError *error = nil;
	
	NSString *defaultDataDir = [lDir stringByExpandingTildeInPath ];
	if([fm fileExistsAtPath: defaultDataDir] == NO) {
		[fm createDirectoryAtPath: defaultDataDir withIntermediateDirectories: YES attributes: nil error: &error ];
		if(error) @throw error;
	}
	
	dataDir = [defaults valueForKey: @"DataDir" ];
	
	// DB directory
	if(dataDir == nil) {
		dataDir = [defaultDataDir retain];
		[defaults setValue: dataDir forKey: @"DataDir" ];
	}
	
	// Passport directory
	ppDir = [[pDir stringByExpandingTildeInPath ] retain];
	if([fm fileExistsAtPath: ppDir] == NO) {
		[fm createDirectoryAtPath: ppDir withIntermediateDirectories: YES attributes: nil error: &error ];
		if(error) @throw error;
	}
}

-(void)migrateDataDirFrom02
{
	NSFileManager	*fm = [NSFileManager defaultManager ];
	NSError *error = nil;
	NSString *newDefaultDir = [lDir stringByExpandingTildeInPath ];
	NSString *newPath = [newDefaultDir stringByAppendingString: _dataFile ];
	if([fm fileExistsAtPath: newPath] == YES) return;
	newPath = [newDefaultDir stringByAppendingString: _imageFile ];
	if([fm fileExistsAtPath: newPath] == YES) return;

	NSDictionary *oldDefaults = [NSDictionary dictionaryWithContentsOfFile: [@"~/Library/Preferences/com.macemmi.pecunia.plist" stringByExpandingTildeInPath ]];
	if(oldDefaults == nil) return;
	NSString *oldDir = [oldDefaults valueForKey:@"DataDir" ];
	if(oldDir == nil) return;
	
	NSString *oldDefaultDir = [ @"~/Library/Pecunia" stringByExpandingTildeInPath ];
	NSString *file = [self dataFileNameAtPath: oldDir ];
	
	if ([oldDir isEqualToString:oldDefaultDir ]) {
		newPath = [NSString stringWithFormat: @"%@/%@", newDefaultDir, file ];
		NSString *oldPath = [NSString stringWithFormat: @"%@/%@", oldDir, file ];
		
		BOOL success = [fm copyItemAtPath: oldPath toPath: newPath error: &error ];
		if(!success) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
}


-(NSString*)passportDirectory
{
	return ppDir;
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
		dataStorePath = [NSString stringWithFormat: @"%@/%@", [wrapper volumePath ], dataFile ];
		[dataStorePath retain ];
		[Keychain setPassword: passwd forService: @"Pecunia" account: @"DataFile" store: savePassword ];
		
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
	imagePath = [path stringByAppendingString: _imageFile ];
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
	NSString *oldPath = [dataStorePath copy ];
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
	NSString *imagePath = [path stringByAppendingString: _imageFile ];
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
	NSError	*error = nil;
	
	if(model) [model release ];
	if(context) [context release ];
	
	NSURL *momURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Accounts" ofType:@"momd"]];
	model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];

	NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	id store = [coord addPersistentStoreWithType: NSSQLiteStoreType 
								   configuration: nil 
											 URL: accountsURL
										 options: [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES ], NSMigratePersistentStoresAutomaticallyOption, nil ] 
										   error: &error];

	if( error != nil ) @throw error;
	
	context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator: coord ];
	
	// save new context
/*	
	if(storeExists == NO) {
		if([context save: &error ] == NO) {
			@throw error;
		}
	}
*/	
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

-(BOOL)relocateToPath: (NSString*)path
{
	NSFileManager *fm = [NSFileManager defaultManager ];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	NSString *filePath;
	NSString *oldFilePath;
	BOOL fileExists = NO;
	
	// check if files exist at target position
	if(encrypted) filePath = [path stringByAppendingString: _imageFile ];
	else filePath = [path stringByAppendingString: _dataFile ];
	
	if(encrypted) oldFilePath = [dataDir stringByAppendingString: _imageFile  ];
	else oldFilePath = [dataDir stringByAppendingString: _dataFile  ];
	
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
	NSString *newPath = [NSString stringWithFormat: @"%@/%@", path, dataFile ];
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

	if([fm copyItemAtPath: dataStorePath toPath: newPath error:&error ] == NO) {
		// file cannot be copied
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return NO;
	};
	
	// now file is copied to new location
	[dataDir release ];
	dataDir = [path retain ];
	
	[dataStorePath release ];
	dataStorePath = [NSString stringWithFormat: @"%@/%@", dataDir, dataFile ];
	[dataStorePath retain ];
	accountsURL = [NSURL fileURLWithPath: dataStorePath];
	
	// set coordinator and stores
	NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator ];
	NSArray *stores = [coord persistentStores ];
	NSPersistentStore *store;
	for(store in stores) {
		[coord setURL: accountsURL forPersistentStore: store ];
	}
	return YES;
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
	[dataStorePath release ];
	if(model) [model release ];
	if(context) [context release ];
	[memContext release ];
	assistant = nil;
	[super dealloc ];
}

@end
