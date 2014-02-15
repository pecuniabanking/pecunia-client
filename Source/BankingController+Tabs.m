/**
 * Copyright (c) 2010, 2013, Pecunia Project. All rights reserved.
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
        [MessageLog.log addMessage: @"Loading HomeScreen.xib" withLevel: LogLevel_Debug];
        if ([NSBundle loadNibNamed: @"HomeScreen" owner: homeScreenController]) {
            [MessageLog.log addMessage: @"Loading successful" withLevel: LogLevel_Debug];
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
        [MessageLog.log addMessage: @"Loading Orders.xib" withLevel: LogLevel_Debug];
        if ([NSBundle loadNibNamed: @"Orders" owner: standingOrderController]) {
            [MessageLog.log addMessage: @"Loading successful" withLevel: LogLevel_Debug];
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
        [MessageLog.log addMessage: @"Loading Transfers.xib" withLevel: LogLevel_Debug];
        if ([NSBundle loadNibNamed: @"Transfers" owner: transfersController]) {
            [MessageLog.log addMessage: @"Loading successful" withLevel: LogLevel_Debug];
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
        [MessageLog.log addMessage: @"Loading Debits.xib" withLevel: LogLevel_Debug];
        if ([NSBundle loadNibNamed: @"Debits" owner: debitsController]) {
            [MessageLog.log addMessage: @"Loading successful" withLevel: LogLevel_Debug];
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
