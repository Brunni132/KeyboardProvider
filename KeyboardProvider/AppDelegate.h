//
//  AppDelegate.h
//  KeyboardProvider
//
//  Created by Florian Bronnimann on 07.05.13.
//  Copyright (c) 2013 Brunni. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "InstructionsController.h"
#import "KeyServer.h"
#import "PreferencesController.h"
#import "WindowRespondingToKeys.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, KeyServerDelegate> {
	@private
	CFRunLoopSourceRef mKeyboardEventSrc;
	CFMachPortRef mMachPortRef;
	BOOL hookInstalled;
	InstructionsController *instructionsController;
	PreferencesController *preferencesController;
}


// Actions
- (IBAction)showPreferences:(id)sender;

@property (assign) IBOutlet WindowRespondingToKeys *window;
@property (strong) IBOutlet NSTextField *serverStatusField;

@end

/**
 * Private. Do not use.
 */
@interface AppDelegate(/*Private*/)

// Settings
+ (NSInteger)serverPort;
+ (NSInteger)maxClients;
+ (BOOL)globalLogging;
+ (BOOL)acceptLocalOnly;

- (BOOL)installKeyboardLogger;
- (void)uninstallKeyboardLogger;

@end
