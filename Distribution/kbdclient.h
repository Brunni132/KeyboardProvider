//
//  kbdclient.h
//  Keyboard provider, http://www.mobile-dev.ch
//
//  Created by Florian Bronnimann on 11.05.13.
//
//  Usage:
//  // Default for simulator (adapt the IP if running on a real phone)
//  kbdclient_init("127.0.0.1", 53841);
//  // Then use this to get key state
//  if (kbdclient_held('a')) { ... }
//

#ifdef __cplusplus
extern "C" {
#endif

#define KEY_UP 63232
#define KEY_DOWN 63233
#define KEY_LEFT 63234
#define KEY_RIGHT 63235

extern void kbdclient_init_default();
extern void kbdclient_init(const char *address, int port);
extern int kbdclient_held(unsigned short key_code);

#ifdef __cplusplus
}
#endif
