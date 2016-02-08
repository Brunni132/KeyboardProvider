#import "AppDelegate.h"
#import "KeyServer.h"
#include <pthread.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

// Quicky read, clear or set key bit based on code (use inside class only)
#define KEY_STATE(keycode)	(keystates[keycode >> 3] & (1 << (keycode & 7)))
#define CLR_KEY_STATE(keycode)	(keystates[keycode >> 3] &= ~(1 << (keycode & 7)))
#define SET_KEY_STATE(keycode)	(keystates[keycode >> 3] |= (1 << (keycode & 7)))

@implementation KeyServer
@synthesize connectedClients, delegate, port;

+ (id)sharedInstance {
	static id instance;
	@synchronized (self) {
		return instance? instance : (instance = [[self alloc] init]);
	}
}

- (id)init {
	if ((self = [super init])) {
		sockfd = -1;
		pthread_cond_init(&nextCommandLock, NULL);
		pthread_mutex_init(&nextCommandLockMutex, NULL);
		maxClients = (int) [AppDelegate maxClients];
		clientSock = malloc(maxClients * sizeof(clientSock[0]));
		port = (int) [AppDelegate serverPort];
		for (int i = 0; i < maxClients; i++)
			clientSock[i] = -1;
	}
	return self;
}

- (BOOL)startServer {
	int portno;
	struct sockaddr_in serv_addr;
	
	NSLog(@"Starting server…");
	/* First call to socket() function */
	sockfd = socket(AF_INET, SOCK_STREAM, 0);
	if (sockfd < 0) {
		[delegate errorHappened:[NSString stringWithFormat:@"Unable to start server: %s. You need to start the app again.", strerror(errno)] critical:YES];
		return NO;
	}
	/* Initialize socket structure */
	bzero((char *) &serv_addr, sizeof (serv_addr));
	portno = port;
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = INADDR_ANY;
	serv_addr.sin_port = htons(portno);
	
	/* Now bind the host address using bind() call.*/
	if (bind(sockfd, (struct sockaddr *) &serv_addr,
			 sizeof (serv_addr)) < 0) {
		[delegate errorHappened:[NSString stringWithFormat:@"Unable to start server: %s. Please try changing the port and restart the app.", strerror(errno)] critical:YES];
		return NO;
	}
	self.connectedClients = 0;
	/* Now start listening for the clients, here
	 * process will go in sleep mode and will wait
	 * for the incoming connection
	 */
	listen(sockfd, maxClients);
	[self performSelectorInBackground:@selector(listenForClients) withObject:nil];
	return YES;
}

- (void)stopServer {
	NSLog(@"Stopping server…");
	if (sockfd != -1) {
		close(sockfd);
	}
}

- (void)notifyKeyDown:(unichar)keyId {
	SET_KEY_STATE(keyId);
	// Write command
	commandBuffer[lastCommandPtr] = keyId & 0xff;
	commandBuffer[(lastCommandPtr + 1) % sizeof(commandBuffer)] = (keyId >> 8) & 0xff;
	commandBuffer[(lastCommandPtr + 2) % sizeof(commandBuffer)] = 1;
	lastCommandPtr = (lastCommandPtr + COMMAND_SIZE) % sizeof(commandBuffer);
	// Ask worker threads to send it
	pthread_mutex_lock(&nextCommandLockMutex);
	pthread_cond_broadcast(&nextCommandLock);
	pthread_mutex_unlock(&nextCommandLockMutex);
}

- (void)notifyKeyUp:(unichar)keyId {
	CLR_KEY_STATE(keyId);
	// Write command
	commandBuffer[lastCommandPtr] = keyId & 0xff;
	commandBuffer[(lastCommandPtr + 1) % sizeof(commandBuffer)] = (keyId >> 8) & 0xff;
	commandBuffer[(lastCommandPtr + 2) % sizeof(commandBuffer)] = 0;
	lastCommandPtr = (lastCommandPtr + COMMAND_SIZE) % sizeof(commandBuffer);
	// Ask worker threads to send it
	pthread_mutex_lock(&nextCommandLockMutex);
	pthread_cond_broadcast(&nextCommandLock);
	pthread_mutex_unlock(&nextCommandLockMutex);
}

- (void)setConnectedClients:(int)newValue {
	connectedClients = newValue;
	[delegate performSelectorOnMainThread:@selector(updatedConnectedClients:) withObject:self waitUntilDone:NO];
}

- (void)listenForClients {
	struct sockaddr_in cli_addr;
	socklen_t clilen = sizeof (cli_addr);
	NSLog(@"Listening for clients…");
	
	// Create child process for working with clients
	[self performSelectorInBackground:@selector(workWithClients) withObject:nil];
	
	while (1) {
		int newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
		NSLog(@"Connected by %x", cli_addr.sin_addr.s_addr);
		if (newsockfd < 0) {
			NSLog(@"Error on accept: %s", strerror(errno));
			break;
		}
		if ([AppDelegate acceptLocalOnly] && cli_addr.sin_addr.s_addr != 0x0100007f) {
			NSLog(@"Refused non local client (addy: %x)", cli_addr.sin_addr.s_addr);
			close(newsockfd);
			continue;
		}
		
		// Ignore writes on closed sockets
		int set = 1, i;
		setsockopt(newsockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
		// Send first a list of currently held keys
		for (int keyId = 0; keyId < sizeof(keystates) * 8; keyId++) {
			if (KEY_STATE(keyId)) {
				uint8_t command[3] = {keyId & 0xff, (keyId >> 8) & 0xff, 1};
				write(newsockfd, command, sizeof(command));
			}
		}
		// Put the socket in a slot, so that it will be handled by the worker thread
		for (i = 0; i < maxClients; i++) {
			if (clientSock[i] == -1) {
				clientSock[i] = newsockfd;
				self.connectedClients++;
				break;
			}
		}
		// No room found
		if (i == maxClients) {
			[delegate errorHappened:@"Maximum number of connected clients reached." critical:NO];
			close(newsockfd);
		}
	}
}

- (void)workWithClients {
	int lastWrittenCommandPtr = lastCommandPtr;
	while (1) {
		// Wait for next comand
		pthread_mutex_lock(&nextCommandLockMutex);
		pthread_cond_wait(&nextCommandLock, &nextCommandLockMutex);
		pthread_mutex_unlock(&nextCommandLockMutex);
		// Write pending commands to all clients and check for disconnected clients
		while (lastWrittenCommandPtr != lastCommandPtr) {
			for (int i = 0; i < maxClients; i++) {
				if (clientSock[i] != -1) {
					// Disconnected?
					if (write(clientSock[i], commandBuffer + lastWrittenCommandPtr, COMMAND_SIZE) < 0) {
						close(clientSock[i]);
						clientSock[i] = -1;
						self.connectedClients--;
					}
				}
			}
			lastWrittenCommandPtr = (lastWrittenCommandPtr + COMMAND_SIZE) % sizeof(commandBuffer);
		}
	}
}

@end
