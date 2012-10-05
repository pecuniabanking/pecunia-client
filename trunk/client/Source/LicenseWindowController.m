//
//  LicenseWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 05.09.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import "LicenseWindowController.h"


@implementation LicenseWindowController

- (void)awakeFromNib
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"gpl-2.0-standalone" withExtension:@"html"];
    NSAttributedString *as = [[NSAttributedString alloc ] initWithURL:url documentAttributes:NULL];
    [[licenseView textStorage ] appendAttributedString:as];
    
    //NSString *path = [[NSBundle mainBundle] pathForResource: @"gpl-2.0-standalone" ofType: @"html"];
    
}

- (IBAction)accept:(id)sender
{
    [ window close ];
    [NSApp stopModalWithCode:0 ];
}

- (IBAction)decline:(id)sender
{
    [ window close ];
    [NSApp stopModalWithCode:1 ];    
}

- (void)windowWillClose:(NSNotification*)aNotification
{
	[NSApp stopModalWithCode:1 ];    
}



@end
