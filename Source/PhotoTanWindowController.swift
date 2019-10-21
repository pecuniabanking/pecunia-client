//
//  PhotoTanWindowController.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 02.03.19.
//  Copyright © 2019 Frank Emminghaus. All rights reserved.
//

import Foundation

class PhotoTanWindowController : NSWindowController {
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var messageView: NSTextView!
    @IBOutlet var tanField: NSTextField!
    @IBOutlet var secureTanField: NSSecureTextField!
    
    var tan:String?
    var image:NSImage?
    var mimeType:String?
    let userMessage:String?
    let message: String?
    
    init(_ code: NSData, message msg: String?, userName: String) {
        message = msg;
        userMessage = String(format: NSLocalizedString("AP184", comment: ""), userName);
        super.init(window: nil);
        parse(code);
    }
    
    func parse(_ data: NSData) {
        let p = data.bytes.assumingMemoryBound(to: UInt8.self);
        let mimeLength = Int(p[0]) * 256 + Int(p[1]);
        let mimeData = NSData(bytes: p.advanced(by: 2), length: mimeLength);
        let imageLength = Int(p[2+mimeLength]) * 256 + Int(p[3+mimeLength]);
        let imageData = NSData(bytes: p.advanced(by: 4+mimeLength), length: imageLength);
        mimeType = String(data: mimeData as Data, encoding: .ascii);
        image = NSImage(data: imageData as Data);
        if image == nil {
            // imageData is not an image - save data
            if let dir = MOAssistant.shared().resourcesDir {
                logInfo("Image could not be extracted from challenge");
                let filePath = dir + "/challenge";
                data.write(toFile: filePath, atomically: true);
                logInfo("Challenge file written to " + filePath);
            } else {
                logInfo("Could not retrieve resources directory");
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var windowNibName: String! {
        return "PhotoTanWindow";
    }
    
    @IBAction func ok(_ sender:Any?) {
        if let tan = tan {
            if tan.length > 0 {
                NSApp.stopModal(withCode: 0);
                self.window?.close();
            }
        }        
    }
    
    @IBAction func cancel(_ sender:Any?) {
        NSApp.stopModal(withCode: 1);
        self.window?.close();
    }
    
    
    
    override func awakeFromNib() {
        if let message = message {
            if let msgString = NSMutableAttributedString(html: message.data(using: .isoLatin1)!, options: [:], documentAttributes: nil) {
                messageView.textStorage?.setAttributedString(msgString);
            }
        }
        
        imageView.image = image;
        
        let defaults = UserDefaults.standard;
        let showTAN = defaults.bool(forKey: "showTAN");
        if showTAN {
            self.window?.makeFirstResponder(tanField);
        } else {
            self.window?.makeFirstResponder(secureTanField);
        }
        
    }
    
    
    
}
