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

 // Implements the functionality of the main statements list (table views) used in many places.

import Foundation

@objc public enum StatementMenuAction: Int {
    case ShowDetails
    case AddStatement
    case SplitStatement
    case DeleteStatement
    case MarkRead
    case MarkUnread
    case StartTransfer
    case CreateTemplate
}

class DetailsPopover : NSPopover {
    internal var wantClose: Bool = false;

    @IBAction internal override func performClose(sender: AnyObject?) {
        wantClose = true;
        super.performClose(sender);
    }
}

var dentSize: CGFloat = 4;

public class StatementsTableRowView : NSTableRowView {

    static var gradientSelected: NSGradient!;
    static var gradientPaleSelected: NSGradient!;
    static var gradientInactive: NSGradient!;

    public class func updateGradients() {
        gradientSelected = NSGradient(colorsAndLocations:
            (NSColor.applicationColorForKey("Selection Gradient (low)"), 1),
            (NSColor.applicationColorForKey("Selection Gradient (high)"), 0)
        );

        gradientPaleSelected = NSGradient(colorsAndLocations:
            (NSColor.applicationColorForKey("Selection Gradient (low)").colorWithAlphaComponent(0.5), 1),
            (NSColor.applicationColorForKey("Selection Gradient (high)").colorWithAlphaComponent(0.5), 0)
        );

        gradientInactive = NSGradient(colorsAndLocations:
            (NSColor.secondarySelectedControlColor(), 1),
            (NSColor.secondarySelectedControlColor(), 0)
        );
    }

    public override func drawBackgroundInRect(dirtyRect: NSRect) {
        if let cellView = viewAtColumn(0) as? NSTableCellView, assignment = cellView.objectValue as? StatCatAssignment, context = NSGraphicsContext.currentContext() {
            // Old style gradient drawing for unassigned and new statements.
            let defaults = NSUserDefaults.standardUserDefaults();

            var preliminary: Bool = false;
            var new: Bool = false;
            var nassValue: NSDecimalNumber = NSDecimalNumber.zero();
            if let statement = assignment.statement {
                if let isPreliminary = statement.isPreliminary {
                    preliminary = isPreliminary.boolValue;
                }

                if let isNew = statement.isNew {
                    new = isNew.boolValue;
                }
                nassValue = statement.nassValue;
            }

            let drawNotAssignedGradient = !preliminary && defaults.boolForKey("markNAStatements");
            let drawNewStatementsGradient = !preliminary && defaults.boolForKey("markNewStatements");

            let hasUnassignedValue = nassValue != NSDecimalNumber.zero();

            context.saveGraphicsState();

            if let category = assignment.category, categoryColor = category.categoryColor {
                categoryColor.set();
                var colorRect = bounds;
                colorRect.size.width = 3;
                NSBezierPath.fillRect(colorRect);
            }

            var gradientRect = bounds;
            gradientRect.origin.x += 3;
            gradientRect.size.width -= 3;
            let path = NSBezierPath(rect: gradientRect);
            if !selected {
                if !preliminary {
                    if hasUnassignedValue && drawNotAssignedGradient {
                        let color = NSColor.applicationColorForKey("Uncategorized Transfer");
                        if let gradient = NSGradient(colorsAndLocations: (NSColor.whiteColor(), -0.1), (color, 1.1)) {
                            gradient.drawInBezierPath(path, angle: 90.0);
                        }
                    }
                    if new && drawNewStatementsGradient {
                        let color = NSColor.applicationColorForKey("Unread Transfer");
                        if let gradient = NSGradient(colorsAndLocations: (NSColor.whiteColor(), -0.1), (color, 1.1)) {
                            gradient.drawInBezierPath(path, angle: 90.0);
                        }
                    }
                } else {
                    NSColor(calibratedWhite: 0.5, alpha: 0.25).set();
                    path.fill();
                }
            }

            context.restoreGraphicsState();
        }
    }

