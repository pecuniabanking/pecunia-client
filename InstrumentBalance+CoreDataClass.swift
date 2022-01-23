//
//  InstrumentBalance+CoreDataClass.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 25.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//
//

import Foundation
import CoreData
import HBCI4Swift

@objc(InstrumentBalance)
public class InstrumentBalance: NSManagedObject {
    public class func createWithHBCIData(balance: HBCICustodyAccountBalance.FinancialInstrument.SubBalance, context:NSManagedObjectContext) -> InstrumentBalance
    {
        let result = NSEntityDescription.insertNewObject(forEntityName: "InstrumentBalance", into: context) as! InstrumentBalance;
        result.balance = balance.balance;
        result.isAvailable = NSNumber(value: balance.isAvailable);
        result.numberType = balance.numberType.rawValue;
        result.qualifier = balance.qualifier;
        return result;
    }
    
    public override func value(forKey key: String) -> Any? {
        if key == "qualifierText" {
            switch self.qualifier {
            case "BLOK": return "Blockiert";
            case "BORR": return "Geliehen";
            case "COLI": return "Sicherheit in";
            case "COLO": return "Sicherheit aus";
            case "LOAN": return "Ausgeliehen";
            case "NOMI": return "Im Namen eines Treuhänders";
            case "PECA": return "Schwebende Corporate Action";
            case "PEND": return "Schwebende Lieferung";
            case "PENR": return "Schwebender Eingang";
            case "REGO": return "Herausgegeben zur Registrierung";
            case "RSTR": return "Eingeschränkt";
            case "SPOS": return "Außerbörsliche Position";
            case "TAVI": return "Insgesamt verfügbar";
            case "TRAN": return "In Übertragung";
            default: return "unbekannt";
            }
        }
        return super.value(forKey: key);
    }
        
}
