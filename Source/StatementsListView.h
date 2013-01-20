/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#import <Cocoa/Cocoa.h>

#import "PXListView.h"
#import "StatementsListviewCell.h"

@protocol StatementsListViewProtocol <PXListViewDelegate>
- (void)activationChanged: (BOOL)active forIndex: (NSUInteger)index;
@end;

@interface StatementsListView : PXListView <PXListViewDelegate, StatementsListViewNotificationProtocol>
{
@private
    id observedObject;

    NSDateFormatter* dateFormatter;
    NSNumberFormatter* numberFormatter;
    
    NSIndexSet* draggedIndexes;
    
    BOOL showAssignedIndicators;
    id owner;
    BOOL autoResetNew;
    BOOL pendingReload;  // Set when a notification arrived to completely reload the listview.
    BOOL pendingRefresh; // Set when there was already a notification to refresh visible cells (for property changes).
    BOOL activating;     // Set when a cells are activated programmatically (so we don't send notifications around).

    // This are cached user settings.
    BOOL showBalances;
    BOOL showHeaders;
    BOOL autoCasing;
}

@property (nonatomic, assign) BOOL showAssignedIndicators;
@property (nonatomic, strong) id owner;
@property (nonatomic, assign) BOOL autoResetNew;
@property (nonatomic, assign) BOOL disableSelection;
@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, assign) BOOL canShowHeaders; // Headers can be switched off temporarily.

- (NSNumberFormatter*) numberFormatter;

- (void)updateVisibleCells;
- (void)activateCells;

@end
