//
//  CatDefWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "CatDefWindowController.h"
#import "CatAssignClassification.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "Category.h"
#import "CategoryView.h"
#import "MCEMOutlineViewLayout.h"
#import "MCEMTreeController.h"
#import "TimeSliceManager.h"
#import "ShortDate.h"
#import "StatCatAssignment.h"
#import "ImageAndTextCell.h"
#import "AmountCell.h"

#define BankStatementDataType	@"BankStatementDataType"
#define CategoryDataType		@"CategoryDataType"

@implementation CatDefWindowController

-(id)init
{
	self = [super init ];
	if(self == nil) return nil;
	ruleChanged = NO;
	return self;
}

-(void)awakeFromNib
{
	NSTableColumn	*tc;
	
	notAssignedSelected = NO;
	awaking = YES;
	
	// green color for preview
	tc = [assignPreview tableColumnWithIdentifier: @"value" ];
	if(tc) {
		NSCell	*cell = [tc dataCell ];
		NSNumberFormatter	*form = [cell formatter ];
		if(form) {
			NSDictionary *newAttrs = [NSDictionary dictionaryWithObjectsAndKeys: 
									  [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100], @"NSColor", nil ];
			[form setTextAttributesForPositiveValues: newAttrs ];
		}
	}
 
	// default: hide values that are already assigned elsewhere
	hideAssignedValues = YES;
	[self setValue:[NSNumber numberWithBool:YES ]  forKey: @"hideAssignedValues" ];
	
	caClassification = [[CatAssignClassification alloc] init];
	[predicateEditor addRow:self ];
//	if ([[MOAssistant assistant ] context]) [catDefController fetchWithRequest:nil merge:NO error:&error];
	
	// sort descriptor for transactions view
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"statement.date" ascending:NO] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[assignPreviewController setSortDescriptors: sds ];
	
	// sort descriptor for category view
	sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	sds = [NSArray arrayWithObject:sd];
	[catDefController setSortDescriptors: sds ];
	
	// register Drag'n Drop
	[assignPreview registerForDraggedTypes: [NSArray arrayWithObject: BankStatementDataType ] ];
	[catView registerForDraggedTypes: [NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil ] ];
	
//	[self performSelector: @selector(restoreCatView) withObject: nil afterDelay: 0.0];
	awaking = NO;
	[catDefController addObserver:self forKeyPath:@"arrangedObjects.catSum" options:0 context:NULL];	
}

-(void)setManagedObjectContext:(NSManagedObjectContext*)context
{
	[assignPreviewController setManagedObjectContext: context ];
	[assignPreviewController prepareContent ];
	[catDefController setManagedObjectContext:context ];
	[catDefController prepareContent ];
	[timeSlicer updateDelegate ];
	[self performSelector: @selector(restoreCatView) withObject: nil afterDelay: 0.0];
}


-(void)prepare
{
	[BankStatement setClassificationContext: caClassification ];
	[self calculateCatAssignPredicate ];
	
	// update values according to slicer
	Category *cat = [Category catRoot ];
	[Category setCatReportFrom: [timeSlicer lowerBounds ] to: [timeSlicer upperBounds ] ];
	[cat rebuildValues ];
	[cat rollup ];
}

-(void)restoreCatView
{
	[catView restoreAll ];
}

-(Category*)currentSelection
{
	NSArray* sel = [catDefController selectedObjects ];
	if(sel == nil || [sel count ] != 1) return nil;
	return [sel objectAtIndex: 0 ];
}
	
