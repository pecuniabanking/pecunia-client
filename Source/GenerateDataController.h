/**
 * Copyright (c) 2012, 2015, Pecunia Project. All rights reserved.
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

@interface GenerateDataController : NSWindowController
{
    NSCalendar *calendar;
}

@property (strong) IBOutlet NSButton            *removeOldDataCheckBox;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSTextField         *totalCountLabel;

@property (assign) NSUInteger startYear;
@property (assign) NSUInteger endYear;
@property (assign) NSUInteger bankCount;
@property (assign) NSUInteger maxAccountsPerBank;
@property (assign) NSUInteger numberOfStatementsPerBank;

@property NSString *dataTemplate;

- (IBAction)selectFile: (id)sender;
- (IBAction)close: (id)sender;
- (IBAction)start: (id)sender;

@end
