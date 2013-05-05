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

#import "DateAndValutaCell.h"

@implementation DateAndValutaCell

@synthesize valuta;
@synthesize formatter;

- (id)initWithCoder: (NSCoder *)decoder
{
    if ((self = [super initWithCoder: decoder])) {
        self.formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle: NSDateFormatterMediumStyle];
        [formatter setTimeStyle: NSDateFormatterNoStyle];
        [formatter setLocale: [NSLocale currentLocale]];
    }
    return self;
}

- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    if (valuta) {
        NSMutableDictionary *attrs = [[[self attributedStringValue] attributesAtIndex: 0 effectiveRange: NULL] mutableCopy];
        NSString            *str = [formatter stringFromDate: valuta];
        NSFont              *txtFont = [NSFont fontWithName: @"Lucida Grande" size: 10];
        attrs[NSFontAttributeName] = txtFont;

        NSAttributedString *s = [[NSAttributedString alloc] initWithString: str attributes: attrs];

        [super drawWithFrame: cellFrame inView: controlView];
        NSRect r, rem;
        NSDivideRect(cellFrame, &r, &rem, 16, NSMaxYEdge);
        r.size.width -= 5;
        [s drawInRect: r];
    } else {
        [super drawWithFrame: cellFrame inView: controlView];
    }
}

- copyWithZone: (NSZone *)zone
{
    DateAndValutaCell *cell = (DateAndValutaCell *)[super copyWithZone: zone];
    cell->formatter = formatter;
    if (valuta) {
        cell->valuta = valuta;
    } else {cell->valuta = nil; }
    return cell;
}


@end
