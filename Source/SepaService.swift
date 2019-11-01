//
//  SepaService.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 27.10.19.
//  Copyright © 2019 Frank Emminghaus. All rights reserved.
//

import Foundation

class SepaService : NSObject {
    @objc class func isValidIBAN(_ iban: String?) -> Bool {
        return IBANtools.isValidIBAN(iban);
    }
    @objc class func isValidBIC(_ bic: String?) -> Bool {
        return IBANtools.isValidBIC(bic);
    }
    @objc class func isValidAccount(_ account: String, bankCode: String, countryCode: String, forIBAN: Bool) -> Dictionary<String, AnyObject> {
        return IBANtools.isValidAccount(account, bankCode: bankCode, countryCode: countryCode, forIBAN: forIBAN);
    }
    @objc class func convertToIBAN(_ account: String, bankCode: String, countryCode: String, validateAccount: Bool) -> Dictionary<String, AnyObject> {
        return IBANtools.convertToIBAN(account, bankCode: bankCode, countryCode: countryCode, validateAccount: validateAccount);
    }
}

class BankInfo: NSObject {
    @objc open var bic: String = "";
    @objc open var bankCode: Int = 0;
    @objc open var countryCode: String = "";
    @objc open var name: String = "";
    @objc open var hbciVersion: String = "";   // for DDV + RDH
    @objc open var pinTanVersion: String = ""; // for HBCI Pin/Tan + RDH
    @objc open var hostURL: String = "";       // host URL for DDV + RDH
    @objc open var pinTanURL: String = "";
    
    init?(_ info: InstituteInfo?) {
        guard let info = info else {
            return nil;
        }
        self.bic = info.bic;
        self.bankCode = info.bankCode;
        self.countryCode = info.countryCode;
        self.name = info.name;
        self.hbciVersion = info.hbciVersion;
        self.pinTanVersion = info.pinTanVersion;
        self.hbciVersion = info.hbciVersion;
        self.hostURL = info.hostURL;
        self.pinTanURL = info.pinTanURL;
    }
}

