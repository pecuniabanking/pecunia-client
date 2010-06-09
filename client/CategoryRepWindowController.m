//
//  CategoryRepWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 19.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "CategoryRepWindowController.h"
#import <SM2DGraphView/SMPieChartView.h>
#import "Category.h"
#import "MCEMOutlineViewLayout.h"
#import "ShortDate.h"
#import "TimeSliceManager.h"

NSInteger comparePies(NSDictionary *a, NSDictionary *b, void* context)
{
	NSString *s1 = [a objectForKey: @"name" ];
	NSString *s2 = [b objectForKey: @"name" ];
	NSComparisonResult r = [s1 compare: s2 ];
	return r;
}

@implementation CategoryRepWindowController

-(id)init
{
	self = [super init ];
	if(self == nil) return nil;
	
	incomesX = expensesX = 0;
	return self;
}

-(void)awakeFromNib
{
	NSError	*error;
	NSRect	frame;
	
	expensesCats = [[NSMutableArray arrayWithCapacity: 10 ] retain ];
	incomesCats  = [[NSMutableArray arrayWithCapacity: 10 ] retain ];
	if([categoryController fetchWithRequest:nil merge:NO error:&error]); // [categoryView restoreAll ];
	incomeExplosionIndex = expenseExplosionIndex = -1;
	
	// get origin x coordinates
	frame = [expenseView frame ];
	expensesX = frame.origin.x;
	frame = [incomeView frame ];
	incomesX = frame.origin.x;
	
	// set Titles
	NSMutableAttributedString *s;
	s = [[NSMutableAttributedString alloc ] initWithString: NSLocalizedString(@"AP64", @"Revenues") ];
	[s addAttribute:NSFontAttributeName
			  value:[NSFont userFontOfSize: 16 ]
			  range:NSMakeRange(0, [s length ]) ];
	[incomeView setAttributedTitle: s ];

	s = [[NSMutableAttributedString alloc ] initWithString: NSLocalizedString(@"AP65", @"Expenses") ];
	[s addAttribute:NSFontAttributeName
			  value:[NSFont userFontOfSize: 16 ]
			  range:NSMakeRange(0, [s length ]) ];
	[expenseView setAttributedTitle: s ];
	
	[self performSelector: @selector(restoreCatView) withObject: nil afterDelay: 0.0];
}


-(void)prepare
{
}

-(void)restoreCatView
{
	[categoryView restoreAll ];
}

-(Category*)currentSelection
{
	NSArray* sel = [categoryController selectedObjects ];
	if(sel == nil || [sel count ] != 1) return nil;
	return [sel objectAtIndex: 0 ];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[incomeLegend deselectAll: self ];
	[expenseLegend deselectAll: self ];
	[self updateValues ];
	[self updateViews ];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	Category *cat = [item representedObject ];
	if(cat == nil) return;
	if(![[tableColumn identifier ] isEqualToString: @"category" ]) return;
	
	NSMutableSet *children = [cat children ];
	if(children == nil || [children count ] == 0) {
		//display in gray color
		NSColor *txtColor = [NSColor grayColor];
		NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys: txtColor, NSForegroundColorAttributeName, nil];
		NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString: [cat localName ] attributes:txtDict] autorelease];
		[cell setAttributedStringValue:attrStr];
	}
	
	if([cat isRoot ]) {
		NSColor *txtColor;
		if([cell isHighlighted ]) txtColor = [NSColor whiteColor]; 
		else txtColor = [NSColor colorWithCalibratedHue: 0.6194 saturation: 0.32 brightness:0.56 alpha:1.0 ];
		NSFont *txtFont = [NSFont fontWithName: @"Arial Rounded MT Bold" size: 13];
		NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys: txtFont,NSFontAttributeName,txtColor, NSForegroundColorAttributeName, nil];
		NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString: [cat localName ] attributes:txtDict] autorelease];
		[cell setAttributedStringValue:attrStr];
	}
}

