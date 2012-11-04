/**
 * Copyright (c) 2010, 2012, Pecunia Project. All rights reserved.
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

#import "BankingController+Tabs.h"

#import "TransfersController.h"
#import "StandingOrderController.h"

#define TransfersTabIdentifier @"transfers"
#define StandingOrderTabIdentifier @"standingOrders"

@implementation BankingController (Tabs)

- (void)activateStandingOrdersTab
{
	NSInteger index = [mainTabView indexOfTabViewItemWithIdentifier: StandingOrderTabIdentifier];
	if (index == NSNotFound) {
		standingOrderController = [[StandingOrderController alloc] init];
		if ([NSBundle loadNibNamed: @"Orders" owner: standingOrderController]) {
			NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier: StandingOrderTabIdentifier];
			[item setView: [standingOrderController mainView]];
			[mainTabView addTabViewItem: item];
			[mainTabView selectTabViewItem: item];
			[mainTabItems setObject: standingOrderController forKey: StandingOrderTabIdentifier];
			[standingOrderController prepare];
		}
	} else {
		[mainTabView selectTabViewItemAtIndex: index];
        [standingOrderController activate];
	}
}

- (void)activateTransfersTab
{
	NSInteger index = [mainTabView indexOfTabViewItemWithIdentifier: TransfersTabIdentifier];
	if (index == NSNotFound) {
		transfersController = [[TransfersController alloc] init];
		if ([NSBundle loadNibNamed: @"Transfers" owner: transfersController]) {
			NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier: TransfersTabIdentifier];
			[item setView: [transfersController mainView]];
			[mainTabView addTabViewItem: item];
			[mainTabView selectTabViewItem: item];
			[mainTabItems setObject: transfersController forKey: TransfersTabIdentifier];
			[transfersController prepare];
		}
	} else {
		[mainTabView selectTabViewItemAtIndex: index];
        [transfersController activate];
	}
}


@end
