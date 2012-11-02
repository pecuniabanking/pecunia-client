/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "MOAssistant.h"
#import "Category.h"
#import "BankAccount.h"
#import "PasswordWindow.h"
#import "Keychain.h"
#import "PecuniaError.h"
#import "LaunchParameters.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

@implementation MOAssistant

@synthesize ppDir;
@synthesize accountsURL;
@synthesize importerDir;
@synthesize tempDir;
@synthesize dataDirURL;
@synthesize dataFilename;
@synthesize pecuniaFileURL;
@synthesize dataPassword;


static MOAssistant	*assistant = nil;

static NSString *dataDirKey = @"DataDir";
static NSString *dataFilenameKey = @"dataFilename";

static NSString *extensionStandard = @".sqlite";
static NSString *extensionCrypted = @".sqlcrypt";
static NSString *extensionPackage = @".pecuniadata";
static NSString *_dataFile = @"/accounts.sqlite";
static NSString *_imageFile = @"/PecuniaData.sparseimage";

static NSString *_dataFileStandard = @"accounts.sqlite";
static NSString *_dataFileCrypted = @"accounts.sqlcrypt";

static NSString* lDir = @"~/Library/Application Support/Pecunia/Data";
static NSString* pDir = @"~/Library/Application Support/Pecunia/Passports";
static NSString* iDir = @"~/Library/Application Support/Pecunia/ImportSettings";

-(id)init
{
    self = [super init ];
    
    NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults ];
    
    self.dataFilename = [defaults valueForKey:dataFilenameKey];
    if (self.dataFilename == nil) {
        self.dataFilename = @"accounts.pecuniadata";
    }
    
    // customize data file name
    if ([LaunchParameters parameters ].dataFile) {
        self.dataFilename = [LaunchParameters parameters ].dataFile;
    }
    
    isEncrypted = NO;
    isDefaultDir = YES;
    decryptionDone = NO;
    
    // do we run in a Sandbox?
    [self checkSandboxed];
    
    // create default directories if necessary
    [self checkPaths ];
    
    // migrate old stores
    [self migrate10];
    
    [self accessSandbox];
    
    isEncrypted = [self checkIsEncrypted];
    
    if (isEncrypted == NO) {
        self.accountsURL = [self.pecuniaFileURL URLByAppendingPathComponent:_dataFileStandard];
    } else {
        self.accountsURL = [[NSURL fileURLWithPath:tempDir] URLByAppendingPathComponent:_dataFileStandard];
    }
    
    model = nil; 
    context = nil;
    return self;
}

-(void)checkSandboxed
{
    NSString *homeDir = [@"~" stringByExpandingTildeInPath];
    if ([homeDir hasSuffix:@"de.pecuniabanking.pecunia/Data"]) {
        isSandboxed = YES;
    } else {
        isSandboxed = NO;
    }
}

-(void)updateDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:self.dataFilename forKey:dataFilenameKey];
    if (isDefaultDir == NO) {
        [defaults setValue:[[self.dataDirURL path] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""] forKey:dataDirKey];
    }
}

