//
//  PreferencesControllerWindowController.m
//  KeyboardProvider
//
//  Created by Florian Bronnimann on 10.05.13.
//  Copyright (c) 2013 Brunni. All rights reserved.
//

#import "PreferencesController.h"
#define TAG_PORT 1
#define TAG_MAXCLIENTS 2

@interface PreferencesController ()

@end

@implementation PreferencesController

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
	NSTextField* textField = [notification object];
	switch (textField.tag) {
		case TAG_PORT: {
			int value = [textField intValue];
			if (value < 1024)
				[textField setIntValue:1024];
			if (value > 65535)
				[textField setIntValue:65535];
			break;
		}
		
		case TAG_MAXCLIENTS: {
			int value = [textField intValue];
			if (value < 0)
				[textField setValue:[NSNumber numberWithInt:0]];
			break;
		}
	}
}

- (IBAction)showInformation:(id)sender {
	instructionsController = [[InstructionsController alloc] initWithWindowNibName:@"Instructions"];
    [instructionsController showWindow:self];
}

@end
