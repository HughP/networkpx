#ifndef UIKIT2_KB_TIME_H
#define UIKIT2_KB_TIME_H

#include <CoreFoundation/CFDate.h>

namespace KB {
	CFAbsoluteTime kb_time_mark(unsigned markID);
	void kb_time_elapsed_msg(unsigned markID, const char* message);	// message will be printed to stderr.
	void kb_time_elapsed(unsigned markID);	// =kb_time_elapsed_msg(markID, "elapsed: ");
};

#endif