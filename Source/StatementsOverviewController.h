/**
 * Copyright (c) 2013, 2014, Pecunia Project. All rights reserved.
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

#import "PecuniaSectionItem.h"
#import "StatementsListView.h"

@interface StatementsOverviewController : NSObject <PecuniaSectionItem, StatementsListViewProtocol>

- (BOOL)validateMenuItem: (NSMenuItem *)item;
- (void)deleteSelectedStatements;
- (void)splitSelectedStatement;
- (void)markSelectedStatementsUnread;
- (void)clearStatementFilter;
- (void)reload;

// PecuniaSectionItem protocol
@property (nonatomic, weak) Category       *selectedCategory;
@property (nonatomic, strong) IBOutlet NSView *mainView;

- (void)activate;
- (void)deactivate;
- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to;
- (void)print;
- (void)terminate;

@end
