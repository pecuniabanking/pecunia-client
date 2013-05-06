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

#import <Cocoa/Cocoa.h>

@interface TanMediaWindowController : NSWindowController {
    IBOutlet NSTextField *messageField;
    IBOutlet NSComboBox  *tanMediaCombo;

    NSString *message;
    NSString *tanMedia;
    NSString *userId;
    NSString *bankCode;
    BOOL     active;
}
- (id)initWithUser: (NSString *)usrId bankCode: (NSString *)code message: (NSString *)msg;

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *tanMedia;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *bankCode;

@end
