/**
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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

#import "NSString+PecuniaAdditions.h"

@implementation NSString (PecuniaAdditions)

/**
 * Returns a new string instance containing the given data as a string (assuming UTF8 encoding).
 * If the given data cannot be converted to an UTF8 string it is converted to a hex string.
 * Returns an empty string if data is nil or empty.
 */
+ (NSString *)stringWithData: (NSData *)data
{
    if (data == nil) {
        return [NSString string];
    }
    
    NSString *result = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
    if (result == nil) {
        const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
        
        if (dataBuffer == nil)
            return [NSString string];
        
        NSMutableString *hexString  = [NSMutableString stringWithCapacity: 2 * data.length];
        for (NSUInteger i = 0; i < data.length; ++i)
            [hexString appendString:[NSString stringWithFormat: @"%02x", dataBuffer[i]]];
        result = [NSString stringWithString: hexString];
    }
    return result;
}

@end
