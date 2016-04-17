//
//  CCSettlementListOrder.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 12.04.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation
import HBCI4Swift

class CCSettlementListOrder : HBCIOrder {
    let account:HBCIAccount;
    var settlementList:CCSettlementList?
    
    init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "CCSettlementList", message: message);
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
        
        var values:Dictionary<String,AnyObject> = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "cc_number":account.number];
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
    
    override func updateResult(result:HBCIResultMessage) {
        super.updateResult(result);
        
        let ccList = CCSettlementList();
        ccList.ccNumber = account.number;
        var ccInfos = [CCSettlementInfo]();
        for seg in resultSegments {
            let degs = seg.elementsForPath("info");
            for deg in degs {
                let info = CCSettlementInfo();
                info.settleID = deg.elementValueForPath("settleID") as? String;
                info.received = NSNumber(bool: (deg.elementValueForPath("received") as? Bool) ?? false );
                if seg.version == 3 {
                    info.settleDate = deg.elementValueForPath("settleDate") as? NSDate;
                    info.firstReceive = deg.elementValueForPath("firstReceive") as? NSDate;
                    
                    if let debitCredit = deg.elementValueForPath("value.debitcredit") as? String {
                        info.value = deg.elementValueForPath("value.value") as? NSDecimalNumber;
                        info.currency = deg.elementValueForPath("value.curr") as? String;
                        if info.value != nil {
                            if debitCredit == "D" {
                                info.value = NSDecimalNumber.zero().decimalNumberBySubtracting(info.value!);
                            }
                        }
                    }
                }
                ccInfos.append(info);
            }
        }
        ccList.settlementInfos = ccInfos;
        settlementList = ccList;
    }



}