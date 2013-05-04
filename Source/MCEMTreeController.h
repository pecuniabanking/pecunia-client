//
//  MCEMTreeController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 13.04.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MCEMTreeController : NSTreeController {
}

- (NSIndexPath *)indexPathForObject: (id)obj;
- (BOOL)setSelectedObject: (id)obj;
- (void)resort;

@end
