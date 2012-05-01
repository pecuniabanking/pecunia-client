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

#import "TransfersListview.h"

#import "TransfersController.h"
#import "TransactionController.h"
#import "PecuniaError.h"
#import "LogController.h"
#import "HBCIClient.h"
#import "MOAssistant.h"
#import "AmountCell.h"

#import "GraphicsAdditions.h"

@implementation TransfersController

- (void)dealloc
{
	[formatter release];
	[super dealloc];
}

- (void)awakeFromNib
{
    [transfers setManagedObjectContext: [[MOAssistant assistant] context]];
    [transfers prepareContent];
    [transactionController setManagedObjectContext: [[MOAssistant assistant] context]];

	// sort descriptor for transfer view
	NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending: NO] autorelease];
	NSArray *sds = [NSArray arrayWithObject: sd];
	[transfers setSortDescriptors: sds];
	
	[transferView setDoubleAction: @selector(transferDoubleClicked:) ];
	[transferView setTarget:self ];
	
    NSDictionary* positiveAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Positive Cash"], NSForegroundColorAttributeName,
                                        nil
                                        ];
    NSDictionary* negativeAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Negative Cash"], NSForegroundColorAttributeName,
                                        nil
                                        ];
    
	formatter = [[NSNumberFormatter alloc ] init ];
	[formatter setNumberStyle: NSNumberFormatterCurrencyStyle ];
	[formatter setLocale:[NSLocale currentLocale ] ];
	[formatter setCurrencySymbol: @"" ];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    
    [transfersListView setCellSpacing: 0];
    [transfersListView setAllowsEmptySelection: YES];
    [transfersListView setAllowsMultipleSelection: YES];
    NSNumberFormatter* listViewFormatter = [transfersListView numberFormatter];
    [listViewFormatter setTextAttributesForPositiveValues: positiveAttributes];
    [listViewFormatter setTextAttributesForNegativeValues: negativeAttributes];

    [transfersListView bind: @"dataSource" toObject: transfers withKeyPath: @"arrangedObjects" options: nil];
    [transfersListView bind: @"valueArray" toObject: transfers withKeyPath: @"arrangedObjects.value" options: nil];
}

- (void)setManagedObjectContext:(NSManagedObjectContext*)context
{
	[transfers setManagedObjectContext: context ];
	[transfers prepareContent ];
}

- (IBAction)sendTransfers: (id)sender
{
	NSArray* sel = [transfers selectedObjects ];
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

- (IBAction)deleteTransfers: (id)sender
{
	NSError *error = nil;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	
	NSArray* sel = [transfers selectedObjects ];
	if(sel == nil || [sel count ] == 0) return;
	
	int res = NSRunAlertPanel(NSLocalizedString(@"AP14", @"Delete transfers"), 
                              NSLocalizedString(@"AP15", @"Entries will be deleted for good. Continue anyway?"),
                              NSLocalizedString(@"no", @"No"), 
                              NSLocalizedString(@"yes", @"Yes"), 
                              nil);
	if (res != NSAlertAlternateReturn) return;
	
	for (Transfer* transfer in sel) {
		[context deleteObject: transfer ];
	}
	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

- (IBAction)changeTransfer: (id)sender
{
	NSArray* sel = [transfers selectedObjects ];
	if(sel == nil || [sel count ] != 1) return;
	
	[transactionController changeTransfer: [sel objectAtIndex:0 ] ];
}

- (IBAction)transferDoubleClicked: (id)sender
{
	int row = [sender clickedRow ];
	if(row<0) return;
	
	NSArray* sel = [transfers selectedObjects ];
	if(sel == nil || [sel count ] != 1) return;
	Transfer *transfer = (Transfer*)[sel objectAtIndex:0 ];
	if ([transfer.isSent boolValue] == NO) {
		[transactionController changeTransfer: transfer ];
	}
}

- (void)setFilterPredicate:(NSPredicate*)pred
{
	[transfers setFilterPredicate: pred ];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSDecimalNumber *sum = [NSDecimalNumber zero ];
	Transfer *transfer;
	NSArray *sel = [transfers selectedObjects ];
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
		NSArray *transfersArray = [transfers arrangedObjects];
		Transfer *transfer = [transfersArray objectAtIndex:rowIndex ];
		
		AmountCell *cell = (AmountCell*)aCell;
		cell.objectValue = transfer.value;
		cell.currency = transfer.currency;
	}
}	

- (NSView *)mainView
{
    return mainView;
}

- (void)prepare
{
    
}

-(void)terminate
{
	
}

@end
