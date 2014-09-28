/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "AttachmentImageView.h"

#import "MOAssistant.h"

static void *AttachmentBindingContext = (void *)@"AttachmentBinding";
static NSString *const AttachmentDataType = @"pecunia.AttachmentDataType"; // For dragging an attachment.

static NSCursor *moveCursor;

@implementation AttachmentImageView

@synthesize reference;

+ (void)initialize
{
    [self exposeBinding: @"reference"];
    moveCursor = [[NSCursor alloc] initWithImage: [NSImage imageNamed: @"move-cursor"] hotSpot: NSMakePoint(18, 6)];
}

- (void)awakeFromNib
{
    [self unregisterDraggedTypes];
    [self registerForDraggedTypes: @[NSStringPboardType, NSFilenamesPboardType]];
}

#pragma mark - Destination Operations

- (NSDragOperation)dragOperationFor: (id <NSDraggingInfo>)sender
{
    if (!self.isEditable || ([sender draggingSource] == self)) {
        return NSDragOperationNone;
    }

    NSArray *types = [[sender draggingPasteboard] types];
    if ([types containsObject: AttachmentDataType]) {
        return NSDragOperationMove;
    }

    if ([types containsObject: NSURLPboardType] || [types containsObject: NSFilenamesPboardType]) {
        NSURL *url = [NSURL URLFromPasteboard: [sender draggingPasteboard]];
        BOOL isFolder;
        if ([NSFileManager.defaultManager fileExistsAtPath: url.path isDirectory: &isFolder]) {
            if (isFolder) {
                return NSDragOperationNone; // If the file is actually a folder don't accept it.
            }
        }

        return NSDragOperationCopy;
    }

    if ([types containsObject: NSStringPboardType]) {
        return NSDragOperationCopy;
    }

    return NSDragOperationNone;
}

- (NSDragOperation)draggingEntered: (id <NSDraggingInfo>)sender
{
    NSDragOperation result = [self dragOperationFor: sender];

    highlight = YES;
    [self setNeedsDisplay: YES];

    switch (result) {
        case NSDragOperationCopy:
            [[NSCursor dragCopyCursor] push];
            break;

        case NSDragOperationMove:
            [moveCursor push];
            break;

        default:
            [[NSCursor operationNotAllowedCursor] push];
            return NSDragOperationNone;
            break;
    }

    return result;

}

- (void)draggingExited: (id <NSDraggingInfo>)sender
{
    [NSCursor pop];

    highlight = NO;
    [self setNeedsDisplay: YES];
}

