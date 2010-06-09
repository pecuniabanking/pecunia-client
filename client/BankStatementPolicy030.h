//
//  BankStatementPolicy030.h
//  Pecunia
//
//  Created by Frank Emminghaus on 24.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BankStatementPolicy030 : NSEntityMigrationPolicy {

}

-(BOOL)createRelationshipsForDestinationInstance:(NSManagedObject *)dInstance 
								   entityMapping:(NSEntityMapping *)mapping 
										 manager:(NSMigrationManager *)manager 
										   error:(NSError **)error;

-(BOOL)endRelationshipCreationForEntityMapping:(NSEntityMapping *)mapping 
									   manager:(NSMigrationManager *)manager 
										 error:(NSError **)error;

-(NSString*)convertGVCode:(NSNumber*)n;

@end
