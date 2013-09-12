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

#import "BankingController+Tabs.h" // Includes BankingController.h

#import "NewBankUserController.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "PreferenceController.h"
#import "MOAssistant.h"
#import "LogController.h"
#import "TagView.h"
#import "ExportController.h"
#import "MCEMOutlineViewLayout.h"
#import "AccountDefController.h"
#import "TimeSliceManager.h"
#import "MCEMTreeController.h"
#import "MCEMDecimalNumberAdditions.h"
#import "WorkerThread.h"
#import "BSSelectWindowController.h"
#import "StatusBarController.h"
#import "DonationMessageController.h"
#import "BankQueryResult.h"
#import "CategoryView.h"
#import "HBCIClient.h"
#import "StatCatAssignment.h"
#import "PecuniaError.h"
#import "ShortDate.h"

#import "StatSplitController.h"
#import "BankStatementController.h"
#import "AccountMaintenanceController.h"
#import "PurposeSplitController.h"
#import "TransferTemplateController.h"

#import "CategoryAnalysisWindowController.h"
#import "CategoryRepWindowController.h"
#import "CategoryDefWindowController.h"
#import "CategoryPeriodsWindowController.h"
#import "CategoryMaintenanceController.h"
#import "CategoryHeatMapController.h"

#import "TransfersController.h"

#import "BankStatementPrintView.h"
#import "DockIconController.h"
#import "GenerateDataController.h"
#import "CreditCardSettlementController.h"

#import "ImportController.h"
#import "ImageAndTextCell.h"
#import "StatementsListview.h"
#import "StatementDetails.h"
#include "ColorPopup.h"

#import "GraphicsAdditions.h"
#import "BWGradientBox.h"

#import "User.h"
#import "Tag.h"
#import "AssignmentController.h"

// Pasteboard data types.
NSString *const BankStatementDataType = @"BankStatementDataType";
NSString *const CategoryDataType = @"CategoryDataType";

// Notification and dictionary key for category color change notifications.
extern NSString *const HomeScreenCardClickedNotification;
NSString *const CategoryColorNotification = @"CategoryColorNotification";
NSString *const CategoryKey = @"CategoryKey";

// KVO contexts.
void *UserDefaultsBindingContext = (void *)@"UserDefaultsContext";

static BankingController *bankinControllerInstance;

static NSCursor *moveCursor;

//----------------------------------------------------------------------------------------------------------------------

@implementation PecuniaSplitView

@synthesize fixedIndex;

- (id)initWithCoder: (NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    if (self != nil) {
        fixedIndex = NSNotFound;
    }
    return self;
}

- (void)awakeFromNib
{
}

- (NSColor *)dividerColor
{
    return [NSColor clearColor];
}

- (void)resizeSubviewsWithOldSize: (NSSize)oldSize
{
    if (fixedIndex == NSNotFound || fixedIndex >= self.subviews.count || self.subviews.count != 2) {
        [super resizeSubviewsWithOldSize: oldSize];
    } else {
        // Fixed size support currently only for 2 subviews.
        NSSize     totalSize = self.bounds.size;
        NSUInteger variableIndex = fixedIndex == 0 ? 1 : 0;
        NSSize     fixedSize = [self.subviews[fixedIndex] frame].size;

        if ([(NSView *)(self.subviews[fixedIndex])isHidden]) {
            fixedSize = NSZeroSize;
        }

        if (self.isVertical) {
            NSSize size;
            size.height = totalSize.height;
            size.width = totalSize.width - self.dividerThickness - fixedSize.width;
            [self.subviews[variableIndex] setFrameSize: size];
            size.width = [self.subviews[fixedIndex] frame].size.width;
            [self.subviews[fixedIndex] setFrameSize: size];
            if (fixedIndex == 1) {
                NSPoint origin = NSMakePoint(totalSize.width - fixedSize.width, 0);
                [self.subviews[fixedIndex] setFrameOrigin: origin];
            }
        } else {
            NSSize size;
            size.width = totalSize.width;
            size.height = totalSize.height - self.dividerThickness - fixedSize.height;
            [self.subviews[variableIndex] setFrameSize: size];
            size.height = [self.subviews[fixedIndex] frame].size.height;
            [self.subviews[fixedIndex] setFrameSize: size];
            if (fixedIndex == 1) {
                NSPoint origin = NSMakePoint(0, totalSize.height - fixedSize.height);
                [self.subviews[fixedIndex] setFrameOrigin: origin];
            }
        }
    }
}

@end

//----------------------------------------------------------------------------------------------------------------------

static void *AttachmentBindingContext = (void *)@"AttachmentBinding";
static NSString *const AttachmentDataType = @"pecunia.AttachmentDataType"; // For dragging an attachment.

@interface AttachmentImageView : NSImageView <NSDraggingSource, NSDraggingDestination>
{
@private
    id       observedObject;
    NSString *observedKeyPath;
    BOOL     highlight;
    BOOL     dragPending;
}

@property (nonatomic, strong) NSString *reference;

@end

@implementation AttachmentImageView

@synthesize reference;

+ (void)initialize
{
    [self exposeBinding: @"reference"];
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
    dragPending = YES;
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
        self.image = nil;
        if (value == nil) {
            self.toolTip = NSLocalizedString(@"AP119", nil);
        } else {
            self.toolTip = nil;
        }
        reference = nil;

        return;
    }

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
    if ([binding isEqualToString: @"reference"]) {
        observedObject = observableObject;
        observedKeyPath = keyPath;
        [observableObject addObserver: self forKeyPath: keyPath options: 0 context: AttachmentBindingContext];
    } else {
        [super bind: binding toObject: observableObject withKeyPath: keyPath options: options];
    }
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == AttachmentBindingContext) {
        self.reference = [observedObject valueForKeyPath: observedKeyPath];
    }
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation BankingController

@synthesize saveValue;
@synthesize managedObjectContext;
@synthesize dockIconController;
@synthesize shuttingDown;

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self != nil) {
        HBCIClient *client = nil;

        bankinControllerInstance = self;
        restart = NO;
        requestRunning = NO;
        mainTabItems = [NSMutableDictionary dictionaryWithCapacity: 10];

        @try {
            client = [HBCIClient hbciClient];
            PecuniaError *error = [client initalizeHBCI];
            if (error != nil) {
                [error alertPanel];
                [NSApp terminate: self];

            }
        }
        @catch (NSError *error) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            [NSApp terminate: self];
        }

        logController = [LogController logController];
    }
    return self;
}

- (void)dealloc
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"recursiveTransactions"];
    [userDefaults removeObserver: self forKeyPath: @"showHiddenCategories"];
    [userDefaults removeObserver: self forKeyPath: @"colors"];
}

- (void)setNumberFormatForCell: (NSCell *)cell positive: (NSDictionary *)positive
                      negative: (NSDictionary *)negative
{
    if (cell == nil) {
        return;
    }

    NSNumberFormatter *formatter;
    if ([cell isKindOfClass: [ImageAndTextCell class]]) {
        formatter =  ((ImageAndTextCell *)cell).amountFormatter;
    } else {
        formatter =  [cell formatter];
    }

    if (formatter) {
        [formatter setTextAttributesForPositiveValues: positive];
        [formatter setTextAttributesForNegativeValues: negative];
    }

}

- (void)awakeFromNib
{
    [self setDefaultUserSettings];
    
    sortAscending = NO;
    sortIndex = 0;

    // set standard details
    statementDetails = standardDetails;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults addObserver: self forKeyPath: @"recursiveTransactions" options: 0 context: UserDefaultsBindingContext];
    [userDefaults addObserver: self forKeyPath: @"showHiddenCategories" options: 0 context: UserDefaultsBindingContext];
    [userDefaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];

    if ([userDefaults objectForKey: @"mainSortIndex"]) {
        sortControl.selectedSegment = [[userDefaults objectForKey: @"mainSortIndex"] intValue];
    }

    if ([userDefaults objectForKey: @"mainSortAscending"]) {
        sortAscending = [[userDefaults objectForKey: @"mainSortAscending"] boolValue];
    }

    lastSplitterPosition = [[userDefaults objectForKey: @"rightSplitterPosition"] intValue];
    if (lastSplitterPosition > 0) {
        // The details pane was collapsed when Pecunia closed last time.
        [statementDetails setHidden: YES];
        [toggleDetailsButton setImage: [NSImage imageNamed: @"show"]];
        [rightSplitter adjustSubviews];
    }
    self.toggleDetailsPaneItem.state = lastSplitterPosition > 0 ? NSOffState : NSOnState;

    [self updateSorting];
    [self updateValueColors];

    // Edit accounts/categories when double clicking on a node.
    [accountsView setDoubleAction: @selector(changeAccount:)];
    [accountsView setTarget: self];

    NSTableColumn *tableColumn = [accountsView tableColumnWithIdentifier: @"name"];
    if (tableColumn) {
        ImageAndTextCell *cell = (ImageAndTextCell *)[tableColumn dataCell];
        if (cell) {
            [cell setFont: [NSFont fontWithName: PreferenceController.mainFontName size: 13]];

            // update unread information
            NSInteger maxUnread = [BankAccount maxUnread];
            [cell setMaxUnread: maxUnread];
        }
    }

    // status (content) bar
    [mainWindow setAutorecalculatesContentBorderThickness: NO forEdge: NSMinYEdge];
    [mainWindow setContentBorderThickness: 30.0f forEdge: NSMinYEdge];

    // register Drag'n Drop
    [accountsView registerForDraggedTypes: @[BankStatementDataType, CategoryDataType]];

    // Set a number images that use a collection (and hence are are not automatically found).
    NSString *path = [[NSBundle mainBundle] pathForResource: @"icon72-1"
                                                     ofType: @"icns"
                                                inDirectory: @"Collections/1"];
    if ([NSFileManager.defaultManager fileExistsAtPath: path]) {
        lockImage.image = [[NSImage alloc] initWithContentsOfFile: path];
    }
    path = [[NSBundle mainBundle] pathForResource: @"icon14-1"
                                           ofType: @"icns"
                                      inDirectory: @"Collections/1"];
    if ([NSFileManager.defaultManager fileExistsAtPath: path]) {
        tagButton.image = [[NSImage alloc] initWithContentsOfFile: path];
    }

    // set encryption image
    [self encryptionChanged];

    splitCursor = [[NSCursor alloc] initWithImage: [NSImage imageNamed: @"split-cursor"] hotSpot: NSMakePoint(0, 0)];
    moveCursor = [[NSCursor alloc] initWithImage: [NSImage imageNamed: @"move-cursor"] hotSpot: NSMakePoint(18, 6)];
    [WorkerThread init];

    [categoryController addObserver: self forKeyPath: @"arrangedObjects.catSum" options: 0 context: nil];
    [categoryAssignments addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: nil];

    // Setup statements listview.
    [statementsListView bind: @"dataSource" toObject: categoryAssignments withKeyPath: @"arrangedObjects" options: nil];

    // Bind controller to selectedRow property and the listview to the controller's selectedIndex property to get notified about selection changes.
    [categoryAssignments bind: @"selectionIndexes" toObject: statementsListView withKeyPath: @"selectedRows" options: nil];
    [statementsListView bind: @"selectedRows" toObject: categoryAssignments withKeyPath: @"selectionIndexes" options: nil];

    [statementsListView setCellSpacing: 0];
    [statementsListView setAllowsEmptySelection: YES];
    [statementsListView setAllowsMultipleSelection: YES];

    currentSection = nil; // The right splitter, which is by default active is not a regular section.
    toolbarButtons.selectedSegment = 0;

    if (self.managedObjectContext) {
        [self publishContext];
    }

    [MOAssistant assistant].mainContentView = [mainWindow contentView];

    [attachement1 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref1" options: nil];
    [attachement2 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref2" options: nil];
    [attachement3 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref3" options: nil];
    [attachement4 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref4" options: nil];

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"order" ascending: YES];
    [statementTags setSortDescriptors: @[sd]];
    [tagsController setSortDescriptors: @[sd]];
    tagButton.bordered = NO;

    // Setup full screen mode support on Lion+.
    // TODO: can be done in the xib.
    [mainWindow setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
    [toggleFullscreenItem setHidden: NO];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(contextChanged)
                                                 name: @"contextDataChanged"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(encryptionChanged)
                                                 name: @"dataFileEncryptionChanged"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(homeScreenCardClicked:)
                                                 name: HomeScreenCardClickedNotification
                                               object: nil];

#ifdef DEBUG
    [developerMenu setHidden: NO];
#endif
}

/**
 * Sets a number of settings to useful defaults.
 */
- (void)setDefaultUserSettings
{
    // Home screen settings.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL stocksDefaultsSet = [defaults boolForKey: @"stocksDefaultsSet"];
    NSString *stockSymbol = [defaults stringForKey: @"stocksSymbol1"];
    if (stockSymbol == nil && !stocksDefaultsSet) {
        [defaults setObject: @"^GDAXI" forKey: @"stocksSymbol1"];
    }
    id stockSymbolColor = [defaults objectForKey: @"stocksSymbolColor1"];
    if (stockSymbolColor == nil) {
        NSData *data = [NSArchiver archivedDataWithRootObject: [NSColor nextDefaultStockGraphColor]];
        [defaults setObject: data forKey: @"stocksSymbolColor1"];
    }

    stockSymbol = [defaults stringForKey: @"stocksSymbol2"];
    if (stockSymbol == nil && !stocksDefaultsSet) {
        [defaults setObject: @"ORCL" forKey: @"stocksSymbol2"];
    }
    stockSymbolColor = [defaults objectForKey: @"stocksSymbolColor2"];
    if (stockSymbolColor == nil) {
        NSData *data = [NSArchiver archivedDataWithRootObject: [NSColor nextDefaultStockGraphColor]];
        [defaults setObject: data forKey: @"stocksSymbolColor2"];
    }

    stockSymbol = [defaults stringForKey: @"stocksSymbol3"];
    if (stockSymbol == nil && !stocksDefaultsSet) {
        [defaults setObject: @"AAPL" forKey: @"stocksSymbol3"];
    }
    stockSymbolColor = [defaults objectForKey: @"stocksSymbolColor3"];
    if (stockSymbolColor == nil) {
        NSData *data = [NSArchiver archivedDataWithRootObject: [NSColor nextDefaultStockGraphColor]];
        [defaults setObject: data forKey: @"stocksSymbolColor3"];
    }
    [defaults setBool: YES forKey: @"stocksDefaultsSet"];

    if ([defaults objectForKey: @"autoCasing"] == nil) {
        [defaults setBool: YES forKey: @"autoCasing"];
    }
}

- (void)publishContext
{
    NSError *error = nil;

    categoryController.managedObjectContext = self.managedObjectContext;
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES];
    [categoryController setSortDescriptors: @[sd]];

    categoryAssignments.managedObjectContext = self.managedObjectContext;
    tagsController.managedObjectContext = self.managedObjectContext;
    [tagsController prepareContent];

    // repair Category Root
    [self repairCategories];

    [self setHBCIAccounts];

    [self updateBalances];

    // update unread information
    [self updateUnread];

    [timeSlicer updateDelegate];
    [categoryController fetchWithRequest: nil merge: NO error: &error];
    [self performSelector: @selector(restoreAccountsView) withObject: nil afterDelay: 0.0];
    dockIconController = [[DockIconController alloc] initWithManagedObjectContext: self.managedObjectContext];
}

- (void)contextChanged
{
    self.managedObjectContext = [[MOAssistant assistant] context];
    [self publishContext];
}

- (void)encryptionChanged
{
    [lockImage setHidden: ![[MOAssistant assistant] encrypted]];
}

#pragma mark - User actions

- (void)homeScreenCardClicked: (NSNotification *)notification
{
    id object = notification.object;
    if ([object isKindOfClass: Category.class]) {
        NSControl *dummy = [[NSControl alloc] init];
        dummy.tag = 1;
        [categoryController setSelectedObject: object];
        [self switchMainPage: 1];
        [self activateAccountPage: dummy];
    }
}

- (void)setHBCIAccounts
{
    NSError             *error = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"accountNumber != nil AND userId != nil"];
    [request setPredicate: predicate];
    NSArray *accounts = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || accounts == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    PecuniaError *pecError = [[HBCIClient hbciClient] setAccounts: accounts];
    if (pecError) {
        [pecError alertPanel];
    }
}

