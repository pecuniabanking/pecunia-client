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

@objc public class BankQueryResult: NSObject {
    dynamic var type: BankQueryType = .BankStatementType;
    dynamic var ccNumber: String?;
    dynamic var lastSettleDate: NSDate?;
    dynamic var balance: NSNumber?;
    dynamic var oldBalance: NSNumber?;
    dynamic var statements: [BankStatement] = [];
    dynamic var standingOrders: [StandingOrder] = [];
    dynamic var account: BankAccount?;
    dynamic var isImport: Bool = false;

    // These values are set by the XML parser and can go when we removed that parser.
    var bankCode: String = "";
    var accountNumber: String = "";
    var accountSuffix: String?;

    override init() {
        super.init();
    }

    /// Factory method to be used in JS. Initializers are not exported to JS.
    /// Since JS doesn't have named parameters, any external parameter names are converted to
    /// camel-case and appended to the function name.
    class func create() -> BankQueryResult {
        return BankQueryResult();
    }

    /// Only used to find a specific result in the HBCIController. Can go when we reworked result
    /// handling there.
    public override func isEqual(object: AnyObject?) -> Bool {
        if let other = object! as? BankQueryResult { // In this specific context is the other object always valid with only an account set.
            if accountNumber == other.account!.accountNumber() && bankCode == other.account!.bankCode {
                    return (accountSuffix == nil && other.account!.accountSuffix == nil) ||
                        (accountSuffix != nil && other.account!.accountSuffix != nil &&
                            accountSuffix == other.account!.accountSuffix);
            }
        }

        return false;
    }

}