- (IBAction)add:(id)sender 
{
	NSError* error;
	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	
	NSArray* trs = [assignPreviewController selectedObjects ];
	StatCatAssignment* stat;

	for(stat in trs) {
		[stat.statement assignAmount: [stat value ] toCategory: cat ];
	}
	[assignPreview setNeedsDisplay: YES ];
	
	[cat invalidateBalance ];
	[Category updateCatValues ];
//	[catView setNeedsDisplay: YES ];
	
	// save updates
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

- (IBAction)remove:(id)sender 
{
	NSError* error;
	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	
	NSArray* trs = [assignPreviewController selectedObjects ];
	StatCatAssignment* stat;
	for(stat in trs) {
		[stat remove ];
	}
	[assignPreviewController rearrangeObjects ];
	[assignPreview setNeedsDisplay: YES ];

	[cat invalidateBalance ];
	[Category updateCatValues ];
//	[catView setNeedsDisplay: YES ];

	// save updates
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
    
}

- (IBAction)saveRule:(id)sender 
{
	NSError* error;

	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	
	NSPredicate* predicate = [predicateEditor objectValue];
	if(predicate) {
		[cat setValue: [predicate description ] forKey: @"rule" ];
	
		// save updates
		NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
		if([context save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
		ruleChanged = NO;
	}
}

- (IBAction)deleteRule:(id)sender
{
	NSError* error;
	
	Category *cat = [self currentSelection ];
	if(cat == nil) return;

	int res = NSRunAlertPanel(NSLocalizedString(@"AP77", @""),
							  NSLocalizedString(@"AP78", @""),
							  NSLocalizedString(@"yes", @"Yes"),
							  NSLocalizedString(@"no", @"No"),
							  nil,
							  [cat localName ]
							  );
	if(res != NSAlertDefaultReturn) return;
	
	[cat setValue: nil forKey: @"rule" ];
	ruleChanged = NO;
	
	// save updates
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	NSPredicate* pred = [NSCompoundPredicate predicateWithFormat: @"statement.purpose CONTAINS[c] ''" ];
	if([pred class ] != [NSCompoundPredicate class ]) {
		NSCompoundPredicate* comp = [[NSCompoundPredicate alloc ] initWithType: NSOrPredicateType subpredicates: [NSArray arrayWithObjects: pred, nil ]];
		pred = comp;
	}
	[predicateEditor setObjectValue: pred ];
	
	[self calculateCatAssignPredicate ];
}

-(IBAction)addCategory: (id)sender
{
	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	if([cat isRoot ]) return [self insertCategory: sender ];
	[catDefController add: sender ]; 
	[catView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];
}

-(IBAction)insertCategory: (id)sender
{
	[catDefController addChild: sender ];
	[catView performSelector: @selector(editSelectedCell) withObject: nil afterDelay: 0.0];
}


-(IBAction)manageCategories:(id)sender
{
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	switch(clickedSegmentTag) {
		case 0: [self addCategory: sender ]; break;
		case 1: [self insertCategory: sender ]; break;
		case 2: [self deleteCategory: sender ]; break;
		default: return;
	}
}

-(NSString*)autosaveNameForTimeSlicer: (TimeSliceManager*)tsm
{
	return @"CatDefTimeSlice";
}

-(void)timeSliceManager: (TimeSliceManager*)tsm changedIntervalFrom: (ShortDate*)from to: (ShortDate*)to
{
	int idx = [mainTabView indexOfTabViewItem: [mainTabView selectedTabViewItem ] ];
	if(idx != 2) return;
	Category *cat = [Category catRoot ];
	[Category setCatReportFrom: from to: to ];
	[cat rebuildValues ];
	[cat rollup ];
	[self calculateCatAssignPredicate ];
}

-(void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
	if([aNotification object ] == catView) {
		Category *cat = [self currentSelection ];
		catView.saveCatName = [[cat name ] retain];
	}	
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	if([aNotification object ] == catView) {
		Category *cat = [self currentSelection ];
		if([cat name ] == nil) {
			[cat setValue: [catView.saveCatName autorelease ] forKey: @"name" ];
		}
		[catDefController resort ];
		if(cat) [catDefController setSelectedObject: cat ];
	}
}

- (IBAction)deleteCategory: (id)sender
{
	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	
	if([cat isRemoveable ] == NO) return;
	NSArray *stats = [[cat mutableSetValueForKey: @"assignments" ] allObjects ];
	StatCatAssignment *stat;
	
	if([stats count ] > 0) {
		int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP84", @"Delete category"),
										  NSLocalizedString(@"AP85", @"Category '%@' still has %d assigned transactions. Do you want to proceed anyway?"),
										  NSLocalizedString(@"no", @"No"),
										  NSLocalizedString(@"yes", @"Yes"),
										  nil,
										  [cat localName ],
										  [stats count ],
										  nil
										  );
		if(res != NSAlertAlternateReturn) return;
	}
	
	//  Delete bank statements from category first
	for(stat in stats) {
		[stat remove ];
	}
	[catDefController remove: cat ];
	[Category updateCatValues ]; 
//	[catView setNeedsDisplay: YES ];
}

-(void)calculateCatAssignPredicate
{
	NSPredicate* pred = nil;
	NSPredicate* compound = nil;
	
	// first add selected category
	Category* cat = [self currentSelection ];
	if(cat == nil) return;
	
	NSMutableArray *orPreds = [NSMutableArray arrayWithCapacity: 5 ];
	
	if([cat valueForKey: @"parent" ] != nil) {
		pred = [NSPredicate predicateWithFormat: @"(category = %@)", cat ];
		[orPreds addObject: pred ];
	}
	NSPredicate* predicate = [predicateEditor objectValue];
	
	// Not assigned statements
	pred = [NSPredicate predicateWithFormat: @"(category = %@)", [Category nassRoot ] ];
	pred = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: pred, predicate, nil ] ];
	[orPreds addObject: pred ];

	// already assigned statements 
	if(!hideAssignedValues) {
		pred = [NSPredicate predicateWithFormat: @"(category.isBankAccount = 0)" ];
		pred = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: pred, predicate, nil ] ];
		[orPreds addObject: pred ];
	}
	
	compound = [NSCompoundPredicate orPredicateWithSubpredicates: orPreds ];
	pred = [timeSlicer predicateForField: @"date" ];
    compound = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: compound, pred, nil ] ];
	
	
	// update classification Context
	if(cat == [Category nassRoot ]) [caClassification setCategory: nil]; else [caClassification setCategory: cat];
	
	// set new fetch predicate
	if(compound) [assignPreviewController setFilterPredicate: compound ];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	Category *cat = [item representedObject ];
	if(cat == nil) return NO;
