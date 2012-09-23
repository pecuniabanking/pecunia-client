/**
 * Copyright (c) 2010, 2012, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "StandingOrderController.h"
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
#import "TransferFormularView.h"

#import "GraphicsAdditions.h"
#import "AnimationHelper.h"

#import "NSButton+PecuniaAdditions.h"

NSString* const OrderDataType = @"OrderDataType"; // For dragging an existing order to the bin.

@interface DeleteOrderTargetView : NSImageView
{
}

@property (nonatomic, assign) StandingOrderController *controller;

@end

@implementation DeleteOrderTargetView

@synthesize controller;

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];
    
    // Register for types that can be deleted.
    [self registerForDraggedTypes: [NSArray arrayWithObjects: OrderDataType, nil]];
}

- (NSDragOperation)draggingEntered: (id <NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString *type = [pasteboard availableTypeFromArray: [NSArray arrayWithObjects: OrderDataType, nil]];
    if (type == nil) {
        return NSDragOperationNone;
    }
    
    [[NSCursor disappearingItemCursor] set];
    return NSDragOperationDelete;
}

- (void)draggingExited: (id <NSDraggingInfo>)info
{
    [[NSCursor arrowCursor] set];
}

- (BOOL)performDragOperation: (id<NSDraggingInfo>)info
{
    if ([controller concludeDropDeleteOperation: info]) {
        return YES;
    }
    return NO;
}

@end

//--------------------------------------------------------------------------------------------------

@interface StandingOrderController (private)
- (void)updateSourceAccountSelector;
- (void)prepareSourceAccountSelector: (BankAccount *)account;
- (void)storeReceiverInMRUList;
- (void)updateSourceAccountSelection;
@end

@implementation StandingOrderController

@synthesize requestRunning;

@synthesize oldMonthCycle;
@synthesize oldMonthDay;
@synthesize oldWeekCycle;
@synthesize oldWeekDay;
@synthesize currentLimits;
@synthesize currentOrder;

-(id)init
{
	self = [super init];
	if (self != nil) {
        managedObjectContext = MOAssistant.assistant.context;
        weekDays = [[NSArray arrayWithObjects:
                     NSLocalizedString(@"AP10030", nil),
                     NSLocalizedString(@"AP10031", nil),
                     NSLocalizedString(@"AP10032", nil),
                     NSLocalizedString(@"AP10033", nil),
                     NSLocalizedString(@"AP10034", nil),
                     NSLocalizedString(@"AP10035", nil),
                     NSLocalizedString(@"AP10036", nil),
                     nil] retain];
        accounts = [[NSMutableArray alloc] initWithCapacity: 10];
        self.requestRunning = [NSNumber numberWithBool: NO];
    }
    
	return self;
}

- (void)dealloc
{
	[currentLimits release];
	[currentOrder release];
	[weekDays release];
	[accounts release];
	
	[oldMonthCycle release];
	[oldMonthDay release];
	[oldWeekCycle release];
	[oldWeekDay release];
    
	[requestRunning release];
    
	[super dealloc];
}

-(void)awakeFromNib
{
    initializing = YES;
    
    monthCell.textColor = [NSColor whiteColor];
    weekCell.textColor = [NSColor whiteColor];

	[self initAccounts];
    [self disableCycles];
	[accountsController setContent: accounts];
    
    [self updateSourceAccountSelector];
    
    [ordersListView setCellSpacing: 0];
    [ordersListView setAllowsEmptySelection: NO];
    [ordersListView setAllowsMultipleSelection: NO];
    
    // TODO: do we really need the "negative cash color"? Standing orders can always only be positive, can't they?
    NSDictionary* positiveAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Positive Cash"], NSForegroundColorAttributeName,
                                        nil
                                        ];
    NSDictionary* negativeAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Negative Cash"], NSForegroundColorAttributeName,
                                        nil
                                        ];
    
    NSNumberFormatter* listViewFormatter = [ordersListView numberFormatter];
    [listViewFormatter setTextAttributesForPositiveValues: positiveAttributes];
    [listViewFormatter setTextAttributesForNegativeValues: negativeAttributes];
    
    /*
	// Sort order list by change date (newest first).
	NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey: @"changeDate" ascending: NO] autorelease];
	NSArray *sds = [NSArray arrayWithObject: sd];
	[orderController setSortDescriptors: sds];
     */
    
    // Actually, the values for the bound property and the key path don't matter as the listview has
    // a very clear understanding what it needs to bind to. It's just there to make the listview
    // establish its bindings.
    [ordersListView bind: @"dataSource" toObject: orderController withKeyPath: @"arrangedObjects" options: nil];
    
    [orderController bind: @"selectionIndexes" toObject: ordersListView withKeyPath: @"selectedRows" options: nil];
    [ordersListView bind: @"selectedRows" toObject: orderController withKeyPath: @"selectionIndexes" options: nil];
    
    standingOrderForm.icon = [NSImage imageNamed: @"cyclic"];
    standingOrderForm.bottomArea = 30;
    
    // We listen to selection changes in the pending transfers list.
    [orderController addObserver: self
                      forKeyPath: @"selectionIndexes"
                         options: 0
                         context: @"order-selection"];
    
    deleteImage.controller = self;
    
    initializing = NO;
}

