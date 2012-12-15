/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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

#import "CategoryMaintenanceController.h"
#import "Category.h"
#import "MOAssistant.h"

#import "BWGradientBox.h"

@implementation CategoryMaintenanceController

- (id)initWithCategory: (Category*)aCategory
{
	self = [super initWithWindowNibName: @"CategoryMaintenance"];
    if (self != nil) {
        moc = MOAssistant.assistant.memContext;

        category = [NSEntityDescription insertNewObjectForEntityForName: @"Category" inManagedObjectContext: moc];

        changedCategory = aCategory;
        category.name = aCategory.name;
        category.currency = aCategory.currency;
        category.categoryColor = aCategory.categoryColor;
    }
	return self;
}

- (void)awakeFromNib
{
    // Manually set up properties which cannot be set via user defined runtime attributes (Color is not available pre XCode 4).
    topGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    topGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];
    backgroundGradient.fillColor = [NSColor whiteColor];
}

-(IBAction)cancel:(id)sender 
{
    [self close];
	[moc reset];
	[NSApp stopModalWithCode: 0];
}

-(IBAction)ok:(id)sender
{
	[categoryController commitEditing];
	NSManagedObjectContext *context = MOAssistant.assistant.context;
	
	// update common data
	changedCategory.name = category.name;
    changedCategory.categoryColor = category.categoryColor;
	
    [self close];

	// save all
	NSError *error = nil;
	if (![context save: &error]) {
		NSAlert *alert = [NSAlert alertWithError: error];
		[alert runModal];
	}

	[moc reset];
	[NSApp stopModalWithCode: 1];
}

@end
