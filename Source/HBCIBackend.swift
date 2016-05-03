//
//  HBCIBackend.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 04.12.15.
//  Copyright © 2015 Frank Emminghaus. All rights reserved.
//

import Foundation
import HBCI4Swift
import CommonCrypto

var _backend:HBCIBackend!

func ==(a:HBCIAccount, b:BankAccount) ->Bool {
    if a.number != b.accountNumber() {
        return false;
    }
    if a.subNumber == nil && b.accountSuffix == nil {
        return true;
    }
    if a.subNumber != nil && b.accountSuffix != nil {
        return a.subNumber == b.accountSuffix;
    }
    return false;
}

extension HBCIUser {
    convenience init(bankUser:BankUser) throws {
        self.init(userId:bankUser.userId, customerId:bankUser.customerId, bankCode:bankUser.bankCode, hbciVersion:bankUser.hbciVersion, bankURLString:bankUser.bankURL);
        self.sysId = bankUser.sysId;
        
        if bankUser.hbciParameters != nil {
            do {
                try setParameterData(bankUser.hbciParameters);
            }
            catch let error as NSError {
                logError("Could not set parameters for user \(bankUser.userId)");
                throw error;
            }
        }
    }
}

extension HBCIAccount {
    convenience init(account:BankAccount) {
        self.init(number: account.accountNumber(), subNumber:account.accountSuffix, bankCode:account.bankCode, owner:account.owner, currency:account.currency);
        self.iban = account.iban;
        self.bic = account.bic;
    }
}

extension NSError {
    @nonobjc static let titleKey = "de.pecuniabanking.pecunia.errortitle";
    
    class func fromHBCIError(error:HBCIError) ->NSError {
        var userInfo = Dictionary<String, String>();
        userInfo[titleKey] = NSLocalizedString("AP128", comment: "Fehler bei der Auftragsausführung");
        
        var msg:String;
        switch error {
        case .ParseError: msg = NSLocalizedString("AP2000", comment: "");
        case .BadURL(let urlString): msg = String(format: NSLocalizedString("AP2001", comment: ""), urlString);
        case .Connection(let path): msg = String(format: NSLocalizedString("AP2002", comment: ""), path);
        case .ServerTimeout(let host): msg = String(format: NSLocalizedString("AP2003", comment: ""), host);
        case .MissingData(let field): msg = String(format: NSLocalizedString("AP2004", comment: ""), field);
        case .InvalidHBCIVersion(let version): msg = String(format: NSLocalizedString("AP2005", comment: ""), version);
        case .SyntaxFileError: msg = NSLocalizedString("AP2006", comment: "");
        case .UserAbort: msg = NSLocalizedString("AP106", comment: "");
        }
        userInfo[NSLocalizedDescriptionKey] = msg;
        return NSError(domain: "de.pecuniabanking.ErrorDomain", code: 1000, userInfo: userInfo);
    }
    class func errorWithMsg(msgId msgId:String, titleId:String  = "AP53", params:CVarArgType...) ->NSError {
        var userInfo = Dictionary<String, String>();
        userInfo[titleKey] = NSLocalizedString(titleId, comment: "");
        userInfo[NSLocalizedDescriptionKey] = String(format: NSLocalizedString(msgId, comment: ""), arguments:params);
        return NSError(domain: "de.pecuniabanking.ErrorDomain", code: 1, userInfo: userInfo);
    }
    
    static var genericHBCI:NSError {
        get {
            return NSError.errorWithMsg(msgId: "AP127", titleId: "AP128");
        }
    }

}

class HBCIBackendCallback : HBCICallback {
    
    init() {}
    
    func getTan(user:HBCIUser, challenge:String?, challenge_hdd_uc:String?) throws ->String {
        let bankUser = BankUser.findUserWithId(user.userId, bankCode:user.bankCode);
        if challenge_hdd_uc != nil {
            // Flicker code.
            let controller = ChipTanWindowController(code: challenge_hdd_uc!, message: challenge); // todo
            if NSApp.runModalForWindow(controller.window!) == 0 {
                return controller.tan;
            } else {
                throw HBCIError.UserAbort;
            }
        }
        
        let tanWindow = TanWindow(text: String(format: NSLocalizedString("AP172", comment: ""), bankUser != nil ? bankUser.name : user.userId, challenge!));
        let res = NSApp.runModalForWindow(tanWindow.window!);
        tanWindow.close();
        if res == 0 {
            return tanWindow.result();
        } else {
            throw HBCIError.UserAbort;
        }
    }
}


public class BackendLog: HBCILog {
    
    public init() {}
    
    public func logError(message: String, file:String, function:String, line:Int) {
        DDLog.doLog(DDLogFlag.Error, message: message, function: function, file: file, line: Int32(line), arguments:[]);
    }
    public func logWarning(message: String, file:String, function:String, line:Int) {
        DDLog.doLog(DDLogFlag.Warning, message: message, function: function, file: file, line: Int32(line), arguments:[]);
    }
    public func logInfo(message: String, file:String, function:String, line:Int) {
        DDLog.doLog(DDLogFlag.Info, message: message, function: function, file: file, line: Int32(line), arguments:[]);
    }
}

class HBCIBackend : NSObject {
    var pluginsRunning = 0;
    var hbciQueriesRunning = 0;
    