-(void)updateValues
{
	NSDecimalNumber	*result;
	
	[expensesCats removeAllObjects ];
	[incomesCats removeAllObjects ];

	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	
	NSMutableSet* childs = [cat mutableSetValueForKey: @"children" ];
	
	if([childs count ] > 0) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults ];
		BOOL balance = [userDefaults boolForKey: @"balanceCategories" ];
		
		NSEnumerator	*enumerator = [childs objectEnumerator];
		NSDecimalNumber	*zero = [NSDecimalNumber zero ];
		Category		*ccat;
		
		while ((ccat = [enumerator nextObject])) {
			if(balance) {
				result = [ccat valuesOfType: cat_all from: fromDate to: toDate ];
				if([result compare: zero ] == NSOrderedAscending) {
					NSMutableDictionary	*pieData = [NSMutableDictionary dictionaryWithCapacity: 2 ];
					[pieData setObject: [ccat localName ] forKey: @"name" ];
					[pieData setObject: result forKey: @"value" ];
					[expensesCats addObject: pieData ];
				}
				if([result compare: zero ] == NSOrderedDescending) {
					NSMutableDictionary	*pieData = [NSMutableDictionary dictionaryWithCapacity: 2 ];
					[pieData setObject: [ccat localName ] forKey: @"name" ];
					[pieData setObject: result forKey: @"value" ];
					[incomesCats addObject: pieData ];
				}
			} else {
				result = [ccat valuesOfType: cat_expenses from: fromDate to: toDate ];
				if([result compare: zero ] != NSOrderedSame) {
					NSMutableDictionary	*pieData = [NSMutableDictionary dictionaryWithCapacity: 2 ];
					[pieData setObject: [ccat localName ] forKey: @"name" ];
					[pieData setObject: result forKey: @"value" ];
					[expensesCats addObject: pieData ];
				}
				result = [ccat valuesOfType: cat_incomes from: fromDate to: toDate ];
				if([result compare: zero ] != NSOrderedSame) {
					NSMutableDictionary	*pieData = [NSMutableDictionary dictionaryWithCapacity: 2 ];
					[pieData setObject: [ccat localName ] forKey: @"name" ];
					[pieData setObject: result forKey: @"value" ];
					[incomesCats addObject: pieData ];
				}
			}
		}
	}
	[incomesCats sortUsingFunction: comparePies context:nil ];
	[expensesCats sortUsingFunction: comparePies context:nil ];
	[self setColors ];
	[incomeView refreshDisplay: self ];
	[expenseView refreshDisplay: self ];
	[incomeLegend reloadData ];
	[expenseLegend reloadData ];
}

-(void)updateViews
{
	if(expensesX == 0) return;
	BOOL income = [incomesCats count ] > 0;
	BOOL expense = [expensesCats count ] > 0;
	
	NSView *inl = [[incomeLegend superview ] superview ];
	NSView *exl = [[expenseLegend superview ] superview ];
	
	if(income) {
		[[incomeView animator] setHidden: NO ];
		[[inl animator] setHidden: NO ];
		[[incomeLabel animator ] setHidden: NO ];
	} else {
		[[incomeView animator] setHidden: YES ];
		[[inl animator] setHidden: YES ];
		[[incomeLabel animator ] setHidden: YES ];
	}
	
	if(expense) {
		[[expenseView animator] setHidden: NO ];
		[[exl animator] setHidden: NO ];
		[[expenseLabel animator ] setHidden: NO ];
	} else {
		[[expenseView animator] setHidden: YES ];
		[[exl animator] setHidden: YES ];
		[[expenseLabel animator ] setHidden: YES ];
	}
	
	// move expenses left
	if(expense && !income) {
		NSRect frame = [expenseView frame ];
		frame.origin.x = incomesX;
		[[expenseView animator] setFrame: frame ];
		frame = [expenseLabel frame ];
		frame.origin.x = incomesX+20;
		[[expenseLabel animator ] setFrame: frame ];
		frame = [exl frame ];
		frame.origin.x = incomesX+20;
		[[exl animator] setFrame: frame ];
	} else {
		NSRect frame = [expenseView frame ];
		frame.origin.x = expensesX;
		[[expenseView animator] setFrame: frame ];
		frame = [expenseLabel frame ];
		frame.origin.x = expensesX+20;
		[[expenseLabel animator ] setFrame: frame ];
		frame = [exl frame ];
		frame.origin.x = expensesX+20;
		[[exl animator] setFrame: frame ];
	}
}

-(void)setColors
{
	int n = [incomesCats count ];
	int i;
	double a = 0.05;
	NSSize s;
	NSRect r;
	
	s.width = 16; s.height = 16;
	r.origin.x = 0; 
	r.origin.y = 0;
	r.size = s;
	
	//if(n>0) a = 1.0 / n;
	for(i = 0; i < n; i++) {
		NSMutableDictionary	*pieData = [incomesCats objectAtIndex: i ];
		NSColor	*color = [NSColor colorWithDeviceHue: a*i saturation: 1.0 brightness: 1.0 alpha: 1.0 ];
		[pieData setObject: color forKey: @"color" ];
		
		NSImage	*img = [[NSImage alloc ] initWithSize: s ];
		[img lockFocus ];
		[color set ];
		NSBezierPath	*path = [NSBezierPath bezierPathWithOvalInRect:r ];
		[path fill ];
		[img setBackgroundColor: [color retain] ];
		[img unlockFocus ];
		[pieData setObject: img forKey: @"image" ];
	}
	
	n = [expensesCats count ];
	//if(n>0) a = 1.0 / n;
	for(i = 0; i < n; i++) {
		NSMutableDictionary	*pieData = [expensesCats objectAtIndex: i ];
		NSColor	*color = [NSColor colorWithDeviceHue: a*i saturation: 1.0 brightness: 1.0 alpha: 1.0 ];
		[pieData setObject: color forKey: @"color" ];

		NSImage	*img = [[NSImage alloc ] initWithSize: s ];
		[img lockFocus ];
		[color set ];
		NSBezierPath	*path = [NSBezierPath bezierPathWithOvalInRect:r ];
		[path fill ];
		[img setBackgroundColor: [color retain] ];
		[img unlockFocus ];
		[pieData setObject: img forKey: @"image" ];
	}
}

