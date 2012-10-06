//
//  BSSelectWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 02.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "BSSelectWindowController.h"
#import "BankAccount.h"
#import "BankingController.h"
#import "MOAssistant.h"
#import "BankStatement.h"
#import "StatusBarController.h"
#import "BankQueryResult.h"
#import "MessageLog.h"

@implementation BSSelectWindowController

-(id)initWithResults: (NSArray*)list
{
	self = [super initWithWindowNibName:@"BSSelectWindow"];
	resultList = [list retain];
	return self;
}

-(void)awakeFromNib
{
	// green color for statements view
	NSTableColumn *tc = [statementsView tableColumnWithIdentifier: @"value" ];
	if(tc) {
		NSCell	*cell = [tc dataCell ];
		NSNumberFormatter	*form = [cell formatter ];
		if(form) {
			NSDictionary *newAttrs = [NSDictionary dictionaryWithObjectsAndKeys: 
									  [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100], @"NSColor", nil ];
			[form setTextAttributesForPositiveValues: newAttrs ];
		}
	}
	
	// sort descriptor for statements view
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[statementsView setSortDescriptors: sds ];
}

-(void)windowDidLoad
{
	NSMutableArray *statements = [NSMutableArray arrayWithCapacity: 100 ];
	BankQueryResult *result;
	
	for(result in resultList) [statements addObjectsFromArray: result.statements ];
	[statController setContent: statements ];
	[[self window ] center ];
	[[self window ] makeKeyAndOrderFront: self ];
}

-(IBAction)ok: (id)sender
{
	int count = 0;
	
	BankQueryResult *result;

    @try {
        for(result in resultList) {
          count += [result.account updateFromQueryResult: result ];  
        }
    }
    @catch (NSException * e) {
        [[MessageLog log ] addMessage:e.reason withLevel:LogLevel_Error];
    }
	[[BankingController controller ] requestFinished: resultList ];

	// status message
	StatusBarController *sc = [StatusBarController controller ];
	[sc setMessage: [NSString stringWithFormat: NSLocalizedString(@"AP80", @""), count ] removeAfter:120 ];

	[[self window ] close ];
}

-(IBAction)cancel: (id)sender
{
	[[BankingController controller ] requestFinished: nil ];
	[[self window ] close ];
}

-(void)dealloc
{
	[resultList release ];
	[super dealloc ];
}


@end
