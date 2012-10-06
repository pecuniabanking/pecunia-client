//
//  ImExporterProfile.h
//  Pecunia
//
//  Created by Frank Emminghaus on 20.08.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#ifdef AQBANKING
#import <Cocoa/Cocoa.h>


@interface ImExporterProfile : NSObject {
	NSString	*name;
	NSString	*shortDescription;
	NSString	*longDescription;

}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *shortDescription;
@property (nonatomic, copy) NSString *longDescription;

@end

#endif