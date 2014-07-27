/**
 * Copyright (c) 2011, 2014, Pecunia Project. All rights reserved.
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

#import "PecuniaListViewCell.h"

typedef NS_ENUM (NSInteger, StatementMenuAction) {
    MenuActionShowDetails,
    MenuActionAddStatement,
    MenuActionSplitStatement,
    MenuActionDeleteStatement,
    MenuActionMarkRead,
    MenuActionMarkUnread,
    MenuActionStartTransfer,
    MenuActionCreateTemplate
};

@protocol StatementsListViewNotificationProtocol

- (void)cellActivationChanged: (BOOL)state forIndex: (NSUInteger)index;
- (void)menuActionForCell: (PecuniaListViewCell *)cell action: (StatementMenuAction)action;
- (BOOL)canHandleMenuActions;

@end

@interface StatementsListViewCell : PecuniaListViewCell

@property (nonatomic, strong) id   delegate;
@property (nonatomic, assign) BOOL hasUnassignedValue;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic, assign) NSUInteger turnovers;

- (IBAction)activationChanged: (id)sender;

- (void)setHeaderHeight: (int)aHeaderHeight;
- (void)showActivator: (BOOL)flag markActive: (BOOL)active;
- (void)showBalance: (BOOL)flag;

@end
