/**
 * Copyright (c) 2010, 2012, Pecunia Project. All rights reserved.
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

#import "TransfersListview.h"

#import "TransfersController.h"
#import "TransactionController.h"
#import "PecuniaError.h"
#import "LogController.h"
#import "HBCIClient.h"
#import "MOAssistant.h"
#import "AmountCell.h"

#import "GraphicsAdditions.h"

#import "iCarousel.h"
#import "OnOffSwitchControlCell.h"

static NSString* const PecuniaTransferTemplateDataType = @"PecuniaTransferTemplateDataType";
extern NSString* const BankStatementDataType;

@interface CarouselView : iCarousel <NSDraggingSource>
{    
}

@end

@implementation CarouselView
{
}

- (void)mouseDown: (NSEvent *)theEvent
{
    NSPoint point = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    NSView *hit = [self viewAtPoint: point];
    if ([theEvent clickCount] > 1 || hit == nil || hit != self.currentItemView) {
        [super mouseDown: theEvent];
    } else {
        NSPasteboard *pasteBoard = [NSPasteboard pasteboardWithUniqueName];
        [pasteBoard setString: [NSString stringWithFormat: @"%i", self.currentItemIndex] forType: PecuniaTransferTemplateDataType];

        NSPoint location;
        location.x = hit.bounds.size.width / 2 + 20;
        location.y = 25;
        
        [self dragImage: [(NSImageView *)hit image]
                     at: location
                 offset: NSZeroSize
                  event: theEvent
             pasteboard: pasteBoard
                 source: self
              slideBack: YES];
    }
}

- (NSDragOperation)draggingSession: (NSDraggingSession *)session sourceOperationMaskForDraggingContext: (NSDraggingContext)context;
{
    return NSDragOperationCopy;
}

@end

@implementation TransferTemplateDragDestination

@synthesize controller;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self != nil) {
        formularVisible = NO;
    }
    return self;
}

#pragma mark -
#pragma mark Dragging support

- (NSDragOperation)draggingEntered: (id<NSDraggingInfo>)sender
{
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated: (id<NSDraggingInfo>)sender
{
    NSPoint location = sender.draggingLocation;
    if (NSPointInRect(location, [self dropTargetFrame])) {
        if (!formularVisible) {
            formularVisible = YES;
            NSRect formularFrame = controller.internalTransferView.frame;
            formularFrame.origin.x = 32;
            formularFrame.origin.y = 0;
            controller.internalTransferView.frame = formularFrame;

            [[self animator] addSubview: controller.internalTransferView];
        }
        return NSDragOperationCopy;
    } else {
        if (formularVisible) {
            formularVisible = NO;
            [[controller.internalTransferView animator] removeFromSuperview];
        }
        return NSDragOperationNone;
    }
}

- (void)draggingExited: (id<NSDraggingInfo>)sender
{
}

- (BOOL)prepareForDragOperation: (id<NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation: (id<NSDraggingInfo>)sender
{
    return NO;
}

- (void)concludeDragOperation: (id<NSDraggingInfo>)sender
{
    if (formularVisible) {
        formularVisible = NO;
        [controller.internalTransferView removeFromSuperview];
    }
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
}

- (BOOL)wantsPeriodicDraggingUpdates
{
    return YES;
}

/**
 * Returns the area in which a drop operation is accepted.
 */
- (NSRect)dropTargetFrame
{
    NSRect dragTargetFrame = self.frame;
    dragTargetFrame.size.width -= 150;
    dragTargetFrame.size.height = 350;
    dragTargetFrame.origin.x += 64;
    dragTargetFrame.origin.y += 35;
    
    return dragTargetFrame;
}

@end

@implementation TransfersController
@synthesize internalTransferView;

- (void)dealloc
{
    templateCarousel.delegate = nil;
	templateCarousel.dataSource = nil;

	[formatter release];
	[super dealloc];
}

