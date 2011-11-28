//
//  ReportingTabs.m
//  Pecunia
//
//  Created by Frank Emminghaus on 11.11.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "ReportingTabs.h"
#import "CategoryPeriodsWindowController.h"
#import "CategoryRepWindowController.h"
#import "AccountRepWindowController.h"
#import "StandingOrderTabController.h"


#define _catPeriodsIdentifier @"categoryPeriods"
#define _catRepIdentifier @"categoryRep"
#define _accountRepIdentifier @"accountRep"
#define _standingOrderTabIdentifier @"standingOrders"

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
			[mainTabItems setObject:controller forKey: _catPeriodsIdentifier ];
		}
	} else {
		[mainTabView selectTabViewItemAtIndex:idx ];
		// reload content, may have changed
		id<MainTabViewItem> controller = (id<MainTabViewItem>)[mainTabItems objectForKey:_catPeriodsIdentifier ];
		[controller prepare ];
	}
	[self adjustSearchField ];
}

-(IBAction)categoryRep: (id)sender
{
	int idx = [ mainTabView indexOfTabViewItemWithIdentifier:_catRepIdentifier ];
	if (idx == NSNotFound) {
		CategoryRepWindowController *controller = [[CategoryRepWindowController alloc ] init ];
		if([NSBundle loadNibNamed:@"CategoryRep" owner:controller ]) {
			NSTabViewItem *item = [[NSTabViewItem alloc ] initWithIdentifier:_catRepIdentifier ];
			[item setView:[controller mainView ] ];
			[mainTabView addTabViewItem:item ];
			[mainTabView selectTabViewItem:item ];
			[mainTabItems setObject:controller forKey: _catRepIdentifier ];
			[controller prepare ];
		}
	} else {
		[mainTabView selectTabViewItemAtIndex:idx ];
	}
	[self adjustSearchField ];
}

-(IBAction)accountsRep: (id)sender 
{
	int idx = [ mainTabView indexOfTabViewItemWithIdentifier:_accountRepIdentifier ];
	if (idx == NSNotFound) {
		AccountRepWindowController *controller = [[AccountRepWindowController alloc ] init ];
		if([NSBundle loadNibNamed:@"AccountRep" owner:controller ]) {
			NSTabViewItem *item = [[NSTabViewItem alloc ] initWithIdentifier:_accountRepIdentifier ];
			[item setView:[controller mainView ] ];
			[mainTabView addTabViewItem:item ];
			[mainTabView selectTabViewItem:item ];
			[mainTabItems setObject:controller forKey: _accountRepIdentifier ];
			[controller prepare ];
		}
	} else {
		[mainTabView selectTabViewItemAtIndex:idx ];
	}
	[self adjustSearchField ];
}

-(IBAction)standingOrders: (id)sender 
{
	int idx = [ mainTabView indexOfTabViewItemWithIdentifier:_standingOrderTabIdentifier ];
	if (idx == NSNotFound) {
		StandingOrderTabController *controller = [[StandingOrderTabController alloc ] init ];
		if([NSBundle loadNibNamed:@"Orders" owner:controller ]) {
			NSTabViewItem *item = [[NSTabViewItem alloc ] initWithIdentifier:_standingOrderTabIdentifier ];
			[item setView:[controller mainView ] ];
			[mainTabView addTabViewItem:item ];
			[mainTabView selectTabViewItem:item ];
			[mainTabItems setObject:controller forKey: _standingOrderTabIdentifier ];
			[controller prepare ];
		}
	} else {
		[mainTabView selectTabViewItemAtIndex:idx ];
	}
	[self adjustSearchField ];
}


@end
