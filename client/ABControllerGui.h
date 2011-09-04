//
//  ABControllerGui.h
//  Pecunia
//
//  Created by Frank Emminghaus on 12.09.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#ifdef AQBANKING
#import <Cocoa/Cocoa.h>
#include <AqBanking/gwenhywfar/gui.h>
@class ABInfoBoxController;
@class ABProgressWindowController;


@interface ABControllerGui : NSObject {
	GWEN_GUI				*gui;
	NSMutableDictionary		*boxes;
    unsigned int			handle;
	unsigned int			lastHandle;
	
}

// Box handling
-(unsigned int)addInfoBox: (ABInfoBoxController *)x;
-(unsigned int)addLogBox: (ABProgressWindowController *)x;
-(void)hideInfoBox: (unsigned int)n;
-(void)hideLogBox: (unsigned int)n;
-(ABProgressWindowController*)getLogBox: (unsigned int)n;
-(GWEN_GUI*)gui;

// security
-(void)clearCacheForToken: (NSString*)token;

@end

#endif