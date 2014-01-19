/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import "Keychain.h"

#import "MOAssistant.h"
#import "Category.h"
#import "BankAccount.h"
#import "PasswordWindow.h"
#import "PecuniaError.h"
#import "LaunchParameters.h"
#import "MainBackgroundView.h"
#import "BankingController.h"
#import "MessageLog.h"

@implementation MOAssistant

@synthesize ppDir;
@synthesize accountsURL;
@synthesize importerDir;
@synthesize tempDir;
@synthesize dataDirURL;
@synthesize dataFilename;
@synthesize pecuniaFileURL;
@synthesize mainContentView;
@synthesize isMaxIdleTimeExceeded;

static MOAssistant *assistant = nil;

static NSString *dataDirKey = @"DataDir";
static NSString *dataFilenameKey = @"dataFilename";

static NSString *_dataFileStandard = @"accounts.sqlite";
static NSString *_dataFileCrypted = @"accounts.sqlcrypt";

static NSString *lDir = @"~/Library/Application Support/Pecunia/Data";
static NSString *pDir = @"~/Library/Application Support/Pecunia/Passports";
static NSString *iDir = @"~/Library/Application Support/Pecunia/ImportSettings";

- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    self.dataFilename = [defaults valueForKey: dataFilenameKey];
    if (self.dataFilename == nil) {
        self.dataFilename = @"accounts.pecuniadata";
    }

    // customize data file name
    if ([LaunchParameters parameters].dataFile) {
        self.dataFilename = [LaunchParameters parameters].dataFile;
    }

    isEncrypted = NO;
    isDefaultDir = YES;
    decryptionDone = NO;
    passwordKeyValid = NO;

    // do we run in a Sandbox?
    [self checkSandboxed];

    // create default directories if necessary
    [self checkPaths];

    // migrate old stores
    [self migrate10];

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(startIdle) name: NSApplicationDidResignActiveNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(stopIdle) name: NSApplicationDidBecomeActiveNotification object: nil];

    idleTimer = nil;
    model = nil;
    context = nil;

    return self;
}

- (void)startIdle
{
    LOG_ENTER;

    if (isEncrypted && isMaxIdleTimeExceeded == NO && decryptionDone == YES) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUInteger     idx = [defaults integerForKey: @"lockTimeIndex"];
        NSUInteger     seconds = 0;

        switch (idx) {
            case 1: seconds = 10; break;

            case 2: seconds = 30; break;

            case 3: seconds = 60; break;

            case 4: seconds = 180; break;

            case 5: seconds = 600; break;

            default:
                break;
        }

        if (seconds > 0) {
            idleTimer = [NSTimer scheduledTimerWithTimeInterval: seconds target: self selector: @selector(maxIdleTimeExceeded) userInfo: nil repeats: NO];
        }
        isMaxIdleTimeExceeded = NO;
    }

    LOG_LEAVE;
}

- (void)stopIdle
{
    LOG_ENTER;

    if (isEncrypted == NO || passwordKeyValid == NO) {
        LOG_LEAVE;
        return;
    }
    [idleTimer invalidate];
    idleTimer = nil;

    if (isMaxIdleTimeExceeded) {
        // check password again
        passwordKeyValid = NO;
        [self decrypt];
        [lockView removeFromSuperview];

        [[NSApp mainWindow] makeKeyAndOrderFront: nil];
        isMaxIdleTimeExceeded = NO;
    }
    LOG_LEAVE;
}

- (void)maxIdleTimeExceeded
{
    LOG_ENTER;
    if (isEncrypted == NO) {
        LOG_LEAVE;
        return;
    }

    NSError *error = nil;
    [context save: &error];
    if (error != nil) {
        NSLog(@"Pecunia save error: %@", error.localizedDescription);
        LOG_LEAVE;
        return;
    }

    isMaxIdleTimeExceeded = YES;

    // encrypt database (but do not disconnect store)
    [self encrypt];

    // Show lock view
    lockView = [[MainBackgroundView alloc] initWithFrame: [mainContentView frame]];
    [lockView setAlphaValue: 0.7];
    [mainContentView addSubview: lockView];

    LOG_LEAVE;
}