//	return cat != [Category nassRoot ];
	return YES;
}

- (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView
{
	Category* cat = [self currentSelection ];
	if(cat == nil) return YES;
	if(ruleChanged == YES) {
		int res = NSRunAlertPanel(NSLocalizedString(@"AP75", @""),
								  NSLocalizedString(@"AP76", @""),
								  NSLocalizedString(@"yes", @"Yes"),
								  NSLocalizedString(@"no", @"No"),
								  nil,
								  [cat localName ]
								  );
		if(res == NSAlertDefaultReturn) [self saveRule:self ];
		ruleChanged = NO;
	}
	return YES;
}


-(void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	// first add selected category
	Category* cat = [self currentSelection ];
	if(cat == nil) return;
	
	if(cat == [Category nassRoot ]) {
		int i;
		NSArray *subviews = [rightSplitContent subviews ];
		NSRect frame = [rightSplitContent frame ];
		frame.origin.x = 0;
		for(i=0; i<[subviews count ]; i++) {
			NSView *cView = [subviews objectAtIndex:i ];
			if([cView tag ] == 1) [cView setHidden: YES ];
		}
		[[[predicateEditor superview] superview ] setHidden: YES ];
		
		[[[assignPreview superview ] superview ] setFrame: frame ];
		notAssignedSelected = YES;
	} else {
		if(notAssignedSelected) {
			int i;
			NSArray *subviews = [rightSplitContent subviews ];
			NSRect frame = [rightSplitContent frame ];
			frame.origin.x = 0; frame.origin.y = 20;
			frame.size.height -= 306;
			for(i=0; i<[subviews count ]; i++) {
				NSView *cView = [subviews objectAtIndex:i ];
				if([cView tag ] == 1) [cView setHidden: NO ];
			}
			[[[predicateEditor superview] superview ] setHidden: NO ];
			
			[[[assignPreview superview ] superview ] setFrame: frame ];
			notAssignedSelected = NO;
		}
	}
	
	// set states of categorie Actions Control
	[catActions setEnabled: [cat isRemoveable ] forSegment: 2 ];
	[catActions setEnabled: [cat isInsertable ] forSegment: 1 ];

	NSString* s = [cat valueForKey: @"rule" ];
	if(s == nil) s = @"statement.purpose CONTAINS[c] ''";
	NSPredicate* pred = [NSCompoundPredicate predicateWithFormat: s ];
	if([pred class ] != [NSCompoundPredicate class ]) {
		NSCompoundPredicate* comp = [[NSCompoundPredicate alloc ] initWithType: NSOrPredicateType subpredicates: [NSArray arrayWithObjects: pred, nil ]];
		pred = comp;
	}
	[predicateEditor setObjectValue: pred ];
	[self calculateCatAssignPredicate ];
}

- (IBAction)predicateEditorChanged:(id)sender
{	
	if(awaking) return;
	// check NSApp currentEvent for the return key
    NSEvent* event = [NSApp currentEvent];
    if ([event type] == NSKeyDown)
	{
		NSString* characters = [event characters];
		if ([characters length] > 0 && [characters characterAtIndex:0] == 0x0D)
		{
			[self calculateCatAssignPredicate ];
			ruleChanged = YES;
		}
    }
    // if the user deleted the first row, then add it again - no sense leaving the user with no rows
    if ([predicateEditor numberOfRows] == 0)
		[predicateEditor addRow:self];
}

- (void)ruleEditorRowsDidChange:(NSNotification *)notification
{
	[self calculateCatAssignPredicate ];
}

- (IBAction)hideAssignedChanged:(id)sender
{
	[self calculateCatAssignPredicate ];
}


- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item 
{
    return [outlineView persistentObjectForItem: item ];
}

-(id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object
{
    return nil;
}

-(void)terminateController
{
	[catView saveLayout ];
}

// Dragging Bank Statements
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	unsigned int		idx[10], count, i;
	StatCatAssignment	*stat;
	NSRange				range;
	NSMutableArray		*uris = [NSMutableArray arrayWithCapacity: 10 ];
	
	range.location = 0;
	range.length = 100000;
	
    // Copy the row numbers to the pasteboard.
	NSArray *objs = [assignPreviewController arrangedObjects ];
	
	do {
		count = [rowIndexes getIndexes: idx maxCount:10 inIndexRange: &range ];
		for(i=0; i < count; i++) {
			stat = [objs objectAtIndex: idx[i] ];
			NSURL *uri = [[stat objectID] URIRepresentation];
			[uris addObject: uri ];
		}
	} while(count > 0);
		
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uris];
    [pboard declareTypes:[NSArray arrayWithObject: BankStatementDataType] owner:self];
    [pboard setData:data forType: BankStatementDataType];
	[tv setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove forLocal: YES ];
    return YES;
}

