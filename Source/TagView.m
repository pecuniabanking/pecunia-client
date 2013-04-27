/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "TagView.h"
#import "Tag.h"

#import "MOAssistant.h"
#import "GraphicsAdditions.h"
#import "ColorPopup.h"

@interface TagAttachment : NSTextAttachment
@property (strong) id representedObject;
@property (assign) BOOL selected;
@end;

@implementation TagAttachment

@end

//----------------------------------------------------------------------------------------------------------------------

@interface TagAttachmentCell : NSTextAttachmentCell
{
    Tag *editedTag; // The tag begin edited when the color popup is displayed.
}

@property (assign) TagView *owner; // controlView in drawWithFrame can be nil so we need a separate reference.
@end

@implementation TagAttachmentCell

@synthesize owner;

#define TAG_ARROW_AREA_WIDTH 15

- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView characterIndex: (NSUInteger)charIndex
{
    // Only called for attachments, not ￼normal text. So we don't need checks if we have an attachment at that index.
    TagAttachment *attachment = [[owner textStorage] attribute: NSAttachmentAttributeName
                                                       atIndex: charIndex
                                                effectiveRange: nil];

    Tag *tag = attachment.representedObject;
    BOOL hot = owner.hotTagIndex == charIndex;

    // We don't really set an alpha value for the color but explicitely blend it to white with the
    // computed alpha. This way it appears correct with whatever background color is set.
    CGFloat alpha = attachment.selected ? 1 : (hot ? 0.7 : 0.4);
    NSColor *endColor = [NSColor colorWithCalibratedRed: tag.tagColor.redComponent * alpha + (1 - alpha)
                                                  green: tag.tagColor.greenComponent * alpha + (1 - alpha)
                                                   blue: tag.tagColor.blueComponent * alpha + (1 - alpha)
                                                  alpha: tag.tagColor.alphaComponent];
    alpha -= 0.1;
    NSColor *startColor = [NSColor colorWithCalibratedRed: tag.tagColor.redComponent * alpha + (1 - alpha)
                                                    green: tag.tagColor.greenComponent * alpha + (1 - alpha)
                                                     blue: tag.tagColor.blueComponent * alpha + (1 - alpha)
                                                    alpha: tag.tagColor.alphaComponent];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor: startColor endingColor: endColor];

    cellFrame.origin.x = (int)cellFrame.origin.x + 0.5;
    cellFrame.origin.y = (int)cellFrame.origin.y + 0.5;
    cellFrame.size.width -= 2;
    cellFrame.size.height -= 2;
    CGFloat radius = cellFrame.size.height / 2.0;
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: cellFrame xRadius: radius yRadius: radius];
    [gradient drawInBezierPath: path angle: 90];

    [tag.tagColor setStroke];
    NSAffineTransform *transform = [[NSAffineTransform alloc] init];
    //[transform translateXBy: 0.5 yBy: 0.5];
    [path transformUsingAffineTransform: transform];
    [path stroke];

    // Color drop down area.
    [NSGraphicsContext saveGraphicsState];
    NSRect buttonArea = cellFrame;
    buttonArea.size.width = TAG_ARROW_AREA_WIDTH;
    cellFrame.origin.x += TAG_ARROW_AREA_WIDTH;
    cellFrame.size.width -= TAG_ARROW_AREA_WIDTH;
    NSRectClip(buttonArea);
    [[tag.tagColor colorWithAlphaComponent: 0.5] set];
    [path fill];
    [path removeAllPoints];
    [path moveToPoint: NSMakePoint(cellFrame.origin.x - 10 , 0.5 + cellFrame.origin.y + (cellFrame.size.height - 5) / 2)];
    [path relativeLineToPoint: NSMakePoint(7, 0)];
    [path relativeLineToPoint: NSMakePoint(-3.5, 5)];
    [path relativeLineToPoint: NSMakePoint(-3.5, -5)];
    [[NSColor whiteColor] set];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSColor *textColor = attachment.selected ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite: 0 alpha: 0.75];
    NSFont *font = self.font != nil ? self.font : owner.defaultFont;
    NSDictionary *attributes = @{NSFontAttributeName: font,
                                 NSParagraphStyleAttributeName: paragraphStyle,
                                 NSForegroundColorAttributeName: textColor};
    cellFrame.origin.y -= 1;
    [tag.caption drawInRect: NSInsetRect(cellFrame, 5, 0) withAttributes: attributes];
}

