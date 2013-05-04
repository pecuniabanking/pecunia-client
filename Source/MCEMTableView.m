//
//  MCEMTableView.m
//  Pecunia
//
//  Created by Frank Emminghaus on 28.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "MCEMTableView.h"

@interface NSObject (MCEMTableView)
- (NSColor *)tableView: (MCEMTableView *)tv labelColorForRow: (int)row;
@end

@implementation MCEMTableView

- (void)drawRow: (int)rowIndex clipRect: (NSRect)clipRect
{
    NSColor *rowColor = nil;
    /* Outcommented to avoid a warning. This class will go anyway.
     if([[self delegate ] respondsToSelector: @selector(tableView:labelColorForRow:) ]) rowColor = [[self delegate] tableView:self labelColorForRow:rowIndex];
     */
    if (![[self selectedRowIndexes] containsIndex: rowIndex] && rowColor) {
        NSRect rect = [self rectOfRow: rowIndex];
        rect.origin.x += 1.0;
        rect.size.width -= 2.0;
        rect.size.height -= 3.0;
        rect.origin.y += 1.0;

        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRoundedRect: rect xRadius: 9.0 yRadius: 9.0];

        NSGradient *aGradient = [[NSGradient alloc]
                                 initWithColorsAndLocations: [NSColor whiteColor], (CGFloat) - 0.1, rowColor, (CGFloat)1.1,
                                 nil];

        [aGradient drawInBezierPath: path angle: 90.0];
    }
    [super drawRow: rowIndex clipRect: clipRect];
}

@end