-(void)accessSandbox
{
    NSError *error=nil;
    
    if (isSandboxed == NO || isDefaultDir == YES) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // we need a security scoped Bookmark
    NSURL *url=nil;
    NSData *bookmark = [defaults objectForKey:@"accountsBookmark"];
    if (bookmark != nil) {
        NSError *error=nil;
        url = [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:NULL error:&error];
        if (error != nil) {
            url = nil;
        }
    }
    if (url != nil) {
        // check if path is the same
        NSString *currentPath = [[dataDirURL URLByAppendingPathComponent:self.dataFilename] path];
        if ([currentPath isEqualToString:[url path]] == NO) {
            url = nil;
        }
    }
    
    if (url) {
        [url startAccessingSecurityScopedResource];
    } else {
        // start an open file dialog to get a SSB
        NSOpenPanel *op = [NSOpenPanel openPanel];
        [op setAllowsMultipleSelection:NO];
        [op setCanChooseDirectories:NO];
        [op setCanChooseFiles:YES];
        [op setCanCreateDirectories:NO];
        [op setDirectoryURL:self.dataDirURL];
        [op setAllowedFileTypes:[NSArray arrayWithObject:@"pecuniadata"]];
        [op setExtensionHidden:YES];
        [op setNameFieldStringValue:self.dataFilename];
        
        NSInteger result = [op runModal];
        if (result ==  NSFileHandlingPanelCancelButton) {
            // todo: Abbruch
            [NSApp terminate:nil];
            return;
        }
        
        url = [op URL];
        NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
        if (error != nil) {
            @throw error;
        } else {
            [defaults setValue:bookmark forKey:@"accountsBookmark"];
        }
        
        self.dataDirURL = [op directoryURL];
        self.dataFilename = [url lastPathComponent];
        
        [self updateDefaults];
    }
}

-(BOOL)checkIsEncrypted
{
    NSFileManager	*fm = [NSFileManager defaultManager ];
    NSURL *dataFileURL = [self.dataDirURL URLByAppendingPathComponent:self.dataFilename];
    NSURL *accountsFileURL = [dataFileURL URLByAppendingPathComponent:_dataFileCrypted];
    
    if ([fm fileExistsAtPath:[accountsFileURL path]]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)checkPaths
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

    NSString *dataDir = [defaults valueForKey: dataDirKey ];
    
    if (isSandboxed) {
        if (dataDir != nil) {
            if ([dataDir hasPrefix:@"/Users/"] && [dataDir hasSuffix:@"/Library/Application Support/Pecunia/Data"]) {
                // it's the default directory, set the DataDir to nil
                [defaults setValue: nil forKey: dataDirKey ];
                dataDir = defaultDataDir;
            } else {
                // it's not the default directory
                isDefaultDir = NO;
            }
        } else {
            dataDir = defaultDataDir;
        }
    } else {
        // not sandboxed
        if (dataDir == nil) {
            dataDir = defaultDataDir;
        } else {
            // check if it is the default directory
            if ([dataDir hasPrefix:defaultDataDir]) {
                [defaults setValue:nil forKey:dataDirKey];
                dataDir = defaultDataDir;
            } else {
                defaultDataDir = NO;
            }
        }
    }
    self.dataDirURL = [NSURL fileURLWithPath:dataDir];
    self.pecuniaFileURL = [self.dataDirURL URLByAppendingPathComponent:self.dataFilename];
	
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
    
    // Temporary Directory
    self.tempDir = NSTemporaryDirectory();
    
    // if it's the default data dir: check if the pecunia datafile already exists - if not, create it
    if (defaultDataDir) {
        if ([fm fileExistsAtPath:[self.pecuniaFileURL path]] == NO) {
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0700] forKey:NSFilePosixPermissions];
            [fm createDirectoryAtPath: [self.pecuniaFileURL path] withIntermediateDirectories: YES attributes: attributes error: &error ];
            if(error) @throw error;
        }
    }
}

-(void)migrate10
{
    if (isDefaultDir == NO) {
        return;
    }
    
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *accURL = [self.pecuniaFileURL URLByAppendingPathComponent:_dataFileCrypted];
    if ([fm fileExistsAtPath:[accURL path]] == NO) {
        accURL = [self.pecuniaFileURL URLByAppendingPathComponent:_dataFileStandard];
        if ([fm fileExistsAtPath:[accURL path]] == NO) {
            // the data store is empty - try to migrate
            NSURL *oldURL = [self.dataDirURL URLByAppendingPathComponent:[self.dataFilename stringByReplacingOccurrencesOfString:@"pecuniadata" withString:@"sqlite"]];
            if ([fm fileExistsAtPath:[oldURL path]] == YES) {
                [fm copyItemAtPath:[oldURL path] toPath:[accURL path] error:&error];
                if (error != nil) {
                    NSLog(@"Copy of old accounts file %@ to new location (%@) failed.", oldURL, accURL);
                }
            }
        }
    }
}

