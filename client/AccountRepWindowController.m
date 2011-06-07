//
//  AccountRepWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "AccountRepWindowController.h"
#import <SM2DGraphView/SM2DGraphView.h>
#import "Category.h"
#import "MCEMOutlineViewLayout.h"
#import "ShortDate.h"
#import "TimeSliceManager.h"
#import "MOAssistant.h"
#import "ImageAndTextCell.h"
#import "BankAccount.h"

double sign(double x)
{
	if(x<0) return -1.0; else return 1.0;
}

@implementation AccountRepWindowController

@synthesize firstDate;
@synthesize fromDate;
@synthesize toDate;

-(id)init
{
	self = [super init ];
	if(self == nil) return nil;
	
	managedObjectContext = [[MOAssistant assistant ] context ];
	return self;
}

-(void)awakeFromNib
{
	NSError			*error;
	
	maxValues.x = maxValues.y = 0.0;
	minValues.x = minValues.y = 0.0;
	points = [[NSMutableArray alloc ] init ];
	if([accountsController fetchWithRequest:nil merge:NO error:&error]); // [accountsView restoreAll ];
	[graphView setDrawsGrid: YES ];
	
	// sort descriptor for accounts view
	NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	NSArray	*sds = [NSArray arrayWithObject:sd];
	[accountsController setSortDescriptors: sds ];
	
	
	[self performSelector: @selector(restoreAccountsView) withObject: nil afterDelay: 0.0];
}	

-(void)prepare
{
}

-(void)print
{
	NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo ];
	[printInfo setTopMargin:45 ];
	[printInfo setBottomMargin:45 ];
	[printInfo setHorizontalPagination:NSFitPagination ];
	[printInfo setVerticalPagination:NSFitPagination ];
	NSPrintOperation *printOp;
	printOp = [NSPrintOperation printOperationWithView:printView printInfo: printInfo ];
	[printOp setShowsPrintPanel:YES ];
	[printOp runOperation ];
}

-(NSView*)mainView
{
	return mainView;
}

// workaround for strange outlineView collapsing...
-(void)restoreAccountsView
{
	[accountsView restoreAll ];
}

-(void)clearGraph
{
	[points removeAllObjects ];
	[graphView setNumberOfTickMarks: 0 forAxis: kSM2DGraph_Axis_Y ];
	[graphView setNumberOfTickMarks: 0 forAxis: kSM2DGraph_Axis_X ];
	[graphView refreshDisplay: self ];
	[self setValue: @"0" forKey: @"sexpense" ];
	[self setValue: @"0" forKey: @"sincome" ];
	[self setValue: @"0" forKey: @"sbalance" ];
	[self setValue: [NSColor colorWithCalibratedRed:0.0 green:0.78 blue:0.0 alpha:1.0 ] forKey: @"balanceColor" ];
}

