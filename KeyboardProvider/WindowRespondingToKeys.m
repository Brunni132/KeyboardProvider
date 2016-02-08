#import "WindowRespondingToKeys.h"

@implementation WindowRespondingToKeys

- (void)keyDown:(NSEvent *)theEvent {
	if (![theEvent isARepeat]) {
		unichar keyCode = [[theEvent characters] characterAtIndex:0];
		[[KeyServer sharedInstance] notifyKeyDown:keyCode];
	}
}

- (void)keyUp:(NSEvent *)theEvent {
	unichar keyCode = [[theEvent characters] characterAtIndex:0];
	[[KeyServer sharedInstance] notifyKeyUp:keyCode];
}

@end
