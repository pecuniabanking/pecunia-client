//
//  CCStatementOrder.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 21.04.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation
import HBCI4Swift

class CCStatementOrder: HBCIOrder {
    let account:HBCIAccount;
    var dateFrom:Date?
    var dateTo:Date?
    var statements:Array<HBCIStatement>?
    
    init?(message: HBCICustomMessage, account:HBCIAccount) {
        self.account = account;
        super.init(name: "CCStatement", message: message);
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
        if let date = dateFrom {
            values["startdate"] = date as AnyObject?;
        }
        if let date = dateTo {
            values["enddate"] = date as AnyObject?;
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
        
        self.statements = [HBCIStatement]();
        for seg in resultSegments {
            let statement = HBCIStatement();
            if let balance_deg = seg.elementForPath("balance") {
                statement.endBalance = HBCIAccountBalance(element: balance_deg);
                statement.localAccountNumber = self.account.number;
                statement.localBankCode = self.account.bankCode;
                statement.accountName = self.account.name;
                statement.localIBAN = self.account.iban;
                statement.localBIC = self.account.bic;
            }
            let stats = seg.elementsForPath("ums");
            var items = Array<HBCIStatementItem>();
            for stat in stats {
                let item = HBCIStatementItem();
                item.ccNumberUms = stat.elementValueForPath("cc_number") as? String;
                item.valutaDate = stat.elementValueForPath("valutaDate") as? NSDate;
                item.docDate = stat.elementValueForPath("docDate") as? NSDate;
                item.date = stat.elementValueForPath("postingDate") as? NSDate;
                
                if let deg = stat.elementForPath("origValue") {
                    if let val = HBCIValue(element: deg) {
                        item.origValue = val.value;
                        item.origCurrency = val.currency;
                    }
                }
                if let deg = stat.elementForPath("value") {
                    if let val = HBCIValue(element: deg) {
                        item.value = val.value;
                        item.currency = val.currency;
                    }
                }
                item.remoteCountry = stat.elementValueForPath("country") as? String;
                item.isSettled = stat.elementValueForPath("settled") as? Bool;
                item.bankReference = stat.elementValueForPath("referebce") as? String;
                item.ccChargeKey = stat.elementValueForPath("chargeKey") as? String;
                item.ccSettlementRef = stat.elementValueForPath("settleRef") as? String;
                item.ccChargeTerminal = stat.elementValueForPath("chargeTerminal") as? String;
                item.ccChargeForeign = stat.elementValueForPath("chargeForeign") as? String;
                
                var purpose = "";
                if let s = stat.elementValueForPath("transaction1") as? String {
                    purpose += s;
                }
                if let s = stat.elementValueForPath("transaction2") as? String {
                    purpose += s;
                }
                if let s = stat.elementValueForPath("transaction3") as? String {
                    purpose += s;
                }
                if let s = stat.elementValueForPath("transaction4") as? String {
                    purpose += s;
                }
                item.purpose = purpose;
                items.append(item);
            }
            statement.items = items;
            self.statements!.append(statement);
        }
    }
    
}
