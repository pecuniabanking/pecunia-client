//
//  InstitutesController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 12.06.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "InstitutesController.h"


@implementation InstitutesController

-(id)init
{
	self = [super initWithWindowNibName:@"Institutes"];
	selectedBank = nil;
	return self;
}

-(void)setBankData: (NSArray*)data
{
	banks = data;
}

-(NSDictionary*)selectedBank
{
	return selectedBank;
}

-(void)setPosition: (NSPoint)xy
{
	origin = xy;
}

-(void)awakeFromNib
{
	[[self window ] setFrameTopLeftPoint: origin ];
}



-(void)windowWillClose:(NSNotification *)aNotification
{
	if(selectedBank == nil) [NSApp stopModalWithCode:1];
	else [NSApp stopModalWithCode:0];
}

-(IBAction)cancel: (id)sender
{
	[self close ];
}

-(IBAction)select:(id)sender
{
	NSArray *sel = [bankController selectedObjects ];
	if(sel == nil || [sel count ] != 1) return;
	selectedBank = [sel objectAtIndex:0 ];
	[self close ];
}

-(IBAction)doSearch: (id)sender
{
	NSTextField	*te = sender;
	NSString	*searchName = [te stringValue ];
	
	if([searchName length ] == 0) [bankController setFilterPredicate: nil ];
	else {
		NSPredicate *pred = [NSPredicate predicateWithFormat: @"bankCode contains[c] %@ or bankLocation contains[c] %@ or bankName contains[c] %@",
							 searchName, searchName, searchName ];
		if(pred) [bankController setFilterPredicate: pred ];
	}
}


@end
