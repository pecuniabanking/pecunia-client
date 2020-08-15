//
//  AccountMergeWindowController.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 12.08.20.
//  Copyright © 2020 Frank Emminghaus. All rights reserved.
//

import Foundation

class AccountMergeWindowController : NSWindowController {
    @IBOutlet var sourceAccounts: NSArrayController!
    @IBOutlet var targetAccounts: NSArrayController!
    @IBOutlet var context: NSManagedObjectContext!
        
    convenience init() {
        self.init(windowNibName: "AccountMergeWindow");
        self.context = MOAssistant.shared().context;
    }
    
    @IBAction override func cancelOperation(_ sender: Any?) {

        self.close();
        NSApp.stopModal(withCode: NSApplication.ModalResponse.cancel);
    }
    
    @IBAction func ok( sender: Any?) {
        guard let sourceAccount = sourceAccounts.selectedObjects.first as? BankAccount else {
            return;
        }
        
        guard let targetAccount = targetAccounts.selectedObjects.first as? BankAccount else {
            return;
        }
        
        let alert = NSAlert();
        alert.alertStyle = NSAlert.Style.critical;
        let msg = String(format: NSLocalizedString("AP2200", comment: ""), sourceAccount.localAccountName, targetAccount.localAccountName, MOAssistant.shared()?.pecuniaFileURL.path ?? "<unbekannt>");
        alert.messageText = NSLocalizedString("AP38", comment: "");
        alert.informativeText = msg;
        alert.addButton(withTitle: NSLocalizedString("AP2", comment: "Cancel"));
        alert.addButton(withTitle: NSLocalizedString("AP36", comment: "Continue"));
        let result = alert.runModal();
        if result == NSApplication.ModalResponse.alertFirstButtonReturn {
            return;
        }
        targetAccount.moveStatements(from: sourceAccount);
        
        self.close();
        NSApp.stopModal(withCode: NSApplication.ModalResponse.OK);

    }

}
