//
//  DepotValueEntry+CoreDataProperties.m
//  Pecunia
//
//  Created by Frank Emminghaus on 25.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//
//

#import "DepotValueEntry+CoreDataProperties.h"

@implementation DepotValueEntry (CoreDataProperties)

+ (NSFetchRequest<DepotValueEntry *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"DepotValueEntry"];
}

@dynamic day;
@dynamic date;
@dynamic accountNumber;
@dynamic bankCode;
@dynamic prepDate;
@dynamic depotValue;
@dynamic depotValueCurrency;
@dynamic instruments;
@dynamic account;

@end
