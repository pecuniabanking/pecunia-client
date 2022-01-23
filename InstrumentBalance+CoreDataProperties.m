//
//  InstrumentBalance+CoreDataProperties.m
//  Pecunia
//
//  Created by Frank Emminghaus on 25.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//
//

#import "InstrumentBalance+CoreDataProperties.h"

@implementation InstrumentBalance (CoreDataProperties)

+ (NSFetchRequest<InstrumentBalance *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"InstrumentBalance"];
}

@dynamic balance;
@dynamic qualifier;
@dynamic isAvailable;
@dynamic numberType;
@dynamic instrument;

@end
