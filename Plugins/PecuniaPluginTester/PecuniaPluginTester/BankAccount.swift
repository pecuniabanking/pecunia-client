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

// Mockup code created from the same BankAccount class in Pecunia.

@objc class BankAccount {
  var accountNumber: String;
  var bankCode: String;

  init (number: String, code: String) {
    accountNumber = number;
    bankCode = code;
  }

  class func findAccountWithNumber(number: String, bankCode code: String) -> BankAccount? {
    return BankAccount(number: number, code: code);
  }
}