-(void)initAccounts
{
	NSError *error = nil;
	
	[accounts removeAllObjects];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity: entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"accountNumber != nil AND isStandingOrderSupported == 1" ];
	[request setPredicate: predicate];
	NSArray *selectedAccounts = [managedObjectContext executeFetchRequest: request error: &error];
	if (error == nil) {
		for (BankAccount *account in selectedAccounts) {
			if ([[HBCIClient hbciClient] isStandingOrderSupportedForAccount: account]) {
				[accounts addObject: account];
			}
		}
	}	
}

-(NSString*)monthDayToString: (int)day
{
	if (day == 97) return @"Ultimo-2";
	else if (day == 98) return @"Ultimo-1";
	else if (day == 99) return @"Ultimo";
	else return [NSString stringWithFormat: @"%d." , day];
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
	currentOrder.cycle = [NSNumber numberWithInt: 1];
	currentOrder.executionDay = [NSNumber numberWithInt: 1];
}

-(int)stringToWeekDay:(NSString*)s
{
	return [weekDays indexOfObject: s] + 1;
}

-(void)preparePurposeFields
{
	int t;
	if(currentLimits == nil) return;
	
	int num = (t = currentLimits.maxLinesPurpose)? t : 2;
	NSTextField* p;
	
	p = (NSTextField*)[mainView viewWithTag: 4 ];
	if(num < 4) {
        [p setHidden: TRUE ];
        [p setStringValue:@"" ];
    } else [p setHidden: FALSE ];
	p = [mainView viewWithTag: 3 ];
	if(num < 3) {
        [p setHidden: TRUE ];
        [p setStringValue:@"" ];        
    } else [p setHidden: FALSE ];
	p = [mainView viewWithTag: 2 ];
	if(num < 2) {
        [p setHidden: TRUE ];
        [p setStringValue:@"" ];
    } else [p setHidden: FALSE ];
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
    NSInteger selectedIndex = 0;
    NSInteger currentCycle = currentOrder.cycle.intValue;
    NSMutableArray *weekCycles = [NSMutableArray arrayWithCapacity: 52];
    
    if (currentLimits.weekCycles == nil || currentLimits.weekCycles.count == 0 || [[currentLimits.weekCycles lastObject] intValue] == 0) {
        [weekCycles addObject: NSLocalizedString(@"AP451",  @"")];
        for(int i = 2; i <= 52; i++) {
            [weekCycles addObject:[NSString stringWithFormat: NSLocalizedString(@"AP453",  @""), i]];
            if (i == currentCycle) {
                selectedIndex = i;
            }
        }
    } else {
        NSInteger index = 0;
        for (NSString *s in currentLimits.weekCycles) {
            if (s.intValue == 1) {
                [weekCycles addObject: NSLocalizedString(@"AP451",  @"")];
            } else {
                [weekCycles addObject: [NSString stringWithFormat: NSLocalizedString(@"AP453",  @""), s.intValue]];
            }
            if (s.intValue == currentCycle) {
                selectedIndex = index;
            }
            index++;
        }
    }
    [weekCyclesController setContent: weekCycles];
    [weekCyclesPopup selectItemAtIndex: selectedIndex];

    NSMutableArray *execDays = [NSMutableArray arrayWithCapacity: 7];
    if (currentLimits.execDaysWeek == nil || [currentLimits.execDaysWeek count] == 0 || [[currentLimits.execDaysWeek lastObject] intValue] == 0) {
        for (int i = 1; i <= 7; i++) {
            [execDays addObject: [self weekDayToString: i]];
        }
    } else {
        for (NSString *s in currentLimits.execDaysWeek) {
            [execDays addObject: [self weekDayToString: s.intValue]];
        }
    }
	
    [execDaysWeekController setContent: execDays];
    [execDaysWeekPopup selectItemWithTitle: [self weekDayToString: currentOrder.executionDay.intValue]];
}