// initializes the data file (can be default data file from preferences or
// from Finder integration)
- (void)initDatafile: (NSString *)path
{
    LOG_ENTER;

    if (context != nil) {
        abort();
    }

    if (self.accountsURL != nil) {
        // data file already defined
        LOG_LEAVE;
        return;
    }

    if (path == nil) {
        // use standard path (as defined in Preferences)
        [self accessSandbox];
    } else {
        // use other data file at startup
        NSURL *fileURL = [NSURL fileURLWithPath: path];
        self.dataFilename = [fileURL lastPathComponent];

        isDefaultDir = NO;

        self.dataDirURL = [fileURL URLByDeletingLastPathComponent];
        self.pecuniaFileURL = fileURL;
    }

    isEncrypted = [self checkIsEncrypted];

    if (isEncrypted == NO) {
        self.accountsURL = [self.pecuniaFileURL URLByAppendingPathComponent: _dataFileStandard];
    } else {
        self.accountsURL = [[NSURL fileURLWithPath: tempDir] URLByAppendingPathComponent: _dataFileStandard];
    }

    LOG_LEAVE;
}

- (void)checkSandboxed
{
    NSString *homeDir = [@"~" stringByExpandingTildeInPath];
    if ([homeDir hasSuffix: @"de.pecuniabanking.pecunia/Data"]) {
        isSandboxed = YES;
    } else {
        isSandboxed = NO;
    }
}

- (void)updateDefaults
{
    LOG_ENTER;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue: self.dataFilename forKey: dataFilenameKey];
    if (isDefaultDir == NO) {
        [defaults setValue: [[self.dataDirURL path] stringByReplacingOccurrencesOfString: @"file://localhost" withString: @""] forKey: dataDirKey];
    } else {
        [defaults setValue: nil forKey: dataDirKey];
    }

    LOG_LEAVE;
}