- (NSIndexPath *)indexPathForCategory: (Category *)cat inArray: (NSArray *)nodes
{
    NSUInteger idx = 0;
    for (NSTreeNode *node in nodes) {
        Category *obj = [node representedObject];
        if (obj == cat) {
            return [NSIndexPath indexPathWithIndex: idx];
        } else {
            NSArray *children = [node childNodes];
            if (children == nil) {
                continue;
            }
            NSIndexPath *p = [self indexPathForCategory: cat inArray: children];
            if (p) {
                return [p indexPathByAddingIndex: idx];
            }
        }
        idx++;
    }
    return nil;
}

- (void)removeBankAccount: (BankAccount *)bankAccount keepAssignedStatements: (BOOL)keepAssignedStats
{
    NSSet         *stats = [bankAccount mutableSetValueForKey: @"statements"];
    NSEnumerator  *enumerator = [stats objectEnumerator];
    BankStatement *statement;
    int           i;
    BOOL          removeParent = NO;

    //  Delete bank statements which are not assigned first
    while ((statement = [enumerator nextObject])) {
        if (keepAssignedStats == NO) {
            [self.managedObjectContext deleteObject: statement];
        } else {
            NSSet *assignments = [statement mutableSetValueForKey: @"assignments"];
            if ([assignments count] < 2) {
                [self.managedObjectContext deleteObject: statement];
            } else if ([assignments count] == 2) {
                // delete statement if not assigned yet
                if ([statement hasAssignment] == NO) {
                    [self.managedObjectContext deleteObject: statement];
                }
            } else {
                statement.account = nil;
            }
        }
    }

    [self.managedObjectContext processPendingChanges];
    [[Category nassRoot] invalidateBalance];
    [Category updateCatValues];

    // remove parent?
    BankAccount *parent = [bankAccount valueForKey: @"parent"];
    if (parent != nil) {
        NSSet *childs = [parent mutableSetValueForKey: @"children"];
        if ([childs count] == 1) {
            removeParent = YES;
        }
    }

    // calculate index path of current object
    NSArray     *nodes = [[categoryController arrangedObjects] childNodes];
    NSIndexPath *path = [self indexPathForCategory: bankAccount inArray: nodes];
    // IndexPath umdrehen
    NSIndexPath *newPath = [[NSIndexPath alloc] init];
    for (i = [path length] - 1; i >= 0; i--) {
        newPath = [newPath indexPathByAddingIndex: [path indexAtPosition: i]];
    }
    [categoryController removeObjectAtArrangedObjectIndexPath: newPath];
    if (removeParent) {
        newPath = [newPath indexPathByRemovingLastIndex];
        [categoryController removeObjectAtArrangedObjectIndexPath: newPath];
    }
    //	[categoryController remove: self];
    [[Category bankRoot] rollup];
}

- (BOOL)cleanupBankNodes
{
    BOOL flg_changed = NO;
    // remove empty bank nodes
    Category *root = [Category bankRoot];
    if (root != nil) {
        NSArray *bankNodes = [[root mutableSetValueForKey: @"children"] allObjects];
        for (BankAccount *node in bankNodes) {
            NSMutableSet *childs = [node mutableSetValueForKey: @"children"];
            if (childs == nil || [childs count] == 0) {
                [self.managedObjectContext deleteObject: node];
                flg_changed = YES;
            }
        }
    }
    return flg_changed;
}

- (Category *)getBankingRoot
{
    NSError        *error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getBankingRoot"];
    NSArray        *cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }
    if ([cats count] > 0) {
        return cats[0];
    }

    // create Root object
    Category *obj = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                  inManagedObjectContext: self.managedObjectContext];
    [obj setValue: @"++bankroot" forKey: @"name"];
    [obj setValue: @YES forKey: @"isBankAcc"];
    return obj;
}

// XXX: is this still required? Looks like a fix for a previous bug.
- (void)repairCategories
{
    NSError  *error = nil;
    Category *catRoot;
    BOOL     found = NO;

    // repair bank root
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getBankingRoot"];
    NSArray        *cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    for (Category *cat in cats) {
        NSString *n = [cat primitiveValueForKey: @"name"];
        if (![n isEqualToString: @"++bankroot"]) {
            [cat setValue: @"++bankroot" forKey: @"name"];
            break;
        }
    }
    // repair categories
    request = [model fetchRequestTemplateForName: @"getCategoryRoot"];
    cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    for (Category *cat in cats) {
        NSString *n = [cat primitiveValueForKey: @"name"];
        if ([n isEqualToString: @"++catroot"] ||
            [n isEqualToString: @"Umsatzkategorien"] ||
            [n isEqualToString: @"Transaction categories"]) {
            [cat setValue: @"++catroot" forKey: @"name"];
            catRoot = cat;
            found = YES;
            break;
        }
    }
    if (found == NO) {
        // create Category Root object
        Category *obj = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                      inManagedObjectContext: self.managedObjectContext];
        [obj setValue: @"++catroot" forKey: @"name"];
        [obj setValue: @NO forKey: @"isBankAcc"];
        catRoot = obj;
    }

    // reassign categories
    for (Category *cat in cats) {
        if (cat == catRoot) {
            continue;
        }
        if ([cat valueForKey: @"parent"] == nil) {
            [cat setValue: catRoot forKey: @"parent"];
        }
    }
    // insert not assigned node
    request = [model fetchRequestTemplateForName: @"getNassRoot"];
    cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    if ([cats count] == 0) {
        Category *obj = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                      inManagedObjectContext: self.managedObjectContext];
        [obj setPrimitiveValue: @"++nassroot" forKey: @"name"];
        [obj setValue: @NO forKey: @"isBankAcc"];
        [obj setValue: catRoot forKey: @"parent"];

        [self updateNotAssignedCategory];
    }

    [self save];
}

- (void)updateBalances
{
    NSError *error = nil;

    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getRootNodes"];
    NSArray        *cats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    for (Category *cat in cats) {
        if ([cat isBankingRoot] == NO) {
            [cat updateInvalidCategoryValues];
        }
        [cat rollup];
    }

    [self save];
}

- (IBAction)enqueueRequest: (id)sender
{
    NSMutableArray *selectedAccounts = [NSMutableArray arrayWithCapacity: 10];
    NSArray        *selectedNodes = nil;
    Category       *cat;
    NSError        *error = nil;

    cat = [self currentSelection];
    if (cat == nil) {
        return;
    }

    // one bank account selected
    if (cat.accountNumber != nil) {
        [selectedAccounts addObject: cat];
    } else {
        // a node was selected
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: self.managedObjectContext];
        NSFetchRequest      *request = [[NSFetchRequest alloc] init];
        [request setEntity: entityDescription];
        if (cat.parent == nil) {
            // root was selected
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@", cat];
            [request setPredicate: predicate];
            selectedNodes = [self.managedObjectContext executeFetchRequest: request error: &error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }
        } else {
            // a node was selected
            selectedNodes = @[cat];
        }
        // now select accounts from nodes
        BankAccount *account;
        for (account in selectedNodes) {
            NSArray     *result;
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == %@ AND noAutomaticQuery == 0", account];
            [request setPredicate: predicate];
            result = [self.managedObjectContext executeFetchRequest: request error: &error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }
            [selectedAccounts addObjectsFromArray: result];
        }
    }
    if ([selectedAccounts count] == 0) {
        return;
    }

    // check if at least one Account is assigned to a user
    NSUInteger  nInactive = 0;
    BankAccount *account;
    for (account in selectedAccounts) {
        if (account.userId == nil && ([account.isManual boolValue] == NO)) {
            nInactive++;
        }
    }
    if (nInactive == [selectedAccounts count]) {
        NSRunAlertPanel(NSLocalizedString(@"AP220", nil),
                        NSLocalizedString(@"AP215", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil, nil
                        );
        return;
    }
    if (nInactive > 0) {
        NSRunAlertPanel(NSLocalizedString(@"AP216", nil),
                        NSLocalizedString(@"AP217", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil, nil,
                        nInactive,
                        [selectedAccounts count]
                        );
    }

    // now selectedAccounts has all selected Bank Accounts
    NSMutableArray *resultList = [NSMutableArray arrayWithCapacity: [selectedAccounts count]];
    for (account in selectedAccounts) {
        if (account.userId) {
            BankQueryResult *result = [[BankQueryResult alloc] init];
            result.accountNumber = account.accountNumber;
            result.accountSubnumber = account.accountSuffix;
            result.bankCode = account.bankCode;
            result.userId = account.userId;
            result.account = account;
            [resultList addObject: result];
        }
    }
    // show log if wanted
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           showLog = [defaults boolForKey: @"logForBankQuery"];
    if (showLog) {
        [logController showWindow: self];
        [[logController window] orderFront: self];
    }

    // prepare UI
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: NO];
    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP219", nil) removeAfter: 0];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(statementsNotification:)
                                                 name: PecuniaStatementsNotification
                                               object: nil];
    [[HBCIClient hbciClient] getStatements: resultList];
}

- (void)statementsNotification: (NSNotification *)notification
{
    BankQueryResult     *result;
    StatusBarController *sc = [StatusBarController controller];
    BOOL                noStatements = YES;
    BOOL                isImport = NO;
    int                 count = 0;

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: PecuniaStatementsNotification
                                                  object: nil];

    NSArray *resultList = [notification object];
    if (resultList == nil) {
        [sc stopSpinning];
        [sc clearMessage];
        requestRunning = NO;
        return;
    }

    // get Proposals
    for (result in resultList) {
        NSArray *stats = result.statements;
        if ([stats count] > 0) {
            noStatements = NO;
            [result.account evaluateQueryResult: result];
        }
        if (result.isImport) {
            isImport = YES;
        }
        [result.account updateStandingOrders: result.standingOrders];
    }
    [sc stopSpinning];
    [sc clearMessage];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           check = [defaults boolForKey: @"manualTransactionCheck"];

    if (check && !noStatements) {
        BSSelectWindowController *selectWindowController = [[BSSelectWindowController alloc] initWithResults: resultList];
        [NSApp runModalForWindow: [selectWindowController window]];
    } else {
        @try {
            for (result in resultList) {
                count += [result.account updateFromQueryResult: result];
            }
        }
        @catch (NSException *e) {
            [[MessageLog log] addMessage: e.reason withLevel: LogLevel_Error];
        }
        if (autoSyncRunning) {
            [self checkBalances: resultList];
        }
        [self requestFinished: resultList];

        [sc setMessage: [NSString stringWithFormat: NSLocalizedString(@"AP218", nil), count] removeAfter: 120];
    }
    autoSyncRunning = NO;

    [self save];

    BOOL suppressSound = [NSUserDefaults.standardUserDefaults boolForKey: @"noSoundAfterSync"];
    if (!suppressSound) {
        NSSound *doneSound = [NSSound soundNamed: @"done.mp3"];
        if (doneSound != nil) {
            [doneSound play];
        }
    }
}

