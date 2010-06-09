//
//  Transaction.h
//  MacBanking
//
//  Created by Frank Emminghaus on 24.03.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <aqbanking/banking.h>

#define _LocalCountry @"lCountry"
#define _LocalBankCode @"lBankCode"
#define _LocalBranch @"lBranch"
#define _LocalAccount @"lAccount"
#define _LocalSuffix @"lSuffix"
#define _LocalName @"lName"

#define _RemoteCountry @"rCountry"
#define _RemoteBankCode @"rBankCode"
#define _RemoteBankName @"rBankName"
#define _RemoteBankLocation @"rBankLoc"
#define _RemoteBranch @"rBranch"
#define _RemoteAccount @"rAccount"
#define _RemoteSuffix @"rSuffix"
#define _RemoteIban @"rIban"
#define _RemoteNames @"rName"

#define _TransactionKey @"TransKey"
#define _CustomerReference @"CustomerRef"
#define _BankReference @"BankRef"
#define _TransactionText @"TransText"
#define _PrimaNota @"PrimaNota"
#define _Purpose @"Purpose"
#define _Category @"Category"
#define _Currency @"Curr"
#define _Date @"Date"
#define _ValutaDate @"ValDate"
#define _Value @"Value"
#define _TextKey @"TextKey"
#define _TransactionCode @"TransCode"

#define _Infos @"Infos"

@interface Transaction : NSObject <NSCoding> {
	NSMutableDictionary*	Infos;
	NSString*				Purpose;
}

-(id)initWithAB: (const AB_TRANSACTION*) trans;
-(NSMutableArray*)stringsFromAB: (const GWEN_STRINGLIST*)sl;
-(void)dealloc;
-(void)encodeWithCoder: (NSCoder*)coder;
-(id)initWithCoder: (NSCoder*)coder;
-(NSString*)Purpose;
-(BOOL)equalDate: (Transaction*)transaction;
-(NSComparisonResult)compareByDate: (Transaction*)transaction;
-(NSString*)remoteName;
-(NSString*)fullPurpose;
-(NSDictionary*)infos;
-(NSDate*)date;

@end