- (void)accessSandbox
{
    LOG_ENTER;

    NSError *error = nil;

    if (isSandboxed == NO || isDefaultDir == YES) {
        LOG_LEAVE;
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // we need a security scoped Bookmark
    NSURL  *url = nil;
    NSData *bookmark = [defaults objectForKey: @"accountsBookmark"];
    if (bookmark != nil) {
        NSError *error = nil;
        url = [NSURL URLByResolvingBookmarkData: bookmark options: NSURLBookmarkResolutionWithSecurityScope relativeToURL: nil bookmarkDataIsStale: NULL error: &error];
        if (error != nil) {
            url = nil;
        }
    }
    if (url != nil) {
        // check if path is the same
        NSString *currentPath = [[dataDirURL URLByAppendingPathComponent: self.dataFilename] path];
        if ([currentPath isEqualToString: [url path]] == NO) {
            url = nil;
        }
    }

    if (url) {
        [url startAccessingSecurityScopedResource];
    } else {
        // start an open file dialog to get a SSB
        NSOpenPanel *op = [NSOpenPanel openPanel];
        [op setAllowsMultipleSelection: NO];
        [op setCanChooseDirectories: NO];
        [op setCanChooseFiles: YES];
        [op setCanCreateDirectories: NO];
        [op setDirectoryURL: self.dataDirURL];
        [op setAllowedFileTypes: @[@"pecuniadata"]];
        [op setExtensionHidden: YES];
        [op setNameFieldStringValue: self.dataFilename];

        NSInteger result = [op runModal];
        if (result ==  NSFileHandlingPanelCancelButton) {
            // todo: Abbruch
            [NSApp terminate: nil];
            return;
        }

        url = [op URL];
        if (![[url lastPathComponent] isEqualToString:self.dataFilename]) {
            @throw [PecuniaError errorWithText: [NSString stringWithFormat:NSLocalizedString(@"AP177", nil), self.dataFilename ]];
        }
        
        NSData *bookmark = [url bookmarkDataWithOptions: NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys: nil relativeToURL: nil error: &error];
        if (error != nil) {
            @throw error;
        } else {
            [defaults setValue: bookmark forKey: @"accountsBookmark"];
        }

        self.dataDirURL = [op directoryURL];
        self.dataFilename = [url lastPathComponent];

        [self updateDefaults];
    }

    LOG_LEAVE;
}

- (BOOL)checkIsEncrypted
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL         *dataFileURL = [self.dataDirURL URLByAppendingPathComponent: self.dataFilename];
    NSURL         *accountsFileURL = [dataFileURL URLByAppendingPathComponent: _dataFileCrypted];

    if ([fm fileExistsAtPath: [accountsFileURL path]]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)checkIsDefaultDataDir:(NSURL*)newDirURL
{
    LOG_ENTER;

    // check if the new data path is the default data path
    NSURL *defaultDataURL = [NSURL fileURLWithPath: [lDir stringByExpandingTildeInPath]];
    BOOL result = NO;
    if ([newDirURL isEqual: defaultDataURL]) {
        result = YES;
    }

    LOG_LEAVE;

    return result;
}

- (void)checkPaths
{
    LOG_ENTER;

    // create default paths
    NSFileManager  *fm = [NSFileManager defaultManager];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSError        *error = nil;

    NSString *defaultDataDir = [lDir stringByExpandingTildeInPath];
    if ([fm fileExistsAtPath: defaultDataDir] == NO) {
        [fm createDirectoryAtPath: defaultDataDir withIntermediateDirectories: YES attributes: nil error: &error];
        if (error) {
            @throw error;
        }
    }

    NSString *dataDir = [defaults valueForKey: dataDirKey];

    if (isSandboxed) {
        if (dataDir != nil) {
            if ([dataDir hasSuffix: @"/Library/Application Support/Pecunia/Data"]) {
                // it's the default directory, set the DataDir to nil
                [defaults setValue: nil forKey: dataDirKey];
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
            if ([dataDir hasPrefix: defaultDataDir]) {
                [defaults setValue: nil forKey: dataDirKey];
                dataDir = defaultDataDir;
            } else {
                isDefaultDir = NO;
            }
        }
    }
    self.dataDirURL = [NSURL fileURLWithPath: dataDir];
    self.pecuniaFileURL = [self.dataDirURL URLByAppendingPathComponent: self.dataFilename];

    // Passport directory
    self.ppDir = [pDir stringByExpandingTildeInPath];
    if ([fm fileExistsAtPath: ppDir] == NO) {
        [fm createDirectoryAtPath: ppDir withIntermediateDirectories: YES attributes: nil error: &error];
        if (error) {
            @throw error;
        }
    }

    // ImExporter Directory
    self.importerDir = [iDir stringByExpandingTildeInPath];
    if ([fm fileExistsAtPath: importerDir] == NO) {
        [fm createDirectoryAtPath: importerDir withIntermediateDirectories: YES attributes: nil error: &error];
        if (error) {
            @throw error;
        }
    }

    // Temporary Directory
    self.tempDir = NSTemporaryDirectory();

    // if it's the default data dir: check if the pecunia datafile already exists - if not, create it
    if (isDefaultDir) {
        if ([fm fileExistsAtPath: [self.pecuniaFileURL path]] == NO) {
            NSDictionary *attributes = @{NSFilePosixPermissions: @0700, NSFileExtensionHidden: @YES};
            [fm createDirectoryAtPath: [self.pecuniaFileURL path] withIntermediateDirectories: YES attributes: attributes error: &error];
            if (error) {
                @throw error;
            }
        }
    }

    LOG_LEAVE;
}

- (void)migrate10
{
    LOG_ENTER;

    NSError *error = nil;

    NSFileManager  *fm = [NSFileManager defaultManager];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           migrated10 = [defaults boolForKey: @"Migrated10"];
    if (migrated10 == NO) {
        if (isDefaultDir == NO) {
            @throw [PecuniaError errorWithText: NSLocalizedString(@"AP159", nil)];
        }

        // check for encryption / sparseimage file
        NSURL *oldURLStandard = [self.dataDirURL URLByAppendingPathComponent: @"accounts.sqlite"];
        NSURL *oldURLEncr = [self.dataDirURL URLByAppendingPathComponent: @"accounts.sparseimage"];

        BOOL wasEncrypted = NO;
        if ([fm fileExistsAtPath: [oldURLEncr path]]) {
            // encrypted file exists, check if unencrypted file exists as well and is older
            if ([fm fileExistsAtPath: [oldURLStandard path]]) {
                // yes, now we have to check the dates
                NSDictionary *standardAttrs = [fm attributesOfItemAtPath: [oldURLStandard path] error: &error];
                NSDictionary *encrAttrs = [fm attributesOfItemAtPath: [oldURLEncr path] error: &error];
                NSDate       *standardDate = standardAttrs[NSFileModificationDate];
                NSDate       *encrDate = encrAttrs[NSFileModificationDate];
                if ([encrDate compare: standardDate] == NSOrderedDescending) {
                    wasEncrypted = YES;
                }
            } else {
                wasEncrypted = YES;
            }
        }
        if (wasEncrypted) {
            @throw [PecuniaError errorWithText: NSLocalizedString(@"AP160", nil)];
        }
    }

    if (isDefaultDir == NO) {
        LOG_LEAVE;
        return;
    }

    NSURL *accURL = [self.pecuniaFileURL URLByAppendingPathComponent: _dataFileCrypted];
    if ([fm fileExistsAtPath: [accURL path]] == NO) {
        accURL = [self.pecuniaFileURL URLByAppendingPathComponent: _dataFileStandard];
        if ([fm fileExistsAtPath: [accURL path]] == NO) {
            // the data store is empty - try to migrate
            NSURL *oldURL = [self.dataDirURL URLByAppendingPathComponent: [self.dataFilename stringByReplacingOccurrencesOfString: @"pecuniadata" withString: @"sqlite"]];
            if ([fm fileExistsAtPath: [oldURL path]] == YES) {
                [fm moveItemAtPath: [oldURL path] toPath: [accURL path] error: &error];
                if (error != nil) {
                    NSLog(@"Move of old accounts file %@ to new location (%@) failed.", oldURL, accURL);
                }
            }
        }
    }

    LOG_LEAVE;
}

- (NSString *)passportDirectory
{
    return ppDir;
}

- (void)shutdown
{
    LOG_ENTER;

    NSError *error = nil;

    NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator];
    NSArray                      *stores = [coord persistentStores];
    NSPersistentStore            *store;
    for (store in stores) {
        [coord removePersistentStore: store error: &error];
    }
    if (error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }

    if (isEncrypted && isMaxIdleTimeExceeded == NO) {
        [self encrypt];
    }

    if (isSandboxed && dataDirURL) {
        [dataDirURL stopAccessingSecurityScopedResource];
    }

    LOG_LEAVE;
}

- (BOOL)encrypted
{
    return isEncrypted;
}

- (NSData*)encryptData:(NSData*)data withKey:(unsigned char*)passwordKey
{
    LOG_ENTER;

    char   *encryptedBytes = malloc([data length] + 80);
    char   *clearBytes = (char *)[data bytes];
    char   checkData[64];
    int    i;
    
    for (i = 0; i < 32; i++) {
        checkData[2 * i] = passwordKey[i];
        checkData[2 * i + 1] = clearBytes[4 * i + 100];
    }
    // now encrypt check data
    CCCryptorStatus status;
    size_t          encryptedSize;
    status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, passwordKey, 32, NULL, checkData, 63, encryptedBytes, 64, &encryptedSize);
    
    // now encrypt file data
    if (status == kCCSuccess) {
        status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, passwordKey, 32, NULL, clearBytes, (unsigned int)[data length], encryptedBytes + 64, (unsigned int)[data length] + 16, &encryptedSize);
    }
    
    if (status != kCCSuccess) {
        NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                        NSLocalizedString(@"AP152", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil,
                        nil);
        NSLog(@"CCCrypt failure: %d", status);
        free(encryptedBytes);
        return nil;
    }
    
    NSData *encryptedData = [NSData dataWithBytes: encryptedBytes length: encryptedSize + 64];
    free(encryptedBytes);

    LOG_LEAVE;

    return encryptedData;
}

