//
//  CategoryHistWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 30.10.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "CategoryHistWindowController.h"
#import <SM2DGraphView/SM2DGraphView.h>
#import "Category.h"
#import "MCEMOutlineViewLayout.h"
#import "ShortDate.h"
#import "CategoryReportingNode.h"
#import "MOAssistant.h"

/*
double sign(double x)
{
	if(x<0) return -1.0; else return 1.0;
}
*/
extern double sign(double x);

@implementation CategoryHistWindowController

@synthesize points;
@synthesize categoryHistory;
@synthesize dates;
@synthesize selectedDates;
@synthesize fromDate;
@synthesize toDate;

-(id)init
{
	self = [super init ];
	if (self == nil) return nil;
	
	managedObjectContext = [[MOAssistant assistant ] context ];
	maxValues.x = maxValues.y = 0.0;
	minValues.x = minValues.y = 0.0;
	histType = cat_histtype_month;
	self.points = [NSMutableArray arrayWithCapacity:20 ];
	self.dates = [NSMutableArray arrayWithCapacity:20];
	self.selectedDates = [NSMutableArray arrayWithCapacity:20];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults ];
	NSDictionary *values = [userDefaults objectForKey: @"catHistDefaults" ];
	if(values) {
		if ([values objectForKey: @"type" ]) {
			histType = (CatHistoryType)[[values objectForKey: @"type" ] intValue ];
		}
		if ([values objectForKey: @"fromDate" ]) {
			self.fromDate = [ShortDate dateWithDate: [values objectForKey: @"fromDate" ] ];
		}
		if ([values objectForKey: @"toDate" ]) {
			self.toDate = [ShortDate dateWithDate: [values objectForKey: @"toDate" ] ];
		}
	}
	
	if (self.fromDate == nil) {
		self.fromDate = [[ShortDate currentDate ] firstDayInYear ];
	}
	if (self.toDate == nil) {
		self.toDate = [[ShortDate currentDate ] firstDayInMonth ];
	}
	
	return self;
}

-(void)awakeFromNib
{
	NSError			*error;

	if([categoryController fetchWithRequest:nil merge:NO error:&error]); // [accountsView restoreAll ];
	[graphView setDrawsGrid: YES ];
	[self performSelector: @selector(restoreCategoryView) withObject: nil afterDelay: 0.0];
	
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"self" ascending:NO] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[catHistDatesController setSortDescriptors:sds ];
	
	if ([dates count ] > 0) [self adjustDates ];	
}	

-(void)prepare
{
}

-(NSView*)mainView
{
	return mainView;
}

-(void)restoreCategoryView
{
	[categoryView restoreAll ];
}

-(void)clearGraph
{
	[points removeAllObjects ];
	[graphView setNumberOfTickMarks: 0 forAxis: kSM2DGraph_Axis_Y ];
	[graphView setNumberOfTickMarks: 0 forAxis: kSM2DGraph_Axis_X ];
	[graphView refreshDisplay: self ];
}

-(Category*)currentSelection
{
	NSArray* sel = [categoryController selectedObjects ];
	if(sel == nil || [sel count ] != 1) return nil;
	return [sel objectAtIndex: 0 ];
}


-(void)adjustDates
{
	if ([dates count ] == 0) return;
	ShortDate *firstDate = [dates objectAtIndex:0 ];
	ShortDate *lastDate = [dates lastObject ];
	ShortDate *refFromDate;
	ShortDate *refToDate;
	
	switch (histType) {
		case cat_histtype_year:
			refFromDate = [self.fromDate firstDayInYear ];
			refToDate = [self.toDate firstDayInYear ];
			break;
		case cat_histtype_quarter:
			refFromDate = [self.fromDate firstDayInQuarter ];
			refToDate = [self.toDate firstDayInQuarter ];
			break;
		default:
			refFromDate = self.fromDate;
			refToDate = self.toDate;
			break;
	}
	
	if ([fromDate compare:firstDate ] == NSOrderedAscending || [fromDate compare:lastDate ] == NSOrderedDescending) {
		self.fromDate = firstDate;
		[fromButton selectItemAtIndex:[dates count ] - 1 ];
	} else {
		int idx = [dates count ] - 1;
		for(ShortDate *date in dates) {
			if ([date isEqual:refFromDate ]) {
				[fromButton selectItemAtIndex:idx ];
			} else idx--;
		}
	}
	
	if ([toDate compare: lastDate ] == NSOrderedDescending || [toDate compare:firstDate ] == NSOrderedAscending) {
		self.toDate = lastDate;
		[toButton selectItemAtIndex:0 ];
	} else {
		int idx = [dates count ] - 1;
		for(ShortDate *date in dates) {
			if ([date isEqual:refToDate ]) {
				[toButton selectItemAtIndex:idx ];
			} else idx--;
		}
	}
}

