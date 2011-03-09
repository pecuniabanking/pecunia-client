//
//  BankStatementPolicy030alpha.m
//  Pecunia
//
//  Created by Frank Emminghaus on 05.02.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "BankStatementPolicy030alpha.h"


@implementation BankStatementPolicy030alpha

-(BOOL)endRelationshipCreationForEntityMapping:(NSEntityMapping *)mapping 
									   manager:(NSMigrationManager *)manager 
										 error:(NSError **)error
{
	NSManagedObjectContext *context = [manager destinationContext ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSArray *statements = [context executeFetchRequest:request error:error];
    
	for (NSManagedObject *statement in statements) {
		// calculate not assigned value
		NSMutableSet* stats = [statement mutableSetValueForKey: @"assignments" ];
		NSEnumerator *iter = [stats objectEnumerator];
		NSManagedObject *stat;
		while (stat = [iter nextObject]) {
			NSManagedObject *cat = [stat valueForKey: @"category" ];
			if ([[cat valueForKey:@"isBankAcc" ] boolValue] == NO && ![[cat valueForKey:@"name" ] isEqualToString: @"++nassroot" ]) {
				[statement setValue:[NSDecimalNumber zero] forKey: @"nassValue" ];
				break;
			}
		}
	}
	return YES;
}

@end