- (BOOL)encrypt
{
    LOG_ENTER;

    // read accounts file
    NSData *fileData = [NSData dataWithContentsOfURL: self.accountsURL];
    NSData *encryptedData = [self encryptData:fileData withKey:dataPasswordKey];
    if (encryptedData != nil) {
        // write encrypted content to pecunia data file
        NSURL *targetURL = [pecuniaFileURL URLByAppendingPathComponent: _dataFileCrypted];
        if ([encryptedData writeToURL: targetURL atomically: NO] == NO) {
            NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                            NSLocalizedString(@"AP111", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil,
                            nil,
                            [targetURL path]);
            LOG_LEAVE;
            return NO;
        }
        
        // now remove uncrypted file
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError       *error = nil;
        [fm removeItemAtPath: [accountsURL path] error: &error];
        if (error != nil) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return NO;
        }
    } else {
        LOG_LEAVE;
        return NO;
    }

    LOG_LEAVE;
    return YES;
}

- (BOOL)decrypt
{
    LOG_ENTER;

    BOOL     savePassword = NO;
    NSString *passwd = nil;

    // read encrypted file
    NSURL  *sourceURL = [pecuniaFileURL URLByAppendingPathComponent: _dataFileCrypted];
    NSData *fileData = [NSData dataWithContentsOfURL: sourceURL];
    char   *decryptedBytes = malloc([fileData length]);

    if (passwordKeyValid == NO) {
        PasswordWindow *pwWindow = nil;
        BOOL passwordOk = NO;
        passwd = [Keychain passwordForService: @"Pecunia" account: @"DataFile"];
        if(passwd == nil) {
            pwWindow = [[PasswordWindow alloc] initWithText: NSLocalizedString(@"AP163", nil)
                                                      title: NSLocalizedString(@"AP162", nil)];
        }
        
        while (passwordOk == NO) {
            if (pwWindow != nil && passwd == nil) {
                int res = [NSApp runModalForWindow: [pwWindow window]];
                if(res) [NSApp terminate: self];
                
                passwd = [pwWindow result];
                savePassword = [pwWindow shouldSavePassword];
            }
            
            // first get key from password
            NSData *data = [passwd dataUsingEncoding:NSUTF8StringEncoding];
            CC_SHA256([data bytes], (unsigned int)[data length], dataPasswordKey);
            passwordKeyValid = YES;
            
            // check if password is correct, first decrypt check data
            CCCryptorStatus status;
            size_t decryptedSize;
            status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, dataPasswordKey, 32, NULL, [fileData bytes], 64, decryptedBytes, 64, &decryptedSize);
            if (status != kCCSuccess) {
                NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                                NSLocalizedString(@"AP153", nil),
                                NSLocalizedString(@"AP1", nil),
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
                if (dataPasswordKey[i] != decryptedBytes[2*i]) {
                    // password is wrong
                    passwordOk = NO;
                    [pwWindow retry];
                    break;
                }
            }
            if (passwordOk == NO) {
                passwd = nil;
                if (pwWindow == nil) {
                    pwWindow = [[PasswordWindow alloc] initWithText: NSLocalizedString(@"AP163", nil)
                                                              title: NSLocalizedString(@"AP162", nil)];
                }
            }
        } // while
        [pwWindow closeWindow];
    }

    // now decrypt
    CCCryptorStatus status;
    size_t          decryptedSize;
    char            *encryptedBytes = (char *)[fileData bytes];
    status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, dataPasswordKey, 32, NULL, encryptedBytes + 64, (unsigned int)[fileData length] - 64, decryptedBytes, (unsigned int)[fileData length] - 64, &decryptedSize);

    if (status != kCCSuccess) {
        NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                        NSLocalizedString(@"AP153", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil,
                        nil);
        NSLog(@"CCCrypt failure: %d", status);
        free(decryptedBytes);
        return NO;
    }

    NSData *decryptedData = [NSData dataWithBytes: decryptedBytes length: decryptedSize];
    free(decryptedBytes);
    if ([decryptedData writeToURL: accountsURL atomically: NO] == NO) {
        NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                        NSLocalizedString(@"AP111", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil,
                        nil,
                        [accountsURL path]);
        return NO;
    }

    // if everything was successful, we can save the password
    if (savePassword && passwd != nil) {
        [Keychain setPassword: passwd forService: @"Pecunia" account: @"DataFile" store: savePassword];
    }

    decryptionDone = YES;

    LOG_LEAVE;
    return YES;
}