- (void)requestFinished: (NSArray *)resultList
{
    [self.managedObjectContext processPendingChanges];
    [self updateBalances];
    requestRunning = NO;
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: YES];

    if (resultList != nil) {
        [[self currentSelection] updateBoundAssignments];

        BankQueryResult *result;
        NSDate          *maxDate = nil;
        for (result in resultList) {
            NSDate *lDate = result.account.latestTransferDate;
            if (((maxDate != nil) && ([maxDate compare: lDate] == NSOrderedAscending)) || (maxDate == nil)) {
                maxDate = lDate;
            }
        }
        if (maxDate) {
            [timeSlicer stepIn: [ShortDate dateWithDate: maxDate]];
        }

        // update unread information
        NSInteger maxUnread = [BankAccount maxUnread];

        // update data cell
        NSTableColumn *tc = [accountsView tableColumnWithIdentifier: @"name"];
        if (tc) {
            ImageAndTextCell *cell = (ImageAndTextCell *)[tc dataCell];
            [cell setMaxUnread: maxUnread];
        }

        // redraw accounts view
        [accountsView setNeedsDisplay: YES];
        [rightPane setNeedsDisplay: YES];

        [categoryAssignments rearrangeObjects];
    }
}

- (void)checkBalances: (NSArray *)resultList
{
    NSNumber *threshold;
    BOOL     alert = NO;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           accWarning = [defaults boolForKey: @"accWarning"];
    if (accWarning == NO) {
        return;
    }

    threshold = [defaults objectForKey: @"accWarningThreshold"];
    if (threshold == nil) {
        threshold = [NSDecimalNumber zero];
    }

    // check if account balances change below threshold
    for (BankQueryResult *result in resultList) {
        if ([result.oldBalance compare: threshold] == NSOrderedDescending && [result.balance compare: threshold] == NSOrderedAscending) {
            alert = YES;
        }
    }
    if (alert == YES) {
        NSRunAlertPanel(NSLocalizedString(@"AP814", nil),
                        NSLocalizedString(@"AP815", nil),
                        NSLocalizedString(@"AP1", nil),
                        nil, nil
                        );
    }
}

- (BOOL)requestRunning
{
    return requestRunning;
}

- (BankAccount *)selectBankAccountWithNumber: (NSString *)accNum bankCode: (NSString *)code
{
    NSError        *error = nil;
    NSDictionary   *subst = @{@"ACCNT" : accNum, @"BCODE": code};
    NSFetchRequest *fetchRequest =
    [model fetchRequestFromTemplateWithName: @"bankAccountByID" substitutionVariables: subst];
    NSArray *results =
    [self.managedObjectContext executeFetchRequest: fetchRequest error: &error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }
    if (results == nil || [results count] != 1) {
        return nil;
    }
    return results[0];
}

- (NSArray *)selectedNodes
{
    return [categoryController selectedObjects];
}

- (IBAction)editBankUsers: (id)sender
{
    if (!bankUserController) {
        bankUserController = [[NewBankUserController alloc] initForController: self];
    }

    [[bankUserController window] makeKeyAndOrderFront: self];
}

- (IBAction)editPreferences: (id)sender
{
    if (!prefController) {
        prefController = [[PreferenceController alloc] init];
    }
    [prefController showWindow: self];
}

- (IBAction)showTagPopup: (id)sender
{
    NSButton *button = sender;
    [tagViewPopup showTagPopupAt: button.bounds forView: button host: tagViewHost];
}

#pragma mark - Account management

- (IBAction)addAccount: (id)sender
{
    NSString *bankCode = nil;
    Category *cat = [self currentSelection];
    if (cat != nil) {
        if ([cat isBankAccount] && ![cat isRoot]) {
            bankCode = [cat valueForKey: @"bankCode"];
        }
    }

    AccountDefController *defController = [[AccountDefController alloc] init];
    if (bankCode) {
        [defController setBankCode: bankCode name: [cat valueForKey: @"bankName"]];
    }

    int res = [NSApp runModalForWindow: [defController window]];
    if (res) {
        // account was created
        [self save];

        [categoryController rearrangeObjects];
        [Category.bankRoot rollup];
    }
}

- (IBAction)changeAccount: (id)sender
{
    // In order to let KVO selection changes work properly when double clicking a node other than
    // the current one we have to run the modal dialogs after the runloop has finished its round.
    [self performSelector: @selector(doChangeAccount) withObject: nil afterDelay: 0];
}

- (void)doChangeAccount
{
    Category *cat = [self currentSelection];
    if (cat == nil) {
        return;
    }

    if (!cat.isBankAccount && cat != Category.nassRoot && cat != Category.catRoot) {
        CategoryMaintenanceController *changeController = [[CategoryMaintenanceController alloc] initWithCategory: cat];
        [NSApp runModalForWindow: [changeController window]];
        [categoryController prepareContent]; // Visibility of a category could have changed.
        [Category.catRoot rollup]; // Category could have switched its noCatRep property.
        return;
    }

    if (cat.accountNumber != nil) {
        AccountMaintenanceController *changeController = [[AccountMaintenanceController alloc] initWithAccount: (BankAccount *)cat];
        [NSApp runModalForWindow: [changeController window]];
        [categoryController prepareContent];
        [Category.bankRoot rollup];
    }
    // Changes are stored in the controllers.
}

- (IBAction)deleteAccount: (id)sender
{
    Category *cat = [self currentSelection];
    if (cat == nil) {
        return;
    }
    if ([cat isBankAccount] == NO) {
        return;
    }
    if ([cat accountNumber] == nil) {
        return;
    }

    BankAccount *account = (BankAccount *)cat;

    // issue a confirmation
    int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP802", nil),
                                      NSLocalizedString(@"AP812", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      nil,
                                      account.accountNumber
                                      );
    if (res != NSAlertDefaultReturn) {
        return;
    }

    // check for transactions
    BOOL         keepAssignedStatements = NO;
    NSMutableSet *stats = [cat mutableSetValueForKey: @"statements"];
    if (stats && [stats count] > 0) {
        BOOL hasAssignment = NO;

        // check if transactions are assigned
        for (BankStatement *stat in stats) {
            if ([stat hasAssignment]) {
                hasAssignment = YES;
                break;
            }
        }
        if (hasAssignment) {
            int alertResult = NSRunCriticalAlertPanel(NSLocalizedString(@"AP802", nil),
                                                      NSLocalizedString(@"AP801", nil),
                                                      NSLocalizedString(@"AP3", nil),
                                                      NSLocalizedString(@"AP4", nil),
                                                      NSLocalizedString(@"AP2", nil),
                                                      account.accountNumber
                                                      );
            if (alertResult == NSAlertDefaultReturn) {
                keepAssignedStatements = YES;
            } else {
                if (alertResult == NSAlertOtherReturn) {
                    return;
                } else {keepAssignedStatements = NO; }
            }
        }
    }
    // delete account
    [self removeBankAccount: account keepAssignedStatements: keepAssignedStatements];

    [self save];
}

#pragma mark - Page switching

- (void)updateStatusbar
{
    Category  *cat = [self currentSelection];
    ShortDate *fromDate = [timeSlicer lowerBounds];
    ShortDate *toDate = [timeSlicer upperBounds];

    NSInteger turnovers = 0;
    int       currentPage = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];
    if (currentPage == 0) {
        NSDecimalNumber *turnoversValue = [cat valuesOfType: cat_turnovers from: fromDate to: toDate];
        turnovers = [turnoversValue integerValue];
    }

    if (turnovers > 0) {
        NSDecimalNumber *spendingsValue = [cat valuesOfType: cat_spendings from: fromDate to: toDate];
        NSDecimalNumber *earningsValue = [cat valuesOfType: cat_earnings from: fromDate to: toDate];

        [spendingsField setValue: spendingsValue forKey: @"objectValue"];
        [earningsField setValue: earningsValue forKey: @"objectValue"];
    } else {
        [spendingsField setStringValue: @""];
        [earningsField setStringValue: @""];
    }
}

- (void)updateDetailsPaneButton
{
    toggleDetailsButton.hidden = (toolbarButtons.selectedSegment != 1) || (currentSection != nil);
}

- (IBAction)activateMainPage: (id)sender
{
    [self switchMainPage: [sender selectedSegment]];
}

- (void)switchMainPage: (NSUInteger)page
{
    switch (page) {
        case 0: {
            [currentSection deactivate];
            [transfersController deactivate];
            [self activateHomeScreenTab];
            toolbarButtons.selectedSegment = 0;

            break;
        }

        case 1: {
            [transfersController deactivate];
            [mainTabView selectTabViewItemAtIndex: 0];
            toolbarButtons.selectedSegment = 1;
            [currentSection activate];

            break;
        }
            
        case 2: {
            [currentSection deactivate];
            [self activateTransfersTab];
            toolbarButtons.selectedSegment = 2;

            break;
        }

        case 3: {
            [currentSection deactivate];
            [transfersController deactivate];
            [self activateStandingOrdersTab];
            toolbarButtons.selectedSegment = 3;

            break;
        }

        case 4: {
            [currentSection deactivate];
            [transfersController deactivate];
            [self activateDebitsTab];
            toolbarButtons.selectedSegment = 4;

            break;
        }
    }

    [self updateStatusbar];
    [self updateDetailsPaneButton];
}

