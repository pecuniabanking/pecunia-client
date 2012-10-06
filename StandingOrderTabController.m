//
//  StandingOrderTabController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 26.11.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "StandingOrderTabController.h"
#import "MOAssistant.h"
#import "StandingOrder.h"
#import "HBCIClient.h"
#import "BankAccount.h"
#import "TransactionLimits.h"
#import "BankQueryResult.h"
#import "MCEMTableView.h"
#import "AmountCell.h"
#import "PecuniaError.h"
#import "StatusBarController.h"
#import "ShortDate.h"

@implementation StandingOrderTabController

@synthesize requestRunning;

@synthesize oldMonthCycle;
@synthesize oldMonthDay;
@synthesize oldWeekCycle;
@synthesize oldWeekDay;
@synthesize currentLimits;
@synthesize currentOrder;

-(id)init
{
	self = [super init ];
	if (self == nil) return nil;
	
	managedObjectContext = [[MOAssistant assistant ] context ];
	weekDays = [NSArray arrayWithObjects:@"Montag",@"Dienstag",@"Mittwoch",@"Donnerstag",@"Freitag",@"Samstag",@"Sonntag",nil ];
	[weekDays retain ];
	accounts = [[NSMutableArray alloc ] initWithCapacity:10 ];
	self.requestRunning = [NSNumber numberWithBool:NO ];
	return self;
}

-(void)awakeFromNib
{
	[self initAccounts ];
    [self disableCycles ];
	[accountsController setContent:accounts ];
}

-(void)prepare
{
	
}

-(void)terminate
{
	
}

-(void)initAccounts
{
	NSError *error = nil;
	
	[accounts removeAllObjects ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"accountNumber != nil AND isStandingOrderSupported == 1" ];
	[request setPredicate:predicate];
	NSArray *selectedAccounts = [managedObjectContext executeFetchRequest:request error:&error];
	if(error == nil) {
		for(BankAccount *account in selectedAccounts) {
			if ([[HBCIClient hbciClient ] isStandingOrderSupportedForAccount:account]) {
				[accounts addObject:account ];
			}
		}
	}	
}

-(NSString*)monthDayToString:(int)day
{
	if (day == 97) return @"Ultimo-2";
	else if (day == 98) return @"Ultimo-1";
	else if (day == 99) return @"Ultimo";
	else return [NSString stringWithFormat:@"%d." , day ];
}

-(NSString*)weekDayToString:(int)day
{
	if (day > 0 && day < 8) {
		return [weekDays objectAtIndex:day-1 ];
	}
	return [weekDays objectAtIndex:1 ];;
}

-(int)stringToMonthDay:(NSString*)s
{
	if ([s isEqualToString:@"Ultimo-2" ]) return 97;
	else if ([s isEqualToString:@"Ultimo-1" ]) return 98;
	else if ([s isEqualToString:@"Ultimo" ]) return 99;
	else return [[s substringToIndex:[s length ] - 1 ] intValue ];
}

-(void)initCycles
{
	currentOrder.cycle = [NSNumber numberWithInt:1];
	currentOrder.executionDay = [NSNumber numberWithInt:1];
}

-(int)stringToWeekDay:(NSString*)s
{
	return [weekDays indexOfObject:s ] + 1;
}

-(void)preparePurposeFields
{
	int t;
	if(currentLimits == nil) return;
	
	int num = (t = currentLimits.maxLinesPurpose)?t:2;
	NSView* p;
	
	p = [mainView viewWithTag: 4 ];
	if(num < 4) [p setHidden: TRUE ]; else [p setHidden: FALSE ];
	p = [mainView viewWithTag: 3 ];
	if(num < 3) [p setHidden: TRUE ]; else [p setHidden: FALSE ];
	p = [mainView viewWithTag: 2 ];
	if(num < 2) [p setHidden: TRUE ]; else [p setHidden: FALSE ];
}