    public override func drawSelectionInRect(dirtyRect: NSRect) {
        if let cellView = viewAtColumn(0) as? NSTableCellView, assignment = cellView.objectValue as? StatCatAssignment,
            context = NSGraphicsContext.currentContext() {

            var preliminary: Bool = false;
            if let statement = assignment.statement, isPreliminary = statement.isPreliminary {
                preliminary = isPreliminary.boolValue;
            }
                
            context.saveGraphicsState();

            let bounds = self.bounds;
            let path = NSBezierPath();

            path.moveToPoint(NSMakePoint(bounds.origin.x + 7, bounds.origin.y));
            path.lineToPoint(NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y));
            path.lineToPoint(NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height));
            path.lineToPoint(NSMakePoint(bounds.origin.x + 7, bounds.origin.y + bounds.size.height));

            // Add a number of dents (triangles) to the left side of the path. Since our height might not be a multiple
            // of the dent height we distribute the remaining pixels to the first and last dent.
            var y = bounds.origin.y + bounds.size.height - 0.5;
            let x = bounds.origin.x + 7.5;
            let dentCount = Int(bounds.size.height / dentSize);
            if dentCount > 0 {
                var remaining = bounds.size.height - dentSize * CGFloat(dentCount);

                var dentHeight = dentSize + CGFloat(remaining / 2);
                remaining -= remaining / 2;

                // First dent.
                path.lineToPoint(NSMakePoint(x + dentSize, y - dentHeight / 2));
                path.lineToPoint(NSMakePoint(x, y - dentHeight));
                y -= dentHeight;

                // Intermediate dents.
                for (var i = 1; i < dentCount - 1; i++) {
                    path.lineToPoint(NSMakePoint(x + dentSize, y - dentSize / 2));
                    path.lineToPoint(NSMakePoint(x, y - dentSize));
                    y -= dentSize;
                }

                // Last dent.
                dentHeight = dentSize + remaining;
                path.lineToPoint(NSMakePoint(x + dentSize, y - dentHeight / 2));
                path.lineToPoint(NSMakePoint(x, y - dentHeight));

                if (!emphasized) {
                    StatementsTableRowView.gradientInactive.drawInBezierPath(path, angle: 90.0);
                } else {
                    if (preliminary) {
                        StatementsTableRowView.gradientPaleSelected.drawInBezierPath(path, angle: 90.0);
                    } else {
                        StatementsTableRowView.gradientSelected.drawInBezierPath(path, angle: 90.0);
                    }
                }
            }

            context.restoreGraphicsState();
        }
    }
}

public class StatementsTable: NSTableView, NSPopoverDelegate {

    var detailsPopover: DetailsPopover!;
    var detailsPopoverController: NSViewController!;
    var detailsView: DetailsView!;
    var positionAnimation: PopoverAnimation!;

