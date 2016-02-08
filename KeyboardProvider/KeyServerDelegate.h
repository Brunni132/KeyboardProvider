/**
 *  KeyServerDelegate.h
 *
 *  Author: Florian Bronnimann (florian.broennimann@lotaris.com)
 *  Date: 09.05.13
 *
 *  Description.
 */

#import <Foundation/Foundation.h>

@class KeyServer;

@protocol KeyServerDelegate <NSObject>

- (void)errorHappened:(NSString *)message critical:(BOOL)critical;
- (void)updatedConnectedClients:(KeyServer *)count;

@end
