//
//  TanMethodListController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 04.12.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TanMethodListController : NSWindowController {

	IBOutlet NSWindow				*tanMethodSheet;
	IBOutlet NSArrayController		*tanMethodController;

	NSArray							*tanMethods;
	NSString						*selectedMethod;

}

-(id)initWithMethods:(NSArray*)methods;

-(IBAction)ok:(id)sender;

-(NSString*)selectedMethod;

@end