-(NSString*)passportDirectory
{
    return ppDir;
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

    if (isEncrypted) {
        [self encrypt];
    }
    
    if (isSandboxed && dataDirURL) {
        [dataDirURL stopAccessingSecurityScopedResource];
    }
}

-(BOOL)encrypted
{
    return isEncrypted;
}

-(BOOL)encrypt
{
    // first get key from password
    unsigned char key[32];
    int i;
    
    NSData *data = [self.dataPassword dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256([data bytes], (unsigned int)[data length], key);
    
    // read accounts file
    NSData *fileData = [NSData dataWithContentsOfURL:self.accountsURL];
    char *encryptedBytes = malloc([fileData length]+80);
    char *clearBytes = (char*)[fileData bytes];
    char checkData[64];

    for (i = 0; i<32; i++) {
        checkData[2*i] = key[i];
        checkData[2*i+1] = clearBytes[4*i+100];
    }
    
    // now encrypt check data
    CCCryptorStatus status;
    size_t encryptedSize;
    status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key, 32, NULL, checkData, 63, encryptedBytes, 64, &encryptedSize);

    // now encrypt file data
    if (status == kCCSuccess) {
        status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key, 32, NULL, clearBytes, (unsigned int)[fileData length], encryptedBytes+64, (unsigned int)[fileData length]+16, &encryptedSize);
    }
    
    if (status != kCCSuccess) {
        NSRunAlertPanel(NSLocalizedString(@"AP46", @""),
                        NSLocalizedString(@"AP186", @""),
                        NSLocalizedString(@"ok", @"Ok"),
                        nil,
                        nil);
        NSLog(@"CCCrypt failure: %d", status);
        free(encryptedBytes);
        return NO;
    }
    
    // write encrypted content to pecunia data file
    NSData *encryptedData = [NSData dataWithBytes:encryptedBytes length:encryptedSize+64];
    free(encryptedBytes);
    NSURL *targetURL = [pecuniaFileURL URLByAppendingPathComponent:_dataFileCrypted];
    if ([encryptedData writeToURL:targetURL atomically:NO] == NO) {
        NSRunAlertPanel(NSLocalizedString(@"AP46", @""),
                        NSLocalizedString(@"AP124", @""),
                        NSLocalizedString(@"ok", @"Ok"),
                        nil,
                        nil,
                        [targetURL path]);
        return NO;
    }
    
    // now remove uncrypted file
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error=nil;
    [fm removeItemAtPath:[accountsURL path] error:&error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return NO;
    }
    
    return YES;
}

