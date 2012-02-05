/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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
    NSArray* _dataSource;
    NSArray* _valueArray;
    
    NSDateFormatter* _dateFormatter;
    NSNumberFormatter* _numberFormatter;
    NSCalendar* _calendar;
    
    NSIndexSet* draggedIndexes;
    
    BOOL showAssignedIndicators;
    id owner;
    BOOL autoResetNew;
}

@property (nonatomic, assign) BOOL showAssignedIndicators;
@property (nonatomic, retain) id owner;
@property (nonatomic, assign) BOOL autoResetNew;

- (NSNumberFormatter*) numberFormatter;

- (NSArray*)dataSource;
- (void)setDataSource: (NSArray*)source;

- (NSArray*)valueArray;
- (void)setValueArray: (NSArray*)array;

- (void)updateSelectedCells;
- (void)updateDraggedCells;

@end
