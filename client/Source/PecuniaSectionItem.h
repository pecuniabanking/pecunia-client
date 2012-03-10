/*
 *  PecuniaSectionItem.h
 *  Pecunia
 *
 *  Created by Frank Emminghaus on 16.11.10.
 *  Copyright 2010 Frank Emminghaus. All rights reserved.
 *
 */

@class Category;
@class ShortDate;

@protocol PecuniaSectionItem

@optional

- (void)prepare;
- (void)terminate;

@required

@property (nonatomic, retain) Category* category;

- (void)print;
- (NSView*)mainView;
- (void)activate;
- (void)deactivate;

- (void)setCategory: (Category*)category;
- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to;

@end

