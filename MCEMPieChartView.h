//
//  MCEMPieChartView.h
//  Pecunia
//
//  Created by Frank Emminghaus on 29.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SM2DGraphView/SMPieChartView.h>

@interface MCEMPieChartView : SMPieChartView {
	NSTrackingRectTag	trackingRect;
	BOOL				wasAcceptingMouseEvents;
	int					slice;
}

@end
