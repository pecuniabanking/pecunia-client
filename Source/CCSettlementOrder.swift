//
//  CCSettlementOrder.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 16.04.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation
import HBCI4Swift

class CCSettlementOrder : HBCIOrder {
    let account:HBCIAccount;
    let settleID:String;
    var settlement:CreditCardSettlement?
    
    init?(message: HBCICustomMessage, account:HBCIAccount, settleID:String) {
        self.account = account;
        self.settleID = settleID;
        super.init(name: "CCSettlement", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    func enqueue() ->Bool {
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: account.number, subNumber: account.subNumber) {
            logError("Segment \(self.name) wird für Konto \(account.number) nicht unterstützt");
            return false;
        }
        
        var values:Dictionary<String,Any> = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "cc_number":account.number, "settleID":settleID];
        if account.subNumber != nil {
            values["KTV.subnumber"] = account.subNumber!
        }
        if !segment.setElementValues(values) {
            logError(self.name + " values could not be set");
            return false;
        }
        
        // add to message
        msg.addOrder(self);
        return true;
    }
    
    override func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        if !result.isOk() {
            return;
        }
        
        let context = MOAssistant.shared().memContext;
        let settle = NSEntityDescription.insertNewObject(forEntityName: "CreditCardSettlement", into: context!) as! CreditCardSettlement;

        for seg in resultSegments {
            settle.ccNumber = seg.elementValueForPath("cc_number") as? String;
            settle.ccAccount = seg.elementValueForPath("cc_account") as? String;
            settle.settleID = seg.elementValueForPath("settleID") as? String;
            
            if let elem = seg.elementForPath("saldo_start") {
                if let val = HBCIValue(element: elem) {
                    settle.startBalance = val.value;
                    settle.currency = val.currency;
                }
            }
            if let elem = seg.elementForPath("saldo_settle") {
                if let val = HBCIValue(element: elem) {
                    settle.endBalance = val.value;
                    settle.currency = val.currency;
                }
            }
            
            settle.nextSettleDate = seg.elementValueForPath("nextsettledate") as? Date;
            settle.ackCode = seg.elementValueForPath("ackcode") as? Data;
            settle.document = seg.elementValueForPath("document") as? Data;
            
            if let texts = seg.elementValuesForPath("text.line") as? [String] {
                var text = "";
                for s in texts {
                    text = text + s + "\n";
                }
                settle.text = text;
            }
            self.settlement = settle;
        }
    }



}