- (NSRect)cellFrameForTextContainer: (NSTextContainer *)textContainer
               proposedLineFragment: (NSRect)lineFrag
                      glyphPosition: (NSPoint)position
                     characterIndex: (NSUInteger)charIndex
{
    TagAttachment *attachment = [[owner textStorage] attribute: NSAttachmentAttributeName
                                                       atIndex: charIndex
                                                effectiveRange: nil];

    NSRect result = [super cellFrameForTextContainer: textContainer
                                proposedLineFragment: lineFrag
                                       glyphPosition: position
                                      characterIndex: charIndex];

    NSString *text = [attachment.representedObject caption];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary *attributes;

    NSFont *font = self.font != nil ? self.font : owner.defaultFont;
    if (font != nil) {
        attributes = @{NSFontAttributeName: font,
                       NSParagraphStyleAttributeName: paragraphStyle};
    } else {
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
    }

    result.size = [text sizeWithAttributes: attributes];
    result.size.width = ceil(result.size.width);
    result.size.height = ceil(result.size.height);
    result.size.width += 22 + TAG_ARROW_AREA_WIDTH;
    CGFloat maxWidth = textContainer.containerSize.width - 2 * textContainer.lineFragmentPadding;
    if (result.size.width > maxWidth) {
        result.size.width = maxWidth;
    }
    result.size.height += 2;
    return result;

}

- (NSPoint)cellBaselineOffset
{
    return NSMakePoint(0, -4);
}

- (BOOL)trackMouse: (NSEvent *)theEvent
            inRect: (NSRect)cellFrame
            ofView: (NSView *)controlView
      untilMouseUp: (BOOL)flag

{
    NSPoint mousePosition = [owner convertPoint: [theEvent locationInWindow] fromView: nil];
    if (mousePosition.x - cellFrame.origin.x < TAG_ARROW_AREA_WIDTH) {
        // Our owner has its hot index set when we come here, so we can use this for getting to the
        // tag we are at.
        if (owner.hotTagIndex != NSNotFound) {
            TagAttachment *attachment = [[owner textStorage] attribute: NSAttachmentAttributeName
                                                               atIndex: owner.hotTagIndex
                                                        effectiveRange: nil];
            NSRect bounds = [owner.layoutManager boundingRectForGlyphRange: NSMakeRange(owner.hotTagIndex, 1)
                                                           inTextContainer: owner.textContainer];
            editedTag = attachment.representedObject;
            ColorPopup.sharedColorPopup.color = editedTag.tagColor;
            ColorPopup.sharedColorPopup.target = self;
            ColorPopup.sharedColorPopup.action = @selector(colorChanged:);
            [ColorPopup.sharedColorPopup popupRelativeToRect: bounds ofView: owner];
            
            return NO;
        }
    }
    return [super trackMouse: theEvent inRect: cellFrame ofView: controlView untilMouseUp: flag];
}