- (BOOL)encryptDataWithPassword: (NSString *)password
{
    LOG_ENTER;

    // first get key from password
    NSData *data = [password dataUsingEncoding: NSUTF8StringEncoding];
    CC_SHA256([data bytes], (unsigned int)[data length], dataPasswordKey);

    if ([self encrypt] == NO) {
        return NO;
    }
    passwordKeyValid = YES;
    isEncrypted = YES;

    self.accountsURL = [[NSURL fileURLWithPath: tempDir] URLByAppendingPathComponent: _dataFileStandard];
    [self decrypt];

    // set coordinator and stores
    NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator];
    NSArray                      *stores = [coord persistentStores];
    NSPersistentStore            *store;
    for (store in stores) {
        [coord setURL: accountsURL forPersistentStore: store];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dataFileEncryptionChanged" object:self];

    LOG_LEAVE;
    return YES;
}

- (BOOL)changePassword: (NSString*)password
{
    LOG_ENTER;

    unsigned char newPasswordKey[32];
    
    // first get new key from new password
    NSData *data = [password dataUsingEncoding: NSUTF8StringEncoding];
    CC_SHA256([data bytes], (unsigned int)[data length], newPasswordKey);
    
    // read accounts file
    NSData *fileData = [NSData dataWithContentsOfURL: self.accountsURL];
    NSData *encryptedData = [self encryptData:fileData withKey:newPasswordKey];
    if (encryptedData != nil) {
        // write encrypted content to pecunia data file
        NSURL *targetURL = [pecuniaFileURL URLByAppendingPathComponent: _dataFileCrypted];
        if ([encryptedData writeToURL: targetURL atomically: NO] == NO) {
            NSRunAlertPanel(NSLocalizedString(@"AP167", nil),
                            NSLocalizedString(@"AP111", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil,
                            nil,
                            [targetURL path]);
            return NO;
        }
    } else {
        return NO;
    }
    memcpy(dataPasswordKey, newPasswordKey, 32);

    LOG_LEAVE;
    return YES;
}

- (BOOL)stopEncryption
{
    LOG_ENTER;

    if (!isEncrypted) {
        LOG_LEAVE;
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError       *error = nil;

    // move unencrypted file
    NSURL *targetURL = [pecuniaFileURL URLByAppendingPathComponent: _dataFileStandard];
    [fm moveItemAtPath: [accountsURL path] toPath: [targetURL path] error: &error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return NO;
    }

    self.accountsURL = targetURL;
    isEncrypted = NO;

    // remove encrypted file
    targetURL = [pecuniaFileURL URLByAppendingPathComponent: _dataFileCrypted];
    [fm removeItemAtPath: [targetURL path] error: &error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }

    // set coordinator and stores
    NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator];
    NSArray                      *stores = [coord persistentStores];
    NSPersistentStore            *store;
    for (store in stores) {
        [coord setURL: accountsURL forPersistentStore: store];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dataFileEncryptionChanged" object:self];

    LOG_LEAVE;
    return YES;
}

/**
 * Clears the entire data in the context. Same as if you just remove the sqlite file manually, but
 * you can immediately start adding new data after return, without restarting the application.
 */
- (void)clearAllData
{
    LOG_ENTER;

    NSURL *storeURL = [[context persistentStoreCoordinator] URLForPersistentStore: [[[context persistentStoreCoordinator] persistentStores] lastObject]];

    // Exclusive access please. Drop pending changes.
    [context lock];

    // Delete the store from the current context.
    NSError *error;
    if ([[context persistentStoreCoordinator] removePersistentStore: [[[context persistentStoreCoordinator] persistentStores] lastObject]
                                                              error: &error]) {
        // Quick and effective: remove the file containing the data.
        [[NSFileManager defaultManager] removeItemAtURL: storeURL error: &error];

        // Now recreate it.
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                                  NSInferMappingModelAutomaticallyOption: @YES};
        [[context persistentStoreCoordinator] addPersistentStoreWithType: NSSQLiteStoreType
                                                           configuration: nil
                                                                     URL: storeURL
                                                                 options: options
                                                                   error: &error];
    }
    [context unlock];
    if (error != nil || ![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }

    LOG_LEAVE;
}

- (void)loadModel
{
    LOG_ENTER;

    NSURL *momURL = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"Accounts" ofType: @"momd"]];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL: momURL];

    LOG_LEAVE;
}

