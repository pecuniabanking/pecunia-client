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

import Foundation

let RemoteResourcePath = "http://www.pecuniabanking.de/downloads/resources/"
let RemoteResourceUpdateInfo = "http://www.pecuniabanking.de/downloads/resources/updateInfo.xml"

public class RemoteResourceManager {
    private let defaultFiles : NSArray

    private var fileInfos : NSArray = []

    init() {
        defaultFiles = ["eu_all22.txt.zip"]

        let url : NSURL = NSURL.fileURLWithPath(RemoteResourceUpdateInfo)!
        if let xmlData = NSData(contentsOfURL: url) {
            var error : NSError?;

            var updateInfo : NSDictionary = NSDictionary.dictForXMLData(xmlData, error: &error);
            if (error != nil) {
                //LogError("Parser error for update info file %@", RemoteResourceUpdateInfo);
                return;
            }

            self.fileInfos = updateInfo.valueForKeyPath("files.file") as NSArray;

            // Trigger updating files in the background.
            dispatch_after(0, dispatch_get_main_queue()) {
                self.updateFiles();
            }
        } else {
            //LogError("Could not load update info file at %@", RemoteResourceUpdateInfo);
        }
    }

    private func updateFiles() {

    }
}

