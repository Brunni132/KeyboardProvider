KeyboardProvider v1.00
Florian Bronnimann - http://www.mobile-dev.ch/
----------------------------------------------

KeyboardProvider is an app running OS X Snow Leopard and higher (10.6). It monitors your keyboard state and makes it available in the form of a local server.

Any app can connect to the server by providing by its IP and port, and a very simple C client (~60 lines) is provided for easy set-up. The only code you have to provide is the following:

#include "kbdclient.h"

void init_game() {
	// Game initialization, typically in AppDelegate, application:didFinishLaunchingWithOptions:
    kbdclient_init("127.0.0.1", 53841);
    ...
}

void do_frame() {
	// Each frame (typically the update method in an OpenGL game)
    if (kbdclient_held(KEY_LEFT))
        Some action...
}

Watch the following video for more information: http://www.youtube.com/watch?v=cFzxoBCgNdg.

LICENSE
-------

For the kbdclient.c and kbdclient.h files - MIT:
« Copyright © 2013, Florian Bronnimann
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
The Software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders X be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the Software. »

For the app (KeyboardProvider.app) - Attribution-NonCommercial-NoDerivs 3.0:
« You are free to Share — to copy, distribute and transmit the work under the following conditions:
- Attribution — You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work).
- Noncommercial — You may not use this work for commercial purposes.
- No Derivative Works — You may not alter, transform, or build upon this work. »
More info: http://creativecommons.org/licenses/by-nc-nd/3.0/

