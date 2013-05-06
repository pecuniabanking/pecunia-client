/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#import "ImportSettings.h"

@implementation ImportSettings

@synthesize name;
@synthesize fields;
@synthesize fieldSeparator;
@synthesize dateFormat;
@synthesize decimalSeparator;
@synthesize encoding;
@synthesize ignoreLines;
@synthesize accountNumber;
@synthesize accountSuffix;
@synthesize bankCode;
@synthesize type;

@synthesize isDirty;
@synthesize fileName;

- (id)init
{
    self = [super init];
    if (self != nil) {
        name = @"";
        fields = @[];
        fieldSeparator = @",";
        dateFormat = @"dd.MM.yyyy";

        NSLocale *locale = NSLocale.currentLocale;
        decimalSeparator = [locale objectForKey: NSLocaleDecimalSeparator];

        encoding = @(NSISOLatin1StringEncoding);
        ignoreLines = @0;
        accountNumber = @"";
        accountSuffix = @"";
        bankCode = @"";
        type = @(SettingsTypeCSV);

        isDirty = YES;
        fileName = @"";

        [self updateBindings];
    }
    return self;
}

- (id)initWithCoder: (NSCoder *)aDecoder
{
    self = [self init];
    name = [aDecoder decodeObjectForKey: @"name"];
    fields = [aDecoder decodeObjectForKey: @"fields"];
    fieldSeparator = [aDecoder decodeObjectForKey: @"sepChar"];
    dateFormat = [aDecoder decodeObjectForKey: @"dateFormatString"];
    decimalSeparator = [aDecoder decodeObjectForKey: @"decimalSeparator"];
    encoding = [aDecoder decodeObjectForKey: @"encoding"];
    ignoreLines = [aDecoder decodeObjectForKey: @"ignoreLines"];
    accountNumber = [aDecoder decodeObjectForKey: @"accountNumber"];
    bankCode = [aDecoder decodeObjectForKey: @"bankCode"];
    accountSuffix = [aDecoder decodeObjectForKey: @"accountSuffix"];
    type = [aDecoder decodeObjectForKey: @"type"];
    isDirty = NO;

    return self;
}

- (void)encodeWithCoder: (NSCoder *)aCoder
{
    [aCoder encodeObject: name forKey: @"name"];
    [aCoder encodeObject: fields forKey: @"fields"];
    [aCoder encodeObject: fieldSeparator forKey: @"sepChar"];
    [aCoder encodeObject: dateFormat forKey: @"dateFormatString"];
    [aCoder encodeObject: decimalSeparator forKey: @"decimalSeparator"];
    [aCoder encodeObject: encoding forKey: @"encoding"];
    [aCoder encodeObject: ignoreLines forKey: @"ignoreLines"];
    [aCoder encodeObject: accountNumber forKey: @"accountNumber"];
    [aCoder encodeObject: bankCode forKey: @"bankCode"];
    [aCoder encodeObject: accountSuffix forKey: @"accountSuffix"];
    [aCoder encodeObject: type forKey: @"type"];
    isDirty = NO;
}

- (void)updateBindings
{
    [self addObserver: self forKeyPath: @"name" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"fields" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"fieldSeparator" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"dateFormat" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"decimalSeparator" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"encoding" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"ignoreLines" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"accountNumber" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"accountSuffix" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"bankCode" options: 0 context: nil];
    [self addObserver: self forKeyPath: @"type" options: 0 context: nil];
}

- (void)dealloc
{
    [self removeObserver: self forKeyPath: @"name"];
    [self removeObserver: self forKeyPath: @"fields"];
    [self removeObserver: self forKeyPath: @"fieldSeparator"];
    [self removeObserver: self forKeyPath: @"dateFormat"];
    [self removeObserver: self forKeyPath: @"decimalSeparator"];
    [self removeObserver: self forKeyPath: @"encoding"];
    [self removeObserver: self forKeyPath: @"ignoreLines"];
    [self removeObserver: self forKeyPath: @"accountNumber"];
    [self removeObserver: self forKeyPath: @"accountSuffix"];
    [self removeObserver: self forKeyPath: @"bankCode"];
    [self removeObserver: self forKeyPath: @"type"];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    [self willChangeValueForKey: @"isDirty"];
    isDirty = YES;
    [self didChangeValueForKey: @"isDirty"];
}

@end
