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

#import "LockViewController.h"
#import "AnimationHelper.h"

@interface LockView : NSView

@end

@implementation LockView

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect: (NSRect)dirtyRect
{
    [[NSColor colorWithCalibratedWhite: 0.169 alpha: 1] set];
    NSRectFill(dirtyRect);
}

@end

@interface LockViewController ()
{
    id replacedContent;
    NSWindow *window;   // The window in which the lock view is currently visible.

}

@property (strong) IBOutlet NSTextField *heading;
@property (strong) IBOutlet NSSecureTextField *passwordField;
@property (strong) IBOutlet NSTextField *description;

@end

@implementation LockViewController

+ (instancetype)createController
{
    LockViewController *result = [[LockViewController alloc] initWithNibName: @"LockView" bundle: NSBundle.mainBundle];
    [result loadView];
    result.heading.stringValue = NSLocalizedString(@"AP162", nil);
    result.description.stringValue = NSLocalizedString(@"AP163", nil);
    result.passwordField.delegate = result;

    return result;
}

- (NSString *)password
{
    return self.passwordField.stringValue;
}

/**
 * Replaces the content of the given window by our lockview, but saves the previous content for later restoration.
 */
- (void)showLockViewInWindow: (NSWindow *)targetWindow
{
    window = targetWindow;
    replacedContent = window.contentView;
    window.contentView = self.view;
    self.view.hidden = NO;
    self.passwordField.stringValue = @"12345";
    [[self.view window] makeFirstResponder: self.passwordField];
}

/**
 * Restores the previous content of the window that was set with a previous call to showLockViewInWindow.
 */
- (void)removeLockView
{
    if (replacedContent != nil) {
        window.contentView = replacedContent;
        window = nil;
    }
    self.view.hidden = YES;
}

/**
 * Starts a modal loop for the window in which the lock view is currently displayed. */
- (NSModalResponse)waitForPassword
{
    if (window == nil) {
        return NSModalResponseAbort;
    }

    return [NSApp runModalForWindow: window];
}

- (void)indicateInvalidPassword
{
    [window makeFirstResponder: nil];
    NSBeep();

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath: @"position"];
    [animation setDuration: 0.05];
    [animation setRepeatCount: 4];
    [animation setAutoreverses: YES];
    NSRect frame = self.passwordField.frame;
    [animation setFromValue: [NSValue valueWithPoint: NSMakePoint(NSMinX(frame) - 20.0f, NSMinY(frame))]];
    [animation setToValue:[NSValue valueWithPoint: NSMakePoint(NSMinX(frame) + 20.0f, NSMinY(frame))]];
    animation.delegate = self;
    [self.passwordField.layer addAnimation: animation forKey: @"position"];
}

- (void)animationDidStop: (CAAnimation *)anim finished: (BOOL)flag
{
    [window makeFirstResponder: self.passwordField];
}

- (IBAction)cancel: (id)sender
{
    [NSApp abortModal];
}

- (IBAction)continue: (id)sender
{
    [NSApp stopModalWithCode: NSModalResponseStop];
}

- (void)controlTextDidEndEditing: (NSNotification *)obj
{
    [NSApp stopModalWithCode: NSModalResponseStop];
}

@end
