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
#import "BankAccount.h"

#import "TransferFormularBackground.h"
#import "GradientButtonCell.h"

#import "GraphicsAdditions.h"
#import "AnimationHelper.h"

#import "iCarousel.h"
#import "OnOffSwitchControlCell.h"
#import "MAAttachedWindow.h"

static NSString* const PecuniaTransferTemplateDataType = @"PecuniaTransferTemplateDataType";
extern NSString* const BankStatementDataType;

@interface CarouselView : iCarousel
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
/*
- (NSDragOperation)draggingSession: (NSDraggingSession *)session sourceOperationMaskForDraggingContext: (NSDraggingContext)context;
{
    return NSDragOperationCopy;
}
*/
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
            NSRect formularFrame = controller.transferFormular.frame;
            formularFrame.origin.x = (self.bounds.size.width - formularFrame.size.width) / 2 - 10;
            formularFrame.origin.y = 0;
            
            NSString *data = [sender.draggingPasteboard stringForType: PecuniaTransferTemplateDataType];
            TransferType type;
            switch ([data intValue]) {
                case 0:
                    type = TransferTypeInternal;
                    break;
                case 2:
                    type = TransferTypeEU;
                    break;
                case 3:
                    type = TransferTypeSEPA;
                    break;
                default:
                    type = TransferTypeStandard;
                    break;
            }
            [controller prepareTransferFormular: type];
            controller.transferFormular.frame = formularFrame;

            [[self animator] addSubview: controller.transferFormular];
        }
        return NSDragOperationCopy;
    } else {
        if (formularVisible) {
            formularVisible = NO;
            [[controller.transferFormular animator] removeFromSuperview];
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
        [controller.transferFormular removeFromSuperview];
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
    dragTargetFrame.origin.x += 65;
    dragTargetFrame.origin.y += 35;
    
    return dragTargetFrame;
}

@end

@interface TransfersController (private)
- (void)prepareAccountSelectors;
- (void)hideCalendarWindow;
- (void)updateCarousel;
@end

@implementation TransfersController

@synthesize transferFormular;

- (void)dealloc
{
    templateCarousel.delegate = nil;
	templateCarousel.dataSource = nil;

	[formatter release];
    [calendarWindow release];
   
	[super dealloc];
}

- (void)awakeFromNib
{
    [[mainView window] setInitialFirstResponder: receiverComboBox];
    
    pendingTransfers.managedObjectContext = MOAssistant.assistant.context;
    pendingTransfers.filterPredicate = [NSPredicate predicateWithFormat: @"isSent = NO"];
    
    finishedTransfers.managedObjectContext = MOAssistant.assistant.context;
    finishedTransfers.filterPredicate = [NSPredicate predicateWithFormat: @"isSent = YES"];

    [transactionController setManagedObjectContext: MOAssistant.assistant.context];

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

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* values = [userDefaults objectForKey: @"transfers"];
    if (values != nil) {
        templateCarousel.type = [[values valueForKey: @"carouselType"] intValue];
    } else {
        templateCarousel.type = iCarouselTypeTimeMachine;
    }
    [self updateCarousel];

    templateCarousel.currentItemIndex = 1;

    rightPane.controller = self;
    [rightPane registerForDraggedTypes: [NSArray arrayWithObjects: PecuniaTransferTemplateDataType, BankStatementDataType, nil]];

    CALayer *layer = [queueItButton layer];
    layer.shadowColor = CGColorCreateGenericGray(0, 1);
    layer.shadowRadius = 1.0;
    layer.shadowOffset = CGSizeMake(1, -1);
    layer.shadowOpacity = 0.5;
    layer = [doItButton layer];
    layer.shadowColor = CGColorCreateGenericGray(0, 1);
    layer.shadowRadius = 1.0;
    layer.shadowOffset = CGSizeMake(1, -1);
    layer.shadowOpacity = 0.5;
    
    [self prepareAccountSelectors];
    
    executeImmediatelyRadioButton.target = self;
    executeImmediatelyRadioButton.action = @selector(executionTimeChanged:);
    executeAtDateRadioButton.target = self;
    executeAtDateRadioButton.action = @selector(executionTimeChanged:);
}

- (NSMenuItem*)createItemForAccountSelector: (Category *)category
{
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: [category localName] action: nil keyEquivalent: @""] autorelease];
    item.representedObject = category;
    
    return item;
}

