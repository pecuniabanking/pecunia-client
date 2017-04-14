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

@objc open class RemoteResourceManager : NSObject {
    private static var __once: () = {
            RemoteResourceManager.singleton = RemoteResourceManager()
        }()
    fileprivate let mandatoryFiles = ["eu_all_mfi.zip", "bank_codes.zip", "fints_institute.zip", "mappings.zip"];
    fileprivate var downloadableFiles : Array<Dictionary<String, String>>?

    static var instance_token : Int = 0;
    static var singleton : RemoteResourceManager? = nil;

    override init() {
        super.init();

        // Trigger updating files in the background.
        let queue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background);
        queue.async {
            objc_sync_enter(self);

            let url : URL? = URL(string: RemoteResourceUpdateInfo);
            let xmlData : Data? = try? Data(contentsOf: url!);
            if xmlData != nil {
	            do {
	                let updateInfo : NSDictionary = try NSDictionary.dict(forXMLData: xmlData) as NSDictionary;
	                let filesEntry = updateInfo["files"] as? NSDictionary;
	                if (filesEntry != nil) {
	                    self.downloadableFiles = filesEntry!["file"] as? Array;
	                }

	                // Trigger updating files in the background.
	                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 0) ) {
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

    open class var sharedManager: RemoteResourceManager {
        _ = RemoteResourceManager.__once
        return singleton!
    }

    open class var pecuniaResourcesUpdatedNotification : String {
        return "PecuniaResourcesUpdatedNotification";
    }

    open func addManagedFile(_ fileName: String) {
        logEnter();
        
        let backgroundQueue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background);
        backgroundQueue.async(execute: {
            self.updateFileAndNotify(fileName);
        })

        logLeave();
    }

    open func removeManagedFile(_ fileName: String) -> Bool {
        logEnter();
        let fm = FileManager.default;
        let assistant = MOAssistant.shared();
        let targetPath = (assistant?.resourcesDir)! + "/" + fileName;

        if fm.fileExists(atPath: targetPath) {
            do {
                try fm.removeItem(atPath: targetPath);
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
    open func fileNeedsUpdate(_ fileName: String) -> Bool {
        let resourcePath = MOAssistant.shared().resourcesDir;
        let fm = FileManager.default;
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd";

        // Check that the given file is one of the remote files we can download.
        objc_sync_enter(self);

        var fileInfo: Dictionary<String, AnyObject>? = nil;
        if downloadableFiles != nil {
            for info in downloadableFiles! {
                if info["name"] == fileName {
                    fileInfo = info as Dictionary<String, AnyObject>?;
                    break;
                }
            }
        }

        objc_sync_exit(self);

        if (fileInfo == nil) {
            return false;
        }

        let targetPath = resourcePath! + "/" + fileName;
        if fm.fileExists(atPath: targetPath) {
            // File exists already. Check if it is older than the last update date.
            do {
                let fileAttrs: NSDictionary = try fm.attributesOfItem(atPath: targetPath) as NSDictionary;
                var date: Date? = fileAttrs.fileModificationDate();
                if (date == nil) {
                    date = fileAttrs.fileCreationDate();
                }
                if date != nil {
                    let fileDate = ShortDate(date: date);
                    if fileInfo!["updated"] != nil {
                        let updateDate = ShortDate(date: dateFormatter.date(from: fileInfo!["updated"]! as! String));
                        if updateDate! <= fileDate! {
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
    fileprivate func updateFile(_ fileName: String) -> Bool {
        let resourcePath = MOAssistant.shared().resourcesDir;
        let fm = FileManager.default;
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd";

        // Check that the given file is one of the remote files we can download.
        objc_sync_enter(self);

        var fileInfo: Dictionary<String, AnyObject>? = nil;
        if downloadableFiles != nil {
            for info in downloadableFiles! {
                if info["name"] == fileName {
                    fileInfo = info as Dictionary<String, AnyObject>?;
                    break;
                }
            }
        }

        objc_sync_exit(self);

        if (fileInfo == nil) {
            logWarning("File %@ is not a remote resource file", arguments: fileName);
            return false;
        }

        let targetPath = resourcePath! + "/" + fileName;
        if fm.fileExists(atPath: targetPath) {
            // File exists already. Check if it is older than the last update date.
            do {
                let fileAttrs: NSDictionary = try fm.attributesOfItem(atPath: targetPath) as NSDictionary;
                var date: Date? = fileAttrs.fileModificationDate();
                if (date == nil) {
                    date = fileAttrs.fileCreationDate();
                }
                if date != nil {
                    let fileDate = ShortDate(date: date);
                    if fileInfo!["updated"] != nil {
                        let updateDate = ShortDate(date: dateFormatter.date(from: fileInfo!["updated"]! as! String));
                        if updateDate! <= fileDate! {
                            return false;
                        }
                    }
                }
                try fm.removeItem(atPath: targetPath);
            }
            catch {

            }
        }

        // Copy file from remote location.
        var sourceURL : URL = URL(string: RemoteResourcePath)!;
        sourceURL = sourceURL.appendingPathComponent(fileName);
        let targetURL = URL(fileURLWithPath: targetPath);

        do {
            let fileData: Data = try Data(contentsOf: sourceURL, options: .uncached);
            if !((try? fileData.write(to: targetURL, options: [.atomic])) != nil) {
                logError("Could not copy remote resource %@", arguments: sourceURL.path);
                return false;
            }
        }
        catch {
            logError("Could not open remote resource %@", arguments: sourceURL.path);
            return false;
        }

        return true;
    }

    fileprivate func updateFileAndNotify(_ fileName: String) {
        if updateFile(fileName) {
            let notification = Notification(name: Notification.Name(rawValue: RemoteResourceManager.pecuniaResourcesUpdatedNotification),
                object: [fileName]);
            NotificationCenter.default.post(notification);
        }
    }

    fileprivate func updateFiles() {
        logEnter();

        // First check if we already did this today.
        let defaults = UserDefaults.standard;
        let lastUpdated = defaults.object(forKey: "remoteFilesLastUpdate") as? Date;
        var last: ShortDate? = (lastUpdated != nil) ? ShortDate(date: lastUpdated) : nil;
        let today = ShortDate.current();

        // Ignore last update date if any of the mandatory files is missing.
        let fm = FileManager.default;
        for fileName in mandatoryFiles {
            if !fm.fileExists(atPath: MOAssistant.shared().resourcesDir + "/" + fileName) {
                last = nil;
                break;
            }
        }

        if (last == nil) || (last! < today!) {
            var updatedFiles : Array<String> = [];
            do {
                let existingFiles = try fm.contentsOfDirectory(atPath: MOAssistant.shared().resourcesDir);

                let files = existingFiles | mandatoryFiles; // Union of all existing and mandatory files.

                // Find a list of all files with potential updates
                // Ensure all mandatory files exist.
                for fileName in files {
                    if !fileName.hasPrefix(".") && updateFile(fileName) {
                        updatedFiles.append(fileName);
                    }
                }

                defaults.set(today?.lowDate(), forKey: "remoteFilesLastUpdate");
                if updatedFiles.count > 0 {
                    let notification = Notification(name: Notification.Name(rawValue: RemoteResourceManager.pecuniaResourcesUpdatedNotification),
                        object: updatedFiles);
                    NotificationCenter.default.post(notification);
                }
            }
            catch {
                
            }
        }

        logLeave();
    }
}

