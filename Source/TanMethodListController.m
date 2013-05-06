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

#import "TanMethodListController.h"
#import "TanMethodOld.h"

@implementation TanMethodListController

@synthesize tanMethods;
@synthesize selectedMethod;

- (id)initWithMethods: (NSArray *)methods
{
    self = [super initWithWindowNibName: @"TanMethods"];
    if (self == nil) {
        return nil;
    }

    self.tanMethods = methods;
    return self;
}

- (void)dealloc
{
    selectedMethod = nil;
    tanMethods = nil;

}

- (IBAction)ok: (id)sender
{
    NSArray      *sel = [tanMethodController selectedObjects];
    TanMethodOld *method = sel[0];
    self.selectedMethod = method.function;

    [NSApp stopModalWithCode: 0];
    [[self window] close];
}

- (void)windowWillClose: (NSNotification *)aNotification
{
    if (selectedMethod == nil) {
        [NSApp stopModalWithCode: 1];
    }
}

- (void)windowDidLoad
{
    [tanMethodController setContent: tanMethods];
}

- (NSNumber *)selectedMethod
{
    return selectedMethod;
}

@end
