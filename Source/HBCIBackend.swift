//
//  HBCIBackend.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 04.12.15.
//  Copyright © 2015 Frank Emminghaus. All rights reserved.
//

import Foundation
import HBCI4Swift


var _backend:HBCIBackend!

public class BackendLog: HBCILog {
    
    public init() {}
    
    public func logError(message: String, file:String, function:String, line:Int) {
        DDLog.doLog(DDLogFlag.Error, message: message, function: function, file: file, line: Int32(line), arguments:[]);
    }
    public func logInfo(message: String, file:String, function:String, line:Int) {
        DDLog.doLog(DDLogFlag.Info, message: message, function: function, file: file, line: Int32(line), arguments:[]);
    }
}

class HBCIBackend : NSObject {
    
    static var backend:HBCIBackend {
        get {
            if _backend == nil {
                _backend = HBCIBackend();
                HBCILogManager.setLog(HBCIConsoleLog());
            }
            return _backend;
        }
    }
    
    func infoForBankCode(bankCode:String) -> InstituteInfo? {
        let (bic, result) = IBANtools.bicForBankCode(bankCode, countryCode: "de");
        if result == .NoBIC || result == .WrongValue {
            return nil;
        }
        return IBANtools.instituteDetailsForBIC(bic);
    }
    
    func getBankNodeWithAccount(account:HBCIAccount) ->BankAccount? {
        let context = MOAssistant.sharedAssistant().context;
        var bankNode = BankAccount.bankRootForCode(account.bankCode);

        if bankNode == nil {
            let root = BankingCategory.bankRoot();
            if root == nil {
                return nil;
            }
            
            // create bank node
            bankNode = NSEntityDescription.insertNewObjectForEntityForName("BankAccount", inManagedObjectContext: context) as! BankAccount;
            //bankNode.name = account.bankName;
            bankNode.bankCode = account.bankCode;
            bankNode.currency = account.currency;
            bankNode.bic = account.bic;
            bankNode.isBankAcc = NSNumber(bool: true);
            bankNode.parent = root;
        }
        return bankNode;
    }
    
    func updateBankAccounts(accounts: Array<HBCIAccount>, user:BankUser) throws {
        let context = MOAssistant.sharedAssistant().context;
        let model = MOAssistant.sharedAssistant().model;
        var found = false;
        
        if let request = model.fetchRequestTemplateForName("allBankAccounts") {
            do {
                var bankAccounts = try context.executeFetchRequest(request) as! [BankAccount];
                
                for account in accounts {
                    found = false;
                    for bankAccount in bankAccounts {
                        if account.bankCode == bankAccount.bankCode && account.number == bankAccount.accountNumber() &&
                            (account.subNumber == nil && bankAccount.accountSuffix == nil || account.subNumber == bankAccount.accountSuffix) {
                                found = true;

                                // update the user if there is none assigned yet
                                let users = bankAccount.mutableSetValueForKey("users");
                                if users.count > 0 {
                                    // there is already another user id assigned...
                                    break;
                                }
                                
                                bankAccount.userId = user.userId;
                                bankAccount.customerId = user.customerId;
                                users.addObject(user);
                                
                                if account.bic != nil {
                                    bankAccount.bic = account.bic;
                                }
                                if account.iban != nil {
                                    bankAccount.iban = account.iban;
                                }
                                if bankAccount.isManual.boolValue == true {
                                    // check if account supports statement transfers
                                    // todo
                                }
                                
                                break;
                        }
                    }
                    if found == false {
                        // bank account was not found - create it
                        
                        guard let bankRoot = getBankNodeWithAccount(account) else {
                            return;
                        }
                        bankAccounts.append(bankRoot);
                        
                        let bankAccount = NSEntityDescription.insertNewObjectForEntityForName("BankAccount", inManagedObjectContext: context) as! BankAccount;
                        bankAccount.bankCode = account.bankCode;
                        bankAccount.setAccountNumber(account.number);
                        bankAccount.name = account.name;
                        bankAccount.currency = account.currency;
                        bankAccount.country = user.country;
                        bankAccount.owner = account.owner;
                        bankAccount.userId = user.userId;
                        bankAccount.customerId = user.customerId;
                        bankAccount.isBankAcc = NSNumber(bool: true);
                        bankAccount.accountSuffix = account.subNumber;
                        bankAccount.bic = account.bic;
                        bankAccount.iban = account.iban;
                        if let type = account.type, typeNum = Int(type) {
                            bankAccount.type = NSNumber(integer: typeNum);
                        }
                        
                        bankAccount.plugin = PluginRegistry.pluginForAccount(account.number, bankCode: account.bankCode);
                        if bankAccount.plugin.length == 0 {
                            bankAccount.plugin = "hbci";
                        }
                        
                        bankAccount.parent = bankRoot;
                        let users = bankAccount.mutableSetValueForKey("users");
                        users.addObject(user);
                    }
                }
            }
        }
    }
    
