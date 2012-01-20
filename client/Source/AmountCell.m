//
//  AmountCell.m
//  Pecunia
//
//  Created by Frank Emminghaus on 06.06.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "AmountCell.h"

#define CELL_BOUNDS 2

@implementation AmountCell

@synthesize amount;
@synthesize currency;
@synthesize formatter;


-(id)initTextCell:(NSString *)aString
{
	if ((self = [super initTextCell:aString ])) {
		self.formatter = [[[NSNumberFormatter alloc ] init ] autorelease ];
		[formatter setNumberStyle: NSNumberFormatterCurrencyStyle ];
		[formatter setLocale:[NSLocale currentLocale ] ];
		[formatter setCurrencySymbol:@"" ];
	}
	return  self;
}

- (id)initWithCoder:(NSCoder*)decoder {
    if ((self = [super initWithCoder:decoder ])) {
		self.formatter = [[[NSNumberFormatter alloc ] init ] autorelease ];
		[formatter setNumberStyle: NSNumberFormatterCurrencyStyle ];
		[formatter setLocale:[NSLocale currentLocale ] ];
		[formatter setCurrencySymbol:@"" ];
    }
    return self;
}

-(void)dealloc
{
	[currency release ];
	[amount release ];
	[formatter release ];
	[super dealloc ];
}

- copyWithZone:(NSZone *)zone
{
    AmountCell *cell = (AmountCell*)[super copyWithZone:zone];
	cell->formatter = [formatter retain ];
	cell->amount = [amount retain ];
	cell->currency = [currency retain ];
    return cell;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSColor *textColor;
	if([amount compare: [NSDecimalNumber zero] ] != NSOrderedAscending) textColor = [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100];
	else textColor  = [NSColor redColor];
	
	if ([self isHighlighted ]) textColor  = [NSColor whiteColor];
	
	NSMutableDictionary *attrs = [[[[self attributedStringValue ] attributesAtIndex:0 effectiveRange:NULL ] mutableCopy] autorelease];
	[attrs setObject:textColor forKey:NSForegroundColorAttributeName ];
	[formatter setCurrencyCode:currency ];
	NSString *str = [formatter stringFromNumber:amount ];
	NSAttributedString *s = [[[NSAttributedString alloc ] initWithString: str attributes: attrs] autorelease];
	
	cellFrame.origin.x += CELL_BOUNDS;
	cellFrame.size.width -= 2*CELL_BOUNDS;
	[s drawInRect:cellFrame ];
}



@end
