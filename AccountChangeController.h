#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface AccountChangeController : NSWindowController {
    IBOutlet NSObjectController		*accountController;
    IBOutlet NSPopUpButton			*dropDown;
	IBOutlet NSTextField			*bicField;
	IBOutlet NSTextField			*bankCodeField;
	IBOutlet NSTextField			*bankNameField;
	IBOutlet NSButton				*collTransferCheck;
	IBOutlet NSButton				*stordCheck;
	IBOutlet NSPredicateEditor		*predicateEditor;
	
	NSManagedObjectContext			*moc;
	BankAccount						*account;
	BankAccount						*changedAccount;
	
	IBOutlet NSBox					*boxView;
	IBOutlet NSView					*manAccountAddView;
	IBOutlet NSView					*accountAddView;
	NSView							*currentAddView;
	
}

- (id)initWithAccount: (BankAccount*)acc;
- (BOOL)check;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)predicateEditorChanged:(id)sender;

@end
