//
//  MCEMOutlineViewLayout.h
//  Pecunia
//
//  Created by Frank Emminghaus on 18.10.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSOutlineView (MCEMOutlineViewLayout) 

-(NSString*)persistentObjectForItem: (id)item;
-(void)restoreExpandedItems;	
-(void)saveLayout;
-(void)restoreLayout;
-(void)restoreAll;
@end