- (void)loadContext
{
    LOG_ENTER;

    NSError *error = nil;

    if (model == nil) {
        [self loadModel];
    }
    if (accountsURL == nil) {
        LOG_LEAVE;
        return;
    }
    if (isEncrypted && decryptionDone == NO) {
        LOG_LEAVE;
        return;
    }

    NSDictionary        *pragmaOptions = nil;
    NSMutableDictionary *storeOptions = [NSMutableDictionary dictionary];
    [storeOptions setDictionary: @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                                   NSInferMappingModelAutomaticallyOption: @YES}];
    if (isEncrypted) {
        pragmaOptions = @{@"synchronous": @"NORMAL", @"fullfsync": @"1"};
        storeOptions[NSSQLitePragmasOption] = pragmaOptions;
    }

    NSPersistentStoreCoordinator *coord = nil;

    if (context != nil && [context persistentStoreCoordinator] != nil) {
        coord = [context persistentStoreCoordinator];
    } else {
        coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
        if (context != nil) {
            [context setPersistentStoreCoordinator:coord];
        }
    }

    [coord addPersistentStoreWithType: NSSQLiteStoreType
                        configuration: nil
                                  URL: accountsURL
                              options: storeOptions
                                error: &error];


    if (error != nil) {
        @throw error;
    }

    if (context == nil) {
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator: coord];
    }

    LOG_LEAVE;
}

