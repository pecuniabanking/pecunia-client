/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

#import "WaitViewController.h"
#import "YRKSpinningProgressIndicator.h"

@interface WaitViewController () {
    YRKSpinningProgressIndicator *spinner;
    NSImageView *checkImage;

    IBOutlet NSView *placeHolder;
}

@property (strong) IBOutlet NSTextField *mainMessageField;
@property (strong) IBOutlet NSTextField *detailsMessageField;
@property (strong) IBOutlet NSTextField *titleField;

@end

@implementation WaitViewController

- (NSString *)nibName {
    return @"WaitView";
}

- (void)updateLabels: (NSDictionary *)parameters {
    id title = parameters[@"title"];
    if ([title isKindOfClass: [NSAttributedString class]]) {
        self.titleField.attributedStringValue = title;
    } else {
        NSString *text = [NSString stringWithFormat: @"%@: %@", NSLocalizedString(@"AP401", nil), title];
        self.titleField.attributedStringValue = [[NSAttributedString alloc] initWithString: text];;
    }

    id message = parameters[@"message"];
    if ([message isKindOfClass: [NSAttributedString class]]) {
        self.mainMessageField.attributedStringValue = message;
    } else {
        NSAttributedString *text = [[NSAttributedString alloc] initWithString: message];
        self.mainMessageField.attributedStringValue = text;
    }

    id details = parameters[@"details"];
    if ([details isKindOfClass: [NSAttributedString class]]) {
        self.detailsMessageField.attributedStringValue = details;
    } else {
        NSAttributedString *text = [[NSAttributedString alloc] initWithString: details];
        self.detailsMessageField.attributedStringValue = text;
    }
}

- (void)startWaiting: (NSDictionary *)parameters {
    if (spinner == nil) {
        spinner = [[YRKSpinningProgressIndicator alloc] initWithFrame: placeHolder.bounds];
        spinner.color = NSColor.whiteColor;
        spinner.usesThreadedAnimation = false;
    }
    [checkImage removeFromSuperview];
    if (spinner.superview == nil) {
        [placeHolder addSubview: spinner];
    }

    [self updateLabels: parameters];
    [spinner startAnimation: nil];
}

- (void)markDone: (NSDictionary *)parameters {
    if (checkImage == nil) {
        checkImage = [[NSImageView alloc] initWithFrame: placeHolder.bounds];
        if ([parameters[@"failed"] boolValue]) {
            checkImage.image = [NSImage imageNamed: @"cross-mark"];
        } else {
            checkImage.image = [NSImage imageNamed: @"check-mark"];
        }
    }

    [self updateLabels: parameters];
    [spinner stopAnimation: nil];
    [placeHolder.animator replaceSubview: spinner with: checkImage];
}

@end
