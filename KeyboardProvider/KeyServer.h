/**
 *  KeyServer.h
 *
 *  Author: Florian Bronnimann (florian.broennimann@lotaris.com)
 *  Date: 08.05.13
 *
 *  Description.
 */

#import <Cocoa/Cocoa.h>
#import "KeyServerDelegate.h"

#define COMMAND_SIZE 3
#define MAX_COMMANDS 128
#define numberof(o) (sizeof(o) / sizeof(*(o)))

@interface KeyServer: NSObject {
	@private
	int sockfd;
	// Connected clients - -1 indicates non connected (free slot)
	int maxClients;
	int *clientSock;
	// Bitfield -- used for new clients only
	uint8_t keystates[1 << (8 * sizeof(unichar) - 3)];
	// Command buffer, used by all client threads
	uint8_t commandBuffer[COMMAND_SIZE * MAX_COMMANDS];
	unsigned lastCommandPtr;
	pthread_cond_t nextCommandLock;
	pthread_mutex_t nextCommandLockMutex;
}

+ (KeyServer*)sharedInstance;

- (BOOL)startServer;
- (void)stopServer;

- (void)notifyKeyDown:(unichar)keyId;
- (void)notifyKeyUp:(unichar)keyId;

@property (nonatomic, strong) NSObject<KeyServerDelegate> *delegate;
@property (nonatomic) int connectedClients;
@property (nonatomic, readonly) int port;

@end

/**
 * Private. Do not use.
 */
@interface KeyServer(/*Private*/)

- (void)listenForClients;
- (void)workWithClients;

@end
