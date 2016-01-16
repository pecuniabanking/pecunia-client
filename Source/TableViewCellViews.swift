/**
 * Copyright (c) 2015, 2016, Pecunia Project. All rights reserved.
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

 // Implements a number of cell views used in table and outline views to implement our customizable user interface.

import Foundation

// The base class for all outline + table views.
public class StandardTableCellView : NSTableCellView {

    var blendValue: CGFloat = 1; // An alpha value for text colors.
    var defaultTextColors = [NSTextField: NSColor]();

    public required init?(coder aCoder: NSCoder) {
        super.init(coder: aCoder);
        collectDefaultColors();
        updateColors();
    }

    // In order to be able to return to the designed text colors we need to keep them somewhere.
    func collectDefaultColors() {
        func collectDefaultColorsFromView(view: NSView) {
            for child in view.subviews {
                if let field = child as? NSTextField {
                    if field.formatter == nil {
                        defaultTextColors[field] = field.textColor;
                    }
                } else {
                    collectDefaultColorsFromView(child);
                }
            }
        }
        collectDefaultColorsFromView(self);
    }

    // Called on setup or selection changes.
    func updateColors() {

        // We apply some some special colors here depending on the identifier, which serves therefore
        // a bit like a markup holder. This way we don't need to handle each label individually.
        func updateSubviewColors(view: NSView) {
            for child in view.subviews {
                if let field = child as? NSTextField {
                    if let formatter = formatterForField(field) {
                        field.formatter = formatter;
                    } else {
                        var color: NSColor!;
                        if backgroundStyle == .Dark {
                            // Selected style.
                            color = NSColor.whiteColor();
                        } else {
                            if let identifier = field.identifier where identifier.hasPrefix("pale") {
                                color = NSColor.applicationColorForKey("Pale Text").colorWithAlphaComponent(blendValue);
                            } else {
                                if let defaultColor = defaultTextColors[field] {
                                    color = defaultColor.colorWithAlphaComponent(blendValue);
                                }
                            }
                        }
                        if field.stringValue.characters.count > 0 {
                            field.attributedStringValue = NSAttributedString(string: field.stringValue, attributes: [NSForegroundColorAttributeName: color]);
                        } else {
                            field.textColor = color;
                        }
                    }
                } else {
                    if let view = child as? NSImageView, name = view.image?.name() {
                        if backgroundStyle == .Dark {
                            // Try replacing the image with a selected variant if one exists.
                            if !name.hasSuffix("-selected") {
                                if let selectedImage = NSImage(named: name + "-selected") {
                                    view.image = selectedImage;
                                }
                            }
                        } else {
                            // Try restoring the unselected image, if one exists.
                            if name.hasSuffix("-selected") {
                                let index = name.endIndex.advancedBy(-"-selected".characters.count);
                                if let normalImage = NSImage(named: name.substringToIndex(index)) {
                                    view.image = normalImage;
                                }
                            }
                        }
                    }
                }

            }

        }
        updateSubviewColors(self);
    }

    // Descendants might return a formatter here.
    func formatterForField(field: NSTextField) -> NSNumberFormatter? {
        return nil;
    }

    // We have to listen to background changes (which indicate if a row gets selected or unselected) to
    // recrecreate the automatic behavior of the cell view text color changes, which we overruled by
    // applying own colors.
    public override var backgroundStyle: NSBackgroundStyle {
        didSet {
            if oldValue != backgroundStyle {
                updateColors();
            }
        }
    }
}

// A specialized cell view class for all outline + table views that is used if number labels exist that must be formatted.
public class NumberTableCellView : StandardTableCellView {

    override func formatterForField(field: NSTextField) -> NSNumberFormatter? {
        // Only return a pecunia formatter for fields that have already a formatter set
        // (either a previously set pecunia formatter or the default one from the xib).
        if let formatter = field.formatter where formatter.isKindOfClass(NSNumberFormatter) {
            return NSNumberFormatter.sharedFormatter(backgroundStyle == .Dark, blended: blendValue != 1);
        }
        return super.formatterForField(field);
    }
}

// A specialized cell view class for all table views that show a statement entry with various field types,
// including date + number types.
public class StatementTableCellView : NumberTableCellView {

    @IBOutlet var separator: NSBox?;
    @IBOutlet var tagView: TagView?;

    var statementTags = NSArrayController();
    
    public override func awakeFromNib() {
        super.awakeFromNib();

        //tagView?.datasource = statementTags;
        tagView?.defaultFont = PreferenceController.mainFontOfSize(11, bold: false);
        tagView?.canCreateNewTags = false;
    }

    public override var objectValue: AnyObject? {
        didSet {
            statementTags.content = objectValue?.statement??.tags;

            if let assignment = objectValue as? StatCatAssignment, preliminary = assignment.statement.isPreliminary {
                blendValue = preliminary.boolValue ? 0.4 : 1;
            } else {
                blendValue = 1;
            }
            updateColors();
        }
    }

    public override var backgroundStyle: NSBackgroundStyle {
        didSet {
            if oldValue != backgroundStyle {
                if backgroundStyle == .Light {
                    separator?.borderColor = NSColor(calibratedWhite: 0.4, alpha: 1);
                } else {
                    separator?.borderColor = NSColor.whiteColor();
                }
            }
        }
    }
}

// Another special cell for the catgory tree.
public class CategoryTableCellView : NumberTableCellView {
    @IBOutlet weak public var colorWellWidthConstraint: NSLayoutConstraint?;

    public override func awakeFromNib() {
        let userDefaults = NSUserDefaults.standardUserDefaults();
        userDefaults.addObserver(self, forKeyPath: "showCatColorsInTree", options: NSKeyValueObservingOptions.Initial,
            context: nil);
    }

    deinit {
        let userDefaults = NSUserDefaults.standardUserDefaults();
        userDefaults.removeObserver(self, forKeyPath: "showCatColorsInTree");
    }

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
            if keyPath == "showCatColorsInTree" {
                if NSUserDefaults.standardUserDefaults().boolForKey("showCatColorsInTree") {
                    colorWellWidthConstraint!.constant = 13;
                } else {
                    colorWellWidthConstraint!.constant = 0;
                }
                return;
            }

            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context);
    }

    public override var objectValue: AnyObject? {
        didSet {
            if let category = objectValue as? BankingCategory {
                blendValue = category.noCatRep.boolValue ? 0.4 : 1;
            } else {
                blendValue = 1;
            }
            updateColors();
        }
    }
}

public class BadgeCellView : StandardTableCellView {
    @IBOutlet weak public var badge: NSButton?;

    public override func awakeFromNib() {
    }

    deinit {
        objectValue?.removeObserver(self, forKeyPath: "unreadEntries");
    }

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
            if keyPath == "unreadEntries" {
                if let value = objectValue?.valueForKey("unreadEntries") {
                    badge?.hidden = value.intValue == 0;
                } else {
                    badge?.hidden = true;
                }
                return;
            }

            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context);
    }

    public override var objectValue: AnyObject? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: "unreadEntries");
            objectValue?.addObserver(self, forKeyPath: "unreadEntries", options: .Initial, context: nil);
        }
    }
}
