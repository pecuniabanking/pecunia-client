//
//  AccountNode.h
//  MacBanking
//
//  Created by Frank Emminghaus on 14.02.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ABAccount.h"

@interface AccountNode : NSObject {
	NSString* name;
	NSString* currency;
	double	  balance;
	

	NSMutableArray	*children;
	ABAccount			*accnt;
}

-(NSString*)name;
-(NSString*)currency;
-(double)balance;
-(double)updateBalance;
-(void)setName: (NSString*) x;
-(void)setCurrency: (NSString*) x;
-(void)setBalance: (double) b;
-(NSMutableArray *)children;
-(void)addChild: (AccountNode*) x;
-(void)setAccount: (ABAccount*) acc;
-(AccountNode*)childAtIndex: (int) i;
-(ABAccount*)account;
-(NSArray*)transactions;
-(NSArray*)leaves;
-(NSArray*)nodes;
-(AccountNode*)find: (NSString*)pname;
-(void)dealloc;
-(int)numberOfChildren;
-(BOOL)isEqual: (AccountNode*) an;
@end
