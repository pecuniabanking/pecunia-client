/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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
#import "NotificationWindowController.h"
#import "TanWindow.h"

static CallbackHandler *callbackHandler = nil;

@implementation CallbackHandler
@synthesize currentSigningOption;
@synthesize notificationController;

-(void)startSession
{
	errorOccured = NO;
}

-(NSString*)getPassword
{
    currentPwService = @"Pecunia";
    currentPwAccount = @"DataFile";
    NSString* passwd = [Keychain passwordForService: currentPwService account: currentPwAccount ];
    if(passwd == nil) {
        if(pwWindow == nil) {
            pwWindow = [[PasswordWindow alloc] initWithText: NSLocalizedString(@"AP163", nil)
                                                      title: NSLocalizedString(@"AP162", nil)];
            
        } else [pwWindow retry ];
        
        int res = [NSApp runModalForWindow: [pwWindow window]];
        if(res) {
            passwd = nil;
        } else {
            passwd = [pwWindow result];
        }
        [pwWindow closeWindow];
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
        errorOccured = YES;
        return @"<abort>";
    }
    passwd = [pwController result];
    
    [Keychain setPassword:passwd forService:@"Pecunia" account:@"DataFile" store:NO ];
    return passwd;
}

-(NSString*)getTanMethod: (CallbackData*)data
{
	if (self.currentSigningOption && self.currentSigningOption.tanMethod) {
		return self.currentSigningOption.tanMethod;
	}

	// alter Code, sollte eigentlich nicht durchlaufen werden. Bleibt drin als Fallback
	BankUser *user = [BankUser userWithId:data.userId bankCode:data.bankCode ];
	if (user.preferredTanMethod != nil) {
		return user.preferredTanMethod.method;
	}
	
    NSMutableArray *tanMethods = [NSMutableArray arrayWithCapacity: 5 ];
    NSArray *meths = [data.proposal componentsSeparatedByString: @"|" ];
    NSString *meth;
    for(meth in meths) {
        TanMethodOld *tanMethod = [[TanMethodOld alloc ] init ];
        NSArray *list = [meth componentsSeparatedByString: @":" ];
        tanMethod.function = @([list[0] integerValue ]);
        tanMethod.description = list[1];
        [tanMethods addObject: tanMethod ];
    }
    
    TanMethodListController *controller = [[TanMethodListController alloc] initWithMethods: tanMethods];
    int res = [NSApp runModalForWindow: [controller window]];
    if(res) {
        return @"<abort>";
    }
    NSString *method = [[controller selectedMethod ] stringValue ];
	
    return method;
}

-(NSString*)getPin:(CallbackData*)data
{
    currentPwService = @"Pecunia PIN";
    NSString *s = [NSString stringWithFormat: @"PIN_%@_%@", data.bankCode, data.userId ];
    if (![s isEqualToString: currentPwAccount]) {
        if(pwWindow) [self finishPasswordEntry ];
        currentPwAccount = s;
    }
    
    NSString* passwd;
    // Check keychain
    passwd = [Keychain passwordForService: currentPwService account: currentPwAccount ];
    if(passwd) return passwd;
    
    if(pwWindow == nil) {
        pwWindow = [[PasswordWindow alloc] initWithText: [NSString stringWithFormat: NSLocalizedString(@"AP171", nil), data.userId ]
                                                  title: @"Bitte PIN eingeben" ];
        
    } else [pwWindow retry ];
    int res = [NSApp runModalForWindow: [pwWindow window]];
    [pwWindow closeWindow];
    if(res == 0) {
        return [pwWindow result];
    } else {
        errorOccured = YES; // don't save PIN
        return @"<abort>";
    }
}

-(void)removePin:(CallbackData*)data
{
    currentPwService = @"Pecunia PIN";
    NSString *s = [NSString stringWithFormat: @"PIN_%@_%@", data.bankCode, data.userId ];
    [Keychain deletePasswordForService:@"Pecunia PIN" account:s];
    errorOccured = YES;
}

-(NSString*)getTan:(CallbackData*)data
{
    if (data.proposal && [data.proposal length ] > 0) {
        // FlickerCode
        ChipTanWindowController *controller = [[ChipTanWindowController alloc] initWithCode: data.proposal message: data.message];
        int res = [NSApp runModalForWindow:[controller window ] ];
        if (res == 0) {
            return [controller tan ];
        } else return  @"<abort>";
    }
    
    TanWindow *tanWindow = [[TanWindow alloc] initWithText: [NSString stringWithFormat: NSLocalizedString(@"AP172", nil), data.userId, data.message]];
    int res = [NSApp runModalForWindow: [tanWindow window]];
    [tanWindow close ];
    if(res == 0) {
        return [tanWindow result];
    } else return @"<abort>";
}

-(NSString*)getTanMedia:(CallbackData*)data
{
    if (self.currentSigningOption && self.currentSigningOption.tanMediumName) {
		return self.currentSigningOption.tanMediumName;
	}
    
    TanMediaWindowController *mediaWindow = [[TanMediaWindowController alloc] initWithUser: data.userId bankCode: data.bankCode message: data.message];
    int res = [NSApp runModalForWindow: [mediaWindow window]];
    if(res == 0) {
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
                                                                     object:@{@"bankCode": data.bankCode, @"message": data.message} ];
        [[NSNotificationCenter defaultCenter ] postNotification:notification ];
    }
    if ([data.command isEqualToString:@"needChipcard" ]) {
        notificationController = [[NotificationWindowController alloc ] initWithMessage:NSLocalizedString(@"AP350", nil)
                                                                                  title:NSLocalizedString(@"AP357", nil) ];
        [notificationController showWindow:self ];
        //[self performSelector:@selector(showNotificationWindow) withObject:nil afterDelay:0.5 ];
    }
    if ([data.command isEqualToString:@"haveChipcard" ]) {
        [[notificationController window ] close ];
        notificationController = nil;
    }
    
    if ([data.command isEqualToString:@"needHardPin" ]) {
        notificationController = [[NotificationWindowController alloc ] initWithMessage:NSLocalizedString(@"AP351", nil)
                                                                                  title:NSLocalizedString(@"AP357", nil) ];
        [notificationController showWindow:self ];
    }
    if ([data.command isEqualToString:@"haveHardPin" ]) {
        [[notificationController window ] close ];
        notificationController = nil;
    }
    if ([data.command isEqualToString:@"wrongPin" ]) {
        [self removePin:data];
    }
    
    return @"";
}

-(void)showNotificationWindow
{
    [notificationController showWindow:self ];
    [[notificationController window] makeKeyAndOrderFront:self];
}

-(void)setErrorOccured
{
	errorOccured = YES;
}

+(CallbackHandler*)handler
{
    if (callbackHandler == nil) {
        callbackHandler = [[CallbackHandler alloc ] init ];
    }
    return callbackHandler;
}



@end
