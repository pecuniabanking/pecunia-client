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
/*
class DetailsPopover : NSPopover {
    internal var wantClose: Bool = false;

    override init() {
        super.init();
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder);
    }

    @IBAction internal override func performClose(sender: AnyObject?) {
        wantClose = true;
        super.performClose(sender);
    }
}
*/
public class StatementsTable: NSTableView, NSPopoverDelegate {

    var detailsPopover: PecuniaPopover!;
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

        detailsPopoverController = NSViewController(nibName: "StatementDetails", bundle: nil);
        detailsView = detailsPopoverController.view as! DetailsView;
        detailsView.owner = self;

        detailsPopover = PecuniaPopover();
        detailsPopover.contentViewController = detailsPopoverController;
        detailsPopover.behavior = .Semitransient;
        detailsPopover.animates = true;
        detailsPopover.delegate = self;
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
            detailsPopover.performClose(nil);
            return;
        }

        updateDetails();
        detailsPopover.showRelativeToRect(popoverRect(), ofView: self, preferredEdge: NSRectEdge.MaxX);
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

    private func updateDetails() {
        let row = (clickedRow == -1 || selectedRowIndexes.containsIndex(clickedRow)) ? selectedRow : clickedRow;
        if let view = viewAtColumn(0, row: row, makeIfNecessary: true) as? NSTableCellView {
            detailsView.representedObject = view.objectValue;
        }
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

            updateDetails();
            updatePopoverPosition();
        }
    }
}
