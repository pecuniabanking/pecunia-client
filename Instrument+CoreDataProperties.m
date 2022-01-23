//
//  Instrument+CoreDataProperties.m
//  Pecunia
//
//  Created by Frank Emminghaus on 25.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//
//

#import "Instrument+CoreDataProperties.h"

@implementation Instrument (CoreDataProperties)

+ (NSFetchRequest<Instrument *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Instrument"];
}

@dynamic isin;
@dynamic wkn;
@dynamic name;
@dynamic totalNumber;
@dynamic currentPrice;
@dynamic currentPriceCurrency;
@dynamic priceDate;
@dynamic depotValue;
@dynamic depotValueCurrency;
@dynamic accruedInterestValue;
@dynamic accruedInterestValueCurrency;
@dynamic depotCurrency;
@dynamic startPrice;
@dynamic startPriceCurrency;
@dynamic interestRate;
@dynamic priceLocation;
@dynamic totalNumberType;
@dynamic balances;
@dynamic valueEntry;

@end
