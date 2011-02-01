#import "AccountDefController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "ABUser.h"
#import "BankInfo.h"
#import "HBCIClient.h"
#import "BankingController.h"

@implementation AccountDefController

-(id)init
{
	self = [super initWithWindowNibName:@"AccountCreate"];
	moc = [[MOAssistant assistant ] memContext ];

	account = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:moc ];
	account.currency = @"EUR";
	account.country = @"DE";
	account.name = @"Neues Konto";
	return self;
}

- (void)setBankCode: (NSString*)code name: (NSString*)name
{
	account.bankCode = code;
	account.bankName = name;
}


-(void)awakeFromNib
{
	[[self window ] center ];
	
	int i=0;
	NSMutableArray* hbciUsers = [NSMutableArray arrayWithArray: [[HBCIClient hbciClient ] users ] ];
	// add special User
	ABUser *noUser  = [[[ABUser alloc ] init ] autorelease ];
	noUser.userId = NSLocalizedString(@"AP101", @"");
	[hbciUsers insertObject:noUser atIndex:0 ];
	
	[users setContent: hbciUsers ];
	// now find first user that fits bank code and change selection
	if(account.bankCode) {
		for(ABUser *user in hbciUsers) {
			if([user.bankCode isEqual: account.bankCode ]) {
				[dropDown selectItemAtIndex:i ];
				break;
			}
			i++;
		}
	}
	currentAddView = accountAddView;
	
	// fill proposal values
	[self dropChanged: self ];
}

-(IBAction)dropChanged: (id)sender
{
	int idx = [dropDown indexOfSelectedItem ];
	if(idx < 0) idx = 0;
	ABUser *user = [[users arrangedObjects ] objectAtIndex: idx];

	if(idx > 0) {
		account.bankName = user.bankName;
		account.bankCode = user.bankCode;
		BankInfo *info = [[HBCIClient hbciClient ] infoForBankCode: user.bankCode inCountry:account.country ];
		if (info) {
			account.bic = info.bic;
			account.bankName = info.name;
		}

		[bankCodeField setEditable: NO ];
		[bankCodeField setBezeled: NO ];
		
		if (currentAddView != accountAddView) {
			[manAccountAddView retain ];
			[boxView replaceSubview:manAccountAddView with:accountAddView ];
			currentAddView = accountAddView;
		}
	} else {
		[bankCodeField setEditable: YES ];
		[bankCodeField setBezeled: YES ];

		if (currentAddView != manAccountAddView) {
			[accountAddView retain ];
			[boxView replaceSubview:accountAddView with:manAccountAddView ];
			currentAddView = manAccountAddView;
		}
	}
}


-(IBAction)cancel:(id)sender 
{
    [self close ];
	[moc reset ];
	[NSApp stopModalWithCode: 0 ];
}

-(IBAction)ok:(id)sender
{
	[accountController commitEditing ];
	if([self check ] == NO) return;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];

	ABUser *user = nil;
	int idx = [dropDown indexOfSelectedItem ];
	if(idx > 0) user = [[users arrangedObjects ] objectAtIndex:idx ];

	// account is new - create entity in productive context
	BankAccount *bankRoot = [BankAccount bankRootForCode: account.bankCode ];
	if(bankRoot == nil) {
		Category *root = [Category bankRoot ];
		if(root != nil) {
			// create root for bank
			bankRoot = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:context];
			bankRoot.bankName = account.bankName;
			bankRoot.name = account.bankName;
			bankRoot.bankCode = account.bankCode;
			bankRoot.currency = account.currency;
			bankRoot.bic = account.bic;
			bankRoot.isBankAcc = [NSNumber numberWithBool: YES ];
			// parent
			bankRoot.parent = root;
		} else bankRoot = nil;
	}
	// insert account into hierarchy
	if(bankRoot) {
		// account is new - create entity in productive context
		newAccount = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:context ];
		newAccount.bankCode = account.bankCode;
		newAccount.bankName = account.bankName;
		if(user) {
			newAccount.isManual = [NSNumber numberWithBool:NO ];
			newAccount.userId = user.userId;
			newAccount.customerId = user.customerId;
			newAccount.collTransfer = account.collTransfer;
			newAccount.isStandingOrderSupported = account.isStandingOrderSupported;
		} else {
			newAccount.isManual = [NSNumber numberWithBool:YES ];	
			newAccount.balance = account.balance;
		}
		
		newAccount.parent = bankRoot;
		newAccount.isBankAcc = [NSNumber numberWithBool:YES ];
	}
	
	if(newAccount) {
		// update common data
		newAccount.iban = account.iban;
		newAccount.bic = account.bic;
		newAccount.owner = account.owner;
		newAccount.accountNumber = account.accountNumber; //?
		newAccount.name = account.name;
		newAccount.currency = account.currency;
	}

    [self close ];

	// save all
	NSError *error=nil;
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	
	if (newAccount.userId) {
		[[HBCIClient hbciClient ] addAccount:newAccount forUser:user ];
	}

	[moc reset ];
	[NSApp stopModalWithCode: 1 ];
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextField	*te = [aNotification object ];
	
	if([te tag ] == 100) {
		BOOL wasEditable = [bankNameField isEditable ];
		BankAccount *bankRoot = [BankAccount bankRootForCode:[te stringValue ] ];
		[bankNameField setEditable:NO ];
		[bankNameField setBezeled:NO ];
		if (bankRoot == nil) {
			NSString *name = [[HBCIClient hbciClient  ] bankNameForCode: [te stringValue ] inCountry: account.country ];
			if ([name isEqualToString:NSLocalizedString(@"unknown",@"") ]) {
				[bankNameField setEditable:YES ];
				[bankNameField setBezeled:YES ];
				if (wasEditable == NO) account.bankName = name;
			} else account.bankName = name;
		} else {
			account.bankName = bankRoot.name;
		}
	}
}


-(BOOL)check
{
	if(account.accountNumber == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
						NSLocalizedString(@"AP9", @"Please enter an account number"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	if(account.bankCode == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP10", @"Please enter a bank code"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	// default currency
	if([account.currency isEqual: @"" ]) account.currency = @"EUR";
	
	
	// check IBAN
	BOOL res;
	HBCIClient *hbciClient = [HBCIClient hbciClient ];
	
	
	if([hbciClient checkIBAN: account.iban ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP26", @"IBAN is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}
	
	// check account number
	res = [hbciClient checkAccount: account.accountNumber forBank: account.bankCode inCountry:account.country ];
	if(res == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP13", @"Account number is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}

	return YES;
}




@end
