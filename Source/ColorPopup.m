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

/**
 * This color popup uses ideas from BFColorPicker written by Balázs Faludi. His color picker requires
 * 10.7 to run (e.g. it uses NSPopover), so I had to reimplement it with MAAttachedWindow.
 * Turned out to be a lot simpler, without using private APIs.
 */

#import "ColorPopup.h"

#import "MAAttachedWindow.h"
#import "AnimationHelper.h"

@interface ColorPopupWindow : MAAttachedWindow
@property (assign) id owner;
@end

@implementation ColorPopupWindow

- (void)cancelOperation: (id)sender
{
    //[self resignKeyWindow]; // The popup listens to this action and closes the window.
    [self.owner close];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface ColorPopup ()

@property (nonatomic) NSColorPanel *colorPanel;
@property (nonatomic, assign) NSColorWell *colorWell;

@end

@implementation ColorPopup
{
@private
    BOOL isVisible;
    ColorPopupWindow *popupWindow;
    NSView *contentView;
    BFIconTabBar *tabBar;
}

@synthesize color;

#pragma mark -
#pragma mark Initialization & Destruction

+ (ColorPopup *)sharedColorPopup
{
    static ColorPopup *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[ColorPopup alloc] init];
    });
    return singleton;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.colorPanel = NSColorPanel.sharedColorPanel;
	}
    return self;
}

#pragma mark -
#pragma mark Getters & Setters

- (NSColor *)color
{
	return self.colorPanel.color;
}

- (void)setColor: (NSColor *)value
{
	color = value;
	if (isVisible) {
		self.colorPanel.color = color;
	}
}

#define TABBAR_HEIGHT 40

- (void)popupAtPosition: (NSPoint)position withOwner: (NSWindow*)owner
{
	// Close the popup if it is currently visible.
	if (isVisible) {
		[self close];
        return;
	}

    isVisible = YES;

    // Remove the shared color panel if it is visible currently as we are rehosting parts of it to our popup.
    if (NSColorPanel.sharedColorPanelExists && NSColorPanel.sharedColorPanel.isVisible) {
		[NSColorPanel.sharedColorPanel orderOut: self];
	}

    // Relocate the content view from the shared color panel to a hosting view we can use
    // in the attached window.
    NSToolbar *toolbar = self.colorPanel.toolbar;
    NSRect hostingFrame = [self.colorPanel.contentView bounds];
    hostingFrame.size.height += TABBAR_HEIGHT; // Fixed value. We cannot ask the toolbar for it.
    NSView *hostingView = [[NSView alloc] initWithFrame: hostingFrame];

	NSMutableArray *tabbarItems = [[NSMutableArray alloc] initWithCapacity: toolbar.items.count];
	NSUInteger selectedIndex = 0;
	for (NSUInteger i = 0; i < toolbar.items.count; i++) {
		NSToolbarItem *toolbarItem = toolbar.items[i];
		NSImage *image = toolbarItem.image;

		BFIconTabBarItem *tabbarItem = [[BFIconTabBarItem alloc] initWithIcon: image tooltip: toolbarItem.toolTip];
		[tabbarItems addObject: tabbarItem];

		if ([toolbarItem.itemIdentifier isEqualToString: toolbar.selectedItemIdentifier]) {
			selectedIndex = i;
		}
	}

	// Create a toolbar replica (we cannot use NSToolbar in a window without title).
	tabBar = [[BFIconTabBar alloc] init];
	tabBar.delegate = self;
	tabBar.items = tabbarItems;
	tabBar.frame = CGRectMake(0.0f, hostingView.bounds.size.height - TABBAR_HEIGHT, hostingView.bounds.size.width, TABBAR_HEIGHT);
	tabBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	[tabBar selectIndex: selectedIndex];
	[hostingView addSubview: tabBar];

	// Add the color picker view.
    contentView = self.colorPanel.contentView;
	[hostingView addSubview: contentView];

    if (color != nil) {
        self.colorPanel.color = color;
    }
    self.colorPanel.showsAlpha = YES;

	// Find and remove the color swatch resize dimple, because it crashes if used outside of a panel.
	NSArray *panelSubviews = [NSArray arrayWithArray: contentView.subviews];
	for (NSView *subview in panelSubviews) {
		if ([subview isKindOfClass: NSClassFromString(@"NSColorPanelResizeDimple")]) {
			[subview removeFromSuperview];
		}
	}

    popupWindow = [[ColorPopupWindow alloc] initWithView: hostingView
                                         attachedToPoint: position
                                                inWindow: owner
                                                  onSide: MAPositionAutomatic
                                              atDistance: 10];
    popupWindow.owner = self;
    popupWindow.isVisible = NO;
    popupWindow.canBecomeKey = YES;
    popupWindow.backgroundColor = [NSColor whiteColor];
    popupWindow.viewMargin = 0;
    popupWindow.borderWidth = 0;
    popupWindow.cornerRadius = 3;
    popupWindow.hasArrow = YES;
    popupWindow.arrowHeight = 10;
    popupWindow.drawsRoundCornerBesideArrow = YES;

    [owner addChildWindow: popupWindow ordered: NSWindowAbove];

    NSRect frame = popupWindow.frame;
    frame.size.width += 40;
    frame.size.height += 100;
    frame.origin.x -= 20;
    [popupWindow zoomInWithOvershot: frame withFade: YES makeKey: YES];

    [self.colorPanel addObserver: self forKeyPath: @"color" options: NSKeyValueObservingOptionNew context: NULL];
    [NSNotificationCenter.defaultCenter addObserver: self
                                           selector: @selector(windowDidResignKey:)
                                               name: NSWindowDidResignKeyNotification
                                             object: popupWindow];
}

