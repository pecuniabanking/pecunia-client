/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

#import "LogController.h"
#import "HBCIController.h"
#import "MessageLog.h"

static LogController *_logController = nil;

@implementation LogController

- (id)init
{
    self = [super initWithWindowNibName: @"LogController"];
    _logController = self;
    messageLog = [MessageLog log];
    isHidden = YES;
    return self;
}

+ (LogController *)logController
{
    if (_logController == nil) {
        _logController = [[LogController alloc] init];
    }
    return _logController;
}

- (void)adjustPopupToLogLevel
{
    NSInteger idx;
    switch (currentLevel) {
        case LogLevel_Error: idx = 0; break;

        case LogLevel_Warning: idx = 1; break;

        case LogLevel_Notice: idx = 2; break;

        case LogLevel_Info: idx = 3; break;

        case LogLevel_Debug: idx = 4; break;

        case LogLevel_Verbous: idx = 5; break;

        default: idx = 2;
    }
    [popUp selectItemAtIndex: idx];
}

- (void)awakeFromNib
{
    [self adjustPopupToLogLevel];
}

- (void)windowDidLoad
{
    //	[popUp selectItemAtIndex:1 ];
}

- (void)windowDidBecomeKey: (NSNotification *)notification
{
    [messageLog registerLogUI: self];
    //[self logLevelChanged: self];
    [self setLogLevel: MessageLog.log.currentLevel];
}

- (void)windowWillClose: (NSNotification *)notification
{
    isHidden = YES;
    [messageLog unregisterLogUI: self];
}

- (void)showWindow: (id)sender
{
    isHidden = NO;
    [super showWindow: sender];
}

- (void)close: (id)sender
{
    [[self window] performClose: self];
}

- (NSColor *)colorForLevel: (LogLevel)level
{
    switch (level) {
        case LogLevel_Error: return [NSColor redColor]; break;

        case LogLevel_Warning: return [NSColor colorWithDeviceRed: 1.0 green: 0.73 blue: 0.0 alpha: 1.0]; break;

        case LogLevel_Notice: return [NSColor colorWithDeviceRed: 0.0 green: 0.54 blue: 0.0 alpha: 1.0]; break;

        case LogLevel_Info: return [NSColor blackColor]; break;

        case LogLevel_Debug:
        case LogLevel_Verbous: return [NSColor darkGrayColor]; break;

        default:
            break;
    }
    return [NSColor blackColor];
}

- (void)addMessage: (NSString *)info withLevel: (LogLevel)level
{
    if (info == nil || [info length] == 0) {
        return;
    }
    if (level > currentLevel) {
        return;
    }
    if (isHidden) {
        if (level <= 1) {
            [self showWindow: self];
            [[self window] orderFront: self];
        } else {
            return;
        }
    }

    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n", info]];
    [s addAttribute: NSForegroundColorAttributeName
              value: [self colorForLevel: level]
              range: NSMakeRange(0, [s length])];
    [[logView textStorage] appendAttributedString: s];

    [logView moveToEndOfDocument: self];
    [logView display];
}

- (void)logLevelChanged: (id)sender
{
    LogLevel level;

    int idx = [popUp indexOfSelectedItem];
    if (idx < 0) {
        return;
    }
    switch (idx) {
        case 0: level = LogLevel_Error; break;

        case 1: level = LogLevel_Warning; break;

        case 2: level = LogLevel_Notice; break;

        case 3: level = LogLevel_Info; break;

        case 4: level = LogLevel_Debug; break;

        case 5: level = LogLevel_Verbous; break;

        default: level = LogLevel_Warning;
    }
    //[messageLog setLevel:level ]; jedes Log hat seinen eigenen Level
    currentLevel = level;

    // workaround: GWEN/Aq sends messages to console...
    [[HBCIController controller] setLogLevel: level];
}

- (void)setLogLevel: (LogLevel)level
{
    if (level <= currentLevel) {
        return;
    }
    currentLevel = level;
    [self adjustPopupToLogLevel];
    //[messageLog setLevel:level ];
    [[HBCIController controller] setLogLevel: level];
}

- (void)saveLog: (id)sender
{
    NSSavePanel *sp;
    NSError     *error = nil;
    int         runResult;

    /* create or get the shared instance of NSSavePanel */
    sp = [NSSavePanel savePanel];

    /* set up new attributes */
    [sp setTitle: @"Logdatei wählen"];
    //	[sp setRequiredFileType:@"txt"];

    /* display the NSSavePanel */
    [sp setDirectoryURL: [NSURL URLWithString: NSHomeDirectory()]];
    runResult = [sp runModal];

    /* if successful, save file under designated name */
    if (runResult == NSOKButton) {
        if ([[[logView textStorage] mutableString] writeToFile: [[sp URL] path]
                                                    atomically: NO
                                                      encoding: NSUTF8StringEncoding
                                                         error: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return;
        }
    }
}

- (IBAction)writeConsole: (id)sender
{
    if ([sender state] == NSOnState) {
        messageLog.forceConsole = YES;
    } else {
        messageLog.forceConsole = NO;
    }
}

- (IBAction)sendMail: (id)sender
{
    // This line defines our entire mailto link. Notice that the link is formed
    // like a standard GET query might be formed, with each parameter, subject
    // and body, follow the email address with a ? and are separated by a &.
    // I use the %@ formatting string to add the contents of the lastResult and
    // songData objects to the body of the message. You should change these to
    // whatever information you want to include in the body.
    NSString *mailtoLink = [NSString stringWithFormat: @"mailto:support@pecuniabanking.de?subject=Pecunia Log&body=--Bitte fügen Sie hier ein, welche Aktion nicht erfolgreich war --\nDanke!\n\nLog:\n\n%@", [[logView textStorage] mutableString]];

    // This creates a URL string by adding percent escapes. Since the URL is
    // just being used locally, I don't know if this is always necessary,
    // however I thought it would be a good idea to stick to standards.
    NSURL *url = [NSURL URLWithString: (NSString *)
                  CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)mailtoLink,
                                                                            NULL, NULL, kCFStringEncodingUTF8))];

    // This just opens the URL in the workspace, to be opened up by Mail.app,
    // with data already entered in the subject, to and body fields.
    [[NSWorkspace sharedWorkspace] openURL: url];
}

- (void)clearLog: (id)sender
{
    [[logView textStorage] setAttributedString: [[NSAttributedString alloc] initWithString: @""]];
}

- (void)dealloc
{
    _logController = nil;
}

@end