    static var backend:HBCIBackend {
        get {
            if _backend == nil {
                _backend = HBCIBackend();
                HBCILogManager.setLog(HBCIConsoleLog());
                
                // load syntax extension
                if var path = NSBundle.mainBundle().resourcePath {
                    path = path + "/hbci_cc_300.xml";
                    let fm = NSFileManager.defaultManager();
                    if fm.fileExistsAtPath(path) {
                        do {
                            try HBCISyntaxExtension.instance.add(path, version: "300");
                            try HBCISyntaxExtension.instance.add(path, version: "220");
                        }
                        catch {
                            logError("Failed to process syntax extension");
                        }
                    }
                }
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
    
    func bankNameForCode(bankCode:String) ->String {
        if let info = IBANtools.instituteDetailsForBankCode(bankCode) {
            return info.name.length > 0 ? info.name : NSLocalizedString("AP13", comment: "");
        }
        return NSLocalizedString("AP13", comment: "");
    }
    
    func infoForIBAN(iban:String?) ->InstituteInfo? {
        guard let iban = iban else {
            return nil;
        }
        guard iban.length == 0 else {
            return nil;
        }
        
        if let bic = bicForIBAN(iban) {
            return IBANtools.instituteDetailsForBIC(bic);
        }
        return nil;
    }
    
    func bankNameForIBAN(iban:String) ->String {
        if let bic = bicForIBAN(iban) {
            if let info = IBANtools.instituteDetailsForBIC(bic) {
                return info.name.length > 0 ? info.name : NSLocalizedString("AP13", comment: "");
            }
        }
        return NSLocalizedString("AP13", comment: "");
    }
    
    func bicForIBAN(iban:String) ->String? {
        let bicInfo:NSDictionary = IBANtools.bicForIBAN(iban);
        if let result = bicInfo["result"]?.integerValue {
            if IBANToolsResult(rawValue: result) != IBANToolsResult.NoBIC {
                return bicInfo["bic"] as? String;
            }
        }
        return nil;
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
            var bankAccounts = try context.executeFetchRequest(request) as! [BankAccount];
            
            for account in accounts {
                found = false;
                for bankAccount in bankAccounts {
                    if account == bankAccount {
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
    
    func transactionTypeToOrderName(tt:TransactionType) ->String? {
        switch(tt) {
        case TransactionType.AccountStatements:
            return "AccountStatement";
        case TransactionType.BankStatements:
            return "Statements";
        case TransactionType.StandingOrderSEPA:
            return "SepaStandingOrderNew";
        case TransactionType.TransferInternalSEPA:
            return "SepaInternalTransfer";
        case TransactionType.TransferSEPA:
            return "SepaTransfer";
        case TransactionType.TransferSEPAScheduled:
            return "SepaDatedTransfer";
        case TransactionType.TransferCollectiveCreditSEPA:
            return "SepaCollectiveTransfer";
        case TransactionType.CCSettlementList:
            return "CCSettlementList";
        case TransactionType.CCSettlement:
            return "CCSettlement";
        case TransactionType.CCStatements:
            return "CCStatement";
        case TransactionType.AccountBalance:
            return "AccountBalance";
        case TransactionType.StandingOrderSEPAEdit:
            return "SepaStandingOrderEdit";
        default: return nil;
        }
    }
    
    func isOrderSupportedForAccount(orderName:String, account:BankAccount) ->Bool {
        guard let bankUser = account.defaultBankUser() else {
            return false;
        }
        do {
            let user = try HBCIUser(bankUser: bankUser);
            return user.parameters.isOrderSupportedForAccount(orderName, number: account.accountNumber(), subNumber: account.accountSuffix);
        }
        catch {}
        return false;
    }
    
    func isTransactionSupportedForAccount(tt:TransactionType, account:BankAccount) ->Bool {
        if let orderName = transactionTypeToOrderName(tt) {
            return self.isOrderSupportedForAccount(orderName, account: account);
        }
        return false;
    }
    
    func isTransactionSupportedForUser(tt:TransactionType, bankUser:BankUser) ->Bool {
        do {
            let user = try HBCIUser(bankUser: bankUser);
            if let orderName = transactionTypeToOrderName(tt) {
                return user.parameters.isOrderSupported(orderName);
            }
        }
        catch {}
        return false;
    }
    
    func isTransferSupportedForAccount(tt:TransferType, account:BankAccount) ->Bool {
        var transactionType:TransactionType?
        switch (tt) {
        case TransferTypeInternalSEPA: transactionType = TransactionType.TransferInternalSEPA;
        case TransferTypeCollectiveCreditSEPA: transactionType = TransactionType.TransferCollectiveCreditSEPA;
        case TransferTypeSEPA: transactionType = TransactionType.TransferSEPA;
        case TransferTypeSEPAScheduled: transactionType = TransactionType.TransferSEPAScheduled;
        default: return false;
        }
        return isTransactionSupportedForAccount(transactionType!, account: account);
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
        }
        catch {}
        return nil;
    }
    
    func supportedVersions() ->Array<String> {
        return ["220", "300"];
    }
    
    func setupSecurityMethod(bankUser:BankUser, user:HBCIUser) throws {
        if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_PinTan {
            user.setSecurityMethod(HBCISecurityMethodPinTan());
            return;
        }
        if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_DDV {
            let ccman = ChipcardManager.manager;
            try ccman.requestCardForUser(bankUser);
            let secMethod = HBCISecurityMethodDDV(card: ccman.card);
            user.setSecurityMethod(secMethod);
        }
    }
    
    func syncBankUser(bankUser:BankUser) ->NSError? {
        if bankUser.customerId == nil {
            bankUser.customerId = "";
        }
        
        do {
            let user = try HBCIUser(bankUser: bankUser);
            try setupSecurityMethod(bankUser, user: user);
            defer {
                if user.securityMethod.code == .DDV {
                    ChipcardManager.manager.close();
                }
            }
            
            // get PIN
            if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_PinTan {
                let request = AuthRequest();
                let password = request.getPin(user.bankCode, userId: user.userId);
                request.finishPasswordEntry();
                if password == "<abort>" {
                    return nil;
                }
                user.pin = password;
            }

            let dialog = try HBCIDialog(user: user);
            
            var result:HBCIResultMessage?
            if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_PinTan {
                result = try dialog.syncInit();
            } else {
                result = try dialog.dialogInit();
            }
            
            if let result = result {
                if result.isOk() {
                    let context = MOAssistant.sharedAssistant().context;
                    
                    // update bank user
                    bankUser.hbciParameters = user.parameters.data();
                    bankUser.sysId = user.sysId;
                    bankUser.bankName = user.bankName;
                    
                    // end sync dialog
                    dialog.dialogEnd();
                    
                    if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_PinTan {
                        if let secfunc = user.parameters.getTanMethods().first?.secfunc {
                            user.tanMethod = secfunc;
                        }

                        // update TAN methods
                        let tanMethods = user.parameters.getTanMethods();
                        updateTanMethodsForUser(bankUser, methods: tanMethods);
                        
                        // update TAN Media
                        updateTanMediaForUser(bankUser, hbciUser: user);
                        
                        if bankUser.preferredTanMethod != nil {
                            user.tanMethod = bankUser.preferredTanMethod.method;
                        } else {
                            // we need a TAN method
                            user.tanMethod = tanMethods.first?.secfunc;
                        }
                    }
                    
                    // get accounts
                    let accounts = user.parameters.getAccounts();
                    try checkSepaInfo(accounts, user:user);
                    
                    try updateBankAccounts(accounts, user: bankUser);
                    
                    try context.save();
                    return nil;
                }
            }
        }
        catch HBCIError.UserAbort {
            // do nothing
            return nil;
        }
        catch let error as HBCIError {
            return NSError.fromHBCIError(error);
        }
        catch let error as NSError {
            var userInfo = error.userInfo;
            userInfo[NSError.titleKey] = NSLocalizedString("AP53", comment: "HBCI-Fehler");
            return NSError(domain: error.domain, code: error.code, userInfo: userInfo);
        }
        catch {}
        return NSError.errorWithMsg(msgId: "AP127", titleId: "AP128");
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
    
    func getBalanceForAccount(bankAccount:BankAccount) -> NSError? {
        guard let bankUser = bankAccount.defaultBankUser() else {
            logError("Skip account \(bankAccount.accountNumber()), no user found");
            return NSError.genericHBCI;
        }
        
        do {
            try processHBCIDialog(bankUser) { user, dialog in
                let account = HBCIAccount(account: bankAccount);
                guard let msg = HBCICustomMessage.newInstance(dialog) else {
                    logError("Failed to create HBCI message");
                    return NSError.genericHBCI;
                }
                if let order = HBCIBalanceOrder(message: msg, account: account) {
                    order.enqueue();
                    guard msg.orders.count > 0 else {
                        return NSError.genericHBCI;
                    }
                    if try msg.send() {
                        if let balance = order.bookedBalance {
                            bankAccount.updateBalanceWithValue(balance.value);
                            return nil;
                        }
                    } else {
                        logError("Failed to get balance for account \(account.number)");
                        return NSError.genericHBCI;
                    }
                }
                return nil;
            }
            
            /*
            let user = try HBCIUser(bankUser: bankUser);
            try setupSecurityMethod(bankUser, user: user);

            if user.securityMethod.code == .PinTan {
                user.tanMethod = user.parameters.getTanMethods().first?.secfunc;

                // get PIN
                let request = AuthRequest();
                user.pin = request.getPin(user.bankCode, userId: user.userId);
            }
            
            let dialog = try HBCIDialog(user: user);
            guard let result = try dialog.dialogInit() else {
                logError("Could not initialize dialog for user \(user.userId)");
                return NSError.genericHBCI;
            }
            
            if result.isOk() {
                let account = HBCIAccount(account: bankAccount);
                guard let msg = HBCICustomMessage.newInstance(dialog) else {
                    logError("Failed to create HBCI message");
                    return NSError.genericHBCI;
                }
                if let order = HBCIBalanceOrder(message: msg, account: account) {
                    order.enqueue();
                    guard msg.orders.count > 0 else {
                        return NSError.genericHBCI;
                    }
                    if try msg.send() {
                        if let balance = order.bookedBalance {
                            bankAccount.updateBalanceWithValue(balance.value);
                            return nil;
                        }
                    } else {
                        logError("Failed to get balance for account \(account.number)");
                        return NSError.genericHBCI;
                    }
                }
                dialog.dialogEnd();
            }
            */
            
        }
        catch HBCIError.UserAbort {
            // do nothing
            return nil;
        }
        catch let error as HBCIError {
            return NSError.fromHBCIError(error);
        }
        catch let error as NSError {
            var userInfo = error.userInfo;
            userInfo[NSError.titleKey] = NSLocalizedString("AP53", comment: "HBCI-Fehler");
            return NSError(domain: error.domain, code: error.code, userInfo: userInfo);
        }
        catch {}
        return NSError.genericHBCI;
    }
    
    func getCCSettlementListForAccount(bankAccount:BankAccount) ->CCSettlementList? {
        guard let bankUser = bankAccount.defaultBankUser() else {
            logError("Skip account \(bankAccount.accountNumber()), no user found");
            return nil;
        }

        do {
            try processHBCIDialog(bankUser) { user, dialog in
                let account = HBCIAccount(account: bankAccount);
                guard let msg = HBCICustomMessage.newInstance(dialog) else {
                    logError("Failed to create HBCI message");
                    return nil;
                }
                if let order = CCSettlementListOrder(message: msg, account: account) {
                    order.enqueue();
                    guard msg.orders.count > 0 else {
                        return nil;
                    }
                    if try msg.send() {
                        return order.settlementList;
                    } else {
                        logError("Failed to get credit card settlement list for account \(account.number)");
                        return nil;
                    }
                }
                return nil;
            }
        }
        catch HBCIError.UserAbort {
            return nil;
        }
        catch let error as HBCIError {
            let error = NSError.fromHBCIError(error);
            logError(error.localizedDescription);
            return nil;
        }
        catch let error as NSError {
            var userInfo = error.userInfo;
            userInfo[NSError.titleKey] = NSLocalizedString("AP53", comment: "HBCI-Fehler");
            let error = NSError(domain: error.domain, code: error.code, userInfo: userInfo);
            logError(error.localizedDescription);
            return nil;
        }
        catch {}
        return nil;

    }
    
    func getCreditCardSettlement(settleID:String, bankAccount:BankAccount) ->CreditCardSettlement? {
        guard let bankUser = bankAccount.defaultBankUser() else {
            logError("Skip account \(bankAccount.accountNumber()), no user found");
            return nil;
        }
        
        do {
            try processHBCIDialog(bankUser) { user, dialog in
                let account = HBCIAccount(account: bankAccount);
                guard let msg = HBCICustomMessage.newInstance(dialog) else {
                    logError("Failed to create HBCI message");
                    return nil;
                }
                if let order = CCSettlementOrder(message: msg, account: account, settleID:settleID) {
                    order.enqueue();
                    guard msg.orders.count > 0 else {
                        return nil;
                    }
                    if try msg.send() {
                        return order.settlement;
                    } else {
                        logError("Failed to get credit card settlement for account \(account.number)");
                        return nil;
                    }
                }
                return nil;
            }

        }
        catch HBCIError.UserAbort {
            return nil;
        }
        catch let error as HBCIError {
            let error = NSError.fromHBCIError(error);
            logError(error.localizedDescription);
            return nil;
        }
        catch let error as NSError {
            var userInfo = error.userInfo;
            userInfo[NSError.titleKey] = NSLocalizedString("AP53", comment: "HBCI-Fehler");
            let error = NSError(domain: error.domain, code: error.code, userInfo: userInfo);
            logError(error.localizedDescription);
            return nil;
        }
        catch {}
        return nil;
    }
    
    func checkGetStatementsFinalization() {
        if self.pluginsRunning == 0 && self.hbciQueriesRunning == 0 {
            // important: nofifications must be sent in main thread!
            let notification = NSNotification(name: PecuniaStatementsFinalizeNotification, object: nil);
            NSNotificationCenter.defaultCenter().postNotification(notification);
        }
    }
    
    func getPluginStatements(accounts:[BankAccount]) {
        var userPluginList = Dictionary<String, Array<BankAccount>>();
        
        if accounts.count == 0 {
            return;
        }
        
        // Organize accounts by user in order to get all statements for all accounts of a given user.
        for account in accounts {
            guard let _ = account.defaultBankUser() else {
                logError("Skip account \(account.accountNumber()), no user found");
                continue;
            }
            
            // Take out those accounts and run them through their appropriate plugin if they have
            // one assigned. Since they don't need to use the same mechanism we have for HBCI,
            // we can just use a local list. All plugins run in parallel.
            if account.plugin.length > 0 && account.plugin != "hbci" {
                if !userPluginList.keys.contains(account.plugin) {
                    userPluginList[account.plugin] = Array<BankAccount>();
                }
                userPluginList[account.plugin]!.append(account);
            }
        }
        self.pluginsRunning = userPluginList.count;
        for accounts in userPluginList.values {
            PluginRegistry.getStatements(accounts, completion: { (results: [BankQueryResult]) -> Void in
                for result in results {
                    self.orderStatements(result);
					if result.statements.count > 0 {
						if let account = result.account {
							account.evaluateQueryResult(result);
						}
					}
                }
				
                dispatch_async(dispatch_get_main_queue(), {
                    // important: nofifications must be sent in main thread!
                    let notification = NSNotification(name: PecuniaStatementsNotification, object: results);
                    NSNotificationCenter.defaultCenter().postNotification(notification);
                    self.pluginsRunning--;
                    self.checkGetStatementsFinalization();
                });
            });
        }
    }
    
    func getStandingOrders(accounts:[BankAccount]) {
        // first reset memory context
        MOAssistant.sharedAssistant().memContext.reset();

        self.getStatements(accounts, userFunc: self.getUserStandingOrders);
    }
    
    func getStatements(accounts:[BankAccount]) {
        // first reset memory context
        MOAssistant.sharedAssistant().memContext.reset();
        
        self.getPluginStatements(accounts);
        self.getStatements(accounts, userFunc: self.getUserStatements);
    }
    
    func getStatements(accounts:[BankAccount], userFunc:([BankAccount]) -> Void) {
        var userList = Dictionary<BankUser, Array<BankAccount>>();

        if accounts.count == 0 || self.hbciQueriesRunning > 0 {
            return;
        }

        // Organize accounts by user in order to get all statements for all accounts of a given user.
        for account in accounts {
            guard let user = account.defaultBankUser() else {
                logError("Skip account \(account.accountNumber()), no user found");
                continue;
            }
            
            // Take out those accounts and run them through their appropriate plugin if they have
            // one assigned. Since they don't need to use the same mechanism we have for HBCI,
            // we can just use a local list. All plugins run in parallel.
            if account.plugin.length > 0 && account.plugin != "hbci" {
                // should be handled by Plugin
            } else {
                if !userList.keys.contains(user) {
                    userList[user] = Array<BankAccount>();
                }
                userList[user]!.append(account);
            }
        }
        
        // retrieve statements for each user id
        let queue = dispatch_queue_create("de.pecuniabanking.pecunia.statementsQueue", nil);

        for user in userList.keys {
            if SecurityMethod(user.secMethod.unsignedIntValue) == SecMethod_PinTan {
                // make sure PIN is known
                let request = AuthRequest();
                let password = request.getPin(user.bankCode, userId: user.userId);
                request.finishPasswordEntry();
                if password == "<abort>" {
                    continue;
                }
            } else {
                // DDV access must be strongly serialized
                continue;
            }

            self.hbciQueriesRunning++;
            dispatch_async(queue, {
                userFunc(userList[user]!);
            });
        }
        
        // now we do the DDV access
        // the DDV access has to be strongly serialized
        for user in userList.keys {
            if SecurityMethod(user.secMethod.unsignedIntValue) == SecMethod_DDV {
                let ccman = ChipcardManager.manager;
                do {
                    try ccman.requestCardForUser(user);
                    self.hbciQueriesRunning++;
                    userFunc(userList[user]!);
                }
                catch let error as NSError {
                    let alert = NSAlert(error: error);
                    alert.runModal();
                }
                catch { }
            }
        }
    }
    
    func convertStandingOrders(orders:[HBCIStandingOrder]) ->BankQueryResult {
        let context = MOAssistant.sharedAssistant().memContext;
        let result = BankQueryResult();
        
        guard let account = orders.first?.account else {
            return result;
        }
        
        result.bankCode = account.bankCode;
        result.accountNumber = account.number;
        result.accountSuffix = account.subNumber;

        for order in orders {
            for item in order.items {
                let stord = NSEntityDescription.insertNewObjectForEntityForName("StandingOrder", inManagedObjectContext: context) as! StandingOrder;
                stord.localAccount = account.number;
                stord.localBankCode = account.bankCode;
                stord.currency = item.currency;
                if stord.currency == nil {
                    stord.currency = account.currency;
                }
                stord.value = item.value;
                stord.purpose1 = item.purpose;
                stord.remoteBIC = item.remoteBic;
                stord.remoteIBAN = item.remoteIban;
                stord.remoteName = item.remoteName;
                
                stord.firstExecDate = order.startDate;
                stord.lastExecDate = order.lastDate;
                stord.cycle = NSNumber(integer: order.cycle);
                stord.executionDay = NSNumber(integer: order.executionDay);
                stord.orderKey = order.orderId;
                if order.cycleUnit == .monthly {
                    stord.period = NSNumber(unsignedInt: stord_monthly.rawValue);
                } else {
                    stord.period = NSNumber(unsignedInt: stord_weekly.rawValue);
                }
                result.standingOrders.append(stord);
            }
        }
        
        // get account reference
        if account.subNumber == nil {
            result.account = BankAccount.findAccountWithNumber(account.number, bankCode: account.bankCode);
        } else {
            result.account = BankAccount.findAccountWithNumber(account.number, subNumber: account.subNumber, bankCode: account.bankCode);
        }

        return result;
    }
    
    func orderStatements(result:BankQueryResult) {
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
        orderStatements(result);
        
        return result;
    }
    
    func getUserStandingOrders(bankAccounts:[BankAccount]) {
        var accounts = [HBCIAccount]();
        var bqResult = [BankQueryResult]();
        
        guard let bankUser = bankAccounts.first?.defaultBankUser() else {
            logError("No bank user defined for account \(bankAccounts.first?.accountNumber())");
            return;
        }
        
        for bankAccount in bankAccounts {
            let account = HBCIAccount(account: bankAccount);
            accounts.append(account);
        }
        
        defer {
            if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_DDV {
                ChipcardManager.manager.close();
            }
        }

        do {
            let user = try HBCIUser(bankUser: bankUser);
            
            if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_PinTan {
                user.setSecurityMethod(HBCISecurityMethodPinTan());
                user.tanMethod = user.parameters.getTanMethods().first?.secfunc;
                
                // get PIN
                let request = AuthRequest();
                user.pin = request.getPin(user.bankCode, userId: bankUser.userId);
            }
            if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_DDV {
                let secMethod = HBCISecurityMethodDDV(card: ChipcardManager.manager.card);
                user.setSecurityMethod(secMethod);
            }
            
            let dialog = try HBCIDialog(user: user);
            if let result = try dialog.dialogInit() {
                if result.isOk() {
                    defer {
                        dialog.dialogEnd();
                    }

                    for account in accounts {
                        if let msg = HBCICustomMessage.newInstance(dialog) {
                            if let order = HBCISepaStandingOrderListOrder(message: msg, account: account) {
                                order.enqueue();
                                
                                try msg.send();
                                
                                for order in msg.orders {
                                    if let order = order as? HBCISepaStandingOrderListOrder {
                                        bqResult.append(convertStandingOrders(order.standingOrders));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        catch {}
        
        dispatch_async(dispatch_get_main_queue(), {
            // important: nofifications must be sent in main thread!
            let notification = NSNotification(name: PecuniaStatementsNotification, object: bqResult);
            NSNotificationCenter.defaultCenter().postNotification(notification);
            self.hbciQueriesRunning--;
            self.checkGetStatementsFinalization();
        });
    }
    
    func getUserStatements(accounts:[BankAccount]) {
        var hbciAccounts = Array<HBCIAccount>();
        var bqResult = Array<BankQueryResult>();
        
        guard let bankUser = accounts.first?.defaultBankUser() else {
            logError("No bank user defined for account \(accounts.first?.accountNumber())");
            return;
        }
        
        for account in accounts {
            let hbciAccount = HBCIAccount(account: account);
            hbciAccounts.append(hbciAccount);
        }
        
        defer {
            if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_DDV {
                ChipcardManager.manager.close();
            }
        }

        do {
            let user = try HBCIUser(bankUser: bankUser);
            
            if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_PinTan {
                user.setSecurityMethod(HBCISecurityMethodPinTan());
                user.tanMethod = user.parameters.getTanMethods().first?.secfunc;
                
                // get PIN
                let request = AuthRequest();
                user.pin = request.getPin(user.bankCode, userId: bankUser.userId);
            }
            if SecurityMethod(bankUser.secMethod.unsignedIntValue) == SecMethod_DDV {
                let secMethod = HBCISecurityMethodDDV(card: ChipcardManager.manager.card);
                user.setSecurityMethod(secMethod);
            }
            
            let dialog = try HBCIDialog(user: user);
            if let result = try dialog.dialogInit() {
                if result.isOk() {
                    defer {
                        dialog.dialogEnd();
                    }
                    
                    for account in accounts {
                        if let msg = HBCICustomMessage.newInstance(dialog) {
                            let hbciAccount = HBCIAccount(account: account);
                            var dateFrom:NSDate?
                            
                            // find out how many days to read from the past
                            var maxStatDays = 0;
                            if NSUserDefaults.standardUserDefaults().boolForKey("limitStatsAge") {
                                maxStatDays = NSUserDefaults.standardUserDefaults().integerForKey("maxStatDays");
                            }
                            
                            if account.latestTransferDate == nil && maxStatDays > 0 {
                                account.latestTransferDate = NSDate(timeInterval: NSTimeInterval(-86400 * maxStatDays), sinceDate: NSDate());
                            }
                            
                            if let latestDate = account.latestTransferDate {
                                let fromDate = NSDate(timeInterval: -605000, sinceDate: latestDate);
                                dateFrom = fromDate;
                            }
                            
                            if isTransactionSupportedForAccount(TransactionType.CCStatements, account: account) {
                                // credit card statements
                                if let order = CCStatementOrder(message: msg, account: hbciAccount) {
                                    
                                    order.dateFrom = dateFrom;
                                    order.enqueue();
                                    
                                    try msg.send();
                                    
                                    for order in msg.orders {
                                        if let order = order as? CCStatementOrder {
                                            if let statements = order.statements {
                                                let result = convertStatements(order.account, statements:statements);
                                                result.account = account;
                                                bqResult.append(result);
                                            } else {
                                                logError("Credit card statements could not be retrieved for account \(order.account.number)");
                                            }
                                        }
                                    }
                                }
                            } else if isTransactionSupportedForAccount(TransactionType.BankStatements, account: account) {
                                // normal statements
                                if let order = HBCIStatementsOrder(message: msg, account: hbciAccount) {
                                    
                                    order.dateFrom = dateFrom;
                                    order.enqueue();
                                    
                                    try msg.send();
                                    
                                    for order in msg.orders {
                                        if let order = order as? HBCIStatementsOrder {
                                            if let statements = order.statements {
                                                let result = convertStatements(order.account, statements:statements);
                                                result.account = account;
                                                bqResult.append(result);
                                            } else {
                                                logError("Statements could not be retrieved for account \(order.account.number)");
                                            }
                                        }
                                    }
                                }
                            } else if isTransactionSupportedForAccount(TransactionType.AccountBalance, account: account) {
                                // Statement are not supported but Account Balance
                                if let order = HBCIBalanceOrder(message: msg, account: hbciAccount) {

                                    order.enqueue();

                                    if try msg.send() {
                                        if let balance = order.bookedBalance {
                                            let result = BankQueryResult();
                                            
                                            result.bankCode = hbciAccount.bankCode;
                                            result.accountNumber = hbciAccount.number;
                                            result.accountSuffix = hbciAccount.subNumber;
                                            
                                            result.balance = balance.value;
                                            result.account = account;
                                            bqResult.append(result);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        catch {
            
        }
        
        for result in bqResult {
            if result.statements.count > 0 {
                if let account = result.account {
                    account.evaluateQueryResult(result);
                }
            }
        }
                
        dispatch_async(dispatch_get_main_queue(), {
            // important: nofifications must be sent in main thread!
            let notification = NSNotification(name: PecuniaStatementsNotification, object: bqResult);
            NSNotificationCenter.defaultCenter().postNotification(notification);
            self.hbciQueriesRunning--;
            self.checkGetStatementsFinalization();
        });
    }
    
    func signingOptionForUser(user:BankUser) ->SigningOption? {
        var options = Array<SigningOption>();
        
        if let option = user.preferredSigningOption() {
            options.append(option);
        } else {
            options.appendContentsOf(user.getSigningOptions() as! [SigningOption]);
        }
        
        if options.count == 0 {
            logDebug("signingOptionForAccount: no signing options defined by bank - use default");
            return SigningOption.defaultOptionForUser(user);
        }
        if options.count == 1 {
            return options.first;
        }
        
        let controller = SigningOptionsController(signingOptions: options, forAccount: nil);
        let res = NSApp.runModalForWindow(controller.window!);
        if res > 0 {
            return nil;
        }
        return controller.selectedOption();
   
    }
    
    func sendCollectiveTransfer(transfers: Array<Transfer>) ->NSError? {
        if transfers.count == 0 {
            return nil;
        }
        
        // check that all transfers have the same sender account
        let firstTransfer = transfers.first!
        for transfer in transfers {
            if transfer.account != firstTransfer.account {
                return NSError.errorWithMsg(msgId: "424", titleId: "423");
            }
        }
        
        HBCIDialog.callback = HBCIBackendCallback();
        
        let bankAccount = firstTransfer.account;
        let bankUser = bankAccount.defaultBankUser();
        
        guard let option = signingOptionForUser(bankUser) else {
            return nil;
        }
        
        do {
            try processHBCIDialog(bankUser, signingOption: option) { user, dialog in
                // now collect transfers
                let account = HBCIAccount(account: bankAccount);
                let sepaTransfer = HBCISepaTransfer(account:account);
                
                for transfer in transfers {
                    let item = HBCISepaTransfer.Item(iban:transfer.remoteIBAN, bic:transfer.remoteBIC, name:transfer.remoteName, value:transfer.value, currency:transfer.currency);
                    item.purpose = transfer.purpose();
                    sepaTransfer.addItem(item);
                }
                
                guard let msg = HBCICustomMessage.newInstance(dialog) else {
                    logError("Failed to create HBCI message");
                    return NSError.genericHBCI;
                }
                
                if let order = HBCISepaCollectiveTransferOrder(message: msg, transfer: sepaTransfer) {
                    order.enqueue();
                }
                
                guard msg.orders.count > 0 else {
                    logError("Failed to create collective transfer order");
                    return NSError.genericHBCI;
                }
                
                if try msg.send() {
                    for transfer in transfers {
                        transfer.isSent = NSNumber(bool: true);
                    }
                    return nil;
                }
                return nil;
            }
            
            /*
            let user = try HBCIUser(bankUser: bankUser);
            try setupSecurityMethod(bankUser, user: user);
            
            if user.securityMethod.code == .PinTan {
                user.tanMethod = option.tanMethod;
                user.tanMediumName = option.tanMediumName;
                
                // get PIN
                let request = AuthRequest();
                user.pin = request.getPin(user.bankCode, userId: user.userId);
            }

            let dialog = try HBCIDialog(user: user);
            guard let result = try dialog.dialogInit() else {
                logError("Could not initialize dialog for user \(user.userId)");
                return NSError.genericHBCI;
            }
            if result.isOk() {
                // now collect transfers
                let account = HBCIAccount(account: bankAccount);
                let sepaTransfer = HBCISepaTransfer(account:account);
                
                for transfer in transfers {
                    let item = HBCISepaTransfer.Item(iban:transfer.remoteIBAN, bic:transfer.remoteBIC, name:transfer.remoteName, value:transfer.value, currency:transfer.currency);
                    item.purpose = transfer.purpose();
                    sepaTransfer.addItem(item);
                }
                
                guard let msg = HBCICustomMessage.newInstance(dialog) else {
                    logError("Failed to create HBCI message");
                    return NSError.genericHBCI;
                }
                
                if let order = HBCISepaCollectiveTransferOrder(message: msg, transfer: sepaTransfer) {
                    order.enqueue();
                }
                
                guard msg.orders.count > 0 else {
                    logError("Failed to create collective transfer order");
                    return NSError.genericHBCI;
                }
                
                if try msg.send() {
                    for transfer in transfers {
                        transfer.isSent = NSNumber(bool: true);
                    }
                    return nil;
                }
                
                dialog.dialogEnd();
            }
            */
        }
        catch HBCIError.UserAbort {
            // do nothing
            return nil;
        }
        catch let error as HBCIError {
            return NSError.fromHBCIError(error);
        }
        catch let error as NSError {
            var userInfo = error.userInfo;
            userInfo[NSError.titleKey] = NSLocalizedString("AP53", comment: "HBCI-Fehler");
            return NSError(domain: error.domain, code: error.code, userInfo: userInfo);
        }
        catch {}
        return NSError.genericHBCI;
    }
    
    func sendTransfers(transfers:Array<Transfer>) {
        
        var accountTransferRegister = Dictionary<BankUser, Array<Transfer>>();
        var errorOccured = false;
        
        HBCIDialog.callback = HBCIBackendCallback();
        
        for transfer in transfers {
            let account = transfer.account;
            guard let bankUser = account.defaultBankUser() else {
                logError("Skip transfer: no bank user found for bank account \(account.accountNumber())");
                errorOccured = true;
                continue;
            }
            if accountTransferRegister[bankUser] == nil {
                accountTransferRegister[bankUser] = Array<Transfer>();
            }
            accountTransferRegister[bankUser]!.append(transfer);
        }
        
        for bankUser in accountTransferRegister.keys {
            guard let option = signingOptionForUser(bankUser) else {
                errorOccured = true;
                continue;
            }
            
            // open dialog once for user
            do {
                try processHBCIDialog(bankUser, signingOption: option) { user, dialog in
                    // now send all transfers for user
                    for transfer in accountTransferRegister[bankUser]! {
                        let account = HBCIAccount(account: transfer.account);
                        
                        let sepaTransfer = HBCISepaTransfer(account: account);
                        
                        if TransferType(transfer.type.unsignedIntValue) == TransferTypeSEPAScheduled  && transfer.valutaDate != nil {
                            sepaTransfer.date = transfer.valutaDate!;
                        }
                        
                        let item = HBCISepaTransfer.Item(iban:transfer.remoteIBAN, bic:transfer.remoteBIC, name:transfer.remoteName, value:transfer.value, currency:transfer.currency);
                        item.purpose = transfer.purpose();
                        sepaTransfer.addItem(item);
                        
                        if let msg = HBCICustomMessage.newInstance(dialog) {
                            if sepaTransfer.date != nil {
                                if let order = HBCISepaDatedTransferOrder(message: msg, transfer: sepaTransfer) {
                                    order.enqueue();
                                }
                            } else {
                                if let order = HBCISepaTransferOrder(message: msg, transfer: sepaTransfer) {
                                    order.enqueue();
                                }
                            }
                            
                            if msg.orders.count > 0 {
                                if try msg.send() {
                                    transfer.isSent = NSNumber(bool: true);
                                    continue;
                                }
                            }
                        }
                        errorOccured = true;
                    } // accounts
                    return nil;
                }
                
                
                /*
                let user = try HBCIUser(bankUser: bankUser);
                try setupSecurityMethod(bankUser, user: user);
                defer {
                    if user.securityMethod.code == .DDV {
                        ChipcardManager.manager.close();
                    }
                }
                
                if user.securityMethod.code == .PinTan {
                    user.tanMethod = option.tanMethod;
                    user.tanMediumName = option.tanMediumName;
                    
                    // get PIN
                    let request = AuthRequest();
                    user.pin = request.getPin(user.bankCode, userId: user.userId);
                }

                let dialog = try HBCIDialog(user: user);
                guard let result = try dialog.dialogInit() else {
                    errorOccured = true;
                    continue;
                }
                guard result.isOk() else {
                    errorOccured = true;
                    continue;
                }
                // now send all transfers for user
                for transfer in accountTransferRegister[bankUser]! {
                    let account = HBCIAccount(account: transfer.account);
                    
                    let sepaTransfer = HBCISepaTransfer(account: account);
                    
                    if TransferType(transfer.type.unsignedIntValue) == TransferTypeSEPAScheduled  && transfer.valutaDate != nil {
                        sepaTransfer.date = transfer.valutaDate!;
                    }
                    
                    let item = HBCISepaTransfer.Item(iban:transfer.remoteIBAN, bic:transfer.remoteBIC, name:transfer.remoteName, value:transfer.value, currency:transfer.currency);
                    item.purpose = transfer.purpose();
                    sepaTransfer.addItem(item);
                    
                    if let msg = HBCICustomMessage.newInstance(dialog) {
                        if sepaTransfer.date != nil {
                            if let order = HBCISepaDatedTransferOrder(message: msg, transfer: sepaTransfer) {
                                order.enqueue();
                            }
                        } else {
                            if let order = HBCISepaTransferOrder(message: msg, transfer: sepaTransfer) {
                                order.enqueue();
                            }
                        }
                        
                        if msg.orders.count > 0 {
                            if try msg.send() {
                                transfer.isSent = NSNumber(bool: true);
                                continue;
                            }
                        }
                    }
                    errorOccured = true;
                } // accounts
                // end dialog
                dialog.dialogEnd();
                */
                
            } // do
            catch HBCIError.UserAbort {
                // do nothing
                return;
            }
            catch let error as NSError {
                logError(error.localizedDescription);
            }
            catch {
                errorOccured = true;
                // continue with next user
            }
        } // users
        
        if errorOccured {
            let alert = NSAlert();
            alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
            alert.messageText = NSLocalizedString("AP128", comment: "");
            alert.informativeText = NSLocalizedString("AP2008", comment: "");
            
            alert.runModal();
        }
    }
    
    func sendStandingOrders(standingOrders:[StandingOrder]) ->NSError? {
        var accountTransferRegister = Dictionary<BankUser, Array<StandingOrder>>();
        var errorOccured = false;
        
        HBCIDialog.callback = HBCIBackendCallback();
        
        for stord in standingOrders {
            let bankAccount = stord.account;
            guard let bankUser = bankAccount.defaultBankUser() else {
                logError("Skip standing order: no bank user found for bank account \(bankAccount.accountNumber())");
                errorOccured = true;
                continue;
            }
            if accountTransferRegister[bankUser] == nil {
                accountTransferRegister[bankUser] = Array<StandingOrder>();
            }
            accountTransferRegister[bankUser]!.append(stord);
        }
        
        for bankUser in accountTransferRegister.keys {
            guard let option = signingOptionForUser(bankUser) else {
                errorOccured = true;
                continue;
            }
            
            // open dialog once for user
            do {
                try processHBCIDialog(bankUser, signingOption: option) { user, dialog in
                    // now send all standing orders for user
                    for stord in accountTransferRegister[bankUser]! {
                        if stord.isChanged.boolValue == false && stord.toDelete.boolValue == false {
                            continue;
                        }
                        
                        if stord.isSent.boolValue == true && stord.orderKey == nil {
                            continue;
                        }
                        
                        if stord.orderKey == nil {
                            // create new standing order
                            if let msg = HBCICustomMessage.newInstance(dialog) {
                                if let order = HBCISepaStandingOrderNewOrder(message: msg, order: self.convertStandingOrder(stord)) {
                                    order.enqueue();
                                    if try msg.send() {
                                        stord.isSent = NSNumber(bool: true);
                                        continue;
                                    }
                                }
                            }
                        } else if stord.toDelete.boolValue == true {
                            if let msg = HBCICustomMessage.newInstance(dialog) {
                                if let order = HBCISepaStandingOrderDeleteOrder(message: msg, order: self.convertStandingOrder(stord), orderId:stord.orderKey) {
                                    order.enqueue();
                                    if try msg.send() {
                                        let context = MOAssistant.sharedAssistant().context;
                                        context.deleteObject(stord);
                                        continue;
                                    }
                                }
                            }
                        } else {
                            // change standing order
                            if let msg = HBCICustomMessage.newInstance(dialog) {
                                if let order = HBCISepaStandingOrderEditOrder(message: msg, order: self.convertStandingOrder(stord), orderId:stord.orderKey) {
                                    order.enqueue();
                                    if try msg.send() {
                                        stord.isSent = NSNumber(bool: true);
                                        continue;
                                    }
                                }
                            }
                        }
                        
                        
                        errorOccured = true;
                    }
                    return nil;
                }
                
                /*
                let user = try HBCIUser(bankUser: bankUser);
                try setupSecurityMethod(bankUser, user: user);
                defer {
                    if user.securityMethod.code == .DDV {
                        ChipcardManager.manager.close();
                    }
                }
                
                if user.securityMethod.code == .PinTan {
                    user.tanMethod = option.tanMethod;
                    user.tanMediumName = option.tanMediumName;
                    
                    // get PIN
                    let request = AuthRequest();
                    user.pin = request.getPin(user.bankCode, userId: user.userId);
                }
                
                let dialog = try HBCIDialog(user: user);
                guard let result = try dialog.dialogInit() else {
                    errorOccured = true;
                    continue;
                }
                guard result.isOk() else {
                    errorOccured = true;
                    continue;
                }
                
                // now send all standing orders for user
                for stord in accountTransferRegister[bankUser]! {
                    if stord.isChanged.boolValue == false && stord.toDelete.boolValue == false {
                        continue;
                    }
                    
                    if stord.isSent.boolValue == true && stord.orderKey == nil {
                        continue;
                    }
                    
                    if stord.orderKey == nil {
                        // create new standing order
                        if let msg = HBCICustomMessage.newInstance(dialog) {
                            if let order = HBCISepaStandingOrderNewOrder(message: msg, order: convertStandingOrder(stord)) {
                                order.enqueue();
                                if try msg.send() {
                                    stord.isSent = NSNumber(bool: true);
                                    continue;
                                }
                            }
                        }
                    } else if stord.toDelete.boolValue == true {
                        // delete standing order
                    } else {
                        // change standing order
                    }
                    
                    
                    errorOccured = true;
                }
                
                // end dialog
                dialog.dialogEnd();
                */
            }
            catch HBCIError.UserAbort {
                // do nothing
                return nil;
            }
            catch let error as NSError {
                logError(error.localizedDescription);
            }
            catch {
                errorOccured = true;
                // continue with next user
            }
        } // users
        if errorOccured {
            return NSError.errorWithMsg(msgId: "AP2009", titleId: "AP128");
        }
        return nil;
    }
    
    func convertStandingOrder(stord:StandingOrder) ->HBCIStandingOrder {
        let account = HBCIAccount(account: stord.account);
        var unit = HBCIStandingOrderCycleUnit.monthly;
        
        
        if StandingOrderPeriod(stord.period.unsignedIntValue) == stord_weekly {
            unit = .weekly;
        }
        
        let result = HBCIStandingOrder(account: account, startDate: stord.firstExecDate, cycle: stord.cycle.integerValue, day: stord.executionDay.integerValue, cycleUnit: unit);
        
        let item = HBCISepaTransfer.Item(iban:stord.remoteIBAN, bic:stord.remoteBIC, name:stord.remoteName, value:stord.value, currency:stord.currency);
        item.purpose = stord.purpose();
        result.addItem(item);
        return result;
    }
    
    func standingOrderLimits(bankUser:BankUser, action:StandingOrderAction) ->TransactionLimits? {
        do {
            let user = try HBCIUser(bankUser: bankUser);
            switch action {
            case stord_create:
                if let params = HBCISepaStandingOrderNewOrder.getParameters(user) {
                    let limits = TransactionLimits();
                    limits.minSetupTime = Int16(params.minPreDays);
                    limits.maxSetupTime = Int16(params.maxPreDays);
                    limits.monthCyclesString = params.cycleMonths;
                    limits.weekCyclesString = params.cycleWeeks;
                    limits.execDaysMonthString = params.daysPerMonth;
                    limits.execDaysWeekString = params.daysPerWeek;
                    return limits;
                }
            case stord_change:
                if let params = HBCISepaStandingOrderEditOrder.getParameters(user) {
                    let limits = TransactionLimits();
                    limits.minSetupTime = Int16(params.minPreDays);
                    limits.maxSetupTime = Int16(params.maxPreDays);
                    limits.allowChangeRemoteAccount = params.creditorAccountChangeable;
                    limits.allowChangeRemoteName = params.creditorChangeable;
                    limits.allowChangeValue = params.amountChangeable;
                    limits.allowChangePurpose = params.usageChangeable;
                    limits.allowChangeFirstExecDate = params.firstExecChangeable;
                    limits.allowChangePeriod = params.timeunitChangeable;
                    limits.allowChangeCycle = params.cycleChangeable;
                    limits.allowChangeExecDay = params.execDayChangeable;
                    limits.allowChangeLastExecDate = params.lastExecChangeable;
                    limits.monthCyclesString = params.cycleMonths;
                    limits.execDaysMonthString = params.daysPerMonth;
                    limits.weekCyclesString = params.cycleWeeks;
                    limits.execDaysWeekString = params.daysPerWeek;
                    return limits;
                }
            case stord_delete:
                if let params = HBCISepaStandingOrderDeleteOrder.getParameters(user) {
                    let limits = TransactionLimits();
                    limits.minSetupTime = Int16(params.minPreDays);
                    limits.maxSetupTime = Int16(params.maxPreDays);
                    return limits;
                }
            default: break;
            }
            
        }
        catch {}
        return nil;
    }
    
    func transferLimits(bankUser:BankUser, type:TransferType) ->TransactionLimits? {
        do {
            let user = try HBCIUser(bankUser: bankUser);
            switch type {
            case TransferTypeSEPAScheduled:
                if let params = HBCISepaDatedTransferOrder.getParameters(user) {
                    let limits = TransactionLimits();
                    limits.minSetupTime = Int16(params.minPreDays);
                    limits.maxSetupTime = Int16(params.maxPreDays);
                    return limits;
                }
            default: break;
            }
        }
        catch {}
        return nil;
    }
    
    func supportedBusinessTransactions(bankAccount:BankAccount) ->Array<String>? {
        do {
            let bankUser = bankAccount.defaultBankUser();
            if bankUser == nil {
                logError("No bank user assigned to account \(bankAccount.accountNumber())");
                return nil;
            }
            let user = try HBCIUser(bankUser: bankAccount.defaultBankUser());
            return user.parameters.supportedOrderCodesForAccount(bankAccount.accountNumber(), subNumber: bankAccount.accountSuffix);
        }
        catch {}
        return nil;
    }
    
    func decryptPassportFile(file:String) {
        func getLength(buffer:UnsafeMutablePointer<UInt8>) ->Int {
            var res = 0;
            var p = buffer;
            let x = p.memory;
            res = Int(x) << 8;
            p = p.advancedBy(1);
            res += Int(p.memory);
            return res;
        }
        func read(buffer:UnsafeMutablePointer<UInt8>) ->(String?, UnsafeMutablePointer<UInt8>) {
            var p = buffer;
            if p.memory == 0x74 {
                p = p.advancedBy(1);
                let len = getLength(p);
                p = p.advancedBy(2);
                return (String(bytesNoCopy: p, length: len, encoding: NSISOLatin1StringEncoding, freeWhenDone: false), p.advancedBy(len));
            }
            return (nil, buffer);
        }
        
        let iterations = 987;
        let bytes:[UInt8] = [0x26,0x19,0x38,0xa7,0x99,0xbc,0xf1,0x55];
        let md5Hash = UnsafeMutablePointer<UInt8>.alloc(16);
        let salt = NSData(bytes: bytes, length: 8);
        if let pwData = "PecuniaData".dataUsingEncoding(NSISOLatin1StringEncoding)?.mutableCopy() {
            pwData.appendData(salt);
            
            // apply MD5 hash
            for var j=0; j<iterations; j++ {
                if j==0 {
                    CC_MD5(pwData.bytes, UInt32((pwData as! NSData).length), md5Hash);
                } else {
                    CC_MD5(md5Hash, 16, md5Hash);
                }
            }
            
            guard let enc = NSData(contentsOfFile: file) else {
                md5Hash.dealloc(16);
                logError("Passport file \(file) could not be opened");
                return;
            }
            
            var length = enc.length;
            let plain = UnsafeMutablePointer<UInt8>.alloc(enc.length);
            let rv = CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmDES), 0, md5Hash, kCCKeySizeDES, md5Hash.advancedBy(8), enc.bytes, enc.length, plain, length, &length);
            md5Hash.dealloc(16);
            if rv == 0 {
                var p = UnsafeMutablePointer<UInt8>(plain).advancedBy(4);
                var bankCode, userId, sysId:String?
                
                (_, p) = read(p);
                (bankCode, p) = read(p);
                (_, p) = read(p);
                (userId, p) = read(p);
                (sysId, p) = read(p);
                
                guard bankCode != nil && userId != nil && sysId != nil else {
                    plain.dealloc(enc.length);
                    logError("Passport data is not readable \(bankCode) \(userId) \(sysId)");
                    return;
                }
                
                if let bankUser = BankUser.findUserWithId(userId, bankCode: bankCode) {
                    bankUser.sysId = sysId;
                }
            } else {
                logError("Decryption of \(file) was not successful");
            }
            plain.dealloc(enc.length);
        }
    }
    
    func migrateHBCI4JavaUsers() throws {
        let passportDir = MOAssistant.sharedAssistant().passportDirectory;
        let fm = NSFileManager.defaultManager();
        
        let files = try fm.contentsOfDirectoryAtPath(passportDir);
        for file in files {
            if file.hasSuffix(".dat") {
                let name = file.substringToIndex(file.endIndex.advancedBy(-4));
                let info = name.componentsSeparatedByString("_");
                if info.count == 2 {
                    if let bankUser = BankUser.findUserWithId(info[1], bankCode: info[0]) {
                        if bankUser.sysId == nil {
                            decryptPassportFile(file);
                        }
                    }
                }
                
            }
        }
    }
    
    func getAccountStatementParametersForUser(bankUser:BankUser) ->AccountStatementParameters? {
        do {
            let user = try HBCIUser(bankUser: bankUser);
            if let params = HBCIAccountStatementOrder.getParameters(user) {
                let par = AccountStatementParameters();
                par.canIndex = NSNumber(bool: params.supportsNumber);
                par.needsReceipt = NSNumber(bool: params.needsReceipt);
                var f = "";
                for format in params.formats {
                    f = f + String(format.rawValue);
                }
                par.formats = f;
                return par;
            }
        }
        catch {}
        return nil;
    }
    
    func convertAccountStatement(statement:HBCIAccountStatement) ->AccountStatement {
        let context = MOAssistant.sharedAssistant().context;
        let stat = NSEntityDescription.insertNewObjectForEntityForName("AccountStatement", inManagedObjectContext: context) as! AccountStatement;
        stat.document = statement.booked;
        stat.format = NSNumber(unsignedInt: statement.format.rawValue);
        stat.startDate = statement.startDate;
        stat.endDate = statement.endDate;
        stat.info = statement.closingInfo;
        stat.conditions = statement.conditionInfo;
        stat.advertisement = statement.advertisement;
        stat.iban = statement.iban;
        stat.bic = statement.bic;
        stat.name = statement.name;
        stat.number = statement.number;
        return stat;
    }
    
    func processHBCIDialog(bankUser:BankUser, signingOption:SigningOption? = nil, block:(user:HBCIUser, dialog:HBCIDialog)  throws ->Any?) throws ->Any? {
        let user = try HBCIUser(bankUser: bankUser);
        try setupSecurityMethod(bankUser, user: user);
        defer {
            if user.securityMethod.code == .DDV {
                ChipcardManager.manager.close();
            }
        }
        
        if user.securityMethod.code == .PinTan {
            if let option = signingOption {
                user.tanMethod = option.tanMethod;
                user.tanMediumName = option.tanMediumName;
            } else {
                user.tanMethod = user.parameters.getTanMethods().first?.secfunc;
            }
            
            // get PIN
            let request = AuthRequest();
            user.pin = request.getPin(user.bankCode, userId: user.userId);
        }
        
        let dialog = try HBCIDialog(user: user);
        guard let result = try dialog.dialogInit() else {
            logError("Could not initialize dialog for user \(user.userId)");
            throw NSError.errorWithMsg(msgId: "2011", params: user.userId);
        }
        
        if result.isOk() {
            defer {
                dialog.dialogEnd();
            }
            
            return try block(user: user, dialog: dialog);
        } else {
            logError("Could not initialize dialog for user \(user.userId), result was not ok");
            throw NSError.errorWithMsg(msgId: "2012", params: user.userId);
        }
    }
    
    func getAccountStatement(number:Int, year:Int, bankAccount:BankAccount) ->AccountStatement? {
        guard let bankUser = bankAccount.defaultBankUser() else {
            logError("Skip account \(bankAccount.accountNumber()), no user found");
            return nil;
        }
        
        do {
            return try processHBCIDialog(bankUser) {user, dialog in
                guard let msg = HBCICustomMessage.newInstance(dialog) else {
                    logError("Failed to create HBCI message");
                    throw NSError.errorWithMsg(msgId: "2007");
                }
                
                let account = HBCIAccount(account: bankAccount);
                if let order = HBCIAccountStatementOrder(message: msg, account: account) {
                    order.number = number;
                    order.year = year;
                    
                    // which format?
                    guard let params = HBCIAccountStatementOrder.getParameters(user) else {
                        logError("AccountStatement: user parameters not found");
                        return nil;
                    }
                    
                    if params.formats.contains(HBCIAccountStatementFormat.PDF) {
                        order.format = HBCIAccountStatementFormat.PDF;
                    } else {
                        if params.formats.contains(HBCIAccountStatementFormat.MT940) {
                            order.format = HBCIAccountStatementFormat.MT940;
                        } else {
                            logError("AccountStatement: format not supported");
                            return nil;
                        }
                    }
                    
                    order.enqueue();
                    guard msg.orders.count > 0 else {
                        return nil;
                    }
                    if try msg.send() {
                        if let stat = order.statements.first {
                            return self.convertAccountStatement(stat);
                        }
                    } else {
                        logError("Failed to get account statement for account \(account.number)");
                        return nil;
                    }
                }
                return nil;
                } as? AccountStatement;
        }
        catch HBCIError.UserAbort {
            // do nothing
            return nil;
        }
        catch {}
        return nil;
    }
    
}
