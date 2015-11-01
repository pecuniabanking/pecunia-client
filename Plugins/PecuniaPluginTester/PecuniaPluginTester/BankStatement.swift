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

// Mockup code created from the same BankStatement class in Pecunia.

@objc class BankStatement : NSObject {
  var isPreliminary: Bool = false;
  var date: NSDate? = nil;
  var valutaDate: NSDate? = nil;
  var value: NSDecimalNumber? = nil;
  var origValue: NSDecimalNumber? = nil;
  var purpose: String? = nil;

  static func createTemporary() -> BankStatement {
    return BankStatement();
  }

  // Due to conflicts with the member "value" and NSObject we cannot make our mock class
  // derive from NSObject. However that requires to explicitly implement setValue:forObject, which
  // is used by PluginWorker explicitly, again due to the value conflict.
   override func setValue(value: AnyObject?, forKey key: String) {
    if key == "value" {
      if let number = value as? NSDecimalNumber {
        self.value = number;
      }
    }
  }
}

// Need to make NSDate comparable as we will sort statement arrays by date.
public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
  return lhs === rhs || lhs.compare(rhs) == .OrderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
  return lhs.compare(rhs) == .OrderedAscending
}

extension NSDate: Comparable { }
