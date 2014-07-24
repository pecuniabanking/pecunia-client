/**
 * Copyright (c) 2013, 2014, Pecunia Project. All rights reserved.
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

#import "AccountStatementsController.h"
#import "HBCIController.h"
#import "MOAssistant.h"
#import "AccountStatement.h"

@interface AccountStatementsController ()

@end

@implementation AccountStatementsController

@synthesize account;
@synthesize statements;

- (id)init
{
    self = [super initWithWindowNibName: @"AccountStatements"];
    return self;
}

- (void)awakeFromNib
{
    [pdfView setAutoScales: YES];
    [self readStatements];

    if ([statements count] > 0) {
        currentIndex = 0;
        AccountStatement *statement = statements[0];

        PDFDocument *document = [[PDFDocument alloc] initWithData: statement.document];
        [pdfView setDocument: document];
    } else {
        NSString *path = [NSBundle.mainBundle pathForResource: @"nostatements" ofType: @"pdf"];

        NSData      *data = [NSData dataWithContentsOfFile: path];
        PDFDocument *document = [[PDFDocument alloc] initWithData: data];
        [pdfView setDocument: document];
    }
    [self enableButtons];
}

- (void)enableButtons
{
    [nextButton setEnabled: (currentIndex > 0)];
    [prevButton setEnabled: (currentIndex < [statements count] - 1)];
}

- (IBAction)next: (id)sender
{
    if (currentIndex > 0) {
        currentIndex--;
        AccountStatement     *statement = statements[currentIndex];
        PDFDocument          *document = [[PDFDocument alloc] initWithData: statement.document];
        [pdfView setDocument: document];
    }
    [self enableButtons];
}

- (IBAction)prev: (id)sender
{
    if ([statements count] > currentIndex + 1) {
        currentIndex++;
        AccountStatement     *statement = statements[currentIndex];
        PDFDocument          *document = [[PDFDocument alloc] initWithData: statement.document];
        [pdfView setDocument: document];
    }
    [self enableButtons];
}

- (void)windowWillClose: (NSNotification *)aNotification
{
    [NSApp stopModalWithCode: 0];
}

- (void)readStatements
{
    NSManagedObjectContext *context = [[MOAssistant assistant] context];

    // fetch all existing statements for this account
    NSFetchRequest      *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"AccountStatement" inManagedObjectContext: context];
    [fetchRequest setEntity: entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"account = %@", account];
    [fetchRequest setPredicate: predicate];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"startDate" ascending: NO];
    [fetchRequest setSortDescriptors: @[sortDescriptor]];

    NSError *error = nil;
    self.statements = [context executeFetchRequest: fetchRequest error: &error];
}

- (IBAction)updateStatements: (id)sender
{
    [self performSelector: @selector(update) withObject: nil afterDelay: 0.1 inModes: @[NSModalPanelRunLoopMode]];
}

- (void)update
{
    NSManagedObjectContext *context = [[MOAssistant assistant] context];

    AccountStatement *memStatement = [[HBCIController controller] getAccountStatementForAccount: account];
    if (memStatement == nil) {
        return;
    }
    
    NSEntityDescription  *entity = [memStatement entity];
    NSArray              *attributeKeys = [[entity attributesByName] allKeys];
    NSDictionary         *attributeValues = [memStatement dictionaryWithValuesForKeys: attributeKeys];
    AccountStatement     *newStatement = [NSEntityDescription insertNewObjectForEntityForName: @"AccountStatement" inManagedObjectContext: context];
    [newStatement setValuesForKeysWithDictionary: attributeValues];
    newStatement.account = account;
    
    NSError *error = nil;
    if ([context save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }

    // show latest document
    [self readStatements];
    if ([statements count] > 0) {
        currentIndex = 0;
        AccountStatement *statement = statements[0];

        PDFDocument *document = [[PDFDocument alloc] initWithData: statement.document];
        [pdfView setDocument: document];
    }
    [self enableButtons];

}

@end
