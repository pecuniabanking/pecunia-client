#import "AccountChangeController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "Passport.h"
#import "BankInfo.h"
#import "HBCIClient.h"
#import "BankingController.h"

@implementation AccountChangeController

-(id)initWithAccount: (BankAccount*)acc
{
	self = [super initWithWindowNibName:@"AccountMaintenance"];
	moc = [[MOAssistant assistant ] memContext ];

	account = [NSEntityDescription insertNewObjectForEntityForName:@"BankAccount" inManagedObjectContext:moc ];
	
	changedAccount = acc;
	account.bankCode = acc.bankCode;
	account.accountNumber = acc.accountNumber;
	account.owner = acc.owner;
	account.bankName = acc.bankName;
	account.name = acc.name;
	account.bic = acc.bic;
	account.iban = acc.iban;
	account.currency = acc.currency;

	return self;
}

-(void)awakeFromNib
{
//	[[self window ] center ];
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
	
	// update common data
	changedAccount.iban = account.iban;
	changedAccount.bic = account.bic;
	changedAccount.owner = account.owner;
//	changedAccount.accountNumber = account.accountNumber; //?
	changedAccount.name = account.name;
//	changedAccount.currency = account.currency;

    [self close ];

	// save all
	NSError *error=nil;
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	
	if (changedAccount.userId) {
		NSArray *accounts = [NSArray arrayWithObject:changedAccount ];
		[[HBCIClient hbciClient ] setAccounts:accounts];
	}

	[moc reset ];
	[NSApp stopModalWithCode: 1 ];
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
