/*

GPApplicationBridge.h ... GriP Application Bridge
 
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

#import <Foundation/NSObject.h>
#import <GriP/GPApplicationBridgeC.h>

@protocol GrowlApplicationBridgeDelegate;
@class NSDictionary, NSString, GPDuplexClient;

@interface GPApplicationBridge : NSObject {
	NSObject<GrowlApplicationBridgeDelegate>* sharedDelegate;
	NSDictionary* cachedRegistrationDictionary;
	NSString* appName;
	GPDuplexClient* duplex;
}

-(void)dealloc;
-(id)init;

@property(readonly,assign,nonatomic,getter=isGrowlInstalled) BOOL installed;
@property(readonly,assign,nonatomic,getter=isGrowlRunning) BOOL running;
@property(assign,nonatomic) NSObject<GrowlApplicationBridgeDelegate>* growlDelegate;

-(void)notifyWithTitle:(NSString*)title description:(NSString*)description notificationName:(NSString*)notifName iconData:(id)iconData priority:(signed)priority isSticky:(BOOL)isSticky clickContext:(NSObject*)clickContext;
-(void)notifyWithTitle:(NSString*)title description:(NSString*)description notificationName:(NSString*)notifName iconData:(id)iconData priority:(signed)priority isSticky:(BOOL)isSticky clickContext:(NSObject*)clickContext identifier:(NSString*)identifier;
-(void)notifyWithDictionary:(NSDictionary*)userInfo;

-(BOOL)registerWithDictionary:(NSDictionary*)potentialDictionary;

// Addition for GriP
// Check if GriP is enabled for this application.
@property(readonly,assign,nonatomic) BOOL enabled;
-(BOOL)enabledForName:(NSString*)notifName;

@end