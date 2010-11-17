//
//  ImExporter.h
//  Pecunia
//
//  Created by Frank Emminghaus on 17.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImExporter : NSObject {
	NSString	*name;
	NSString	*description;
	NSString	*longDescription;
	NSArray		*profiles;
}

@property (nonatomic, retain) NSArray *profiles;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *longDescription;

@end