-(Category*)currentSelection
{
	NSArray* sel = [accountsController selectedObjects ];
	if(sel == nil || [sel count ] != 1) return nil;
	return [sel objectAtIndex: 0 ];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[balanceHistory release ];
	balanceHistory = nil;
	[balanceKeys release ];
	balanceKeys = nil;
	
	Category *cat = [self currentSelection ];
	if(cat == nil) return;
	
	balanceHistory = [cat balanceHistory ];
	if(balanceHistory == nil) {
		[self clearGraph ];
		return;
	}
	balanceKeys = [[balanceHistory allKeys ] sortedArrayUsingSelector: @selector(compare:) ];
	if([balanceKeys count ] == 0) { 
		balanceKeys = nil; 
		balanceHistory = nil;
		[self clearGraph ];
		return; 
	}
	
	[balanceHistory retain ];
	[balanceKeys retain ];
	
	//set Date restrictions
	[tsManager setMinDate: [balanceKeys objectAtIndex:0 ] ];
	[tsManager setMaxDate: [ShortDate dateWithDate: [NSDate date ] ] ];

	[self drawGraph ];
	[self updateValues ];
}
/*
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	Category *cat = [item representedObject ];
	if(cat == nil) return;
	if([[tableColumn identifier ] isEqualToString: @"account" ]) {
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
	if([[tableColumn identifier ] isEqualToString: @"balance" ]) {
		if([cell isHighlighted ]){
			[(NSTextFieldCell*)cell setTextColor: [NSColor whiteColor ] ];
		} else {
			if([[cat catSum ] doubleValue ] >= 0) [(NSTextFieldCell*)cell setTextColor: [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100]];
			else [(NSTextFieldCell*)cell setTextColor: [NSColor redColor ] ];
		} 
	}
}
*/


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(ImageAndTextCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	Category *cat = [item representedObject ];
	if(cat == nil) return;
	
//	NSImage *catImage		= [NSImage imageNamed:@"catdef4_18.png"];
	NSImage *moneyImage		= [NSImage imageNamed:@"money_18.png"];
	NSImage *moneySyncImage	= [NSImage imageNamed:@"money_sync_18.png"];
	NSImage *folderImage	= [NSImage imageNamed:@"folder_18.png"];
		
	if([cat isBankAccount] && cat.accountNumber == nil) 	[cell setImage: folderImage];
	if([cat isBankAccount] && cat.accountNumber != nil) {
		BankAccount *account = (BankAccount*)cat;
		if([account.isManual boolValue ] == YES || [account.noAutomaticQuery boolValue ] == YES) [cell setImage: moneyImage];
		else [cell setImage: moneySyncImage];
	}
	
	BOOL itemIsSelected = FALSE;
	if ([outlineView itemAtRow:[outlineView selectedRow]] == item)	 itemIsSelected = TRUE;
	
	BOOL itemIsRoot = [cat isRoot];
	if (itemIsRoot == TRUE) {
		[cell setImage:Nil];
	}
	
	[cell setValues:[cat catSum] currency:cat.currency unread:0 selected:itemIsSelected root:itemIsRoot ];
}


-(void)updateValues
{
	Category *cat = [self currentSelection ];

	NSDecimalNumber	*expenses = [cat valuesOfType: cat_expenses from: self.fromDate to: self.toDate ];
	NSDecimalNumber *incomes = [cat valuesOfType: cat_incomes from: self.fromDate to: self.toDate ];
	NSDecimalNumber *balance = [incomes decimalNumberByAdding: expenses ];
	
	NSDecimalNumber *zero = [NSDecimalNumber zero ];
//	[balanceColor release ];
	if([balance compare: zero ] == NSOrderedAscending) [self setValue: [NSColor redColor ] forKey: @"balanceColor" ]; 
	else [self setValue: [NSColor colorWithCalibratedRed:0.0 green:0.78 blue:0.0 alpha:1.0 ] forKey: @"balanceColor" ];

	[self setValue: expenses forKey: @"sexpense" ];
	[self setValue: incomes forKey: @"sincome" ];
	[self setValue: balance forKey: @"sbalance" ];
}
	
