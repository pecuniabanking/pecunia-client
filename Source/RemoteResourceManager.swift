/**
 * Copyright (c) 2014, 2015, Pecunia Project. All rights reserved.
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

let RemoteResourcePath = "http://www.pecuniabanking.de/downloads/resources/"
let RemoteResourceUpdateInfo = "http://www.pecuniabanking.de/downloads/resources/updateInfo.xml"

@objc public class RemoteResourceManager : NSObject {
    private let mandatoryFiles = ["eu_all_mfi.zip", "bank_codes.zip", "fints_institute.zip", "mappings.zip"];
    private var downloadableFiles : Array<Dictionary<String, String>>?

    static var instance_token : dispatch_once_t = 0;
    static var singleton : RemoteResourceManager? = nil;

    override init() {
        super.init();

        // Trigger updating files in the background.
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queue) {
            objc_sync_enter(self);

            let url : NSURL? = NSURL(string: RemoteResourceUpdateInfo);
            let xmlData : NSData? = NSData(contentsOfURL: url!);
            if xmlData != nil {
	            do {
	                let updateInfo : NSDictionary = try NSDictionary.dictForXMLData(xmlData);
	                let filesEntry = updateInfo["files"] as? NSDictionary;
	                if (filesEntry != nil) {
	                    self.downloadableFiles = filesEntry!["file"] as? Array;
	                }

	                // Trigger updating files in the background.
	                dispatch_after(0, dispatch_get_main_queue()) {
	                    self.updateFiles();
	                }
	            }
	            catch {
	                // Currently default and variadic parameters don't work well together.
	                // So we need to help a compiler a bit to pick up the variadics (here for the logError call).
	                logError("Parser error for update info file %@", arguments: RemoteResourceUpdateInfo);
	                return;
	            }
            } else {
                logError("Could not load update info file at %@", arguments: RemoteResourceUpdateInfo);
            }

            objc_sync_exit(self);
        }
    }

    public class var sharedManager: RemoteResourceManager {
        dispatch_once(&instance_token) {
            self.singleton = RemoteResourceManager()
        }
        return singleton!
    }

    public class var pecuniaResourcesUpdatedNotification : String {
        return "PecuniaResourcesUpdatedNotification";
    }

    public func addManagedFile(fileName: String) {
        logEnter();
        
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(backgroundQueue, {
            self.updateFileAndNotify(fileName);
        })

        logLeave();
    }

    public func removeManagedFile(fileName: String) -> Bool {
        logEnter();
        let fm = NSFileManager.defaultManager();
        let assistant = MOAssistant.sharedAssistant();
        let targetPath = assistant.resourcesDir + "/" + fileName;

        if fm.fileExistsAtPath(targetPath) {
            do {
                try fm.removeItemAtPath(targetPath);
            }
            catch let error as NSError {
                NSAlert(error: error).runModal();
                logLeave();
                return false;
            }
        }
        logLeave();
        return true;
    }

    /**
     * Checks if the given file would need an update, which requires that it must be one of
     * the downloadable files (but not necessarily be managed).
     */
    public func fileNeedsUpdate(fileName: String) -> Bool {
        let resourcePath = MOAssistant.sharedAssistant().resourcesDir;
        let fm = NSFileManager.defaultManager();
        let dateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd";

        // Check that the given file is one of the remote files we can download.
        objc_sync_enter(self);

        var fileInfo: Dictionary<String, AnyObject>? = nil;
        if downloadableFiles != nil {
            for info in downloadableFiles! {
                if info["name"] == fileName {
                    fileInfo = info;
                    break;
                }
            }
        }

        objc_sync_exit(self);

        if (fileInfo == nil) {
            return false;
        }

        let targetPath = resourcePath + "/" + fileName;
        if fm.fileExistsAtPath(targetPath) {
            // File exists already. Check if it is older than the last update date.
            do {
                let fileAttrs: NSDictionary = try fm.attributesOfItemAtPath(targetPath);
                var date: NSDate? = fileAttrs.fileModificationDate();
                if (date == nil) {
                    date = fileAttrs.fileCreationDate();
                }
                if date != nil {
                    let fileDate = ShortDate(date: date);
                    if fileInfo!["updated"] != nil {
                        let updateDate = ShortDate(date: dateFormatter.dateFromString(fileInfo!["updated"]! as! String));
                        if updateDate <= fileDate {
                            return false;
                        }
                    }
                }
            }
            catch {
            }
        }
        return true;
    }

    /**
     * Typically triggered in a background thread to check and eventually update the given file from
     * the remote location (if it doesn't exist or is outdated).
     *
     * @param fileName Contains the pure file name without path information.
     * @return true, if the file has been updated.
     */
    private func updateFile(fileName: String) -> Bool {
        let resourcePath = MOAssistant.sharedAssistant().resourcesDir;
        let fm = NSFileManager.defaultManager();
        let dateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd";

        // Check that the given file is one of the remote files we can download.
        objc_sync_enter(self);

        var fileInfo: Dictionary<String, AnyObject>? = nil;
        if downloadableFiles != nil {
            for info in downloadableFiles! {
                if info["name"] == fileName {
                    fileInfo = info;
                    break;
                }
            }
        }

        objc_sync_exit(self);

        if (fileInfo == nil) {
            logWarning("File %@ is not a remote resource file", arguments: fileName);
            return false;
        }

        let targetPath = resourcePath + "/" + fileName;
        if fm.fileExistsAtPath(targetPath) {
            // File exists already. Check if it is older than the last update date.
            do {
                let fileAttrs: NSDictionary = try fm.attributesOfItemAtPath(targetPath);
                var date: NSDate? = fileAttrs.fileModificationDate();
                if (date == nil) {
                    date = fileAttrs.fileCreationDate();
                }
                if date != nil {
                    let fileDate = ShortDate(date: date);
                    if fileInfo!["updated"] != nil {
                        let updateDate = ShortDate(date: dateFormatter.dateFromString(fileInfo!["updated"]! as! String));
                        if updateDate <= fileDate {
                            return false;
                        }
                    }
                }
                try fm.removeItemAtPath(targetPath);
            }
            catch {

            }
        }

        // Copy file from remote location.
        var sourceURL : NSURL = NSURL(string: RemoteResourcePath)!;
        sourceURL = sourceURL.URLByAppendingPathComponent(fileName)!;
        let targetURL = NSURL(fileURLWithPath: targetPath);

        do {
            let fileData: NSData = try NSData(contentsOfURL: sourceURL, options: .DataReadingUncached);
            if !fileData.writeToURL(targetURL, atomically: true) {
                logError("Could not copy remote resource %@", arguments: sourceURL.path!);
                return false;
            }
        }
        catch {
            logError("Could not open remote resource %@", arguments: sourceURL.path!);
            return false;
        }

        return true;
    }

    private func updateFileAndNotify(fileName: String) {
        if updateFile(fileName) {
            let notification = NSNotification(name: RemoteResourceManager.pecuniaResourcesUpdatedNotification,
                object: [fileName]);
            NSNotificationCenter.defaultCenter().postNotification(notification);
        }
    }

    private func updateFiles() {
        logEnter();

        // First check if we already did this today.
        let defaults = NSUserDefaults.standardUserDefaults();
        let lastUpdated = defaults.objectForKey("remoteFilesLastUpdate") as? NSDate;
        var last: ShortDate? = (lastUpdated != nil) ? ShortDate(date: lastUpdated) : nil;
        let today = ShortDate.currentDate();

        // Ignore last update date if any of the mandatory files is missing.
        let fm = NSFileManager.defaultManager();
        for fileName in mandatoryFiles {
            if !fm.fileExistsAtPath(MOAssistant.sharedAssistant().resourcesDir + "/" + fileName) {
                last = nil;
                break;
            }
        }

        if (last == nil) || (last! <= today) {
            var updatedFiles : Array<String> = [];
            do {
                let existingFiles = try fm.contentsOfDirectoryAtPath(MOAssistant.sharedAssistant().resourcesDir);

                let files = existingFiles | mandatoryFiles; // Union of all existing and mandatory files.

                // Find a list of all files with potential updates
                // Ensure all mandatory files exist.
                for fileName in files {
                    if !fileName.hasPrefix(".") && updateFile(fileName) {
                        updatedFiles.append(fileName);
                    }
                }

                defaults.setObject(today.lowDate(), forKey: "remoteFilesLastUpdate");
                if updatedFiles.count > 0 {
                    let notification = NSNotification(name: RemoteResourceManager.pecuniaResourcesUpdatedNotification,
                        object: updatedFiles);
                    NSNotificationCenter.defaultCenter().postNotification(notification);
                }
            }
            catch {
                
            }
        }

        logLeave();
    }
}

