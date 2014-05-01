/**
 * Copyright (c) 2008, 2014, Pecunia Project. All rights reserved.
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

/*
 Based on ImageAndTextCell.m, supplied by Apple as example code.
 Copyright (c) 2006, Apple Computer, Inc., all rights reserved.

 Subclass of NSTextFieldCell which can display text and an image simultaneously.
 */

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell : NSTextFieldCell
{
}

@property (nonatomic, strong) NSColor           *swatchColor;
@property (nonatomic, strong) NSImage           *image;
@property (nonatomic, strong) NSString          *currency;
@property (nonatomic, strong) NSDecimalNumber   *amount;
@property (nonatomic, strong) NSNumberFormatter *amountFormatter; // TODO: why not using the cell's formatter?

- (void)setValues: (NSDecimalNumber *)aAmount
         currency: (NSString *)aCurrency
           unread: (NSInteger)unread
         disabled: (BOOL)disabled
           isRoot: (BOOL)root
         isHidden: (BOOL)hidden
        isIgnored: (BOOL)ignored;

- (void)setMaxUnread: (NSInteger)n;
- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView;

- (NSSize)sizeOfBadge: (NSInteger)unread;
- (void)drawBadgeInRect: (NSRect)badgeFrame;

@end
