//
//  DepotOverviewController.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 27.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

import Foundation

@objc class DepotOverviewController : NSObject, PecuniaSectionItem {
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
                    /*
                    if let entry = account.depotValueEntry {
                        entryController.content = entry;
                    } else {
                        entryController.content = nil;
                    }
                    */
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
