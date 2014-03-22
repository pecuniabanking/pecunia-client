/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import <Foundation/Foundation.h>

#import "PecuniaSectionItem.h"

@class StatementsListView;
@class TagView;
@class AttachmentImageView;
@class StatementDetails;
@class PecuniaSplitView;

@interface StatementsOverviewController : NSObject <PecuniaSectionItem>
{
    IBOutlet NSArrayController  *categoryAssignments;
    IBOutlet StatementsListView *statementsListView;

    IBOutlet NSArrayController *statementTags;
    IBOutlet NSArrayController *tagsController;
    IBOutlet NSButton          *tagButton;
    IBOutlet TagView           *tagsField;
    IBOutlet TagView           *tagViewPopup;
    IBOutlet NSView            *tagViewHost;
    IBOutlet NSTextField       *valueField;
    IBOutlet NSTextField       *nassValueField;
    IBOutlet NSTextField       *remoteNameLabel;
    IBOutlet StatementDetails  *statementDetails;
    IBOutlet NSTextField       *selectedSumField;
    IBOutlet NSTextField       *totalSumField;
    IBOutlet NSTextField       *originalAmountField;

    IBOutlet NSSegmentedControl *sortControl;

    IBOutlet AttachmentImageView *attachment1;
    IBOutlet AttachmentImageView *attachment2;
    IBOutlet AttachmentImageView *attachment3;
    IBOutlet AttachmentImageView *attachment4;
}

@property (strong) IBOutlet PecuniaSplitView *mainView;
@property (weak) NSButton *toggleDetailsButton; // Reference to the BankingController's toggle button.

- (BOOL)validateMenuItem: (NSMenuItem *)item;
- (void)deleteSelectedStatements;
- (void)splitSelectedStatement;
- (BOOL)toggleDetailsPane;

// PecuniaSectionItem protocol
@property (nonatomic, weak) Category *selectedCategory;

- (void)activate;
- (void)deactivate;
- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to;
- (void)print;
- (void)terminate;

@end
