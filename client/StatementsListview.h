//
//  StatementsListview.h
//  Pecunia
//
//  Created by Mike on 01.10.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXListView.h"

@interface StatementsListView : PXListView <PXListViewDelegate>
{
  NSArray* _dataSource;
  NSArray* _valueArray;

  NSDateFormatter* _dateFormatter;
  NSNumberFormatter* _numberFormatter;
  NSCalendar* _calendar;
}

- (NSNumberFormatter*) numberFormatter;

- (NSArray*)dataSource;
- (void)setDataSource: (NSArray*)source;

- (NSArray*)valueArray;
- (void)setValueArray: (NSArray*)array;

- (void)updateSelectedCell;

@end
