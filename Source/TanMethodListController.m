//
//  TanMethodListController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 04.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TanMethodListController.h"
#import "TanMethodOld.h"

@implementation TanMethodListController

@synthesize tanMethods;
@synthesize selectedMethod;

-(id)initWithMethods:(NSArray*)methods
{
	self = [super initWithWindowNibName: @"TanMethods" ];
	if(self == nil) return nil;
	
	self.tanMethods = methods;
	return self;
}

-(void)dealloc
{
	selectedMethod = nil;
	tanMethods = nil;

}

-(IBAction)ok:(id)sender
{
	NSArray *sel = [tanMethodController selectedObjects ];
	TanMethodOld *method = [sel objectAtIndex:0 ];
	self.selectedMethod = method.function;
	
	[NSApp stopModalWithCode:0 ];
	[[self window ] close ];
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	if(selectedMethod == nil) [NSApp stopModalWithCode:1];
}

-(void)windowDidLoad
{
	[tanMethodController setContent: tanMethods];
}


-(NSNumber*)selectedMethod
{
	return selectedMethod;
}


@end


