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
#import "LaunchParameters.h"

//#define CURRENT_BUILD 3
//NSString* const MD_Build_Number = @"MD_BUILDNUMBER";

@implementation MOAssistant

@synthesize dataDir;
@synthesize ppDir;
@synthesize dataStorePath;
@synthesize accountsURL;
@synthesize importerDir;

static MOAssistant	*assistant = nil;
//static NSString* oldFile = @"accounts_old.sqlite";
static NSString *_dataFile = @"/accounts.sqlite";
static NSString *_imageFile = @"/PecuniaData.sparseimage";

static NSString* lDir = @"~/Library/Application Support/Pecunia/Data";
static NSString* pDir = @"~/Library/Application Support/Pecunia/Passports";
static NSString* iDir = @"~/Library/Application Support/Pecunia/ImportSettings";

-(id)init
{
	self = [super init ];
	
	[NSMigrationManager addRelationshipMigrationMethodIfMissing ];
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults ];

    // customize data file name
    if ([LaunchParameters parameters ].dataFile) {
        _dataFile = [LaunchParameters parameters ].dataFile;
    }

	encrypted = NO;
	imageAvailable = NO;
	
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

	if (encrypted == NO) {
		self.dataStorePath = [dataDir stringByAppendingString:_dataFile ];
		self.accountsURL = [NSURL fileURLWithPath: dataStorePath];
	}
	
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
		return _imageFile;
	} else {
		return _dataFile;
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
	
	self.dataDir = [defaults valueForKey: @"DataDir" ];
	
	// DB directory
	if(dataDir == nil) {
		self.dataDir = defaultDataDir;
		[defaults setValue: dataDir forKey: @"DataDir" ];
	}
	
	// Passport directory
	self.ppDir = [pDir stringByExpandingTildeInPath];
	if([fm fileExistsAtPath: ppDir] == NO) {
		[fm createDirectoryAtPath: ppDir withIntermediateDirectories: YES attributes: nil error: &error ];
		if(error) @throw error;
	}
	
	// ImExporter Directory
	self.importerDir = [iDir stringByExpandingTildeInPath];
	if([fm fileExistsAtPath: importerDir ] == NO) {
		[fm createDirectoryAtPath: importerDir withIntermediateDirectories: YES attributes: nil error: &error ];
		if(error) @throw error;
	}
}

-(void)migrateDataDirFrom02
{
	NSFileManager	*fm = [NSFileManager defaultManager ];
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults ];
	NSError *error = nil;
	BOOL success;
	NSString *newDefaultDir = [lDir stringByExpandingTildeInPath ];
	NSString *newPath = [newDefaultDir stringByAppendingString: _dataFile ];
	
	if([fm fileExistsAtPath: newPath] == YES) return;
	newPath = [newDefaultDir stringByAppendingString: _imageFile ];
	if([fm fileExistsAtPath: newPath] == YES) return;
	
	// copy preferences
	NSDictionary *oldDefaults = [NSDictionary dictionaryWithContentsOfFile: [@"~/Library/Preferences/com.macemmi.pecunia.plist" stringByExpandingTildeInPath ]];
	if(oldDefaults == nil) return;

	for(NSString* key in [oldDefaults allKeys ]) {
		if ([key isEqualToString:@"DataDir" ]) continue;
		NSRange r = [key rangeOfString:@":" ];
		if (r.location != NSNotFound) continue;
		[defaults setObject:[oldDefaults objectForKey:key ] forKey:key ];
	}
		
	// copy data file if located at old defaults path
	NSString *oldDir = [oldDefaults valueForKey:@"DataDir" ];
	if(oldDir == nil) return;
	
	NSString *oldDefaultDir = [ @"~/Library/Pecunia" stringByExpandingTildeInPath ];
	NSString *file = [self dataFileNameAtPath: oldDir ];
	
	if ([oldDir isEqualToString:oldDefaultDir ]) {
		newPath = [newDefaultDir stringByAppendingString:file ];
		NSString *oldPath = [oldDir stringByAppendingString:file ];
		
		success = [fm copyItemAtPath: oldPath toPath: newPath error: &error ];
		if(!success) {
            NSLog(@"Migration from file: %@ to file: %@ was not successful!", oldPath, newPath );
			return;
		}
	} else {
		self.dataDir = oldDir;
		[defaults setValue: oldDir forKey: @"DataDir" ];		
	}

}

-(NSString*)passportDirectory
{
	return ppDir;
}


-(BOOL)openImage
{
	HDIWrapper *wrapper = [HDIWrapper wrapper ];
	NSString *path = [dataDir stringByAppendingString: _imageFile ];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	BOOL browsable = [defaults boolForKey: @"BrowseImage" ];

	BOOL savePassword = NO;
	NSString* passwd = [Keychain passwordForService: @"Pecunia" account: @"DataFile" ];
	if(passwd == nil) {
		PasswordWindow *pwWindow = [[[PasswordWindow alloc] initWithText: NSLocalizedString(@"AP54", @"")
                                                                   title: NSLocalizedString(@"AP53", @"")] autorelease];
		
		
		int res = [NSApp runModalForWindow: [pwWindow window]];
		if(res) [NSApp terminate: self ];
		
		passwd = [pwWindow result];
		savePassword = [pwWindow shouldSavePassword ];
	}
	
	BOOL success = [wrapper attachImage: path withPassword: passwd browsable: browsable ];
	
	if(success) {
		self.dataStorePath = [[wrapper volumePath ] stringByAppendingString:_dataFile ];
		[Keychain setPassword: passwd forService: @"Pecunia" account: @"DataFile" store: savePassword ];
		self.accountsURL = [NSURL fileURLWithPath: dataStorePath];
		imageAvailable = YES;
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

-(BOOL)encryptDataWithPassword: (NSString*)password
{
	// now create 
	HDIWrapper *wrapper = [HDIWrapper wrapper ];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSString *path = [defaults valueForKey: @"DataDir" ];
	BOOL browsable = [defaults boolForKey: @"BrowseImage" ];
	NSString *imagePath = [path stringByAppendingString: @"/PecuniaData" ];
	
	BOOL success = [wrapper createImage: imagePath withPassword: password strongEncryption: YES ];
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
	if(model) [model release ];
	
	NSURL *momURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Accounts" ofType:@"momd"]];
	model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
}

-(void)loadContext
{
	NSError	*error = nil;

	if (model == nil) [self loadModel ];
	if(context) [context release ];
	if (encrypted && imageAvailable == NO) return;
	
	NSPersistentStoreCoordinator *coord = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model] autorelease];
	
	[coord addPersistentStoreWithType: NSSQLiteStoreType 
						configuration: nil 
								  URL: accountsURL
							  options: [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES ], NSMigratePersistentStoresAutomaticallyOption, 
                                                                                  [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil ] 
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
	
	NSPersistentStoreCoordinator *coord = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model] autorelease];

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
	self.dataDir = path;
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
	NSString *newPath = [path stringByAppendingString:_dataFile ];
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
	self.dataDir = path;
	
	self.dataStorePath = [dataDir stringByAppendingString:_dataFile ];
	self.accountsURL = [NSURL fileURLWithPath: dataStorePath];
	
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
	if(context == nil) [self loadContext ];
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
	[dataDir release], dataDir = nil;
	[dataStorePath release], dataStorePath = nil;
	[accountsURL release], accountsURL = nil;

	[super dealloc ];
}

@end