- (IBAction)activateAccountPage: (id)sender
{
    BOOL   pageHasChanged = NO;
    NSView *currentView;
    if (currentSection != nil) {
        currentView = [currentSection mainView];
    } else {
        currentView = rightSplitter;
    }

    [statementsButton setImage: [NSImage imageNamed: @"statementlist"]];
    [graph1Button setImage: [NSImage imageNamed: @"graph1"]];
    [graph2Button setImage: [NSImage imageNamed: @"graph2"]];
    [computingButton setImage: [NSImage imageNamed: @"computing"]];
    [rulesButton setImage: [NSImage imageNamed: @"rules"]];
    [heatMapButton setImage: [NSImage imageNamed: @"heat-map"]];

    // Reset fetch predicate for the tree controller if we are switching away from
    // the category periods view.
    if (currentSection != nil && currentSection == categoryPeriodsController && [sender tag] != 3) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == nil"];
        [categoryController setFetchPredicate: predicate];

        // Restore the previous expand state and selection (after a delay, to let the controller
        // propagate the changed content to the outline.
        [self performSelector: @selector(restoreBankAccountItemsStates) withObject: nil afterDelay: 0.1];

        [timeSlicer showControls: YES];
    }

    if (currentSection != nil && currentSection == heatMapController && [sender tag] != 6) {
        [timeSlicer setYearOnlyMode: NO];
    }

    NSRect frame = [currentView frame];
    switch ([sender tag]) {
        case 0:
            // Cross-fade between the active view and the right splitter.
            if (currentSection != nil) {
                [currentSection deactivate];
                [rightSplitter setFrame: frame];
                [rightPane replaceSubview: currentView with: rightSplitter];
                currentSection = nil;

                // update values in category tree to reflect time slicer interval again
                [timeSlicer updateDelegate];
                pageHasChanged = YES;
            }

            [statementsButton setImage: [NSImage imageNamed: @"statementlist-active"]];
            break;

        case 1:
            if (categoryAnalysisController == nil) {
                categoryAnalysisController = [[CategoryAnalysisWindowController alloc] init];
                if ([NSBundle loadNibNamed: @"CategoryAnalysis" owner: categoryAnalysisController]) {
                    NSView *view = [categoryAnalysisController mainView];
                    view.frame = frame;
                }
                [categoryAnalysisController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
            }

            if (currentSection != categoryAnalysisController) {
                [currentSection deactivate];
                [[categoryAnalysisController mainView] setFrame: frame];
                [rightPane replaceSubview: currentView with: [categoryAnalysisController mainView]];
                currentSection = categoryAnalysisController;
                [categoryAnalysisController updateTrackingAreas];
                pageHasChanged = YES;
            }

            [graph1Button setImage: [NSImage imageNamed: @"graph1-active"]];

            // update values in category tree to reflect time slicer interval again
            [timeSlicer updateDelegate];
            break;

        case 2:
            if (categoryReportingController == nil) {
                categoryReportingController = [[CategoryRepWindowController alloc] init];
                if ([NSBundle loadNibNamed: @"CategoryReporting" owner: categoryReportingController]) {
                    NSView *view = [categoryReportingController mainView];
                    view.frame = frame;
                }
                [categoryReportingController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
            }

            if (currentSection != categoryReportingController) {
                [currentSection deactivate];
                [[categoryReportingController mainView] setFrame: frame];
                [rightPane replaceSubview: currentView with: [categoryReportingController mainView]];
                currentSection = categoryReportingController;

                // If a category is selected currently which has no child categories then move the
                // selection to its parent instead.
                Category *category = [self currentSelection];
                if ([[category children] count] < 1) {
                    [categoryController setSelectedObject: category.parent];
                }
                pageHasChanged = YES;
            }

            // Update values in category tree to reflect time slicer interval again.
            [timeSlicer updateDelegate];

            [graph2Button setImage: [NSImage imageNamed: @"graph2-active"]];
            break;

        case 3:
            if (categoryPeriodsController == nil) {
                categoryPeriodsController = [[CategoryPeriodsWindowController alloc] init];
                if ([NSBundle loadNibNamed: @"CategoryPeriods" owner: categoryPeriodsController]) {
                    NSView *view = [categoryPeriodsController mainView];
                    view.frame = frame;
                    [categoryPeriodsController connectScrollViews: accountsScrollView];
                }
                [categoryPeriodsController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
                categoryPeriodsController.outline = accountsView;
            }

            if (currentSection != categoryPeriodsController) {
                [currentSection deactivate];
                [[categoryPeriodsController mainView] setFrame: frame];
                [rightPane replaceSubview: currentView with: [categoryPeriodsController mainView]];
                currentSection = categoryPeriodsController;

                // In order to be able to line up the category entries with the grid we hide the bank
                // accounts.
                [self saveBankAccountItemsStates];

                NSPredicate *predicate = [NSPredicate predicateWithFormat: @"parent == nil && isBankAcc == NO"];
                [categoryController setFetchPredicate: predicate];
                [categoryController prepareContent];
                [timeSlicer showControls: NO];

                pageHasChanged = YES;
            }

            [computingButton setImage: [NSImage imageNamed: @"computing-active"]];
            break;

        case 4:
            if (categoryDefinitionController == nil) {
                categoryDefinitionController = [[CategoryDefWindowController alloc] init];
                if ([NSBundle loadNibNamed: @"CategoryDefinition" owner: categoryDefinitionController]) {
                    NSView *view = [categoryDefinitionController mainView];
                    view.frame = frame;
                }
                [categoryDefinitionController setManagedObjectContext: self.managedObjectContext];
                categoryDefinitionController.timeSliceManager = timeSlicer;
                [categoryDefinitionController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
            }
            if (currentSection != categoryDefinitionController) {
                [currentSection deactivate];
                [[categoryDefinitionController mainView] setFrame: frame];
                [rightPane replaceSubview: currentView with: [categoryDefinitionController mainView]];
                currentSection = categoryDefinitionController;

                // If a bank account is currently selected then switch to the not-assigned category.
                // Bankaccounts don't use rules for assigning transfers to them.
                Category *category = [self currentSelection];
                if ([category isBankAccount]) {
                    [categoryController setSelectedObject: Category.nassRoot];
                }
                pageHasChanged = YES;
            }

            // update values in category tree to reflect time slicer interval again
            [timeSlicer updateDelegate];

            [rulesButton setImage: [NSImage imageNamed: @"rules-active"]];
            break;

        case 6:
            if (heatMapController == nil) {
                heatMapController = [[CategoryHeatMapController alloc] init];
                if ([NSBundle loadNibNamed: @"CategoryHeatMap" owner: heatMapController]) {
                    heatMapController.mainView.frame = frame;
                }
                [heatMapController setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
            }
            if (currentSection != heatMapController) {
                [currentSection deactivate];
                heatMapController.mainView.frame = frame;
                [rightPane replaceSubview: currentView with: heatMapController.mainView];
                currentSection = heatMapController;
                pageHasChanged = YES;
            }
            [timeSlicer setYearOnlyMode: YES];
            [heatMapButton setImage: [NSImage imageNamed: @"heat-map-active"]];
            break;

    }

    if (pageHasChanged) {
        if (currentSection != nil) {
            currentSection.selectedCategory = [self currentSelection];
            [currentSection activate];
        }
        [accountsView setNeedsDisplay];
    }
    [self updateDetailsPaneButton];
}

#pragma mark - File actions

- (IBAction)export: (id)sender
{
    Category *cat;

    cat = [self currentSelection];
    ExportController *controller = [ExportController controller];
    [controller startExport: cat fromDate: [timeSlicer lowerBounds] toDate: [timeSlicer upperBounds]];
}

- (IBAction)import: (id)sender
{
    ImportController *controller = [[ImportController alloc] init];
    int              res = [NSApp runModalForWindow: [controller window]];
    if (res == 0) {
        NSArray        *results = @[controller.importResult];
        NSNotification *notification = [NSNotification notificationWithName: PecuniaStatementsNotification object: results];
        [self statementsNotification: notification];
    }
}

- (BOOL)applicationShouldHandleReopen: (NSApplication *)theApplication hasVisibleWindows: (BOOL)flag
{
    if (flag == NO) {
        [mainWindow makeKeyAndOrderFront: self];
    }
    return YES;
}

- (BOOL)canTerminate
{
    // Check if there are unsent or unfinished transfers. Send unsent transfers if the users says so.
    BOOL canClose = [self checkForUnhandledTransfersAndSend];
    if (!canClose) {
        return NO;
    }

    // check if there are BankUsers. If not, don't show the donation popup
    NSArray *users = [BankUser allUsers];
    if ([users count] == 0) {
        return YES;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           hideDonationMessage = [defaults boolForKey: @"DonationPopup100"];

    if (!hideDonationMessage) {
        DonationMessageController *controller = [[DonationMessageController alloc] init];
        BOOL                      donate = [controller run];
        if (donate) {
            [self performSelector: @selector(donate:) withObject: self afterDelay: 0.0];
            return NO;
        }
    }
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate: (NSApplication *)sender
{
    if ([self canTerminate] == NO) {
        return NSTerminateCancel;
    }
    return NSTerminateNow;
}

- (void)applicationWillTerminate: (NSNotification *)aNotification
{
    shuttingDown = YES;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue: @((int)lastSplitterPosition) forKey: @"rightSplitterPosition"];

    [currentSection deactivate];
    [accountsView saveLayout];

    // Remove explicit bindings and observers to speed up shutdown.
    [categoryController removeObserver: self forKeyPath: @"arrangedObjects.catSum"];
    [categoryAssignments removeObserver: self forKeyPath: @"selectionIndexes"];
    [statementsListView unbind: @"dataSource"];
    [categoryAssignments unbind: @"selectionIndexes"];
    [statementsListView unbind: @"selectedRows"];

    for (id<PecuniaSectionItem> item in [mainTabItems allValues]) {
        if ([(id)item respondsToSelector: @selector(terminate)]) {
            [item terminate];
        }
    }
    if ([categoryAnalysisController respondsToSelector: @selector(terminate)]) {
        [categoryAnalysisController terminate];
    }
    if ([categoryReportingController respondsToSelector: @selector(terminate)]) {
        [categoryReportingController terminate];
    }
    if ([categoryDefinitionController respondsToSelector: @selector(terminate)]) {
        [categoryDefinitionController terminate];
    }
    if ([categoryPeriodsController respondsToSelector: @selector(terminate)]) {
        [categoryPeriodsController terminate];
    }

    dockIconController = nil;

    if (self.managedObjectContext && [MOAssistant assistant].isMaxIdleTimeExceeded == NO) {
        if (![self save]) {
            return;
        }
    }

    [[MOAssistant assistant] shutdown];
    [WorkerThread finish];
}

// workaround for strange outlineView collapsing...
- (void)restoreAccountsView
{
    [accountsView restoreAll];
}

- (int)AccSize
{
    return 20;
}

- (IBAction)showLog: (id)sender
{
    [logController setLogLevel: LogLevel_Verbous];
    [logController showWindow: self];
}

- (BankAccount *)selectedBankAccount
{
    Category *cat = [self currentSelection];
    if (cat == nil) {
        return nil;
    }
    if ([cat isMemberOfClass: [Category class]]) {
        return nil;
    }

    NSString *accNumber = [cat valueForKey: @"accountNumber"];
    if (accNumber == nil || [accNumber isEqual: @""]) {
        return nil;
    }
    return (BankAccount *)cat;
}

- (IBAction)transfer_local: (id)sender
{
    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeStandard withAccount: account];
}

- (IBAction)donate: (id)sender
{
    // check if there are any bank users
    NSArray *users = [BankUser allUsers];
    if (users == nil || users.count == 0) {
        NSRunAlertPanel(NSLocalizedString(@"AP105", nil),
                        NSLocalizedString(@"AP803", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return;
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start transfer editing process.
    [transfersController startDonationTransfer];
}

- (IBAction)transfer_internal: (id)sender
{
    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeInternal withAccount: account];
}

- (IBAction)transfer_dated: (id)sender
{
    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeDated withAccount: account];
}

- (IBAction)transfer_eu: (id)sender
{
    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // check if bic and iban is defined
    if (account != nil) {
        if (account.iban == nil || account.bic == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP101", nil),
                            [NSString stringWithFormat: NSLocalizedString(@"AP77", nil), account.accountNumber],
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return;
        }
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeEU withAccount: account];
}

- (IBAction)transfer_sepa: (id)sender
{
    BankAccount *account = self.selectedBankAccount;
    if (account != nil && [account.isManual boolValue]) {
        return;
    }

    // check if bic and iban is defined
    if (account != nil) {
        if (account.iban == nil || account.bic == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP101", nil),
                            [NSString stringWithFormat: NSLocalizedString(@"AP77", nil), account.accountNumber],
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return;
        }
    }

    // Switch to the transfers page.
    [self switchMainPage: 2];

    // Start local transfer
    [transfersController startTransferOfType: TransferTypeSEPA withAccount: account];
}

- (Category *)currentSelection
{
    NSArray *sel = [categoryController selectedObjects];
    if (sel == nil || [sel count] != 1) {
        return nil;
    }
    return sel[0];
}

#pragma mark - Outline delegate methods

- (id)outlineView: (NSOutlineView *)outlineView persistentObjectForItem: (id)item
{
    return [outlineView persistentObjectForItem: item];
}

- (id)outlineView: (NSOutlineView *)outlineView itemForPersistentObject: (id)object
{
    return nil;
}

/**
 * Prevent the outline from selecting entries under certain conditions.
 */
- (BOOL)outlineView: (NSOutlineView *)outlineView shouldSelectItem: (id)item
{
    if (currentSection != nil) {
        if (currentSection == categoryReportingController) {
            // If category reporting is active then don't allow selecting entries without children.
            return [outlineView isExpandable: item];
        }

        if (currentSection == categoryDefinitionController) {
            Category *category = [item representedObject];
            if ([category isBankAccount]) {
                return NO;
            }
            if ([categoryDefinitionController categoryShouldChange] == NO) {
                return NO;
            }
        }
    }

    return YES;
}

- (BOOL)outlineView: (NSOutlineView *)ov writeItems: (NSArray *)items toPasteboard: (NSPasteboard *)pboard
{
    Category *cat;

    cat = [items[0] representedObject];
    if (cat == nil) {
        return NO;
    }
    if ([cat isBankAccount]) {
        return NO;
    }
    if ([cat isRoot]) {
        return NO;
    }
    if (cat == [Category nassRoot]) {
        return NO;
    }
    NSURL  *uri = [[cat objectID] URIRepresentation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uri];
    [pboard declareTypes: @[CategoryDataType] owner: self];
    [pboard setData: data forType: CategoryDataType];
    return YES;
}

- (NSDragOperation)outlineView: (NSOutlineView *)ov validateDrop: (id <NSDraggingInfo>)info proposedItem: (id)item proposedChildIndex: (NSInteger)childIndex
{
    NSPasteboard *pboard = [info draggingPasteboard];

    // This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
    if (childIndex >= 0) {
        return NSDragOperationNone;
    }
    if (item == nil) {
        return NSDragOperationNone;
    }
    Category *cat = (Category *)[item representedObject];
    if (cat == nil) {
        return NSDragOperationNone;
    }
    [[NSCursor arrowCursor] set];

    NSString *type = [pboard availableTypeFromArray: @[BankStatementDataType, CategoryDataType]];
    if (type == nil) {
        return NO;
    }
    if ([type isEqual: BankStatementDataType]) {
        if ([cat isBankAccount]) {
            // only allow for manual accounts
            BankAccount *account = (BankAccount *)cat;
            if ([account.isManual boolValue] == YES) {
                return NSDragOperationCopy;
            }
            return NSDragOperationNone;
        }

        NSDragOperation mask = [info draggingSourceOperationMask];
        Category        *scat = [self currentSelection];
        if ([cat isRoot]) {
            return NSDragOperationNone;
        }
        // if not yet assigned: move
        if (scat == [Category nassRoot]) {
            return NSDragOperationMove;
        }
        if (mask == NSDragOperationCopy && cat != [Category nassRoot]) {
            return NSDragOperationCopy;
        }
        if (mask == NSDragOperationGeneric && cat != [Category nassRoot]) {
            [splitCursor set];
            return NSDragOperationGeneric;
        }
        return NSDragOperationMove;
    } else {
        if ([cat isBankAccount]) {
            return NSDragOperationNone;
        }
        NSData            *data = [pboard dataForType: type];
        NSURL             *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
        Category          *scat = (Category *)[self.managedObjectContext objectWithID: moID];
        if ([scat checkMoveToCategory: cat] == NO) {
            return NSDragOperationNone;
        }
        return NSDragOperationMove;
    }
}

- (BOOL)outlineView: (NSOutlineView *)outlineView acceptDrop: (id <NSDraggingInfo>)info item: (id)item childIndex: (NSInteger)childIndex
{
    Category     *cat = (Category *)[item representedObject];
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString     *type = [pboard availableTypeFromArray: @[BankStatementDataType, CategoryDataType]];
    if (type == nil) {
        return NO;
    }
    NSData *data = [pboard dataForType: type];

    BOOL needListViewUpdate = NO;
    if ([type isEqual: BankStatementDataType]) {
        NSDragOperation mask = [info draggingSourceOperationMask];
        NSArray         *uris = [NSKeyedUnarchiver unarchiveObjectWithData: data];

        for (NSURL *uri in uris) {
            NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
            if (moID == nil) {
                continue;
            }
            StatCatAssignment *stat = (StatCatAssignment *)[self.managedObjectContext objectWithID: moID];

            if ([[self currentSelection] isBankAccount]) {
                // if already assigned or copy modifier is pressed, copy the complete bank statement amount - else assign residual amount (move)
                if ([cat isBankAccount]) {
                    // drop on a manual account
                    BankAccount *account = (BankAccount *)cat;
                    [account copyStatement: stat.statement];
                    [[Category bankRoot] rollup];
                } else {
                    if (mask == NSDragOperationCopy || [stat.statement.isAssigned boolValue]) {
                        [stat.statement assignToCategory: cat];
                    } else if (mask == NSDragOperationGeneric) {
                        BOOL            negate = NO;
                        NSDecimalNumber *residual = stat.statement.nassValue;
                        if ([residual compare: [NSDecimalNumber zero]] == NSOrderedAscending) {
                            negate = YES;
                        }
                        if (negate) {
                            residual = [[NSDecimalNumber zero] decimalNumberBySubtracting: residual];
                        }
                        
                        AssignmentController *controller = [[AssignmentController alloc] initWithAmount:residual];
                        int res = [NSApp runModalForWindow:controller.window];
                        if (res) {
                            return NO;
                        }
                        residual = controller.amount;
                        
                        if (negate) {
                            residual = [[NSDecimalNumber zero] decimalNumberBySubtracting: residual];
                        }
                        [stat.statement assignAmount: residual toCategory: cat withInfo: controller.info];
                        needListViewUpdate = YES;
                    } else {
                        [stat.statement assignAmount: stat.statement.nassValue toCategory: cat withInfo: nil];
                    }
                }

                // KVO takes care for changes in the category part of the tree. But for accounts the assignments
                // list is not changed by this operation, so we need a manual trigger for screen updates.
                needListViewUpdate = YES;
            } else {
                if (mask == NSDragOperationCopy) {
                    [stat.statement assignAmount: stat.value toCategory: cat withInfo: nil];
                } else if (mask == NSDragOperationGeneric) {
                    // split
                    BOOL            negate = NO;
                    NSDecimalNumber *amount = stat.value;
                    if ([amount compare: [NSDecimalNumber zero]] == NSOrderedAscending) {
                        negate = YES;
                    }
                    if (negate) {
                        amount = [[NSDecimalNumber zero] decimalNumberBySubtracting: amount];
                    }
                    
                    AssignmentController *controller = [[AssignmentController alloc] initWithAmount:amount];
                    int res = [NSApp runModalForWindow:controller.window];
                    if (res) {
                        return NO;
                    }
                    amount = controller.amount;
                    
                    if (negate) {
                        amount = [[NSDecimalNumber zero] decimalNumberBySubtracting: amount];
                    }
                    // now we have the amount that should be assigned to the target category
                    if ([[amount abs] compare: [stat.value abs]] != NSOrderedDescending) {
                        [stat moveAmount: amount toCategory: cat withInfo: controller.info];
                        needListViewUpdate = YES;
                    }
                } else {
                    [stat moveToCategory: cat];
                }
            }
        }
        // update values including rollup
        [Category updateCatValues];
    } else {
        NSURL             *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        NSManagedObjectID *moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri];
        if (moID == nil) {
            return NO;
        }
        Category *scat = (Category *)[self.managedObjectContext objectWithID: moID];
        [scat setValue: cat forKey: @"parent"];
        [[Category catRoot] rollup];
    }

    [self save];

    if (needListViewUpdate) {
        // Updating the assignments (statments) list kills the current selection, so we preserve it here.
        // Reassigning it after the update has the neat side effect that the details pane is properly updated too.
        NSUInteger selection = categoryAssignments.selectionIndex;
        categoryAssignments.selectionIndex = NSNotFound;
        [statementsListView reloadData];
        categoryAssignments.selectionIndex = selection;
    }
    return YES;
}

- (void)outlineViewSelectionDidChange: (NSNotification *)aNotification
{
    if (shuttingDown) {
        return;
    }

    Category *cat = [self currentSelection];

    // set states of categorie Actions Control
    [catActions setEnabled: [cat isRemoveable] forSegment: 2];
    [catActions setEnabled: [cat isInsertable] forSegment: 1];

    BOOL editable = NO;
    if (![cat isBankAccount] && cat != [Category nassRoot] && cat != [Category catRoot]) {
        editable = categoryAssignments.selectedObjects.count == 1;
    }

    // value field
    [valueField setEditable: editable];
    if (editable) {
        [valueField setDrawsBackground: YES];
        [valueField setBackgroundColor: [NSColor whiteColor]];
    } else {
        [valueField setDrawsBackground: NO];
    }

    // Update current section if the default is not active.
    if (currentSection != nil) {
        currentSection.selectedCategory = cat;
    }

}

- (void)outlineView: (NSOutlineView *)outlineView willDisplayCell: (ImageAndTextCell *)cell
     forTableColumn: (NSTableColumn *)tableColumn item: (id)item
{
    if (![[tableColumn identifier] isEqualToString: @"name"]) {
        return;
    }

    Category *cat = [item representedObject];
    if (cat == nil) {
        return;
    }

    cell.swatchColor = cat.categoryColor;

    if (moneyImage == nil) {
        moneyImage = [NSImage imageNamed: @"money_18.png"];
        moneySyncImage = [NSImage imageNamed: @"money_sync_18.png"];

        NSString *path = [[NSBundle mainBundle] pathForResource: @"icon95-1"
                                                         ofType: @"icns"
                                                    inDirectory: @"Collections/1/"];
        bankImage = [[NSImage alloc] initWithContentsOfFile: path];
    }

    if (cat.iconName == nil) {
        [self determineDefaultIconForCategory: cat];
    }

    if ([cat.iconName length] > 0) {
        NSString *path;
        if ([cat.iconName isAbsolutePath]) {
            path = cat.iconName;
        } else {
            NSString *subfolder = [cat.iconName stringByDeletingLastPathComponent];
            if (subfolder.length > 0) {
                path = [[NSBundle mainBundle] pathForResource: [cat.iconName lastPathComponent]
                                                       ofType: @"icns"
                                                  inDirectory: subfolder];
            } else {
                [cell setImage: nil];
            }
        }
        if (path != nil) {
            // Also assigns nil if the path doesn't exist or the referenced file cannot be used as image.
            [cell setImage: [[NSImage alloc] initWithContentsOfFile: path]];
        } else {
            [cell setImage: nil];
        }
    } else {
        [cell setImage: nil];
    }

    NSInteger numberUnread = 0;

    if ([cat isBankAccount] && cat.accountNumber == nil) {
        [cell setImage: bankImage];
    }

    if ([cat isBankAccount] && cat.accountNumber != nil) {
        BankAccount *account = (BankAccount *)cat;
        if ([account.isManual boolValue] || [account.noAutomaticQuery boolValue]) {
            [cell setImage: moneyImage];
        } else {
            [cell setImage: moneySyncImage];
        }
    }

    if (![cat isBankAccount] || [cat isRoot]) {
        numberUnread = 0;
    } else {
        numberUnread = [(BankAccount *)cat unread];
    }

    BOOL itemIsDisabled = NO;
    if (currentSection != nil) {
        if (currentSection == categoryReportingController && [[cat children] count] == 0) {
            itemIsDisabled = YES;
        }
        if (currentSection == categoryDefinitionController && [cat isBankAccount]) {
            itemIsDisabled = YES;
        }
    }

    BOOL itemIsRoot = [cat isRoot];
    if (itemIsRoot) {
        [cell setImage: nil];
    }

    [cell setValues: cat.catSum
           currency: cat.currency
             unread: numberUnread
           disabled: itemIsDisabled
             isRoot: itemIsRoot
           isHidden: cat.isHidden.boolValue
          isIgnored: cat.noCatRep.boolValue];
}

- (CGFloat)outlineView: (NSOutlineView *)outlineView heightOfRowByItem: (id)item
{
    return 22;
}

#pragma mark - Splitview delegate methods

- (CGFloat)splitView: (NSSplitView *)splitView constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainVSplit) {
        return 370;
    }
    if (splitView == rightSplitter) {
        return 240;
    }
    return proposedMin;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainVSplit) {
        return NSWidth([mainWindow frame]) - 800;
    }
    if (splitView == rightSplitter) {
        return NSHeight([rightSplitter frame]) - 300;
    }
    return proposedMax;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainSplitPosition: (CGFloat)proposedPosition ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == rightSplitter) {
        // This function is called only when dragging the divider with the mouse. If the details pane is currently collapsed
        // then it is automatically shown when dragging the divider. So we have to reset our interal state.
        if (lastSplitterPosition > 0) {
            lastSplitterPosition = 0;
            [toggleDetailsButton setImage: [NSImage imageNamed: @"hide"]];
        }
    }

    return proposedPosition;
}

