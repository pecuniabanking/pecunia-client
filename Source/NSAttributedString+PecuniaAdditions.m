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

#import "NSView+PecuniaAdditions.h"

@implementation NSAttributedString (PecuniaAdditions)

+ (NSAttributedString *)hyperlinkFromString: (NSString*)inString withURL: (NSURL*)aURL underlined: (BOOL)underlined
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    [attrString beginEditing];
    [attrString addAttribute: NSLinkAttributeName value: [aURL absoluteString] range: range];

    // Make the text appear in blue
    [attrString addAttribute: NSForegroundColorAttributeName value: [NSColor blueColor] range: range];

    // Next make the text appear with an underline.
    if (underlined) {
        [attrString addAttribute: NSUnderlineStyleAttributeName value: @(NSSingleUnderlineStyle) range: range];
    }
    [attrString endEditing];

    return attrString;
}

/**
 * Any HTML as string content, including clickable links.
 */
+ (NSAttributedString *)stringFromHTML: (NSString *)html withFont: (NSFont *)font
{
    if (!font) {
        font = [NSFont systemFontOfSize: 0.0]; // Default font
    }
    html = [NSString stringWithFormat:@"<span style=\"font-family:'%@'; font-size:%dpx;\">%@</span>", [font fontName], (int)[font pointSize], html];
    NSData *data = [html dataUsingEncoding: NSUTF8StringEncoding];
    NSAttributedString* string = [[NSAttributedString alloc] initWithHTML: data documentAttributes: nil];
    return string;
}

@end

