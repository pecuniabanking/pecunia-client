/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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

#import "CategoryMaintenanceController.h"
#import "Category.h"
#import "MOAssistant.h"
#include "AnimationHelper.h"

#import "BWGradientBox.h"
#import "MAAttachedWindow.h"

extern NSString* const CategoryColorNotification;
extern NSString* const CategoryKey;

// A simple descendant to accept double clicks.
@interface DoubleClickImageView : NSImageView
{
}
@property (assign) id controller;
@end

@implementation DoubleClickImageView

@synthesize controller;

- (void)mouseDown:(NSEvent *)theEvent
{
    if (theEvent.clickCount > 1) {
        [controller imageDoubleClicked: self];
    }
}

- (void)resetCursorRects
{
    [super resetCursorRects];
    [self addCursorRect: [self bounds] cursor: [NSCursor pointingHandCursor]];
}

- (void)concludeDragOperation: (id <NSDraggingInfo>)sender
{
    // Read image path for later processing.
    NSString *path = [[sender draggingPasteboard] propertyListForType: @"NSFilenamesPboardType"][0];
    [super concludeDragOperation: sender];
    self.image.name = path;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface LibraryIconView : NSBox
{
}
@end

@implementation LibraryIconView

- (id)initWithFrame: (NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self != nil) {

    }
    return self;
}

- (NSView *)hitTest: (NSPoint)aPoint
{
  // Don't allow any mouse clicks for subviews in this NSBox (necessary for making this box selectable).
	if (NSPointInRect(aPoint, [self convertRect: [self bounds] toView: [self superview]])) {
        return self;
    } else {
        return nil;
    }
}

- (void)mouseDown: (NSEvent *)theEvent
{
    [super mouseDown: theEvent];

    if ([theEvent clickCount] > 1) {
        [NSApp sendAction: @selector(acceptImage:) to: nil from: self];
    }
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface ImageLibraryPopup : NSView
@end

@implementation ImageLibraryPopup

- (void)cancelOperation:(id)sender
{
    [NSApp sendAction: @selector(cancelImage:) to: nil from: self];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation CategoryMaintenanceController

@synthesize iconCollection;

- (id)initWithCategory: (Category*)aCategory
{
	self = [super initWithWindowNibName: @"CategoryMaintenance"];
    if (self != nil) {
        moc = MOAssistant.assistant.memContext;

        category = [NSEntityDescription insertNewObjectForEntityForName: @"Category" inManagedObjectContext: moc];

        changedCategory = aCategory;
        category.name = aCategory.name;
        category.currency = aCategory.currency;
        category.categoryColor = aCategory.categoryColor;
        category.iconName = aCategory.iconName;
    }
	return self;
}

- (void)awakeFromNib
{
    // Manually set up properties which cannot be set via user defined runtime attributes
    // (Color type is not available pre 10.7).
    topGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    topGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];
    backgroundGradient.fillColor = [NSColor whiteColor];

    iconCollection = [NSMutableArray arrayWithCapacity: 100];
    [self.categoryIcon addObserver: self forKeyPath: @"image" options: 0 context: nil];
    self.categoryIcon.controller = self;

    NSString *path;
    if ([category.iconName isAbsolutePath]) {
        path = category.iconName;
    } else {
        NSString* subfolder = [category.iconName stringByDeletingLastPathComponent];
        path = [[NSBundle mainBundle] pathForResource: [category.iconName lastPathComponent]
                                               ofType: @"icns"
                                          inDirectory: subfolder];
    }
    self.categoryIcon.image = [[NSImage alloc] initWithContentsOfFile: path];
    self.categoryIcon.image.name = [category.iconName lastPathComponent];

    // Set up the icon collection with all icons in our (first) internal collection.
    NSArray *paths = [NSBundle.mainBundle pathsForResourcesOfType: @"icns" inDirectory: @"Collections/1"];

    for (NSString *path in paths) {
        NSString* fileName = [[path lastPathComponent] stringByDeletingPathExtension];
        NSImage *image = [[NSImage alloc] initWithContentsOfFile: path];
        image.name = fileName;
        [self.iconCollectionController addObject: @{@"icon": image}];
    }
}

#pragma mark -
#pragma mark KVO handling

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    self.smallCategoryIcon.image = self.categoryIcon.image;
}

