/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

/**
 * Enhancement of the coreplot time formatter, which allows to use other time units instead just seconds.
 */
@interface PecuniaPlotTimeFormatter : CPTTimeFormatter
{
    int calendarUnit;
}

- (id)initWithDateFormatter: (NSDateFormatter *)aDateFormatter calendarUnit: (int)unit;

@end

/**
 * The stocks time formatter is a bit different. It works with unix time stamps.
 */
@interface StocksPlotTimeFormatter : CPTTimeFormatter
{
}

- (id)initWithDateFormatter: (NSDateFormatter *)aDateFormatter calendarUnit: (int)unit;

@end
