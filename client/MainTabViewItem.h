/*
 *  MainTabViewItem.h
 *  Pecunia
 *
 *  Created by Frank Emminghaus on 16.11.10.
 *  Copyright 2010 Frank Emminghaus. All rights reserved.
 *
 */

@protocol MainTabViewItem

-(void)prepare;
-(void)terminate;
-(NSView*)mainView;

@end

