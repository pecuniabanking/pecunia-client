/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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

#import "PecuniaSectionItem.h"

@class CatAssignClassification;
@class Category;
@class StatementsListView;
@class TimeSliceManager;

@class BWGradientBox;

@interface CategoryDefWindowController : NSObject <PecuniaSectionItem>
{
    IBOutlet NSArrayController	*assignPreviewController;
    IBOutlet NSPredicateEditor	*predicateEditor;
	IBOutlet NSView				*rightSplitContent;
    IBOutlet NSView             *topView;
    IBOutlet StatementsListView *statementsListView;
    IBOutlet NSButton           *saveButton;
    IBOutlet NSButton           *discardButton;
    
    IBOutlet BWGradientBox      *predicatesBackground;
	
	CatAssignClassification* caClassification;
    TimeSliceManager* timeSliceManager;
	BOOL hideAssignedValues;
	BOOL ruleChanged;
	BOOL awaking;
    
    Category* currentCategory;
}

@property (nonatomic, strong) TimeSliceManager* timeSliceManager;
@property (nonatomic, strong) Category* category;

- (IBAction)predicateEditorChanged:(id)sender;
- (IBAction)saveRule:(id)sender;
- (IBAction)deleteRule:(id)sender;
- (IBAction)hideAssignedChanged:(id)sender;

- (void)setManagedObjectContext: (NSManagedObjectContext*)context;
- (void)calculateCatAssignPredicate;

- (void)activationChanged: (BOOL)active forIndex: (NSUInteger)index;
- (BOOL)categoryShouldChange;

// PecuniaSectionItem protocol.
- (NSView*)mainView;
- (void)print;
- (void)prepare;
- (void)activate;
- (void)deactivate;

@end
