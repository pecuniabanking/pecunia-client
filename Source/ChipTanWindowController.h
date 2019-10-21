/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

@property (nonatomic, copy)     NSString *tan;
@property (nonatomic, retain)   NSString *userMessage;


- (id)initWithCode: (NSString *)flickerCode message: (NSString *)msg userName: (NSString *)name;

- (IBAction)ok: (id)sender;
- (IBAction)cancel: (id)sender;
- (IBAction)frequencySliderChanged: (id)sender;
- (IBAction)sizeSliderChanged: (id)sender;


@end