- (void)colorChanged: (id)sender
{
    editedTag.tagColor = ColorPopup.sharedColorPopup.color;
    [owner setNeedsDisplay: YES];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@interface TagView ()
{
    NSPopover *tagPopover;
    NSViewController *tagPopoverController;
}

@end

@implementation TagView

@synthesize datasource;
@synthesize hotTagIndex;
@synthesize defaultFont;
@synthesize canCreateNewTags;

- (void)doInit
{
    self.delegate = self;
    attachmentCell = [[TagAttachmentCell alloc] init];
    attachmentCell.owner = self;
    defaultFont = [NSFont fontWithName: @"HelveticaNeue" size: 12];

    sourceDragIndex = NSNotFound;
    hotTagIndex = NSNotFound;
    canCreateNewTags = NO;

    tagPopoverController = [[NSViewController alloc] init];
    [self setSelectedTextAttributes: nil];
}

- (id)initWithCoder: (NSCoder *)coder
{
    self = [super initWithCoder: coder];
    if (self != nil) {
        [self doInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    if (attachmentCell == nil) {
        [self doInit];
    }
}

- (NSMenu *)menuForEvent: (NSEvent *)event
{
    return nil; // No context menu.
}

- (void)updateDragTypeRegistration
{
    [self unregisterDraggedTypes];
    [self registerForDraggedTypes: @[NSStringPboardType]];
}

- (void)setDefaultFont: (NSFont *)value
{
    defaultFont = value;
    attachmentCell.font = value;
}

- (void)setDatasource: (NSArrayController *)value
{
    if (datasource != nil) {
        [datasource removeObserver: self forKeyPath: @"arrangedObjects"];
        [datasource removeObserver: self forKeyPath: @"selectedObjects"];
        [datasource removeObserver: self forKeyPath: @"selection.caption"];
        [datasource removeObserver: self forKeyPath: @"selection.tagColor"];
    }
    datasource = value;
    if (datasource != nil) {
        [datasource addObserver: self forKeyPath: @"arrangedObjects" options: 0 context: nil];
        [datasource addObserver: self forKeyPath: @"selectedObjects" options: 0 context: nil];
        [datasource addObserver: self forKeyPath: @"selection.caption" options: 0 context: nil];
        [datasource addObserver: self forKeyPath: @"selection.tagColor" options: 0 context: nil];
    }
}

- (void)setSelectedRanges: (NSArray *)ranges affinity: (NSSelectionAffinity)affinity stillSelecting: (BOOL)stillSelectingFlag;
{
    if (updatingContent) {
        [super setSelectedRanges: ranges affinity: affinity stillSelecting: stillSelectingFlag];
        return;
    }
    
    // Show selected background only for plain text, no attachment, no line end.
    // Mark attachments as selected instead. They draw their selection state differently.
    // We can only have a single selected range.

    if (self.textStorage.length > 0) {
        NSRange range = self.selectedRange;
        for (NSUInteger i = range.location; i < range.location + range.length;) {
            NSRange effectiveRange;
            [self.textStorage attribute: NSAttachmentAttributeName
                                atIndex: i
                         effectiveRange: &effectiveRange];
            [self.layoutManager removeTemporaryAttribute: NSBackgroundColorAttributeName
                                       forCharacterRange: effectiveRange];
            i += effectiveRange.length;
        }

        NSMutableArray *selectedTags = [NSMutableArray arrayWithCapacity: range.length];
        range = [ranges.lastObject rangeValue];
        for (NSUInteger i = range.location; i < range.location + range.length;) {
            NSRange effectiveRange;
            TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                            atIndex: i
                                                     effectiveRange: &effectiveRange];
            effectiveRange = NSIntersectionRange(effectiveRange, range);
            if (attachment != nil) {
                [selectedTags addObject: attachment.representedObject];
            } else {
                [self.layoutManager addTemporaryAttributes: @{NSBackgroundColorAttributeName: [NSColor selectedTextBackgroundColor]}
                                         forCharacterRange: effectiveRange];
            }
            i += effectiveRange.length;
        }

        [datasource setSelectedObjects: selectedTags];
     }

    // Let super set the insertion point and update the selectedRange(s) members.
    [super setSelectedRanges: ranges affinity: affinity stillSelecting: stillSelectingFlag];

}

- (void)convertTextToAttachment
{
    // Two runs here. We need to remove the selection before we change the content, but we should not remove
    // it if nothing is to convert. So check first if there's actually something to convert.
    BOOL needConversion = NO;
    NSUInteger i = 0;
    for (; i < self.textStorage.length;) {
        NSRange effectiveRange;
        TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                        atIndex: i
                                                 effectiveRange: &effectiveRange];
        if (attachment == nil) {
            needConversion = YES;
            break;
        }
        i += effectiveRange.length;
    }

    if (needConversion) {
        [self setSelectedRange: NSMakeRange(i + 1, 0)];

        for (NSUInteger i = 0; i < self.textStorage.length;) {
            NSRange effectiveRange;
            TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                            atIndex: i
                                                     effectiveRange: &effectiveRange];
            if (attachment == nil) {
                NSAttributedString *text = [self.textStorage attributedSubstringFromRange: effectiveRange];

                // Check if there's already a tag with that caption. Don't allow adding duplicates.
                Tag *tag = [Tag tagWithCaption: text.string];
                if (tag != nil) {
                    if ([datasource.arrangedObjects indexOfObject: tag] != NSNotFound) {
                        tag = nil;
                    }
                } else {
                    if (canCreateNewTags) {
                        tag = [Tag createTagWithCaption: text.string index: effectiveRange.location];
                    }
                }
                if (tag != nil) {
                    [datasource insertObject: tag atArrangedObjectIndex: effectiveRange.location];
                } else {
                    NSBeep();
                }
            }
            i += effectiveRange.length;
        }
    }
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (updatingContent) {
        return;
    }
    
    if ([keyPath isEqualToString: @"arrangedObjects"]) {
        updatingContent = YES;

        NSMutableAttributedString *newText = [[NSMutableAttributedString alloc] init];
        for (Tag *tag in datasource.arrangedObjects) {
            TagAttachment *attachment = [TagAttachment new];
            attachment.attachmentCell = attachmentCell;

            // Cross link attachment and tag as we need to lookup either by the other.
            attachment.representedObject = tag;

            NSAttributedString *text = [NSAttributedString attributedStringWithAttachment: attachment];
            [newText appendAttributedString: text];
        }
        
        self.textStorage.attributedString = newText;
        updatingContent = NO;
        return;
    }

    if ([keyPath isEqualToString: @"selectedObjects"]) {
        for (NSUInteger i = 0; i < self.textStorage.length;) {
            NSRange effectiveRange;
            TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                            atIndex: i
                                                     effectiveRange: &effectiveRange];
            if (attachment != nil) {
                attachment.selected = [datasource.selectedObjects containsObject: attachment.representedObject];
            }
            i += effectiveRange.length;
        }

        [self setNeedsDisplay: YES];
        return;
    }

    if ([keyPath isEqualToString: @"selection.caption"] || [keyPath isEqualToString: @"selection.tagColor"]) {
        [self setNeedsDisplay: YES];
        return;
    }
    
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

