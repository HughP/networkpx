/*

iKeyEx-KBMan ... Utility for iKeyEx keyboard package management.
 
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
#import "libiKeyEx.h"
#include <notify.h>
#include "cin2pat.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#import <AppSupport/AppSupport.h>

static void print_usage () {
	fprintf(stderr,
			"Usage: iKeyEx-KBMan <options>\n"
			"\n"
			"where options are:\n"
			"   register <mode> <name> <layout> <ime>\n"
			"    - Register the input mode for using the layout and input manager.\n"
			"   activate <mode>\n"
			"    - Activate the input mode.\n"
			"   deactivate <mode>\n"
			"    - Deactivate the input mode.\n"
			"   unregister <mode>\n"
			"    - Deactivate and unregister the input mode.\n"
			"   unregister-layout <layout>\n"
			"    - Deactivate and unregister all modes using the specified layout.\n"
			"   unregister-ime <ime>\n"
			"    - Deactivate and unregister all modes using the specified input\n"
			"      manager.\n"
			"   cache-ime <ime>\n"
			"    - Generate cache for the specified input manager.\n"
			"   cache-phrase <language> <phrase>\n"
			"    - Generate cache for the specified phrase table.\n"
			"   select-phrase <lang> <phrase>\n"
			"    - Use a phrase table for a specific language.\n"
			"   select-chars <lang> <phrase>\n"
			"    - Use a characters table for a specific language.\n"
			"   deselect-phrase <lang> <phrase>\n"
			"    - Deselect a phrase table for a specific language.\n"
			"   deselect-chars <lang> <phrase>\n"
			"    - Deselect a characters table for a specific language.\n"
			"   purge-layout <layout>\n"
			"    - Clear automatically generated cache for the specified layout.\n"
			"   purge-ime <ime>\n"
			"    - Clear automatically generated cache for the specified input\n"
			"      manager.\n"
			"   purge-phrase <language> <phrase>\n"
			"    - Clear automatically generated cache for the specified phrase\n"
			"      table.\n"
			"   purge-all\n"
			"    - Clear all automatically generated cache.\n"
			"	sync\n"
			"	 - Synchronize preferences from .GlobalPreferences.plist.\n"
			"\n"
	);
}

static void print_arg_error (const char* cmd, unsigned req) {
	fprintf(stderr, "Error: '%s' requires %u argument%s\n\n", cmd, req, req==1?"":"s");
}

static BOOL check_internal (const char* x) {
	if (strncmp(x, "__", 2) == 0) {
		fprintf(stderr, "Error: Cannot manipulate internal object '%s'.\n\n", x);
		return NO;
	} else
		return YES;
}

static void SaveConfig() {
	IKXFlushConfigDictionary();
	notify_post("hk.kennytm.iKeyEx3.FlushConfigDictionary");
}

static NSString* modeStringOf (const char* mode) {
	BOOL hasiKeyExPrefixAlready = NO;
	if (strncmp(mode, "iKeyEx:", strlen("iKeyEx:")) == 0) {
		mode += strlen("iKeyEx:");
		hasiKeyExPrefixAlready = YES;
	}
	if (!check_internal(mode))
		return nil;

	if (hasiKeyExPrefixAlready)
		return [NSString stringWithUTF8String:mode-strlen("iKeyEx:")];
	else
		return [NSString stringWithFormat:@"iKeyEx:%s", mode];
}

static void Register(NSString* modeString, const char* name, const char* layout, const char* ime) {
	if (!check_internal(layout) || !check_internal(ime))
		return;
	
	NSDictionary* immModesDict = IKXConfigCopy(@"modes");
	NSMutableDictionary* modesDict = [immModesDict mutableCopy];
	[immModesDict release];
	if (modesDict == nil)
		modesDict = [[NSMutableDictionary alloc] init];
	
	if ([modesDict objectForKey:modeString] != nil)
		fprintf(stderr, "Warning: Input mode '%s' was already registered. Re-registering.\n\n", [modeString UTF8String]);
	
	NSDictionary* regDict = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSString stringWithUTF8String:name], @"name", 
							 [NSString stringWithUTF8String:layout], @"layout",
							 [NSString stringWithUTF8String:ime], @"manager",
							 nil];
	[modesDict setObject:regDict forKey:modeString];
	
	IKXConfigSet(@"modes", modesDict);
	[modesDict release];
	
	SaveConfig();
}

static NSArray* Sync() {
	CFStringRef globalPrefsDomain = CPCopySharedResourcesPreferencesDomainForDomain(CFSTR(".GlobalPreferences"));
	CFArrayRef AppleKeyboards = CFPreferencesCopyAppValue(CFSTR("AppleKeyboards"), globalPrefsDomain);
	if (AppleKeyboards == NULL)
		AppleKeyboards = CFArrayCreate(NULL, NULL, 0, &kCFTypeArrayCallBacks);
		
	IKXConfigSet(@"AppleKeyboards", (NSArray*)AppleKeyboards);
	CFRelease(globalPrefsDomain);
	
	return (NSArray*)AppleKeyboards;
}
static void ReverseSync(NSArray* arr) {
	CFStringRef globalPrefsDomain = CPCopySharedResourcesPreferencesDomainForDomain(CFSTR(".GlobalPreferences"));
	CFPreferencesSetAppValue(CFSTR("AppleKeyboards"), arr, globalPrefsDomain);
	CFPreferencesAppSynchronize(globalPrefsDomain);
	notify_post("AppleKeyboardsPreferencesChangedNotification");
	CFRelease(globalPrefsDomain);
}

static void Activate(NSString* modeString) {
	NSArray* arr = IKXConfigCopy(@"AppleKeyboards");
	if (arr == nil)
		arr = Sync();
	
	if (![arr containsObject:modeString]) {
		NSArray* arr2 = [arr arrayByAddingObject:modeString];
		IKXConfigSet(@"AppleKeyboards", arr2);
		SaveConfig();
		ReverseSync(arr2);
	}
	
	[arr release];
}

static void Deactivate(NSString* modeString) {
	NSArray* arr = IKXConfigCopy(@"AppleKeyboards");
	if (arr == nil)
		arr = Sync();

	NSUInteger i = [arr indexOfObject:modeString];
	if (i != NSNotFound) {
		NSMutableArray* arr2 = [arr mutableCopy];
		[arr2 removeObjectAtIndex:i];
		IKXConfigSet(@"AppleKeyboards", arr2);
		SaveConfig();
		ReverseSync(arr2);
		[arr2 release];
	}
	
	[arr release];
}

static void Unregister(NSString* modeString) {
	Deactivate(modeString);
	
	NSDictionary* dict = IKXConfigCopy(@"modes");
	if ([dict objectForKey:modeString]) {
		NSMutableDictionary* md = [dict mutableCopy];
		[md removeObjectForKey:modeString];
		IKXConfigSet(@"modes", dict);
		SaveConfig();
		[md release];
	}
	[dict release];
}

static void UnregisterWhere(NSString* key, const char* matching) {
	NSString* test = [NSString stringWithUTF8String:matching];
	
	NSDictionary* dict = IKXConfigCopy(@"modes");
	NSMutableArray* modesToRemove = [[NSMutableArray alloc] init];
	for (NSString* mode in dict) {
		NSDictionary* subConfigDict = [dict objectForKey:mode];
		if ([[subConfigDict objectForKey:key] isEqualToString:test])
			[modesToRemove addObject:mode];
	}
	if ([modesToRemove count] == 0) {
		[dict release];
		[modesToRemove release];
		return;
	}
	
	NSMutableDictionary* md = [dict mutableCopy];
	[dict release];
	[md removeObjectsForKeys:modesToRemove];
	IKXConfigSet(@"modes", md);
	[md release];
	
	NSArray* arr = IKXConfigCopy(@"AppleKeyboards");
	if (arr == nil)
		arr = Sync();
	NSMutableArray* ma = [arr mutableCopy];
	[arr release];
	[ma removeObjectsInArray:modesToRemove];
	[modesToRemove release];
	IKXConfigSet(@"AppleKeyboards", ma);
	ReverseSync(ma);
	[ma release];
	[arr release];
	
	SaveConfig();
}

static void PurgeWithPrefix(NSString* prefix) {
	NSFileManager* fman = [NSFileManager defaultManager];
	[fman changeCurrentDirectoryPath:IKX_SCRAP_PATH];
	for (NSString* filename in [fman contentsOfDirectoryAtPath:@"." error:NULL]) {
		if ([filename hasPrefix:prefix]) {
			NSError* err = nil;
			if (![fman removeItemAtPath:filename error:&err])
				fprintf(stderr, "Warning: Cannot remove '%s': %s.\n", [filename UTF8String], [[err localizedDescription] UTF8String]);
		}
	}
}

static void CacheIME(const char* mode) {
	NSString* imePath = [NSString stringWithFormat:IKX_LIB_PATH@"/InputManagers/%s.ime", mode];
	NSBundle* imeBundle = [NSBundle bundleWithPath:imePath];
	NSString* cinName = [imeBundle objectForInfoDictionaryKey:@"UIKeyboardInputManagerClass"];
	if (![cinName hasSuffix:@".cin"]) {
		fprintf(stderr, "Error: Cannot generate cache for non-.cin IME '%s'.\n", mode);
		return;
	}
	NSString* cinPath = [imeBundle pathForResource:cinName ofType:nil];
	NSString* patPath = [NSString stringWithFormat:IKX_SCRAP_PATH@"/iKeyEx::cache::ime::%s.pat", mode];
	NSString* knsPath = [[patPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"kns"];
	
	printf("Info: Converting .cin IME '%s' to Patricia trie dump. Please wait a few seconds... ", mode);
	IKXConvertCinToPat([cinPath UTF8String], [patPath UTF8String], [knsPath UTF8String], NULL, NULL);
	printf("Done.\n");
}

static void CachePhrase(const char* lang, const char* phrase) {
	NSString* phraseTablePath = [NSString stringWithFormat:IKX_LIB_PATH@"/Phrase/%s/%s.phrs", lang, phrase];
	NSString* triePath = [NSString stringWithFormat:IKX_SCRAP_PATH@"/iKeyEx::cache::phrase::%s::%s.phrs.pat", lang, phrase];
	
	printf("Info: Converting phrase table '%s' (%s) to Patricia trie dump. Please wait a few seconds... ", phrase, lang);
	IKXConvertPhraseToPat([phraseTablePath UTF8String], [triePath UTF8String]);
	printf("Done.\n");
}

static void SelectPhrase(const char* lang, const char* phrase, unsigned index) {
	NSDictionary* phraseDict0 = IKXConfigCopy(@"phrase");
	NSMutableDictionary* phraseDict;
	
	if (phraseDict0 == nil)
		phraseDict = [[NSMutableDictionary alloc] init];
	else
		phraseDict = [phraseDict0 mutableCopy];
	[phraseDict0 release];
	
	NSString* langStr = [NSString stringWithUTF8String:lang];
	NSMutableArray* langArr = [phraseDict objectForKey:langStr];
	if (langArr == nil)
		langArr = [[NSMutableArray alloc] initWithObjects:@"__Internal", @"__Internal", nil];
	else
		langArr = [langArr mutableCopy];
	[langArr replaceObjectAtIndex:index withObject:[NSString stringWithUTF8String:phrase]];
	[phraseDict setObject:langArr forKey:langStr];
	IKXConfigSet(@"phrase", phraseDict);
	[phraseDict release];
	
	SaveConfig();
}
static void DeselectPhrase(const char* lang, const char* phrase, unsigned index) {
	NSDictionary* phd = IKXConfigCopy(@"phrase");
	const char* curPhrase = [[[phd objectForKey:[NSString stringWithUTF8String:lang]] objectAtIndex:index] UTF8String];
	if (curPhrase != NULL && strcmp(curPhrase, phrase) == 0)
		SelectPhrase(lang, "__Internal", index);
	[phd release];
}

int main (int argc, const char* argv[]) {
	if (argc >= 2) {
		NSAutoreleasePool* pool = [NSAutoreleasePool new];
		
		const char* command = argv[1];
		
		if (strcmp(command, "register") == 0) {
			if (argc < 6)
				print_arg_error("register", 4);
			else {
				NSString* ms = modeStringOf(argv[2]);
				if (ms != nil)
					Register(ms, argv[3], argv[4], argv[5]);
			}
		} else if (strcmp(command, "activate") == 0) {
			if (argc < 3)
				print_arg_error("activate", 1);
			else {
				NSString* ms = modeStringOf(argv[2]);
				if (ms != nil)
					Activate(ms);
			}
		} else if (strcmp(command, "deactivate") == 0) {
			if (argc < 3)
				print_arg_error("deactivate", 1);
			else {
				NSString* ms = modeStringOf(argv[2]);
				if (ms != nil)
					Deactivate(ms);
			}
		} else if (strcmp(command, "unregister") == 0) {
			if (argc < 3)
				print_arg_error("unregister", 1);
			else {
				NSString* ms = modeStringOf(argv[2]);
				if (ms != nil)
					Unregister(ms);
			}
		} else if (strcmp(command, "remove") == 0) {
			fprintf(stderr, "Warning: 'remove' command is deprecated in iKeyEx 3. Use 'unregister-layout' instead.\n\n");
			goto deprecated_remove;
		} else if (strcmp(command, "unregister-layout") == 0) {
deprecated_remove:
			if (argc < 3)
				print_arg_error("unregister-layout", 1);
			else {
				if (check_internal(argv[2]))
					UnregisterWhere(@"layout", argv[2]);
			}
		} else if (strcmp(command, "unregister-ime") == 0) {
			if (argc < 3)
				print_arg_error("unregister-ime", 1);
			else {
				if (check_internal(argv[2]))
					UnregisterWhere(@"manager", argv[2]);
			}
		} else if (strcmp(command, "cache-ime") == 0) {
			if (argc < 3)
				print_arg_error("cache-ime", 1);
			else {
				if (check_internal(argv[2]))
					CacheIME(argv[2]);
			}
		} else if (strcmp(command, "cache-phrase") == 0) {
			if (argc < 4)
				print_arg_error("cache-phrase", 4);
			else {
				if (check_internal(argv[3]))
					CachePhrase(argv[2], argv[3]);
			}
		} else if (strcmp(command, "purge") == 0) {
			fprintf(stderr, "Warning: 'purge' command is deprecated in iKeyEx 3. Use 'purge-layout' instead.\n\n");
			goto deprecated_purge;
		} else if (strcmp(command, "purge-layout") == 0) {
deprecated_purge:
			if (argc < 3)
				print_arg_error("purge-layout", 1);
			else
				PurgeWithPrefix([NSString stringWithFormat:@"iKeyEx::cache::layout::iKeyEx:%s", argv[2]]);
		} else if (strcmp(command, "purge-ime") == 0) {
			if (argc < 3)
				print_arg_error("purge-ime", 1);
			else
				PurgeWithPrefix([NSString stringWithFormat:@"iKeyEx::cache::ime::%s", argv[2]]);
		} else if (strcmp(command, "purge-phrase") == 0) {
			if (argc < 4)
				print_arg_error("purge-phrase", 2);
			else
				PurgeWithPrefix([NSString stringWithFormat:@"iKeyEx::cache::phrase::%s::%s", argv[2], argv[3]]);
		} else if (strcmp(command, "purge-all") == 0) {
			PurgeWithPrefix(@"iKeyEx::cache::");
		} else if (strcmp(command, "add") == 0) {
			fprintf(stderr, "Warning: 'add' command is deprecated in iKeyEx 3. Use 'register' and 'activate' instead.\n\n");
			if (argc < 3)
				print_arg_error("add", 1);
			else {
				NSString* ms = modeStringOf(argv[2]);
				if (ms != nil) {
					Register(ms, argv[2], argv[2], "=en_US");
					Activate(ms);
				}
			}
		} else if (strcmp(command, "select-phrase") == 0) {
			if (argc < 4)
				print_arg_error("select-phrase", 2);
			else
				SelectPhrase(argv[2], argv[3], 0);
		} else if (strcmp(command, "select-chars") == 0) {
			if (argc < 4)
				print_arg_error("select-chars", 2);
			else
				SelectPhrase(argv[2], argv[3], 1);
		} else if (strcmp(command, "deselect-phrase") == 0) {
			if (argc < 4)
				print_arg_error("deselect-phrase", 2);
			else
				DeselectPhrase(argv[2], argv[3], 0);
		} else if (strcmp(command, "deselect-chars") == 0) {
			if (argc < 4)
				print_arg_error("deselect-chars", 2);
			else
				DeselectPhrase(argv[2], argv[3], 1);
		} else if (strcmp(command, "sync") == 0) {
			Sync();
		} else
			fprintf(stderr, "Error: Unrecognized command '%s'.\n\n", argv[1]);
		
		[pool drain];
	} else	
		print_usage();
	
	return 0;
}
