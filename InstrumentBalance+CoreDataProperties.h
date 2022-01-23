//
//  InstrumentBalance+CoreDataProperties.h
//  Pecunia
//
//  Created by Frank Emminghaus on 25.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//
//

#import "InstrumentBalance+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface InstrumentBalance (CoreDataProperties)

+ (NSFetchRequest<InstrumentBalance *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDecimalNumber *balance;
@property (nullable, nonatomic, copy) NSString *qualifier;
@property (nullable, nonatomic, copy) NSNumber *isAvailable;
@property (nullable, nonatomic, copy) NSNumber *numberType;
@property (nullable, nonatomic, retain) Instrument *instrument;

@end

NS_ASSUME_NONNULL_END