-(BOOL)decrypt
{
    BOOL savePassword = NO;
    NSString *passwd;
    
    // read encrypted file
    NSURL *sourceURL = [pecuniaFileURL URLByAppendingPathComponent:_dataFileCrypted];
    NSData *fileData = [NSData dataWithContentsOfURL:sourceURL];
    char *decryptedBytes = malloc([fileData length]);
    unsigned char key[32];

    
    if (self.dataPassword == nil) {
        passwd = [Keychain passwordForService: @"Pecunia" account: @"DataFile" ];
        if(passwd == nil) {
            BOOL passwordOk = NO;
            PasswordWindow *pwWindow = [[[PasswordWindow alloc] initWithText: NSLocalizedString(@"AP54", @"")
                                                                       title: NSLocalizedString(@"AP53", @"")] autorelease];
            while (passwordOk == NO) {
                int res = [NSApp runModalForWindow: [pwWindow window]];
                if(res) [NSApp terminate: self ];

                passwd = [pwWindow result];
                savePassword = [pwWindow shouldSavePassword ];
                
                // first get key from password
                NSData *data = [passwd dataUsingEncoding:NSUTF8StringEncoding];
                CC_SHA256([data bytes], (unsigned int)[data length], key);
                
                // check if password is correct, first decrypt check data
                CCCryptorStatus status;
                size_t decryptedSize;
                status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key, 32, NULL, [fileData bytes], 64, decryptedBytes, 64, &decryptedSize);
                if (status != kCCSuccess) {
                    NSRunAlertPanel(NSLocalizedString(@"AP46", @""),
                                    NSLocalizedString(@"AP187", @""),
                                    NSLocalizedString(@"ok", @"Ok"),
                                    nil,
                                    nil);
                    NSLog(@"CCCrypt failure: %d", status);
                    free(decryptedBytes);
                    return NO;
                }

                // now check hash
                int i;
                passwordOk = YES;
                for (i=0; i<32; i++) {
                    if (key[i] != decryptedBytes[2*i]) {
                        // password is wrong
                        passwordOk = NO;
                        [pwWindow retry];
                        break;
                    }
                }
            }
        }
    } else {
        passwd = self.dataPassword;
    }
    
    // first get key from password
    NSData *data = [passwd dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256([data bytes], (unsigned int)[data length], key);
    
    // now decrypt
    CCCryptorStatus status;
    size_t decryptedSize;
    char *encryptedBytes = (char*)[fileData bytes];
    status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key, 32, NULL, encryptedBytes+64, (unsigned int)[fileData length]-64, decryptedBytes, (unsigned int)[fileData length]-64, &decryptedSize);
    
    if (status != kCCSuccess) {
        NSRunAlertPanel(NSLocalizedString(@"AP46", @""),
                        NSLocalizedString(@"AP187", @""),
                        NSLocalizedString(@"ok", @"Ok"),
                        nil,
                        nil);
        NSLog(@"CCCrypt failure: %d", status);
        free(decryptedBytes);
        return NO;
    }
    
    NSData *decryptedData = [NSData dataWithBytes:decryptedBytes length:decryptedSize];
    free(decryptedBytes);
    if ([decryptedData writeToURL:accountsURL atomically:NO] == NO) {
        NSRunAlertPanel(NSLocalizedString(@"AP46", @""),
                        NSLocalizedString(@"AP124", @""),
                        NSLocalizedString(@"ok", @"Ok"),
                        nil,
                        nil,
                        [accountsURL path]);
        return NO;
    }

    // if everything was successful, we can save the password
    self.dataPassword = passwd;
    if (savePassword) {
        [Keychain setPassword: passwd forService: @"Pecunia" account: @"DataFile" store: savePassword ];
    }
    
    decryptionDone = YES;
    return YES;
}

-(BOOL)encryptDataWithPassword: (NSString*)password
{
    
    self.dataPassword = password;
    if ([self encrypt] == NO) {
        return NO;
    }
    
    self.accountsURL = [[NSURL fileURLWithPath:tempDir] URLByAppendingPathComponent:_dataFileStandard];
    isEncrypted = YES;
    [self decrypt];
    
    // set coordinator and stores
    NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator ];
    NSArray *stores = [coord persistentStores ];
    NSPersistentStore *store;
    for(store in stores) {
        [coord setURL: accountsURL forPersistentStore: store ];
    }
    
    return YES;
}

-(BOOL)stopEncryption
{
    if(!isEncrypted) return NO;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error=nil;
    
    // move unencrypted file
    NSURL *targetURL = [pecuniaFileURL URLByAppendingPathComponent:_dataFileStandard];
    [fm moveItemAtPath:[accountsURL path] toPath:[targetURL path] error:&error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return NO;
    }

    self.accountsURL = targetURL;
    isEncrypted = NO;
    
    // remove encrypted file
    targetURL = [pecuniaFileURL URLByAppendingPathComponent:_dataFileCrypted];
    [fm removeItemAtPath:[targetURL path] error:&error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }
    
    // set coordinator and stores
    NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator ];
    NSArray *stores = [coord persistentStores ];
    NSPersistentStore *store;
    for(store in stores) {
        [coord setURL: accountsURL forPersistentStore: store ];
    }
    
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
    if (isEncrypted && decryptionDone == NO) return;
    
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

