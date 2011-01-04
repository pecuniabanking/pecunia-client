//
//  TransferTemplate.h
//  Pecunia
//
//  Created by Frank Emminghaus on 26.09.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TransferTemplate : NSManagedObject {

}

-(NSString*)purpose;

@end

@interface TransferTemplate (CoreDataGeneratedAccessors)
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * purpose1;
@property (nonatomic, retain) NSString * purpose2;
@property (nonatomic, retain) NSString * purpose3;
@property (nonatomic, retain) NSString * purpose4;
@property (nonatomic, retain) NSString * remoteAccount;
@property (nonatomic, retain) NSString * remoteBankCode;
@property (nonatomic, retain) NSString * remoteBIC;
@property (nonatomic, retain) NSString * remoteCountry;
@property (nonatomic, retain) NSString * remoteIBAN;
@property (nonatomic, retain) NSString * remoteName;
@property (nonatomic, retain) NSDecimalNumber * value;
@property (nonatomic, retain) NSNumber * type;
@end