    func updateSupportedJobs(user:BankUser, parameters:HBCIParameters) throws {
        let accounts = parameters.getAccounts();
        
        for account in accounts {
            if let bankAccount = BankAccount.findAccountWithNumber(account.number, subNumber: account.subNumber, bankCode: account.bankCode) {
                let supportedJobs = parameters.supportedOrdersForAccount(account.number, subNumber: account.subNumber);
                let error = SupportedTransactionInfo.updateSupportedTransactionInfoForUser(user, account: bankAccount, withJobs: supportedJobs );
                if error != nil {
                    throw error;
                }
            }
        }
    }
    
    func updateTanMethodsForUser(user:BankUser, methods:Array<HBCITanMethod>) {
        let context = MOAssistant.sharedAssistant().context;
        let oldMethods = user.tanMethods.allObjects as! [TanMethod];
        
        for method in methods {
            let tanMethod = NSEntityDescription.insertNewObjectForEntityForName("TanMethod", inManagedObjectContext: context) as! TanMethod;
            tanMethod.identifier = method.identifier;
            tanMethod.inputInfo = method.inputInfo;
            tanMethod.name = method.name;
            tanMethod.maxTanLength = NSNumber(integer: method.maxTanLength);
            tanMethod.method = method.secfunc;
            tanMethod.needTanMedia = method.needTanMedia;
            tanMethod.process = method.process.rawValue;
            tanMethod.zkaMethodName = method.zkaMethodName;
            tanMethod.zkaMethodVersion = method.zkaMethodVersion;
            tanMethod.user = user;
            
            // take over data from old methods
            for oldMethod in oldMethods {
                if tanMethod.method == oldMethod.method {
                    tanMethod.preferredMedium = oldMethod.preferredMedium;
                }
            }
        }
        
        // remove old methods
        for oldMethod in oldMethods {
            context.deleteObject(oldMethod);
        }
        context.processPendingChanges();
    }
    
    func updateTanMediaForUser(user:BankUser, hbciUser:HBCIUser) {
        let context = MOAssistant.sharedAssistant().context;
        var tanMedia = Array<HBCITanMedium>();
        
        
        do {
            let dialog = try HBCIDialog(user: hbciUser);
            if let result = try dialog.dialogInit() {
                if result.isOk() {
                    if let msg = HBCICustomMessage.newInstance(dialog) {
                        if let order = HBCITanMediaOrder(message: msg) {
                            order.mediaType = "1";
                            order.mediaCategory = "A";
                            order.enqueue();
                            do {
                                try msg.send();
                                tanMedia = order.tanMedia;
                            }
                            catch {
                                dialog.dialogEnd();
                                return;
                            }
                        }
                    }
                    // end dialog
                    dialog.dialogEnd();
                }
            }
        }
        catch {
            return;
        }
        
        let oldMedia = user.tanMedia.allObjects as! [TanMedium];
        for tanMedium in tanMedia {
            let medium = NSEntityDescription.insertNewObjectForEntityForName("TanMedium", inManagedObjectContext: context) as! TanMedium;
            medium.category = tanMedium.category;
            medium.status = tanMedium.status;
            medium.cardNumber = tanMedium.cardNumber;
            medium.cardSeqNumber = tanMedium.cardSeqNumber;
            medium.cardType = tanMedium.cardType;
            medium.validFrom = tanMedium.validFrom;
            medium.validTo = tanMedium.validTo;
            medium.tanListNumber = tanMedium.tanListNumber;
            medium.name = tanMedium.name;
            medium.mobileNumber = tanMedium.mobileNumber;
            medium.mobileNumberSecure = tanMedium.mobileNumberSecure;
            medium.freeTans = tanMedium.freeTans == nil ? nil:NSNumber(integer: tanMedium.freeTans!);
            medium.lastUse = tanMedium.lastUse;
            medium.activatedOn = tanMedium.activatedOn;
            medium.user = user;
            
            for method in user.tanMethods {
                if let method = method as? TanMethod {
                    if let prefMedium = method.preferredMedium {
                        if prefMedium.name == medium.name! {
                            method.preferredMedium = medium;
                        }
                    }
                }
            }
        }
        
        for oldMedium in oldMedia {
            context.deleteObject(oldMedium);
        }
        
        context.processPendingChanges();
    }
    
