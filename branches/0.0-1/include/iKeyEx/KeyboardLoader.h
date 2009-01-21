/*
 
 KeyboardLoader.h ... Load iKeyEx .keyboard bundles
 
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

#import <Foundation/Foundation.h>
#import <UIKit2/UIKeyboardInputManager.h>

// This class includes all valuable information from the .keyboard's Info.plist.
// (Make the bundle as a member instead of subclass to avoid unneccesary caching across session.)
@interface KeyboardBundle : NSObject {
	NSBundle* bundle;
	UIKeyboardInputManager* manager;
	Class layoutClassPortrait;
	Class layoutClassLandscape;
	NSString* origLayoutClassPortrait;
	NSString* origLayoutClassLandscape;
	NSString* displayName;
	NSDictionary* variants;
}
@property(readonly) UIKeyboardInputManager* manager;		// The custom input manager.
@property(readonly) Class layoutClassPortrait;			// The custom layout class
@property(readonly) Class layoutClassLandscape;
@property(readonly) NSString* origLayoutClassPortrait;	// The refered input mode for layout, if any.
@property(readonly) NSString* origLayoutClassLandscape;
@property(readonly) NSString* displayName;
@property(readonly) NSDictionary* variants;
@property(readonly) NSBundle* bundle;

// proxy functions for the NSBundle. (Maybe I should setup an NSProxy instead...)
-(id)objectForInfoDictionaryKey:(NSString*)key;
-(NSString*)pathForResource:(NSString*)name ofType:(NSString*)extension;

// initializers. modename must include the "iKeyEx:" prefix.
-(id)initWithModeName:(NSString*)modeName;
+(KeyboardBundle*)bundleWithModeName:(NSString*)modeName;

// use default input manager & layout class. Don't call these directly.
-(void)useDefaultManager;
-(void)useDefaultLayoutClassWithLandscape:(BOOL)landsc;

// Obtain layout classes and referred input modes for layout classes.
-(Class)layoutClassWithLandscape:(BOOL)landsc;
-(NSString*)origLayoutClassWithLandscape:(BOOL)landsc;

// Get variants for an input.
-(NSArray*)variantsForString:(NSString*)str;

// Get the currently active keyboard bundle, if any.
+(KeyboardBundle*)activeBundle;

// Clear the bundle cache.
+(void)clearCache;
@end