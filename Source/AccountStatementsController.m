/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

#import "MOAssistant.h"
#import "AccountStatement.h"
#import "BankAccount.h"
#import "ShortDate.h"
#import "PreferenceController.h"

#import "NSImage+PecuniaAdditions.h"
#import "NSString+PecuniaAdditions.h"

@interface AccountStatementsController ()
{
    IBOutlet PDFView     *pdfView;
    IBOutlet NSTextField *statusField;
    IBOutlet NSTextField *title;
    IBOutlet NSImageView *bankImage;
    IBOutlet NSButton    *clearButton;

    IBOutlet NSSegmentedControl  *toggleButton;
    IBOutlet NSProgressIndicator *spinner;

    NSUInteger currentIndex;
    BOOL       messagesShown;
    NSArray    *statements;
    NSFont     *boldFont;
    NSFont     *normalFont;

    NSDateFormatter         *dateFormatter;
    NSMutableParagraphStyle *rightAlignParagraphStyle;

}
@end

@implementation AccountStatementsController

@synthesize account;

- (id)init {
    self = [super initWithWindowNibName: @"AccountStatements"];
    if (self != nil) {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateStyle = kCFDateFormatterShortStyle;

        boldFont = [NSFont fontWithName: PreferenceController.mainFontNameBold size: 13];
        normalFont = [NSFont fontWithName: PreferenceController.mainFontName size: 13];

        rightAlignParagraphStyle = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
        rightAlignParagraphStyle.alignment = NSRightTextAlignment;
    }
    return self;
}

- (void)awakeFromNib {
    title.stringValue = [NSString stringWithFormat: @"%@ - %@", account.bankName, account.name];
    bankImage.image = [NSImage imageNamed: @"icon95-1" fromCollection: 1];
    clearButton.image = [NSImage imageNamed: @"icon66-1" fromCollection: 1];

    [self readStatements];
    [self updateDisplayIncludingStatus: YES];
}

- (void)timedUpdate {
    [self updateDisplayIncludingStatus: YES];
}

- (void)updateDisplayIncludingStatus: (BOOL)withStatus {
    if (statements.count > 0) {
        AccountStatement *statement = statements[currentIndex];

        PDFDocument *document = [[PDFDocument alloc] initWithData: statement.document];
        [pdfView setDocument: document];

        if (withStatus) {
            NSString *startDate = [dateFormatter stringFromDate: statement.startDate];
            NSString *endDate = [dateFormatter stringFromDate: statement.endDate];
            unsigned year = [ShortDate dateWithDate: statement.startDate].year;

            NSDictionary *attributes = @{
                NSFontAttributeName: normalFont,
                NSParagraphStyleAttributeName: rightAlignParagraphStyle
            };

            NSString *text = [NSString stringWithFormat: NSLocalizedString(@"AP832", nil), statement.number.intValue, year, startDate, endDate];
            statusField.attributedStringValue = [[NSAttributedString alloc] initWithString: text attributes: attributes];
        }
    } else {
        NSString *path = [NSBundle.mainBundle pathForResource: @"nostatements" ofType: @"pdf"];

        NSData      *data = [NSData dataWithContentsOfFile: path];
        PDFDocument *document = [[PDFDocument alloc] initWithData: data];
        [pdfView setDocument: document];

        if (withStatus) {
            statusField.stringValue = @"";
        }
    }
    [self updateNavigationButtons];
}

- (void)readStatements {
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];

    // fetch all existing statements for this account
    NSFetchRequest      *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"AccountStatement" inManagedObjectContext: context];
    [fetchRequest setEntity: entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"account = %@", account];
    [fetchRequest setPredicate: predicate];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"startDate" ascending: NO];
    [fetchRequest setSortDescriptors: @[sortDescriptor]];

    NSError *error = nil;
    statements = [context executeFetchRequest: fetchRequest error: &error];
    currentIndex = 0;
}