-(void)enableWeekly:(BOOL)weekly
{
	if (weekly) {
		[execDaysMonthPopup setTitle:@"" ];
		[monthCyclesPopup setTitle:@"" ];
	} else {
		[execDaysWeekPopup setTitle:@"" ];
		[weekCyclesPopup setTitle:@"" ];
	} 
	[execDaysMonthPopup setEnabled:!weekly ];
	[monthCyclesPopup setEnabled:!weekly ];
	[execDaysWeekPopup setEnabled:weekly ];
	[weekCyclesPopup setEnabled:weekly ];
}

-(void)disableCycles
{
	[execDaysMonthPopup setEnabled:NO ];
	[monthCyclesPopup setEnabled:NO ];
	[execDaysWeekPopup setEnabled:NO ];
	[weekCyclesPopup setEnabled:NO ];
    [weekCell setEnabled:NO ];
    [monthCell setEnabled:NO ];
}

-(void)updateWeekCycles
{
	int i;
	
	NSMutableArray *weekCycles = [NSMutableArray arrayWithCapacity:52 ];
	if (currentLimits.weekCycles == nil || [currentLimits.weekCycles count] == 0 || [[currentLimits.weekCycles lastObject ] intValue ] == 0) {
		for(i=1;i<=52;i++) [weekCycles addObject:[NSString stringWithFormat:@"%d",i ] ];
	} else {
		for(NSString *s in currentLimits.weekCycles) [weekCycles addObject:[NSString stringWithFormat:@"%d", [s intValue ] ]];
	}
	[weekCyclesController setContent:weekCycles ];
	[weekCyclesPopup selectItemWithTitle:[NSString stringWithFormat:@"%d",[currentOrder.cycle intValue ] ]];
	
	NSMutableArray *execDays = [NSMutableArray arrayWithCapacity:7 ];
	if (currentLimits.execDaysWeek == nil || [currentLimits.execDaysWeek count] == 0 || [[currentLimits.execDaysWeek lastObject ] intValue ] == 0) {
		for(i=1;i<=7;i++) [execDays addObject:[self weekDayToString: i ] ];
	} else {
		for(NSString *s in currentLimits.execDaysWeek) [execDays addObject:[self weekDayToString:[s intValue ] ] ];
	}
	
	[execDaysWeekController setContent:execDays ];
	[execDaysWeekPopup selectItemWithTitle:[self weekDayToString: [currentOrder.executionDay intValue ] ]];
}