- (NSManagedObjectContext *)memContext
{
    LOG_ENTER;

    NSError *error = nil;
    if (memContext) {
        return memContext;
    }
    if (model == nil) {
        return nil;
    }

    NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];

    [coord addPersistentStoreWithType: NSInMemoryStoreType configuration: nil URL: nil options: nil error: &error];
    if (error != nil) {
        @throw error;
    }
    memContext = [[NSManagedObjectContext alloc] init];
    [memContext setPersistentStoreCoordinator: coord];

    LOG_LEAVE;
    return memContext;
}

- (void)relocateToURL: (NSURL *)newFilePathURL
{
    LOG_ENTER;

    // check if it is already
    if ([newFilePathURL isEqual: dataDirURL]) {
        LOG_LEAVE;
        return;
    }

    NSFileManager  *fm = [NSFileManager defaultManager];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSError        *error = nil;

    NSString *newFilename = [newFilePathURL lastPathComponent];
    NSURL    *newDataDirURL = [newFilePathURL URLByDeletingLastPathComponent];

    // first check if data file already exists at target position
    if ([fm fileExistsAtPath: [newFilePathURL path]]) {
        int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP6", nil),
                                          NSLocalizedString(@"AP164", nil),
                                          NSLocalizedString(@"AP2", nil),
                                          NSLocalizedString(@"AP15", nil),
                                          NSLocalizedString(@"AP14", nil),
                                          [newFilePathURL path]
                                          );

        if (res == NSAlertDefaultReturn) {
            LOG_LEAVE;
            return;
        }
        if (res == NSAlertAlternateReturn) {
            // remove existing file
            [fm removeItemAtPath: [newFilePathURL path] error: &error];
            if (error != nil) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                LOG_LEAVE;
                return;
            }
        }

        if (res == NSAlertOtherReturn) {
            [self useExistingDataFile: newFilePathURL];
            LOG_LEAVE;
            return;
        }
    }

    // check if the new data path is the default data path
    isDefaultDir = [self checkIsDefaultDataDir:newDataDirURL];

    // move pecunia file with all included files
    [fm moveItemAtPath: [pecuniaFileURL path] toPath: [newFilePathURL path] error: &error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    // set file and directory variables
    self.dataDirURL = newDataDirURL;
    self.dataFilename = newFilename;
    self.pecuniaFileURL = newFilePathURL;

    // get SCB
    if (isDefaultDir == NO) {
        NSData *bookmark = [self.pecuniaFileURL bookmarkDataWithOptions: NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys: nil relativeToURL: nil error: &error];
        if (error != nil) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
        } else {
            [defaults setValue: bookmark forKey: @"accountsBookmark"];
        }
    }

    [self updateDefaults];

    if (isEncrypted == NO) {
        self.accountsURL = [self.pecuniaFileURL URLByAppendingPathComponent: _dataFileStandard];

        // set coordinator and stores
        NSPersistentStoreCoordinator *coord = [context persistentStoreCoordinator];
        NSArray                      *stores = [coord persistentStores];
        NSPersistentStore            *store;
        for (store in stores) {
            [coord setURL: self.accountsURL forPersistentStore: store];
        }
    }

    LOG_LEAVE;
}