-(void)drawRect: (NSRect)rect
{
    [super drawRect: rect];

    if (highlight) {
        [[NSColor grayColor] set];
        [NSBezierPath setDefaultLineWidth: 5];
        [NSBezierPath strokeRect: rect];
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    highlight = NO;
    [self setNeedsDisplay: YES];

    return YES;
}

- (BOOL)performDragOperation: (id<NSDraggingInfo>)sender
{
    NSDragOperation operation = [self dragOperationFor: sender];

    switch (operation) {
        case NSDragOperationMove: {
            AttachmentImageView *otherView = [sender draggingSource];
            NSString *value = otherView.reference;
            [observedObject setValue: value forKeyPath: observedKeyPath];
            [otherView->observedObject setValue: nil forKeyPath: otherView->observedKeyPath];

            break;
        }

        case NSDragOperationCopy: {
            NSURL *url;

            NSArray *types = [[sender draggingPasteboard] types];
            if ([types containsObject: NSURLPboardType] || [types containsObject: NSFilenamesPboardType]) {
                url = [NSURL URLFromPasteboard: [sender draggingPasteboard]];
            } else {
                // Just some text. See if we can make a URL from it.
                NSString *text = [[sender draggingPasteboard] stringForType: NSStringPboardType];
                if (text.length > 0) {
                    url = [NSURL URLWithString: text];
                    if (url == nil) {
                        // Not a valid web URL. Try using it as file name.
                        // Of course the file must exist to be accepted.
                        if ([NSFileManager.defaultManager fileExistsAtPath: text]) {
                            url = [NSURL fileURLWithPath: text];
                        }
                    }
                }
            }

            if (url != nil) {
                [self processAttachment: url];
            } else {
                return NO;
            }
            break;
        }
    }

    return YES;
}

- (void)concludeDragOperation: (id<NSDraggingInfo>)sender
{
    // Only here to disable NSImageView's drop handling.
}

#pragma mark - Source Operations

- (void)mouseDown: (NSEvent *)event
{
    if (self.isEditable) {
        dragPending = YES;
    }
}

- (void)mouseUp: (NSEvent *)event
{
    if (dragPending) {
        // User just clicked. No mouse move.
        dragPending = NO;
        if ([[self target] respondsToSelector: [self action]]) {
            [NSApp sendAction: [self action] to: [self target] from: self];
        }
    }
}

- (void)mouseDragged: (NSEvent *)event
{
    if (dragPending) {
        dragPending = NO;

        NSURL *url = [NSURL URLWithString: reference];
        if (url != nil) {
            NSPoint dragPosition = [self convertPoint: [event locationInWindow] fromView: nil];
            dragPosition.x -= 100;

            NSPasteboard *pasteBoard = [NSPasteboard pasteboardWithUniqueName];
            [pasteBoard declareTypes: @[AttachmentDataType] owner: self];
            [pasteBoard writeObjects: @[url]];

            [self dragImage: [self image]
                         at: dragPosition
                     offset: NSZeroSize
                      event: event
                 pasteboard: pasteBoard
                     source: self
                  slideBack: NO];
        }
    }
}

- (NSDragOperation)       draggingSession: (NSDraggingSession *)session
    sourceOperationMaskForDraggingContext: (NSDraggingContext)context;
{
    switch(context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationDelete;
            break;

        case NSDraggingContextWithinApplication:
        default:
            return NSDragOperationDelete | NSDragOperationMove;
            break;
    }
}

- (BOOL)ignoreModifierKeysForDraggingSession:(NSDraggingSession *)session
{
    return YES;
}

- (void)draggingSession: (NSDraggingSession *)session
           movedToPoint: (NSPoint)screenPoint
{
    if (NSPointInRect(screenPoint, self.window.frame)) {
        NSRect windowRect = [self.window convertRectFromScreen: NSMakeRect(screenPoint.x, screenPoint.y, 1, 1)];
        NSView *view = [self.window.contentView hitTest: windowRect.origin];
        if (![view isKindOfClass: [AttachmentImageView class]]) {
            [[NSCursor disappearingItemCursor] set];
        }
    }
}

- (void)updateDraggingItemsForDrag: (id<NSDraggingInfo>)sender
{
    sender.numberOfValidItemsForDrop = 1;
}

- (void)draggedImage: (NSImage *)image
             endedAt: (NSPoint)screenPoint
           operation: (NSDragOperation)operation
{
    // NSDragOperationNone is returned outside of instances of this class. So it's good as
    // a delete indicator too.
    screenPoint.x += 100;
    NSRect windowRect = [self.window convertRectFromScreen: NSMakeRect(screenPoint.x, screenPoint.y, 1, 1)];
    NSView *view = [self.window.contentView hitTest: windowRect.origin];
    if (![view isKindOfClass: [AttachmentImageView class]] && (operation == NSDragOperationDelete || operation == NSDragOperationNone)) {
        [self processAttachment: nil];
        NSShowAnimationEffect(NSAnimationEffectPoof, screenPoint, self.bounds.size, nil, nil, NULL);
    }
}

- (void)resetCursorRects
{
    [super resetCursorRects];
    [self addCursorRect: [self bounds]
                 cursor: self.isEditable ? [NSCursor pointingHandCursor]: [NSCursor operationNotAllowedCursor]];
}

/**
 * Processes the given URL depending on its type. In case of a file URL the file is copied to Pecunia's
 * attachment folder (using a unique id) and a special reference is generated. For all other types the URL
 * is simply stored in the reference field.
 *
 * The format of the reference for a file is: "attachment://unique-id.ext?original-name.ext".
 */
- (void)processAttachment: (NSURL *)url
{
    // If the current reference points to a file then remove it.
    NSURL *oldUrl = [NSURL URLWithString: reference];
    self.reference = nil;
    [observedObject setValue: nil forKeyPath: observedKeyPath];

    if (oldUrl != nil) {
        if ([oldUrl.scheme isEqual: @"attachment"]) {
            NSString *targetFolder = [NSString stringWithFormat: @"%@/Attachments/", MOAssistant.assistant.pecuniaFileURL.path];
            NSString *targetFileName;
            targetFileName = [NSString stringWithFormat: @"%@%@", targetFolder, oldUrl.host];

            // Remove the file but don't show a message in case of an error. The message is
            // meaningless anyway (since it contains the internal filename).
            [NSFileManager.defaultManager removeItemAtPath: targetFileName error: nil];
        }
    }

    if (url == nil) {
        return;
    }

    if (url.isFileURL) {
        NSString *sourceFileName = url.path;
        NSString *extension = sourceFileName.pathExtension;

        NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
        NSString *uniqueFilenName = [NSString stringWithFormat: @"%@.%@", guid, extension];
        NSString *targetFolder = [NSString stringWithFormat: @"%@/Attachments/", MOAssistant.assistant.pecuniaFileURL.path];
        NSString *targetFileName = [targetFolder stringByAppendingString: uniqueFilenName];

        NSError *error = nil;
        if (![NSFileManager.defaultManager createDirectoryAtPath: targetFolder withIntermediateDirectories: YES attributes: nil error: &error]) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return;
        }
        if (![NSFileManager.defaultManager copyItemAtPath: sourceFileName toPath: targetFileName error: &error]) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return;
        }

        NSString *escapedName = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                          (__bridge CFStringRef)sourceFileName.lastPathComponent, NULL, NULL, kCFStringEncodingUTF8));

        NSString *newReference = [NSString stringWithFormat: @"attachment://%@?%@", uniqueFilenName, escapedName];
        [observedObject setValue: newReference forKeyPath: observedKeyPath];
    } else {
        [observedObject setValue: url.absoluteString forKeyPath: observedKeyPath];
    }
}

