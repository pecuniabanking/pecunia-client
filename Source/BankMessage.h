//
//  BankMessage.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.01.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BankMessage : NSManagedObject {
}

@property (nonatomic, strong) NSString *bankCode;
@property (nonatomic, strong) NSDate   *date;
@property (nonatomic, strong) NSString *message;

@end
