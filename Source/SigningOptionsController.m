//
//  SigningOptionsController.m
//  SigningOptions
//
//  Created by Frank Emminghaus on 06.08.12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "SigningOptionsController.h"
#import "SigningOptionsViewCell.h"
#import "SigningOption.h"
#import "BankAccount.h"
#import "User.h"

@implementation SigningOptionsController

-(id)initWithSigningOptions:(NSArray*)opts forAccount:(BankAccount*)acc
{
    self = [super initWithWindowNibName:@"SigningOptions" ];
    
    options = opts;
    accountNumber = acc.accountNumber;
    return self;
}

-(void)awakeFromNib
{
    NSTableColumn* column = [[optionsView tableColumns] objectAtIndex:0];
    SigningOptionsViewCell* cell = [[SigningOptionsViewCell alloc] init];
    [column setDataCell: cell];
/*    
    NSMutableArray *options = [NSMutableArray arrayWithCapacity:10 ];
    SigningOption *option = [[[SigningOption alloc ] init ] autorelease ];
    option.userName = @"User 1";
    option.secMethod = SecMethod_PinTan;
    option.tanMethodName = @"SmartTan optisch";
    option.tanMediumCategory = @"G";
    option.tanMediumName = @"Frank1";
    [options addObject:option ];
    option = [[[SigningOption alloc ] init ] autorelease ];
    option.userName = @"User 2";
    option.secMethod = SecMethod_PinTan;
    option.tanMethodName = @"mTAN";
    option.tanMediumCategory = @"M";
    option.tanMediumName = @"47998092342";
    [options addObject:option ];
    option = [[[SigningOption alloc ] init ] autorelease ];
    option.userName = @"User 2";
    option.secMethod = SecMethod_DDV;
    option.cardId = @"4562348875234";
    [options addObject:option ];
*/    
    [optionsController setContent:options ];
}

-(SigningOption*)selectedOption
{
    NSArray *sel = [optionsController selectedObjects ];
    return [sel lastObject ];
}


-(IBAction)ok:(id)sender
{
    [[self window ] close ];
    [NSApp stopModalWithCode:0 ];
}

-(IBAction)cancel:(id)sender
{
    [[self window ] close ];
    [NSApp stopModalWithCode:1 ];    
}

@end
