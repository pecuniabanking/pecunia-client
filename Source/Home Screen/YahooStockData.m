/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "YahooStockData.h"

#import "NSDictionary+PecuniaAdditions.h"
#import "ShortDate.h"

@implementation YahooStockData

/**
 * Returns chart values for the given symbols (e.g. AAPL) for the given interval. The result is
 * returned asynchronously as a dictionary (if there was no error) which represents the XML data
 * returned by the used service. It is nil if an unexpected response came back or an error appeared.
 *
 * @param interval A string describing the date interval to retrieve (1d for intraday, 5d, 1m etc.).
 *                 There must be only 1 symbol if this interval is other than 1d.
 *
 * This implementation uses the same service as the dashboard stock ticker widget.
 */
+ (void)tickerValuesForSymbols: (NSArray *)symbols
                      interval: (NSString *)interval
             completionHandler: (void (^)(NSDictionary*, NSError*)) handler
{
    if (symbols.count == 0 || interval.length == 0) {
        return;
    }

    NSString *urlString = @"http://wu-charts.apple.com/dgw?imei=1&apptype=finance";
    NSDate   *date = [NSDate date];
    NSString *symbolString = @"<list>";
    if ([interval isEqualToString: @"1d"]) {
        for (NSString *symbol in symbols) {
            symbolString = [symbolString stringByAppendingFormat: @"<symbol>%@</symbol>", symbol];
        }
        symbolString = [symbolString stringByAppendingString: @"</list>"];
    } else {
        symbolString = [NSString stringWithFormat: @"<symbol>%@</symbol>", symbols[0]];
    }

    NSString *body = [NSString stringWithFormat: @"<?xml version='1.0' encoding='utf-8'?>"
                      "<request devtype='Apple_OSX' deployver='APPLE_DASHBOARD_1_0' "
                      "app='YGoAppleStocksWidget' appver='unknown' api='finance' apiver='1.0.1' "
                      "acknotification='0000'><query id='0' timestamp='%d"
                      "' type='getchart'>%@<range>%@</range></query></request>",
                      (int)[date timeIntervalSince1970], symbolString, interval];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL: [NSURL URLWithString: urlString]];
    [request setHTTPMethod: @"POST"];

    [request addValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
    [request addValue: @"IMSI=1" forHTTPHeaderField: @"X-Client-ID"];
    [request addValue: @"no-cache" forHTTPHeaderField: @"Cache-Control"];

    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData: [body dataUsingEncoding: NSUTF8StringEncoding]];
    [request setHTTPBody: postBody];

    [NSURLConnection sendAsynchronousRequest: request
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
                                   NSInteger statusCode = [(id)response statusCode];
                                   if (statusCode >= 200 && statusCode < 300) {
                                       NSDictionary *result = [NSDictionary dictForXMLData: data error: NULL];
                                       handler(result, error);
                                   } else {
                                       handler(nil, error);
                                   }
                               } else {
                                   handler(nil, error);
                               }
                           }

     ];
}

/**
 * Returns quotes for the given symbols. The result is
 * returned asynchronously as a dictionary (if there was no error) which represents the XML data
 * returned by the used service. It is nil if an unexpected response came back or an error appeared.
 *
 * This implementation uses the same service as the dashboard stock ticker widget.
 */
+ (void)quotesForSymbols: (NSArray *)symbols
       completionHandler: (void (^)(NSDictionary*, NSError*)) handler
{
    if (symbols.count == 0) {
        return;
    }

    NSString *urlString = @"http://wu-charts.apple.com/dgw?imei=1&apptype=finance";
    NSDate   *date = [NSDate date];
    NSString *symbolString = @"<list>";
    for (NSString *symbol in symbols) {
        symbolString = [symbolString stringByAppendingFormat: @"<symbol>%@</symbol>", symbol];
    }
    symbolString = [symbolString stringByAppendingString: @"</list>"];

    NSString *body = [NSString stringWithFormat: @"<?xml version='1.0' encoding='utf-8'?>"
                      "<request devtype='Apple_OSX' deployver='APPLE_DASHBOARD_1_0' "
                      "app='YGoAppleStocksWidget' appver='unknown' api='finance' apiver='1.0.1' "
                      "acknotification='0000'><query id='0' timestamp='%d"
                      "' type='getquotes'>%@</query></request>",
                      (int)[date timeIntervalSince1970], symbolString];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL: [NSURL URLWithString: urlString]];
    [request setHTTPMethod: @"POST"];

    [request addValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
    [request addValue: @"IMSI=1" forHTTPHeaderField: @"X-Client-ID"];
    [request addValue: @"no-cache" forHTTPHeaderField: @"Cache-Control"];

    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData: [body dataUsingEncoding: NSUTF8StringEncoding]];
    [request setHTTPBody: postBody];

    [NSURLConnection sendAsynchronousRequest: request
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
                                   NSInteger statusCode = [(id)response statusCode];
                                   if (statusCode >= 200 && statusCode < 300) {
                                       NSDictionary *result = [NSDictionary dictForXMLData: data error: NULL];
                                       handler(result, error);
                                   } else {
                                       handler(nil, error);
                                   }
                               } else {
                                   handler(nil, error);
                               }
                           }
     
     ];
}