#pragma mark - Sorting and searching statements

- (IBAction)filterStatements: (id)sender
{
    NSTextField *te = sender;
    NSString    *searchName = [te stringValue];

    if ([searchName length] == 0) {
        [categoryAssignments setFilterPredicate: [timeSlicer predicateForField: @"date"]];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithFormat: @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or userInfo contains[c] %@ or value = %@",
                             searchName, searchName, searchName, [NSDecimalNumber decimalNumberWithString: searchName locale: [NSLocale currentLocale]]];
        if (pred != nil) {
            [categoryAssignments setFilterPredicate: pred];
        }
    }
}

- (IBAction)sortingChanged: (id)sender
{
    if ([sender selectedSegment] == sortIndex) {
        sortAscending = !sortAscending;
    } else {
        sortAscending = NO; // Per default entries are sorted by date in decreasing order.
    }

    [self updateSorting];
}

#pragma mark - Menu handling

- (BOOL)validateMenuItem: (NSMenuItem *)item
{
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];

    if (idx != 0) {
        if ([item action] == @selector(export:)) {
            return NO;
        }
        if ([item action] == @selector(addAccount:)) {
            return NO;
        }
        if ([item action] == @selector(changeAccount:)) {
            return NO;
        }
        if ([item action] == @selector(deleteAccount:)) {
            return NO;
        }
        if ([item action] == @selector(enqueueRequest:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_local:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_eu:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_sepa:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_dated:)) {
            return NO;
        }
        if ([item action] == @selector(transfer_internal:)) {
            return NO;
        }
        if ([item action] == @selector(splitStatement:)) {
            return NO;
        }
        if ([item action] == @selector(donate:)) {
            return NO;
        }
        if ([item action] == @selector(deleteStatement:)) {
            return NO;
        }
        if ([item action] == @selector(addStatement:)) {
            return NO;
        }
        if ([item action] == @selector(creditCardSettlements:)) {
            return NO;
        }
    }

    if (idx == 0) {
        Category *cat = [self currentSelection];
        if (cat == nil || [cat accountNumber] == nil) {
            if ([item action] == @selector(enqueueRequest:)) {
                return NO;
            }
            if ([item action] == @selector(changeAccount:)) {
                return NO;
            }
            if ([item action] == @selector(deleteAccount:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_local:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_eu:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_sepa:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_dated:)) {
                return NO;
            }
            if ([item action] == @selector(transfer_internal:)) {
                return NO;
            }
            if ([item action] == @selector(addStatement:)) {
                return NO;
            }
            if ([item action] == @selector(creditCardSettlements:)) {
                return NO;
            }
        }
        if ([cat isKindOfClass: [BankAccount class]]) {
            BankAccount *account = (BankAccount *)cat;
            if ([[account isManual] boolValue] == YES) {
                if ([item action] == @selector(transfer_local:)) {
                    return NO;
                }
                if ([item action] == @selector(transfer_eu:)) {
                    return NO;
                }
                if ([item action] == @selector(transfer_sepa:)) {
                    return NO;
                }
                if ([item action] == @selector(transfer_dated:)) {
                    return NO;
                }
                if ([item action] == @selector(transfer_internal:)) {
                    return NO;
                }
                if ([item action] == @selector(creditCardSettlements:)) {
                    return NO;
                }
            } else {
                if ([item action] == @selector(addStatement:)) {
                    return NO;
                }
                if ([item action] == @selector(creditCardSettlements:)) {
                    if ([[HBCIClient hbciClient] isTransactionSupported: TransactionType_CCSettlement forAccount: account] == NO) {
                        return NO;
                    }
                }
            }
        }

        if ([item action] == @selector(deleteStatement:)) {
            if ([cat isBankAccount] == NO || categoryAssignments.selectedObjects.count == 0) {
                return NO;
            }
        }
        if ([item action] == @selector(splitStatement:)) {
            if ([[categoryAssignments selectedObjects] count] != 1) {
                return NO;
            }
        }
        if (requestRunning && [item action] == @selector(enqueueRequest:)) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Category management

- (void)updateNotAssignedCategory
{
    NSError *error = nil;

    // fetch all bank statements
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: self.managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSArray *stats = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    for (BankStatement *stat in stats) {
        [stat updateAssigned];
    }

    [self save];
}

- (void)deleteCategory: (id)sender
{
    Category *cat = [self currentSelection];
    if (cat == nil) {
        return;
    }

    if ([cat isRemoveable] == NO) {
        return;
    }
    NSArray           *stats = [[cat mutableSetValueForKey: @"assignments"] allObjects];
    StatCatAssignment *stat;

    if ([stats count] > 0) {
        int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP303", nil),
                                          NSLocalizedString(@"AP304", nil),
                                          NSLocalizedString(@"AP4", nil),
                                          NSLocalizedString(@"AP3", nil),
                                          nil,
                                          [cat localName],
                                          [stats count],
                                          nil
                                          );
        if (res != NSAlertAlternateReturn) {
            return;
        }
    }

    //  Delete bank statements from category first.
    for (stat in stats) {
        [stat remove];
    }
    [categoryController remove: cat];
    [Category updateCatValues];

    // workaround: NSTreeController issue: when an item is removed and the NSOutlineViewSelectionDidChange notification is sent,
    // the selectedObjects: message returns the wrong (the old) selection
    [self performSelector: @selector(outlineViewSelectionDidChange:) withObject: nil afterDelay: 0];

    // Save changes to avoid losing category changes in case of failures/crashs.
    [self save];
}

