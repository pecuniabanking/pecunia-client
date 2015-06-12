/**
 * Copyright (c) 2009, 2015, Pecunia Project. All rights reserved.
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

@class ResultParser;
@class CallbackParser;
@class LogParser;

@class HBCIError;
@class PecuniaError;
@class CallbackData;

@class AuthRequest;

@interface HBCIBridge : NSObject <NSXMLParserDelegate>

@property (readonly) AuthRequest *authRequest;

- (NSPipe *)outPipe;
- (BOOL)setResult: (id)res;
- (id)result;
- (void)startup;

- (id)syncCommand: (NSString *)cmd error: (PecuniaError **)err;
- (void)asyncCommand: (NSString *)cmd sender: (id)sender;
- (HBCIError *)error;

@end
