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

@class LockViewController;

@interface MOAssistant : NSObject

@property (nonatomic, copy) NSString *passportDirectory;
@property (nonatomic, copy) NSString *importerDir;
@property (nonatomic, copy) NSString *resourcesDir;

@property (nonatomic, copy) NSURL    *pecuniaFileURL; // Location (directory) of the persistent store file.

@property (nonatomic, copy) NSURL    *dataDirURL;
@property (nonatomic, copy) NSString *dataFilename;

@property (nonatomic, assign) NSWindow *mainWindow; // Just a weak reference to our application window.
@property (nonatomic, assign, readonly) BOOL isMaxIdleTimeExceeded;

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSManagedObjectModel   *model;
@property (nonatomic, strong) NSManagedObjectContext *memContext;

@property (nonatomic, assign) BOOL isEncrypted;

+ (MOAssistant *)sharedAssistant;

- (void)clearAllData;
- (void)loadModel;
- (void)relocate;
- (void)relocateToStandard;
- (void)useExistingDataFile:(NSURL *)url;
- (BOOL)decrypt;
- (void)shutdown;
- (BOOL)encryptDataWithPassword: (NSString *)password;
- (BOOL)stopEncryption;
- (BOOL)checkDataPassword: (NSString *)password;
- (BOOL)changePassword: (NSString*)password;
- (void)checkPaths;
- (void)initDatafile: (NSString *)path;

@end
