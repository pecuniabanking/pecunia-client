//
//  ChipcardPinRequestController.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 30.12.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

class ChipcardPinRequestController : NSWindowController {
    @IBOutlet var messageField:NSTextField!
    var _userIdName:String?
    var _timer:NSTimer?
    var card:HBCISmartcardDDV!
    var connectResult = HBCISmartcard.ConnectResult.no_card;
    
    override func awakeFromNib() {
        messageField.stringValue = String(format: NSLocalizedString("AP351", comment: ""));
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("checkPin:"), userInfo: nil, repeats: false);
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSModalPanelRunLoopMode);
        _timer = timer;
    }
    
    func checkPin(timer:NSTimer) {
        timer.invalidate();
        if card == nil {
            card = ChipcardManager.manager().card;
        }
        
        if !card.verifyPin() {
            self.close();
            NSApp.stopModalWithCode(1);
        } else {
            self.close();
            NSApp.stopModalWithCode(0);

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