-(void)drawGraph
{
	int i, j, ip, jp, tickCount, days = 0;
	double a,b, lastValue = 0.0;
	NSPoint p;
	ShortDate	*date = nil;
	
	maxValues.x = maxValues.y = minValues.x = minValues.y = 0;
	
	[points removeAllObjects ];

	self.firstDate = nil;

    NSMutableArray* dates = [[NSMutableArray alloc] init];
	for(i=0; i<[balanceKeys count ]; i++) {
		ShortDate* date = [balanceKeys objectAtIndex: i ];
		if([date compare: self.fromDate ] == NSOrderedAscending) {
			lastValue = [[balanceHistory objectForKey: date ] doubleValue ];
			continue;
		}
		if([date compare: self.toDate ] == NSOrderedDescending) continue;
		[dates addObject: date ];
	}
	if([dates count ] == 0) {
		[dates addObject: self.fromDate ];
		[dates addObject: self.toDate ];
	}
	
  	date = [dates objectAtIndex: 0 ];
	if([self.fromDate compare: date ] == NSOrderedAscending) {
		[dates insertObject: self.fromDate atIndex: 0 ];
	}
	
  	date = [dates objectAtIndex: [dates count ]-1 ];
	if([date compare: self.toDate ] == NSOrderedAscending) {
		[dates addObject: self.toDate ];
	}
	
	for(i=0; i<[dates count ]; i++) {
		date = [dates objectAtIndex: i ];
		
		if([balanceHistory objectForKey: date ] == nil) p.y = lastValue;
		else p.y = [[balanceHistory objectForKey: date ] doubleValue ];

		if(firstDate == nil) {
			self.firstDate = date;
		} else {
			days = [self.firstDate daysToDate: date ];
		}
		p.x = (double)days;
		
		[points addObject: NSStringFromPoint(p) ];
		
		if(minValues.y > p.y) minValues.y = p.y;
		if(maxValues.y < p.y) maxValues.y = p.y;
		lastValue = p.y;
	}
	
	
	if(days == 0) days = 1;
	
	maxValues.x = (double)days;
	
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
	
	a = r.size.width / 70;
	if(a < 1) a = 1;
	if(a>days) a = days;
 
	xTickCountFactor = maxValues.x/(int)a;
	
	[graphView setNumberOfTickMarks: (int)a+1 forAxis: kSM2DGraph_Axis_X ];
	[graphView refreshDisplay: self ];
}

-(IBAction) setGraphStyle: (id)sender
{
	drawAsBars = NO;
	[graphView reloadAttributesForLineIndex:0 ];
}

-(IBAction) setBarStyle: (id)sender
{
	drawAsBars = YES;
	[graphView reloadAttributesForLineIndex:0 ];
}

-(NSString*)autosaveNameForTimeSlicer: (TimeSliceManager*)tsm
{
	return @"AccRepTimeSlice";
}

-(void)timeSliceManager: (TimeSliceManager*)tsm changedIntervalFrom: (ShortDate*)from to: (ShortDate*)to
{
	self.fromDate = from;
	self.toDate = to;
	[self updateValues ];
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
	double a;
	
	if(inAxis == kSM2DGraph_Axis_Y) return inDefault;
	
	a = inTickMarkIndex * xTickCountFactor;
	ShortDate* date = [self.firstDate dateByAddingDays: (int)a ];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease ];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		
	return [dateFormatter stringFromDate: [date lowDate] ];
}

- (NSDictionary *)twoDGraphView:(SM2DGraphView *)inGraphView attributesForLineIndex:(unsigned int)inLineIndex
{
    NSDictionary	*result = nil;
	
	if(drawAsBars == YES)
    result = [ NSDictionary dictionaryWithObjectsAndKeys:
			  [ NSNumber numberWithBool:YES ], SM2DGraphBarStyleAttributeName,
//			  [ NSColor orangeColor ], NSForegroundColorAttributeName,
			  nil ];
	else result = [NSDictionary dictionary ];
	
    return result;
}

- (void)twoDGraphView:(SM2DGraphView *)inGraphView willDisplayBarIndex:(unsigned int)inBarIndex forLineIndex:(unsigned int)inLineIndex withAttributes:(NSMutableDictionary *)attr
{
	NSString* ps = [points objectAtIndex: inBarIndex ];
	if(ps == nil) return;
	NSPoint p = NSPointFromString(ps);
	if(p.y < 0) [ attr setObject: [ NSColor redColor ] forKey:NSForegroundColorAttributeName ]; 
	else [ attr setObject: [ NSColor greenColor ] forKey:NSForegroundColorAttributeName ];
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item 
{
    return [outlineView persistentObjectForItem: item ];
}

-(void)terminate
{
	[accountsView saveLayout ];
}

-(void)dealloc
{
	[points release ];
	[firstDate release], firstDate = nil;
	[fromDate release], fromDate = nil;
	[toDate release], toDate = nil;

	[super dealloc ];
}

	
	
@end

