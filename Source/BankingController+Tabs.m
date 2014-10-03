/**
 * Copyright (c) 2010, 2014, Pecunia Project. All rights reserved.
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

#import "HomeScreenController.h"
#import "TransfersController.h"
#import "StandingOrderController.h"
#import "DebitsController.h"
#import "CategoryHeatMapController.h"

#import "MessageLog.h"

#define HomeScreenTabIdentifier    @"homeScreen"
#define TransfersTabIdentifier     @"transfers"
#define StandingOrderTabIdentifier @"standingOrders"
#define DebitsTabIdentifier        @"debits"
#define HeatMapTabIdentifier       @"heatMap"

@implementation BankingController (Tabs)

- (void)activateHomeScreenTab
{
    LogEnter;

    NSInteger index = [mainTabView indexOfTabViewItemWithIdentifier: HomeScreenTabIdentifier];
    if (index == NSNotFound) {
        homeScreenController = [[HomeScreenController alloc] init];
        LogDebug(@"Loading HomeScreen.xib");
        if ([NSBundle.mainBundle loadNibNamed: @"HomeScreen" owner: homeScreenController topLevelObjects: nil]) {
            LogDebug(@"Loading successful");
            NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier: HomeScreenTabIdentifier];
            [item setView: homeScreenController.view];
            [mainTabView addTabViewItem: item];
            [mainTabView selectTabViewItem: item];
            mainTabItems[HomeScreenTabIdentifier] = homeScreenController;
        }
    } else {
        [mainTabView selectTabViewItemAtIndex: index];
        [homeScreenController activate];
    }
}

- (void)activateStandingOrdersTab
{
    LogEnter;

    NSInteger index = [mainTabView indexOfTabViewItemWithIdentifier: StandingOrderTabIdentifier];
    if (index == NSNotFound) {
        standingOrderController = [[StandingOrderController alloc] init];
        LogDebug(@"Loading Orders.xib");
        if ([NSBundle.mainBundle loadNibNamed: @"Orders" owner: standingOrderController topLevelObjects: nil]) {
            LogDebug(@"Loading successful");
            NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier: StandingOrderTabIdentifier];
            [item setView: [standingOrderController mainView]];
            [mainTabView addTabViewItem: item];
            [mainTabView selectTabViewItem: item];
            mainTabItems[StandingOrderTabIdentifier] = standingOrderController;
            [standingOrderController prepare];
        }
    } else {
        [mainTabView selectTabViewItemAtIndex: index];
        [standingOrderController activate];
    }
}

- (void)activateTransfersTab
{
    LogEnter;

    NSInteger index = [mainTabView indexOfTabViewItemWithIdentifier: TransfersTabIdentifier];
    if (index == NSNotFound) {
        transfersController = [[TransfersController alloc] init];
        LogDebug(@"Loading Transfers.xib");
        if ([NSBundle.mainBundle loadNibNamed: @"Transfers" owner: transfersController topLevelObjects: nil]) {
            LogDebug(@"Loading successful");
            NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier: TransfersTabIdentifier];
            [item setView: [transfersController mainView]];
            [mainTabView addTabViewItem: item];
            [mainTabView selectTabViewItem: item];
            mainTabItems[TransfersTabIdentifier] = transfersController;
            [transfersController prepare];
        }
    } else {
        [mainTabView selectTabViewItemAtIndex: index];
        [transfersController activate];
    }
}

- (void)activateDebitsTab
{
    LogEnter;

    NSInteger index = [mainTabView indexOfTabViewItemWithIdentifier: DebitsTabIdentifier];
    if (index == NSNotFound) {
        debitsController = [[DebitsController alloc] init];
        LogDebug(@"Loading Debits.xib");
        if ([NSBundle.mainBundle loadNibNamed: @"Debits" owner: debitsController topLevelObjects: nil]) {
            LogDebug(@"Loading successful");
            NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier: DebitsTabIdentifier];
            [item setView: [debitsController mainView]];
            [mainTabView addTabViewItem: item];
            [mainTabView selectTabViewItem: item];
            mainTabItems[DebitsTabIdentifier] = debitsController;
            [debitsController prepare];
        }
    } else {
        [mainTabView selectTabViewItemAtIndex: index];
        [debitsController activate];
    }
}

@end
