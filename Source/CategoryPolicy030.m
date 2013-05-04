//
//  CategoryPolicy030.m
//  Pecunia
//
//  Created by Frank Emminghaus on 30.03.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "CategoryPolicy030.h"


@implementation CategoryPolicy030

- (NSString *)convertRule: (NSString *)rule
{
    NSString *res;
    if (rule != nil) {
        res = [rule stringByReplacingOccurrencesOfString: @"purpose" withString: @"statement.purpose"];
        res = [res stringByReplacingOccurrencesOfString: @"remoteName" withString: @"statement.remoteName"];
        res = [res stringByReplacingOccurrencesOfString: @"remoteAccount" withString: @"statement.remoteAccount"];
        res = [res stringByReplacingOccurrencesOfString: @"localAccount" withString: @"statement.localAccount"];
        return res;
    } else {return rule; }
}

@end