// Drag Categories
- (BOOL)outlineView:(NSOutlineView*)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard 
{
	Category		*cat;
	
	cat = [[items objectAtIndex:0 ] representedObject ];
	if(cat == nil) return NO;
	if([cat isBankAccount ]) return NO;
	if([cat isRoot ]) return NO;
	if(cat == [Category nassRoot ]) return NO;
	NSURL *uri = [[cat objectID] URIRepresentation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uri];
    [pboard declareTypes:[NSArray arrayWithObject: CategoryDataType] owner:self];
    [pboard setData:data forType: CategoryDataType];
	return YES;
}


- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex
{
	NSPasteboard *pboard = [info draggingPasteboard];
	
    // This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
	if(childIndex >= 0) return NSDragOperationNone;
	if(item == nil) return NSDragOperationNone;
	Category* cat = (Category*)[item representedObject ];
	if([cat isBankAccount]) return NSDragOperationNone;
	
	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil]];
	if(type == nil) return NO;
	if([type isEqual: BankStatementDataType ]) {
		Category *scat = [self currentSelection ];
		if([cat isRoot ]) return NSDragOperationNone;
		// if source is not assigned -> do move
		if(scat == [Category nassRoot ]) return NSDragOperationMove;
		NSDragOperation mask = [info draggingSourceOperationMask];
		if(mask == NSDragOperationCopy && cat != [Category nassRoot ]) return NSDragOperationCopy;
		return NSDragOperationMove;
	} else {
		NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
		NSData *data = [pboard dataForType: type ];
		NSURL *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data ];
		NSManagedObjectID *moID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri ];
		Category *scat = (Category*)[context objectWithID: moID];
		if ([scat checkMoveToCategory:cat ] == NO) return NSDragOperationNone;
		return NSDragOperationMove;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex 
{
	int i;
	NSError *error;
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	Category *cat = (Category*)[item representedObject ];
	NSPasteboard *pboard = [info draggingPasteboard];
	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects: BankStatementDataType, CategoryDataType, nil]];
	if(type == nil) return NO;
	NSData *data = [pboard dataForType: type ];

	if([type isEqual: BankStatementDataType ]) {
		NSDragOperation mask = [info draggingSourceOperationMask];
		NSArray *uris = [NSKeyedUnarchiver unarchiveObjectWithData: data ];
		for(i=0; i<[uris count ]; i++) {
			NSURL *uri = [uris objectAtIndex: i ];
			NSManagedObjectID *moID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri ];
			if(moID == nil) continue;
			StatCatAssignment *stat = (StatCatAssignment*)[context objectWithID: moID];
			if(mask == NSDragOperationCopy) [stat.statement assignAmount: stat.value toCategory: cat ]; else {
				[stat moveToCategory: cat ];
				[assignPreviewController fetch: self ];
			}
		}
		[assignPreview reloadData ];
		[assignPreview setNeedsDisplay: YES ];

		[cat invalidateBalance ];
		[Category updateCatValues ];
