# KeyboardProvider

Small and easy to integrate project allowing the use of your Mac's keyboard in your iOS apps.

KeyboardProvider is an app running OS X Snow Leopard and higher (10.6). It monitors your keyboard state and makes it available in the form of a local server. Watch the following video: http://www.youtube.com/watch?v=cFzxoBCgNdg.

Any app can connect to the server by providing by its IP and port, and a very simple C client (~60 lines) is provided for easy set-up. The only code you have to provide is the following:

	#include "kbdclient.h"

	void init_game() {
	    kbdclient_init("127.0.0.1", 53841);
	    ...
	}

	void do_frame() {
	    if (kbdclient_held(KEY_LEFT))
	        Some action...
	}