-(void)relocate
{
   	NSFileManager *fm = [NSFileManager defaultManager ];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSError *error=nil;
    
	NSSavePanel *panel = [NSSavePanel savePanel ];
    [panel setNameFieldStringValue:self.dataFilename];
    [panel setCanCreateDirectories:YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"pecuniadata"]];
    if (isDefaultDir == NO) {
        [panel setDirectoryURL:self.dataDirURL];
    }
    
    NSInteger result = [panel runModal];
    if (result == NSFileHandlingPanelCancelButton) {
        return;
    }
    
    NSURL *newFilePathURL = [panel URL];
    NSString *newFilename = [newFilePathURL lastPathComponent];
    NSURL *newDataDirURL = [panel directoryURL];
    
    // first check if data file already exists at target position
    BOOL useExisting = NO;
    if ([fm fileExistsAtPath:[newFilePathURL path]]) {
        int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP42", @""),
                                          NSLocalizedString(@"AP59", @""),
                                          NSLocalizedString(@"cancel", @""),
                                          NSLocalizedString(@"AP61", @""),
                                          NSLocalizedString(@"AP60", @""),
                                          [newFilePathURL path]
                                          );

        if (res == NSAlertDefaultReturn) {
            return;
        }
        if (res == NSAlertAlternateReturn) {
            // remove existing file
            [fm removeItemAtPath:[newFilePathURL path] error:&error];
            if (error != nil) {
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
                return;
            }
        }
        
        if (res == NSAlertOtherReturn && isEncrypted) {
            // if current store is encrypted first remove it
            [fm removeItemAtPath:[self.accountsURL path] error:&error];
            if (error != nil) {
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
                return;
            }
        }
        
        if (res == NSAlertOtherReturn) {
            useExisting = YES;
        }
     }

    // move pecunia file with all included files
    [fm moveItemAtPath:[pecuniaFileURL path] toPath:[newFilePathURL path] error:&error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
        
    // set file and directory variables
    self.dataDirURL = newDataDirURL;
    self.dataFilename = newFilename;
    self.pecuniaFileURL = newFilePathURL;
    
    isDefaultDir = NO;
    [self updateDefaults];
    
    // get SCB
    NSData *bookmark = [self.pecuniaFileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    } else {
        [defaults setValue:bookmark forKey:@"accountsBookmark"];
    }
    
    
    // now use new store
    if (useExisting) {
        // new store should be used instead of old one. Check if it is a crypted store. If yes, decrypt it
        isEncrypted = [self checkIsEncrypted];
        
        // decrypt store and set accountsURL
        if (isEncrypted) {
            self.accountsURL = [[NSURL fileURLWithPath:tempDir] URLByAppendingPathComponent:_dataFileStandard];
            self.dataPassword = nil;
            [self decrypt];
        }
        
    }
    
    if (isEncrypted == NO) {
        self.accountsURL = [self.pecuniaFileURL URLByAppendingPathComponent:_dataFileStandard];
    }
    
    // set coordinator and stores
    NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator ];
    NSArray *stores = [coord persistentStores ];
    NSPersistentStore *store;
    for(store in stores) {
        [coord setURL: self.accountsURL forPersistentStore: store ];
    }
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
    [accountsURL release];
    [dataDirURL release];
    [dataFilename release];
    [dataPassword release];
    [pecuniaFileURL release];
    [ppDir release];
    [importerDir release];
    [tempDir release];
    if(model) [model release ];
    if(context) [context release ];
    [memContext release ];
    assistant = nil;
    [accountsURL release], accountsURL = nil;

    [super dealloc ];
}

@end

