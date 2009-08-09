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

#define GLOBALS_PREFS_PATH @"/var/mobile/Library/Preferences/.GlobalPreferences.plist"

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
			"   purge-layout <layout>\n"
			"    - Clear automatically generated cache for the specified layout.\n"
			"   purge-ime <ime>\n"
			"    - Clear automatically generated cache for the specified input\n"
			"      manager.\n\n"
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

static NSString* modeStringOf (const char* mode) {
	BOOL hasiKeyExPrefixAlready = NO;
	if (strncmp(mode, "iKeyEx:", strlen("iKeyEx:")) == 0) {
		mode += strlen("iKeyEx:");
		hasiKeyExPrefixAlready = YES;
	}
	if (!check_internal(mode))
		return nil;

	if (hasiKeyExPrefixAlready)
		return [NSString stringWithUTF8String:mode];
	else
		return [NSString stringWithFormat:@"iKeyEx:%s", mode];
}

static void Register(NSString* modeString, const char* name, const char* layout, const char* ime) {
	if (!check_internal(layout) || !check_internal(ime))
		return;
	
	NSMutableDictionary* configDict = [NSMutableDictionary dictionaryWithContentsOfFile:IKX_LIB_PATH@"/Config.plist"];
	NSMutableDictionary* modesDict = [configDict objectForKey:@"modes"];
	if ([modesDict objectForKey:modeString] != nil)
		fprintf(stderr, "Warning: Input mode '%s' was already registered. Re-registering.\n\n", [modeString UTF8String]);
	NSDictionary* regDict = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSString stringWithUTF8String:name], @"name", 
							 [NSString stringWithUTF8String:layout], @"layout",
							 [NSString stringWithUTF8String:ime], @"manager",
							 nil];
	[modesDict setObject:regDict forKey:modeString];
	[configDict writeToFile:IKX_LIB_PATH@"/Config.plist" atomically:YES];
}

static void Activate(NSString* modeString) {
	NSMutableDictionary* globalsDict = [NSMutableDictionary dictionaryWithContentsOfFile:GLOBALS_PREFS_PATH];
	[[globalsDict objectForKey:@"AppleKeyboards"] addObject:modeString];
	[globalsDict writeToFile:GLOBALS_PREFS_PATH atomically:NO];
}

static void Deactivate(NSString* modeString) {
	NSMutableDictionary* globalsDict = [NSMutableDictionary dictionaryWithContentsOfFile:GLOBALS_PREFS_PATH];
	[[globalsDict objectForKey:@"AppleKeyboards"] removeObject:modeString];
	[globalsDict writeToFile:GLOBALS_PREFS_PATH atomically:NO];	
}

static void Unregister(NSString* modeString) {
	Deactivate(modeString);
	NSMutableDictionary* configDict = [NSMutableDictionary dictionaryWithContentsOfFile:IKX_LIB_PATH@"/Config.plist"];
	[[configDict objectForKey:@"modes"] removeObjectForKey:modeString];
	[configDict writeToFile:IKX_LIB_PATH@"/Config.plist" atomically:YES];
}

static void UnregisterWhere(NSString* key, const char* matching) {
	NSString* test = [NSString stringWithUTF8String:matching];
	NSMutableDictionary* configDict = [NSMutableDictionary dictionaryWithContentsOfFile:IKX_LIB_PATH@"/Config.plist"];
	NSMutableDictionary* modesDict = [configDict objectForKey:@"modes"];
	NSMutableArray* modesToRemove = [NSMutableArray array];
	for (NSString* mode in modesDict) {
		NSDictionary* subConfigDict = [modesDict objectForKey:mode];
		if ([[subConfigDict objectForKey:key] isEqualToString:test])
			[modesToRemove addObject:mode];
	}
	[modesDict removeObjectsForKeys:modesToRemove];
	[configDict writeToFile:IKX_LIB_PATH@"/Config.plist" atomically:NO];
	
	NSMutableDictionary* globalsDict = [NSMutableDictionary dictionaryWithContentsOfFile:GLOBALS_PREFS_PATH];
	[[globalsDict objectForKey:@"AppleKeyboards"] removeObjectsInArray:modesToRemove];
	[globalsDict writeToFile:GLOBALS_PREFS_PATH atomically:NO];
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


int main (int argc, const char* argv[]) {
	if (argc > 2) {
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
		} else if (strcmp(command, "purge") == 0) {
			fprintf(stderr, "Warning: 'purge' command is deprecated in iKeyEx 3. Use 'purge-layout' instead.\n\n");
			goto deprecated_purge;
		} else if (strcmp(command, "purge-layout") == 0) {
deprecated_purge:
			if (argc < 3)
				print_arg_error("purge-layout", 1);
			else
				PurgeWithPrefix([NSString stringWithFormat:@"iKeyEx::cache::layout::%s", argv[2]]);
		} else if (strcmp(command, "purge-ime") == 0) {
			if (argc < 3)
				print_arg_error("purge-ime", 1);
			else
				PurgeWithPrefix([NSString stringWithFormat:@"iKeyEx::cache::ime::%s", argv[2]]);
		} else if (strcmp(command, "add") == 0) {
			fprintf(stderr, "Warning: 'add' command is deprecated in iKeyEx 3. Use 'register' and 'activate' instead.\n\n");
			if (argc < 3)
				fprintf(stderr, "Error: 'add' requires 1 argument.\n\n");
			else {
				NSString* ms = modeStringOf(argv[2]);
				if (ms != nil) {
					Register(ms, argv[2], argv[2], "=en_US");
					Activate(ms);
				}
			}
		} else
			fprintf(stderr, "Error: Unrecognized command '%s'.\n\n", argv[1]);
		
		[pool drain];
	} else	
		print_usage();
	
	return 0;
}
