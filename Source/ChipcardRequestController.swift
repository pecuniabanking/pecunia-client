//
//  ChipcardRequestController.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 03.07.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation
import Cocoa
import HBCI4Swift

// RequestController is called when
// -no card inserted
// -wrong card inserted

class ChipcardRequestController : NSWindowController {
    @IBOutlet var messageField:NSTextField!
    var _userIdName:String?
    var _timer:NSTimer?
    var card:HBCISmartcardDDV!
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
        
        if connectResult == HBCISmartcard.ConnectResult.connected ||
            connectResult == HBCISmartcard.ConnectResult.reconnected ||
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
