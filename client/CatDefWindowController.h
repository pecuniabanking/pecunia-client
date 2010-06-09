//
//  CatDefWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CatAssignClassification;
@class CategoryView;
@class MCEMTreeController;
@class TimeSliceManager;

@interface CatDefWindowController : NSObject 
{
    IBOutlet NSArrayController	*assignPreviewController;
    IBOutlet MCEMTreeController	*catDefController;
    IBOutlet NSPredicateEditor	*predicateEditor;
	IBOutlet NSTableView		*assignPreview;
	IBOutlet CategoryView		*catView;
	IBOutlet NSSplitView		*splitView;
	IBOutlet NSView				*rightSplitContent;
	IBOutlet NSTabView			*mainTabView;
	IBOutlet TimeSliceManager	*timeSlicer;
	IBOutlet NSSegmentedControl *catActions;
	IBOutlet NSButton			*saveButton;
	
	CatAssignClassification		*caClassification;
	BOOL						hideAssignedValues;
	BOOL						notAssignedSelected;
	BOOL						ruleChanged;
	BOOL						awaking;
}
- (IBAction)add:(id)sender;
- (IBAction)predicateEditorChanged:(id)sender;
//- (IBAction)remove:(id)sender;
- (IBAction)saveRule:(id)sender;
- (IBAction)deleteRule:(id)sender;
- (IBAction)hideAssignedChanged:(id)sender;
- (IBAction)deleteCategory: (id)sender;
- (IBAction)addCategory: (id)sender;
- (IBAction)insertCategory: (id)sender;
- (IBAction)manageCategories:(id)sender;

-(void)prepare;
-(void)terminateController;

-(void)calculateCatAssignPredicate;

@end
