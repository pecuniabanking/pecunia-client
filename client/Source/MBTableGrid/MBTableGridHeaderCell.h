/*
 Copyright (c) 2008 Matthew Ball - http://www.mattballdesign.com
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Cocoa/Cocoa.h>

typedef enum _MBTableGridHeaderOrientation {
	MBTableHeaderHorizontalOrientation		= 0,
	MBTableHeaderVerticalOrientation		= 1,
	MBTableHeaderCornerOrientation			= 2
} MBTableGridHeaderOrientation;

/**
 * @brief		\c MBTableGridHeaderCell is solely
 *				responsible for drawing column and
 *				row headers.
 */
@interface MBTableGridHeaderCell : NSCell {
	MBTableGridHeaderOrientation orientation;
}

/**
 * @brief		The orientation of the header.
 * @details		Use this property to change the
 *				cell's appearance to match its
 *				orientation.
 */
@property(assign) MBTableGridHeaderOrientation orientation;

@end