- (void)awakeFromNib
{
    pendingTransfers.managedObjectContext = MOAssistant.assistant.context;
    pendingTransfers.filterPredicate = [NSPredicate predicateWithFormat: @"isSent = NO"];
    
    finishedTransfers.managedObjectContext = MOAssistant.assistant.context;
    //finishedTransfers.filterPredicate = [NSPredicate predicateWithFormat: @"isSent = YES"];

    transactionController.managedObjectContext = MOAssistant.assistant.context;

	// Sort transfer list views by date (newest first).
	NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO] autorelease];
	NSArray *sds = [NSArray arrayWithObject: sd];
	[pendingTransfers setSortDescriptors: sds];
	[finishedTransfers setSortDescriptors: sds];
	
	[transferView setDoubleAction: @selector(transferDoubleClicked:) ];
	[transferView setTarget:self ];
	
    NSDictionary* positiveAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Positive Cash"], NSForegroundColorAttributeName,
                                        nil
                                        ];
    NSDictionary* negativeAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor applicationColorForKey: @"Negative Cash"], NSForegroundColorAttributeName,
                                        nil
                                        ];
    
	formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
	[formatter setLocale:[NSLocale currentLocale]];
	[formatter setCurrencySymbol: @""];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    
    [pendingTransfersListView setCellSpacing: 0];
    [pendingTransfersListView setAllowsEmptySelection: YES];
    [pendingTransfersListView setAllowsMultipleSelection: YES];
    NSNumberFormatter* listViewFormatter = [pendingTransfersListView numberFormatter];
    [listViewFormatter setTextAttributesForPositiveValues: positiveAttributes];
    [listViewFormatter setTextAttributesForNegativeValues: negativeAttributes];
    
    [pendingTransfersListView bind: @"dataSource" toObject: pendingTransfers withKeyPath: @"arrangedObjects" options: nil];
    [pendingTransfersListView bind: @"valueArray" toObject: pendingTransfers withKeyPath: @"arrangedObjects.value" options: nil];

    [finishedTransfersListView setCellSpacing: 0];
    [finishedTransfersListView setAllowsEmptySelection: YES];
    [finishedTransfersListView setAllowsMultipleSelection: YES];
    listViewFormatter = [finishedTransfersListView numberFormatter];
    [listViewFormatter setTextAttributesForPositiveValues: positiveAttributes];
    [listViewFormatter setTextAttributesForNegativeValues: negativeAttributes];
    
    [finishedTransfersListView bind: @"dataSource" toObject: finishedTransfers withKeyPath: @"arrangedObjects" options: nil];
    [finishedTransfersListView bind: @"valueArray" toObject: finishedTransfers withKeyPath: @"arrangedObjects.value" options: nil];
    
    [carouselSwitch setOnOffSwitchControlColors: OnOffSwitchControlDefaultColors];
    [carouselSwitch setOnSwitchLabel: @"Rad"];
    [carouselSwitch setOffSwitchLabel: @"Reihe"];

    [self carouselSwitchChanged: carouselSwitch];
    templateCarousel.currentItemIndex = 4;

    rightPane.controller = self;
    [rightPane registerForDraggedTypes: [NSArray arrayWithObjects: PecuniaTransferTemplateDataType, BankStatementDataType, nil]];
}

- (void)setManagedObjectContext:(NSManagedObjectContext*)context
{
	[finishedTransfers setManagedObjectContext: context ];
	[finishedTransfers prepareContent ];
}

