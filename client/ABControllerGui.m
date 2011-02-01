//
//  ABControllerGui.m
//  Pecunia
//
//  Created by Frank Emminghaus on 12.09.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "ABControllerGui.h"
#import "Keychain.h"
#import "PasswordWindow.h"
#import "ABInputWindowController.h"
#import "ABInfoBoxController.h"
#import "ABProgressWindowController.h"
#import "MessageLog.h"
#include <gwenhywfar/logger.h>
#include <aqhbci/aqhbci.h>
#include <aqbanking/banking.h>

static GWEN_GUI_CHECKCERT_FN	standardCertFn;
static ABControllerGui *abGui;

int MessageBox(
			   GWEN_GUI	*gui,
			   uint32_t   flags,
			   const char *title,
			   const char *text,
			   const char *b1,
			   const char *b2,
			   const char *b3,
			   uint32_t	guiid	) {
	
	NSRange range;
	NSString *sText;
	int	defaultButton;
	
	sText = [NSString stringWithUTF8String: text];
	range = [sText rangeOfString: @"<html>" ];
	if(range.location == NSNotFound) range.location = [sText length ];
	
	defaultButton = GWEN_GUI_MSG_FLAGS_CONFIRM_BUTTON(flags);
	if (flags & GWEN_GUI_MSG_FLAGS_SEVERITY_DANGEROUS) {
		if(defaultButton == 1) {
			if (b2) defaultButton = 2;
		} else defaultButton = 1;
	}
	
	switch (defaultButton) {
		case 1: {
			int res = NSRunAlertPanel([NSString stringWithUTF8String: title],
									  [sText substringToIndex: range.location],
									  b1 ? [NSString stringWithUTF8String: b1] : nil,
									  b2 ? [NSString stringWithUTF8String: b2] : nil,
									  b3 ? [NSString stringWithUTF8String: b3] : nil);
			switch (res) {
				case NSAlertDefaultReturn: return 1;
				case NSAlertAlternateReturn: return 2;
				case NSAlertOtherReturn: return 3;
				default: return 0; 
			}
		}
		case 2: {
			int res = NSRunAlertPanel([NSString stringWithUTF8String: title],
									  [sText substringToIndex: range.location],
									  b2 ? [NSString stringWithUTF8String: b2] : nil,
									  b1 ? [NSString stringWithUTF8String: b1] : nil,
									  b3 ? [NSString stringWithUTF8String: b3] : nil);
			switch (res) {
				case NSAlertDefaultReturn: return 2;
				case NSAlertAlternateReturn: return 1;
				case NSAlertOtherReturn: return 3;
				default: return 0; 
			}
		}
		case 3: {
			int res = NSRunAlertPanel([NSString stringWithUTF8String: title],
									  [sText substringToIndex: range.location],
									  b3 ? [NSString stringWithUTF8String: b3] : nil,
									  b1 ? [NSString stringWithUTF8String: b1] : nil,
									  b2 ? [NSString stringWithUTF8String: b2] : nil);
			switch (res) {
				case NSAlertDefaultReturn: return 3;
				case NSAlertAlternateReturn: return 1;
				case NSAlertOtherReturn: return 2;
				default: return 0; 
			}
		}
	}
	
	return 0;
}

