/*
 
FILE_NAME ... FILE_DESCRIPTION

Copyright (c) 2009  KennyTM~ <kennytm@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, 
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Neither the name of the KennyTM~ nor the names of its contributors may be
  used to endorse or promote products derived from this software without
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#include "INXCommon.h"
#include <servers/bootstrap.h>
#include <mach/mach.h>
#include <stdarg.h>
#include <CoreFoundation/CFLogUtilities.h>

static int _INXIsSpringBoard = -1;
static mach_port_t _port = MACH_PORT_NULL;

extern bool INXIsSpringBoard() {
	if (_INXIsSpringBoard == -1) {
		CFStringRef thisBundleID = CFBundleGetIdentifier(CFBundleGetMainBundle());
		_INXIsSpringBoard = CFEqual(thisBundleID, CFSTR("com.apple.springboard"));
	}
	return _INXIsSpringBoard != 0;
}

extern mach_port_t INXPort() {
	if (_port == MACH_PORT_DEAD) {
		if (!INXIsSpringBoard()) {
			mach_port_t xport = MACH_PORT_DEAD;
			kern_return_t err = bootstrap_look_up(bootstrap_port, "hk.kennytm.iNotifyEx.server", &xport);
			if (err)
				CFLog(kCFLogLevelError, CFSTR("iNotifyEx: Fail to look up service \"hk.kennytm.iNotifyEx.server\": %s"), mach_error_string(err));
			_port = xport;
		}
	}
	return _port;
}

extern CFPropertyListRef INXCreateDictionaryWithString(CFStringRef s) {
	if (s == NULL)
		return NULL;
	CFDataRef data = CFStringCreateExternalRepresentation(NULL, s, kCFStringEncodingUTF8, 0);
	if (data == NULL)
		return NULL;
	CFPropertyListRef retval = CFPropertyListCreateFromXMLData(NULL, data, kCFPropertyListImmutable, NULL);
	CFRelease(data);
	return retval;
}
