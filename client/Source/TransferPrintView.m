//
//  TransferPrintView.m
//  Pecunia
//
//  Created by Frank Emminghaus on 31.08.12.
//  Copyright (c) 2012 Frank Emminghaus. All rights reserved.
//

#import "TransferPrintView.h"
#import "Transfer.h"
#import "TransfersListViewCell.h"
#import "BankAccount.h"

extern NSString *StatementDateKey;
extern NSString *StatementTurnoversKey;
extern NSString *StatementRemoteNameKey;
extern NSString *StatementPurposeKey;
extern NSString *StatementCategoriesKey;
extern NSString *StatementValueKey;
extern NSString *StatementSaldoKey;
extern NSString *StatementCurrencyKey;
extern NSString *StatementTransactionTextKey;
extern NSString *StatementIndexKey;
extern NSString *StatementNoteKey;
extern NSString *StatementRemoteBankNameKey;
extern NSString *StatementColorKey;
extern NSString *StatementRemoteAccountKey;
extern NSString *StatementRemoteBankCodeKey;
extern NSString *StatementRemoteIBANKey;
extern NSString *StatementRemoteBICKey;
extern NSString *StatementTypeKey;


@implementation TransferPrintView

@synthesize transfers;

- (id)initWithTransfers:(NSArray*)transfersToPrint printInfo:(NSPrintInfo*)pi
{
	paperSize = [pi paperSize ];
	topMargin = [pi topMargin ];
	bottomMargin = [pi bottomMargin ];
	leftMargin = [pi leftMargin ];
	rightMargin = [pi rightMargin ];
	purposeWidth = paperSize.width - leftMargin - rightMargin - 320;
	pageHeight = paperSize.height - topMargin - bottomMargin;
	pageWidth = paperSize.width - leftMargin - rightMargin;
	dateWidth = 37;
	amountWidth = 65;
	purposeWidth = pageWidth - dateWidth - 3*amountWidth;
	padding = 3;
	currentPage = 1;
	
    self.transfers = [transfersToPrint mutableCopy];
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[self.transfers sortUsingDescriptors:sds ];
    
	statHeights = (int*)malloc([self.transfers count ]*sizeof(int));
	
	dateFormatter = [[NSDateFormatter alloc ] init ];
	[dateFormatter setDateFormat: @"dd.MM." ];
	
	numberFormatter = [[NSNumberFormatter alloc ] init ];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle ];
	[numberFormatter setMinimumFractionDigits:2 ];
	
	debitNumberFormatter = [numberFormatter copy ];
	[debitNumberFormatter setMinusSign:@"" ];
    
	NSRect frame;
	
	frame.origin.x = 0;
	frame.origin.y = 0;
    frame.size.height = 0;
	frame.size.width = pageWidth;
	    
    // transfer cell
    NSNib *cellNib = [[NSNib alloc] initWithNibNamed:@"TransfersListViewCell" bundle:nil];
    NSArray *objects = nil;
    
    [cellNib instantiateNibWithOwner:nil topLevelObjects:&objects];
    for(id object in objects) {
        if([object isKindOfClass:[TransfersListViewCell class]]) {
            cell = object;
            break;
        }
    }
    [cellNib release];


    self = [super initWithFrame:frame];
    if (self) {
		int height = [self.transfers count] * cell.frame.size.height;
		if(height > pageHeight) frame.size.height = height; else frame.size.height = pageHeight;
		[self setFrame:frame ];
    }

    return self;
}

- (id)safeAndFormattedValue: (id)value
{
    if (value == nil || [value isKindOfClass: [NSNull class]])
        value = @"";
    else
    {
        if ([value isKindOfClass: [NSDate class]]) {
            value = [dateFormatter stringFromDate: value];
        }
    }
    
    return value;
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    NSRect drawRect =dirtyRect;
    drawRect.size.height = cell.frame.size.height;
    int row = 0;
    for (Transfer *transfer in self.transfers) {
        NSDate *date = transfer.valutaDate;
        if (date == nil) {
            date = transfer.date;
        }
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt: row], StatementIndexKey,
                                 [self safeAndFormattedValue: date], StatementDateKey,
                                 [self safeAndFormattedValue: transfer.remoteName], StatementRemoteNameKey,
                                 [self safeAndFormattedValue: transfer.purpose], StatementPurposeKey,
                                 [self safeAndFormattedValue: transfer.value], StatementValueKey,
                                 [self safeAndFormattedValue: transfer.currency], StatementCurrencyKey,
                                 [self safeAndFormattedValue: transfer.remoteBankName], StatementRemoteBankNameKey,
                                 [self safeAndFormattedValue: transfer.remoteBankCode], StatementRemoteBankCodeKey,
                                 [self safeAndFormattedValue: transfer.remoteIBAN], StatementRemoteIBANKey,
                                 [self safeAndFormattedValue: transfer.remoteBIC], StatementRemoteBICKey,
                                 [self safeAndFormattedValue: transfer.remoteAccount], StatementRemoteAccountKey,
                                 [self safeAndFormattedValue: transfer.type], StatementTypeKey,
                                 [transfer.account categoryColor], StatementColorKey,
                                 nil];
        
        [cell setDetails: details];
        row++;
        [cell drawRect:drawRect];
        drawRect.origin.y -= cell.frame.size.height;
        
    }
}

@end
