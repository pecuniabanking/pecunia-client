//
//  VoPConfirmationWindowController.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 13.09.25.
//  Copyright © 2025 Frank Emminghaus. All rights reserved.
//

import Foundation
import HBCI4Swift

class VoPConfirmationWindowController : NSWindowController {
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet var report: NSAttributedString?
    
    var vopResult: HBCIVoPResult!
    
    init(vopResult: HBCIVoPResult) {
        super.init(window: nil);
        self.vopResult = vopResult;
        
        let rep = NSMutableAttributedString();
        for item in vopResult.items {
            if item.status == HBCIVoPResultStatus.match {
                continue;
            }
            rep.append(NSAttributedString(string: "IBAN: "));
            rep.append(NSAttributedString(string: item.iban));
            rep.append(NSAttributedString(string: "\n"));
            rep.append(NSAttributedString(string: "Angegebener Empfänger: "));
            rep.append(NSAttributedString(string: item.givenName));
            rep.append(NSAttributedString(string: "\n"));
            if let actualName = item.actualName {
                rep.append(NSAttributedString(string: "Korrekter Empfänger: "));
                rep.append(NSAttributedString(string: actualName));
                rep.append(NSAttributedString(string: "\n"));
            }
            switch item.status {
            case .match:
                break;
            case .closeMatch:
                rep.append(NSAttributedString(string: vopResult.textCloseMatch!, attributes: [.foregroundColor: NSColor.red]));
                break;
            case .noMatch:
                rep.append(NSAttributedString(string: vopResult.textNoMatch!, attributes: [.foregroundColor: NSColor.red]));
                break;
            case .notApplicable:
                rep.append(NSAttributedString(string: vopResult.textNA!, attributes: [.foregroundColor: NSColor.red]));
                break;
            case .withMismatches:
                break;
            case .pending:
                break;
            }
            
            rep.append(NSAttributedString(string: "\n"));
        }
        
        self.report = rep;
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var windowNibName: String! {
        return "VoPConfirmationWindow";
    }
    
    @IBAction func ok(_ sender:Any?) {
        NSApp.stopModal(withCode: NSApplication.ModalResponse.OK);
        self.window?.close();
    }
    
    @IBAction func cancel(_ sender:Any?) {
        NSApp.stopModal(withCode: NSApplication.ModalResponse.cancel);
        self.window?.close();
    }

    override func awakeFromNib() {
        self.textView.isEditable = false;
    }
    
}