int GetPassword (
				 GWEN_GUI	*gui,
				 uint32_t 	flags,
				 const char	*token,
				 const char	*title,
				 const char	*text,
				 char		*buffer,
				 int			minLen,
				 int			maxLen,
				 uint32_t	guiid
				 ) 	
{
	int		res;
	BOOL	savePin = NO;
	
	// if PIN, try to retrieve saved PIN
	if(!(flags & GWEN_GUI_INPUT_FLAGS_TAN)) {

		// Check keychain
		NSString* passwd = [Keychain passwordForService: @"Pecunia PIN" account: [NSString stringWithUTF8String: token ] ];
		if(passwd) {
			strncpy(buffer, [passwd UTF8String ], maxLen); 
			return 0;
		}
		
		// issue Password window
		NSRange  range;
		NSString *sText;
		
		sText = [NSString stringWithUTF8String: text];
		range = [sText rangeOfString: @"<html>" ];
		if(range.location == NSNotFound) range.location = [sText length ];
		
		PasswordWindow *pwWindow = [[PasswordWindow alloc] initWithText: [sText substringToIndex: range.location]
																  title: [NSString stringWithUTF8String: title]];
		
		res = [NSApp runModalForWindow: [pwWindow window]];
		if(res == 0) {
			const char* r = [[pwWindow result] UTF8String];
			strncpy(buffer, r, maxLen);
			if([pwWindow shouldSavePassword ]) savePin = YES;
		}
		[pwWindow release ];
		
	} else res=InputBox(gui, flags, title, text, buffer, minLen, maxLen);
	
	// if PIN, save it
	if(!(flags & GWEN_GUI_INPUT_FLAGS_TAN)) {
		if(res == 0 && token) {
			[Keychain setPassword: [NSString stringWithUTF8String: buffer ] forService: @"Pecunia PIN" account: [NSString stringWithUTF8String: token ] store: savePin ];
		}
	}
	return res;
}


int CheckCert(
			  GWEN_GUI *gui,
			  const GWEN_SSLCERTDESCR *cert,
			  GWEN_SYNCIO *sio,
			  uint32_t guiid)
{
	const char	*hash = GWEN_SslCertDescr_GetFingerPrint(cert);
	uint32		status = GWEN_SslCertDescr_GetStatusFlags(cert);
	NSMutableString	*certID = [NSMutableString stringWithUTF8String: hash ];
	[certID appendString: @"/" ];
	[certID appendString: [NSString stringWithFormat: @"%x", (int)status  ] ];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL accept = [defaults boolForKey: certID ];
	if(accept) return 0;
	
	int res = standardCertFn(gui, cert, sio, guiid);
	if(res == 0) [defaults setBool: YES forKey: certID ];
	
	return res;
}


int InputBox(
			 GWEN_GUI	*gui,
			 uint32_t	flags, 
			 const char	*title, 
			 const char	*text, 
			 char		*buffer, 
			 int			minLen, 
			 int			maxLen,
			 uint32_t	guiid)
{
	int      res;
	NSRange  range;
	NSString *sText;
	
	sText = [NSString stringWithUTF8String: text];
	range = [sText rangeOfString: @"<html>" ];
	if(range.location == NSNotFound) range.location = [sText length ];
	
	ABInputWindowController *abInputController = [[ABInputWindowController alloc] 
												  initWithText: [sText substringToIndex: range.location]
												  title: [NSString stringWithUTF8String: title]];
	
	
	res = [NSApp runModalForWindow: [abInputController window]];
    const char* r = [[abInputController result] UTF8String];
	strncpy(buffer, r, maxLen);
	[abInputController release ];
	return res;
}

uint32_t ShowBox(
				 GWEN_GUI		*gui,
				 uint32_t		flags, 
				 const char		*title, 
				 const char		*text,
				 uint32_t		guiid)
{
	unsigned int n;
	
	ABInfoBoxController* abBoxController = [[ABInfoBoxController alloc] 
											initWithText:[NSString stringWithUTF8String: text]
											title: [NSString stringWithUTF8String: title]];
	[abBoxController showWindow: nil];
	n = [abGui addInfoBox: abBoxController];
	return (uint32_t)n;
}

void HideBox(GWEN_GUI *gui, uint32_t n)
{
	[abGui hideInfoBox: (unsigned int)n];
}



