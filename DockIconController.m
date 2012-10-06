//
//  DockIconController.m
//  Pecunia
//
//  Created by Eike Wolgast on 04.06.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

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
			[[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%d", badgeValue]];
		}
		
		
	}
	return;
}

@end
