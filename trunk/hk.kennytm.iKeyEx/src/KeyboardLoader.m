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

#import <iKeyEx/common.h>
#import <iKeyEx/KeyboardLoader.h>
#import <UIKit2/Functions.h>
#import <UIKit2/UIKeyboardLayoutQWERTY.h>
#import <UIKit2/UIKeyboardLayoutQWERTYLandscape.h>
#import <iKeyEx/UIKBStandardKeyboardLayout.h>

static NSMutableDictionary* kbcache = nil;	// Contains KeyboardBundle for all iKeyEx .keyboard's.

static NSMutableDictionary* referedManagerClasses = nil;
static NSMutableDictionary* referedLayoutClasses = nil;

//------------------------------------------------------------------------------
//-- Implementations -----------------------------------------------------------
//------------------------------------------------------------------------------

@implementation KeyboardBundle
@synthesize manager, layoutClassPortrait, layoutClassLandscape, displayName, variants;
@synthesize bundle;

-(id)objectForInfoDictionaryKey:(NSString*)key { return [bundle objectForInfoDictionaryKey:key]; }
-(NSString*)pathForResource:(NSString*)name ofType:(NSString*)extension { return [bundle pathForResource:name ofType:extension]; }
-(NSString*)localizedStringForKey:(NSString*)key { return [bundle localizedStringForKey:key value:nil table:nil]; }

