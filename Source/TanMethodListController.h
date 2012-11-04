//
//  TanMethodListController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 04.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TanMethodListController : NSWindowController {

	IBOutlet NSWindow				*tanMethodSheet;
	IBOutlet NSArrayController		*tanMethodController;

	NSArray							*tanMethods;
	NSNumber						*selectedMethod;

}

@property (nonatomic, copy) NSArray *tanMethods;
@property (nonatomic, strong) NSNumber *selectedMethod;


-(id)initWithMethods:(NSArray*)methods;

-(IBAction)ok:(id)sender;

-(NSNumber*)selectedMethod;

@end


