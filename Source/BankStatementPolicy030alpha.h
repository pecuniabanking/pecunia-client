//
//  BankStatementPolicy030alpha.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.02.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BankStatementPolicy030alpha : NSEntityMigrationPolicy {
}

- (BOOL)endRelationshipCreationForEntityMapping: (NSEntityMapping *)mapping
                                        manager: (NSMigrationManager *)manager
                                          error: (NSError **)error;

@end