- (void)addCategory: (id)sender
{
    Category *cat = [self currentSelection];
    if (cat.isBankAccount) {
        return;
    }
    if (cat.isRoot) {
        [categoryController addChild: sender];
    } else {
        [categoryController add: sender];
    }
    [accountsView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];

    [self save];
}

- (void)insertCategory: (id)sender
{
    Category *cat = [self currentSelection];
    if ([cat isInsertable] == NO) {
        return;
    }
    [categoryController addChild: sender];
    [accountsView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];

    [self save];
}

- (IBAction)manageCategories: (id)sender
{
    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment: clickedSegment];
    switch (clickedSegmentTag) {
        case 0:[self addCategory: sender]; break;

        case 1:[self insertCategory: sender]; break;

        case 2:[self deleteCategory: sender]; break;

        default: return;
    }
    [currentSection activate]; // Notifies the current section to updates values if necessary.
}

- (NSString *)autosaveNameForTimeSlicer: (TimeSliceManager *)tsm
{
    return @"AccMainTimeSlice";
}

- (void)timeSliceManager: (TimeSliceManager *)tsm changedIntervalFrom: (ShortDate *)from to: (ShortDate *)to
{
    if (self.managedObjectContext == nil) {
        return;
    }
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];
    if (idx) {
        return;
    }
    [Category setCatReportFrom: from to: to];

    // todo: remove filter stuff
    // change filter
    /*
     NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(statement.date => %@) AND (statement.date <= %@)", [from lowDate], [to highDate]];
     [categoryAssignments setFilterPredicate: predicate];
     */
    [[self currentSelection] updateBoundAssignments];

    // Update current section if the default is not active.
    if (currentSection != nil) {
        [currentSection setTimeRangeFrom: [timeSlicer lowerBounds] to: [timeSlicer upperBounds]];
    }

    [self updateStatusbar];
}

- (void)controlTextDidBeginEditing: (NSNotification *)aNotification
{
    if ([aNotification object] == accountsView) {
        Category *cat = [self currentSelection];
        accountsView.saveCatName = [cat name];
    }
    if ([aNotification object] == valueField) {
        NSArray *sel = [categoryAssignments selectedObjects];
        if (sel && [sel count] == 1) {
            StatCatAssignment *stat = sel[0];
            self.saveValue = stat.value;
        }
    }
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    // Category name changed
    if ([aNotification object] == accountsView) {
        Category *cat = [self currentSelection];
        if ([cat name] == nil) {
            [cat setValue: accountsView.saveCatName forKey: @"name"];
        }
        [categoryController resort];
        if (cat) {
            [categoryController setSelectedObject: cat];
        }
        
        // Category was created or changed. Save changes.
        [self save];
    }

    // Value field changed (todo: replace by key value observation).
    if ([aNotification object] == valueField) {
        NSArray *sel = [categoryAssignments selectedObjects];
        if (sel && [sel count] == 1) {
            StatCatAssignment *stat = sel[0];

            // do some checks
            // amount must have correct sign
            NSDecimal d1 = [stat.statement.value decimalValue];
            NSDecimal d2 = [stat.value decimalValue];
            if (d1._isNegative != d2._isNegative) {
                NSBeep();
                stat.value = self.saveValue;
                return;
            }

            // amount must not be higher than original amount
            if (d1._isNegative) {
                if ([stat.value compare: stat.statement.value] == NSOrderedAscending) {
                    NSBeep();
                    stat.value = self.saveValue;
                    return;
                }
            } else {
                if ([stat.value compare: stat.statement.value] == NSOrderedDescending) {
                    NSBeep();
                    stat.value = self.saveValue;
                    return;
                }
            }

            // [Category updateCatValues] invalidates the selection we got. So re-set it first and then update.
            [categoryAssignments setSelectedObjects: sel];

            [stat.statement updateAssigned];
            Category *cat = [self currentSelection];
            if (cat !=  nil) {
                [cat invalidateBalance];
                [Category updateCatValues];
                [statementsListView updateVisibleCells];
            }
        }
    }
}

- (void)setRestart
{
    restart = YES;
}

- (IBAction)deleteStatement: (id)sender
{
    if (!self.currentSelection.isBankAcc.boolValue) {
        return;
    }

    // Process all selected assignments. If only a single assignment is selected then do an extra round
    // regarding duplication check and confirmation from the user. Otherwise just confirm the delete operation as such.
    NSArray *assignments = [categoryAssignments selectedObjects];
    BOOL    doDuplicateCheck = assignments.count == 1;

    if (!doDuplicateCheck) {
        int result = NSRunAlertPanel(NSLocalizedString(@"AP806", nil),
                                     NSLocalizedString(@"AP809", nil),
                                     NSLocalizedString(@"AP3", nil),
                                     NSLocalizedString(@"AP4", nil),
                                     nil, assignments.count);
        if (result != NSAlertDefaultReturn) {
            return;
        }
    }

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: self.managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSMutableSet *affectedAccounts = [[NSMutableSet alloc] init];
    for (StatCatAssignment *assignment in assignments) {
        BankStatement *statement = assignment.statement;

        NSError *error = nil;
        BOOL    deleteStatement = NO;

        if (doDuplicateCheck) {
            // Check if this statement is a duplicate. Select all statements with same date.
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date = %@)", statement.account, statement.date];
            [request setPredicate: predicate];

            NSArray *possibleDuplicates = [self.managedObjectContext executeFetchRequest: request error: &error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }

            BOOL hasDuplicate = NO;
            for (BankStatement *possibleDuplicate in possibleDuplicates) {
                if (possibleDuplicate != statement && [possibleDuplicate matches: statement]) {
                    hasDuplicate = YES;
                    break;
                }
            }
            int res;
            if (hasDuplicate) {
                res = NSRunAlertPanel(NSLocalizedString(@"AP805", nil),
                                      NSLocalizedString(@"AP807", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      nil);
                if (res == NSAlertDefaultReturn) {
                    deleteStatement = YES;
                }
            } else {
                res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP805", nil),
                                              NSLocalizedString(@"AP808", nil),
                                              NSLocalizedString(@"AP4", nil),
                                              NSLocalizedString(@"AP3", nil),
                                              nil);
                if (res == NSAlertAlternateReturn) {
                    deleteStatement = YES;
                }
            }
        } else {
            deleteStatement = YES;
        }

        if (deleteStatement) {
            BOOL isManualAccount = statement.account.isManual;
            BankAccount *account = statement.account;
            [affectedAccounts addObject: account]; // Automatically ignores duplicates.

            [self.managedObjectContext deleteObject: statement];

            // Rebuild balances - only for manual accounts.
            if (isManualAccount) {
                NSPredicate *balancePredicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date > %@)", account, statement.date];
                request.predicate = balancePredicate;
                NSArray *remainingStatements = [self.managedObjectContext executeFetchRequest: request error: &error];
                if (error != nil) {
                    NSAlert *alert = [NSAlert alertWithError: error];
                    [alert runModal];
                    return;
                }

                for (BankStatement *remainingStatement in remainingStatements) {
                    remainingStatement.saldo = [remainingStatement.saldo decimalNumberBySubtracting: statement.value];
                }
                account.balance = [account.balance decimalNumberBySubtracting: statement.value];
            }
        }
    }

    for (BankAccount *account in affectedAccounts) {
        // Special behaviour for top bank accounts.
        if (account.accountNumber == nil) {
            [self.managedObjectContext processPendingChanges];
        }
        [account updateBoundAssignments];
    }
    
    [[Category bankRoot] rollup];
    [categoryAssignments prepareContent];

    [self save];
}

- (void)splitStatement: (id)sender
{
    int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]];
    if (idx == 0) {
        NSArray *sel = [categoryAssignments selectedObjects];
        if (sel != nil && [sel count] == 1) {
            StatSplitController *splitController = [[StatSplitController alloc] initWithStatement: [sel[0] statement]
                                                                                             view: accountsView];
            [NSApp runModalForWindow: [splitController window]];
        }
    }
}

- (IBAction)addStatement: (id)sender
{
    Category *cat = [self currentSelection];
    if (cat == nil) {
        return;
    }
    if (cat.accountNumber == nil) {
        return;
    }

    BankStatementController *statementController = [[BankStatementController alloc] initWithAccount: (BankAccount *)cat statement: nil];

    int res = [NSApp runModalForWindow: [statementController window]];
    if (res) {
        [cat updateBoundAssignments];
        [self save];
    }
}

- (IBAction)splitPurpose: (id)sender
{
    Category *cat = [self currentSelection];

    PurposeSplitController *splitController = [[PurposeSplitController alloc] initWithAccount: (BankAccount *)cat];
    [NSApp runModalForWindow: [splitController window]];
}

/**
 * Takes the (localized) title of the given category and determines an icon for it from the default collection.
 */