/**
 * Looks up synchronously the given suggestion to find a certain symbol.
 * The returned dictionary is organized by stock exchanges (dictionary of arrays of dictionary).
 *
 * This implementation uses the same service as the dashboard stock ticker widget.
 */
+ (NSDictionary *)lookupSymbol: (NSString *)suggestion error: (NSError **)error;
{
    NSString *urlString = @"http://wu-charts.apple.com/dgw?imei=1&apptype=finance";
    NSDate   *date = [NSDate date];

    NSString *body = [NSString stringWithFormat: @"<?xml version='1.0' encoding='utf-8'?>"
                      "<request devtype='Apple_OSX' deployver='APPLE_DASHBOARD_1_0' "
                      "app='YGoAppleStocksWidget' appver='unknown' api='finance' apiver='1.0.1' "
                      "acknotification='0000'><query id='0' timestamp='%d"
                      "' type='getsymbol'><phrase>%@</phrase><count>30</count><offset>0</offset></query></request>",
                      (int)[date timeIntervalSince1970], suggestion];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL: [NSURL URLWithString: urlString]];
    [request setHTTPMethod: @"POST"];

    [request addValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
    [request addValue: @"IMSI=1" forHTTPHeaderField: @"X-Client-ID"];
    [request addValue: @"no-cache" forHTTPHeaderField: @"Cache-Control"];

    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData: [body dataUsingEncoding: NSUTF8StringEncoding]];
    [request setHTTPBody: postBody];

    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest: request
                                         returningResponse: &response
                                                     error: error];

    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(id)response statusCode];
        if (statusCode >= 200 && statusCode < 300) {
            NSDictionary *rawResult = [NSDictionary dictForXMLData: data error: NULL];

            NSArray *list;
            if ([rawResult[@"response"][@"result"][@"list"][@"count"] intValue] == 1) {
                id temp = [NSArray arrayWithObject: rawResult[@"response"][@"result"][@"list"][@"quote"]];
                if ([temp isKindOfClass: NSArray.class]) {
                    list = temp;
                }
            } else {
                id temp = rawResult[@"response"][@"result"][@"list"][@"quote"];
                if ([temp isKindOfClass: NSArray.class]) {
                    list = temp;
                }
            }
            if (list.count == 0) {
                return [NSDictionary dictionaryWithObject: [NSArray array]
                                                   forKey: NSLocalizedString(@"AP734", nil)];
            }
            NSMutableDictionary *result = [NSMutableDictionary dictionary];

            for (id entry in list) {
                if ([entry isKindOfClass: NSDictionary.class]) {
                    NSString *exchange;
                    if ([entry[@"exchange"] isKindOfClass: NSDictionary.class]) {
                        exchange = entry[@"exchange"][@"text"];
                    }
                    if (exchange.length == 0) {
                        exchange = NSLocalizedString(@"AP19", nil);
                    }

                    NSMutableArray *values = result[exchange];
                    if (values == nil) {
                        values = [NSMutableArray arrayWithCapacity: 3];
                        result[exchange] = values;
                    }

                    NSString *name;
                    if ([entry[@"name"] isKindOfClass: NSDictionary.class]) {
                        name = entry[@"name"][@"text"];
                    }

                    NSString *symbol;
                    if ([entry[@"exchange"] isKindOfClass: NSDictionary.class]) {
                        symbol = entry[@"symbol"][@"text"];
                    }
                    if (name.length > 0 && symbol.length > 0) {
                        NSDictionary *details = @{@"name": name, @"symbol": symbol};
                        [values addObject: details];
                    }
                }
            }
            return result;
        }
    }
    return nil;
}

@end
