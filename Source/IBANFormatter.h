//
//  IBANFormatter.h
//  Pecunia
//
//  Created by Frank Emminghaus on 13.03.24.
//  Copyright © 2024 Frank Emminghaus. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IBANFormatter : NSFormatter

+ (NSString *)formatIBAN:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
