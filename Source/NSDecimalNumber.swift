// Copyright (c) 2011, 2014, Pecunia Project. All rights reserved.
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
    private static var numberHandler: NSDecimalNumberHandler? = nil;
    private static var outboundHandler: NSDecimalNumberHandler? = nil;
    private static var roundDownHandler: NSDecimalNumberHandler? = nil;

    override public class func initialize() {
        super.initialize();

        numberHandler = NSDecimalNumberHandler(roundingMode: .RoundPlain, scale: 2,
            raiseOnExactness: true, raiseOnOverflow: true, raiseOnUnderflow: true,
            raiseOnDivideByZero: true);

        outboundHandler = NSDecimalNumberHandler(roundingMode: .RoundPlain, scale: 0,
            raiseOnExactness: true, raiseOnOverflow: true, raiseOnUnderflow: true,
            raiseOnDivideByZero: true);

        // Like the default handler, but with round down mode.
        roundDownHandler = NSDecimalNumberHandler(roundingMode: .RoundDown, scale: Int16(NSDecimalNoScale),
            raiseOnExactness: false, raiseOnOverflow: true, raiseOnUnderflow: true,
            raiseOnDivideByZero: true);
    }

    func isNegative() -> Bool {
        // Useful mostly for legacy Obj-C code.
        return self < NSDecimalNumber.zero();
    }

    func abs() -> NSDecimalNumber {
        if self < NSDecimalNumber.zero() {
            return -self;
        }
        return self;
    }

    // Returns the number digits of this number (interpreting it in a 10-based system),
    // not counting any fractional parts.
    func numberOfDigits() -> Int {
        var value = abs();

        var result = 0;
        let one = NSDecimalNumber.one();
        while value >= one {
            result++;
            value = value.decimalNumberByMultiplyingByPowerOf10(-1, withBehavior: NSDecimalNumber.roundDownHandler);
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
        var zero = 0.decimalValue;
        let isNegative = (NSDecimalCompare(&value, &zero) == .OrderedAscending);
        if isNegative {
            var minusOne = (-1).decimalValue;
            NSDecimalMultiply(&value, &value, &minusOne, .RoundPlain);
        }

        var second = value;

        // First determine the most significant digit. That forms our base. But only if the overall
        // value is >= 10.
        var ten = 10.decimalValue;
        var five = 5.decimalValue;
        if (NSDecimalCompare(&second, &ten) == .OrderedAscending) {
            NSDecimalRound(&value, &value, 1, .RoundUp);
        } else {
            NSDecimalRound(&value, &value, -digits + 1, .RoundDown);

            // Get the second MSD as this is used to determine where we round to.
            // If the MSD is however 5 or more then we just round that up.
            NSDecimalSubtract(&second, &second, &value, .RoundDown);
            NSDecimalMultiplyByPowerOf10(&second, &second, -digits + 2, .RoundDown);

            var first = NSDecimal();
            NSDecimalMultiplyByPowerOf10(&first, &value, -digits + 1, .RoundDown);
            let msdIs5Orlarger = NSDecimalCompare(&first, &five) != .OrderedAscending;

            // See if the second MSD is below or above 5. In the latter case increase the MSD by one
            // and return this as the rounded value.
            if (msdIs5Orlarger || NSDecimalCompare(&second, &five) == .OrderedDescending) {
                var offset = 1.decimalValue;
                NSDecimalMultiplyByPowerOf10(&offset, &offset, Int16(digits - 1), .RoundDown);
                NSDecimalAdd(&value, &value, &offset, .RoundDown);
            } else {
                // The second MSD is < 5, so we round it up to 5 and add this to the overall value.
                var offset = 5.decimalValue;
                NSDecimalMultiplyByPowerOf10(&offset, &offset, Int16(digits - 2), .RoundDown);
                NSDecimalAdd(&value, &value, &offset, .RoundDown);
            }
        }

        if isNegative {
            var minusOne = (-1).decimalValue;
            NSDecimalMultiply(&value, &value, &minusOne, .RoundPlain);
        }
        
        return NSDecimalNumber(decimal: value);
    }

    func rounded() -> NSDecimalNumber {
        return decimalNumberByRoundingAccordingToBehavior(NSDecimalNumber.numberHandler);
    }

    func outboundNumber() -> NSDecimalNumber {
        return decimalNumberByMultiplyingByPowerOf10(2, withBehavior: NSDecimalNumber.outboundHandler);
    }

}

public func == (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .OrderedSame
}

public func < (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .OrderedAscending
}

// MARK: - Arithmetic Operators

public prefix func - (value: NSDecimalNumber) -> NSDecimalNumber {
    return value.decimalNumberByMultiplyingBy(NSDecimalNumber(mantissa: 1, exponent: 0, isNegative: true))
}

public func + (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.decimalNumberByAdding(rhs)
}

public func - (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.decimalNumberBySubtracting(rhs)
}

public func * (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.decimalNumberByMultiplyingBy(rhs)
}

public func / (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.decimalNumberByDividingBy(rhs)
}

public func ^ (lhs: NSDecimalNumber, rhs: Int) -> NSDecimalNumber {
    return lhs.decimalNumberByRaisingToPower(rhs)
}
