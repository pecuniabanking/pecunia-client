/**
 * Copyright (c) 2009, 2015, Pecunia Project. All rights reserved.
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

#import "HBCIBridge.h"
#import "HBCIError.h"
#import "PecuniaError.h"
#import "HBCICommon.h"
#import "LaunchParameters.h"
#import "CallbackHandler.h"
#import "HBCIController.h"
#import "NSString+PecuniaAdditions.h"

@interface HBCIBridge () {

    NSPipe *inPipe;
    NSPipe *outPipe;
    NSTask *task;

    BOOL resultExists;
    BOOL running;

    id result;
    id asyncSender;

    HBCI_Error *error;

    NSMutableString *asyncString;
}

@end

@implementation HBCIBridge

@synthesize authRequest;

- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    running = NO;
    authRequest = [AuthRequest new];

    return self;
}

- (NSPipe *)outPipe {
    return outPipe;
}

// Returns NO if the result was an error.
- (BOOL)setResult: (id)res {
    if ([res isKindOfClass: [HBCI_Error class]]) {
        result = nil;
        error = res;
        return NO;
    } else {
        result = res;
        error = nil;
    }
    return YES;
}

- (id)result {
    return result;
}

- (HBCI_Error *)error {
    return error;
}

- (void)startup {
}

- (void)parse: (NSString *)cmd
{
}

- (void)getData: (NSNotification *)aNotification
{
}

- (void)receive
{
}

- (void)parser: (NSXMLParser *)parser didStartElement: (NSString *)elementName namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qName attributes: (NSDictionary *)attributeDict
{
}

- (void)parser: (NSXMLParser *)parser didEndElement: (NSString *)elementName namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qName
{
}

- (id)syncCommand: (NSString *)cmd error: (PecuniaError **)err
{
    result = nil; error = nil; resultExists = NO;
    return result;
}

- (void)asyncCommand: (NSString *)cmd sender: (id)sender
{
}

@end
