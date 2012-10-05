//
//  AccountNode.m
//  MacBanking
//
//  Created by Frank Emminghaus on 14.02.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AccountNode.h"
#import "ABController.h"

@implementation AccountNode

-(id)init
{
	[super init ];
	children = nil;
	balance = 0.0f;
	name = @"";
	currency = @"";
	accnt = nil;
	return self;
}

-(NSString*)name
{
	return name;
}

-(NSString*)currency
{
	return currency;
}

-(double)balance
{
	return balance;
}

-(void)setName: (NSString*) x
{
	x = [x copy];
	[name release];
	name=x;
}

-(void)setCurrency: (NSString*) x
{
	[currency release];
	currency = [x copy ];
}

-(void)setBalance: (double) b
{
	balance = b;
}

-(NSMutableArray *)children
{
	return children;
}

-(void)addChild: (AccountNode*) x
{
	if(!children) children = [[NSMutableArray arrayWithCapacity: 5] retain];
	[children addObject: x];
}

-(void)setAccount: (ABAccount*)acc
{
	if(accnt) [accnt release];
	accnt = [acc retain];
}

-(ABAccount*)account
{
	return accnt;
}

-(BOOL)isEqual: (AccountNode*) an
{
	return [name isEqual: an->name ];
}

-(double)updateBalance
{
	int			i;
	double      bal;
	AccountNode	*node;
	NSString	*curr = nil;
	
	if(children) {
		bal = 0;
		for(i=0; i< [children count ]; i++) {
			node = [children objectAtIndex: i ];
			bal += [node updateBalance ];
			if(!curr) curr = [node currency ];
			else {
				if(![curr isEqual: [node currency ] ]) {
					bal = 0;
					[self setCurrency: @"*" ];
				}
			}
		}
		[self setCurrency: curr ];
	}
	else { 
//		bal = [accnt balance ];
		[self setCurrency: [accnt currency ] ];
	}
	[self setBalance: bal ];		// for KVO compliance
	return bal;
}

-(NSArray*)leaves
{
	NSMutableArray	*leaves = [NSMutableArray arrayWithCapacity: 10 ];
	
	int			i;
	AccountNode	*node;
	
	if(children) {
		for(i=0; i< [children count ]; i++) {
			node = [children objectAtIndex: i ];
			[leaves addObjectsFromArray: [node leaves ] ];
		}
	}
	else [leaves addObject: self ];
	return leaves;
}

-(NSArray*)nodes
{
	NSMutableArray	*leaves = [NSMutableArray arrayWithCapacity: 10 ];

	int			i;
	AccountNode	*node;

	if(children) {
		[leaves addObject: self ];
		for(i=0; i< [children count ]; i++) {
			node = [children objectAtIndex: i ];
			[leaves addObjectsFromArray: [node leaves ] ];
		}
	}
	else [leaves addObject: self ];
	return leaves;
}

-(AccountNode*)find: (NSString*)pname
{
	int i;
	
	if([name isEqual: pname]) return self;
	if(children) {
		for(i = 0; i< [children count ]; i++) {
			AccountNode	*node = [[children objectAtIndex: i ] find: pname ];
			if(node) return node;
		}
	}
	return nil;
}


-(NSArray*)transactions
{
	if(!accnt) return nil;
	return [accnt transactions ];
}

-(int)numberOfChildren
{
	if(!children) return 0;
	else return [children count ];
}

-(AccountNode*)childAtIndex: (int) i
{
	return [children objectAtIndex: i ];
}

-(void)dealloc
{
	[name release ];
	[currency release ];
	if(children) [children release ];
	if(accnt) [accnt release ];
	[super dealloc ];
}

@end
