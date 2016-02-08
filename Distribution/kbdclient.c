#include "kbdclient.h"
#include <arpa/inet.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>

// Quicky read, clear or set key bit based on code (use inside class only)
#define KEY_STATE(keycode)	(keystates[keycode >> 3] & (1 << (keycode & 7)))
#define CLR_KEY_STATE(keycode)	(keystates[keycode >> 3] &= ~(1 << (keycode & 7)))
#define SET_KEY_STATE(keycode)	(keystates[keycode >> 3] |= (1 << (keycode & 7)))

static in_addr_t address;
static int port, already_started;
static uint8_t keystates[65536 / 8];
static void *server_connection(void *unused_params);

void kbdclient_init_default() {
	kbdclient_init("127.0.0.1", 53841);
}

void kbdclient_init(const char *_address, int _port) {
	// Avoid starting twice
	if (already_started)
		return;
	// Store parameters
	port = _port;
	address = inet_addr(_address);
	// Create TCP thread
	pthread_t thread_id;
	pthread_create(&thread_id, NULL, server_connection, NULL);
}

int kbdclient_held(unsigned short keycode) {
	return KEY_STATE(keycode);
}

void *server_connection(void *unused_params) {
	int sockfd = socket(AF_INET, SOCK_STREAM, 0);
	struct sockaddr_in sin;
	sin.sin_addr.s_addr = address;
	sin.sin_family = AF_INET;
	sin.sin_port = htons(port);
	if (connect(sockfd, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
		perror("kbdclient: unable to connect to key server.");
		return NULL;
	}
	printf("kbdclient: connected to key server.\n");
	memset(keystates, 0, sizeof(keystates));
	while (1) {
		uint8_t command_buffer[3];
		// Break on error
		if (recv(sockfd, command_buffer, sizeof(command_buffer), MSG_WAITALL) < 3)
			break;
		// Held or released
		unsigned short keycode = command_buffer[0] | command_buffer[1] << 8;
		if (command_buffer[2] & 1)
			SET_KEY_STATE(keycode);
		else
			CLR_KEY_STATE(keycode);
	}
	perror("kbdclient: closed connection.");
	return NULL;
}
