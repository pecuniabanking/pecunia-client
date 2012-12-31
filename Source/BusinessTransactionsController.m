/**
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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

#import "BusinessTransactionsController.h"
#import "LogController.h"

@implementation BusinessTransactionsController

- (id)initWithTransactions: (NSArray*)transactions;
{
    self = [super initWithWindowNibName: @"BusinessTransactionsWindow"];
    if (self != nil) {
        NSString* path = [[NSBundle mainBundle] resourcePath];
        path = [path stringByAppendingString: @"/HBCI business transactions.csv"];
	
        allTransactions = [NSMutableDictionary dictionary];
        NSError* error = nil;
        NSString* content = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
        if (error) {
            [[MessageLog log] addMessage: @"Error reading HBCI business transactions file" withLevel: LogLevel_Error];
        } else {
            NSArray* entries = [content componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
            for (content in entries) {
                NSArray* values = [content componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\t"]];
                if ([values count] < 2) {
                    continue;
                }
                NSString* abbreviation = [values[0] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\"" ]];
                NSString* description = [values[1] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\"" ]];
                allTransactions[abbreviation] = description;
            }
        }
        
        NSArray* sortedTransactions = [transactions sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)];
        transactionList = [NSMutableArray array];
        for (size_t i = 0; i < [sortedTransactions count]; i++) {
            NSString* description = allTransactions[sortedTransactions[i]];
            if (description == nil) {
                description = NSLocalizedString(@"AP174", "no info");
            }
            [transactionList addObject: @[sortedTransactions[i], description]];
        }
    }
	return self;
}

- (IBAction)copyToPasteboard: (id)sender
{
    NSString *text = @"";
    for (NSArray *entry in transactionList) {
        text = [text stringByAppendingFormat: @"%@\t%@\n", entry[0], entry[1]];
    }

    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString: text forType: NSPasteboardTypeString];
}


- (IBAction)endSheet: (id)sender
{
	[[self window] orderOut: sender];
	[NSApp endSheet: [self window] returnCode: 0];
}

- (NSInteger)numberOfRowsInTableView: (NSTableView *)aTableView
{
    return [transactionList count];
}

- (id)tableView: (NSTableView *)aTableView objectValueForTableColumn: (NSTableColumn *)aTableColumn row: (NSInteger)rowIndex
{
    if ([aTableColumn.identifier isEqualTo: @"abbreviation"]) {
        return transactionList[rowIndex][0];
    } else {
        return transactionList[rowIndex][1];
    }
}

@end