- (void)determineDefaultIconForCategory: (Category *)category
{
    if (defaultIcons == nil) {
        NSMutableArray *entries = [NSMutableArray arrayWithCapacity: 100];

        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *path = [mainBundle pathForResource: @"category-icon-defaults" ofType: @"txt"];
        NSError  *error = nil;
        NSString *s = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
        if (error) {
            NSLog(@"Error reading default category icon assignments file at %@\n%@", path, [error localizedFailureReason]);
        } else {
            NSArray *lines = [s componentsSeparatedByString: @"\n"];
            for (__strong NSString *line in lines) {
                NSRange hashPosition = [line rangeOfString: @"#"];
                if (hashPosition.length > 0) {
                    line = [line substringToIndex: hashPosition.location];
                }
                line = [line stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                if (line.length == 0) {
                    continue;
                }

                NSArray *components = [line componentsSeparatedByString: @"="];
                if (components.count < 2) {
                    continue;
                }
                NSString *icon = [components[0] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                NSArray  *keywordArray = [components[1] componentsSeparatedByString: @","];

                NSMutableArray *keywords = [NSMutableArray arrayWithCapacity: keywordArray.count];
                for (__strong NSString *keyword in keywordArray) {
                    keyword = [keyword stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                    if (keyword.length == 0) {
                        continue;
                    }
                    [keywords addObject: keyword];
                }
                NSDictionary *entry = @{@"icon": icon, @"keywords": keywords};
                [entries addObject: entry];
            }
        }

        defaultIcons = entries;
    }

    // Finding a default icon means to compare the category title with all the keywords we have in our defaultIcons
    // list. For flexibility we also compare substrings. Exact matches get priority though. If there's more than one hit
    // of the same priority then that wins which has fewer keywords assigned (so is likely more specialized).
    NSString *name = category.name;
    if ([name hasPrefix: @"++"]) {
        // One of the predefined root notes. They don't have an image.
        category.iconName = @"";
        return;
    }

    NSString   *bestMatch = @"";
    BOOL       exactMatch = NO;
    NSUInteger currentCount = 1000; // Number of keywords assigned to the best match so far.
    for (NSDictionary *entry in defaultIcons) {
        NSArray *keywords = entry[@"keywords"];
        for (NSString *keyword in keywords) {
            if ([keyword caseInsensitiveCompare: @"Default"] == NSOrderedSame && bestMatch.length == 0) {
                // No match so far, but we found the default entry. Keep this as first best match.
                bestMatch = entry[@"icon"];
                continue;
            }
            NSRange range = [name rangeOfString: keyword options: NSCaseInsensitiveSearch];
            if (range.length == 0) {
                continue; // No match at all.
            }

            if (range.length == name.length) {
                // Exact match. If there wasn't any exact match before then use this one as the current
                // best match, ignoring any previous partial matches.
                if (!exactMatch || keywords.count < currentCount) {
                    exactMatch = YES;
                    bestMatch = entry[@"icon"];
                    currentCount = keywords.count;
                }

                // If the current keyword count is 1 then we can't get any better. So stop here with what we have.
                if (currentCount == 1) {
                    category.iconName = bestMatch;
                    return;
                }
            } else {
                // Only consider this partial match if we haven't had any exact match so far.
                if (!exactMatch && keywords.count < currentCount) {
                    bestMatch = entry[@"icon"];
                    currentCount = keywords.count;
                }
            }
        }
    }
    // The icon determined is one of the default collection.
    category.iconName = [@"Collections/1/" stringByAppendingString : bestMatch];
}

#pragma mark - Miscellaneous code

/**
 * Saves the expand states of the top bank account node and all its children.
 * Also saves the current selection if it is on a bank account.
 */
- (void)saveBankAccountItemsStates
{
    Category *category = [self currentSelection];
    if ([category isBankAccount]) {
        lastSelection = category;
        [categoryController setSelectedObject: Category.nassRoot];
    }
    bankAccountItemsExpandState = [NSMutableArray array];
    NSUInteger row, numberOfRows = [accountsView numberOfRows];

    for (row = 0; row < numberOfRows; row++) {
        id       item = [accountsView itemAtRow: row];
        Category *category = [item representedObject];
        if (![category isBankAccount]) {
            break;
        }
        if ([accountsView isItemExpanded: item]) {
            [bankAccountItemsExpandState addObject: category];
        }
    }
}

/**
 * Restores the previously saved expand states of all bank account nodes and sets the
 * last selection if it was on a bank account node.
 */
- (void)restoreBankAccountItemsStates
{
    NSUInteger row, numberOfRows = [accountsView numberOfRows];
    for (Category *savedItem in bankAccountItemsExpandState) {
        for (row = 0; row < numberOfRows; row++) {
            id       item = [accountsView itemAtRow: row];
            Category *object = [item representedObject];
            if ([object.name isEqualToString: savedItem.name]) {
                [accountsView expandItem: item];
                numberOfRows = [accountsView numberOfRows];
                break;
            }
        }
    }
    bankAccountItemsExpandState = nil;

    // Restore the last selection, but only when selecting the item is allowed.
    if (lastSelection != nil && currentSection != categoryReportingController && currentSection != categoryDefinitionController) {
        [categoryController setSelectedObject: lastSelection];
    }
    lastSelection = nil;
}

- (void)syncAllAccounts
{
    NSError        *error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"allBankAccounts"];
    NSArray        *selectedAccounts = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error) {
        NSLog(@"Read bank accounts error on automatic sync");
        return;
    }

    // now selectedAccounts has all selected Bank Accounts
    BankAccount    *account;
    NSMutableArray *resultList = [NSMutableArray arrayWithCapacity: [selectedAccounts count]];
    for (account in selectedAccounts) {
        if ([account.noAutomaticQuery boolValue] == YES) {
            continue;
        }

        BankQueryResult *result = [[BankQueryResult alloc] init];
        result.accountNumber = account.accountNumber;
        result.accountSubnumber = account.accountSuffix;
        result.bankCode = account.bankCode;
        result.userId = account.userId;
        result.account = account;
        [resultList addObject: result];
    }
    // prepare UI
    [[[mainWindow contentView] viewWithTag: 100] setEnabled: NO];
    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP219", nil) removeAfter: 0];

    // get statements in separate thread
    autoSyncRunning = YES;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(statementsNotification:)
                                                 name: PecuniaStatementsNotification
                                               object: nil];
    [[HBCIClient hbciClient] getStatements: resultList];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: [NSDate date] forKey: @"lastSyncDate"];

    // if autosync, setup next timer event
    BOOL autoSync = [defaults boolForKey: @"autoSync"];
    if (autoSync) {
        NSDate *syncTime = [defaults objectForKey: @"autoSyncTime"];
        if (syncTime == nil) {
            NSLog(@"No autosync time defined");
            return;
        }
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        // set date +24Hr
        NSDateComponents *comps1 = [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate: [NSDate dateWithTimeIntervalSinceNow: 86400]];
        NSDateComponents *comps2 = [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: syncTime];
        [comps1 setHour: [comps2 hour]];
        [comps1 setMinute: [comps2 minute]];
        NSDate *syncDate = [calendar dateFromComponents: comps1];
        // syncTime in future: setup Timer
        NSTimer *timer = [[NSTimer alloc] initWithFireDate: syncDate
                                                  interval: 0.0
                                                    target: self
                                                  selector: @selector(autoSyncTimerEvent)
                                                  userInfo: nil
                                                   repeats: NO];
        [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
    }
}

- (void)checkForAutoSync
{
    BOOL           syncDone = NO;
    NSDate         *syncTime;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           syncAtStartup = [defaults boolForKey: @"syncAtStartup"];
    BOOL           autoSync = [defaults boolForKey: @"autoSync"];
    if (!(autoSync || syncAtStartup)) {
        return;
    }
    if (autoSync) {
        syncTime = [defaults objectForKey: @"autoSyncTime"];
        if (syncTime == nil) {
            NSLog(@"No autosync time defined");
            autoSync = NO;
        }
    }
    NSDate    *lastSyncDate = [defaults objectForKey: @"lastSyncDate"];
    ShortDate *d1 = [ShortDate dateWithDate: lastSyncDate];
    ShortDate *d2 = [ShortDate dateWithDate: [NSDate date]];
    if ((d1 == nil || [d1 compare: d2] != NSOrderedSame) && syncAtStartup) {
        // no sync done today. If in startup, do immediate sync
        [self performSelector: @selector(syncAllAccounts) withObject: nil afterDelay: 5.0];
        syncDone = YES;
    }

    if (!autoSync) {
        return;
    }
    // get today's sync time.
    NSCalendar       *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    NSDateComponents *comps1 = [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate: [NSDate date]];
    NSDateComponents *comps2 = [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: syncTime];

    [comps1 setHour: [comps2 hour]];
    [comps1 setMinute: [comps2 minute]];
    NSDate *syncDate = [calendar dateFromComponents: comps1];
    // if syncTime has passed, do immediate sync
    if ([syncDate compare: [NSDate date]] == NSOrderedAscending) {
        if (!syncDone) {
            [self performSelector: @selector(syncAllAccounts) withObject: nil afterDelay: 5.0];
        }
    } else {
        // syncTime in future: setup Timer
        NSTimer *timer = [[NSTimer alloc] initWithFireDate: syncDate
                                                  interval: 0.0
                                                    target: self
                                                  selector: @selector(autoSyncTimerEvent)
                                                  userInfo: nil
                                                   repeats: NO];
        [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
    }
}

- (IBAction)showLicense: (id)sender
{
    NSString *path = [[NSBundle mainBundle] pathForResource: @"gpl-2.0-standalone" ofType: @"html"];
    [[NSWorkspace sharedWorkspace] openFile: path];
}

- (IBAction)showConsole:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"Console"];
}

- (void)applicationWillFinishLaunching: (NSNotification *)notification
{
    /*
    // Check License Agreement
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
    BOOL licenseAgreed = [defaults boolForKey:@"licenseAgreed" ];
    if (licenseAgreed == NO) {
        int result = [NSApp runModalForWindow:licenseWindow ];
        if (result == 1) {
            [NSApp terminate:nil ];
            return;
        } else {
            [defaults setBool:YES forKey:@"licenseAgreed" ];
        }
    }
    */
    
    // Display main window
    [mainWindow display];
    [mainWindow makeKeyAndOrderFront: self];

    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    [sc setMessage: NSLocalizedString(@"AP108", nil) removeAfter: 0];

    rightSplitter.fixedIndex = 1;
    mainVSplit.fixedIndex = 0;

    tagViewPopup.datasource = tagsController;
    tagViewPopup.defaultFont = [NSFont fontWithName: PreferenceController.popoverFontName size: 10];
    tagViewPopup.canCreateNewTags = YES;

    tagsField.datasource = statementTags;
    tagsField.defaultFont = [NSFont fontWithName: PreferenceController.popoverFontName size: 10];
    tagsField.canCreateNewTags = YES;

}

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
    StatusBarController *sc = [StatusBarController controller];
    MOAssistant         *assistant = [MOAssistant assistant];

    // Load context & model.
    @try {
        model = [assistant model];
        [assistant initDatafile: nil]; // use default data file
        self.managedObjectContext = [assistant context];
    }
    @catch (NSError *error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        [NSApp terminate: self];
    }

    // Open encrypted database
    if ([assistant encrypted]) {
        StatusBarController *sc = [StatusBarController controller];
        [sc startSpinning];
        [sc setMessage: NSLocalizedString(@"AP108", nil) removeAfter: 0];

        @try {
            [assistant decrypt];
            self.managedObjectContext = [assistant context];
        }
        @catch (NSError *error) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            [NSApp terminate: self];
        }
    }

    [self migrate];

    [self publishContext];
    [sc stopSpinning];
    [sc clearMessage];

    [self activateMainPage: nil];

    // Display main window.
    [mainWindow display];
    [mainWindow makeKeyAndOrderFront: self];

    [self checkForAutoSync];

    // Add default tags if there are none yet.
    NSError        *error = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"allTags"];
    NSUInteger     count = [self.managedObjectContext countForFetchRequest: request error: &error];
    if (error != nil) {
        NSLog(@"Error reading tags: %@", error.localizedDescription);
    }
    if (count == 0) {
        [Tag createDefaultTags];
    }

    // Add default categories if there aren't any but the predefined ones.
    if ([Category.catRoot.children count] == 1) {
        [Category createDefaultCategories];
    }

    // Check if there are any bank users or at least manual accounts.
    if (BankUser.allUsers.count == 0 && [Category.bankRoot.children count] == 0) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP804", nil),
                                  NSLocalizedString(@"AP151", nil),
                                  NSLocalizedString(@"AP3", nil),
                                  NSLocalizedString(@"AP800", nil),
                                  nil
                                  );
        if (res == NSAlertDefaultReturn) {
            [self editBankUsers: self];
        }
    }
}

- (void)autoSyncTimerEvent: (NSTimer *)theTimer
{
    [self syncAllAccounts];
}

- (BOOL)checkForUnhandledTransfersAndSend
{
    // Check for a new transfer not yet finished.
    if ([transfersController editingInProgress]) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP109", nil),
                                  NSLocalizedString(@"AP431", nil),
                                  NSLocalizedString(@"AP411", nil),
                                  NSLocalizedString(@"AP412", nil),
                                  nil
                                  );
        if (res == NSAlertAlternateReturn) {
            [self switchMainPage: 2];
            return NO;
        }
        [transfersController cancelEditing];
    }

    // Check for unsent transfers.
    NSError             *error = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"Transfer" inManagedObjectContext: self.managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isSent = NO"];
    [request setPredicate: predicate];
    NSArray *transfers = [self.managedObjectContext executeFetchRequest: request error: &error];
    if (error || [transfers count] == 0) {
        return YES;
    }

    int res = NSRunAlertPanel(NSLocalizedString(@"AP109", nil),
                              NSLocalizedString(@"AP430", nil),
                              NSLocalizedString(@"AP7", nil),
                              NSLocalizedString(@"AP412", nil),
                              NSLocalizedString(@"AP432", nil),
                              nil
                              );
    if (res == NSAlertDefaultReturn) {
        return YES;
    }
    if (res == NSAlertAlternateReturn) {
        [self switchMainPage: 2];
        return NO;
    }

    // send transfers
    BOOL sent = [[HBCIClient hbciClient] sendTransfers: transfers];
    if (sent) {
        [self save];
    }
    return NO;
}

- (void)updateUnread
{
    NSTableColumn *tc = [accountsView tableColumnWithIdentifier: @"name"];
    if (tc) {
        ImageAndTextCell *cell = (ImageAndTextCell *)[tc dataCell];
        // update unread information
        NSInteger maxUnread = [BankAccount maxUnread];
        [cell setMaxUnread: maxUnread];
    }
}

- (void)printCurrentAccountsView
{
    if (currentSection == nil) {
        NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
        [printInfo setTopMargin: 45];
        [printInfo setBottomMargin: 45];
        NSPrintOperation *printOp;
        NSView           *view = [[BankStatementPrintView alloc] initWithStatements: [categoryAssignments arrangedObjects] printInfo: printInfo];
        printOp = [NSPrintOperation printOperationWithView: view printInfo: printInfo];
        [printOp setShowsPrintPanel: YES];
        [printOp runOperation];

        return;
    }

    [currentSection print];
}

- (IBAction)printDocument: (id)sender
{
    switch ([mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem]]) {
        case 0:
            [self printCurrentAccountsView];
            break;

        case 1: {
            [transfersController print];
            /*
             NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo];
             [printInfo setTopMargin:45];
             [printInfo setBottomMargin:45];
             [printInfo setHorizontalPagination:NSFitPagination];
             [printInfo setVerticalPagination:NSFitPagination];
             NSPrintOperation *printOp;
             printOp = [NSPrintOperation printOperationWithView:[[mainTabView selectedTabViewItem] view] printInfo: printInfo];
             [printOp setShowsPrintPanel:YES];
             [printOp runOperation];
             */
            break;
        }

        default: {
            id <PecuniaSectionItem> item = mainTabItems[[[mainTabView selectedTabViewItem] identifier]];
            [item print];
        }
    }
}

- (IBAction)accountMaintenance: (id)sender
{
    BankAccount *account = nil;
    Category    *cat = [self currentSelection];
    if (cat == nil || cat.accountNumber == nil) {
        return;
    }
    account = (BankAccount *)cat;

    [account doMaintenance];
    [self save];
}

