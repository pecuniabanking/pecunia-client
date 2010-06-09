#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface AccountChangeController : NSWindowController {
    IBOutlet NSObjectController		*accountController;
    IBOutlet NSPopUpButton			*dropDown;
    IBOutlet NSArrayController		*passports;
	IBOutlet NSTextField			*bicField;
	IBOutlet NSTextField			*bankCodeField;
	IBOutlet NSTextField			*bankNameField;
	
	NSManagedObjectContext			*moc;
	BankAccount						*account;
	BankAccount						*changedAccount;
}

- (id)initWithAccount: (BankAccount*)acc;
- (BOOL)check;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;

@end
