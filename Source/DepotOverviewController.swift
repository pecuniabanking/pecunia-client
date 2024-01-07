//
//  DepotOverviewController.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 27.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

import Foundation

@objc class DepotOverviewController : NSObject, PecuniaSectionItem, NSTableViewDelegate {
    var selectedCategory: BankingCategory! {
        set {
            if newValue.isBankAccount() {
                if let account = currentAccount {
                    account.removeObserver(self, forKeyPath: "depotValueEntry");
                }
                
                if let account = newValue as? BankAccount {
                    account.addObserver(self, forKeyPath: "depotValueEntry", options: NSKeyValueObservingOptions.initial, context: nil);
                    currentAccount = account;
                    
                    entryController.content = account.depotValueEntry;
                    
                    if let entry = account.depotValueEntry {
                        if entry.depotChange() < 0 {
                            totalChangeField.textColor = NSColor.init(red: 0.7, green: 0, blue: 0, alpha: 1.0);
                            totalChangeTextField.stringValue = "Verlust";
                            totalChangeTextField.textColor = NSColor.init(red: 0.7, green: 0, blue: 0, alpha: 1.0);
                        } else {
                            totalChangeField.textColor = NSColor.init(red: 0, green: 0.5, blue: 0, alpha: 1.0);
                            totalChangeTextField.stringValue = "Gewinn";
                            totalChangeTextField.textColor = NSColor.init(red: 0, green: 0.5, blue: 0, alpha: 1.0);
                        }
                    }
                }
            }
        }
        get {
            return self.category;
        }
    }
    var category:BankingCategory!
    var currentAccount:BankAccount?
    
    @IBOutlet var entryController:NSObjectController!
    @IBOutlet var instrumentsController:NSArrayController!
    @IBOutlet var context:NSManagedObjectContext!
    @IBOutlet var mainView: NSView!
    @IBOutlet var totalChangeField:NSTextField!
    @IBOutlet var totalChangeTextField:NSTextField!
    
    override func awakeFromNib() {
        self.context = MOAssistant.shared().context;
        entryController.managedObjectContext = self.context;
        instrumentsController.managedObjectContext = self.context;
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "depotValueEntry" {
            if let account = object as? BankAccount {
                if let entry = account.depotValueEntry {
                    entryController.content = entry;
                    
                    if entry.depotChange() < 0 {
                        totalChangeField.textColor = NSColor.init(red: 0.7, green: 0, blue: 0, alpha: 1.0);
                        totalChangeTextField.stringValue = "Verlust";
                        totalChangeTextField.textColor = NSColor.init(red: 0.7, green: 0, blue: 0, alpha: 1.0);
                    } else {
                        totalChangeField.textColor = NSColor.init(red: 0, green: 0.5, blue: 0, alpha: 1.0);
                        totalChangeTextField.stringValue = "Gewinn";
                        totalChangeTextField.textColor = NSColor.init(red: 0, green: 0.5, blue: 0, alpha: 1.0);
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        
        if let instruments = instrumentsController.arrangedObjects as? [Instrument] {
            if let identifier = tableColumn?.identifier {
                if identifier.rawValue == "percentChange" {
                    if let cell = cell as? NSTextFieldCell {
                        if tableView.isRowSelected(row) {
                            cell.textColor = NSColor.white;
                            return;
                        }
                        if instruments[row].percentChange().isNegative() {
                            cell.textColor = NSColor.init(red: 0.7, green: 0, blue: 0, alpha: 1.0);
                        } else {
                            cell.textColor = NSColor.init(red: 0, green: 0.5, blue: 0, alpha: 1.0);
                        }
                    }
                }
                if identifier.rawValue == "valueChange" {
                    if let cell = cell as? NSTextFieldCell {
                        if tableView.isRowSelected(row) {
                            cell.textColor = NSColor.white;
                            return;
                        }
                        if instruments[row].valueChange().isNegative() {
                            cell.textColor = NSColor.init(red: 0.7, green: 0, blue: 0, alpha: 1.0);
                        } else {
                            cell.textColor = NSColor.init(red: 0, green: 0.5, blue: 0, alpha: 1.0);
                        }
                    }
                }
            }

        }
    }
    
    func activate() {
    }

    func deactivate() {
        
    }
    
    func setTimeRangeFrom(_ from: ShortDate!, to: ShortDate!) {
        
    }
    
    func print() {
        
    }
    
    func terminate() {
        
    }

}