- (void)mouseMoved: (NSEvent *)theEvent
{
    [super mouseMoved: theEvent];
    [self updateTargetDropIndexAtPoint: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
}

- (void)mouseExited: (NSEvent*)theEvent
{
    [super mouseExited: theEvent];
    
    if (hotTagIndex != NSNotFound) {
        NSRect bounds = [self.layoutManager boundingRectForGlyphRange: NSMakeRange(hotTagIndex, 1)
                                                      inTextContainer: self.textContainer];
        hotTagIndex = NSNotFound;
        [self setNeedsDisplayInRect: bounds];
    }
}

- (void)mouseDown: (NSEvent *)theEvent
{
    NSPoint point = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    CGFloat fraction;
    sourceDragIndex = [self.layoutManager glyphIndexForPoint: point
                                             inTextContainer: self.textContainer
                              fractionOfDistanceThroughGlyph: &fraction];
    if (fraction >= 1) {
        sourceDragIndex = NSNotFound;
    } else {
        self.selectedRange = NSMakeRange(sourceDragIndex, 0);
    }
    hotTagIndex = sourceDragIndex; // The hot index is reset below but won't be set before the mouse is moved.

    [super mouseDown: theEvent];

    // NSTextView creates local run loops in mouseDown, so no mouseUp is generated and we actually
    // can do our mouseUp handling here.
    if (sourceDragIndex == NSNotFound) {
        [self checkForConversion];
    }

    sourceDragIndex = NSNotFound;
    hotTagIndex = NSNotFound;
}

- (void)keyDown: (NSEvent *)theEvent
{
    [super keyDown: theEvent];
    [self checkForConversion];
}

- (void)insertNewline: (id)sender
{
    [self convertTextToAttachment];
}

- (void)deleteSelection
{
    // Delete everything in the current selection.
    NSRange range = self.selectedRange;
    if (range.length == 0) {
        return;
    }
    
    NSMutableArray *candiates = [NSMutableArray arrayWithCapacity: range.length];
    NSMutableArray *ranges = [NSMutableArray arrayWithCapacity: range.length];

    for (NSUInteger i = range.location; i < range.location + range.length;) {
        NSRange effectiveRange;
        TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                        atIndex: i
                                                 effectiveRange: &effectiveRange];
        if (attachment != nil) {
            [candiates addObject: attachment.representedObject];
        } else {
            [ranges addObject: [NSValue valueWithRange: effectiveRange]];
        }
        i += effectiveRange.length;
    }

    updatingContent = YES;
    for (NSValue *value in ranges.reverseObjectEnumerator) {
        [self.textStorage deleteCharactersInRange: value.rangeValue];
    }

    for (id element in candiates) {
        [datasource removeObject: element];
    }

    range.length = 0;
    self.selectedRange = range;
    updatingContent = NO;

    [datasource rearrangeObjects];
}