- (void)removeAllStatements {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

    for (AccountStatement *statement in statements) {
        [context deleteObject: statement];
    }
    [context save: nil];
    statements = nil;

    NSString *path = [NSBundle.mainBundle pathForResource: @"nostatements" ofType: @"pdf"];

    NSData      *data = [NSData dataWithContentsOfFile: path];
    PDFDocument *document = [[PDFDocument alloc] initWithData: data];
    [pdfView setDocument: document];
    statusField.stringValue = @"";

    [self updateNavigationButtons];
    currentIndex = -1;
}

- (void)updateNavigationButtons {
    [toggleButton setEnabled: (currentIndex + 1 < statements.count) forSegment: 0];
    [toggleButton setEnabled: (currentIndex > 0) forSegment: 1];
}

- (void)windowWillClose: (NSNotification *)aNotification {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [NSApp stopModalWithCode: 0];
}

- (void)setProgress: (NSString *)message number: (int)number year: (int)year {
    NSDictionary *attributes = @{
        NSFontAttributeName: boldFont,
    };

    NSString *text = [NSString stringWithFormat: message, number, year];
    statusField.attributedStringValue = [[NSAttributedString alloc] initWithString: text attributes: attributes];
    [statusField display];
}

/**
 * Retrieves all currently available statements from the given account that are newer than the latest one stored already.
 * If there's no statement yet everything is retrieved.
 */
- (void)retrieveStatements {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

    [spinner setHidden: NO];
    [spinner startAnimation: self];

    int  currentYear = ShortDate.currentDate.year;
    int  year = currentYear;
    int  number = 2; // If we have no start value then the check for the first document is already done in the loop.
    BOOL haveStart = NO;

    // If there are already statements get a start value from the latest which we can use to find new statements.
    if (statements.count > 0) {
        AccountStatement *statement = statements[0];
        if (statement.number != nil) {
            ShortDate *date = [ShortDate dateWithDate: statement.startDate];
            year = date.year;
            number = statement.number.intValue + 1;
            haveStart = YES;
        }
    }

    // For the algorithm to work we assume that all statements are consistently numbered without any omission.
    if (!haveStart) {
        NSMutableSet *foundYears = [NSMutableSet new];

        // Try to find a start year by sending a request for the first statement for this and any previous year
        // until we fail to get it.
        while (true) {
            // The returned statement is always valid, but contains no values if there's no data returned from the bank.
            [self setProgress: NSLocalizedString(@"AP831", nil) number: 1 year: year];
            AccountStatement *statement = [HBCIBackend.backend getAccountStatement: 1 year: year bankAccount: account];

            // If there's no first document for a year then we have found something to start from. Except it fails for
            // the current year. In that case it could be that there's no document yet. Try the previous year too then.
            if ((statement == nil || statement.document == nil) && year < currentYear) {
                break;
            }

            // Keep a list of years we found a first statement for to ease later forward stepping.
            if (year < currentYear) {
                [foundYears addObject: @(year)];
            }
            --year;
        }

        // Now go forward until we get a statement (but not further than the current year).
        // From there go on until there's no more statement.
        // We are in a dilemma here, however, as we don't have a count of statements per year or at least overall.
        // As an arbitrary maximum count per year we use 104 (twice a week). That should be fairly enough.
        while (true) {
            [self setProgress: NSLocalizedString(@"AP831", nil) number: number year: year];
            AccountStatement *statement = [HBCIBackend.backend getAccountStatement: number year: year bankAccount: account];
            if (statement == nil || statement.document != nil) {
                break;
            }
            if (++number > 104) {
                number = 1;
                ++year;
                if (year > currentYear) {
                    [spinner stopAnimation: self]; // No statements at all.
                    [spinner setHidden: YES];
                    [self setProgress: NSLocalizedString(@"AP828", nil) number: 0 year: 0];
                    [self performSelector: @selector(timedUpdate) withObject: nil afterDelay: 5 inModes: @[NSModalPanelRunLoopMode]];
                    return;
                }
            }
        }
    }

    // Here we have the year and number for the first available statement. Now read all available statements.
    NSError *error = nil;
    int     count = 0;
    while (year <= currentYear) {
        // Read the next statement. It will be placed into our memory store.
        // Below we create a persistent instance from it in our main store.
        [self setProgress: NSLocalizedString(@"AP834", nil) number: number year: year];
        AccountStatement *statement = [HBCIBackend.backend getAccountStatement: number year: year bankAccount: account];
        if (statement == nil || statement.document == nil) {
            // We either went beyond the available documents for the year or there's no more at all.
            // Try with the next year to decide.
            if (year < currentYear) {
                number = 1;
                ++year;
                continue;
            } else {
                break;
            }
        } else {
            ++number;
            ++count;
        }

        if (statement) {
            // Now insert a new instance in our main store.
            NSEntityDescription *entity = statement.entity;
            
            NSArray      *attributeKeys = entity.attributesByName.allKeys;
            NSDictionary *attributeValues = [statement dictionaryWithValuesForKeys: attributeKeys];
            
            AccountStatement *newStatement = [NSEntityDescription insertNewObjectForEntityForName: @"AccountStatement" inManagedObjectContext: context];
            
            newStatement.valuesForKeysWithDictionary = attributeValues;
            newStatement.account = account;
        }
    }
    switch (count) {
        case 0:
            [self setProgress: NSLocalizedString(@"AP828", nil) number: 0 year: 0];
            break;
        case 1:
            [self setProgress: NSLocalizedString(@"AP830", nil) number: 1 year: 0];
            break;
        default:
            [self setProgress: NSLocalizedString(@"AP829", nil) number: count year: 0];
            break;
    }
    [self performSelector: @selector(timedUpdate) withObject: nil afterDelay: 5 inModes: @[NSModalPanelRunLoopMode]];

    error = nil;
    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }

    // Show the latest document.
    [self readStatements];
    [self updateDisplayIncludingStatus: NO];

    [spinner stopAnimation: self];
    [spinner setHidden: YES];

    BOOL suppressSound = [NSUserDefaults.standardUserDefaults boolForKey: @"noSoundAfterSync"];
    if (!suppressSound) {
        NSSound *doneSound = [NSSound soundNamed: @"done.mp3"];
        if (doneSound != nil) {
            [doneSound play];
        }
    }
}