- (void)relocate
{
    LOG_ENTER;

    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue: self.dataFilename];
    [panel setCanCreateDirectories: YES];
    [panel setAllowedFileTypes: @[@"pecuniadata"]];
    if (isDefaultDir == NO) {
        [panel setDirectoryURL: self.dataDirURL];
    }

    NSInteger result = [panel runModal];
    if (result == NSFileHandlingPanelCancelButton) {
        return;
    }

    [self relocateToURL: [panel URL]];

    LOG_LEAVE;
}

- (void)useExistingDataFile:(NSURL*)url
{
    LOG_ENTER;

    if (url == nil) {
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setCanCreateDirectories: YES];
        [panel setAllowedFileTypes: @[@"pecuniadata"]];
        
        NSInteger result = [panel runModal];
        if (result == NSFileHandlingPanelCancelButton) {
            LOG_LEAVE;
            return;
        }
        url = panel.URLs[0];
    }

    // first savely close existing File
    NSError *error = nil;
    [context save: &error];
    if (error != nil) {
        NSLog(@"Pecunia save error: %@", error.localizedDescription);
        LOG_LEAVE;
        return;
    }
    
    // write new defaults and restart
    BOOL defaultDir = [self checkIsDefaultDataDir:[url URLByDeletingLastPathComponent]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue: [url lastPathComponent] forKey: dataFilenameKey];
    if (defaultDir == NO) {
        [defaults setValue: [[[url URLByDeletingLastPathComponent] path] stringByReplacingOccurrencesOfString: @"file://localhost" withString: @""] forKey: dataDirKey];
    } else {
        [defaults setValue: nil forKey: dataDirKey];
    }
    
    if (!isDefaultDir) {
        // save SSB
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *bookmark = [url bookmarkDataWithOptions: NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys: nil relativeToURL: nil error: &error];
        if (error != nil) {
            [NSAlert alertWithError:error];
            [NSApp terminate:self];
            return;
        } else {
            [defaults setValue: bookmark forKey: @"accountsBookmark"];
        }
    }
    
    [defaults synchronize];
   
    [[BankingController controller] setRestart];

    LOG_LEAVE;
    [NSApp terminate:self];
    
}

- (void)relocateToStandard
{
    LOG_ENTER;

    NSString *defaultDataDir = [lDir stringByExpandingTildeInPath];
    NSURL    *dataURL = [NSURL fileURLWithPath: defaultDataDir isDirectory: YES];
    NSURL    *dataFileURL = [dataURL URLByAppendingPathComponent: @"accounts.pecuniadata"];

    [self relocateToURL: dataFileURL];

    LOG_LEAVE;
}

- (BOOL)checkDataPassword: (NSString *)password
{
    LOG_ENTER;

    unsigned char key[32];

    NSData *data = [password dataUsingEncoding: NSUTF8StringEncoding];
    CC_SHA256([data bytes], (unsigned int)[data length], key);

    LOG_LEAVE;
    return memcmp(key, dataPasswordKey, 32) == 0;
}

- (NSManagedObjectContext *)context
{
    if (context == nil) {
        [self loadContext];
    }
    return context;
}

- (NSManagedObjectModel *)model
{
    if (model == nil) {
        [self loadModel];
    }
    return model;
}

+ (MOAssistant *)assistant
{
    if (assistant) {
        return assistant;
    }
    assistant = [[MOAssistant alloc] init];
    return assistant;
}

@end
