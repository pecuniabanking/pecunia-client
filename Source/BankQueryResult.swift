/**
* Copyright (c) 2009, 2015, Pecunia Project. All rights reserved.
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation; version 2 of the
* License.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
* 02110-1301  USA
*/

import Foundation
import JavaScriptCore

@objc public enum BankQueryType: Int {
    case BankStatementType;
    case StandingOrderType;
}

/// Define JS protocol for the result class so we can use it in our JS plugins.
@objc protocol BankQueryResultJSExport : JSExport {
    var type: BankQueryType { get set };
    var ccNumber: String { get set };
    var lastSettleDate: NSDate { get set };
    var balance: NSNumber { get set };
    var oldBalance: NSNumber { get set };
    var statements: [BankStatement] { get set };
    var standingOrders: [StandingOrder] { get set };
    var account: BankAccount? { get set };
    var isImport: Bool { get set };

    static func create() -> BankQueryResult;
}

@objc public class BankQueryResult: NSObject, BankQueryResultJSExport {
    dynamic var type: BankQueryType;
    dynamic var ccNumber: String;
    dynamic var lastSettleDate: NSDate;
    dynamic var balance: NSNumber;
    dynamic var oldBalance: NSNumber;
    dynamic var statements: [BankStatement];
    dynamic var standingOrders: [StandingOrder];
    dynamic var account: BankAccount?;
    dynamic var isImport: Bool;

    override init() {
        self.type = .BankStatementType;
        ccNumber = "";

        lastSettleDate = NSDate();
        balance = NSDecimalNumber.zero();
        oldBalance = NSDecimalNumber.zero();
        statements = [];
        standingOrders = [];
        account = nil;
        isImport = false;

        super.init();
    }

    /// Factory method to be used in JS. Initializers are not exported to JS.
    /// Since JS doesn't have named parameters, any external parameter names are converted to
    /// camel-case and appended to the function name.
    class func create() -> BankQueryResult {
        return BankQueryResult();
    }

    public override func isEqual(object: AnyObject?) -> Bool {
        if object != nil && account != nil {
            if let other = object! as? BankQueryResult {
                if account!.accountNumber == other.account!.accountNumber &&
                    account!.bankCode == other.account!.bankCode {
                        return (account!.accountSuffix == nil && other.account!.accountSuffix == nil) ||
                            (account!.accountSuffix != nil && other.account!.accountSuffix != nil &&
                                account!.accountSuffix == other.account!.accountSuffix);
                }
            }
        }

        return false;
    }

    func setBankCode(bankCode: String) -> Void {
        account!.bankCode = bankCode;
    }

    func setAccountNumber(accountNumber: String) -> Void {
        account!.accountNumber = accountNumber;
    }
    
}