- (void)deleteForward: (id)sender
{
    NSRange range = self.selectedRange;
    if (range.length > 0) {
        [self deleteSelection];
    } else {
        // Remove the char to the right of the insertion point.
        if (self.textStorage.length > 0 && range.location < self.textStorage.length) {
            TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                            atIndex: range.location
                                                     effectiveRange: nil];
            if (attachment != nil) {
                [datasource removeObject: attachment.representedObject];
            } else {
                range.length = 1;
                [self.textStorage deleteCharactersInRange: range];
            }
        }
    }
}

- (void)deleteBackward: (id)sender
{
    NSRange range = self.selectedRange;
    if (range.length > 0) {
        [self deleteSelection];
    } else {
        // Remove the char to the left of the insertion point.
        if (range.location > 0) {
            range.location--;
            TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                            atIndex: range.location
                                                     effectiveRange: nil];
            if (attachment != nil) {
                [datasource removeObject: attachment.representedObject];
            } else {
                range.length = 1;
                [self.textStorage deleteCharactersInRange: range];
            }
        }
    }
}

- (void)checkForConversion
{
    // If we end up with a selection that touches any of the attachments then check if there's
    // text that must be converted to a new tag.
    NSRange range = self.selectedRange;
    BOOL needScan = NO;

    if (range.length > 0) {
        for (NSUInteger i = range.location; i < range.location + range.length;) {
            NSRange effectiveRange;
            TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                            atIndex: i
                                                     effectiveRange: &effectiveRange];
            if (attachment != nil) {
                needScan = YES;
                break;
            }
            i += effectiveRange.length;
        }
    }

    if (needScan) {
        [self convertTextToAttachment];
    }
}

- (BOOL)shouldDrawInsertionPoint
{
    return datasource.selectedObjects.count == 0;
}

- (void)textView: (NSTextView *)textView
   clickedOnCell: (id <NSTextAttachmentCell>)cell
          inRect: (NSRect)cellFrame
         atIndex: (NSUInteger)charIndex
{
    TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                    atIndex: charIndex
                                             effectiveRange: nil];
    datasource.selectedObjects = [NSArray arrayWithObject: attachment.representedObject];
}

#pragma mark -
#pragma mark Drag and drop

- (NSDragOperation)draggingSession: (NSDraggingSession *)session
sourceOperationMaskForDraggingContext: (NSDraggingContext)context
{
    switch (context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationDelete;
            break;

        default:
            return [super draggingSession: session sourceOperationMaskForDraggingContext: context];
            break;
    }
}

- (BOOL)ignoreModifierKeysForDraggingSession: (NSDraggingSession *)session
{
    return YES;
}

/**
 * Determines the index under the mouse. For highlighting we use the index only if the mouse is actually
 * within the tag bounds. For selection purposes we return the index as it was found even if the mouse pointer
 * is outside the tag bounds.
 */
