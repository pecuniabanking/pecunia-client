//
//  LogParser.h
//  Client
//
//  Created by Frank Emminghaus on 19.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HBCIBridge;

@interface LogParser : NSObject <NSXMLParserDelegate> {
    NSMutableString *currentValue;
    int             level;
    id              parent;

}

- (id)initWithParent: (id)par level: (NSString *)lev;

@end