-(void)updateMonthCycles
{
	int i;
	
	NSMutableArray *monthCycles = [NSMutableArray arrayWithCapacity:12 ];
	if (currentLimits.monthCycles == nil || [currentLimits.monthCycles count] == 0 || [[currentLimits.monthCycles lastObject ] intValue ] == 0) {
		for(i=1;i<=12;i++) [monthCycles addObject:[NSString stringWithFormat:@"%d",i ] ];
	} else {
		for(NSString *s in currentLimits.monthCycles) [monthCycles addObject:[NSString stringWithFormat:@"%d", [s intValue ] ]];
	}
	
	[monthCyclesController setContent:monthCycles ];
	[monthCyclesPopup selectItemWithTitle:[NSString stringWithFormat:@"%d",[currentOrder.cycle intValue ] ]];
	
	NSMutableArray *execDays = [NSMutableArray arrayWithCapacity:31 ];
	if (currentLimits.execDaysMonth == nil || [currentLimits.execDaysMonth count] == 0 || [[currentLimits.execDaysMonth lastObject ] intValue ] == 0) {
		for(i=1;i<=28;i++) [execDays addObject:[NSString stringWithFormat:@"%d.",i ] ];
		[execDays addObject:@"Ultimo-2" ];
		[execDays addObject:@"Ultimo-1" ];
		[execDays addObject:@"Ultimo" ];
	} else {
		for(NSString *s in currentLimits.execDaysMonth) {
			[execDays addObject:[self monthDayToString: [s intValue ] ] ];
		}
	}
	
	[execDaysMonthController setContent:execDays ];
	[execDaysMonthPopup selectItemWithTitle:[self monthDayToString: [currentOrder.executionDay intValue ] ]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSArray *sel = [orderController selectedObjects ];
	if (sel == nil || [sel count ] == 0) {
        [self disableCycles ];
        return;
    }
	self.currentOrder = [sel objectAtIndex:0 ];
	
	oldWeekDay = nil; oldWeekCycle = nil; oldMonthDay =  nil; oldMonthCycle = nil;
	if (currentOrder.orderKey == nil) {
		self.currentLimits = [[HBCIClient hbciClient ] standingOrderLimitsForAccount:currentOrder.account action:stord_create ];
	} else {
		self.currentLimits = [[HBCIClient hbciClient ] standingOrderLimitsForAccount:currentOrder.account action:stord_change ];
	}
	[self preparePurposeFields ];
	
	if(self.currentOrder.remoteBankCode != nil && (self.currentOrder.remoteBankName == nil || [self.currentOrder.remoteBankName length ] == 0 )) {
		NSString *bankName = [[HBCIClient hbciClient  ] bankNameForCode: self.currentOrder.remoteBankCode inCountry: self.currentOrder.account.country ];
		if(bankName) self.currentOrder.remoteBankName = bankName;
	}
	
	StandingOrderPeriod period = [currentOrder.period intValue ];
	if (period == stord_weekly) {
		[self enableWeekly:YES ];
		[weekCell setState:NSOnState ];
		[monthCell setState:NSOffState ];
		[self updateWeekCycles ];
		[weekCyclesPopup setEnabled:currentLimits.allowChangeCycle ];
		[execDaysWeekPopup setEnabled:currentLimits.allowChangeExecDay ];
	} else {
		[self enableWeekly:NO ];
		[weekCell setState:NSOffState ];
		[monthCell setState:NSOnState ];
		[self updateMonthCycles ];
		[monthCyclesPopup setEnabled:currentLimits.allowChangeCycle ];
		[execDaysMonthPopup setEnabled:currentLimits.allowChangeExecDay ];
	}		
	
	[weekCell setEnabled: currentLimits.allowWeekly];
	[monthCell setEnabled: currentLimits.allowMonthly];	
}

-(IBAction)monthCycle:(id)sender
{
	StandingOrderPeriod period = [currentOrder.period intValue ];
	if (period == stord_weekly) {
		self.oldWeekDay = currentOrder.executionDay;
		self.oldWeekCycle = currentOrder.cycle;
		if(oldMonthDay) currentOrder.executionDay = oldMonthDay; else currentOrder.executionDay = [NSNumber numberWithInt:1 ];
		if(oldMonthCycle) currentOrder.cycle = oldMonthCycle; else currentOrder.cycle = [NSNumber numberWithInt:1 ];
	}
	[self enableWeekly:NO ];
	currentOrder.period = [NSNumber numberWithInt:stord_monthly ];
	currentOrder.isChanged = [NSNumber numberWithBool:YES ];
	[self updateMonthCycles ];
}

-(IBAction)weekCycle:(id)sender
{
	StandingOrderPeriod period = [currentOrder.period intValue ];
	if (period == stord_monthly) {
		self.oldMonthDay = currentOrder.executionDay;
		self.oldMonthCycle = currentOrder.cycle;
		if(oldWeekDay) currentOrder.executionDay = oldWeekDay; else currentOrder.executionDay = [NSNumber numberWithInt:1 ];
		if(oldWeekCycle) currentOrder.cycle = oldWeekCycle; else currentOrder.cycle = [NSNumber numberWithInt:1 ];
	}
	[self enableWeekly:YES ];
	currentOrder.period = [NSNumber numberWithInt:stord_weekly ];
	currentOrder.isChanged = [NSNumber numberWithBool:YES ];
	[self updateWeekCycles ];
	
}

-(IBAction)monthCycleChanged:(id)sender
{
	currentOrder.cycle = [NSNumber numberWithInt:[[monthCyclesPopup titleOfSelectedItem ] intValue ] ];
	currentOrder.isChanged = [NSNumber numberWithBool:YES ];
}

-(IBAction)monthDayChanged:(id)sender
{
	currentOrder.executionDay = [NSNumber numberWithInt:[self stringToMonthDay:[execDaysMonthPopup titleOfSelectedItem ] ]];
	currentOrder.isChanged = [NSNumber numberWithBool:YES ];
}

-(IBAction)weekCycleChanged:(id)sender
{
	currentOrder.cycle = [NSNumber numberWithInt:[[weekCyclesPopup titleOfSelectedItem ] intValue ] ];
	currentOrder.isChanged = [NSNumber numberWithBool:YES ];
}

-(IBAction)weekDayChanged:(id)sender
{
	currentOrder.executionDay = [NSNumber numberWithInt: [self stringToWeekDay:[execDaysWeekPopup titleOfSelectedItem ] ]];
	currentOrder.isChanged = [NSNumber numberWithBool:YES ];
}

-(void)add
{
	[self initAccounts ];
	int res = [NSApp runModalForWindow:selectAccountWindow ];
	if (res) {
		NSArray *sel = [accountsController selectedObjects ];
		if (sel == nil || [sel count ] != 1) return;
		BankAccount *account = [sel lastObject ];
		
		StandingOrder *stord = [NSEntityDescription insertNewObjectForEntityForName:@"StandingOrder"
															 inManagedObjectContext:managedObjectContext];
		stord.account = account;
		stord.period = [NSNumber numberWithInt:stord_monthly ];
		stord.cycle = [NSNumber numberWithInt:1 ];
		stord.executionDay = [NSNumber numberWithInt:1 ];
		stord.isChanged = [NSNumber numberWithBool:YES ];
		stord.currency = account.currency;
        stord.lastExecDate = [[ShortDate dateWithYear:2999 month:12 day:31 ] lowDate ];
		
		[orderController addObject:stord ];
		[orderController setSelectedObjects:[NSArray arrayWithObject:stord ] ];
	}
}

-(void)delete
{
	int res = NSRunAlertPanel(NSLocalizedString(@"AP117", @""), 
							  NSLocalizedString(@"AP118", @""),
							  NSLocalizedString(@"no", @"No"), 
							  NSLocalizedString(@"yes", @"Yes"), nil);
	
	if (res == NSAlertDefaultReturn) return;	
	[orderController remove:self ];
}

-(IBAction)accountsOk:(id)sender
{
	[selectAccountWindow close ];
	[NSApp stopModalWithCode:1 ];
}

-(IBAction)accountsCancel:(id)sender
{
	[selectAccountWindow close ];
	[NSApp stopModalWithCode:0 ];
}

-(IBAction)firstExecDateChanged:(id)sender
{
	currentOrder.isChanged = [NSNumber numberWithBool:YES ];
}

-(IBAction)lastExecDateChanged:(id)sender
{
	currentOrder.isChanged = [NSNumber numberWithBool:YES ];
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextField	*te = [aNotification object ];
	NSString	*bankName;
	
	if([te tag ] == 100) {
		bankName = [[HBCIClient hbciClient  ] bankNameForCode: [te stringValue ] inCountry: currentOrder.account.country ];
		if(bankName) currentOrder.remoteBankName = bankName;
	}
	currentOrder.isChanged = [NSNumber numberWithBool:YES ];
}


-(IBAction)segButtonPressed:(id)sender
{
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	switch(clickedSegmentTag) {
		case 0: [self add ]; break;
		case 1: [self delete ]; break;
//		case 2: [self edit: sender ]; break;
		default: return;
	}
}

- (void)dealloc
{
	[currentLimits release], currentLimits = nil;
	[currentOrder release], currentOrder = nil;
	[weekDays release ];
	[accounts release ];
	
	[oldMonthCycle release], oldMonthCycle = nil;
	[oldMonthDay release], oldMonthDay = nil;
	[oldWeekCycle release], oldWeekCycle = nil;
	[oldWeekDay release], oldWeekDay = nil;

	[requestRunning release], requestRunning = nil;

	[super dealloc];
}

-(BOOL)checkOrder:(StandingOrder*)stord
{
	BOOL			res;
	NSNumber		*value;
	
	if(stord.remoteName == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP8", @"Please enter a receiver"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	// do not check remote account for EU transfers, instead IBAN
	if(stord.remoteAccount == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"),
						NSLocalizedString(@"AP9", @"Please enter an account number"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	if(stord.remoteBankCode == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP10", @"Please enter a bank code"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
		
	if( (value = stord.value) == nil ) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP11", @"Please enter a value"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	if([value doubleValue ] <= 0) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP12", @"Please enter a value greater 0"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
	
	// purpose?
	if (stord.purpose1 == nil || [stord.purpose1 length ] == 0) {
		NSRunAlertPanel(NSLocalizedString(@"AP1", @"Missing data"), 
						NSLocalizedString(@"AP121", @"Please enter a purpose"),
						NSLocalizedString(@"ok", @"Ok"), nil, nil);
		return NO;
	}
				
	res = [[HBCIClient hbciClient ] checkAccount: stord.remoteAccount 
										 forBank: stord.remoteBankCode
									   inCountry: @"DE" ];
	
	if(res == NO) {
		NSRunAlertPanel(NSLocalizedString(@"wrong_input", @"Wrong input"), 
						NSLocalizedString(@"AP13", @"Account number is not valid"),
						NSLocalizedString(@"retry", @"Retry"), nil, nil);
		return NO;
	}

	return YES;	
}

-(IBAction)update:(id)sender
{
	NSError *error = nil;
	
	NSArray *orders = [orderController arrangedObjects ];
	for(StandingOrder *stord in orders) {
		if ([self checkOrder:stord ] == NO) {
			[orderController setSelectedObjects:[NSArray arrayWithObject:stord ] ];
			return;
		}
	}
	
	PecuniaError *hbciError = [[HBCIClient hbciClient ] sendStandingOrders: orders ];
	if (hbciError) {
		[hbciError alertPanel ];
		return;
	}
	
	// check if there are new orders without key
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"StandingOrder" inManagedObjectContext:managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	//	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"accountNumber != nil AND isStandingOrderSupported == 1" ];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isSent == YES AND orderKey == nil" ];
	[request setPredicate:predicate];
	NSArray *stords = [managedObjectContext executeFetchRequest:request error:&error];
	if ([stords count ] > 0) {
		int res = NSRunAlertPanel(NSLocalizedString(@"AP115", @""), 
								  NSLocalizedString(@"AP116", @""),
								  NSLocalizedString(@"yes", @"Yes"), 
								  NSLocalizedString(@"no", @"No"), nil);
		if (res == NSAlertDefaultReturn) {
			[self performSelector:@selector(getOrders:) withObject:self afterDelay:0 ];
		}
	}
	
	// save updates
	if([managedObjectContext save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}	
}

-(IBAction)getOrders:(id)sender
{
	NSError *error=nil;
	BankAccount *account;
	NSMutableArray *resultList;

    [self initAccounts ];
	
	if ([accounts count] == 0) {
		// no accounts for StandingOrder found...check?
		int res = NSRunAlertPanel(NSLocalizedString(@"AP108", @""), 
								  NSLocalizedString(@"AP109", @""),
								  NSLocalizedString(@"yes", @"Yes"), 
								  NSLocalizedString(@"no", @"No"), nil);
		if (res == NSAlertDefaultReturn) {
			NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:managedObjectContext];
			NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
			[request setEntity:entityDescription];
			//	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"accountNumber != nil AND isStandingOrderSupported == 1" ];
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"accountNumber != nil AND isManual = FALSE" ];
			[request setPredicate:predicate];
			NSArray *selectedAccounts = [managedObjectContext executeFetchRequest:request error:&error];
			if (selectedAccounts) {
				resultList = [[NSMutableArray arrayWithCapacity: [selectedAccounts count ] ] retain ];
				for(account in selectedAccounts) {
					if ([[HBCIClient hbciClient ] isStandingOrderSupportedForAccount:account]) {
						if (account.userId) {
							BankQueryResult *result = [[BankQueryResult alloc ] init ];
							result.accountNumber = account.accountNumber;
                            result.accountSubnumber = account.accountSuffix;
							result.bankCode = account.bankCode;
							result.userId = account.userId;
							result.account = account;
							account.isStandingOrderSupported = [NSNumber numberWithBool:YES ];
							[resultList addObject: [result autorelease] ];
						}					
					}
				}
			}
		} else return;
	} else {
		resultList = [[NSMutableArray arrayWithCapacity: [accounts count ] ] retain ];
		for(account in accounts) {
			if (account.userId) {
				BankQueryResult *result = [[BankQueryResult alloc ] init ];
				result.accountNumber = account.accountNumber;
                result.accountSubnumber = account.accountSuffix;
				result.bankCode = account.bankCode;
				result.userId = account.userId;
				result.account = account;
				[resultList addObject: [result autorelease] ];
			}
		}
	}
	
	StatusBarController *sc = [StatusBarController controller ];
	[sc startSpinning ];
	self.requestRunning = [NSNumber numberWithBool:YES ];
	[sc setMessage: NSLocalizedString(@"AP129", @"Load statements...") removeAfter:0 ];
	[[NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(ordersNotification:) name:PecuniaStatementsNotification object:nil ];

	[[HBCIClient hbciClient ] getStandingOrders: resultList ];

	// next remove orders withoud ID
	for(StandingOrder *stord in [orderController arrangedObjects ]) {
		if (stord.orderKey == nil) [managedObjectContext deleteObject:stord ];
	}
}

-(NSColor*)tableView:(MCEMTableView*)tv labelColorForRow:(int)row
{
	StandingOrder *stord = [[orderController arrangedObjects ] objectAtIndex: row ];
	if (stord.orderKey == nil && [stord.isSent boolValue ] == YES) return [NSColor redColor ];
	return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier ] isEqualToString: @"value" ]) {
		NSArray *orders = [orderController arrangedObjects ];
		StandingOrder *order = [orders objectAtIndex:rowIndex ];
		
		AmountCell *cell = (AmountCell*)aCell;
		cell.amount = order.value;
		cell.currency = order.currency;
	}
}

-(void)ordersNotification: (NSNotification*)notification
{
	BankQueryResult *result;
	StatusBarController *sc = [StatusBarController controller ];
	
	[[NSNotificationCenter defaultCenter ] removeObserver:self name:PecuniaStatementsNotification object:nil ];
	
	NSArray *resultList = [notification object ];
	if(resultList == nil) {
		[sc stopSpinning ];
		[sc clearMessage ];
		self.requestRunning = [NSNumber numberWithBool:NO ];
		return;
	}
	
	for(result in resultList) {
		[result.account updateStandingOrders: result.standingOrders ];
	}
	
	[orderController rearrangeObjects ];
	
	[sc stopSpinning ];
	[sc clearMessage ];
	self.requestRunning = [NSNumber numberWithBool:NO ];
	[resultList autorelease ];
}


-(NSView*)mainView
{
	return mainView;
}

-(void)print
{
	
}
	

@end



