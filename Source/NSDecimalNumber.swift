// Copyright (c) 2011, 2015, Pecunia Project. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation; version 2 of the
// License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
// 02110-1301  USA

import Foundation

extension NSDecimalNumber : Comparable {
    fileprivate static var numberHandler: NSDecimalNumberHandler? = nil;
    fileprivate static var outboundHandler: NSDecimalNumberHandler? = nil;
    fileprivate static var roundDownHandler: NSDecimalNumberHandler? = nil;
    fileprivate static let separators = CharacterSet.init(charactersIn: ".,");

    override open class func initialize() {
        super.initialize();

        numberHandler = NSDecimalNumberHandler(roundingMode: .plain, scale: 2,
            raiseOnExactness: true, raiseOnOverflow: true, raiseOnUnderflow: true,
            raiseOnDivideByZero: true);

        outboundHandler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0,
            raiseOnExactness: true, raiseOnOverflow: true, raiseOnUnderflow: true,
            raiseOnDivideByZero: true);

        // Like the default handler, but with round down mode.
        roundDownHandler = NSDecimalNumberHandler(roundingMode: .down, scale: Int16(NSDecimalNoScale),
            raiseOnExactness: false, raiseOnOverflow: true, raiseOnUnderflow: true,
            raiseOnDivideByZero: true);
    }

    // Tries to determine the correct group and decimal separators automatically.
    // In order for that to work we have to apply some heuristics to get the correct format.
    // For simplicity we assume that the number of fractional digits
    // is always 2 and the number of group digits is always 3. This lets us check the first
    // non-digit value from the right side. If that separates only 2 digits it's the decimal
    // separator, otherwise the group separator. Since in financial data we additionally only
    // have 2 separator values (comma and dot, at least in those values Pecunia can deal with),
    // it's easy to continue from that decision.
    class func fromString(_ input: String) -> NSDecimalNumber? {
        let formatter = NumberFormatter();
        formatter.generatesDecimalNumbers = true;

        // Split input by space char in order to strip off potential currency values.
        let values = (input as NSString).components(separatedBy: " ");
        if values.isEmpty {
            return nil;
        }

        if let separatorRange = values[0].rangeOfCharacter(from: separators, options: .backwards) {
            if values[0].distance(from: separatorRange.lowerBound, to: separatorRange.upperBound) == 1 {
            //if separatorRange.count == 1 {
                formatter.usesGroupingSeparator = true;
                formatter.groupingSize = 3;

                // One char separator length is the only one we accept.
                let separator = String(values[0][separatorRange.lowerBound]);
                if values[0].distance(from: separatorRange.lowerBound, to: values[0].endIndex) == 3 {
//                if separatorRange.lowerBound.distanceTo(values[0].endIndex) == 3 {
                    // 2 digits
                    formatter.decimalSeparator = separator;
                    formatter.groupingSeparator = (separator == ".") ? "," : ".";
                } else {
                    formatter.groupingSeparator = separator;
                    formatter.decimalSeparator = (separator == ".") ? "," : ".";
                }
            }
        }

        formatter.maximumFractionDigits = 2;

        var object: AnyObject?;
        var range: NSRange = NSMakeRange(0, input.characters.count);
        do {
            try formatter.getObjectValue(&object, for: input, range: &range);

            if let number = object as? NSDecimalNumber {
                return number;
            }
        } catch {
            // Ignore. We return nil.
        }
        return nil;
    }

    func isNegative() -> Bool {
        // Useful mostly for legacy Obj-C code.
        return self < NSDecimalNumber.zero;
    }

    func abs() -> NSDecimalNumber {
        if self < NSDecimalNumber.zero {
            return -self;
        }
        return self;
    }

    // Returns the number digits of this number (interpreting it in a 10-based system),
    // not counting any fractional parts.
    func numberOfDigits() -> Int {
        var value = abs();

        var result = 0;
        let one = NSDecimalNumber.one;
        while value >= one {
            result += 1;
            value = value.multiplying(byPowerOf10: -1, withBehavior: NSDecimalNumber.roundDownHandler);
        }

        return result;

    }

    // Returns a value whose sign is the same as that of the receiver and whose absolute value is equal
    // or larger such that only the most significant digit is not zero. If the receiver's MSD and the second MSD
    // are smaller than 5 then the result is rounded towards a 5 as the second MSD instead of increasing
    // the MSD.
    // Examples: 12 => 15, 17 => 20, 45 => 50, 61 => 70, 123456 => 150000, -77000 => -80000.
    func roundedToUpperOuter() -> NSDecimalNumber {
        let digits = numberOfDigits();

        var value = self.decimalValue;
        var zero = Decimal(0);
        let isNegative = (NSDecimalCompare(&value, &zero) == .orderedAscending);
        if isNegative {
            var minusOne = Decimal(-1);
            NSDecimalMultiply(&value, &value, &minusOne, .plain);
        }

        var second = value;

        // First determine the most significant digit. That forms our base. But only if the overall
        // value is >= 10.
        var ten = Decimal(10);
        var five = Decimal(5);
        if (NSDecimalCompare(&second, &ten) == .orderedAscending) {
            NSDecimalRound(&value, &value, 1, .up);
        } else {
            NSDecimalRound(&value, &value, -digits + 1, .down);

            // Get the second MSD as this is used to determine where we round to.
            // If the MSD is however 5 or more then we just round that up.
            NSDecimalSubtract(&second, &second, &value, .down);
            NSDecimalMultiplyByPowerOf10(&second, &second, -digits + 2, .down);

            var first = Decimal();
            NSDecimalMultiplyByPowerOf10(&first, &value, -digits + 1, .down);
            let msdIs5Orlarger = NSDecimalCompare(&first, &five) != .orderedAscending;

            // See if the second MSD is below or above 5. In the latter case increase the MSD by one
            // and return this as the rounded value.
            if (msdIs5Orlarger || NSDecimalCompare(&second, &five) == .orderedDescending) {
                var offset = Decimal(1);
                NSDecimalMultiplyByPowerOf10(&offset, &offset, Int16(digits - 1), .down);
                NSDecimalAdd(&value, &value, &offset, .down);
            } else {
                // The second MSD is < 5, so we round it up to 5 and add this to the overall value.
                var offset = Decimal(5);
                NSDecimalMultiplyByPowerOf10(&offset, &offset, Int16(digits - 2), .down);
                NSDecimalAdd(&value, &value, &offset, .down);
            }
        }

        if isNegative {
            var minusOne = Decimal(-1);
            NSDecimalMultiply(&value, &value, &minusOne, .plain);
        }
        
        return NSDecimalNumber(decimal: value);
    }

    func rounded() -> NSDecimalNumber {
        return rounding(accordingToBehavior: NSDecimalNumber.numberHandler);
    }

    func outboundNumber() -> NSDecimalNumber {
        return multiplying(byPowerOf10: 2, withBehavior: NSDecimalNumber.outboundHandler);
    }

}

public func == (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedSame
}

public func < (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedAscending
}

// MARK: - Arithmetic Operators

public prefix func - (value: NSDecimalNumber) -> NSDecimalNumber {
    return value.multiplying(by: NSDecimalNumber(mantissa: 1, exponent: 0, isNegative: true))
}

public func + (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.adding(rhs)
}

public func - (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.subtracting(rhs)
}

public func * (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.multiplying(by: rhs)
}

public func / (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.dividing(by: rhs)
}

public func ^ (lhs: NSDecimalNumber, rhs: Int) -> NSDecimalNumber {
    return lhs.raising(toPower: rhs)
}