uint32_t ProgressStart(
					   GWEN_GUI	*gui,
					   uint32_t	progressFlags,
					   const char	*title, 
					   const char	*text,
					   uint64_t	total,
					   uint32_t	guiid)
{
	unsigned int n;
	
	if(progressFlags & GWEN_GUI_PROGRESS_DELAY) return (uint32_t)20;
	
	ABProgressWindowController *abProgressController = [[ABProgressWindowController alloc] 
														initWithText: [NSString stringWithUTF8String: text?text:""] 
														title: [NSString stringWithUTF8String: title?title:""]];
	
	if(progressFlags & GWEN_GUI_PROGRESS_KEEP_OPEN) [abProgressController setKeepOpen: TRUE ];
	[abProgressController setProgressMaxValue: (double)total];
	if(progressFlags & GWEN_GUI_PROGRESS_SHOW_LOG == 0) [abProgressController hideLog ];
	if(progressFlags & GWEN_GUI_PROGRESS_SHOW_PROGRESS == 0) [abProgressController hideProgressIndicator ];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL hideProgressWindow = [defaults boolForKey: @"hideProgressWindow" ];
	if(!hideProgressWindow)	[abProgressController showWindow: nil];
	n = [abGui addLogBox: abProgressController];
	return (uint32_t)n;
}

int ProgressAdvance(
					GWEN_GUI	*gui,
					uint32_t	handle,
					uint64_t	progress)
{
	ABProgressWindowController *bc;
	
	if(handle == 20) return 0;
	bc = [abGui getLogBox: (unsigned int)handle];
	if ([bc isAborted ]) return 1;
    if(progress != GWEN_GUI_PROGRESS_NONE) [bc setProgressCurrentValue: (double)progress];
	return 0;
}

int ProgressLog(
				GWEN_GUI			*gui,
				uint32_t			handle,
				GWEN_LOGGER_LEVEL	level,
				const char			*text)
{
	ABProgressWindowController  *bc;
	
	if(handle == 20) return 0;
	bc = [abGui getLogBox: (unsigned int)handle];
	if ([bc isAborted ]) return 1;
	[bc addLog: [NSString stringWithUTF8String: text] withLevel: level ];
	return 0;
}

int ProgressEnd(GWEN_GUI *gui, uint32_t handle)
{
	if(handle == 20) return 0;
	[abGui hideLogBox: (unsigned int)handle];
	return 0;
}

int SetPasswordStatus(GWEN_GUI *gui,
					  const char *token,
					  const char *pin,
					  GWEN_GUI_PASSWORD_STATUS status,
					  uint32_t guiid) 
{
	if (token==NULL && pin==NULL && status==GWEN_Gui_PasswordStatus_Remove) [Keychain clearCache ];
	else {
		if(status == GWEN_Gui_PasswordStatus_Remove || status == GWEN_Gui_PasswordStatus_Bad) {
			NSRunCriticalAlertPanel(NSLocalizedString(@"AP66", @""),
									NSLocalizedString(@"AP67", @""),
									NSLocalizedString(@"ok", @"Ok"),
									nil,
									nil,
									[NSString stringWithUTF8String: token],
									[NSString stringWithUTF8String: pin]
									);
			
			[abGui clearCacheForToken: [NSString stringWithUTF8String: token] ];
		}
	}
	return 0;
}	

int Print(GWEN_GUI		*gui,
		  const char	*docTitle,
	      const char	*docType,
		  const char	*descr,
		  const char	*text,
		  uint32_t		guiid)
{
	return 0;
}

int LogHook(GWEN_GUI *gui, const char *logDomain, GWEN_LOGGER_LEVEL priority, const char *str)
{
	LogLevel level;
	switch (priority) {
		case GWEN_LoggerLevel_Alert:
		case GWEN_LoggerLevel_Error: level = LogLevel_Error; break;
		case GWEN_LoggerLevel_Warning: level = LogLevel_Warning; break;
		case GWEN_LoggerLevel_Notice: level = LogLevel_Notice; break;
		case GWEN_LoggerLevel_Info: level = LogLevel_Info; break;
		case GWEN_LoggerLevel_Debug: level = LogLevel_Debug; break;
		case GWEN_LoggerLevel_Verbous: level = LogLevel_Verbous; break;
		default: level = LogLevel_Warning;
	}
	NSMutableDictionary *data = [[NSMutableDictionary alloc ] initWithCapacity:2 ];
	[data setObject:[NSString stringWithUTF8String: str ] forKey:@"message" ];
	[data setObject:[NSNumber numberWithInt:(int)level ] forKey:@"level" ];
	
	[[MessageLog log ] performSelectorOnMainThread:@selector(addMessageFromDict:) withObject:data waitUntilDone:NO ];
//	[[MessageLog log ] addMessage:[NSString stringWithUTF8String: str ] withLevel:level];
	return 1;
}



