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
    
    // checks if IBAN, BIC is provided. If not, start dialog to retrieve it from bank
    func checkSepaInfo(accounts: Array<HBCIAccount>, user:HBCIUser) throws {
        if let account = accounts.first {
            if account.iban == nil || account.bic == nil {
                let dialog = try HBCIDialog(user: user);
                if let result = try dialog.dialogInit() {
                    if result.isOk() {
                        if let msg = HBCICustomMessage.newInstance(dialog) {
                            if let order = HBCISepaInfoOrder(message: msg, accounts: accounts) {
                                order.enqueue();
                                try msg.send();
                            }
                        }
                        
                        dialog.dialogEnd();                        
                    }
                }
            }
        }
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
                                    // check if account supports statement transfers - if yes,clear manual flag
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
        
        let secfunc = user.preferredTanMethod?.method;
        user.preferredTanMethod = nil;
        
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
            
            if secfunc != nil {
                if tanMethod.method == secfunc {
                    user.preferredTanMethod = tanMethod;
                }
            }
        }
        
        // remove old methods
        for oldMethod in oldMethods {
            context.deleteObject(oldMethod);
        }
        
        // set TAN method if not yet set
        
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
    
    func syncBankUser(user:BankUser) ->PecuniaError? {
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
                    
                    // end sync dialog
                    dialog.dialogEnd();
                    
                    //todo: update supported transactions
                    try updateSupportedJobs(user, parameters: hbciUser.parameters);
                    
                    if SecurityMethod(user.secMethod.unsignedIntValue) == SecMethod_PinTan {
                        if let secfunc = hbciUser.parameters.getTanMethods().first?.secfunc {
                            hbciUser.tanMethod = secfunc;
                        }

                        // update TAN methods
                        let tanMethods = hbciUser.parameters.getTanMethods();
                        updateTanMethodsForUser(user, methods: tanMethods);
                        
                        // update TAN Media
                        updateTanMediaForUser(user, hbciUser: hbciUser);
                        
                        if user.preferredTanMethod != nil {
                            hbciUser.tanMethod = user.preferredTanMethod.method;
                        } else {
                            // we need a TAN method
                            hbciUser.tanMethod = tanMethods.first?.secfunc;
                        }
                    }
                    
                    // get accounts
                    let accounts = hbciUser.parameters.getAccounts();
                    try checkSepaInfo(accounts, user:hbciUser);
                    
                    try updateBankAccounts(accounts, user: user);
                    
                    try context.save();
                    return nil;
                }
            }
        }
        catch let err as HBCIError {
            switch err {
            case .BadURL: print("test");
            default: print("next");
            }
        }
        catch let err as PecuniaError {
            return err;
        }
        catch let err as NSError {
            let error = PecuniaError(message: err.localizedDescription, title: NSLocalizedString("AP83", comment: "Fehler"));
            return error;
        }
        catch {}
        
        return PecuniaError(message: NSLocalizedString("AP127", comment: ""), title: NSLocalizedString("AP128", comment: ""));
    }
    
    func getParameterDescription(user:BankUser) ->String? {
        let hbciUser = HBCIUser(userId: user.userId, customerId: user.customerId, bankCode: user.bankCode, hbciVersion: user.hbciVersion, bankURLString: user.bankURL);
        if user.hbciParameters != nil {
            do {
                try hbciUser.setParameterData(user.hbciParameters);
            }
            catch {
                return nil;
            }
            return hbciUser.parameters.description;
        }
        return nil;
    }
    
    func getStatements(accounts:[BankAccount]) {
        var userList = Dictionary<String, Array<BankAccount>>();

        if userList.count > 0 || accounts.count == 0 {
            return;
        }

        // Organize accounts by user in order to get all statements for all accounts of a given user.
        for account in accounts {
            // Take out those accounts and run them through their appropriate plugin if they have
            // one assigned. Since they don't need to use the same mechanism we have for HBCI,
            // we can just use a local list. All plugins run in parallel.
            if account.plugin.length > 0 && account.plugin != "hbci" {
                // todo
            } else {
                if !userList.keys.contains(account.userId) {
                    userList[account.userId] = Array<BankAccount>();
                }
                userList[account.userId]!.append(account);
            }
        }
        
        // retrieve statements for each user id
        let queue = dispatch_queue_create("de.pecuniabanking.pecunia.statementsQueue", nil);

        for userId in userList.keys {
            // make sure PIN is known
            let user:BankUser! = accounts.first?.users.first as? BankUser;
            guard user != nil else {
                logError("Could not get bank user from account \(accounts.first!.accountNumber())");
                continue;
            }
            
            let request = AuthRequest();
            let password = request.getPin(user.bankCode, userId: user.userId);
            request.finishPasswordEntry();
            if password == "<abort>" {
                continue;
            }

            dispatch_async(queue, {
                self.getUserStatements(userList[userId]!);
            });
        }
        
        dispatch_async(queue, {
            let notification = NSNotification(name: PecuniaStatementsFinalizeNotification, object: nil);
            NSNotificationCenter.defaultCenter().postNotification(notification);            
        });
    }
    
    func convertStatements(account:HBCIAccount, statements:Array<HBCIStatement>) ->BankQueryResult {
        let context = MOAssistant.sharedAssistant().memContext;
        let result = BankQueryResult();
        var latest = NSDate.distantPast();
        
        result.bankCode = account.bankCode;
        result.accountNumber = account.number;
        result.accountSuffix = account.subNumber;

        for statement in statements {
            // get latest balance
            if let balance = statement.endBalance {
                if balance.postingDate > latest {
                    result.balance = balance.value;
                    latest = balance.postingDate;
                }
            }
            
            for item in statement.items {
                let stat = NSEntityDescription.insertNewObjectForEntityForName("BankStatement", inManagedObjectContext: context) as! BankStatement;
                stat.localAccount = account.number;
                stat.localSuffix = account.subNumber;
                stat.localBankCode = account.bankCode;
                stat.bankReference = item.bankReference;
                stat.currency = statement.endBalance?.currency;
                if stat.currency == nil {
                    stat.currency = account.currency;
                }
                stat.customerReference = item.customerReference;
                stat.date = item.date;
                stat.valutaDate = item.valutaDate;
                stat.value = item.value;
                stat.charge = item.charge;
                stat.primaNota = item.primaNota;
                stat.purpose = item.purpose;
                stat.remoteAccount = item.remoteAccountNumber;
                stat.remoteBankCode = item.remoteBankCode;
                stat.remoteBIC = item.remoteBIC;
                stat.remoteCountry = item.remoteCountry;
                stat.remoteIBAN = item.remoteIBAN;
                stat.remoteName = item.remoteName;
                let transCode = item.transactionCode == nil ? 999:item.transactionCode;
                stat.transactionCode = String(format: "%0.3d", transCode!);
                stat.transactionText = item.transactionText;
                stat.isStorno = NSNumber(bool: (item.isCancellation ?? false));
                stat.isPreliminary = NSNumber(bool: false);
                result.statements.append(stat);
            }
        }
        // check the order - oldest statement must be first
        if result.statements.count > 1 {
            if let first = result.statements.first?.date, last = result.statements.last?.date {
                if first > last {
                    var statements = Array<BankStatement>();
                    for i in 0..<result.statements.count {
                        statements.append(result.statements[i]);
                    }
                    result.statements = statements;
                }
            }
        }
        // calculate intermediate balances
        if var balance = result.balance {
            for var i = result.statements.count-1; i>=0; i-- {
                result.statements[i].saldo = balance;
                balance = balance - result.statements[i].value;
            }
        }
        return result;
    }
    
    func getUserStatements(accounts:[BankAccount]) {
        var hbciAccounts = Array<HBCIAccount>();
        var bqResult = Array<BankQueryResult>();
        
        let user:BankUser! = accounts.first?.users.first as? BankUser;
        guard user != nil else {
            logError("No bank user defined for account \(accounts.first?.accountNumber())");
            performSelectorOnMainThread(Selector("statementsReceived:"), withObject: nil, waitUntilDone: false);
            return;
        }
        
        for account in accounts {
            let hbciAccount = HBCIAccount(number: account.accountNumber(), subNumber:account.accountSuffix, bankCode:account.bankCode, owner:account.owner, currency:account.currency);
            hbciAccount.iban = account.iban;
            hbciAccount.bic = account.bic;
            hbciAccounts.append(hbciAccount);
        }

        let hbciUser = HBCIUser(userId: user.userId, customerId: user.customerId, bankCode: user.bankCode, hbciVersion: user.hbciVersion, bankURLString: user.bankURL);
        if user.hbciParameters != nil {
            do {
                try hbciUser.setParameterData(user.hbciParameters);
            }
            catch {
                logError("Could not set parameters for user \(user.userId)");
                performSelectorOnMainThread(Selector("statementsReceived:"), withObject: nil, waitUntilDone: false);
                return;
            }
        }
        
        hbciUser.sysId = user.sysId;
        hbciUser.tanMethod = hbciUser.parameters.getTanMethods().first?.secfunc;
        
        // get PIN
        let request = AuthRequest();
        hbciUser.pin = request.getPin(user.bankCode, userId: user.userId);
        
        if SecurityMethod(user.secMethod.unsignedIntValue) == SecMethod_PinTan {
            hbciUser.setSecurityMethod(HBCISecurityMethodPinTan());
        } else if SecurityMethod(user.secMethod.unsignedIntValue) == SecMethod_DDV {
            //hbciUser.setSecurityMethod(HBCISecurityMethodDDV());
        }
        
        do {
            let dialog = try HBCIDialog(user: hbciUser);
            if let result = try dialog.dialogInit() {
                if result.isOk() {
                    for hbciAccount in hbciAccounts {
                        if let msg = HBCICustomMessage.newInstance(dialog) {
                            if let order = HBCIStatementsOrder(message: msg, account: hbciAccount) {
                                order.enqueue();
                                
                                try msg.send();
                                
                                for order in msg.orders {
                                    if let order = order as? HBCIStatementsOrder {
                                        if let statements = order.statements {
                                            bqResult.append(convertStatements(order.account, statements:statements));
                                        } else {
                                            logError("Statements could not be retrieved for account \(order.account.number)");
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    /*
                    if let msg = HBCICustomMessage.newInstance(dialog) {
                        for hbciAccount in hbciAccounts {
                            if let order = HBCIStatementsOrder(message: msg, account: hbciAccount) {
                                order.enqueue();
                            }
                        }
                        
                        try msg.send();
                        
                        for order in msg.orders {
                            if let order = order as? HBCIStatementsOrder {
                                if let statements = order.statements {
                                    bqResult.append(convertStatements(order.account, statements:statements));
                                } else {
                                    logError("Statements could not be retrieved for account \(order.account.number)");
                                }
                            }
                        }
                    }
                    */
                    
                    // end dialog
                    dialog.dialogEnd();                    
                }
            }
        }
        catch {
            
        }
        
        let notification = NSNotification(name: PecuniaStatementsNotification, object: bqResult);
        NSNotificationCenter.defaultCenter().postNotification(notification);
    }
    
}