-(void)updateMonthCycles
{
    NSInteger selectedIndex = 0;
    NSInteger currentCycle = currentOrder.cycle.intValue;
	NSMutableArray *monthCycles = [NSMutableArray arrayWithCapacity: 12];
    
	if (currentLimits.monthCycles == nil || currentLimits.monthCycles.count == 0 || [[currentLimits.monthCycles lastObject] intValue] == 0) {
        [monthCycles addObject: NSLocalizedString(@"AP450",  @"")];
		for (NSInteger i = 1; i <= 12; i++) {
            [monthCycles addObject: [NSString stringWithFormat: NSLocalizedString(@"AP452",  @""), i]];
            if (i == currentCycle) {
                selectedIndex = i;
            }
        }
	} else {
        NSInteger index = 0;
		for (NSString *s in currentLimits.monthCycles) {
            if (s.intValue == 1) {
                [monthCycles addObject: NSLocalizedString(@"AP450",  @"")];
            } else {
                [monthCycles addObject: [NSString stringWithFormat: NSLocalizedString(@"AP452",  @""), s.intValue]];
            }
            if (s.intValue == currentCycle) {
                selectedIndex = index;
            }
            index++;
        }
	}
	
	[monthCyclesController setContent: monthCycles];
	[monthCyclesPopup selectItemAtIndex: selectedIndex];
	
	NSMutableArray *execDays = [NSMutableArray arrayWithCapacity: 31];
	if (currentLimits.execDaysMonth == nil || currentLimits.execDaysMonth.count == 0 || [[currentLimits.execDaysMonth lastObject] intValue] == 0) {
		for (int i = 1; i <= 28; i++) [execDays addObject: [NSString stringWithFormat: @"%d.", i]];
		[execDays addObject: @"Ultimo-2"];
		[execDays addObject: @"Ultimo-1"];
		[execDays addObject: @"Ultimo"];
	} else {
		for (NSString *s in currentLimits.execDaysMonth) {
			[execDays addObject: [self monthDayToString: s.intValue]];
		}
	}
	
	[execDaysMonthController setContent: execDays];
	[execDaysMonthPopup selectItemWithTitle: [self monthDayToString: currentOrder.executionDay.intValue]];
}

- (NSMenuItem*)createItemForAccountSelector: (BankAccount *)account
{
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: [account localName] action: nil keyEquivalent: @""] autorelease];
    item.representedObject = account;
    
    return item;
}


/**
 * Refreshes the content of the source account selector.
 * An attempt is made to keep the current selection.
 */
- (void)updateSourceAccountSelector
{
    [self prepareSourceAccountSelector: sourceAccountSelector.selectedItem.representedObject];
}

// update the selected item of the account selector with currentObject's account
- (void)updateSourceAccountSelection
{
    NSInteger selectedItem = 0;
    NSMenu *menu = [sourceAccountSelector menu ];
    NSArray *items = [menu itemArray ];
    for (NSMenuItem *item in items) {
        if (item.representedObject == currentOrder.account) {
            [sourceAccountSelector selectItemAtIndex: selectedItem];
            return;
        }
        selectedItem += 1;
    }
    [sourceAccountSelector selectItemAtIndex: -1];
}

/**
 * Refreshes the content of the source account selector and selects the given account (if found).
 */