- (IBAction)getAccountBalance: (id)sender
{
    PecuniaError *pec_err = nil;
    BankAccount  *account = nil;
    Category     *cat = [self currentSelection];
    if (cat == nil || cat.accountNumber == nil) {
        return;
    }
    account = (BankAccount *)cat;

    pec_err = [[HBCIClient hbciClient] getBalanceForAccount: account];
    if (pec_err) {
        return;
    }

    [self save];
}

- (IBAction)resetIsNewStatements: (id)sender
{
    NSError                *error = nil;
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isNew = 1"];
    [request setPredicate: predicate];
    NSArray *statements = [context executeFetchRequest: request error: &error];
    for (BankStatement *stat in statements) {
        stat.isNew = @NO;
    }
    [self save];

    [self updateUnread];
    [accountsView setNeedsDisplay: YES];
    [categoryAssignments rearrangeObjects];
}

- (IBAction)showAboutPanel: (id)sender
{
    if (aboutWindow == nil) {
        [NSBundle loadNibNamed: @"About" owner: self];

        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *path = [mainBundle pathForResource: @"Credits" ofType: @"rtf"];
        [aboutText readRTFDFromFile: path];
        [versionText setStringValue: [NSString stringWithFormat: @"Version %@ (%@)",
                                      [mainBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                      [mainBundle objectForInfoDictionaryKey: @"CFBundleVersion"]
                                      ]];
        [copyrightText setStringValue: [mainBundle objectForInfoDictionaryKey: @"NSHumanReadableCopyright"]];
        gradient.fillColor = [NSColor whiteColor];
    }

    [aboutWindow orderFront: self];
}

- (BOOL)application: (NSApplication *)theApplication openFile: (NSString *)filename
{
    [[MOAssistant assistant] initDatafile: filename];
    return YES;
}

- (IBAction)toggleFullscreenIfSupported: (id)sender
{
    [mainWindow toggleFullScreen: mainWindow];
}

- (IBAction)toggleDetailsPane: (id)sender
{
    NSView *firstChild = (rightSplitter.subviews)[0];
    if (lastSplitterPosition == 0) {
        [statementDetails setHidden: YES];
        lastSplitterPosition = NSHeight(firstChild.frame);
        [toggleDetailsButton setImage: [NSImage imageNamed: @"show"]];
        [rightSplitter adjustSubviews];
        self.toggleDetailsPaneItem.state = NSOffState;
    } else {
        [statementDetails setHidden: NO];
        NSRect frame = firstChild.frame;
        frame.size.height = lastSplitterPosition;
        firstChild.frame = frame;
        [rightSplitter adjustSubviews];
        lastSplitterPosition = 0;
        [toggleDetailsButton setImage: [NSImage imageNamed: @"hide"]];
        self.toggleDetailsPaneItem.state = NSOnState;
    }
}

- (IBAction)toggleFeature: (id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if (sender == self.toggleDetailsPaneItem) {
        [self toggleDetailsPane: nil];
        [userDefaults setValue: @((int)lastSplitterPosition) forKey: @"rightSplitterPosition"];
    }
}

- (IBAction)attachmentClicked: (id)sender
{
    AttachmentImageView *image = sender;

    if (image.reference == nil) {
        // No attachment yet. Allow adding one if editing is possible.
        if (self.canEditAttachment) {
            NSOpenPanel *panel = [NSOpenPanel openPanel];
            panel.title = NSLocalizedString(@"AP118", nil);
            panel.canChooseDirectories = NO;
            panel.canChooseFiles = YES;
            panel.allowsMultipleSelection = NO;

            int runResult = [panel runModal];
            if (runResult == NSOKButton) {
                [image processAttachment: panel.URL];
            }
        }
    } else {
        [image openReference];
    }
}

- (BOOL)canEditAttachment
{
    return categoryAssignments.selectedObjects.count == 1;
}

- (void)reapplyDefaultIconsForCategory: (Category *)category
{
    for (Category *child in category.children) {
        if ([child.name hasPrefix: @"++"]) {
            continue;
        }
        [self determineDefaultIconForCategory: child];
        [self reapplyDefaultIconsForCategory: child];
    }
}

- (IBAction)resetCategoryIcons: (id)sender
{
    int res = NSRunAlertPanel(NSLocalizedString(@"AP301", nil),
                              NSLocalizedString(@"AP302", nil),
                              NSLocalizedString(@"AP4", nil),
                              NSLocalizedString(@"AP3", nil),
                              nil
                              );
    if (res != NSAlertAlternateReturn) {
        return;
    }
    [self reapplyDefaultIconsForCategory: Category.catRoot];
    [accountsView setNeedsDisplay: YES];
}

/**
 * Applies the positive and negative cash color values to various fields.
 */
- (void)updateValueColors
{
    NSDictionary *positiveAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]};
    NSDictionary *negativeAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]};

    [self setNumberFormatForCell: [valueField cell] positive: positiveAttributes negative: negativeAttributes];
    [valueField setNeedsDisplay];
    [self setNumberFormatForCell: [headerValueField cell] positive: positiveAttributes negative: negativeAttributes];
    [headerValueField setNeedsDisplay];
    [self setNumberFormatForCell: [nassValueField cell] positive: positiveAttributes negative: negativeAttributes];
    [nassValueField setNeedsDisplay];
    [self setNumberFormatForCell: [sumValueField cell] positive: positiveAttributes negative: negativeAttributes];
    [sumValueField setNeedsDisplay];
}

#pragma mark - KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"recursiveTransactions"]) {
            [[self currentSelection] updateBoundAssignments];
            return;
        }

        if ([keyPath isEqualToString: @"showHiddenCategories"]) {
            [categoryController prepareContent];
            return;
        }

        if ([keyPath isEqualToString: @"colors"]) {
            [self updateValueColors];
            return;
        }

        return;
    }

    if (object == categoryController) {
        [accountsView setNeedsDisplay: YES];
        return;
    }

    if (object == categoryAssignments) {
        if ([keyPath compare: @"selectionIndexes"] == NSOrderedSame) {
            // Selection did change.

            // If the currently selected entry is a new one remove the "new" mark.
            NSEnumerator      *enumerator = [[categoryAssignments selectedObjects] objectEnumerator];
            StatCatAssignment *stat = nil;
            NSDecimalNumber   *firstValue = nil;
            while ((stat = [enumerator nextObject]) != nil) {
                if (firstValue == nil) {
                    firstValue = stat.statement.value;
                }
                if ([stat.statement.isNew boolValue]) {
                    stat.statement.isNew = @NO;
                    BankAccount *account = stat.statement.account;
                    account.unread = account.unread - 1;
                    if (account.unread == 0) {
                        [self updateUnread];
                    }
                }
            }
            [accountsView setNeedsDisplay: YES];

            // Check for the type of transaction and adjust remote name display accordingly.
            if ([firstValue compare: [NSDecimalNumber zero]] == NSOrderedAscending) {
                [remoteNameLabel setStringValue: NSLocalizedString(@"AP208", nil)];
            } else {
                [remoteNameLabel setStringValue: NSLocalizedString(@"AP209", nil)];
            }

            // need to switch details view?
            NSArray *assignments = [categoryAssignments selectedObjects];
            if ([assignments count] > 0) {
                StatCatAssignment *stat = assignments[0];
                if ([stat.statement.type intValue] == StatementType_CreditCard && statementDetails == standardDetails) {
                    // switch to credit card details
                    NSRect frame = [statementDetails frame];
                    [creditCardDetails setFrame: frame];
                    [rightSplitter replaceSubview: statementDetails with: creditCardDetails];
                    statementDetails = creditCardDetails;
                }
                if ([stat.statement.type intValue] == StatementType_Standard && statementDetails == creditCardDetails) {
                    //switch to standard details
                    NSRect frame = [statementDetails frame];
                    [standardDetails setFrame: frame];
                    [rightSplitter replaceSubview: statementDetails with: standardDetails];
                    statementDetails = standardDetails;
                }
            }

            [statementDetails setNeedsDisplay: YES];
            [self updateStatusbar];
        }
    }
}

#pragma mark - Developer tools

- (IBAction)deleteAllData: (id)sender
{
    int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP114", nil),
                                      NSLocalizedString(@"AP115", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      nil
                                      );
    if (res != NSAlertAlternateReturn) {
        return;
    }

    [MOAssistant.assistant clearAllData];
    [Category recreateRoots];
}

- (IBAction)generateData: (id)sender
{
    GenerateDataController *generator = [[GenerateDataController alloc] init];
    [NSApp runModalForWindow: generator.window];
}

#pragma mark - Other stuff

- (IBAction)creditCardSettlements: (id)sender
{
    BankAccount *account = [self selectedBankAccount];
    if (account == nil) {
        return;
    }

    CreditCardSettlementController *controller = [[CreditCardSettlementController alloc] init];
    controller.account = account;

    [NSApp runModalForWindow: [controller window]];
}

- (void)migrate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           migrated10 = [defaults boolForKey: @"Migrated10"];
    if (migrated10 == NO) {
        NSError                *error = nil;
        NSManagedObjectContext *context = [[MOAssistant assistant] context];
        NSArray                *bankUsers = [BankUser allUsers];
        NSArray                *users = [[HBCIClient hbciClient] getOldBankUsers];

        for (User *user in users) {
            BOOL found = NO;
            for (BankUser *bankUser in bankUsers) {
                if ([user.userId isEqualToString: bankUser.userId] &&
                    [user.bankCode isEqualToString: bankUser.bankCode] &&
                    (user.customerId == nil || [user.customerId isEqualToString: bankUser.customerId])) {
                    found = YES;
                }
            }
            if (found == NO) {
                // create BankUser
                BankUser *bankUser = [NSEntityDescription insertNewObjectForEntityForName: @"BankUser" inManagedObjectContext: context];
                bankUser.name = user.name;
                bankUser.bankCode = user.bankCode;
                bankUser.bankName = user.bankName;
                bankUser.bankURL = user.bankURL;
                bankUser.port = user.port;
                bankUser.hbciVersion = user.hbciVersion;
                bankUser.checkCert = @(user.checkCert);
                bankUser.country = user.country;
                bankUser.userId = user.userId;
                bankUser.customerId = user.customerId;
                bankUser.secMethod = @(SecMethod_PinTan);
            }
        }
        // BankUser assign accounts
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: context];
        NSFetchRequest      *request = [[NSFetchRequest alloc] init];
        [request setEntity: entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"userId != nil", self];
        [request setPredicate: predicate];
        NSArray *accounts = [context executeFetchRequest: request error: &error];

        // assign users to accounts and issue a message if an assigned user is not found
        NSMutableSet *invalidUsers = [NSMutableSet setWithCapacity: 10];
        for (BankAccount *account in accounts) {
            if ([invalidUsers containsObject: account.userId]) {
                continue;
            }
            BankUser *user = [BankUser userWithId: account.userId bankCode: account.bankCode];
            if (user) {
                NSMutableSet *users = [account mutableSetValueForKey: @"users"];
                [users addObject: user];
            } else {
                [invalidUsers addObject: account.userId];
            }
        }
        
        if (![self save]) {
            return;
        }

        // BankUser update BPD
        bankUsers = [BankUser allUsers];
        if ([bankUsers count] > 0) {
            NSRunAlertPanel(NSLocalizedString(@"AP150", nil),
                            NSLocalizedString(@"AP203", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil, nil
                            );
            for (BankUser *user in [BankUser allUsers]) {
                [[HBCIClient hbciClient] updateBankDataForUser: user];
            }
        }

        [defaults setBool: YES forKey: @"Migrated10"];

        // success message
        if ([users count] > 0 && [bankUsers count] > 0) {
            NSRunAlertPanel(NSLocalizedString(@"AP150", nil),
                            NSLocalizedString(@"AP156", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil, nil
                            );
        }
    }
}

- (void)updateSorting
{
    [sortControl setImage: nil forSegment: sortIndex];
    sortIndex = [sortControl selectedSegment];
    NSImage *sortImage = sortAscending ? [NSImage imageNamed: @"sort-indicator-inc"] : [NSImage imageNamed: @"sort-indicator-dec"];
    [sortControl setImage: sortImage forSegment: sortIndex];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue: @((int)sortIndex) forKey: @"mainSortIndex"];
    [userDefaults setValue: @(sortAscending) forKey: @"mainSortAscending"];

    NSString *key;
    switch (sortIndex) {
        case 1:
            statementsListView.canShowHeaders = NO;
            key = @"statement.remoteName";
            break;

        case 2:
            statementsListView.canShowHeaders = NO;
            key = @"statement.purpose";
            break;

        case 3:
            statementsListView.canShowHeaders = NO;
            key = @"statement.categoriesDescription";
            break;

        case 4:
            statementsListView.canShowHeaders = NO;
            key = @"value";
            break;

        default: {
            statementsListView.canShowHeaders = YES;
            key = @"statement.date";
            break;
        }
    }
    [categoryAssignments setSortDescriptors: @[[[NSSortDescriptor alloc] initWithKey: key ascending: sortAscending]]];
}

- (BOOL)save
{
    NSError *error = nil;
    
    // save updates
    if (![self.managedObjectContext save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return NO;
    }
    return YES;
}

+ (BankingController *)controller
{
    return bankinControllerInstance;
}

//--------------------------------------------------------------------------------------------------

@end
