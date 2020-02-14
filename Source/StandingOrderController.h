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

#import <Cocoa/Cocoa.h>

#import "PecuniaTabItem.h"
#import "OrdersListView.h"

@class TransactionLimits;
@class StandingOrder;
@class TransferFormularView;
@class DeleteOrderTargetView;

@interface StandingOrderController : NSObject <PecuniaTabItem> {
    IBOutlet NSArrayController     *orderController;
    IBOutlet NSArrayController     *monthCyclesController;
    IBOutlet NSArrayController     *weekCyclesController;
    IBOutlet NSArrayController     *execDaysMonthController;
    IBOutlet NSArrayController     *execDaysWeekController;
    IBOutlet NSView                *mainView;
    IBOutlet NSButtonCell          *monthCell;
    IBOutlet NSButtonCell          *weekCell;
    IBOutlet NSPopUpButton         *monthCyclesPopup;
    IBOutlet NSPopUpButton         *weekCyclesPopup;
    IBOutlet NSPopUpButton         *execDaysMonthPopup;
    IBOutlet NSPopUpButton         *execDaysWeekPopup;
    IBOutlet OrdersListView        *ordersListView;
    IBOutlet TransferFormularView  *standingOrderForm;
    IBOutlet NSPopUpButton         *sourceAccountSelector;
    IBOutlet NSComboBox            *receiverComboBox;
    IBOutlet DeleteOrderTargetView *deleteImage;
    IBOutlet NSButton              *deleteButton;

@private
    NSManagedObjectContext *managedObjectContext;
    NSArray                *weekDays;
    TransactionLimits      *currentLimits;
    StandingOrder          *currentOrder;
    NSNumber               *oldMonthCycle;
    NSNumber               *oldMonthDay;
    NSNumber               *oldWeekCycle;
    NSNumber               *oldWeekDay;

    NSNumber *requestRunning;
    BOOL     initializing;
}

@property (nonatomic, strong) NSNumber          *requestRunning;
@property (nonatomic, strong) NSNumber          *oldMonthCycle;
@property (nonatomic, strong) NSNumber          *oldMonthDay;
@property (nonatomic, strong) NSNumber          *oldWeekCycle;
@property (nonatomic, strong) NSNumber          *oldWeekDay;
@property (nonatomic, strong) TransactionLimits *currentLimits;
@property (nonatomic, strong) StandingOrder     *currentOrder;
@property (nonatomic, assign) BOOL              editable;

- (NSView *)mainView;
- (void)disableCycles;

- (IBAction)monthCycle: (id)sender;
- (IBAction)weekCycle: (id)sender;
- (IBAction)monthCycleChanged: (id)sender;
- (IBAction)monthDayChanged: (id)sender;
- (IBAction)weekCycleChanged: (id)sender;
- (IBAction)weekDayChanged: (id)sender;
- (IBAction)firstExecDateChanged: (id)sender;
- (IBAction)lastExecDateChanged: (id)sender;

- (IBAction)update: (id)sender;
- (IBAction)getOrders: (id)sender;

- (BOOL)concludeDropDeleteOperation: (id<NSDraggingInfo>)info;
- (IBAction)deleteOrder: (id)sender;

@end
