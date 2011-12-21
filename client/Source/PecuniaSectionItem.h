/*
 *  PecuniaSectionItem.h
 *  Pecunia
 *
 *  Created by Frank Emminghaus on 16.11.10.
 *  Copyright 2010 Frank Emminghaus. All rights reserved.
 *
 */

@protocol PecuniaSectionItem

@optional

- (void)prepare;
- (void)terminate;

@required

- (void)print;
- (NSView*)mainView;
- (void)activate;
- (void)deactivate;

@end

