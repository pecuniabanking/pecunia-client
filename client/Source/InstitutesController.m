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
	self = [super initWithWindowNibName: @"Institutes"];
	selectedBank = nil;
	return self;
}

- (void)setBankData: (NSArray*)data
{
	banks = data;
}

- (NSDictionary*)selectedBank
{
	return selectedBank;
}

- (void)cancelSheet:(id)sender
{
	[self.window orderOut: sender];
	[NSApp endSheet: self.window returnCode: 1];
}

- (void)endSheet: (id)sender
{
	NSArray* selection = [bankController selectedObjects];
	if (selection == nil || [selection count] != 1) {
        return;
    }
	selectedBank = [selection objectAtIndex: 0];
	[self.window orderOut: sender];
	[NSApp endSheet: self.window returnCode: 0];
}

- (IBAction)doSearch: (id)sender
{
	NSTextField	*te = sender;
	NSString *searchName = [te stringValue];
	
	if ([searchName length] == 0) {
        [bankController setFilterPredicate: nil];
    }
	else {
		NSPredicate *pred = [NSPredicate predicateWithFormat: @"bankCode contains[c] %@ or bankLocation contains[c] %@ or bankName contains[c] %@",
							 searchName, searchName, searchName];
		if (pred) {
            [bankController setFilterPredicate: pred];
        }
	}
}


@end
