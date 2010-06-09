//
//  MigrationManagerWorkaround.h
//  Pecunia
//
//  Created by Frank Emminghaus on 27.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMigrationManager (MigrationManagerWorkaround) 
	
+ (void)addRelationshipMigrationMethodIfMissing;
- (NSArray *)workaround_destinationInstancesForSourceRelationshipNamed:(NSString *)srcRelationshipName sourceInstances:(id)source;

@end