- (void)prepareAccountSelectors
{
    [sourceAccountSelector removeAllItems];
    [targetAccountSelector removeAllItems];
    
    NSMenu *sourceMenu = [sourceAccountSelector menu];
    NSMenu *targetMenu = [targetAccountSelector menu];
    
    Category *category = [Category bankRoot];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey: @"localName" ascending: YES] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
    NSArray *institutes = [[category children] sortedArrayUsingDescriptors: sortDescriptors];
    
    // Convert list of accounts in their institutes branches to a flat list
    // usable by the selector.
    NSEnumerator *institutesEnumerator = [institutes objectEnumerator];
    Category *currentInstitute;
    while ((currentInstitute = [institutesEnumerator nextObject])) {
        NSMenuItem *item = [self createItemForAccountSelector: currentInstitute];
        [sourceMenu addItem: item];
        [item setEnabled: NO ];
        item = [self createItemForAccountSelector: currentInstitute];
        [item setEnabled: NO ];
        [targetMenu addItem: item];

        NSArray *accounts = [[currentInstitute children] sortedArrayUsingDescriptors: sortDescriptors];
        NSEnumerator *accountEnumerator = [accounts objectEnumerator];
        Category *currentAccount;
        while ((currentAccount = [accountEnumerator nextObject])) {
            item = [self createItemForAccountSelector: currentAccount];
            [item setEnabled: YES ];
            item.indentationLevel = 1;
            [sourceMenu addItem: item];
            item = [self createItemForAccountSelector: currentAccount];
            [item setEnabled: YES ];
            item.indentationLevel = 1;
            [targetMenu addItem: item];
        }
    }
    if (sourceMenu.numberOfItems > 1) {
        [sourceAccountSelector selectItemAtIndex: 1];
        [targetAccountSelector selectItemAtIndex: 1];
    } else {
        [sourceAccountSelector selectItemAtIndex: -1];
        [targetAccountSelector selectItemAtIndex: -1];
    }
    [self sourceAccountChanged: sourceAccountSelector];
}

/**
 * Prepares the transfer formular for the given type. Not every UI element is visible for all types
 * so we have hide what is not needed and update also some captions.
 */
