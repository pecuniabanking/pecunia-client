#import <Cocoa/Cocoa.h>

@class ABAccount;
@class BankAccount;
@class User;

@interface AccountDefController : NSWindowController {
    IBOutlet NSObjectController		*accountController;
    IBOutlet NSPopUpButton			*dropDown;
    IBOutlet NSArrayController		*users;
	IBOutlet NSTextField			*bicField;
	
	NSManagedObjectContext			*moc;
	ABAccount						*account;
	BankAccount						*changedAccount;
	BOOL							newAccount;
}

- (id)initWithAccount: (BankAccount*)acc;
- (BOOL)check;
- (void)setBankCode: (NSString*)code name: (NSString*)name;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)dropChanged: (id)sender;

@end
