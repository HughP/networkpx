/*

GPMessageLog.c ... Log received GriP messages.
 
Copyright (c) 2009, KennyTM~
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

#include <pthread.h>
#include <libkern/OSAtomic.h>
#include <GriP/GPMessageLog.h>
#include <GriP/GPPreferences.h>
#include <GriP/common.h>
#include <GriP/GPMessageLogUI.h>

// assume the iPhoneOS does not appear in the reference date (1 Jan 2001). Oh well....
static uint64_t sessionID;
static int32_t messageUID;
static pthread_mutex_t logLock = PTHREAD_MUTEX_INITIALIZER;


static inline CFURLRef GPCopyMessageLogURL () {
#if GRIP_JAILBROKEN
	return CFURLCreateWithFileSystemPath(NULL, CFSTR("/Library/GriP/GPMessageLog.plist"), kCFURLPOSIXPathStyle, false);
#else
	return CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("GPMessageLog"), CFSTR("plist"), NULL);
#endif	
}

#if GRIP_JAILBROKEN
#define GPMessageLog_plist 
#else
#define GPMessageLog_plist CFSTR("/Users/kennytm/Downloads/GPMessageLog.plist")
#endif

void GPMessageLogStartNewSession() { sessionID = ((union{CFAbsoluteTime t;uint64_t i;})CFAbsoluteTimeGetCurrent()).i; messageUID = 0; }


static int compareByResolveDate (CFDictionaryRef* a, CFDictionaryRef* b) {
	CFDateRef ra = CFDictionaryGetValue(*a, GRIP_RESOLVEDATE), rb = CFDictionaryGetValue(*b, GRIP_RESOLVEDATE);
	if (ra == rb)
		return 0;
	else if (ra == NULL)
		return 1;
	else if (rb == NULL)
		return -1;
	else
		return CFDateCompare(ra, rb, NULL);
}

static CFMutableDictionaryRef GPOpenMessageLog (CFURLRef logFileURL) {
	pthread_mutex_lock(&logLock);
	CFReadStreamRef logFileStream = CFReadStreamCreateWithFile(NULL, logFileURL);
	CFMutableDictionaryRef logDict = NULL;
	CFStringRef errStr = NULL;
	if (CFReadStreamOpen(logFileStream))
		logDict = (CFMutableDictionaryRef)CFPropertyListCreateFromStream(NULL, logFileStream, 0, kCFPropertyListMutableContainers, NULL, &errStr);
	CFReadStreamClose(logFileStream);
	CFRelease(logFileStream);
	
	if (logDict == NULL) {
		CFShow(CFSTR("GriP: Error: Cannot read message log at /Library/GriP/GPMessageLog.plist."));
		if (errStr != NULL) {
			CFShow(errStr);
			CFRelease(errStr);
		}
		return NULL;
	} else if (CFGetTypeID(logDict) != CFDictionaryGetTypeID()) {
		CFShow(CFSTR("GriP: Error: Message log at /Library/GriP/GPMessageLog.plist is malformed."));
		CFRelease(logDict);
		return NULL;
	} else {
		// Drop any old messages.
		CFDictionaryRef prefs = GPCopyPreferences();
		CFNumberRef maxLogsNumber = CFDictionaryGetValue(prefs, CFSTR("LogLimit"));
		
		if (maxLogsNumber != NULL) {
			int maxLogs = 0;
			if (CFGetTypeID(maxLogsNumber) == CFNumberGetTypeID())
				CFNumberGetValue(maxLogsNumber, kCFNumberIntType, &maxLogs);
			else if (CFGetTypeID(maxLogsNumber) == CFStringGetTypeID())
				maxLogs = CFStringGetIntValue((CFStringRef)maxLogsNumber);
			CFIndex logDictCount = CFDictionaryGetCount(logDict);
			if (maxLogs > 0 && logDictCount > maxLogs) {
				CFDictionaryRef* logEntries = logDictCount > 1024 ? malloc(sizeof(CFDictionaryRef)*logDictCount) : alloca(sizeof(CFDictionaryRef)*logDictCount);
				CFDictionaryGetKeysAndValues(logDict, NULL, (const void**)logEntries);
				qsort(logEntries, logDictCount, sizeof(CFDictionaryRef), (int(*)(const void*,const void*))&compareByResolveDate);
				int itemsToDelete = logDictCount - maxLogs*2/3;
				for (int i = 0; i < itemsToDelete; ++ i) {
					CFDateRef logDate = CFDictionaryGetValue(logEntries[i], GRIP_RESOLVEDATE);
					if (logDate == NULL)
						break;
					else
						CFDictionaryRemoveValue(logDict, CFDictionaryGetValue(logEntries[i], GRIP_MSGUID));
				}
				if (logDictCount > 1024)
					free(logEntries);
			}
		}
		
		CFRelease(prefs);
		
		return logDict;
	}
}

static void GPSaveMessageLog(CFURLRef url, CFDictionaryRef logDict) {
	if (logDict != NULL) {
		CFWriteStreamRef logFileStream = CFWriteStreamCreateWithFile(NULL, url);
		if (CFWriteStreamOpen(logFileStream)) {
			CFStringRef errStr = NULL;
			if (CFPropertyListWriteToStream(logDict, logFileStream, kCFPropertyListBinaryFormat_v1_0, &errStr) == 0) {
				CFShow(CFSTR("GriP: Error: Cannot write message log to /Library/GriP/GPMessageLog.plist"));
				CFShow(errStr);
				CFRelease(errStr);
			}
		}
		CFWriteStreamClose(logFileStream);
		CFRelease(logFileStream);
		CFRelease(logDict);
	}
	pthread_mutex_unlock(&logLock);
}



void GPMessageLogAddMessage(CFMutableDictionaryRef message) {
	CFDateRef now = CFDateCreate(NULL, CFAbsoluteTimeGetCurrent());
	Boolean doLog = false;
	
	CFStringRef completeMessageUID = CFStringCreateWithFormat(NULL, NULL, CFSTR("%016llx::%d"), sessionID, OSAtomicIncrement32(&messageUID));
	CFDictionarySetValue(message, GRIP_MSGUID, completeMessageUID);
	
	// Don't pollute the message with these details.
	CFMutableDictionaryRef messageCopy = CFDictionaryCreateMutableCopy(NULL, 0, message);
	CFDictionarySetValue(messageCopy, GRIP_STATUS, CFSTR("Queuing"));
	CFDictionarySetValue(messageCopy, GRIP_QUEUEDATE, now);
	CFRelease(now);
	
	CFURLRef logFileURL = GPCopyMessageLogURL();
	CFMutableDictionaryRef logDict = GPOpenMessageLog(logFileURL);
	if (logDict != NULL) {
		CFDictionarySetValue(logDict, completeMessageUID, messageCopy);
		doLog = true;
	}
	CFRelease(messageCopy);
	GPSaveMessageLog(logFileURL, logDict);
	CFRelease(logFileURL);
	
	if (doLog) {
		CFArrayRef array = CFArrayCreate(NULL, (const void**)&completeMessageUID, 1, &kCFTypeArrayCallBacks);
		GPMessageLogRefresh(array);
		CFRelease(array);
	}
	
	CFRelease(completeMessageUID);
}


struct ResolveContext {
	CFMutableDictionaryRef logDict;
	CFStringRef status;
	CFStringRef dateKey;
	CFDateRef now;
};

static void GPMessageLogResolveMessageCallback(CFStringRef completeMessageUID, struct ResolveContext* context) {
	CFMutableDictionaryRef thisMsgDict = (CFMutableDictionaryRef)CFDictionaryGetValue(context->logDict, completeMessageUID);
	if (thisMsgDict == NULL || CFGetTypeID(thisMsgDict) != CFDictionaryGetTypeID())
		CFShow(CFSTR("GriP: Error: A message has been shown/resolved without queuing"));
	else {
		CFDictionarySetValue(thisMsgDict, context->dateKey, context->now);
		CFDictionarySetValue(thisMsgDict, GRIP_STATUS, context->status);
	}
}

void GPMessageLogShowMessages(CFArrayRef completeMessageUIDs) {
	if (CFArrayGetCount(completeMessageUIDs) == 0)
		return;
	CFDateRef now = CFDateCreate(NULL, CFAbsoluteTimeGetCurrent());
	Boolean doLog = false;
	CFURLRef logFileURL = GPCopyMessageLogURL();
	CFMutableDictionaryRef logDict = GPOpenMessageLog(logFileURL);
	if (logDict != NULL) {
		struct ResolveContext context = {logDict, CFSTR("Showing"), GRIP_SHOWDATE, now};
		CFArrayApplyFunction(completeMessageUIDs, CFRangeMake(0, CFArrayGetCount(completeMessageUIDs)), (CFArrayApplierFunction)&GPMessageLogResolveMessageCallback, &context);
		doLog = true;
	}
	GPSaveMessageLog(logFileURL, logDict);
	CFRelease(logFileURL);
	CFRelease(now);
	if (doLog)
		GPMessageLogRefresh(completeMessageUIDs);
}
void GPMessageLogResolveMessages(CFArrayRef completeMessageUIDs, SInt32 resolution) {
	if (CFArrayGetCount(completeMessageUIDs) == 0)
		return;
	CFDateRef now = CFDateCreate(NULL, CFAbsoluteTimeGetCurrent());
	Boolean doLog = false;
	CFURLRef logFileURL = GPCopyMessageLogURL();
	CFMutableDictionaryRef logDict = GPOpenMessageLog(logFileURL);
	if (logDict != NULL) {
		struct ResolveContext context = {logDict, (resolution == GriPMessage_ClickedNotification ? CFSTR("Touched") :
												   resolution == GriPMessage_CoalescedNotification ? CFSTR("Coalesced") :
												   CFSTR("Ignored")), GRIP_RESOLVEDATE, now};
		CFArrayApplyFunction(completeMessageUIDs, CFRangeMake(0, CFArrayGetCount(completeMessageUIDs)), (CFArrayApplierFunction)&GPMessageLogResolveMessageCallback, &context);
		doLog = true;
	}
	GPSaveMessageLog(logFileURL, logDict);
	CFRelease(logFileURL);
	CFRelease(now);
	if (doLog)
		GPMessageLogRefresh(completeMessageUIDs);
}