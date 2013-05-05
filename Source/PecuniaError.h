/**
 * Copyright (c) 2009, 2013, Pecunia Project. All rights reserved.
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

typedef enum {
    err_hbci_abort = 0,
    err_hbci_gen,
    err_hbci_passwd,
    err_hbci_param,
    err_gen = 100
} ErrorCode;

@interface PecuniaError : NSError {
    NSString *title;
}

@property (nonatomic, strong) NSString *title;

+ (NSError *)errorWithText: (NSString *)msg;
+ (PecuniaError *)errorWithCode: (ErrorCode)code message: (NSString *)msg;
+ (PecuniaError *)errorWithMessage: (NSString *)msg title: (NSString *)title;

- (void)alertPanel;
- (void)logMessage;

@end
