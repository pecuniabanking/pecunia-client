//
//  CallbackHandler.m
//  Pecunia
//
//  Created by Emminghaus, Frank on 09.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import "CallbackHandler.h"
#import "CallbackData.h"
#import "Keychain.h"
#import "PasswordWindow.h"
#import "Keychain.h"
#import "TanMethodOld.h"
#import "TanMethod.h"
#import "PasswordWindow.h"
#import "NewPasswordController.h"
#import "TanMethodListController.h"
#import "PecuniaError.h"
#import "LogController.h"
#import "ChipTanWindowController.h"
#import "TanMediaWindowController.h"
#import "HBCIBackend.h"
#import "BankUser.h"
#import "TanMedium.h"
#import "TanSigningOption.h"

@implementation CallbackHandler
@synthesize currentSignOptions;

-(void)startSession
{
	self.currentSignOptions = [NSMutableDictionary dictionaryWithCapacity:10 ];
	errorOccured = NO;
}

-(NSString*)getPassword
{
    currentPwService = @"Pecunia";
    currentPwAccount = @"DataFile";
    NSString* passwd = [Keychain passwordForService: currentPwService account: currentPwAccount ];
    if(passwd == nil) {
        if(pwWindow == nil) {
            pwWindow = [[PasswordWindow alloc] initWithText: NSLocalizedString(@"AP54", @"")
                                                      title: NSLocalizedString(@"AP53", @"")];
            
        } else [pwWindow retry ];
        
        int res = [NSApp runModalForWindow: [pwWindow window]];
        if(res) [NSApp terminate: self ];
        
        passwd = [pwWindow result];
    }
    if(passwd == nil || [passwd length ] == 0) return @"<abort>";
    return passwd;
}

-(void)finishPasswordEntry
{
	if (pwWindow) {
		if(errorOccured == NO) {
			NSString *passwd = [pwWindow result];
			BOOL savePassword = [pwWindow shouldSavePassword ];
			[Keychain setPassword:passwd forService:currentPwService account:currentPwAccount store:savePassword ];
		}
		[pwWindow close ];
		[pwWindow release ];
		pwWindow = nil;
	}
}

-(NSString*)getNewPassword: (CallbackData*)data
{
    NSString* passwd = [Keychain passwordForService: @"Pecunia" account: @"DataFile" ];
    if(passwd) return passwd;
    NewPasswordController *pwController = [[NewPasswordController alloc] initWithText: data.message
                                                                                title: @"Bitte Passwort eingeben" ];
    int res = [NSApp runModalForWindow: [pwController window]];
    if(res) {
        [pwController release ];
        return @"<abort>";
    }
    passwd = [pwController result ];
    [pwController autorelease ];
    
    [Keychain setPassword:passwd forService:@"Pecunia" account:@"DataFile" store:NO ];
    return passwd;
}

-(NSString*)getTanMethod: (CallbackData*)data
{
	BankUser *user = [BankUser userWithId:data.userId bankCode:data.bankCode ];
	if (user.preferredTanMethod != nil) {
		return user.preferredTanMethod.method;
	}
	
	TanSigningOption *option = [currentSignOptions objectForKey:user ];
	if (option) {
		return option.tanMethod;
	}
	
	
    NSMutableArray *tanMethods = [NSMutableArray arrayWithCapacity: 5 ];
    NSArray *meths = [data.proposal componentsSeparatedByString: @"|" ];
    NSString *meth;
    for(meth in meths) {
        TanMethodOld *tanMethod = [[[TanMethodOld alloc ] init ] autorelease ];
        NSArray *list = [meth componentsSeparatedByString: @":" ];
        tanMethod.function = [NSNumber numberWithInteger:[[list objectAtIndex:0 ] integerValue ] ];
        tanMethod.description = [list objectAtIndex:1 ];
        [tanMethods addObject: tanMethod ];
    }
    
    TanMethodListController *controller = [[[TanMethodListController alloc] initWithMethods: tanMethods] autorelease];
    int res = [NSApp runModalForWindow: [controller window]];
    if(res) {
        return @"<abort>";
    }
    NSString *method = [[controller selectedMethod ] stringValue ];
	
	option = [[[TanSigningOption alloc ] init ] autorelease ];
	option.tanMethod = method;
	if (self.currentSignOptions) [currentSignOptions setObject:option forKey:user ];
    return method;
}