-(id)initWithModeName:(NSString*)mode {
	if ((self = [super init])) {
		NSString* modeName = [mode substringFromIndex:[iKeyEx_Prefix length]];
		bundle = [[NSBundle alloc] initWithPath:[NSString stringWithFormat:iKeyEx_KeyboardsPath@"/%@.keyboard", modeName]];
		
		if (bundle == nil) {
			//[self useDefaultManager];
			[self useDefaultLayoutClassWithLandscape:NO];
			[self useDefaultLayoutClassWithLandscape:YES];
			displayName = [modeName retain];
			//variants = nil;
			return self;
		}
		
		displayName = [[bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"] retain];
		if (displayName == nil)
			displayName = [modeName retain];
		
		// Fetch input manager class.
		NSString* managerClass = [bundle objectForInfoDictionaryKey:@"UIKeyboardInputManagerClass"];
		manager = nil;
		if (![managerClass isKindOfClass:[NSString class]])
			[self useDefaultManager];
		else {
			// refered manager class. just obtain the shared instance directly.
			if ([managerClass hasPrefix:@"="]) {
				if ([managerClass hasPrefix:@"="iKeyEx_Prefix]) {
					// TODO: allow reference to other iKeyEx: modes with check of circular references. 
					//       (if we do so, make sure only a single instance is allocated...)
					[self useDefaultManager];
				} else {
					NSString* origManagerClass = [managerClass substringFromIndex:1];
					[referedManagerClasses setObject:origManagerClass forKey:mode];
					manager = [[UIKeyboardInputManager sharedInstanceForInputMode:origManagerClass] retain];
				}
			} else {
				if ([managerClass hasSuffix:@".cin"]) {
					// TODO: support .cin files.
					[self useDefaultManager];
				} else {
					Class managerCls = [bundle classNamed:managerClass];
					if (managerCls != nil) {
						manager = [[managerCls alloc] init];
					}
				}
			}
		}
		
		// Fetch layout class.
		id layoutInfo = [bundle objectForInfoDictionaryKey:@"UIKeyboardLayoutClass"];
		if ([layoutInfo isKindOfClass:[NSString class]]) {
			NSString* layoutStr = layoutInfo;
			// refered layout class. fill in the "origLayoutClassXXX" variables for later reference.
			if ([layoutStr hasPrefix:@"="]) {
				NSString* origMode = [layoutStr substringFromIndex:1];
				layoutClassPortrait = Nil;
				layoutClassLandscape = Nil;
				[referedLayoutClasses setObject:origMode forKey:mode];
				[UIKeyboardInputManager sharedInstanceForInputMode:origMode];	// force to load .artwork file into memory.
			// layout class defined on a plist. Create a copy of UIKBStandardKeyboardLayout and let the plist be loaded on runtime.
			} else {
				layoutClassPortrait = createSubclassCopy([UIKBStandardKeyboardLayout class]);
				layoutClassLandscape = createSubclassCopy([UIKBStandardKeyboardLayoutLandscape class]);
			}
		// actually defined classes in the executable.
		} else if ([layoutInfo isKindOfClass:[NSDictionary class]]) {
			NSDictionary* layoutDict = layoutInfo;
			NSString* portraitLayout = [layoutDict objectForKey:@"Portrait"];
			NSString* landscapeLayout = [layoutDict objectForKey:@"Landscape"];
			
			if ([portraitLayout isKindOfClass:[NSString class]]) {
				layoutClassPortrait = [bundle classNamed:portraitLayout];
				if (layoutClassPortrait == Nil)
					[self useDefaultLayoutClassWithLandscape:NO];
			}
			
			if ([landscapeLayout isKindOfClass:[NSString class]]) {
				layoutClassLandscape = [bundle classNamed:landscapeLayout];
				if (layoutClassLandscape == Nil)
					[self useDefaultLayoutClassWithLandscape:YES];
			}
		} else {
			[self useDefaultLayoutClassWithLandscape:NO];
			[self useDefaultLayoutClassWithLandscape:YES];
		}
		
		variants = [[NSDictionary alloc] initWithContentsOfFile:[bundle pathForResource:@"variants" ofType:@"plist"]];
	}

	return self;
}

+(KeyboardBundle*)bundleWithModeName:(NSString*)mode {
	if (mode == nil)
		return nil;
	KeyboardBundle* retval = [kbcache objectForKey:mode];
	if (retval == nil) {
		if (kbcache == nil) {
			// force loading of necessary .artwork files.
			[UIKeyboardInputManager sharedInstanceForInputMode:@"intl"];
			kbcache = [[NSMutableDictionary alloc] init];
		}
		if (referedManagerClasses == nil)
			referedManagerClasses = [[NSMutableDictionary alloc] init];
		if (referedLayoutClasses == nil)
			referedLayoutClasses = [[NSMutableDictionary alloc] init];
		retval = [[KeyboardBundle alloc] initWithModeName:mode];
		[kbcache setObject:retval forKey:mode];
		[retval release];
	}
	return retval;
}

-(void)useDefaultManager {
	[manager release];
	manager = nil; // [[UIKeyboardInputManager sharedInstanceForInputMode:@"intl"] retain];	// or "en_US" ?? [[alloc]init] ?
}

-(void)useDefaultLayoutClassWithLandscape:(BOOL)landsc {
	if (landsc) {
		layoutClassLandscape = [UIKeyboardLayoutQWERTYLandscape class];
	} else {
		layoutClassPortrait = [UIKeyboardLayoutQWERTY class];
	}
}

-(Class)layoutClassWithLandscape:(BOOL)landsc { return landsc ? layoutClassLandscape : layoutClassPortrait; }
-(NSArray*)variantsForString:(NSString*)str { return [variants objectForKey:str]; }

-(void)dealloc {
	[manager release];
	[displayName release];
	[variants release];
	[bundle unload];
	[bundle release];
	[super dealloc];
}


+(KeyboardBundle*)activeBundle {
	return [KeyboardBundle bundleWithModeName:UIKeyboardGetCurrentInputMode()];
}

+(void)clearCache {
	[kbcache release];
	kbcache = nil;
	[referedManagerClasses release];
	[referedLayoutClasses release];
}

+(NSString*)referedManagerClassForMode:(NSString*)mode {
	NSString* retval = [referedManagerClasses objectForKey:mode];
	return retval ? retval : mode;
}
+(NSString*)referedLayoutClassForMode:(NSString*)mode {
	NSString* retval = [referedLayoutClasses objectForKey:mode];
	return retval ? retval : mode;
}

@end
