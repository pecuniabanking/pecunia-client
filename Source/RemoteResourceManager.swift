/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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
let PecuniaResourcesUpdatedNotification = "PecuniaResourcesUpdatedNotification"

@objc public class RemoteResourceManager : NSObject {
    private let mandatoryFiles = ["eu_all22.txt.zip"];
    private var downloadableFiles : Array<Dictionary<String, String>>?

    private struct Static {
        static var instance_token : dispatch_once_t = 0;
        static var singleton : RemoteResourceManager?;
    }

    override init() {
        assert(Static.singleton == nil, "Singleton already initialized!");

        super.init();

        let url : NSURL? = NSURL(string: RemoteResourceUpdateInfo);
        let xmlData : NSData? = NSData(contentsOfURL: url!);
        if xmlData != nil {
            var error : NSError?;

            var updateInfo : NSDictionary = NSDictionary.dictForXMLData(xmlData, error: &error);
            if (error != nil) {
                // Currently default and variadic parameters don't work well together.
                // So we need to help a compiler a bit to pick up the variadics (here for the logError call).
                logError("Parser error for update info file %@", arguments: RemoteResourceUpdateInfo);
                return;
            }

            let filesEntry = updateInfo["files"] as? NSDictionary;
            if (filesEntry != nil) {
                downloadableFiles = filesEntry!["file"] as? Array;
            }

            // Trigger updating files in the background.
            dispatch_after(0, dispatch_get_main_queue()) {
                self.updateFiles();
            }
        } else {
            logError("Could not load update info file at %@", arguments: RemoteResourceUpdateInfo);
        }
    }

    public class var manager: RemoteResourceManager {
        dispatch_once(&Static.instance_token) {
            Static.singleton = RemoteResourceManager()
        }
        return Static.singleton!
    }

    public func addManagedFile(fileName: String) {
        logEnter();
        let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
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

        var error : NSError?;
        fm.removeItemAtPath(targetPath, error: &error);
        if error != nil {
            NSAlert(error: error!).runModal();
            logLeave();
            return false;
        }
        logLeave();
        return true;
    }
    
    /**
    * Typically triggered in a background thread to check and eventually update the given file from
    * the remote location (if it doesn't exist or is outdated).
    *
    * @param fileName Contains the pure file name without path information.
    * @return true, if the file is up-to-date or could be updated successfully.
    */
    private func updateFile(fileName: String) -> Bool {
        let resourcePath = MOAssistant.sharedAssistant().resourcesDir;
        let fm = NSFileManager.defaultManager();
        var dateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd";

        // Check that the given file is one of the remote files we can download.
        var fileInfo: Dictionary<String, AnyObject>? = nil;
        if downloadableFiles != nil {
            for info in downloadableFiles! {
                if info["name"] == fileName {
                    fileInfo = info;
                    break;
                }
            }
        }

        if (fileInfo == nil) {
            return false;
        }

        if fileInfo!["name"] as String != fileName {
            logWarning("File %@ is not a remote resource file", arguments: fileName);
            return false;
        }

        let targetPath = resourcePath + "/" + fileName;
        if fm.fileExistsAtPath(targetPath) {
            // File exists already. Check if it is older than the last update date.
            var error: NSError?;
            var fileAttrs: NSDictionary? = fm.attributesOfItemAtPath(targetPath, error: &error);
            if fileAttrs != nil {
                var date: NSDate? = fileAttrs!.fileModificationDate();
                if (date == nil) {
                    date = fileAttrs!.fileCreationDate();
                }
                if date != nil {
                    let fileDate = ShortDate(date: date);
                    if fileInfo!["updated"] != nil {
                        let updateDate = ShortDate(date: dateFormatter.dateFromString(fileInfo!["updated"]! as String));
                        if updateDate <= fileDate {
                            return true;
                        }
                    }
                }
            }
            fm.removeItemAtPath(targetPath, error: &error);
        }

        // Copy file from remote location.
        var sourceURL : NSURL = NSURL(string: RemoteResourcePath)!;
        sourceURL = sourceURL.URLByAppendingPathComponent(fileName);
        let targetURL = NSURL(fileURLWithPath: targetPath);

        var error: NSError?;
        let fileData: NSData? = NSData(contentsOfURL: sourceURL, options: NSDataReadingOptions.DataReadingUncached, error: &error);
        if error != nil {
            logError("Could not open remote resource %@", arguments: sourceURL.path!);
            return false;
        }

        if fileData != nil {
            if !fileData!.writeToURL(targetURL!, atomically: true) {
                logError("Could not copy remote resource %@", arguments: sourceURL.path!);
                return false;
            }
        }
        
        return true;
    }

    private func updateFileAndNotify(fileName: String) {
        let result = updateFile(fileName);
        let notification = NSNotification(name: PecuniaResourcesUpdatedNotification, object: NSNumber(bool: result));
        NSNotificationCenter.defaultCenter().postNotification(notification);
    }

    private func updateFiles() {
        logEnter();

        // first check if we already did this today
        var error: NSError?;
        let defaults = NSUserDefaults.standardUserDefaults();
        let lastUpdated = defaults.objectForKey("remoteFilesLastUpdate") as NSDate?;
        let last: ShortDate? = nil //(lastUpdated != nil) ? ShortDate(date: lastUpdated!) : nil;
        let today = ShortDate.currentDate();

        if (last == nil) || (last! < today) {
            let fm = NSFileManager.defaultManager();
            var files: Array<String>? = fm.contentsOfDirectoryAtPath(MOAssistant.sharedAssistant().resourcesDir,
                                            error: &error) as? Array<String>;

            // Ensure all mandatory files exist.
            for fileName in mandatoryFiles {
                if let index = find(files!, fileName) {
                    files?.removeAtIndex(index);
                    updateFile(fileName);
                }
            }

            // Now update all remaining files.
            for fileName in files! {
                updateFile(fileName as String);
            }

            defaults.setObject(today.lowDate(), forKey: "remoteFilesLastUpdate");
            let notification = NSNotification(name: PecuniaResourcesUpdatedNotification, object: nil);
            NSNotificationCenter.defaultCenter().postNotification(notification);
        }

        logLeave();
    }
}

