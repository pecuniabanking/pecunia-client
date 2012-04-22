//
//  ReportingTabs.m
//  Pecunia
//
//  Created by Frank Emminghaus on 11.11.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "ReportingTabs.h"
#import "CategoryPeriodsWindowController.h"
#import "StandingOrderTabController.h"


#define _catPeriodsIdentifier @"categoryPeriods"
#define _standingOrderTabIdentifier @"standingOrders"

@implementation BankingController (ReportingTabs)

-(IBAction)standingOrders: (id)sender 
{
	NSInteger idx = [ mainTabView indexOfTabViewItemWithIdentifier:_standingOrderTabIdentifier ];
	if (idx == NSNotFound) {
		StandingOrderTabController *controller = [[[StandingOrderTabController alloc] init] autorelease];
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
}


@end
