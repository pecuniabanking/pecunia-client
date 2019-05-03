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
        
        var values:Dictionary<String,Any> = ["KTV.number":account.number, "KTV.KIK.country":"280", "KTV.KIK.blz":account.bankCode, "cc_number":account.number];
        if account.subNumber != nil {
            values["KTV.subnumber"] = account.subNumber!
        }
        if !segment.setElementValues(values) {
            logError(self.name + ": Parameter konnten nicht gesetzt werden");
            return false;
        }
        
        // add to message
        msg.addOrder(self);
        return true;
    }
    
    override func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        let ccList = CCSettlementList();
        ccList.ccNumber = account.number;
        var ccInfos = [CCSettlementInfo]();
        for seg in resultSegments {
            let degs = seg.elementsForPath("info");
            for deg in degs {
                let info = CCSettlementInfo();
                info.settleID = deg.elementValueForPath("settleID") as? String;
                info.received = NSNumber(value: (deg.elementValueForPath("received") as? Bool) ?? false );
                if seg.version == 3 {
                    info.settleDate = deg.elementValueForPath("settleDate") as? Date;
                    info.firstReceive = deg.elementValueForPath("firstReceive") as? Date;
                    
                    if let elem = deg.elementForPath("value") {
                        if let val = HBCIValue(element: elem) {
                            info.value = val.value;
                            info.currency = val.currency;
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