// Forward the selection action message to the color panel.
- (void)tabBarChangedSelection: (BFIconTabBar *)tabbar
{
    if (tabbar.selectedIndex != -1) {
        NSToolbarItem *selectedItem = self.colorPanel.toolbar.items[(NSUInteger)tabbar.selectedIndex];
        SEL action = selectedItem.action;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

        [self.colorPanel performSelector: action withObject: selectedItem];

#pragma clang diagnostic pop
    }
}

- (void)windowDidResignKey: (NSNotification *)aNotification
{
    [self close];
}

- (void)removeTargetAndAction
{
	self.target = nil;
	self.action = nil;
}

- (void)deactivateColorWell
{
	[self.colorWell deactivate];
	self.colorWell = nil;
}

- (void)closeAndDeactivateColorWell: (BOOL)deactivate
                       removeTarget: (BOOL)removeTarget
                     removeObserver: (BOOL)removeObserver
{
    [NSNotificationCenter.defaultCenter removeObserver: self];
	if (removeTarget) {
		[self removeTargetAndAction];
	}
	if (removeObserver) {
		[self.colorPanel removeObserver: self forKeyPath: @"color"];
	}

	[popupWindow fadeOut];
    [self performSelector: @selector(performCloseCleanUp)
               withObject: nil
               afterDelay: [[NSAnimationContext currentContext] duration]];

	if (deactivate) {
		[self deactivateColorWell];
	}
    isVisible = NO;
}

- (void)performCloseCleanUp
{
    self.colorPanel.contentView = contentView;
    [popupWindow.parentWindow removeChildWindow: popupWindow];
    popupWindow = nil;
}

- (void)close
{
	[self closeAndDeactivateColorWell: YES removeTarget: YES removeObserver: YES];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
	if (object == self.colorPanel && [keyPath isEqualToString: @"color"]) {
		color = self.colorPanel.color;
		if (self.target && self.action && [self.target respondsToSelector: self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

			[self.target performSelector: self.action withObject: self];

#pragma clang diagnostic pop
		}
	}
}

@end