- (IBAction)sendTransfers: (id)sender
{
	NSArray* sel = [finishedTransfers selectedObjects ];
	if(sel == nil) return;
	
	// show log if wanted
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL showLog = [defaults boolForKey: @"logForTransfers" ];
	if (showLog) {
		LogController *logController = [LogController logController ];
		[logController showWindow:self ];
		[[logController window ] orderFront:self ];
	}
	
	BOOL sent = [[HBCIClient hbciClient ] sendTransfers: sel ];
	if(sent) {
		// save updates
		NSError *error = nil;
		NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
		if([context save: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		}
	}
}

- (IBAction)deleteTransfers: (id)sender
{
	NSError *error = nil;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	
	NSArray* sel = [finishedTransfers selectedObjects ];
	if(sel == nil || [sel count ] == 0) return;
	
	int res = NSRunAlertPanel(NSLocalizedString(@"AP14", @"Delete transfers"), 
                              NSLocalizedString(@"AP15", @"Entries will be deleted for good. Continue anyway?"),
                              NSLocalizedString(@"no", @"No"), 
                              NSLocalizedString(@"yes", @"Yes"), 
                              nil);
	if (res != NSAlertAlternateReturn) return;
	
	for (Transfer* transfer in sel) {
		[context deleteObject: transfer ];
	}
	// save updates
	if([context save: &error ] == NO) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}

- (IBAction)changeTransfer: (id)sender
{
	NSArray* sel = [finishedTransfers selectedObjects ];
	if(sel == nil || [sel count ] != 1) return;
	
	[transactionController changeTransfer: [sel objectAtIndex:0 ] ];
}

- (IBAction)transferDoubleClicked: (id)sender
{
	int row = [sender clickedRow ];
	if(row<0) return;
	
	NSArray* sel = [finishedTransfers selectedObjects ];
	if(sel == nil || [sel count ] != 1) return;
	Transfer *transfer = (Transfer*)[sel objectAtIndex:0 ];
	if ([transfer.isSent boolValue] == NO) {
		[transactionController changeTransfer: transfer ];
	}
}

- (IBAction)carouselSwitchChanged: (id)sender
{
    if (carouselSwitch.state == NSOffState) {
        templateCarousel.type = iCarouselTypeTimeMachine;
    
        templateCarousel.perspective = -0.001;
        templateCarousel.bounces = YES;
        templateCarousel.bounceDistance = 0.3;
        templateCarousel.contentOffset = CGSizeMake(0, 0);
        templateCarousel.viewpointOffset = CGSizeMake(0, 0);
    } else {
        templateCarousel.type = iCarouselTypeWheel;

        templateCarousel.perspective = -0.001;
        templateCarousel.bounces = NO;
        templateCarousel.bounceDistance = 0.3;
        templateCarousel.contentOffset = CGSizeMake(0, 0);
        templateCarousel.viewpointOffset = CGSizeMake(0, 0);
    } 
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSDecimalNumber *sum = [NSDecimalNumber zero ];
	Transfer *transfer;
	NSArray *sel = [finishedTransfers selectedObjects ];
	NSString *currency = nil;

	for(transfer in sel) {
		if ([transfer.isSent boolValue] == NO) {
			if (transfer.value) {
				sum = [sum decimalNumberByAdding:transfer.value ];
			}
			if (currency) {
				if (![transfer.currency isEqualToString:currency ]) {
					currency = @"*";
				}
			} else currency = transfer.currency;
		}
	}
	
	if(currency) [selAmountField setStringValue: [NSString stringWithFormat: @"(%@%@ ausgewählt)", [formatter stringFromNumber:sum ], currency ] ];
	else [selAmountField setStringValue: @"" ];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier ] isEqualToString: @"value" ]) {
		NSArray *transfersArray = [finishedTransfers arrangedObjects];
		Transfer *transfer = [transfersArray objectAtIndex:rowIndex ];
		
		AmountCell *cell = (AmountCell*)aCell;
		cell.objectValue = transfer.value;
		cell.currency = transfer.currency;
	}
}	

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel: (iCarousel *)carousel
{
    return 5; // Internal transfer, normal transfer, EU transfer, SEPA transfer, debit.
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel
{
    return 5;
}

- (NSView *)carousel: (iCarousel *)carousel viewForItemAtIndex: (NSUInteger)index reusingView: (NSView *)view
{
	if (view == nil)
	{
		NSImage *image;
        switch (index) {
            case 1:
                image = [NSImage imageNamed: @"transfer-normal-preview.png"];
                break;
            case 2:
                image = [NSImage imageNamed: @"transfer-eu-preview.png"];
                break;
            case 3:
                image = [NSImage imageNamed: @"transfer-sepa-preview.png"];
                break;
            case 4:
                image = [NSImage imageNamed: @"transfer-debit-preview.png"];
                break;
            default:
                image = [NSImage imageNamed: @"transfer-internal-preview.png"];
                break;
        }
       	view = [[[NSImageView alloc] initWithFrame: NSMakeRect(0, 0, image.size.width, image.size.height)] autorelease];
        [(NSImageView *)view setImage: image];
        [(NSImageView *)view setImageScaling: NSImageScaleNone];
	}
	
	return view;
}

- (NSUInteger)numberOfPlaceholdersInCarousel: (iCarousel *)carousel
{
	return NO;
}

- (CGFloat)carouselItemWidth: (iCarousel *)carousel
{
    return (carouselSwitch.state == NSOffState) ? 180 : 280;
}

- (BOOL)carouselShouldWrap: (iCarousel *)carousel
{
    return carouselSwitch.state != NSOffState;
}

/**
 * Triggered when the carousel finished its scroll animation (after either a swipe, mouse wheel
 * or mouse dragging even).
 */
- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel;
{
    [mainView setNeedsDisplay: YES];
}

#pragma mark -
#pragma mark Interface functions for main window

- (NSView *)mainView
{
    return mainView;
}

- (void)prepare
{
    
}

- (void)activate
{
    [templateCarousel layOutItemViews];
}

-(void)terminate
{
	
}

@end
