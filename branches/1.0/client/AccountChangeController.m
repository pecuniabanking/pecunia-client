#import "AccountChangeController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
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
	account.collTransfer = acc.collTransfer;
	account.isStandingOrderSupported = acc.isStandingOrderSupported;
  account.noAutomaticQuery = acc.noAutomaticQuery;	
	account.userId = acc.userId;

	return self;
}

-(void)awakeFromNib
{

	if ([changedAccount.isManual boolValue] == YES) {
		[boxView replaceSubview:accountAddView with:manAccountAddView ];

		[predicateEditor addRow:self ];
		NSString* s = changedAccount.rule;
		if(s) {
			NSPredicate* pred = [NSCompoundPredicate predicateWithFormat: s ];
			if([pred class ] != [NSCompoundPredicate class ]) {
				NSCompoundPredicate* comp = [[NSCompoundPredicate alloc ] initWithType: NSOrPredicateType subpredicates: [NSArray arrayWithObjects: pred, nil ]];
				pred = comp;
			}
			[predicateEditor setObjectValue: pred ];
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
	
	// update common data
	changedAccount.iban = account.iban;
	changedAccount.bic = account.bic;
	changedAccount.owner = account.owner;
	changedAccount.name = account.name;
	changedAccount.collTransfer = account.collTransfer;
	changedAccount.isStandingOrderSupported = account.isStandingOrderSupported;
  changedAccount.noAutomaticQuery = account.noAutomaticQuery;
	
	if ([changedAccount.isManual boolValue] == YES) {
		NSPredicate* predicate = [predicateEditor objectValue];
		if(predicate) changedAccount.rule = [predicate description ];
	}
	

    [self close ];

	// save all
	NSError *error=nil;
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	
	if (changedAccount.userId) {
		[[HBCIClient hbciClient ] changeAccount:changedAccount ];
	}

	[moc reset ];
	[NSApp stopModalWithCode: 1 ];
}

- (IBAction)predicateEditorChanged:(id)sender
{	
//	if(awaking) return;
	// check NSApp currentEvent for the return key
    NSEvent* event = [NSApp currentEvent];
    if ([event type] == NSKeyDown)
	{
		NSString* characters = [event characters];
		if ([characters length] > 0 && [characters characterAtIndex:0] == 0x0D)
		{
/*			
			[self calculateCatAssignPredicate ];
			ruleChanged = YES;
*/ 
		}
    }
    // if the user deleted the first row, then add it again - no sense leaving the user with no rows
    if ([predicateEditor numberOfRows] == 0)
		[predicateEditor addRow:self];
}

- (void)ruleEditorRowsDidChange:(NSNotification *)notification
{
//	[self calculateCatAssignPredicate ];
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
