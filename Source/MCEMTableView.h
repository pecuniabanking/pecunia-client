//
//  MCEMTableView.h
//  Pecunia
//
//  Created by Frank Emminghaus on 28.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MCEMTableView : NSTableView {
}

- (void)drawRow: (int)rowIndex clipRect: (NSRect)clipRect;

@end
