//
//  CategoryView.h
//  Pecunia
//
//  Created by Frank Emminghaus on 27.05.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CategoryView : NSOutlineView {
	NSString	*saveCatName;
}

@property (copy) NSString *saveCatName;

@end
