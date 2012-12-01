//
//  BWSplitView.h
//  BWToolkit
//
//  Created by Brandon Walkin (www.brandonwalkin.com) and Fraser Kuyvenhoven.
//  All code is provided under the New BSD license.
//

#import <Cocoa/Cocoa.h>

@interface BWSplitView : NSSplitView <NSSplitViewDelegate>
{
	NSColor *color;
	BOOL colorIsEnabled, checkboxIsEnabled, dividerCanCollapse, collapsibleSubviewCollapsed;
	NSMutableDictionary *minValues, *maxValues, *minUnits, *maxUnits;
	NSMutableDictionary *resizableSubviewPreferredProportion, *nonresizableSubviewPreferredSize;
	NSArray *stateForLastPreferredCalculations;
	int collapsiblePopupSelection;
	float uncollapsedSize;
	
	// Collapse button
	NSButton *toggleCollapseButton;
	BOOL isAnimating;
}

@property (nonatomic, strong) NSMutableDictionary *minValues, *maxValues, *minUnits, *maxUnits;
@property (nonatomic, strong) NSMutableDictionary *resizableSubviewPreferredProportion, *nonresizableSubviewPreferredSize;
@property (nonatomic, strong) NSArray *stateForLastPreferredCalculations;
@property (nonatomic, strong) NSButton *toggleCollapseButton;
@property (unsafe_unretained) id secondaryDelegate;
@property (nonatomic) BOOL collapsibleSubviewCollapsed;
@property int collapsiblePopupSelection;
@property BOOL dividerCanCollapse;

// The split view divider color
@property (copy) NSColor *color;

// Flag for whether a custom divider color is enabled. If not, the standard divider color is used.
@property (nonatomic) BOOL colorIsEnabled;

// Call this method to collapse or expand a subview configured as collapsible in the IB inspector.
- (IBAction)toggleCollapse:(id)sender;

@end
