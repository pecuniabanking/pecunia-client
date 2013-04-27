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

@interface ColorPopup ()

@property (nonatomic) NSColorPanel *colorPanel;
@property (nonatomic, assign) NSColorWell *colorWell;

@end

@implementation ColorPopup
{
@private
    BOOL isVisible;

    NSViewController *colorPopoverController;
    NSPopover *colorPopover;
    NSView *colorPopoverHostingView;

    NSView *contentView;
    BFIconTabBar *tabBar;
}

@synthesize color;

#pragma mark -
#pragma mark Initialization & Destruction

#define TABBAR_HEIGHT 40

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

        colorPopoverController = [[NSViewController alloc] init];

        NSRect hostingFrame = [self.colorPanel.contentView bounds];
        hostingFrame.size.height += TABBAR_HEIGHT; // Fixed value. We cannot ask the toolbar for it.
        colorPopoverHostingView = [[NSView alloc] initWithFrame: hostingFrame];
        colorPopoverController.view = colorPopoverHostingView;

        // Create a copy of the color panel's toolbar items, since we cannot relocate them to our hosting view.
        NSToolbar *toolbar = self.colorPanel.toolbar;
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

        tabBar = [[BFIconTabBar alloc] init];
        tabBar.delegate = self;
        tabBar.items = tabbarItems;
        tabBar.frame = CGRectMake(0.0f, colorPopoverHostingView.bounds.size.height - TABBAR_HEIGHT,
                                  colorPopoverHostingView.bounds.size.width, TABBAR_HEIGHT);
        tabBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        [tabBar selectIndex: selectedIndex];
        [colorPopoverHostingView addSubview: tabBar];
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

- (void)createPopover
{
    colorPopover = [[NSPopover alloc] init];
    colorPopover.contentViewController = colorPopoverController;
    colorPopover.behavior = NSPopoverBehaviorTransient;
    colorPopover.delegate = self;
}

- (void)popupRelativeToRect: (NSRect)rect ofView: (NSView*)view
{
    if (colorPopover.shown) {
        return;
    }
    
    isVisible = YES;

    // Remove the shared color panel if it is visible currently as we are rehosting parts of it to our popup.
    if (NSColorPanel.sharedColorPanelExists && NSColorPanel.sharedColorPanel.isVisible) {
		[NSColorPanel.sharedColorPanel orderOut: self];
	}

    // Relocate the content view from the shared color panel to a hosting view.
    contentView = self.colorPanel.contentView;
	[colorPopoverHostingView addSubview: contentView];

    if (color != nil) {
        self.colorPanel.color = color;
    }
    self.colorPanel.showsAlpha = YES;

    NSString *selectedIdentifier = self.colorPanel.toolbar.selectedItemIdentifier;
    NSUInteger selectedIndex = 0;
    for (NSToolbarItem *item in self.colorPanel.toolbar.items) {
        if ([item.itemIdentifier isEqualToString: selectedIdentifier]) {
            break;
        }
        selectedIndex++;
    }
    [tabBar selectIndex: selectedIndex];
    
	// Find and remove the color swatch resize dimple, because it crashes if used outside of a panel.
	NSArray *panelSubviews = [NSArray arrayWithArray: contentView.subviews];
    Class dimpleClass = NSClassFromString(@"NSColorPanelResizeDimple");
	for (NSView *subview in panelSubviews) {
		if ([subview isKindOfClass: dimpleClass]) {
			[subview removeFromSuperview];
		}
	}

    [self createPopover];
    [self.colorPanel addObserver: self forKeyPath: @"color" options: NSKeyValueObservingOptionNew context: NULL];
    [colorPopover showRelativeToRect: rect ofView: view preferredEdge: NSMaxYEdge];
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
	if (removeTarget) {
		[self removeTargetAndAction];
	}
	if (removeObserver) {
		[self.colorPanel removeObserver: self forKeyPath: @"color"];
	}

	if (deactivate) {
		[self deactivateColorWell];
	}
    self.colorPanel.contentView = contentView;
    colorPopover = nil;
    isVisible = NO;
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

#pragma mark -
#pragma mark Popover Delegate Methods

- (void)popoverDidClose: (NSNotification *)notification
{
    [self close];
}

@end
