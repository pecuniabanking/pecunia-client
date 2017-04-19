//
//  BankMessageWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 13.08.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BankMessageWindowController : NSWindowController {
}

@property(nonatomic, retain) IBOutlet NSTextView *textView;
@property(nonatomic, retain) IBOutlet NSAttributedString *content;


@end
