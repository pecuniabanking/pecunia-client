/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#import "DockIconController.h"


@implementation DockIconController


-(DockIconController*)initWithManagedObjectContext: (NSManagedObjectContext *) objectContext
{
	[super init];
	managedObjectContext = objectContext;
	
	[[NSNotificationCenter defaultCenter]  addObserver:self
											  selector:@selector(managedObjectContextChanged:)
												  name:NSManagedObjectContextObjectsDidChangeNotification
												object:managedObjectContext];
	
	[self drawIconBadge];
	return self;
}

-(void)managedObjectContextChanged:(NSNotification *)notification
{
	NSDictionary *userInfoDictionary = [notification userInfo];
    NSSet *updatedObjects = [userInfoDictionary objectForKey:NSUpdatedObjectsKey];
	
	NSEnumerator *enumerator = [updatedObjects objectEnumerator];
	id value;
	
    BOOL bankStatementUpdated = FALSE;
	
	while ((value = [enumerator nextObject])) {
		if ([value isKindOfClass:[BankStatement class]]) {
			bankStatementUpdated = TRUE;
			break;
		}
	}
	
	if (bankStatementUpdated)
	{	
		[self drawIconBadge];
	}
	
	return;
}

-(NSInteger)numberUnread
{
	NSError *error = nil;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isNew = 1", self ];
	[request setPredicate:predicate];
	NSArray *statements = [managedObjectContext executeFetchRequest:request error:&error];
	return [statements count ];
}

-(void)drawIconBadge
{
	NSInteger newBadgeValue = [self numberUnread];
	
	if (badgeValue == newBadgeValue)
	{
		return;
	}
	else
	{
		badgeValue = newBadgeValue;
		if (newBadgeValue == 0) {
			[[[NSApplication sharedApplication] dockTile] setBadgeLabel:@""];
		}
		else {
			[[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%li", badgeValue]];
		}
		
		
	}
	return;
}

@end
