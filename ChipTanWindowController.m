//
//  ChipTanWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 05.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "ChipTanWindowController.h"
#import "FlickerView.h"

#define FREQ_MAX 40
#define FREQ_MIN 2
#define FREQ_DEFAULT 20

#define FLICKER_SIZE_MIN 30
#define FLICKER_SIZE_MAX 60
#define FLICKER_SIZE_DEFAULT 45

@implementation ChipTanWindowController


@synthesize tan;

-(id)initWithCode:(NSString*)flickerCode message:(NSString*)msg
{
	NSString *code;
	NSUInteger i;
	
	self = [super initWithWindowNibName:@"ChipTanWindow"];
	code = @"0FFF";
	code = [code stringByAppendingString:flickerCode ];
	
	const char *cCode = [code UTF8String ];
	codeLen = strlen(cCode);
	bitString = (char*)malloc(codeLen);
	const char *c = cCode;
	int x;
	for (i=0; i < codeLen; i+=2)
	{
        sscanf(c, "%1x", &x);
		bitString[i+1] = (char)(x<<1);
        sscanf(c+1, "%1x", &x);
		bitString[i] = (char)(x<<1);
		c+=2;
	}
	frequency = FREQ_DEFAULT;
	clock = 1;
	currentCode = 0;
	message = [[msg stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"] retain ];
	return self;
}

-(void)awakeFromNib
{
	NSMutableAttributedString *msgString = [[[NSMutableAttributedString alloc] initWithHTML:[message dataUsingEncoding:NSISOLatin1StringEncoding ] documentAttributes:nil] autorelease];
	[[messageView textStorage] setAttributedString:msgString ];
	[frequencySlider setMaxValue:FREQ_MAX ];
	[frequencySlider setMinValue:FREQ_MIN ];
	frequency = (int)[frequencySlider floatValue ];
	if (frequency < FREQ_MIN || frequency > FREQ_MAX) {
		[frequencySlider setFloatValue:FREQ_DEFAULT ];
		frequency = FREQ_DEFAULT;
	}
	[sizeSlider setMaxValue:FLICKER_SIZE_MAX ];
	[sizeSlider setMinValue:FLICKER_SIZE_MIN ];
	int size = (int)[sizeSlider floatValue ];
	if (size < FLICKER_SIZE_MIN || size > FLICKER_SIZE_MAX) {
		[sizeSlider setFloatValue:FLICKER_SIZE_DEFAULT ];
	}
	flickerView.size = size;
	timer = [NSTimer timerWithTimeInterval:1.0/frequency target:self selector:@selector(clock:) userInfo:nil repeats:YES ];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
}

-(void)clock:(NSTimer*)timer
{
	char code = bitString[currentCode];
	code |= clock;
	
	flickerView.code = code;
	[flickerView setNeedsDisplay:YES ];
	
	clock -= 1;
	if (clock < 0) {
		clock = 1;
		currentCode++;
		if (currentCode >= codeLen) {
			currentCode = 0;
		}
	}
}

-(IBAction)frequencySliderChanged:(id)sender
{
	[timer invalidate ];
	frequency = (int)[frequencySlider floatValue ];
	timer = [NSTimer timerWithTimeInterval:1.0/frequency target:self selector:@selector(clock:) userInfo:nil repeats:YES ];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
}

-(IBAction)sizeSliderChanged:(id)sender
{
	int size = (int)[sizeSlider floatValue ];
	flickerView.size = size;
	[flickerView setNeedsDisplay:YES ];
}


-(void)windowWillClose:(NSNotification *)aNotification
{
	[timer invalidate ];
	if(tan == nil) [NSApp stopModalWithCode:1];
}

-(IBAction)ok:(id)sender
{
	self.tan = [tanField stringValue];
	if(self.tan) [NSApp stopModalWithCode:0];
	[[self window ] close ];
}

-(IBAction)cancel:(id)sender
{
	[[self window ] close ];
}

- (void)dealloc
{
	[tan release], tan = nil;
	[timer release ], timer = nil;
	[message release ];
	if (bitString) free(bitString);
	[super dealloc];
}

@end

