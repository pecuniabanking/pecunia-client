/**
 * Copyright (c) 2015, Pecunia Project. All rights reserved.
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

// Mockup code created from the same BankQueryResult class in Pecunia.

@objc enum BankQueryType: Int {
  case BankStatement;
  case CreditCard;
  case StandingOrder;
}

@objc class BankQueryResult : NSObject {
  var type: BankQueryType = .BankStatement;
  var ccNumber: String?;
  var lastSettleDate: NSDate?;
  var balance: NSNumber?;
  var oldBalance: NSNumber?;
  var statements: [BankStatement] = [];
  var standingOrders: [StandingOrder] = [];
  var account: BankAccount?;

}
