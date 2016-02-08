//
//  AppDelegate.m
//  KeyboardProvider
//
//  Created by Florian Bronnimann on 07.05.13.
//  Copyright (c) 2013 Brunni. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Defaults
	srand((unsigned) time(nil));
	// Register defaults
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:16], @"maxclients",
								 [NSNumber numberWithInt:53841], @"serverport",
								 [NSNumber numberWithBool:YES], @"globallogging",
								 [NSNumber numberWithBool:YES], @"localonly", nil];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
 	[defaults registerDefaults:appDefaults];
	// First time: generate a random port for the server
/*	if ([AppDelegate serverPort] == 0) {
		[defaults setInteger:rand() % 32768 + 32768 forKey:@"serverport"];
		[defaults synchronize];
	}*/
	// Start server
	KeyServer *keyServer = [KeyServer sharedInstance];
	keyServer.delegate = self;
	if (![keyServer startServer]) {
		self.serverStatusField.stringValue = @"Server NOT running. Check settings and restart the app.";
	}
	// Start logging if applicable at startup
	if ([AppDelegate globalLogging])
		[self installKeyboardLogger];
	else
		self.window.enableLoggingFromWindow = YES;
	[defaults addObserver:self forKeyPath:@"globallogging" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[[NSUserDefaults standardUserDefaults] synchronize];
	[[KeyServer sharedInstance] stopServer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// Global logging state changed
	if ([AppDelegate globalLogging]) {
		[self installKeyboardLogger];
		self.window.enableLoggingFromWindow = NO;
	}
	else {
		[self uninstallKeyboardLogger];
		self.window.enableLoggingFromWindow = YES;
	}
}

- (IBAction)showPreferences:(id)sender123 {
	preferencesController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
    [preferencesController showWindow:self];
}

// MARK: KeyServerDelegate
- (void)errorHappened:(NSString *)message critical:(BOOL)critical {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:message];
	[alert beginSheetModalForWindow:self.window
					  modalDelegate:self
					 didEndSelector:nil
						contextInfo:nil];
}

- (void)updatedConnectedClients:(KeyServer*)sender {
	int clients = sender.connectedClients;
	self.serverStatusField.stringValue = [NSString stringWithFormat:@"Server listening on port %d. %d client%sconnected.", sender.port, clients, clients == 1 ? " " : "s "];
}

// MARK: Private
+ (NSInteger)serverPort {
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"serverport"];
}

+ (NSInteger)maxClients {
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"maxclients"];
}

+ (BOOL)globalLogging {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"globallogging"];
}

+ (BOOL)acceptLocalOnly {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"localonly"];
}

// Based on: http://stackoverflow.com/questions/4556278/cgeventtapcreates-watching-keyboard-input-in-cocoa
- (BOOL)installKeyboardLogger {
	if (hookInstalled)
		return NO;
	
	CGEventMask keyboardMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp);
//	CGEventMask mouseMask = CGEventMaskBit(kCGEventMouseMoved) |   CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventRightMouseDown);
	
//	CGEventMask mask = keyboardMask + mouseMask;// + mouseMask;//CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventMouseMoved);
	
	// Try to create keyboard-only hook. It will fail if Assistive Devices are not set.
	mMachPortRef =  CGEventTapCreate(kCGAnnotatedSessionEventTap,
									 kCGTailAppendEventTap, // kCGHeadInsertEventTap
									 kCGEventTapOptionListenOnly,
									 keyboardMask,
									 (CGEventTapCallBack)eventTapFunction, nil);
	if (!mMachPortRef) {
		NSLog(@"Can't install keyboard hook.");
		return NO;
	}
	else
		CFRelease(mMachPortRef);
	
/*	mMachPortRef = CGEventTapCreate(kCGAnnotatedSessionEventTap,
									kCGTailAppendEventTap, // kCGHeadInsertEventTap
									kCGEventTapOptionListenOnly,
									mask,
									(CGEventTapCallBack)eventTapFunction, nil);
	if (!mMachPortRef) {
		NSLog(@"Can't install keyboard&mouse hook.");
		return NO;
	}*/
	
	mKeyboardEventSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mMachPortRef, 0);
	if (!mKeyboardEventSrc) {
		CFRelease(mMachPortRef);
		mMachPortRef = nil;
		return NO;
	}
	
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	if (!runLoop) {
		CFRelease(mMachPortRef);
		mMachPortRef = nil;
		return NO;
	}
	
	CFRunLoopAddSource(runLoop, mKeyboardEventSrc, kCFRunLoopDefaultMode);
	hookInstalled = YES;
	NSLog(@"Hook installed");
	return YES;
}

- (void)uninstallKeyboardLogger {
	if (!hookInstalled)
		return;
	if (mMachPortRef)
		CFRelease(mMachPortRef);
	mMachPortRef = nil;
	
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	if (runLoop)
		CFRunLoopRemoveSource(runLoop, mKeyboardEventSrc, kCFRunLoopDefaultMode);
	hookInstalled = NO;
	NSLog(@"Hook uninstalled");
}

CGEventRef eventTapFunction(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
	if (type != NX_KEYDOWN && type != NX_KEYUP
		/* && type != NX_OMOUSEDOWN && type != NX_OMOUSEUP && type != NX_OMOUSEDRAGGED &&
		type != NX_LMOUSEUP && type != NX_LMOUSEDOWN && type != NX_RMOUSEUP && type != NX_RMOUSEDOWN &&
		type != NX_MOUSEMOVED && type != NX_LMOUSEDRAGGED && type != NX_RMOUSEDRAGGED*/)
		return event;
	
	NSEvent* sysEvent = [NSEvent eventWithCGEvent:event];
	if (type == NX_KEYDOWN /*&& [sysEvent type] == NSKeyDown*/) {
		if (![sysEvent isARepeat]) {
			unichar keyCode = [[sysEvent characters] characterAtIndex:0];
			[[KeyServer sharedInstance] notifyKeyDown:keyCode];
		}
	} else if (type == NX_KEYUP) {
		unichar keyCode = [[sysEvent characters] characterAtIndex:0];
		[[KeyServer sharedInstance] notifyKeyUp:keyCode];
	}
	
	return event;
}

@end