    func getBankSetupInfo(bankCode:String) ->BankSetupInfo? {
        do {
            if let info = infoForBankCode(bankCode), url = NSURL(string: info.pinTanURL) {
                let dialog = try HBCIAnonymousDialog(hbciVersion: info.hbciVersion);
                
                
                if let result = try dialog.dialogWithURL(url, bankCode: bankCode) {
                    if result.isOk() {
                        let params = result.hbciParameters();
                        if let pinTanInfos = params.pinTanInfos {
                            let bsInfo = BankSetupInfo();
                            
                            if pinTanInfos.text_userId != nil {
                                bsInfo.info_userid = pinTanInfos.text_userId;
                            }
                            if pinTanInfos.text_customerId != nil {
                                bsInfo.info_customerid = pinTanInfos.text_customerId;
                            }
                            // todo: add pinlen/tanlen
                            return bsInfo;
                        }                        
                    }
                }
            }
        } catch {}
        
        return nil;
    }
    
    func supportedVersions() ->Array<String> {
        return ["220", "300"];
    }
    
    func addBankUser(user:BankUser) ->PecuniaError? {
        let hbciUser = HBCIUser(userId: user.userId, customerId: user.customerId, bankCode: user.bankCode, hbciVersion: user.hbciVersion, bankURLString: user.bankURL);
        
        // get PIN
        let request = AuthRequest();
        let password = request.getPin(user.bankCode, userId: user.userId);
        request.finishPasswordEntry();
        if password == "<abort>" {
            return nil;
        }
        hbciUser.pin = password;
        
        if UInt32(user.secMethod.intValue) == SecMethod_PinTan.rawValue {
            hbciUser.setSecurityMethod(HBCISecurityMethodPinTan());
        }
        if UInt32(user.secMethod.intValue) == SecMethod_DDV.rawValue {
            //hbciUser.setSecurityMethod(HBCISecurityMethodDDV());
        }

        
        do {
            let dialog = try HBCIDialog(user: hbciUser);
            if let result = try dialog.syncInit() {
                if result.isOk() {
                    let context = MOAssistant.sharedAssistant().context;
                    
                    user.hbciParameters = hbciUser.parameters.data();
                    user.sysId = hbciUser.sysId;
                    user.bankName = hbciUser.bankName;
                    if let method = hbciUser.parameters.getTanMethods().first, secm = UInt32(method.identifier) {
                        user.secMethod = NSNumber(unsignedInt: secm);
                    }
                    
                    // end sync dialog
                    dialog.dialogEnd();
                    
                    // get accounts
                    let accounts = hbciUser.parameters.getAccounts();
                    try updateBankAccounts(accounts, user: user);
                    
                    //todo: update supported transactions
                    try updateSupportedJobs(user, parameters: hbciUser.parameters);
                    
                    if SecurityMethod(user.secMethod.unsignedIntValue) == SecMethod_PinTan {
                        // update TAN methods
                        updateTanMethodsForUser(user, methods: hbciUser.parameters.getTanMethods());
                        
                        // update TAN Media
                        updateTanMediaForUser(user, hbciUser: hbciUser);
                    }
                    
                    try context.save();
                    return nil;
                }
            }
        }
        catch let err as PecuniaError {
            return err;
        }
        catch let err as NSError {
            let error = PecuniaError(message: err.localizedDescription, title: NSLocalizedString("83", comment: "Fehler"));
            return error;
        }
        
        return PecuniaError(message: NSLocalizedString("127", comment: ""), title: NSLocalizedString("128", comment: ""));
    }
    
}
