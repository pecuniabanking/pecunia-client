//
//  BankStatement.h
//  MacBanking
//
//  Created by Frank Emminghaus on 30.06.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankAccount;
@class ClassificationContext;
@class Category;
@class StatCatAssignment;

@interface BankStatement : NSManagedObject {
	
//	BankAccount *account;
	BOOL		isNew;
}

-(BOOL)matches: (BankStatement*)stat;

-(NSObject*)classify;
-(NSString*)stringForFields: (NSArray*)fields usingDateFormatter: (NSDateFormatter*)dateFormatter;
-(NSComparisonResult)compareValuta: (BankStatement*)stat;

-(void)assignToCategory:(Category*)cat;
-(void)assignAmount: (NSDecimalNumber*)value toCategory:(Category*)cat;
-(void)updateAssigned;
-(BOOL)hasAssignment;
-(NSDecimalNumber*)residualAmount;
-(StatCatAssignment*)bankAssignment;

-(void)removeFromCategory:(Category*)cat;
-(void)moveFromCategory:(Category*)scat toCategory:(Category*)tcat;
-(void)addToAccount: (BankAccount*)account;

-(NSString*)floatingPurpose;

+(void)setClassificationContext: (ClassificationContext*)cc;
+(void)initCategoriesCache;

@property (nonatomic, retain) NSDate *valutaDate;
@property (nonatomic, retain) NSDate *date;

@property (nonatomic, retain) NSDecimalNumber *value;
@property (nonatomic, retain) NSDecimalNumber *charge;
@property (nonatomic, retain) NSDecimalNumber *saldo;


@property (nonatomic, retain) NSString *remoteName;
@property (nonatomic, retain) NSString *remoteIBAN;
@property (nonatomic, retain) NSString *remoteBIC;
@property (nonatomic, retain) NSString *remoteBankCode;
@property (nonatomic, retain) NSString *remoteBankLocation;
@property (nonatomic, retain) NSString *remoteBankName;
@property (nonatomic, retain) NSString *remoteAccount;
@property (nonatomic, retain) NSString *remoteCountry;
@property (nonatomic, retain) NSString *purpose;

@property (assign) BOOL isNew;

@property (nonatomic, retain, readonly) NSString * categoriesDescription;

@property (nonatomic, retain) NSString *localBankCode, *localAccount;
@property (nonatomic, retain) NSString *customerReference;
@property (nonatomic, retain) NSString *bankReference;
@property (nonatomic, retain) NSString *transactionText;
@property (nonatomic, retain) NSNumber *transactionCode;
@property (nonatomic, retain) NSString *currency;
@property (nonatomic, retain) NSString *primaNota;

@property (nonatomic, retain) NSString *additional;
@property (nonatomic, retain) NSNumber *hashNumber;
@property (nonatomic, retain) NSNumber *isAssigned;		// assigned to >= 100%
@property (nonatomic, retain) NSNumber * isManual;
@property (nonatomic, retain) NSNumber * isStorno;

@property (nonatomic, retain) BankAccount *account;

@end

// coalesce these into one @interface BankStatement (CoreDataGeneratedAccessors) section
@interface BankStatement (CoreDataGeneratedAccessors)
@end
