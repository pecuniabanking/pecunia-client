//
//  TanMethodListController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 04.12.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "TanMethodListController.h"
#import "TanMethod.h"

@implementation TanMethodListController

-(id)initWithMethods:(NSArray*)methods
{
	self = [super initWithWindowNibName: @"TanMethods" ];
	if(self == nil) return nil;
	
	tanMethods = [methods retain ];
	selectedMethod = nil;
	return self;
}

-(void)dealloc
{
	[tanMethods release ];
	[super dealloc ];
}

-(IBAction)ok:(id)sender
{
	NSArray *sel = [tanMethodController selectedObjects ];
	TanMethod *method = [sel objectAtIndex:0 ];
	selectedMethod = method.function;
	
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


-(NSString*)selectedMethod
{
	return selectedMethod;
}


@end
