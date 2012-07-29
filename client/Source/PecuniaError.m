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


+(NSError*)errorWithText: (NSString*)msg
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1 ];
	if(msg) [userInfo setObject: msg forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:@"de.pecuniabanking.ErrorDomain" code:1 userInfo:userInfo];
}

+(PecuniaError*)errorWithCode:(NSInteger)code message:(NSString*)msg
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1 ];
	if(msg) [userInfo setObject: msg forKey:NSLocalizedDescriptionKey];
	PecuniaError *error = [[PecuniaError alloc ] initWithDomain: @"de.pecuniabanking.ErrorDomain" code:code userInfo:userInfo ];
	return [error autorelease ];
}

-(void)alertPanel
{
	// HBCI Errors
	NSString *title = nil;
	NSString *message = nil;
	if(self.code < 100) title = NSLocalizedString(@"AP7", @"HBCI error occured!");
	switch(self.code) {
		case 0: message = NSLocalizedString(@"AP93", @"User abort"); break;
		case 1: message = [self localizedDescription ]; break;
		case 2: message = NSLocalizedString(@"AP94", @"The password entered was wrong"); break;
		case 3: message = [NSString stringWithFormat: NSLocalizedString(@"AP95", @"Missing HBCI-Information: %@"), [self localizedDescription ] ]; break;
	}
	if(message && title) {
		NSRunAlertPanel(title, message,	NSLocalizedString(@"ok", @"Ok"), nil, nil);
	} else NSLog(@"Unhandled alert: %@", [self localizedDescription ]);
}

-(void)logMessage
{
    [[MessageLog log] addMessage: [self localizedDescription] withLevel: LogLevel_Error];
}


@end
