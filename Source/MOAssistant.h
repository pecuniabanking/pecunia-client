/**
 * Copyright (c) 2011, 2014, Pecunia Project. All rights reserved.
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

#import <Cocoa/Cocoa.h>

@class LockViewController;

@interface MOAssistant : NSObject {
    NSManagedObjectContext *context;
    NSManagedObjectContext *memContext;
    NSManagedObjectModel   *model;

    // Location (external/internal) of data file (directory & filename)
    NSURL    *dataDirURL;
    NSString *dataFilename;

    // location (directory) of persistent store file
    NSURL *pecuniaFileURL;

    // resulting URL to use for persistent store
    NSURL *accountsURL;

    // passport directory
    NSString *ppDir;

    // import settings directory
    NSString *importerDir;
    
    // resources directory
    NSString *resourcesDir;

    // temporary directory
    NSString *tempDir;

    // Idle timer to lock application/encrypted data file.
    NSTimer *idleTimer;

    LockViewController *lockViewController;

    unsigned char dataPasswordKey[32];

    BOOL passwordKeyValid;
    BOOL isEncrypted;
    BOOL decryptionDone;
    BOOL isSandboxed;
    BOOL isDefaultDir;
    BOOL isMaxIdleTimeExceeded;
}

@property (nonatomic, copy) NSString *ppDir;
@property (nonatomic, copy) NSString *importerDir;
@property (nonatomic, copy) NSString *resourcesDir;
@property (nonatomic, copy) NSString *tempDir;
@property (nonatomic, copy) NSString *dataFilename;
@property (nonatomic, strong) NSURL  *accountsURL;
@property (nonatomic, strong) NSURL  *dataDirURL;
@property (nonatomic, strong) NSURL  *pecuniaFileURL;

@property (nonatomic, assign) NSWindow *mainWindow; // Just a weak reference to our application window.
@property (nonatomic, assign, readonly) BOOL isMaxIdleTimeExceeded;

- (void)clearAllData;
- (void)loadModel;
- (void)relocate;
- (void)relocateToStandard;
- (void)useExistingDataFile:(NSURL *)url;
- (BOOL)decrypt;
- (void)shutdown;
- (BOOL)encrypted;
- (BOOL)encryptDataWithPassword: (NSString *)password;
- (BOOL)stopEncryption;
- (BOOL)checkDataPassword: (NSString *)password;
- (BOOL)changePassword: (NSString*)password;
- (void)checkPaths;
- (void)checkSandboxed;
- (void)initDatafile: (NSString *)path;

- (NSString *)passportDirectory;

- (NSManagedObjectContext *)context;
- (NSManagedObjectModel *)model;
- (NSManagedObjectContext *)memContext;

+ (MOAssistant *)assistant;

@end
