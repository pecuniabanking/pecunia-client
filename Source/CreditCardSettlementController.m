/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "CreditCardSettlementController.h"
#import "HBCIClient.h"
#import "MOAssistant.h"
#import "CCSettlementList.h"
#import "CreditCardSettlement.h"

@interface CreditCardSettlementController ()

@end

@implementation CreditCardSettlementController

@synthesize account;
@synthesize settlements;

- (id)init
{
    self = [super initWithWindowNibName:@"CreditCardSettlement"];
    return self;
}

- (void)awakeFromNib
{
    [pdfView setAutoScales:YES];
    [self readSettlements];
    
    if ([settlements count] > 0) {
        currentIndex = 0;
        CreditCardSettlement *settlement = settlements[0];
        
        PDFDocument *document = [[PDFDocument alloc] initWithData:settlement.document];
        [pdfView setDocument:document];
    } else {
        NSString* path = [[NSBundle mainBundle] resourcePath];
        path = [path stringByAppendingString: @"/noccsettlements.pdf"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        PDFDocument *document = [[PDFDocument alloc] initWithData:data];
        [pdfView setDocument:document];
    }
    [self enableButtons];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)enableButtons
{
    [nextButton setEnabled:(currentIndex > 0)];
    [prevButton setEnabled:(currentIndex < [settlements count]-1)];
}

- (IBAction)next:(id)sender
{
    if (currentIndex > 0) {
        currentIndex--;
        CreditCardSettlement *settlement = settlements[currentIndex];
        PDFDocument *document = [[PDFDocument alloc] initWithData:settlement.document];
        [pdfView setDocument:document];
    }
    [self enableButtons];
}

- (IBAction)prev:(id)sender
{
    if ([settlements count] > currentIndex+1) {
        currentIndex++;
        CreditCardSettlement *settlement = settlements[currentIndex];
        PDFDocument *document = [[PDFDocument alloc] initWithData:settlement.document];
        [pdfView setDocument:document];
    }
    [self enableButtons];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[NSApp stopModalWithCode:0];
}

- (void)readSettlements
{
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    
    // fetch all existing settlements for this account
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CreditCardSettlement" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = %@", account];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"settleDate" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSError *error = nil;
    self.settlements = [context executeFetchRequest:fetchRequest error:&error];
}

- (IBAction)updateSettlements:(id)sender
{
    [self performSelector:@selector(update) withObject:nil afterDelay:0.1 inModes:@[NSModalPanelRunLoopMode]];
}

- (void)update
{
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    int oldNum = [settlements count];
    int newNum = 0;
    
    CCSettlementList *settleList = [[HBCIClient hbciClient] getCCSettlementListForAccount:account];
    if (settleList == nil) {
        return;
    }
    newNum = [settleList.settlementInfos count];
    
    for (CCSettlementInfo *info in settleList.settlementInfos) {
        BOOL found = NO;
        for (CreditCardSettlement *settlement in settlements) {
            if ([settlement.settleID isEqualToString:info.settleID]) {
                found = YES;
                break;
            }
        }
        if (found == NO) {
            // get new settlement
            CreditCardSettlement *memSettlement = [[HBCIClient hbciClient] getCreditCardSettlement:info.settleID forAccount:account];
            
            // copy from memory to real context
            if (memSettlement != nil) {
                NSEntityDescription *entity = [memSettlement entity];
                NSArray *attributeKeys = [[entity attributesByName] allKeys];
                NSDictionary *attributeValues = [memSettlement dictionaryWithValuesForKeys:attributeKeys];
                CreditCardSettlement *newSettlement = [NSEntityDescription insertNewObjectForEntityForName:@"CreditCardSettlement" inManagedObjectContext:context];
                [newSettlement setValuesForKeysWithDictionary:attributeValues];
                newSettlement.value = info.value;
                newSettlement.currency = info.currency;
                newSettlement.settleDate = info.settleDate;
                newSettlement.account = account;
                newSettlement.firstReceive = info.firstReceive;
            }
        }
    }
    
    NSError *error=nil;
    if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
    
    if (newNum > oldNum) {
        newNum -= oldNum;
    } else {
        newNum = 0;
    }
    
    // show latest document
    [self readSettlements];
    if ([settlements count] > 0) {
        currentIndex = 0;
        CreditCardSettlement *settlement = settlements[0];
        
        PDFDocument *document = [[PDFDocument alloc] initWithData:settlement.document];
        [pdfView setDocument:document];
    }
    [self enableButtons];
    
    if (newNum > 0) {
        NSRunAlertPanel(NSLocalizedString(@"AP71", nil),
                        NSLocalizedString(@"AP116", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil, newNum);
    } else {
        NSRunAlertPanel(NSLocalizedString(@"AP72", nil),
                        NSLocalizedString(@"AP117", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
    }
}


@end
