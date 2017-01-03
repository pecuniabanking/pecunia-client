/**
 * Copyright (c) 2015, 2016, Pecunia Project. All rights reserved.
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
import Cocoa
import HBCI4Swift

// RequestController is called when
// -no card inserted
// -wrong card inserted

class ChipcardRequestController : NSWindowController {
    @IBOutlet var messageField:NSTextField!;
    var _userIdName:String?;
    var _timer: NSTimer?;
    var card: HBCISmartcardDDV!;
    var connectResult = HBCISmartcard.ConnectResult.no_card;
    
    override func awakeFromNib() {
        if let name = self._userIdName {
            messageField.stringValue = String(format: NSLocalizedString("AP350", comment: ""), name);
        } else {
            messageField.stringValue = NSLocalizedString("AP361", comment: "");
        }
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("checkCard:"), userInfo: nil, repeats: true);
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSModalPanelRunLoopMode);
        _timer = timer;
    }
    
    func checkCard(timer:NSTimer) {
        if card == nil {
            card = ChipcardManager.manager.card;
        }
        connectResult = card.connect(1);
        
        if connectResult == .connected ||
            connectResult == .reconnected ||
            connectResult != HBCISmartcard.ConnectResult.no_card {
            // exit from dialog
            timer.invalidate();
            self.close();
            if connectResult == HBCISmartcard.ConnectResult.connected ||
               connectResult == HBCISmartcard.ConnectResult.reconnected {
                NSApp.stopModalWithCode(0);
            } else {
                NSApp.stopModalWithCode(1);
            }
            return;
        }
    }
    
    @IBAction override func cancelOperation(sender: AnyObject?) {
        if let timer = _timer {
            timer.invalidate();
        }
        self.close();
        NSApp.stopModalWithCode(1);
    }
    
}
