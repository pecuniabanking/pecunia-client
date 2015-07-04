//
//  ChipcardRequestController.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 03.07.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation
import Cocoa

// RequestController is called when
// -no card inserted
// -wrong card inserted

class ChipcardRequestController : NSWindowController {
    @IBOutlet var messageField:NSTextField!
    var readerName:NSString!
    var _userId:String?
    var card:HBCISmartcardDDV!
    
    override func awakeFromNib() {
        if let userId = self._userId {
            messageField.stringValue = "Bitte legen Sie die Chipkarte mit der Benutzerkennung " + userId + " ein";
        } else {
            messageField.stringValue = "Bitte legen Sie die Chipkarte ein";
        }
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("checkCard:"), userInfo: nil, repeats: true);
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSModalPanelRunLoopMode);
    }
    
    func checkCard(timer:NSTimer) {
        if card == nil {
            card = HBCISmartcardDDV(readerName: readerName);
        }
        if card.connect(1) {
            if let userId = _userId {
                // check if userId is same as requested
                if let bankData = card.getBankData(0) {
                    if bankData.userId != userId {
                        // wrong card inserted
                        messageField.stringValue = "Diese Chipkarte hat die Benutzerkennung " + bankData.userId + ". Bitte ";
                        card.disconnect();
                        // Bitte richtige Karte einführen
                    } else {
                        // Karte korrekt
                        self.close();
                        NSApp.stopModalWithCode(0);
                    }
                } else {
                    // Bankdaten können nicht gelesen werden
                }
            }
            // Karte erkannt
            self.close();
            NSApp.stopModalWithCode(0);
        }
    }
    
    @IBAction override func cancelOperation(sender: AnyObject?) {
        self.close();
        NSApp.stopModalWithCode(1);
    }
    
}
