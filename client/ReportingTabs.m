//
//  ReportingTabs.m
//  Pecunia
//
//  Created by Frank Emminghaus on 11.11.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ReportingTabs.h"
#import "CategoryPeriodsWindowController.h"
#import "CategoryHistWindowController.h"

#define _catPeriodsIdentifier @"categoryPeriods"
#define _catHistoryIdentifier @"categoryHistory"

@implementation BankingController (ReportingTabs)

-(IBAction)catPeriodView: (id)sender
{
	int idx = [ mainTabView indexOfTabViewItemWithIdentifier:_catPeriodsIdentifier ];
	if (idx == NSNotFound) {
		CategoryPeriodsWindowController *controller = [[CategoryPeriodsWindowController alloc ] init ];
		if([NSBundle loadNibNamed:@"CategoryPeriods" owner:controller ]) {
			//		[controller prepare ];
			NSTabViewItem *item = [[NSTabViewItem alloc ] initWithIdentifier:_catPeriodsIdentifier ];
			[item setView:[controller mainView ] ];
			[mainTabView addTabViewItem:item ];
			[mainTabView selectTabViewItem:item ];
			[mainTabItems addObject:controller ];
		}
	} else {
		[mainTabView selectTabViewItemAtIndex:idx ];
	}
	[self adjustSearchField ];
}

-(IBAction)catHistoryView: (id)sender;
{
	int idx = [ mainTabView indexOfTabViewItemWithIdentifier:_catHistoryIdentifier ];
	if (idx == NSNotFound) {
		CategoryHistWindowController *controller = [[CategoryHistWindowController alloc ] init ];
		if([NSBundle loadNibNamed:@"CategoryHistory" owner:controller ]) {
			//		[controller prepare ];
			NSTabViewItem *item = [[NSTabViewItem alloc ] initWithIdentifier:_catHistoryIdentifier ];
			[item setView:[controller mainView ] ];
			[mainTabView addTabViewItem:item ];
			[mainTabView selectTabViewItem:item ];
			[mainTabItems addObject:controller ];
		}
	} else {
		[mainTabView selectTabViewItemAtIndex:idx ];
	}
	[self adjustSearchField ];
}



@end
