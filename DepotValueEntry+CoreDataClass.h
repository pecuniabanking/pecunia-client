//
//  DepotValueEntry+CoreDataClass.h
//  Pecunia
//
//  Created by Frank Emminghaus on 25.05.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BankAccount, Instrument;

NS_ASSUME_NONNULL_BEGIN

@interface DepotValueEntry : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "DepotValueEntry+CoreDataProperties.h"