-(void)updateData
{
	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	
	self.categoryHistory = [[cat categoryHistoryWithType:histType ] values ];
	if(categoryHistory == nil) {
		[self clearGraph ];
		return;
	}
	
	NSArray *categoryKeys = [[categoryHistory allKeys ] sortedArrayUsingSelector: @selector(compare:) ];
	if([categoryKeys count ] == 0) { 
		categoryKeys = nil; 
		categoryHistory = nil;
		[self clearGraph ];
		return; 
	}
	
	// get all dates between first and last
	[dates removeAllObjects ];
	
	// get all selected dates
	if ([categoryKeys count ] > 0) {
		ShortDate *firstDate = [categoryKeys objectAtIndex:0 ];
		ShortDate *lastDate = [categoryKeys lastObject ];
		ShortDate *date = firstDate;
		while ([date compare: lastDate ] != NSOrderedDescending) {
			[dates addObject:date ];
			switch (histType) {
				case cat_histtype_year: date = [date dateByAddingYears:1 ]; break;
				case cat_histtype_quarter: date = [date dateByAddingMonths: 3 ]; break;
				default: date = [date dateByAddingMonths: 1 ]; break;
			}
		}
	}	
	
	[catHistDatesController setContent:dates ];
	[catHistDatesController rearrangeObjects ];
	
	[self adjustDates ];
	[self drawGraph ];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[self updateData ];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	Category *cat = [item representedObject ];
	if(cat == nil) return;
	if(![[tableColumn identifier ] isEqualToString: @"category" ]) return;

/*	
	NSMutableSet *children = [cat children ];
	if(children == nil || [children count ] == 0) {
		//display in gray color
		NSColor *txtColor = [NSColor grayColor];
		NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys: txtColor, NSForegroundColorAttributeName, nil];
		NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString: [cat localName ] attributes:txtDict] autorelease];
		[cell setAttributedStringValue:attrStr];
	}
*/	
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

-(void)drawGraph
{
	int i, j, ip, jp, tickCount, negCount = 0, posCount = 0;
	double a,b;
	NSPoint p;

	if ([dates count ] == 0) return;

	maxValues.x = maxValues.y = minValues.x = minValues.y = 0;
	
	[points removeAllObjects ];
	
	p.x = 0;

	[selectedDates removeAllObjects ];
	for(ShortDate *date in dates) {
		if ([date isBetween:fromDate and:toDate ]) {
			[selectedDates addObject:date ];
			if([categoryHistory objectForKey: date ] == nil) continue;
			else p.y = [[categoryHistory objectForKey: date ] doubleValue ];
			if (p.y < 0) negCount++; else posCount++;
		}
	}
	if (negCount > posCount ) invertValues = YES; else invertValues = NO;
	
/*	
	if ([selectedDates count ] == 1) {
		ShortDate *date = [selectedDates objectAtIndex:0 ];
		ShortDate *date1;
		ShortDate *date2;
		
		switch (histType) {
			case cat_histtype_year: 
				date1 = [date dateByAddingYears:-1 ]; 
				date2 = [date dateByAddingYears:1 ];
				break;
			case cat_histtype_quarter: 
				date1 = [date dateByAddingMonths: -3 ]; 
				date2 = [date dateByAddingMonths: 3 ];
				break;
			default: 
				date1 = [date dateByAddingMonths: -1 ]; 
				date2 = [date dateByAddingMonths: 1 ];
				break;
		}
		[selectedDates insertObject:date1 atIndex:0 ];
		[selectedDates addObject:date2 ];
	}
*/ 
	
	for(ShortDate *date in selectedDates) {
		if([categoryHistory objectForKey: date ] == nil) p.y = 0;
		else p.y = [[categoryHistory objectForKey: date ] doubleValue ];
		if (invertValues) p.y = p.y * -1.0;
		[points addObject: NSStringFromPoint(p) ];
		p.x += 1.0;
		
		if(minValues.y > p.y) minValues.y = p.y;
		if(maxValues.y < p.y) maxValues.y = p.y;
	}
	
	maxValues.x = [points count ] - 1;
	if (maxValues.x == 0) {
		maxValues.x = 1.0;
	}
	
	// normalize y-values
	i=j=0;
	ip = jp = 1;
	a = maxValues.y;
	b = minValues.y;
	if(b>0) b=0.0;
	if(a<0) a=0.0;
	
	while(abs(a) > 10.0) { i++; a/=10.0; ip*=10;	}
	while(abs(b) > 10.0) { j++; b/=10.0; jp*=10; 	}
	
	if(jp < ip) {
		if(b != 0) b = sign(b);
	} else if(jp > ip) {
		if(a != 0) a = sign(a);
		ip = jp;
	}
	
	if(a > 0 && a != (int)a) a=a+1;
	if(b < 0 && b != (int)b) b=b-1;
	
	maxValues.y = (int)a * ip;
	minValues.y = (int)b * ip;
	
	tickCount = (int)a - (int)b + 1;
	
	NSRect r = [graphView frame ];
	
	[graphView setNumberOfTickMarks: tickCount forAxis: kSM2DGraph_Axis_Y ];
	a = r.size.height/tickCount;
	if(a>50) [graphView setNumberOfMinorTickMarks:9 forAxis: kSM2DGraph_Axis_Y ];
	else [graphView setNumberOfMinorTickMarks:1 forAxis: kSM2DGraph_Axis_Y ];
	
	a = r.size.width / [points count ] ;
	
	[graphView setNumberOfTickMarks: [points count ] forAxis: kSM2DGraph_Axis_X ];
	[graphView setAxisInset:a/2 forAxis:kSM2DGraph_Axis_X ];
	[graphView refreshDisplay: self ];
}

-(IBAction) histTypeChanged: (id)sender
{
	NSSegmentedControl *sc = (NSSegmentedControl*)sender;
	int idx = [sc selectedSegment ];
	switch (idx) {
		case 0: histType = cat_histtype_year;
			[fromButton bind:@"contentValues" toObject:catHistDatesController withKeyPath:@"arrangedObjects.yearDescription" options: nil ];
			[toButton bind:@"contentValues" toObject:catHistDatesController withKeyPath:@"arrangedObjects.yearDescription" options: nil ];
			break;
		case 1: histType = cat_histtype_quarter; 
			[fromButton bind:@"contentValues" toObject:catHistDatesController withKeyPath:@"arrangedObjects.quarterYearDescription" options: nil ];
			[toButton bind:@"contentValues" toObject:catHistDatesController withKeyPath:@"arrangedObjects.quarterYearDescription" options: nil ];
			break;
		default: histType = cat_histtype_month; 
			[fromButton bind:@"contentValues" toObject:catHistDatesController withKeyPath:@"arrangedObjects.monthYearDescription" options: nil ];
			[toButton bind:@"contentValues" toObject:catHistDatesController withKeyPath:@"arrangedObjects.monthYearDescription" options: nil ];
			break;
	}
	[self updateData ];
}

-(IBAction)fromButtonPressed:(id)sender
{
	int idx_from = [fromButton indexOfSelectedItem ];
	int idx_to = [toButton indexOfSelectedItem ];
	if (idx_from < idx_to) {
		[fromButton selectItemAtIndex:idx_to ];
		[self drawGraph ];
		return;
	}
	if (idx_from >=0 ) {
		self.fromDate = [[catHistDatesController arrangedObjects ] objectAtIndex:idx_from ];
	}
	[self drawGraph ];
}

-(IBAction)toButtonPressed:(id)sender
{
	int idx_from = [fromButton indexOfSelectedItem ];
	int idx_to = [toButton indexOfSelectedItem ];
	if (idx_from < idx_to) {
		[toButton selectItemAtIndex:idx_from ];
		[self drawGraph ];
		return;
	}
	if (idx_to >=0 ) {
		self.toDate = [[catHistDatesController arrangedObjects ] objectAtIndex:idx_to ];
	}
	[self drawGraph ];
}


-(unsigned int)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView
{
	return 1;
}

-(NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(unsigned int)inLineIndex
{
	return points;
}

-(double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(unsigned int)inLineIndex
			   forAxis:(SM2DGraphAxisEnum)inAxis
{
	if(inAxis == kSM2DGraph_Axis_X) return maxValues.x; else return maxValues.y;
}

-(double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(unsigned int)inLineIndex
			   forAxis:(SM2DGraphAxisEnum)inAxis
{
	if(inAxis == kSM2DGraph_Axis_X) return minValues.x; else return minValues.y;
}

- (NSString *)twoDGraphView:(SM2DGraphView *)inGraphView labelForTickMarkIndex:(unsigned int)inTickMarkIndex
					forAxis:(SM2DGraphAxisEnum)inAxis defaultLabel:(NSString *)inDefault
{
	if(inAxis == kSM2DGraph_Axis_Y) return inDefault;
	
	if (inTickMarkIndex > [selectedDates count ] -1) {
		return inDefault;
	}
	ShortDate* date = [selectedDates objectAtIndex: inTickMarkIndex ];
	switch (histType) {
		case cat_histtype_year: return [date yearDescription ];
		case cat_histtype_quarter: return [date quarterYearDescription ];
		default: return [date monthYearDescription ];
	}
}

- (NSDictionary *)twoDGraphView:(SM2DGraphView *)inGraphView attributesForLineIndex:(unsigned int)inLineIndex
{
    NSDictionary	*result = nil;
	
	result = [ NSDictionary dictionaryWithObjectsAndKeys:
			  [ NSNumber numberWithBool:YES ], SM2DGraphBarStyleAttributeName,
			  //			  [ NSColor orangeColor ], NSForegroundColorAttributeName,
			  nil ];
	
    return result;
}

- (void)twoDGraphView:(SM2DGraphView *)inGraphView willDisplayBarIndex:(unsigned int)inBarIndex forLineIndex:(unsigned int)inLineIndex withAttributes:(NSMutableDictionary *)attr
{
	NSString* ps = [points objectAtIndex: inBarIndex ];
	if(ps == nil) return;
	NSPoint p = NSPointFromString(ps);
	if(p.y < 0 && invertValues == NO || p.y > 0 && invertValues == YES) [ attr setObject: [ NSColor redColor ] forKey:NSForegroundColorAttributeName ]; 
	else [ attr setObject: [ NSColor greenColor ] forKey:NSForegroundColorAttributeName ];
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item 
{
    return [outlineView persistentObjectForItem: item ];
}

-(void)terminate
{
	[categoryView saveLayout ];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults ];
	NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity:5 ];
	
	[values setObject:[NSNumber numberWithInt:histType ] forKey:@"type" ];
	[values setObject:[fromDate lowDate ] forKey:@"fromDate" ];
	[values setObject:[toDate highDate ] forKey:@"toDate" ];
	
	[userDefaults setObject:values forKey:@"catHistDefaults" ];
}

-(void)dealloc
{
	[fromDate release], fromDate = nil;
	[toDate release], toDate = nil;
	[points release], points = nil;
	[categoryHistory release], categoryHistory = nil;
	[dates release], dates = nil;
	[selectedDates release], selectedDates = nil;

	[super dealloc ];
}



@end




