//
//  BankStatementController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 10.03.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankAccount;
@class BankStatement;

@interface BankStatementController : NSWindowController {
	IBOutlet NSObjectController		*statementController;
	IBOutlet NSObjectController		*accountController;
	IBOutlet NSArrayController		*categoriesController;
	IBOutlet NSDatePicker			*dateField;
	IBOutlet NSDatePicker			*valutaField;
	IBOutlet NSTextField			*saldoField;
	IBOutlet NSTextField			*valueField;
	
	BankAccount				*account;
	NSManagedObjectContext	*memContext;
	NSManagedObjectContext	*context;
	BankStatement			*currentStatement;
	NSString				*bankName;
	BOOL					firstStatement;
	NSDate					*lastDate;
	BankStatement			*lastStatement;
	NSArray					*accountStatements;
	int						actionResult;
	BOOL					negateValue;
}

@property (nonatomic, copy) NSArray *accountStatements;

-(id)initWithAccount: (BankAccount*)acc statement:(BankStatement*)stat;


-(IBAction)cancel: (id)sender;
-(IBAction)next: (id)sender;
-(IBAction)done: (id)sender;
-(IBAction)dateChanged:(id)sender;
-(IBAction)negateValueChanged:(id)sender;

-(BOOL)check;
-(void)arrangeStatements;

@end

