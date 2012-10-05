#import "AccountDefController.h"
#import "ABController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "User.h"
#import "BankInfo.h"

@implementation AccountDefController

-(id)initWithAccount: (BankAccount*)acc
{
	self = [super initWithWindowNibName:@"AccountMaintenance"];
	moc = [[MOAssistant assistant ] context ];
	account = [[ABAccount alloc ] init ];
	changedAccount = acc;
	if(acc) {
		newAccount = NO;
		ABAccount* bankAccount = [acc abAccount ];
		account.bankCode = bankAccount.bankCode;
		account.accountNumber = bankAccount.accountNumber;
		account.bankName = bankAccount.bankName;
		account.bic = bankAccount.bic;
		account.iban = bankAccount.iban;
		account.currency = bankAccount.currency;
		account.country = bankAccount.country;
		account.name = bankAccount.name;
		account.ownerName = bankAccount.ownerName;
		account.collTransfer = bankAccount.collTransfer;
	} else {
		account.currency = @"EUR";
		account.country = @"de";
		newAccount = YES;
	}
	return self;
}

- (void)setBankCode: (NSString*)code name: (NSString*)name
{
	account.bankCode = code;
	account.bankName = name;
}


-(void)awakeFromNib
{
	int i;
	
	ABController *abController = [ABController abController ];
	if(abController == nil) return;
	NSArray* bankUsers = [abController users ];
	[users setContent: bankUsers ];
	// now find first user that fits bank code and change selection
	if([account bankCode ]) {
		for(i=0; i<[bankUsers count ]; i++) {
			User *user = [bankUsers objectAtIndex:i ];
			if([[user bankCode ] isEqual: [account bankCode ] ]) {
				[dropDown selectItemAtIndex:i ];
				break;
			}
		}
	}
	
	if(newAccount == NO) {
		[[self window ] setTitle: NSLocalizedString(@"change_account", @"Change Account") ];
	}
	if(newAccount == YES) {
		// fill proposal values
		[self dropChanged: self ];
	}
}

-(IBAction)dropChanged: (id)sender
{
	int idx = [dropDown indexOfSelectedItem ];
	if(idx < 0) idx = 0;
	User *user = [[users arrangedObjects ] objectAtIndex: idx];
	BankInfo *info = [[ABController abController ] infoForBankCode: user.bankCode inCountry: user.country ];
	if(info==nil) return;
	account.bankName = info.name;
	account.bankCode = user.bankCode;
	account.bic = info.bic;
}


-(IBAction)cancel:(id)sender 
{
    [self close ];
	[account release ];
	[NSApp stopModalWithCode: 0 ];
}

-(IBAction)ok:(id)sender
{
	[accountController commitEditing ];
	if([self check ] == NO) return;
	ABController *abController = [ABController abController ];
	if(newAccount) {
		NSArray	*objs = [users arrangedObjects ];
		int idx = [dropDown indexOfSelectedItem ];
		User *user = [objs objectAtIndex:idx ];
		if(idx<0) return;
		if([abController addAccount: account forUser: user ] == NO) {

		
		}
	} else {
		// change existing account
		ABAccount *bankAccount = [changedAccount abAccount ];
		bankAccount.bic = account.bic;
		bankAccount.iban = account.iban;
		bankAccount.name = account.name;
		bankAccount.ownerName = account.ownerName;
		bankAccount.collTransfer = account.collTransfer;
		[bankAccount updateChanges ];
		
		changedAccount.name = account.name;
		changedAccount.owner = account.ownerName;
		
	}
	[abController save ];
    [self close ];
	[account release ];
	[NSApp stopModalWithCode: 1 ];
}

// leave this in in case we have to change the bank code later
/*
-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextField	*te = [aNotification object ];
	NSString	*bankName;
	
	if([te tag ] != 100) return;
	
	if([account bankName ] == nil) {
		bankName = [[ABController abController ] bankNameForCode: [te stringValue ]
															inCountry: @"de" ];
		[account setValue: bankName forKey: @"bankName" ];
	}
}
*/

-(BOOL)check
{
	if(account.accountNumber == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
						NSLocalizedString(@"AP9", @"Please enter an account number"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	if(account.bankCode== nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP10", @"Please enter a bank code"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	// default currency
	if([account.currency isEqual: @"" ]) account.currency = @"EUR";
	
	
	// check IBAN
	BOOL res;
	ABController *abController = [ABController abController ];
	
	if([abController checkIBAN: account.iban ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP26", @"IBAN is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}
	
	// check account number
	res = [abController checkAccount: account.accountNumber
							 forBank: account.bankCode
						   inCountry: @"de" ];
	if(res == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP13", @"Account number is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}
	return YES;
}




@end
