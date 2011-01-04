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
	if (account.userId == nil) {
		[collTransferCheck setHidden:YES ];
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
//		[[HBCIClient hbciClient ] setAccounts:accounts];
	}

	[moc reset ];
	[NSApp stopModalWithCode: 1 ];
}

-(BOOL)check
{	
	// check IBAN
	HBCIClient *hbciClient = [HBCIClient hbciClient ];	
	
	if([hbciClient checkIBAN: account.iban ] == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP26", @"IBAN is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}
	
	return YES;
}




@end
