/*

FILE_NAME ... FILE_DESCRIPTION
Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <notify.h>
#include <syslog.h>

typedef char BOOL;
static const BOOL YES = 1, NO = 0;

extern BOOL isCapable() { return YES; }
extern BOOL isEnabled() {
	uint64_t state;
	int token;
	notify_register_check("hk.kennytm.DontScrollToTop.enabled", &token);
	notify_get_state(token, &state);
	notify_cancel(token);
	return state != 0;
}
extern BOOL getStateFast() { return isEnabled(); }
extern void setState(BOOL enable) {
	int token;
	notify_register_check("hk.kennytm.DontScrollToTop.enabled", &token);
	notify_set_state(token, enable);
	notify_cancel(token);
	notify_post("hk.kennytm.DontScrollToTop.enabled");
	
}
extern float getDelayTime() { return 0.1f; }
