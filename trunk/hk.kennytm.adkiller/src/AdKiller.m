/*

AdKiller.m ... Ad Killer for iPhoneOS
 
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

#import <substrate.h>
#import <Foundation/Foundation.h>

typedef NSURLConnection* (*FunctorInit) (NSURLConnection* self, SEL _cmd, NSURLRequest* request, id delegate, BOOL usesCache, long long maxContentLength, BOOL startImmediately, id connectionProperties);
typedef void (*FunctorSend) (Class self, SEL _cmd, NSURLRequest* request, NSURLResponse** response, NSError** error);

static FunctorInit oldInit = NULL;
static FunctorSend oldSend = NULL;

static BOOL isAd(NSURLRequest* request) {
	NSString* url = [[request URL] absoluteString];
	// Do some check regarding url here.
	if ([url rangeOfString:@"GSContent"].location != NSNotFound)
		return YES;
	return NO;
}

static NSURLRequest* constructBadRequest(NSURLRequest* request) {
	NSMutableURLRequest* badRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"] cachePolicy:NSURLRequestReturnCacheDataDontLoad timeoutInterval:1];
	[badRequest setHTTPMethod:[request HTTPMethod]]; 
	[badRequest setHTTPShouldHandleCookies:NO];
	[badRequest setAllHTTPHeaderFields:[request allHTTPHeaderFields]];
	[badRequest setHTTPBody:[NSData data]];
	return badRequest;
}

static NSURLConnection* newInit (NSURLConnection* self, SEL _cmd, NSURLRequest* request, id delegate, BOOL usesCache, long long maxContentLength, BOOL startImmediately, id connectionProperties) {
	return oldInit(self, _cmd, isAd(request) ? constructBadRequest(request) : request, delegate, usesCache, maxContentLength, startImmediately, connectionProperties);
}
			
static void newSend (Class self, SEL _cmd, NSURLRequest* request, NSURLResponse** response, NSError** error) {
	oldSend(self, _cmd, isAd(request) ? constructBadRequest(request) : request, response, error);
}

void initialize () {
	oldInit = (FunctorInit)MSHookMessage(objc_getClass("NSURLConnection"), @selector(_initWithRequest:delegate:usesCache:maxContentLength:startImmediately:connectionProperties:), (IMP)&newInit, NULL);
	oldSend = (FunctorSend)MSHookMessage(objc_getMetaClass("NSURLConnection"), @selector(sendSynchronousRequest:returningResponse:error:), (IMP)&newSend, NULL);
}