//
//  PreferencesControllerWindowController.h
//  KeyboardProvider
//
//  Created by Florian Bronnimann on 10.05.13.
//  Copyright (c) 2013 Brunni. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "InstructionsController.h"

@interface PreferencesController : NSWindowController <NSTextFieldDelegate> {
	@private
	InstructionsController *instructionsController;
}

- (IBAction)showInformation:(id)sender;

@end