- (void)prepareSourceAccountSelector: (BankAccount *)selectedAccount
{
    [sourceAccountSelector removeAllItems];
    
    NSMenu *sourceMenu = [sourceAccountSelector menu];
    
    Category *category = [Category bankRoot];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey: @"localName" ascending: YES] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
    NSArray *institutes = [[category children] sortedArrayUsingDescriptors: sortDescriptors];
    
    // Convert list of accounts in their institutes branches to a flat list
    // usable by the selector.
    NSEnumerator *institutesEnumerator = [institutes objectEnumerator];
    Category *currentInstitute;
    NSInteger selectedItem = 1; // By default the first entry after the first institute entry is selected.
    while ((currentInstitute = [institutesEnumerator nextObject])) {
        if (![currentInstitute isKindOfClass: [BankAccount class]]) {
            continue;
        }
        
        NSMenuItem *item = [self createItemForAccountSelector: (BankAccount *)currentInstitute];
        [sourceMenu addItem: item];
        [item setEnabled: NO];
        
        NSArray *accountsForInstitute = [[currentInstitute children] sortedArrayUsingDescriptors: sortDescriptors];
        NSEnumerator *accountEnumerator = [accountsForInstitute objectEnumerator];
        Category *currentAccount;
        while ((currentAccount = [accountEnumerator nextObject])) {
            if (![currentAccount isKindOfClass: [BankAccount class]]) {
                continue;
            }
            
            BankAccount *account = (BankAccount *)currentAccount;
            
            // Exclude manual accounts and those that don't support standing orders from the list.
            if ([account.isManual boolValue] || ![[HBCIClient hbciClient] isStandingOrderSupportedForAccount: account]) {
                continue;
            }
            
            item = [self createItemForAccountSelector: account];
            [item setEnabled: YES];
            item.indentationLevel = 1;
            [sourceMenu addItem: item];
            if (currentAccount == selectedAccount)
                selectedItem = sourceMenu.numberOfItems - 1;
        }
    }
    
    if (sourceMenu.numberOfItems > 1) {
        [sourceAccountSelector selectItemAtIndex: selectedItem];
    } else {
        [sourceAccountSelector selectItemAtIndex: -1];
    }
}

-(IBAction)monthCycle: (id)sender
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
	currentOrder.isChanged = [NSNumber numberWithBool: YES];
	[self updateMonthCycles ];
}

-(IBAction)weekCycle: (id)sender
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
	currentOrder.isChanged = [NSNumber numberWithBool: YES];
	[self updateWeekCycles ];
	
}

-(IBAction)monthCycleChanged: (id)sender
{
	currentOrder.cycle = [NSNumber numberWithInt:[[monthCyclesPopup titleOfSelectedItem ] intValue ] ];
	currentOrder.isChanged = [NSNumber numberWithBool: YES];
}

-(IBAction)monthDayChanged: (id)sender
{
	currentOrder.executionDay = [NSNumber numberWithInt:[self stringToMonthDay:[execDaysMonthPopup titleOfSelectedItem ] ]];
	currentOrder.isChanged = [NSNumber numberWithBool: YES];
}

-(IBAction)weekCycleChanged: (id)sender
{
	currentOrder.cycle = [NSNumber numberWithInt:[[weekCyclesPopup titleOfSelectedItem ] intValue ] ];
	currentOrder.isChanged = [NSNumber numberWithBool: YES];
}

-(IBAction)weekDayChanged: (id)sender
{
	currentOrder.executionDay = [NSNumber numberWithInt: [self stringToWeekDay:[execDaysWeekPopup titleOfSelectedItem ] ]];
	currentOrder.isChanged = [NSNumber numberWithBool: YES];
}

- (IBAction)add: (id)sender
{
	[self initAccounts];
    StandingOrder *order = [NSEntityDescription insertNewObjectForEntityForName: @"StandingOrder"
                                                         inManagedObjectContext: managedObjectContext];
    
    BankAccount *account = [sourceAccountSelector selectedItem].representedObject;
    
	order.account = account;
    if (account.currency.length == 0) {
        order.currency = @"EUR";
    } else {
        order.currency = account.currency;
    }
    order.period = [NSNumber numberWithInt: stord_monthly];
    order.cycle = [NSNumber numberWithInt: 1];
    order.executionDay = [NSNumber numberWithInt: 1];
    order.isChanged = [NSNumber numberWithBool: YES];
    ShortDate *startDate = [[ShortDate currentDate] firstDayInMonth];
    order.firstExecDate = [[startDate dateByAddingUnits: 1 byUnit: NSMonthCalendarUnit] lowDate];
    order.lastExecDate = [[ShortDate dateWithYear: 2999 month: 12 day: 31] lowDate];
    
    [orderController addObject: order];
}

