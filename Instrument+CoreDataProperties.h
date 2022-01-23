//
//  Instrument+CoreDataProperties.h
//  Pecunia
//
//  Created by Frank Emminghaus on 25.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//
//

#import "Instrument+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Instrument (CoreDataProperties)

+ (NSFetchRequest<Instrument *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *isin;
@property (nullable, nonatomic, copy) NSString *wkn;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSDecimalNumber *totalNumber;
@property (nullable, nonatomic, copy) NSDecimalNumber *currentPrice;
@property (nullable, nonatomic, copy) NSString *currentPriceCurrency;
@property (nullable, nonatomic, copy) NSDate *priceDate;
@property (nullable, nonatomic, copy) NSDecimalNumber *depotValue;
@property (nullable, nonatomic, copy) NSString *depotValueCurrency;
@property (nullable, nonatomic, copy) NSDecimalNumber *accruedInterestValue;
@property (nullable, nonatomic, copy) NSString *accruedInterestValueCurrency;
@property (nullable, nonatomic, copy) NSString *depotCurrency;
@property (nullable, nonatomic, copy) NSDecimalNumber *startPrice;
@property (nullable, nonatomic, copy) NSString *startPriceCurrency;
@property (nullable, nonatomic, copy) NSDecimalNumber *interestRate;
@property (nullable, nonatomic, copy) NSString *priceLocation;
@property (nullable, nonatomic, copy) NSNumber *totalNumberType;
@property (nullable, nonatomic, retain) NSSet<InstrumentBalance *> *balances;
@property (nullable, nonatomic, retain) DepotValueEntry *valueEntry;

@end

@interface Instrument (CoreDataGeneratedAccessors)

- (void)addBalancesObject:(InstrumentBalance *)value;
- (void)removeBalancesObject:(InstrumentBalance *)value;
- (void)addBalances:(NSSet<InstrumentBalance *> *)values;
- (void)removeBalances:(NSSet<InstrumentBalance *> *)values;

@end

NS_ASSUME_NONNULL_END
