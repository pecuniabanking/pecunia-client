//
//  DateAndValutaCell.m
//  Pecunia
//
//  Created by Frank Emminghaus on 06.06.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "DateAndValutaCell.h"


@implementation DateAndValutaCell

@synthesize valuta;
@synthesize formatter;

- (id)initWithCoder:(NSCoder*)decoder {
    if ((self = [super initWithCoder:decoder ])) {
		
		self.formatter = [[NSDateFormatter alloc ] init ];
		[formatter setDateStyle:NSDateFormatterMediumStyle ];
		[formatter setTimeStyle:NSDateFormatterNoStyle ];
		[formatter setLocale:[NSLocale currentLocale ] ];
    }
    return self;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (valuta) {
		NSMutableDictionary *attrs = [[[self attributedStringValue ] attributesAtIndex: 0 effectiveRange: NULL] mutableCopy];
		NSString *str = [formatter stringFromDate:valuta ];
		NSFont *txtFont = [NSFont fontWithName: @"Lucida Grande" size: 10 ];
		[attrs setObject:txtFont forKey:NSFontAttributeName ];
		
		NSAttributedString *s = [[NSAttributedString alloc ] initWithString:str attributes: attrs];
		
		[super drawWithFrame:cellFrame inView:controlView ];
		NSRect r, rem;
		NSDivideRect(cellFrame, &r, &rem, 16, NSMaxYEdge);
		r.size.width -= 5;
		[s drawInRect:r ];
	} else {
		[super drawWithFrame:cellFrame inView:controlView ];		
	}
}




- copyWithZone:(NSZone *)zone
{
    DateAndValutaCell *cell = (DateAndValutaCell*)[super copyWithZone:zone];
	cell->formatter = formatter;
	if(valuta) cell->valuta = valuta; else cell->valuta = nil;
    return cell;
}


@end
