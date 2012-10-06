//
//  PecuniaPlotTimeFormatter.h
//  Pecunia
//
//  Created by Mike Lischke on 25.11.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

/**
 * Enhancement of the coreplot time formatter, which allows to use days instead of seconds.
 */
@interface PecuniaPlotTimeFormatter : CPTTimeFormatter {
    int calendarUnit;
}

- (id)initWithDateFormatter: (NSDateFormatter*)aDateFormatter calendarUnit: (int)unit;

@end
