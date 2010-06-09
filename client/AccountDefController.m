#import "AccountDefController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "Passport.h"
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
	NSMutableArray* pps = [NSMutableArray arrayWithArray: [[HBCIClient hbciClient ] passports ] ];
	// add special Passport
	Passport *noPP  = [[[Passport alloc ] init ] autorelease ];
	noPP.userId = NSLocalizedString(@"AP101", @"");
	[pps insertObject:noPP atIndex:0 ];
	
	[passports setContent: pps ];
	// now find first user that fits bank code and change selection
	if(account.bankCode) {
		for(Passport *pp in pps) {
			if([pp.bankCode isEqual: account.bankCode ]) {
				[dropDown selectItemAtIndex:i ];
				break;
			}
			i++;
		}
	}
	
	// fill proposal values
	[self dropChanged: self ];
}

-(IBAction)dropChanged: (id)sender
{
	int idx = [dropDown indexOfSelectedItem ];
	if(idx < 0) idx = 0;
	Passport *pp = [[passports arrangedObjects ] objectAtIndex: idx];

	if(idx > 0) {
		account.bankName = pp.bankName;
		account.bankCode = pp.bankCode;
		BankAccount *bankRoot = [BankAccount bankRootForCode: pp.bankCode ];
		if(bankRoot) account.bic = bankRoot.bic;
		else {
			PecuniaError *error = nil;
			BankInfo *info = [[HBCIClient hbciClient ] infoForBankCode: pp.bankCode error: &error ];
			if(info) account.bic = info.bic;
		}
		[bankCodeField setEditable: NO ];
		[bankCodeField setBezeled: NO ];
		[balanceField setHidden: YES ];
//		[balanceField setBezeled: NO ];
	} else {
//		account.bankCode = account.bankName = account.bic = @"";
		[bankCodeField setEditable: YES ];
		[bankCodeField setBezeled: YES ];
		[balanceField setHidden: NO ];
//		[balanceField setBezeled: YES ];
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

	Passport *pp = nil;
	int idx = [dropDown indexOfSelectedItem ];
	if(idx > 0) pp = [[passports arrangedObjects ] objectAtIndex:idx ];

	// account is new - create entity in productive context
	BankAccount *bankRoot = [BankAccount bankRootForCode: account.bankCode ];
	if(bankRoot == nil) {
		Category *root = [Category bankRoot ];
		if(root != nil) {
			// create root for bank
			bankRoot = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:context];
			bankRoot.bankName = account.bankName;
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
		if(pp) newAccount.userId = pp.userId;
		if(pp) newAccount.customerId = pp.customerId;
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
		newAccount.balance = account.balance;
	}

    [self close ];

	// save all
	NSError *error=nil;
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	
	if (newAccount.userId) {
		NSArray *accounts = [NSArray arrayWithObject:newAccount ];
		[[HBCIClient hbciClient ] setAccounts:accounts];
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
			NSString *name = [[HBCIClient hbciClient  ] bankNameForCode: [te stringValue ] ];
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
	PecuniaError *error = nil;
	
	
	if([hbciClient checkIBAN: account.iban error: &error ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP26", @"IBAN is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}
	
	// check account number
	res = [hbciClient checkAccount: account.accountNumber bankCode: account.bankCode error: &error ];
	if(res == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP13", @"Account number is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}

	return YES;
}




@end
