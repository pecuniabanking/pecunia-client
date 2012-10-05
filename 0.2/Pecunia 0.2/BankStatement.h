//
//  BankStatement.h
//  MacBanking
//
//  Created by Frank Emminghaus on 30.06.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <aqbanking/banking.h>

@class BankAccount;
@class ClassificationContext;
@class Category;

@interface BankStatement : NSManagedObject {
	
//	BankAccount *account;
	BOOL		isNew;
}

-(void)updateWithAB: (const AB_TRANSACTION*)t;
-(NSString*)stringsFromAB: (const GWEN_STRINGLIST*)sl;

-(BOOL)matches: (BankStatement*)stat;

-(NSObject*)classify;
-(NSString*)stringForFields: (NSArray*)fields usingDateFormatter: (NSDateFormatter*)dateFormatter;
-(NSComparisonResult)compareValuta: (BankStatement*)stat;

-(BOOL)isAssigned;
-(void)assignToCategory:(Category*)cat;
-(void)removeFromCategory:(Category*)cat;
-(void)moveFromCategory:(Category*)scat toCategory:(Category*)tcat;
-(void)verifyAssignment;
-(void)addToAccount: (BankAccount*)account;

+(void)setClassificationContext: (ClassificationContext*)cc;
+(void)initCategoriesCache;

@property (nonatomic, retain) NSDate * valutaDate;
@property (nonatomic, retain) NSDecimalNumber * value;
@property (nonatomic, retain) NSString * remoteName;
@property (nonatomic, retain) NSString * remoteIBAN;
@property (nonatomic, retain) NSString * remoteBIC;
@property (nonatomic, retain) NSString * remoteBankCode;
@property (nonatomic, retain) NSString * remoteAccount;
@property (nonatomic, retain) NSString * purpose;

@property (assign) BOOL isNew;
@property (nonatomic, retain, readonly) NSString * categoriesDescription;

@property (nonatomic, retain) NSString * localCountry, *localBankCode, *localBranch, *localAccount, *localSuffix, *localName, *localIBAN, *localBIC;
@property (nonatomic, retain) NSString * remoteCountry, *remoteBankName, *remoteBankLocation, *remoteBranch, *remoteSuffix;
@property (nonatomic, retain) NSString * transactionKey;
@property (nonatomic, retain) NSString * customerReference;
@property (nonatomic, retain) NSString * bankReference;
@property (nonatomic, retain) NSString * transactionText;
@property (nonatomic, retain) NSString * primaNota;
@property (nonatomic, retain) NSNumber * textKey;
@property (nonatomic, retain) NSNumber * transactionCode;
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSString * date;








@end