- (IBAction)firstExecDateChanged: (id)sender
{
	currentOrder.isChanged = [NSNumber numberWithBool: YES];
}

- (IBAction)lastExecDateChanged: (id)sender
{
	currentOrder.isChanged = [NSNumber numberWithBool: YES];
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
	NSTextField *textField = [aNotification object];
	NSString *bankName;
	
	if ([textField tag] == 100) {
		bankName = [[HBCIClient hbciClient] bankNameForCode: [textField stringValue] inCountry: currentOrder.account.country];
		if (bankName) {
            currentOrder.remoteBankName = bankName;
        }
	}
	currentOrder.isChanged = [NSNumber numberWithBool: YES];
}

- (BOOL)checkOrder: (StandingOrder*)stord
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

- (IBAction)update: (id)sender
{
    // Make the sender the first responder to finish any pending edit action.
    [[mainView window] makeFirstResponder: sender];
    
	NSError *error = nil;
	NSArray *orders = [orderController arrangedObjects];
    
	for (StandingOrder *stord in orders) {
		if (![self checkOrder: stord]) {
			[orderController setSelectedObjects: [NSArray arrayWithObject: stord]];
			return;
		}
	}
	
	StatusBarController *sc = [StatusBarController controller];
	[sc startSpinning];
	self.requestRunning = [NSNumber numberWithBool: YES];
	[sc setMessage: NSLocalizedString(@"AP460", nil) removeAfter: 0];
    
	PecuniaError *hbciError = [[HBCIClient hbciClient] sendStandingOrders: orders];
	if (hbciError != nil) {
		[sc stopSpinning];
		[sc clearMessage];
		self.requestRunning = [NSNumber numberWithBool: NO];

		[hbciError alertPanel];
		return;
	}
	
	// Check if there are new orders without key.
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"StandingOrder" inManagedObjectContext:managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity: entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isSent == YES AND orderKey == nil" ];
	[request setPredicate: predicate];
	NSArray *stords = [managedObjectContext executeFetchRequest: request error: &error];
	if ([stords count ] > 0) {
		int res = NSRunAlertPanel(NSLocalizedString(@"AP115", @""), 
								  NSLocalizedString(@"AP116", @""),
								  NSLocalizedString(@"yes", @"Yes"), 
								  NSLocalizedString(@"no", @"No"), nil);
		if (res == NSAlertDefaultReturn) {
			[self performSelector: @selector(getOrders:) withObject: self afterDelay: 0];
		}
	}
	
    [sc stopSpinning];
    [sc clearMessage];
    self.requestRunning = [NSNumber numberWithBool: NO];

	// save updates
	if ([managedObjectContext save: &error] == NO) {
		NSAlert *alert = [NSAlert alertWithError: error];
		[alert runModal];
		return;
	}	
}

