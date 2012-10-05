//
//  AccountMoveController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 19.05.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AccountMoveController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "Category.h"

@implementation AccountMoveController

@synthesize newAccountNumber;
@synthesize newBankCode;

- (void)dealloc
{
	[newAccountNumber release], newAccountNumber = nil;
	[newBankCode release], newBankCode = nil;

	[super dealloc];
}


-(id)initWithAccount: (BankAccount*)acc
{
	self = [super initWithWindowNibName:@"AccountMoveController"];
	account = acc;
	isOk = NO;
	return self;
}

-(void)awakeFromNib
{
	[[newAccountController content ] setValue:account.bankCode forKey: @"newBankCode" ];
	[[newAccountController content ] setValue:account.accountNumber forKey: @"newAccountNumber" ];
}
-(void)windowWillClose:(NSNotification *)aNotification
{
	if(isOk) [NSApp stopModalWithCode:1];
	else [NSApp stopModalWithCode:0];
}

-(IBAction)cancel: (id)sender
{
	[self close ];
}

-(IBAction)ok:(id)sender
{
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSManagedObjectModel *model = [[MOAssistant assistant ] model ];
	NSError *error = nil;
	BankAccount *bankNode;
	BOOL found;
	
	[newAccountController commitEditing ];
	account.accountNumber = [[newAccountController content ] valueForKey:@"newAccountNumber" ];
	account.bankCode = [[newAccountController content ] valueForKey:@"newBankCode" ];
	
	// look for bank code entry
	Category	*root = [Category bankRoot ];
	if(root == nil) return;
	
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"bankNodes"];
	NSArray *nodes = [context executeFetchRequest:request error:&error];
	if( error != nil || nodes == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	
	found = NO;
	for(bankNode in nodes) {
		if( [[bankNode valueForKey: @"bankCode" ] isEqual: account.bankCode ]) {
			found = YES;
			break;
		}
	}
	if(found == NO) {
		// create bank node
		bankNode = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount"
												 inManagedObjectContext:context];
		[bankNode setValue: account.bankName forKey: @"name" ];
		[bankNode setValue: account.bankCode forKey: @"bankCode"];
		[bankNode setValue: account.bankName forKey: @"bankName"];
		[bankNode setValue: account.currency forKey: @"currency"];
		[bankNode setValue: [NSNumber numberWithBool: YES ] forKey: @"isBankAcc" ];
		// link
		[bankNode setValue: root forKey: @"parent"];
	}
	
	BankAccount *oldParent = (BankAccount*)account.parent;
	account.parent = bankNode;
	[account.parent invalidateBalance ];
	
	// remove parent if it no longer has children
	NSMutableSet *children = [oldParent mutableSetValueForKey:@"children" ];
	if ([children count ] == 0) {
		// remove old parent
		// maybe this does not work, has to be tested well
		[context deleteObject:oldParent ];
	} else {
		[oldParent invalidateBalance ];
	}
	
	isOk = YES;
	[self close ];
}


@end