    var popoverWillOpen: Bool = false;

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect);
        setup();
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder);
        setup();
    }

    private func setup() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setNeedsDisplay",
            name: WordMapping.pecuniaWordsLoadedNotification, object: nil);
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "colors",
            options: NSKeyValueObservingOptions.Initial, context: nil);

        detailsPopoverController = NSViewController(nibName: "StatementDetails", bundle: nil);
        detailsView = detailsPopoverController.view as! DetailsView;
        detailsView.owner = self;

        detailsPopover = DetailsPopover();
        detailsPopover.contentViewController = detailsPopoverController;
        detailsPopover.behavior = .Semitransient;
        detailsPopover.animates = true;
        detailsPopover.delegate = self;
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "colors");
    }

    public override func dragImageForRowsWithIndexes(dragRows: NSIndexSet, tableColumns: [NSTableColumn],
        event dragEvent: NSEvent, offset dragImageOffset: NSPointPointer) -> NSImage {
            selectRowIndexes(dragRows, byExtendingSelection: false);
            if let dragImage = NSImage(named: (dragRows.count == 1) ? "statement-drag-single" : "statement-drag-multi") {
                dragImageOffset.memory.x = dragImage.size.width / 2 + 4;
                dragImageOffset.memory.y = -(dragImage.size.height / 2 + 4);
                return dragImage;
            }
        return super.dragImageForRowsWithIndexes(dragRows, tableColumns: tableColumns, event: dragEvent, offset: dragImageOffset);
    }

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
            if keyPath == "colors" {
                StatementsTableRowView.updateGradients();
                setNeedsDisplay();
                return;
            }

            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context);
    }
    
    // MARK: - Popover handling

    public func popoverWillShow(notification: NSNotification) {
        popoverWillOpen = true;
    }

    public func popoverDidShow(notification: NSNotification) {
        detailsPopover.wantClose = false;
        popoverWillOpen = false;
    }

    public func popoverShouldClose(popover: NSPopover) -> Bool {
        var allowClose = true;

        if (!detailsPopover.wantClose) {
            // Lets see if the mouse is over the popover ...
            let globalLocation = NSMakeRect(NSEvent.mouseLocation().x, NSEvent.mouseLocation().y, 0, 0);
            let windowLocation = popover.contentViewController!.view.window!.convertRectFromScreen(globalLocation);
            let viewLocation = popover.contentViewController!.view.convertPoint(windowLocation.origin, fromView: nil);
            if NSPointInRect(viewLocation, popover.contentViewController!.view.bounds) {
                allowClose = false;
            }
        }
        return allowClose;
    }

    private func popoverRect() -> NSRect {
        var rect: NSRect;
        if clickedRow > -1 && !selectedRowIndexes.containsIndex(clickedRow) {
            rect = rectOfRow(clickedRow);
        } else {
            rect = rectOfRow(selectedRow);
        }

        // Center over the row.
        let midX = NSMidX(rect);
        let midY = NSMidY(rect);
        rect.origin.x = midX - 5;
        rect.origin.y = midY - 5;
        rect.size = NSMakeSize(10, 10);
        
        return rect;
    }

    public func toggleStatementDetails() {
        if detailsPopover.shown {
            detailsPopover.close();
            return;
        }

        if updateDetails() {
            detailsPopover.showRelativeToRect(popoverRect(), ofView: self, preferredEdge: NSRectEdge.MaxX);
        }
    }

    private func updatePopoverPosition() {
        if detailsPopover.shown {
            let rect = popoverRect();
            if NSIntersectsRect(bounds, rect) {
                detailsPopover.positioningRect = rect;
            } else {
                detailsPopover.close();
            }
        }
    }

    private func updateDetails() -> Bool {
        let row = (clickedRow == -1 || selectedRowIndexes.containsIndex(clickedRow)) ? selectedRow : clickedRow;
        if row == -1 {
            return false;
        }

        if let view = viewAtColumn(0, row: row, makeIfNecessary: true) as? NSTableCellView {
            detailsView.representedObject = view.objectValue;
        }
        return true;
    }

    public override func resignFirstResponder() -> Bool {
        if (popoverWillOpen) {
            return false;
        }
        return true;
    }

    public override func keyDown(theEvent: NSEvent) {
        super.keyDown(theEvent);
        
        switch (theEvent.keyCode) {
        case 49 where !theEvent.ARepeat: // Space char.
            toggleStatementDetails();

        case 125, 126 where !theEvent.ARepeat:
            if (detailsPopover.shown) {
                updateDetails();
                updatePopoverPosition();
            }

        default:
            break;
        }
    }

    public override func mouseDown(theEvent: NSEvent) {
        // A mouse down will implicitly hide the popover in semi-transient mode, so temporarily
        // take over full control of the visibility.
        if detailsPopover.shown {
            detailsPopover.behavior = .ApplicationDefined;
        } else {
            if theEvent.clickCount > 1 && !detailsPopover.shown {
                toggleStatementDetails();
            }
        }
        super.mouseDown(theEvent);

        if detailsPopover.shown {
            detailsPopover.behavior = .Semitransient;

            if updateDetails() {
                updatePopoverPosition();
            } else {
                detailsPopover.close();
            }
        }
    }
}