- (void)openImageLibrary
{
    if (imageLibraryPopupWindow == nil) {
        NSRect bounds = self.categoryIcon.bounds;
        NSPoint targetPoint = NSMakePoint(NSMidX(bounds),
                                          NSMidY(bounds));
        targetPoint = [self.categoryIcon convertPoint: targetPoint toView: nil];
        imageLibraryPopupWindow = [[MAAttachedWindow alloc] initWithView: self.imageLibraryPopup
                                                         attachedToPoint: targetPoint
                                                                inWindow: self.window
                                                                  onSide: MAPositionAutomatic
                                                              atDistance: 20];

        [imageLibraryPopupWindow setBackgroundColor: [NSColor colorWithCalibratedWhite: 1 alpha: 0.8]];
        [imageLibraryPopupWindow setViewMargin: 1];
        [imageLibraryPopupWindow setBorderWidth: 1];
        [imageLibraryPopupWindow setCornerRadius: 10];
        [imageLibraryPopupWindow setHasArrow: YES];
        [imageLibraryPopupWindow setDrawsRoundCornerBesideArrow: YES];

        [imageLibraryPopupWindow setAlphaValue: 0];
        [self.window addChildWindow: imageLibraryPopupWindow ordered: NSWindowAbove];
        [imageLibraryPopupWindow fadeIn];
        [imageLibraryPopupWindow makeKeyWindow];
    }
}

#pragma mark -
#pragma mark Event handling

- (void)imageDoubleClicked: (id)sender
{
    [self openImageLibrary];
}

- (IBAction)acceptImage: (id)sender
{
    [imageLibraryPopupWindow fadeOut];
    [self.window removeChildWindow: imageLibraryPopupWindow];
    imageLibraryPopupWindow = nil;

    NSArray *selection = self.iconCollectionController.selectedObjects;
    if ([selection count] > 0) {
        self.categoryIcon.image = selection[0][@"icon"];
    }
}

- (IBAction)cancelImage: (id)sender
{
    [imageLibraryPopupWindow fadeOut];
    [self.window removeChildWindow: imageLibraryPopupWindow];
    imageLibraryPopupWindow = nil;
}

- (IBAction)cancel: (id)sender
{
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }
    [self.categoryIcon removeObserver: self forKeyPath: @"image"];

    [self close];
	[moc reset];
	[NSApp stopModalWithCode: 0];
}

- (IBAction)ok: (id)sender
{
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }
    [self.categoryIcon removeObserver: self forKeyPath: @"image"];

	[categoryController commitEditing];
	NSManagedObjectContext *context = MOAssistant.assistant.context;
	
	// Take changes over.
	changedCategory.localName = category.localName;
    changedCategory.categoryColor = category.categoryColor;

    NSImage *image = self.categoryIcon.image;
    if (image != nil && image.name != nil) {
        if ([image.name isAbsolutePath]) {
            changedCategory.iconName = image.name;
        } else {
            // A library icon was selected. Construct the relative path.
            changedCategory.iconName = [@"Collections/1/" stringByAppendingString: image.name];
        }
    }

    NSDictionary *info = @{CategoryKey: changedCategory};
    [NSNotificationCenter.defaultCenter postNotificationName: CategoryColorNotification
                                                      object: self
                                                    userInfo: info];
    [self close];

	// save all
	NSError *error = nil;
	if (![context save: &error]) {
		NSAlert *alert = [NSAlert alertWithError: error];
		[alert runModal];
	}

	[moc reset];
	[NSApp stopModalWithCode: 1];
}

@end
