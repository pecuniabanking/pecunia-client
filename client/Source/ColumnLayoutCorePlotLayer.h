//
//  ColumnLayoutCorePlotLayer.h
//  Pecunia
//
//  Created by Mike on 17.11.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

@interface ColumnLayoutCorePlotLayer : CPTBorderedLayer {
  CGFloat spacing;

}

@property (nonatomic, readwrite) CGFloat spacing;

-(void)layoutSublayers;

@end