#pragma mark - Action handling

- (IBAction)close: (id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [[self window] orderOut: self];
    [NSApp stopModalWithCode: 0];
}

- (IBAction)clear: (id)sender {
    int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP833", nil),
                                      NSLocalizedString(@"AP827", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      nil
                                      );
    if (res != NSAlertAlternateReturn) {
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [self removeAllStatements];
}

- (IBAction)togglePage: (id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    if ([sender isSelectedForSegment: 0]) {
        // One page back.
        if (currentIndex < statements.count - 1) {
            currentIndex++;
            [self updateDisplayIncludingStatus: YES];
        }
    } else {
        // One page forward.
        if (currentIndex > 0) {
            currentIndex--;
            [self updateDisplayIncludingStatus: YES];
        }
    }
}

- (IBAction)updateStatements: (id)sender {
    
    // which format?
    AccountStatementParameters *params = [HBCIBackend.backend getAccountStatementParametersForUser:account.defaultBankUser];
    if (params == nil) {
        return;
    }
    if ([params supportsFormat:AccountStatement_PDF] || [params supportsFormat:AccountStatement_MT940]) {
        [self performSelector: @selector(retrieveStatements) withObject: nil afterDelay: 0.1 inModes: @[NSModalPanelRunLoopMode]];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedString(@"AP83", nil)
                                         defaultButton: NSLocalizedString(@"AP1", nil)
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"AP840", nil) ];
        [alert runModal];
    }
    
}

- (IBAction)zoomIn: (id)sender {
    pdfView.scaleFactor *= 1.2;
}

- (IBAction)zoomOut: (id)sender {
    pdfView.scaleFactor /= 1.2;
}

@end
