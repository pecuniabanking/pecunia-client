//
//  ChipTanWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class FlickerView;

@interface ChipTanWindowController : NSWindowController {
    IBOutlet NSTextView  *messageView;
    IBOutlet NSTextField *tanField;
    IBOutlet NSTextField *secureTanField;
    IBOutlet FlickerView *flickerView;
    IBOutlet NSSlider    *sizeSlider;
    IBOutlet NSSlider    *frequencySlider;

    char       *bitString;
    int        frequency;
    NSUInteger currentCode;
    int        clock;
    NSUInteger codeLen;
    NSString   *tan;
    NSTimer    *timer;
    NSString   *message;

}

@property (nonatomic, copy) NSString *tan;


- (id)initWithCode: (NSString *)flickerCode message: (NSString *)msg;

- (IBAction)ok: (id)sender;
- (IBAction)cancel: (id)sender;
- (IBAction)frequencySliderChanged: (id)sender;
- (IBAction)sizeSliderChanged: (id)sender;


@end
