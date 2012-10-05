//
//  TransferListController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 14.07.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "TransferListController.h"
#import "TransactionController.h"
#import "PecuniaError.h"
#import "LogController.h"
#import "HBCIClient.h"
#import "MOAssistant.h"
#import "AmountCell.h"


@implementation TransferListController

-(void)awakeFromNib
{
	// sort descriptor for transfer view
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[transferController setSortDescriptors: sds ];
	
	[transferView setDoubleAction: @selector(transferDoubleClicked:) ];
	[transferView setTarget:self ];
	
	formatter = [[NSNumberFormatter alloc ] init ];
	[formatter setNumberStyle: NSNumberFormatterCurrencyStyle ];
	[formatter setLocale:[NSLocale currentLocale ] ];
	[formatter setCurrencySymbol:@"" ];
}

-(void)setManagedObjectContext:(NSManagedObjectContext*)context
{
	[transferController setManagedObjectContext: context ];
	[transferController prepareContent ];
}

-(IBAction)sendTransfers: (id)sender
{
	NSArray* sel = [transferController selectedObjects ];
	if(sel == nil) return;
	
	// show log if wanted
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL showLog = [defaults boolForKey: @"logForTransfers" ];
	if (showLog) {
		LogController *logController = [LogController logController ];
		[logController showWindow:self ];
		[[logController window ] orderFront:self ];
	}
	
	BOOL sent = [[HBCIClient hbciClient ] sendTransfers: sel ];
	if(sent) {
		// save updates
		NSError *error = nil;
		NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
		if([context save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
}

-(IBAction)deleteTransfers: (id)sender
{
	int		i;
	NSError *error = nil;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	
	NSArray* sel = [transferController selectedObjects ];
	if(sel == nil || [sel count ] == 0) return;
	
	i = NSRunAlertPanel(NSLocalizedString(@"AP14", @"Delete transfers"), 
						NSLocalizedString(@"AP15", @"Entries will be deleted for good. Continue anyway?"),
						NSLocalizedString(@"no", @"No"), 
						NSLocalizedString(@"yes", @"Yes"), 
						nil);
	if(i != NSAlertAlternateReturn) return;
	
	for(i=0; i < [sel count ]; i++) {
		Transfer* transfer = [sel objectAtIndex: i ];
		[context deleteObject: transfer ];
	}
	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

-(IBAction)changeTransfer: (id)sender
{
	NSArray* sel = [transferController selectedObjects ];
	if(sel == nil || [sel count ] != 1) return;
	
	[transferWindowController changeTransfer: [sel objectAtIndex:0 ] ];
}

-(IBAction)transferDoubleClicked: (id)sender
{
	int row = [sender clickedRow ];
	if(row<0) return;
	
	NSArray* sel = [transferController selectedObjects ];
	if(sel == nil || [sel count ] != 1) return;
	Transfer *transfer = (Transfer*)[sel objectAtIndex:0 ];
	if ([transfer.isSent boolValue] == NO) {
		[transferWindowController changeTransfer: transfer ];
	}
}

-(void)setFilterPredicate:(NSPredicate*)pred
{
	[transferController setFilterPredicate: pred ];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSDecimalNumber *sum = [NSDecimalNumber zero ];
	Transfer *transfer;
	NSArray *sel = [transferController selectedObjects ];
	NSString *currency = nil;

	for(transfer in sel) {
		if ([transfer.isSent boolValue] == NO) {
			if (transfer.value) {
				sum = [sum decimalNumberByAdding:transfer.value ];
			}
			if (currency) {
				if (![transfer.currency isEqualToString:currency ]) {
					currency = @"*";
				}
			} else currency = transfer.currency;
		}
	}
	
	if(currency) [selAmountField setStringValue: [NSString stringWithFormat: @"(%@%@ ausgewählt)", [formatter stringFromNumber:sum ], currency ] ];
	else [selAmountField setStringValue: @"" ];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier ] isEqualToString: @"value" ]) {
		NSArray *transfers = [transferController arrangedObjects ];
		Transfer *transfer = [transfers objectAtIndex:rowIndex ];
		
		AmountCell *cell = (AmountCell*)aCell;
		cell.amount = transfer.value;
		cell.currency = transfer.currency;
	}
}	

-(void)dealloc
{
	[formatter release ];
	[super dealloc ];
}


@end
