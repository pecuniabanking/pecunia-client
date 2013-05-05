/**
 * Copyright (c) 2010, 2013, Pecunia Project. All rights reserved.
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

@class TransferTemplate;

@interface TransferTemplateController : NSWindowController {
    NSManagedObjectContext      *context;
    IBOutlet NSArrayController  *templateController;
    IBOutlet NSArrayController  *countryController;
    IBOutlet NSView             *standardView;
    IBOutlet NSView             *euView;
    IBOutlet NSView             *boxView;
    IBOutlet NSTableView        *tableView;
    IBOutlet NSSegmentedControl *segmentView;
    IBOutlet NSView             *scrollView;
    IBOutlet NSButton           *cancelButton;

    NSView  *currentView;
    NSPoint subViewPos;
    BOOL    editMode;
}

- (IBAction)segButtonPressed: (id)sender;
- (IBAction)finished: (id)sender;
- (IBAction)countryChanged: (id)sender;
- (IBAction)cancel: (id)sender;

@end
