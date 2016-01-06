/**
 * Copyright (c) 2014, 2016, Pecunia Project. All rights reserved.
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

import Foundation
import CoreData

// Number of entries in one batch of a dispatch_apply invocation.
let wordsLoadStride : Int = 50000;

@objc public class WordMapping: NSManagedObject {

    @NSManaged var wordKey: String
    @NSManaged var translated: String

    static private var mappingsAvailable : Bool?;

    public static let pecuniaWordsLoadedNotification: String = "PecuniaWordsLoadedNotification";

    public class var wordMappingsAvailable : Bool {
        if mappingsAvailable == nil {
            let request = NSFetchRequest();
            request.entity = NSEntityDescription.entityForName("WordMapping",
                inManagedObjectContext: MOAssistant.sharedAssistant().context);
            request.includesSubentities = false;

            let count = MOAssistant.sharedAssistant().context.countForFetchRequest(request, error: nil);
            mappingsAvailable = count > 0;
        }
        return mappingsAvailable!;
    }

    /**
    * Called when a new (or first-time) word list was downloaded and updates the shared data store.
    */
    public class func updateWordMappings() {
        logEnter();

        // First check if there's a word.zip file before removing the existing values.
        let fm = NSFileManager.defaultManager();
        let zipPath = MOAssistant.sharedAssistant().resourcesDir + "/words.zip";
        if !fm.fileExistsAtPath(zipPath) {
            logLeave();
            return;
        }

        // Now we are safe to remove old mappings.
        removeWordMappings();

        logDebug("Loading new word list");
        let startTime = Mathematics.beginTimeMeasure();
        let file : ZipFile = ZipFile(fileName: zipPath, mode: ZipFileModeUnzip);
        let info : FileInZipInfo = file.getCurrentFileInZipInfo();
        if info.length < 100000000 { // Sanity check. Not more than 100MB.
            var buffer = NSMutableData(length: Int(info.length));
            let stream = file.readCurrentFileInZip();
            let length = stream.readDataWithBuffer(buffer);
            if (length == info.length) {
                var text = NSString(data: buffer!, encoding: NSUTF8StringEncoding);
                buffer = nil; // Free buffer to lower mem consuption.
                let lines = text!.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet());
                text = nil;

                // Convert to lower case and decompose diacritics (e.g. umlauts).
                // Split work into blocks of wordsLoadStride size and iterate in parallel over them.
                let lineCount = lines.count;
                var blockCount = lineCount / wordsLoadStride;
                if lineCount % wordsLoadStride != 0 {
                    ++blockCount; // One more (incomplete) block for the remainder.
                }

                // Create an own managed context for each block, so we don't get into concurrency issues.
                dispatch_apply(blockCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { index in

                    // Create a local managed context for this thread.
                    let coordinator = MOAssistant.sharedAssistant().context.persistentStoreCoordinator;
                    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType);
                    context.persistentStoreCoordinator = coordinator;

                    let start = index * wordsLoadStride;
                    var end = start + wordsLoadStride;
                    if (end > lineCount) {
                        end = lineCount;
                    }
                    for (var i = start; i < end; ++i) {
                        let key = lines[Int(i)].stringWithNormalizedGermanChars().lowercaseString;
                        let mapping = NSEntityDescription.insertNewObjectForEntityForName("WordMapping",
                            inManagedObjectContext: context) as! WordMapping;
                        mapping.wordKey = key;
                        mapping.translated = lines[Int(i)] as String;
                    }

                    do {
                        try context.save();
                    }
                    catch let error as NSError {
                        let alert = NSAlert(error: error);
                        alert.runModal();
                    }
                    }
                );
            }

            mappingsAvailable = true;
            let notification = NSNotification(name: pecuniaWordsLoadedNotification, object: nil);
            NSNotificationCenter.defaultCenter().postNotification(notification);
        }

        logDebug("Word list loading done in: %.2fs", arguments: Mathematics.timeDifferenceSince(startTime) / 1000000000);
        logLeave();
    }

    /**
    * Removes all shared word list data (e.g. for updates or if the user decided not to want
    * the overhead anymore.
    */
    public class func removeWordMappings() {
        logDebug("Clearing word list");

        mappingsAvailable = false;
        
        let startTime = Mathematics.beginTimeMeasure();

        let coordinator = MOAssistant.sharedAssistant().context.persistentStoreCoordinator;
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType);
        context.persistentStoreCoordinator = coordinator;

        let allMappings = NSFetchRequest();
        allMappings.entity = NSEntityDescription.entityForName("WordMapping", inManagedObjectContext: context);
        allMappings.includesPropertyValues = false; // Fetch only IDs.

        do {
            let mappings = try context.executeFetchRequest(allMappings);
            for mapping in mappings {
                context.deleteObject(mapping as! WordMapping);
            }
            try context.save();
        }
        catch let error as NSError {
            let alert = NSAlert(error: error);
            alert.runModal();
        }
        logDebug("Word list truncation done in: %.2fs", arguments: Mathematics.timeDifferenceSince(startTime) / 1000000000);
    }
}