-(NSString*)getPin:(CallbackData*)data
{
    currentPwService = @"Pecunia PIN";
    NSString *s = [NSString stringWithFormat: @"PIN_%@_%@", data.bankCode, data.userId ];
    if (![s isEqualToString: currentPwAccount]) {
        if(pwWindow) [self finishPasswordEntry ];
        [currentPwAccount release ];
        currentPwAccount = [s retain ];
    }
    
    NSString* passwd;
    // Check keychain
    passwd = [Keychain passwordForService: currentPwService account: currentPwAccount ];
    if(passwd) return passwd;
    
    if(pwWindow == nil) {
        pwWindow = [[PasswordWindow alloc] initWithText: [NSString stringWithFormat: NSLocalizedString(@"AP96", @""), data.userId ]
                                                  title: @"Bitte PIN eingeben" ];
        
    } else [pwWindow retry ];
    
    int res = [NSApp runModalForWindow: [pwWindow window]];
    if(res == 0) {
        return [pwWindow result];
    } else return @"<abort>";
}

-(NSString*)getTan:(CallbackData*)data
{
    if (data.proposal && [data.proposal length ] > 0) {
        // FlickerCode
        ChipTanWindowController *controller = [[[ChipTanWindowController alloc] initWithCode: data.proposal message: data.message] autorelease];
        int res = [NSApp runModalForWindow:[controller window ] ];
        if (res == 0) {
            return [controller tan ];
        } else return  @"<abort>";
    }
    
    
    PasswordWindow *tanWindow = [[[PasswordWindow alloc] initWithText: [NSString stringWithFormat: NSLocalizedString(@"AP98", @""), data.userId, data.message]
                                                                title: @"Bitte TAN eingeben" ] autorelease];
    [tanWindow disablePasswordSave ];
    int res = [NSApp runModalForWindow: [tanWindow window]];
    [tanWindow close ];
    if(res == 0) {
        return [tanWindow result];
    } else return @"<abort>";
}

-(NSString*)getTanMedia:(CallbackData*)data
{
	BankUser *user = [BankUser userWithId:data.userId bankCode:data.bankCode ];
	if (user.preferredTanMethod != nil) {
		if (user.preferredTanMethod.preferredMedium != nil) {
			return user.preferredTanMethod.preferredMedium.name;
		}
	}
	
	TanSigningOption *option = [currentSignOptions objectForKey:user ];
	if (option && option.tanMediumName != nil) {
		return option.tanMediumName;
	}
	
    TanMediaWindowController *mediaWindow = [[[TanMediaWindowController alloc] initWithUser: data.userId bankCode: data.bankCode message: data.message] autorelease];
    int res = [NSApp runModalForWindow: [mediaWindow window]];
    if(res == 0) {
		if (option) {
			option.tanMediumName = mediaWindow.tanMedia;
		}
        return mediaWindow.tanMedia;
    } else return @"<abort>";
}


-(NSString*)callbackWithData:(CallbackData*)data
{
    if([data.command isEqualToString: @"password_load" ]) {
        NSString *passwd = [self getPassword ];
        return passwd;
    }
    if([data.command isEqualToString: @"password_save" ]) {
        NSString *passwd = [self getNewPassword: data ];
        return passwd;
    }
    if([data.command isEqualToString: @"getTanMethod" ]) {
        return [self getTanMethod: data ];
    }
    if([data.command isEqualToString: @"getPin" ]) {
        return [self getPin: data ];
    }
    if([data.command isEqualToString: @"getTan" ]) {
        return [self getTan: data ];
    }
    if([data.command isEqualToString: @"getTanMedia" ]) {
        return [self getTanMedia: data ];
    }
    if ([data.command isEqualToString:@"instMessage" ]) {
        NSNotification *notification = [NSNotification notificationWithName:PecuniaInstituteMessageNotification 
                                                                     object:[NSDictionary dictionaryWithObjectsAndKeys:data.bankCode, @"bankCode", data.message, @"message", nil ] ];
        [[NSNotificationCenter defaultCenter ] postNotification:notification ];
    }
    if ([data.command isEqualToString:@"needChipcard" ]) {
        MessageLog *log = [MessageLog log ];
        [log addMessage:NSLocalizedString(@"AP350", @"") withLevel:LogLevel_Info ];
    }
    if ([data.command isEqualToString:@"haveChipcard" ]) {
    }
    
    return @"";
}

-(void)setErrorOccured
{
	errorOccured = YES;
}


@end
