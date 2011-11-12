//
//  ResultParser.h
//  Client
//
//  Created by Frank Emminghaus on 16.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HBCIBridge;

@interface ResultParser : NSObject <NSXMLParserDelegate> {
    NSMutableString *currentValue;
    HBCIBridge	*parent;
    id result;
    
    NSMutableArray	*stack;
    NSDateFormatter *dateFormatter;
    NSString		*currentType;
}

-(id)result;
-(id)initWithParent: (HBCIBridge*)par;

@end
