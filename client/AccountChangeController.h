#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface AccountChangeController : NSWindowController {
    IBOutlet NSObjectController		*accountController;
    IBOutlet NSPopUpButton			*dropDown;
	IBOutlet NSTextField			*bicField;
	IBOutlet NSTextField			*bankCodeField;
	IBOutlet NSTextField			*bankNameField;
	IBOutlet NSButton				*collTransferCheck;
	
	NSManagedObjectContext			*moc;
	BankAccount						*account;
	BankAccount						*changedAccount;
}

- (id)initWithAccount: (BankAccount*)acc;
- (BOOL)check;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;

@end