- (IBAction)getOrders: (id)sender
{
    // Make the sender the first responder to avoid changing anything if there was an ongoing
    // edit action.
    [[mainView window] makeFirstResponder: sender];

	NSMutableArray *resultList = nil;
/*    
	NSError *error = nil;
	BankAccount *account;

    [self initAccounts];
	
	if ([accounts count] == 0) {
		// no accounts for StandingOrder found...check?
		int res = NSRunAlertPanel(NSLocalizedString(@"AP108", @""), 
								  NSLocalizedString(@"AP109", @""),
								  NSLocalizedString(@"yes", @"Yes"), 
								  NSLocalizedString(@"no", @"No"), nil);
		if (res == NSAlertDefaultReturn) {
			NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: managedObjectContext];
			NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
			[request setEntity: entityDescription];
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"accountNumber != nil AND isManual = FALSE" ];
			[request setPredicate: predicate];
			NSArray *selectedAccounts = [managedObjectContext executeFetchRequest:request error:&error];
			if (selectedAccounts) {
				resultList = [NSMutableArray arrayWithCapacity: [selectedAccounts count]];
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
		resultList = [NSMutableArray arrayWithCapacity: [accounts count]];
		for (account in accounts) {
			if (account.userId) {
				BankQueryResult *result = [[BankQueryResult alloc] init];
				result.accountNumber = account.accountNumber;
                result.accountSubnumber = account.accountSuffix;
				result.bankCode = account.bankCode;
				result.userId = account.userId;
				result.account = account;
				[resultList addObject: [result autorelease]];
			}
		}
	}
*/
    resultList = [NSMutableArray arrayWithCapacity: 10];
    NSMenu *menu = [sourceAccountSelector menu ];
    NSArray *items = [menu itemArray ];
    for (NSMenuItem *item in items) {
        if ([item.representedObject isKindOfClass:[BankAccount class ]]) {
            BankAccount *account = (BankAccount*)item.representedObject;
			if (account.userId) {
				BankQueryResult *result = [[BankQueryResult alloc] init];
				result.accountNumber = account.accountNumber;
                result.accountSubnumber = account.accountSuffix;
				result.bankCode = account.bankCode;
				result.userId = account.userId;
				result.account = account;
				[resultList addObject: [result autorelease]];
			}
        }
    }
    
	StatusBarController *sc = [StatusBarController controller];
	[sc startSpinning];
	self.requestRunning = [NSNumber numberWithBool: YES];
	[sc setMessage: NSLocalizedString(@"AP459", nil) removeAfter: 0];
	[[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(ordersNotification:)
                                                 name: PecuniaStatementsNotification
                                               object: nil];

	[[HBCIClient hbciClient] getStandingOrders: resultList];

	// Next remove orders without ID.
	for (StandingOrder *order in [orderController arrangedObjects]) {
		if (order.orderKey == nil) {
            [managedObjectContext deleteObject: order];
        }
	}
}

#pragma mark -
#pragma mark Other notifications

- (IBAction)sourceAccountChanged: (id)sender
{
    BankAccount *account = [sender selectedItem].representedObject;
    
	currentOrder.account = account;
    if (account.currency.length == 0) {
        currentOrder.currency = @"EUR";
    } else {
        currentOrder.currency = account.currency;
    }
    
    // re-calculate limits and check
    if (currentOrder.orderKey == nil) {
        self.currentLimits = [[HBCIClient hbciClient] standingOrderLimitsForAccount: currentOrder.account action: stord_create];
    } else {
        self.currentLimits = [[HBCIClient hbciClient] standingOrderLimitsForAccount: currentOrder.account action: stord_change];
    }
    [self preparePurposeFields];
    
    // todo: update order to meet (new) limits
    
}

- (void)ordersNotification: (NSNotification*)notification
{
	BankQueryResult *result;
	StatusBarController *sc = [StatusBarController controller];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self name: PecuniaStatementsNotification object: nil];
	
	NSArray *resultList = [notification object];
	if (resultList == nil) {
		[sc stopSpinning];
		[sc clearMessage];
		self.requestRunning = [NSNumber numberWithBool: NO];
		return;
	}
	
	for (result in resultList) {
		[result.account updateStandingOrders: result.standingOrders];
	}
	
	[orderController rearrangeObjects];
	
	[sc stopSpinning];
	[sc clearMessage];
	self.requestRunning = [NSNumber numberWithBool: NO];
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context
{
    if (object == orderController) {
        if (initializing) {
            return;
        }
        
        NSArray *selection = [orderController selectedObjects];
        if (selection == nil || [selection count] == 0) {
            [self disableCycles];
            return;
        }
        if (currentOrder == [selection objectAtIndex: 0]) {
            return;
        }
        self.currentOrder = [selection objectAtIndex: 0];
        
        oldWeekDay = nil;
        oldWeekCycle = nil;
        oldMonthDay =  nil;
        oldMonthCycle = nil;
        if (currentOrder.orderKey == nil) {
            self.currentLimits = [[HBCIClient hbciClient] standingOrderLimitsForAccount: currentOrder.account action: stord_create];
        } else {
            self.currentLimits = [[HBCIClient hbciClient] standingOrderLimitsForAccount: currentOrder.account action: stord_change];
        }
        [self preparePurposeFields];
        if (self.currentOrder.remoteBankCode != nil && (self.currentOrder.remoteBankName == nil || [self.currentOrder.remoteBankName length] == 0)) {
            NSString *bankName = [[HBCIClient hbciClient] bankNameForCode: self.currentOrder.remoteBankCode inCountry: self.currentOrder.account.country];
            if (bankName) {
                self.currentOrder.remoteBankName = bankName;
            }
        }
        
        StandingOrderPeriod period = [currentOrder.period intValue];
        if (period == stord_weekly) {
            [self enableWeekly: YES];
            [weekCell setState: NSOnState];
            [monthCell setState: NSOffState];
            [self updateWeekCycles];
            [weekCyclesPopup setEnabled: currentLimits.allowChangeCycle];
            [execDaysWeekPopup setEnabled: currentLimits.allowChangeExecDay];
        } else {
            [self enableWeekly: NO];
            [weekCell setState: NSOffState];
            [monthCell setState: NSOnState];
            [self updateMonthCycles];
            [monthCyclesPopup setEnabled: currentLimits.allowChangeCycle];
            [execDaysMonthPopup setEnabled: currentLimits.allowChangeExecDay];
        }
        
        [weekCell setEnabled: currentLimits.allowWeekly];
        [monthCell setEnabled: currentLimits.allowMonthly];
        
        // (Re)Load the set of previously entered text for the receiver combo box.
        [receiverComboBox removeAllItems];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *values = [userDefaults dictionaryForKey: @"transfers"];
        if (values != nil) {
            id previousReceivers = [values objectForKey: @"previousReceivers"];
            if ([previousReceivers isKindOfClass: [NSArray class]]) {
                [receiverComboBox addItemsWithObjectValues: previousReceivers];
            }
        }
        
        // update account selector
        [self updateSourceAccountSelection ];
    } else {
        [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
    }
}

#pragma mark -
#pragma mark Drag and drop

/**
 * Called when the user drags transfers to the waste basket, which represents a delete operation.
 */
- (BOOL)concludeDropDeleteOperation: (id<NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString *type = [pasteboard availableTypeFromArray: [NSArray arrayWithObjects: OrderDataType, nil]];
    if (type == nil) {
        return NO;
    }
    
    // There can always be only one entry in the set.
    NSData *data = [pasteboard dataForType: type];
    NSArray *entries = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    NSManagedObjectID *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [entries lastObject]];
    if (objectId == nil) {
        return NO;
    }
    StandingOrder *order = (StandingOrder *)[context objectWithID: objectId];

    // If there is no order key yet then we are deleting a newly created standing order, which
    // has not yet been sent to the bank. So we can simply remove it from the controller.
    if (order.orderKey == nil) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP454", nil),
                                  NSLocalizedString(@"AP458", nil),
                                  NSLocalizedString(@"cancel", nil),
                                  NSLocalizedString(@"yes", nil),
                                  nil);
        if (res != NSAlertAlternateReturn) {
            return NO;
        }
        [orderController remove: self]; // The order is currently selected.
        return YES;
    }
    
    // Otherwise ask to mark the order for deletion. It gets then deleted when all changes are
    // sent to the bank.
    int res = NSRunAlertPanel(NSLocalizedString(@"AP454", nil),
                              NSLocalizedString(@"AP455", nil),
                              NSLocalizedString(@"cancel", nil),
                              NSLocalizedString(@"AP456", nil),
                              nil);
    if (res != NSAlertAlternateReturn) {
        return NO;
    }
    
    order.toDelete = [NSNumber numberWithBool: YES];
    
    return YES;
}

#pragma mark -
#pragma mark PecuniaTabItem protocol

-(NSView*)mainView
{
	return mainView;
}

-(void)print
{
}

- (void)activate
{
    [self updateSourceAccountSelector];
}

- (void)deactivate
{
}

-(void)prepare
{
}

-(void)terminate
{
}


@end



