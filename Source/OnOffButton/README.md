# Cocoa On/Off Switch Control

![Screenshot](wiki/screenshot1.png)

## About

This is a fork of the original PRHOnOffButton project by Peter Hosey (boredzo). That project was awesome, but I wanted to make the switches more iOS-like, with different colors for the on/off states, as well as labels for each state. 

## Future plans

Eventually I'll make the switches also stylable, so they can be round like in iOS 5+.

## Usage

You can create iOS-like switch toggles for your cocoa apps on OS X. There are a few built in settings for changing the appearance:

    // from OnOffSwitchControlCell.h
	typedef enum {
		OnOffSwitchControlDefaultColors = 0,
		OnOffSwitchControlCustomColors = 1,
		OnOffSwitchControlBlueGreyColors = 2,
		OnOffSwitchControlGreenRedColors = 3,
		OnOffSwitchControlBlueRedColors = 4,
	} OnOffSwitchControlColors;
    
* `OnOffSwitchControlDefaultColors`: No colors for on/off states (other than the default *grey* control color).
* `OnOffSwitchControlBlueGreyColors`: Blue on state and grey off state (like in iOS).
* `OnOffSwitchControlGreenRedColors`: Red off state and green on state.
* `OnOffSwitchControlBlueRedColors`: Red off state and blue on state.
* `OnOffSwitchControlCustomColors`: Allows you to specify custom colors for the two states.

You set this flag by:

    #import "OnOffSwitchControlCell.h"
	// ...
    someInstanceOfTheControl.onOffSwitchControlColors = OnOffSwitchControlGreenRedColors;

If you use `OnOffSwitchControlCustomColors`, then you will need to specify the colors to use with the method:

	- (void) setOnOffSwitchCustomOnColor:(NSColor *)onColor offColor:(NSColor *)offColor;

If you want to turn off the labels (they are shown by default), do:

   someInstanceOfTheControl.showsOnOffLabels = NO;

If you want to change the text for the labels, do:

    someInstanceOfTheControl.onSwitchLabel = @"YES WAY!";
	someInstanceOfTheControl.offSwitchLabel = @"NO WAY!";


## Integration in your project

Basically:

1. Copy OnOffSwitchControl.h/m and OnOffSwitchControlCell.h/m (4 files in total) into your project.
2. Drag instances of "Check Box" from the library palette in Xcode 4.x onto your canvas, and change the "Class" field on the "identity inspector" tab to be "OnOffSwitchControl"; or you could create them programmatically...

## About default settings

By default the switches (at runtime) will be blue/gray for the on/off states, with "on"/"off" as the labels, but this can be overridden in two ways.

1. As explained above in the "usage" section.
2. In IB on the "Identify inspector" tab, add "user defined runtime attributes" on the `OnOffSwitchControlCell` instance, for any of the following:
    * "onOffSwitchControlColors" (Integer, see values from enum above)
	* "onSwitchLabel" (String)
	* "offSwitchLabel" (String)
	* "showsOnOffLabels" (Boolean)

The `MainMenu.xib` file has a few of the switches configured this way for reference.
