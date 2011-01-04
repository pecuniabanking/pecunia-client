//
//  BankStatementPolicy030.m
//  Pecunia
//
//  Created by Frank Emminghaus on 24.03.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "BankStatementPolicy030.h"


@implementation BankStatementPolicy030

-(BOOL)createRelationshipsForDestinationInstance:(NSManagedObject*)dInstance 
								   entityMapping:(NSEntityMapping*)mapping 
										 manager:(NSMigrationManager*)manager 
										   error:(NSError**)error
{
	// get source object
	NSArray *sources = [manager sourceInstancesForEntityMappingNamed:[mapping name] destinationInstances:[NSArray arrayWithObject:dInstance ] ];
	NSManagedObject *source = [sources objectAtIndex:0 ];
	NSSet *cats = [ source mutableSetValueForKey:@"categories" ];
	NSManagedObject *cat;
	if ([cats count ] == 0) {
		NSManagedObjectContext *context = [manager destinationContext ];
		[context deleteObject:dInstance ];
		return YES;
	}
	for(cat in cats) {
		NSManagedObject *target;
		if([[cat valueForKey: @"isBankAcc" ] boolValue ]) {
			NSArray *targets = [manager destinationInstancesForEntityMappingNamed: @"BankAccountToBankAccount" sourceInstances:[NSArray arrayWithObject:cat ] ];
			target = [targets objectAtIndex:0 ];
			// maintain account relationship
			[dInstance setValue:target forKey: @"account" ];
		} else {
			NSArray *targets = [manager destinationInstancesForEntityMappingNamed: @"CategoryToCategory" sourceInstances:[NSArray arrayWithObject:cat ] ];
			target = [targets objectAtIndex:0 ];
			NSString *catName = [cat valueForKey:@"name" ];
			if ([catName isEqualToString:@"++nassroot" ] == NO) [dInstance setValue:[NSNumber numberWithBool:YES ] forKey:@"isAssigned" ];
		}
		// category assignments
		NSManagedObjectContext *targetContext = [manager destinationContext ];
		
		// create StatCatAssignment
		NSManagedObject *stat = [NSEntityDescription insertNewObjectForEntityForName: @"StatCatAssignment" inManagedObjectContext:targetContext ];
		[stat setValue: target forKey: @"category" ];
		[stat setValue: dInstance forKey: @"statement" ];
		[stat setValue: [dInstance valueForKey: @"value" ] forKey: @"value" ];
	}
	return YES;
}

// calculate saldo field
-(BOOL)endRelationshipCreationForEntityMapping:(NSEntityMapping *)mapping 
									   manager:(NSMigrationManager *)manager 
										 error:(NSError **)error
{
	NSManagedObjectContext *context = [manager destinationContext ];
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isBankAcc == 1 and accountNumber != nil" ];
	[request setPredicate:predicate];
	NSArray *accounts = [context executeFetchRequest:request error:error];

	NSManagedObject *account;
	for(account in accounts) {
		NSSet *stats = [account mutableSetValueForKey: @"statements" ];
		if ([stats count ] == 0) {
			continue;
		}
		NSSortDescriptor *sd = [[[NSSortDescriptor alloc ] initWithKey: @"date" ascending: NO ] autorelease ];
		NSArray *statarray = [stats allObjects ];
		NSArray *statements = [statarray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sd ] ];
		NSDecimalNumber *saldo = [account valueForKey: @"balance" ];
		NSManagedObject *stat;
		NSDate *date = nil;
		for(stat in statements) {
			[stat setValue:saldo forKey: @"saldo" ];
			saldo = [saldo decimalNumberBySubtracting:[stat valueForKey: @"value" ] ];
		}
		int i;
		NSTimeInterval j=1;
		for(i = [statements count ]-1; i--; i>=0) {
			stat = [statements objectAtIndex:i ];
			if (date == nil) date = [stat valueForKey: @"date" ];
			else {
				if ([date isEqualToDate:[stat valueForKey: @"date" ] ]) {
					[stat setValue:[[NSDate alloc ] initWithTimeInterval:j++ sinceDate: date ] forKey: @"date" ];
				} else {
					date = [stat valueForKey: @"date" ];
					j=1;
				}
			}
		}
		if ([statements count ] > 0) {
			stat = [statements objectAtIndex:0 ];
			[account setValue: [stat valueForKey:@"date" ] forKey:@"latestTransferDate" ];
		}
	}
	return YES;
}

-(NSString*)convertGVCode:(NSNumber*)n
{
	NSString *res = [NSString stringWithFormat:@"%0.3d", [n intValue ] ];
	return res;
}

-(NSString*)trimString:(NSString*)s
{
	return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet ] ];
}


@end
