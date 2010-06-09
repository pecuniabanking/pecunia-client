//
//  BankStatementController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 10.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankAccount;
@class BankStatement;

@interface BankStatementController : NSWindowController {
	IBOutlet NSObjectController		*statementController;
	IBOutlet NSObjectController		*accountController;
	IBOutlet NSDatePicker			*dateField;
	IBOutlet NSDatePicker			*valutaField;
	IBOutlet NSTextField			*saldoField;
	
	BankAccount				*account;
	NSManagedObjectContext	*memContext;
	NSManagedObjectContext	*context;
	BankStatement			*currentStatement;
	BankStatement			*oldStatement;
	NSString				*bankName;
	BOOL					firstStatement;
	NSDate					*lastDate;
	BankStatement			*lastStatement;
	NSArray					*accountStatements;
	int						actionResult;
}

@property (nonatomic, copy) NSArray *accountStatements;

-(id)initWithAccount: (BankAccount*)acc statement:(BankStatement*)stat;


-(IBAction)cancel: (id)sender;
-(IBAction)next: (id)sender;
-(IBAction)done: (id)sender;
-(IBAction)dateChanged:(id)sender;

-(BOOL)check;
-(void)arrangeStatements;

@end

