/*

GPSingleton.h ... Thread-Safe Singleton Pattern.
 
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


#ifndef GRIP_GPSINGLETON_H
#define GRIP_GPSINGLETON_H

/* Usage:
 
 GPSingletonConstructor(
	 ptr_to_singleton_obj,
	 {
		 [lots of construction statements];
		 __NEWOBJ__ = [result of construction];
		 [more construction statements];
	 },
	 {
		 [lots of destruction statements];
		 release(__NEWOBJ__);
		 [more destruction statements];
	 }
 );
 
 GPSingletonDestructor follows a similar pattern.
 
 */
// Due to use of typeof you must compile with -std=gnu99.


#if 0

#include <pthread.h>
static pthread_mutex_t wtfLock = PTHREAD_MUTEX_INITIALIZER;

#define GPSingletonConstructor(ptrobj, constructor_statement, release_statement) \
	pthread_mutex_lock(&wtfLock); \
	if ((ptrobj) == NULL) { \
		typeof(ptrobj) __NEWOBJ__ = NULL; \
		constructor_statement; \
		ptrobj = __NEWOBJ__; \
	} \
	pthread_mutex_unlock(&wtfLock)

#define GPSingletonDestructor(ptrobj, release_statement) \
	pthread_mutex_lock(&wtfLock); \
	if ((ptrobj) != NULL) { \
		typeof(ptrobj) __NEWOBJ__ = (ptrobj); \
		ptrobj = NULL; \
		release_statement; \
	} \
	pthread_mutex_unlock(&wtfLock)

#else

#include <libkern/OSAtomic.h>

#define GPSingletonConstructor(ptrobj, constructor_statement, release_statement) \
	if ((ptrobj) == NULL) { \
		typeof(ptrobj) __NEWOBJ__ = NULL; \
		constructor_statement; \
		if (!OSAtomicCompareAndSwapPtrBarrier(NULL, (void*)__NEWOBJ__, (void*volatile*)&(ptrobj))) { \
			release_statement; \
		} \
	}

// Someone please check for me if this really works. I basically modify it to do the reverse of constructor.
#define GPSingletonDestructor(ptrobj, release_statement) \
	if ((ptrobj) != NULL) { \
		typeof(ptrobj) __NEWOBJ__ = (ptrobj); \
		if (OSAtomicCompareAndSwapPtrBarrier((void*)__NEWOBJ__, NULL, (void*volatile*)&(ptrobj))) { \
			release_statement; \
		} \
	}

#endif

#endif