//
//  AccountSettingsController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "AccountSettingsController.h"
#import "BankingController.h"

@implementation AccountSettingsController

-(id)init
{
	self = [super initWithWindowNibName:@"AccountSettings"];
	managedObjectContext = [[BankingController controller] managedObjectContext ];
	return self;
}


@end
