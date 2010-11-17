#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface AccountDefController : NSWindowController {
    IBOutlet NSObjectController		*accountController;
    IBOutlet NSPopUpButton			*dropDown;
    IBOutlet NSArrayController		*users;
	IBOutlet NSTextField			*bicField;
	IBOutlet NSTextField			*bankCodeField;
	IBOutlet NSTextField			*bankNameField;
	IBOutlet NSTextField			*balanceField;
	IBOutlet NSTextField			*balanceLabel;
	
	IBOutlet NSBox					*boxView;
	IBOutlet NSView					*manAccountAddView;
	IBOutlet NSView					*accountAddView;
	NSView							*currentAddView;
	
	NSManagedObjectContext			*moc;
	BankAccount						*account;
	BankAccount						*newAccount;
}

- (id)init;
- (BOOL)check;
- (void)setBankCode: (NSString*)code name: (NSString*)name;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)dropChanged: (id)sender;

@end