- (void)prepareTransferFormular: (TransferType)type
{
    switch (type) {
        case TransferTypeInternal:
            [titleText setStringValue: NSLocalizedString(@"AP183", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP188", @"")];
            transferFormular.icon = [NSImage imageNamed: @"internal-transfer-icon.png"];
            break;
        case TransferTypeStandard:
            [titleText setStringValue: NSLocalizedString(@"AP184", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP134", @"")];
            [accountText setStringValue: NSLocalizedString(@"AP191", @"")];
            [bankCodeText setStringValue: NSLocalizedString(@"AP192", @"")];
            transferFormular.icon = [NSImage imageNamed: @"standard-transfer-icon.png"];
            break;
        case TransferTypeEU:
            [titleText setStringValue: NSLocalizedString(@"AP185", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP134", @"")];
            [accountText setStringValue: NSLocalizedString(@"AP189", @"")];
            [bankCodeText setStringValue: NSLocalizedString(@"AP190", @"")];
            transferFormular.icon = [NSImage imageNamed: @"eu-transfer-icon.png"];
            break;
        case TransferTypeSEPA:
            [titleText setStringValue: NSLocalizedString(@"AP186", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP134", @"")];
            [accountText setStringValue: NSLocalizedString(@"AP189", @"")];
            [bankCodeText setStringValue: NSLocalizedString(@"AP190", @"")];
            transferFormular.icon = [NSImage imageNamed: @"sepa-transfer-icon.png"];
            break;
        case TransferTypeDebit:
            [titleText setStringValue: NSLocalizedString(@"AP187", @"")];
            [receiverText setStringValue: NSLocalizedString(@"AP134", @"")];
            [accountText setStringValue: NSLocalizedString(@"AP191", @"")];
            [bankCodeText setStringValue: NSLocalizedString(@"AP192", @"")];
            transferFormular.icon = [NSImage imageNamed: @"debit-transfer-icon.png"];
            break;
        case TransferTypeDated: // TODO: needs to go, different transfer types allow an execution date.
            return;
            break;
    }
    
    BOOL isInternal = (type == TransferTypeInternal);
    [targetAccountSelector setHidden: !isInternal];
    [receiverComboBox setHidden: isInternal];
    [accountText setHidden: isInternal];
    [accountNumber setHidden: isInternal];
    [bankCodeText setHidden: isInternal];
    [bankCode setHidden: isInternal];

    BOOL isEUTransfer = (type == TransferTypeEU);
    [targetCountryText setHidden: !isEUTransfer];
    [targetCountrySelector setHidden: !isEUTransfer];
    [feeText setHidden: !isEUTransfer];
    [feeSelector setHidden: !isEUTransfer];
    
    [bankDescription setHidden: type != TransferTypeStandard];
    
    // These business transactions support termination:
    //   - SEPA company/normal single debit/transfer
    //   - SEPA consolidated company/normal debits/transfers
    //   - Standard company/normal single debit/transfer
    //   - Standard consolidated company/normal debits/transfers
    BOOL canBeTerminated = (type == TransferTypeSEPA) || (type == TransferTypeStandard) || (type == TransferTypeDebit);
    [executionText setHidden: !canBeTerminated];
    [executeImmediatelyRadioButton setHidden: !canBeTerminated];
    [executeImmediatelyText setHidden: !canBeTerminated];
    [executeAtDateRadioButton setHidden: !canBeTerminated];
    [executionDatePicker setHidden: !canBeTerminated];
    [calendarButton setHidden: !canBeTerminated];
    
    [self prepareAccountSelectors];
    
    // Load the set of previously entered text for the receiver combo box.
    [receiverComboBox removeAllItems];
    [receiverComboBox setStringValue: @""];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* values = [userDefaults objectForKey: @"transfers"];
    if (values != nil) {
        NSArray *previousReceivers = [values valueForKey: @"previousReceivers"];
        [receiverComboBox addItemsWithObjectValues: previousReceivers];
    }
    [amountTextField setObjectValue: [NSNumber numberWithInt: 0]];
    [accountNumber setStringValue: @""];
    [bankCode setStringValue: @""];
    [bankDescription setStringValue: @""];
    executeImmediatelyRadioButton.state = NSOnState;
    executeAtDateRadioButton.state = NSOffState;
    executionDatePicker.dateValue = [NSDate date];
}

#pragma mark -
#pragma mark Actions messages

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
    } else {
        templateCarousel.type = iCarouselTypeWheel;
    }
    [self updateCarousel];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* values = [userDefaults objectForKey: @"transfers"];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 1];
        [userDefaults setObject: values forKey: @"transfers"];
    }
    [values setValue: [NSNumber numberWithInt: templateCarousel.type] forKey: @"carouselType"];
}

- (IBAction)showCalendar: (id)sender
{
    if (calendarWindow == nil) {
        NSPoint buttonPoint = NSMakePoint(NSMidX([sender frame]),
                                          NSMidY([sender frame]));
        buttonPoint = [transferFormular convertPoint: buttonPoint toView: nil];
        calendarWindow = [[MAAttachedWindow alloc] initWithView: calendarView 
                                                attachedToPoint: buttonPoint 
                                                       inWindow: [transferFormular window] 
                                                         onSide: MAPositionTopLeft 
                                                     atDistance: 20];
        
        [calendarWindow setBackgroundColor: [NSColor colorWithCalibratedWhite: 1 alpha: 0.9]];
        [calendarWindow setViewMargin: 0];
        [calendarWindow setBorderWidth: 0];
        [calendarWindow setCornerRadius: 10];
        [calendarWindow setHasArrow: YES];
        [calendarWindow setDrawsRoundCornerBesideArrow: YES];
        
        [calendarWindow setAlphaValue: 0];
        [[sender window] addChildWindow: calendarWindow ordered: NSWindowAbove];
        [calendarWindow fadeIn];
        [calendarWindow makeKeyWindow];
    }
}

- (IBAction)calendarChanged: (id)sender
{
    [executionDatePicker setDateValue: [sender dateValue]];
    [self hideCalendarWindow];
}

- (IBAction)sourceAccountChanged: (id)sender
{
    Category *category = [sender selectedItem].representedObject;
    [saldoText setObjectValue: [category catSum]];
}

- (IBAction)executionTimeChanged: (id)sender {
    if (sender == executeImmediatelyRadioButton) {
        executeAtDateRadioButton.state = NSOffState;
        [executionDatePicker setEnabled: NO ];
        [calendarButton setEnabled: NO ];
    } else {
        executeImmediatelyRadioButton.state = NSOffState;
        [executionDatePicker setEnabled: YES ];
        [calendarButton setEnabled: YES ];
    }
}

- (void)textDidEndEditing: (NSNotification *)aNotification
{
    if (aNotification.object == bankDescription) {
        
    }
}

- (IBAction)queueTransfer:(id)sender {
}


- (IBAction)sendTransfer:(id)sender {
}

#pragma mark -
#pragma mark Other application logic

- (void)updateCarousel
{
    switch (templateCarousel.type) {
        case iCarouselTypeTimeMachine:
            templateCarousel.perspective = -0.001;
            templateCarousel.bounces = YES;
            templateCarousel.bounceDistance = 0.6;
            templateCarousel.contentOffset = CGSizeMake(0, 0);
            templateCarousel.viewpointOffset = CGSizeMake(0, 0);
            carouselSwitch.state = NSOffState;
            break;
        case iCarouselTypeWheel:
            templateCarousel.perspective = -0.001;
            templateCarousel.bounces = NO;
            templateCarousel.bounceDistance = 0.3;
            templateCarousel.contentOffset = CGSizeMake(0, 0);
            templateCarousel.viewpointOffset = CGSizeMake(0, 0);
            carouselSwitch.state = NSOnState;
            break;
        default:
            break;
    }
}

- (void)releaseCalendarWindow
{
    [[calendarButton window] removeChildWindow: calendarWindow];
    [calendarWindow orderOut: self];
    [calendarWindow release];
    calendarWindow = nil;
}

- (void)hideCalendarWindow
{
    if (calendarWindow != nil) {
        [calendarWindow fadeOut];
        
        // We need to delay the release of the calendar window
        // otherwise it will just disappear instead to fade out.
        [NSTimer scheduledTimerWithTimeInterval: .5
                                         target: self 
                                       selector: @selector(releaseCalendarWindow)
                                       userInfo: nil
                                        repeats: NO];
    }
}

- (void)tableViewSelectionDidChange: (NSNotification *)aNotification
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
    return 4; // Internal transfer, normal transfer, EU transfer, SEPA transfer (debit not yet).
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel
{
    return 10; // Must be at least number of items in the carousel.
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
    return (templateCarousel.type == iCarouselTypeWheel) ? 280 : 180;
}

- (BOOL)carouselShouldWrap: (iCarousel *)carousel
{
    return templateCarousel.type == iCarouselTypeWheel;
}

/**
 * Triggered when the carousel finished its scroll animation (after either a swipe, mouse wheel
 * or mouse dragging even).
 */
- (void)carouselDidEndScrollingAnimation: (iCarousel *)carousel;
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

- (void)deactivate
{
    [self hideCalendarWindow];
}

-(void)terminate
{
	
}

@end
