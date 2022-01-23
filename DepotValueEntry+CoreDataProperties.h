//
//  DepotValueEntry+CoreDataProperties.h
//  Pecunia
//
//  Created by Frank Emminghaus on 25.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//
//

#import "DepotValueEntry+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DepotValueEntry (CoreDataProperties)

+ (NSFetchRequest<DepotValueEntry *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *day;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, copy) NSString *accountNumber;
@property (nullable, nonatomic, copy) NSString *bankCode;
@property (nullable, nonatomic, copy) NSDate *prepDate;
@property (nullable, nonatomic, copy) NSDecimalNumber *depotValue;
@property (nullable, nonatomic, copy) NSString *depotValueCurrency;
@property (nullable, nonatomic, retain) NSSet<Instrument *> *instruments;
@property (nullable, nonatomic, retain) BankAccount *account;

@end

@interface DepotValueEntry (CoreDataGeneratedAccessors)

- (void)addInstrumentsObject:(Instrument *)value;
- (void)removeInstrumentsObject:(Instrument *)value;
- (void)addInstruments:(NSSet<Instrument *> *)values;
- (void)removeInstruments:(NSSet<Instrument *> *)values;

@end

NS_ASSUME_NONNULL_END
