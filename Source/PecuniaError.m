//
//  PecuniaError.m
//  Pecunia
//
//  Created by Frank Emminghaus on 15.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "PecuniaError.h"
#import "MessageLog.h"

@implementation PecuniaError
@synthesize title;

+(NSError*)errorWithText: (NSString*)msg
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1 ];
	if(msg) [userInfo setObject: msg forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:@"de.pecuniabanking.ErrorDomain" code:1 userInfo:userInfo];
}

+(PecuniaError*)errorWithCode:(ErrorCode)code message:(NSString*)msg
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1 ];
	if(msg) [userInfo setObject: msg forKey:NSLocalizedDescriptionKey];
	PecuniaError *error = [[PecuniaError alloc ] initWithDomain: @"de.pecuniabanking.ErrorDomain" code:code userInfo:userInfo ];
	return error;
}

+(PecuniaError*)errorWithMessage:(NSString*)msg title:(NSString*)title
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1 ];
	if(msg) [userInfo setObject: msg forKey:NSLocalizedDescriptionKey];
	PecuniaError *error = [[PecuniaError alloc ] initWithDomain: @"de.pecuniabanking.ErrorDomain" code:err_gen userInfo:userInfo ];
    if (title) error.title = title;
	return error;    
}


-(void)alertPanel
{
	// HBCI Errors
	if(self.code < err_gen && self.title == nil) self.title = NSLocalizedString(@"AP7", @"HBCI error occured!");

	NSString *message = nil;
	switch(self.code) {
		case err_hbci_abort : message = NSLocalizedString(@"AP93", @"User abort"); break;
		case err_hbci_gen   : message = [self localizedDescription ]; break;
		case err_hbci_passwd: message = NSLocalizedString(@"AP94", @"The password entered was wrong"); break;
		case err_hbci_param : message = [NSString stringWithFormat: NSLocalizedString(@"AP95", @"Missing HBCI-Information: %@"), [self localizedDescription ] ]; break;
        default             : message = [self localizedDescription ]; break;
	}

	if(message && title) {
		NSRunAlertPanel(title, message,	NSLocalizedString(@"ok", @"Ok"), nil, nil);
	} else NSLog(@"Unhandled alert: %@", [self localizedDescription ]);
    
}

-(void)logMessage
{
	NSString *message = nil;
	switch(self.code) {
		case err_hbci_abort : message = NSLocalizedString(@"AP93", @"User abort"); break;
		case err_hbci_gen   : message = [self localizedDescription ]; break;
		case err_hbci_passwd: message = NSLocalizedString(@"AP94", @"The password entered was wrong"); break;
		case err_hbci_param : message = [NSString stringWithFormat: NSLocalizedString(@"AP95", @"Missing HBCI-Information: %@"), [self localizedDescription ] ]; break;
        default             : message = [self localizedDescription ]; break;
	}    
    [[MessageLog log] addMessage: message withLevel: LogLevel_Error];
}


@end