//		[catView setNeedsDisplay: YES ];
	} else {
		NSURL *uri = [NSKeyedUnarchiver unarchiveObjectWithData: data ];
		NSManagedObjectID *moID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri ];
		if(moID == nil) return NO;
		Category *scat = (Category*)[context objectWithID: moID];
		[scat setValue: cat forKey: @"parent" ];
		[[Category catRoot ] rollup ];
	}
	
	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return NO;
	}
	return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(ImageAndTextCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	Category *cat = [item representedObject ];
	if(cat == nil) return;

/*	
	NSImage *catImage		= [NSImage imageNamed:@"catdef4_18.png"];
	NSImage *moneyImage		= [NSImage imageNamed:@"money_18.png"];
	NSImage *moneySyncImage	= [NSImage imageNamed:@"money_sync_18.png"];
	NSImage *folderImage	= [NSImage imageNamed:@"folder_18.png"];
*/	
	[cell setImage: nil];
	
	BOOL itemIsSelected = FALSE;
	if ([outlineView itemAtRow:[outlineView selectedRow]] == item)	 itemIsSelected = TRUE;
	
	[cell setValues:[cat catSum] currency:cat.currency unread:0 selected:itemIsSelected root:[cat isRoot] ];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier ] isEqualToString: @"value" ]) {
		NSArray *statements = [assignPreviewController arrangedObjects ];
		StatCatAssignment *stat = [statements objectAtIndex:rowIndex ];
		
		AmountCell *cell = (AmountCell*)aCell;
		cell.amount = stat.value;
		cell.currency = stat.statement.currency;
	}
}	

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == catDefController) {
		[catView setNeedsDisplay: YES ];
	}	
}


- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	if(offset==0) return 270;
	return proposedMin;
}


-(void)dealloc
{
	[caClassification release ];
	[super dealloc ];
}

@end
