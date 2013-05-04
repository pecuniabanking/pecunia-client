//
//  PecuniaTabItem.h
//  Pecunia
//
//  Created by Frank Emminghaus on 31.08.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol PecuniaTabItem

@optional

- (void)prepare;
- (void)terminate;

@required

- (void)print;
- (NSView *)mainView;
- (void)activate;
- (void)deactivate;


@end