@implementation ABControllerGui

-(id)init
{
	self = [super init ];
	if (self == nil) return nil;

	boxes = [[NSMutableDictionary dictionaryWithCapacity: 10] retain];
	handle = 1;
	
	gui = GWEN_Gui_new();

	GWEN_Gui_SetHideBoxFn(gui, HideBox);
	GWEN_Gui_SetInputBoxFn(gui, InputBox);
	GWEN_Gui_SetMessageBoxFn(gui, MessageBox);
	GWEN_Gui_SetPrintFn(gui, Print);
	GWEN_Gui_SetProgressAdvanceFn(gui, ProgressAdvance);
	GWEN_Gui_SetProgressEndFn(gui, ProgressEnd);
	GWEN_Gui_SetProgressLogFn(gui, ProgressLog);
	GWEN_Gui_SetProgressStartFn(gui, ProgressStart);
	GWEN_Gui_SetGetPasswordFn(gui, GetPassword);
	GWEN_Gui_SetSetPasswordStatusFn(gui, SetPasswordStatus);
	standardCertFn = GWEN_Gui_SetCheckCertFn(gui, CheckCert);
	
	//	AB_Banking_SetSetPinStatusFn(ab, SetPinStatus);
	//	AB_Banking_SetSetTanStatusFn(ab, SetTanStatus);
	//	AB_Banking_SetGetPinFn(ab, GetPin);
	GWEN_Gui_SetShowBoxFn(gui, ShowBox);
	GWEN_Gui_SetLogHookFn(gui, LogHook);

	GWEN_Logger_SetLevel(AQHBCI_LOGDOMAIN, GWEN_LoggerLevel_Error);
	GWEN_Logger_SetLevel(AQBANKING_LOGDOMAIN, GWEN_LoggerLevel_Error);
	GWEN_Logger_SetLevel(GWEN_LOGDOMAIN, GWEN_LoggerLevel_Error);
	
	abGui = self;
	return self;
}

-(GWEN_GUI*)gui
{
	return gui;
}


-(void)clearCacheForToken: (NSString*)token
{
	[Keychain deletePasswordForService: @"Pecunia PIN" account: token ];
}

-(unsigned int)addInfoBox: (ABInfoBoxController *)x
{
	unsigned int n = handle++;
	
	[boxes setObject: x forKey: [NSNumber numberWithUnsignedInt: n]];
	lastHandle = n;
	return n;
}

-(unsigned int)addLogBox: (ABProgressWindowController *)x
{
	unsigned int n = handle++;
	
	[boxes setObject: x forKey: [NSNumber numberWithUnsignedInt: n]];
	lastHandle = n;
	return n;
}

-(void)hideInfoBox: (unsigned int)n
{
	unsigned int x;
	ABInfoBoxController	*bc;
	
	if(!n) x = lastHandle; else x = n;
	bc = [boxes objectForKey: [NSNumber numberWithUnsignedInt: x]];
	[boxes removeObjectForKey: [NSNumber numberWithUnsignedInt: x]];
	[bc close];
	[bc release];
}


-(void)hideLogBox: (unsigned int)n
{
	unsigned int x;
	ABProgressWindowController	*bc;
	
	if(!n) x = lastHandle; else x = n;
	bc = [boxes objectForKey: [NSNumber numberWithUnsignedInt: x]];
	[boxes removeObjectForKey: [NSNumber numberWithUnsignedInt: x]];
	if([bc stop] == FALSE) [bc release ];
}

-(ABProgressWindowController*)getLogBox: (unsigned int)n
{
	unsigned int x;
	
	if(!n) x = lastHandle; else x = n;
	return [boxes objectForKey: [NSNumber numberWithUnsignedInt: x]];
}

-(void)dealloc
{
	[boxes release ];
	[super dealloc ];
}


@end
