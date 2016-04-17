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
            logError(self.name + " is not supported for account " + account.number);
            return false;
        }
        
        var values:Dictionary<String,AnyObject> = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "cc_number":account.number, "settleID":settleID];
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
    
    func getBalance(elem:HBCISyntaxElement) ->(value:NSDecimalNumber, currency:String)? {
        if let debitCredit = elem.elementValueForPath("debitcredit") as? String {
            if let currency = elem.elementValueForPath("currency") as? String {
                if var value = elem.elementValueForPath("value") as? NSDecimalNumber {
                    if debitCredit == "D" {
                        value = NSDecimalNumber.zero().decimalNumberBySubtracting(value);
                    }
                    return (value, currency);
                }
            }
        }
        return nil;
    }

    
    override func updateResult(result:HBCIResultMessage) {
        super.updateResult(result);
        
        if !result.isOk() {
            return;
        }
        
        let context = MOAssistant.sharedAssistant().memContext;
        let settle = NSEntityDescription.insertNewObjectForEntityForName("CreditCardSettlement", inManagedObjectContext: context) as! CreditCardSettlement;

        for seg in resultSegments {
            settle.ccNumber = seg.elementValueForPath("cc_number") as? String;
            settle.ccAccount = seg.elementValueForPath("cc_account") as? String;
            settle.settleID = seg.elementValueForPath("settleID") as? String;
            
            if let elem = seg.elementForPath("saldo_start") {
                if let (value, currency) = self.getBalance(elem) {
                    settle.startBalance = value;
                    settle.currency = currency;
                }
            }
            if let elem = seg.elementForPath("saldo_settle") {
                if let (value, currency) = self.getBalance(elem) {
                    settle.endBalance = value;
                    settle.currency = currency;
                }
            }
            
            settle.nextSettleDate = seg.elementValueForPath("nextsettledate") as? NSDate;
            settle.ackCode = seg.elementValueForPath("ackcode") as? NSData;
            settle.document = seg.elementValueForPath("document") as? NSData;
            
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