//
//  MCEMTransparentTableView.m
//  Pecunia
//
//  Created by Frank Emminghaus on 31.05.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "MCEMTransparentTableView.h"


@implementation MCEMTransparentTableView

- (BOOL)isOpaque
{
    return NO;
}

- (void)drawBackgroundInClipRect: (NSRect)clipRect
{
    // don't draw a background rect
}

@end
