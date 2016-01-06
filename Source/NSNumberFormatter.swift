// Copyright (c) 2016, Pecunia Project. All rights reserved.
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

// A formatter that includes settings for all standard money labels in Pecunia.
// This class is used like a singleton (or rather 2 singletons).
public class PecuniaMoneyFormatter : NSNumberFormatter {

    private var blendFactor: CGFloat = 1;
    private var useWhite: Bool = false;

    init(whiteStyle: Bool, blend: CGFloat = 1) {
        blendFactor = blend;
        useWhite = whiteStyle;

        super.init();
        formatterBehavior = .Behavior10_4;
        numberStyle = .CurrencyStyle;
        locale = NSLocale.currentLocale();

        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "colors", options: .Initial, context: nil);
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
            if keyPath == "colors" {
                updateColors();
                return;
            }

            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context);
    }

    private func updateColors() {

        if useWhite { // White style is never blended.
            textAttributesForPositiveValues = [NSForegroundColorAttributeName: NSColor.whiteColor()];
            textAttributesForNegativeValues = [NSForegroundColorAttributeName: NSColor.whiteColor()];
        } else {
            textAttributesForPositiveValues = [NSForegroundColorAttributeName: NSColor.applicationColorForKey("Positive Cash").colorWithAlphaComponent(blendFactor)];
            textAttributesForNegativeValues = [NSForegroundColorAttributeName: NSColor.applicationColorForKey("Negative Cash").colorWithAlphaComponent(blendFactor)];
        }
    }
}

extension NSNumberFormatter {
    struct Shared {
        static let moneyFormatter = PecuniaMoneyFormatter(whiteStyle: false); // Application colors for +/- values.
        static let moneyBlendedFormatter = PecuniaMoneyFormatter(whiteStyle: false, blend: 0.4); // Like above but for e.g. disabled entries.
        static let moneyWhiteFormatter = PecuniaMoneyFormatter(whiteStyle: true); // White style (e.g. for selected entries).
    }

    public static func sharedFormatter(selected: Bool, blended: Bool = false) -> PecuniaMoneyFormatter {
        if selected {
            return Shared.moneyWhiteFormatter;
        } else {
            if blended {
                return Shared.moneyBlendedFormatter;
            } else {
                return Shared.moneyFormatter;
            }
        }
    }
}