/**
 * Open the reference in the default web browser if it is a web URL, otherwise construct a full path
 * from the reference and open it with it's default application.
 */
- (void)openReference
{
    NSURL *url = [NSURL URLWithString: reference];

    if (url.isFileURL || [url.scheme isEqual: @"attachment"]) {
        NSString *targetFolder = [NSString stringWithFormat: @"%@/Attachments/", MOAssistant.assistant.pecuniaFileURL.path];

        NSString *targetFileName;
        if ([url.scheme isEqual: @"attachment"]) {
            targetFileName = [NSString stringWithFormat: @"%@%@", targetFolder, url.host];
        } else {
            targetFileName = url.absoluteString;
        }
        [NSWorkspace.sharedWorkspace openFile: targetFileName];
    } else {
        [NSWorkspace.sharedWorkspace openURL: url];
    }
}

- (void)setReference: (id)value
{
    [self.window invalidateCursorRectsForView: self];

    if (value == NSNoSelectionMarker || value == NSMultipleValuesMarker || value == nil) {
        self.image = [NSImage imageNamed: @"gray-hatch2"];
        self.imageScaling = NSImageScaleNone;
        if (value == nil) {
            self.toolTip = NSLocalizedString(@"AP119", nil);
        } else {
            self.toolTip = nil;
        }
        reference = nil;

        return;
    }

    self.imageScaling = NSImageScaleProportionallyUpOrDown;
    NSURL *url = [NSURL URLWithString: value];

    // Ensure we always have a scheme in the URL. Assume file as default.
    if (url.scheme == nil) {
        url = [NSURL URLWithString: [NSString stringWithFormat: @"file://localhost/%@", value]];
    }

    reference = url.absoluteString;

    if (url.isFileURL || [url.scheme isEqual: @"attachment"]) {
        NSString *targetFolder = [NSString stringWithFormat: @"%@/Attachments/", MOAssistant.assistant.pecuniaFileURL.path];

        NSString *targetFileName;
        NSString *tooltipFileName;
        if ([url.scheme isEqual: @"attachment"]) {
            targetFileName = [NSString stringWithFormat: @"%@%@", targetFolder, url.host];
            tooltipFileName = url.query;
        } else {
            targetFileName = value;
            tooltipFileName = [targetFileName lastPathComponent];
        }

        NSString *unescapedTooltipFileName = CFBridgingRelease(
                                                               CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)tooltipFileName, CFSTR(""),
                                                                                                                       kCFStringEncodingUTF8));
        NSString *extension = targetFileName.pathExtension;

        self.toolTip = [NSString stringWithFormat: @"%@\n\n%@", unescapedTooltipFileName, NSLocalizedString(@"AP120", nil)];
        NSImage *image;

        // Display images as such. Exclude pdf files manually as they qualify as images too.
        // (It's such a nonsense to show the content of the first pdf page as icon <sigh>.)
        if (![extension isCaseInsensitiveLike: @"pdf"]) {
            NSArray *types = NSImage.imageFileTypes;
            if ([types containsObject: extension]) {
                image = [[NSImage alloc] initWithContentsOfFile: targetFileName];
                if (image != nil) {
                    self.image = image;
                    return;
                }
            }
        }

        // Anything else. Get the system's icon for it. If there's no extension use the entire path.
        if (extension.length == 0) {
            image = [NSWorkspace.sharedWorkspace iconForFile: targetFileName];
        } else {
            image = [[NSWorkspace sharedWorkspace] iconForFileType: extension];
        }
        image.size = NSMakeSize(128, 128); // Lower resolution is automatically used, depending on available space.
        self.image = image;


    } else {
        reference = url.absoluteString;

        self.toolTip = [NSString stringWithFormat: @"%@\n\n%@", reference, NSLocalizedString(@"AP120", nil)];
        NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType: @"html"];
        image.size = NSMakeSize(128, 128);
        self.image = image;
    }
}

- (void)   bind: (NSString *)binding
       toObject: (id)observableObject
    withKeyPath: (NSString *)keyPath
        options: (NSDictionary *)options
{
    if ([binding isEqualToString: @"reference"] || [binding isEqualToString: @"valueURL"]) {
        observedObject = observableObject;
        observedKeyPath = keyPath;
        [observableObject addObserver: self forKeyPath: keyPath options: 0 context: AttachmentBindingContext];
    } else {
        [super bind: binding toObject: observableObject withKeyPath: keyPath options: options];
    }
}

- (void)unbind: (NSString *)binding
{
    if ([binding isEqualToString: @"reference"]) {
        [observedObject removeObserver: self forKeyPath: observedKeyPath];
    } else {
        [super unbind: binding];
    }
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == AttachmentBindingContext) {
        self.reference = [observedObject valueForKeyPath: observedKeyPath];
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

@end