-(NSString*)autosaveNameForTimeSlicer: (TimeSliceManager*)tsm
{
	return @"CatRepTimeSlice";
}

-(void)timeSliceManager: (TimeSliceManager*)tsm changedIntervalFrom: (ShortDate*)from to: (ShortDate*)to
{
	[fromDate release ];
	[toDate release ];
	fromDate = [from retain ];
	toDate = [to retain ];
	[incomeLegend deselectAll: self ];
	[expenseLegend deselectAll: self ];
	[self updateValues ];
	[self updateViews ];
}


- (unsigned int)numberOfSlicesInPieChartView:(SMPieChartView*)inPieChartView
{
	if(inPieChartView == (SMPieChartView*)incomeView) return [incomesCats count ];
	return [expensesCats count ];
}

- (double)pieChartView:(SMPieChartView*)inPieChartView dataForSliceIndex:(unsigned int)inSliceIndex
{
	if(inPieChartView == (SMPieChartView*)incomeView) {
		return [[[incomesCats objectAtIndex: inSliceIndex ] objectForKey: @"value" ] doubleValue ];
	}
	return [[[expensesCats objectAtIndex: inSliceIndex ] objectForKey: @"value" ] doubleValue ];
}

- (NSString *)pieChartView:(SMPieChartView*)inPieChartView labelForSliceIndex:(unsigned int)inSliceIndex
{
	if(inPieChartView == (SMPieChartView*)incomeView) {
		return [[incomesCats objectAtIndex: inSliceIndex ] objectForKey: @"name" ];
	}
	return [[expensesCats objectAtIndex: inSliceIndex ] objectForKey: @"name" ];
	
}

- (NSDictionary *)pieChartView:(SMPieChartView*)inPieChartView attributesForSliceIndex:(unsigned int)inSliceIndex
{
	NSColor	*color;
	if(inPieChartView == (SMPieChartView*)incomeView) color = [[incomesCats objectAtIndex: inSliceIndex ] objectForKey: @"color" ];
	else color = [[expensesCats objectAtIndex: inSliceIndex ] objectForKey: @"color" ];
	return [NSDictionary dictionaryWithObjectsAndKeys: color, NSBackgroundColorAttributeName, nil  ];
}


-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	NSDictionary	*pieData;
	if([aTableView tag ] == 1) pieData = [incomesCats objectAtIndex: row ]; else pieData = [expensesCats objectAtIndex: row ];
	return [pieData objectForKey: [column identifier ] ];
}

-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if([aTableView tag ] == 1) return [incomesCats count ]; else return [expensesCats count ];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([[aNotification object ] tag ] == 1) {
		incomeExplosionIndex = [incomeLegend selectedRow ];
		[incomeView refreshDisplay: self ];
	} else {
		expenseExplosionIndex = [expenseLegend selectedRow ];
		[expenseView refreshDisplay: self ];
	}
}

- (NSRange)pieChartView:(SMPieChartView*)inPieChartView rangeOfExplodedPartIndex:(unsigned int)inIndex
{
	NSRange r;
	r.length = 1;
	if(inPieChartView == (SMPieChartView*)incomeView) r.location = incomeExplosionIndex; else r.location = expenseExplosionIndex;
	return r;
}

- (unsigned int)numberOfExplodedPartsInPieChartView:(SMPieChartView*)inPieChartView
{
	if(inPieChartView == (SMPieChartView*)incomeView && incomeExplosionIndex >= 0) return  1; 
	if(inPieChartView == (SMPieChartView*)expenseView && expenseExplosionIndex >= 0) return  1; 
	return 0;
}

-(void)pieChartView: (MCEMPieChartView*)view mouseOverSlice: (int)slice
{
	if(view == incomeView) {
		if(slice >= 0) [incomeLabel setStringValue: [[incomesCats objectAtIndex: slice ] objectForKey: @"name" ] ];
		else [incomeLabel setStringValue: @"" ];
	} else {
		if(slice >= 0) [expenseLabel setStringValue: [[expensesCats objectAtIndex: slice ] objectForKey: @"name" ] ];
		else [expenseLabel setStringValue: @"" ];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item 
{
    return [outlineView persistentObjectForItem: item ];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return [outlineView isExpandable: item ];
}

-(void)terminateController
{
	[categoryView saveLayout ];
}


-(void)mouseOverSlice: (int)n
{
	if(n>0) NSLog(@"Mouse over: %@\n", [[incomesCats objectAtIndex: n ] objectForKey: @"name" ]);
}

-(IBAction)balancingRuleChanged: (id)sender
{
	[self updateValues ];
	[self updateViews ];
}

-(void)dealloc
{
	[expensesCats release ];
	[incomesCats release ];
	[super dealloc ];
}

@end