- (NSUInteger)updateTargetDropIndexAtPoint: (NSPoint)point
{
    CGFloat fraction;
    NSUInteger index = [self.layoutManager glyphIndexForPoint: point
                                              inTextContainer: self.textContainer
                               fractionOfDistanceThroughGlyph: &fraction];
    NSUInteger caretIndex = index;
    if (fraction > 0.5) {
        caretIndex++;
    }

    // For highlighting a tag we have to check if the mouse is actually within the tag.
    NSRect bounds = [self.layoutManager boundingRectForGlyphRange: NSMakeRange(index, 1)
                                                  inTextContainer: self.textContainer];
    NSUInteger newIndex;
    if (NSPointInRect(point, bounds)) {
        newIndex = index;
    } else {
        newIndex = NSNotFound;
    }
    if (hotTagIndex != newIndex) {
        NSRect oldBounds = [self.layoutManager boundingRectForGlyphRange: NSMakeRange(hotTagIndex, 1)
                                                         inTextContainer: self.textContainer];
        [self setNeedsDisplayInRect: oldBounds];
        hotTagIndex = newIndex;
        [self setNeedsDisplayInRect: bounds];
    }

    return caretIndex;
}

- (NSDragOperation)draggingUpdated: (id <NSDraggingInfo>)sender
{
    NSUInteger index = [self updateTargetDropIndexAtPoint: [self convertPoint: sender.draggingLocation fromView: nil]];
    self.selectedRange = NSMakeRange(index, 0);

    if (sender.draggingSource == self) {
        return NSDragOperationMove;
    }
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation: (id<NSDraggingInfo>)sender
{
    hotTagIndex = NSNotFound;
    
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    NSPoint location = [self convertPoint: sender.draggingLocation fromView: nil];
    CGFloat fraction;
    NSUInteger targetIndex = [self.layoutManager glyphIndexForPoint: location
                                                    inTextContainer: self.textContainer
                                     fractionOfDistanceThroughGlyph: &fraction];

    if (fraction > 0.5) {
        // Fraction determines the position relative to the target glyph.
        // Values < 0.5 are left from the middle and vice versa.
        targetIndex++;
    }

    if (sourceDragIndex != NSNotFound) {
        // Moving tag within the view.
        if (sourceDragIndex == targetIndex) {
            return NO;
        }

        Tag *target = nil;
        if (targetIndex < self.textStorage.length) {
            TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                                            atIndex: targetIndex
                                                     effectiveRange: nil];
            target = attachment.representedObject;
        }

        TagAttachment *attachment = [self.textStorage attribute: NSAttachmentAttributeName
                                         atIndex: sourceDragIndex
                                  effectiveRange: nil];
        [attachment.representedObject sortBefore: target];
    } else {
        // Something was dragged in from outside.
        if ([sender.draggingSource isKindOfClass: [TagView class]]) {
            // It's a tag.
            TagView *source = sender.draggingSource;
            TagAttachment *attachment = [source.textStorage attribute: NSAttachmentAttributeName
                                                              atIndex: source->sourceDragIndex
                                                       effectiveRange: nil];
            [datasource insertObject: attachment.representedObject atArrangedObjectIndex: targetIndex];
        } else {
            // Plain text.
            NSAttributedString *text = [[NSAttributedString alloc] initWithString: [pasteboard stringForType: NSStringPboardType]];
            if (text.length > 1) {
                [self.textStorage insertAttributedString: text atIndex: targetIndex];
                [self convertTextToAttachment];
            }
        }
    }
    [datasource rearrangeObjects];

    return YES;
}

- (void)createPopoverWithHost: (NSView *)host
{
    tagPopoverController.view = host;

    tagPopover = [[NSPopover alloc] init];
    tagPopover.contentViewController = tagPopoverController;
    tagPopover.behavior = NSPopoverBehaviorSemitransient;
    tagPopover.delegate = self;
}

/**
 * Displays a popover window with a tag view to select tags from and edit them.
 */
- (void)showTagPopupAt: (NSRect)rect forView: (NSView *)owner host: (NSView *)host
{
    if (tagPopover.shown) {
        return;
    }

    [self createPopoverWithHost: host];
    [tagPopover showRelativeToRect: rect ofView: owner preferredEdge: NSMinYEdge];
}

#pragma mark -
#pragma mark Popover Delegate Methods

- (void)popoverDidClose:(NSNotification *)notification
{
    tagPopover = nil;
}

@end

//----------------------------------------------------------------------------------------------------------------------
