/*

Pref.m ... Pref bundle for iKeyEx
 
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

#import <Preferences/Preferences.h>
#import <UIKit/UIKit2.h>
#import "libiKeyEx.h"
#include <notify.h>
#include <sys/types.h>
#include <sys/stat.h>

#define LS(key) ([selfBundle localizedStringForKey:(key) value:nil table:@"iKeyEx"])

static NSArray* allSupportedModesSorted = nil;

static NSComparisonResult sortByMovingIKXKeyboardsToFront(NSString* a, NSString* b, NSString* priortyLang) {
	BOOL ai = IKXIsiKeyExMode(a), bi = IKXIsiKeyExMode(b);
	if (ai == bi) {
		ai = [a hasPrefix:priortyLang];
		bi = [b hasPrefix:priortyLang];
		if (ai == bi)
			return [IKXNameOfMode(a) localizedCaseInsensitiveCompare:IKXNameOfMode(b)];
	}
	if (ai)
		return NSOrderedAscending;
	else
		return NSOrderedDescending;
}

static NSUInteger setKeyboards(UIKeyboardImpl* impl, NSArray* keyboards) {
	if ([keyboards count] == 0)
		keyboards = [NSArray arrayWithObject:@"en_US"];
	UIKeyboardSetActiveInputModes(keyboards);
	[impl setInputModePreference];
	[impl setInputMode:[keyboards lastObject]];
	return [keyboards count];
}

static void saveConfig() {
	IKXFlushConfigDictionary();
	notify_post("hk.kennytm.iKeyEx3.FlushConfigDictionary");
	notify_post("AppleKeyboardsPreferencesChangedNotification");
}

static void recomputeAllModes() {
	saveConfig();
	NSString* curLang = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
	allSupportedModesSorted = [[UIKeyboardGetSupportedInputModes() sortedArrayUsingFunction:(void*)sortByMovingIKXKeyboardsToFront context:curLang] retain];
}



@interface iKeyExEditKeyboardController : PSListController {
	NSArray* layoutRefs;
	NSArray* layoutTitles;
	NSArray* imeRefs;
	NSArray* imeTitles;
	
	NSMutableDictionary* subConfigDict;
	NSString* modeName;
}
@property(retain,nonatomic) NSString* displayName, *layout, *ime;
@end
@implementation iKeyExEditKeyboardController
-(id)initForContentSize:(CGSize)size {
	if ((self = [super initForContentSize:size])) {
		NSFileManager* fman = [NSFileManager defaultManager];
		[fman changeCurrentDirectoryPath:IKX_LIB_PATH@"/Keyboards"];
		
		NSMutableArray* refs = [NSMutableArray array], *titles = [NSMutableArray array];
		for (NSString* mode in allSupportedModesSorted) {
			if (!IKXIsiKeyExMode(mode)) {
				[refs addObject:[@"=" stringByAppendingString:mode]];
				[titles addObject:IKXNameOfMode(mode)];
			}
		}
		
		NSArray* layouts = [fman contentsOfDirectoryAtPath:@"." error:NULL];
		NSMutableArray* layoutRefs1 = [NSMutableArray array], *layoutTitles1 = [NSMutableArray array];
		for (NSString* bundle in layouts) {
			if ([bundle hasSuffix:@".keyboard"] && ![bundle hasPrefix:@"__"]) {
				NSString* bundleName = [bundle stringByDeletingPathExtension];
				[layoutRefs1 addObject:bundleName];
				[layoutTitles1 addObject:[[NSBundle bundleWithPath:bundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: bundleName];
			}
		}
		[layoutRefs1 addObjectsFromArray:refs];
		[layoutTitles1 addObjectsFromArray:titles];
		
		layoutRefs = [layoutRefs1 retain];
		layoutTitles = [layoutTitles1 retain];
		
		[fman changeCurrentDirectoryPath:IKX_LIB_PATH@"/InputManagers"];
		NSArray* imes = [fman contentsOfDirectoryAtPath:@"." error:NULL];
		NSMutableArray* imeRefs1 = [NSMutableArray array], *imeTitles1 = [NSMutableArray array];
		for (NSString* bundle in imes) {
			if ([bundle hasSuffix:@".ime"] && ![bundle hasPrefix:@"__"]) {
				NSString* bundleName = [bundle stringByDeletingPathExtension];
				[imeRefs1 addObject:bundleName];
				[imeTitles1 addObject:[[NSBundle bundleWithPath:bundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: bundleName];
			}
		}
		[imeRefs1 addObjectsFromArray:refs];
		[imeTitles1 addObjectsFromArray:titles];
		
		imeRefs = [imeRefs1 retain];
		imeTitles = [imeTitles1 retain];
	}
	return self;
}
-(void)suspend {
	NSDictionary* modesDict = IKXConfigCopy(@"modes");
	NSMutableDictionary* mmd = [modesDict mutableCopy];
	[modesDict release];
	if ([[subConfigDict objectForKey:@"name"] length] == 0) {
		[mmd removeObjectForKey:modeName];
		NSArray* activeModes = UIKeyboardGetActiveInputModes();
		NSUInteger curModeLoc = [activeModes indexOfObject:modeName];
		if (curModeLoc != NSNotFound) {
			NSMutableArray* newActiveModes = [activeModes mutableCopy];
			[newActiveModes removeObjectAtIndex:curModeLoc];
			setKeyboards([UIKeyboardImpl sharedInstance], newActiveModes);
			[newActiveModes release];
		}
	} else {
		[mmd setObject:subConfigDict forKey:modeName];
	}
	IKXConfigSet(@"modes", mmd);
	[mmd release];
	[self.specifier->target performSelector:@selector(reloadSpecifiers)];
	[super suspend];
}
-(void)dealloc {
	[layoutRefs release];
	[layoutTitles release];
	[imeRefs release];
	[imeTitles release];
	[modeName release];
	[subConfigDict release];
	[super dealloc];
}
-(NSString*)ime { return [subConfigDict objectForKey:@"manager"]; }
-(void)setIme:(NSString*)x { [subConfigDict setObject:(x?:@"=en_US") forKey:@"manager"]; }
-(NSString*)layout { return [subConfigDict objectForKey:@"layout"]; }
-(void)setLayout:(NSString*)x { [subConfigDict setObject:(x?:@"=en_US") forKey:@"layout"]; }
-(NSString*)displayName { return [subConfigDict objectForKey:@"name"]; }
-(void)setDisplayName:(NSString*)x { if ([x length] > 0) { [subConfigDict setObject:x forKey:@"name"]; } }

-(void)deleteMode {
	// This will indirectly tell -suspend to delete this mode.
	[subConfigDict setObject:@"" forKey:@"name"];
	[self.parentController popController];
}

-(NSArray*)specifiers {
	if (_specifiers == nil) {
		PSSpecifier* selfSpec = self.specifier;
		modeName = [[selfSpec propertyForKey:@"modeName"] retain];
		BOOL modeNameWasNil = (modeName == nil);
		NSDictionary* modesDict = IKXConfigCopy(@"modes");
		if (modeNameWasNil) {
			CFUUIDRef uuid = CFUUIDCreate(NULL);
			CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
			modeName = [[@"iKeyEx:" stringByAppendingString:(NSString*)uuidString] retain];
			subConfigDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"=en_US", @"layout", @"=en_US", @"manager", @"", @"name", nil];
			NSMutableDictionary* mmd = [modesDict mutableCopy];
			[mmd setObject:subConfigDict forKey:modeName];
			IKXConfigSet(@"modes", mmd);
			[mmd release];
			CFRelease(uuidString);
			CFRelease(uuid);
		} else {
			subConfigDict = [[modesDict objectForKey:modeName] mutableCopy];
		}
		[modesDict release];
		
		NSMutableArray* specs = [NSMutableArray arrayWithObject:[PSSpecifier emptyGroupSpecifier]];
		
		NSBundle* selfBundle = [self bundle];
		
		PSSpecifier* layoutSpec = [PSSpecifier preferenceSpecifierNamed:LS(@"Layout") target:self set:@selector(setLayout:) get:@selector(layout) detail:[PSListItemsController class] cell:PSLinkListCell edit:Nil];
		layoutSpec.titleDictionary = [NSDictionary dictionaryWithObjects:layoutTitles forKeys:layoutRefs];
		layoutSpec.values = layoutRefs;
		[specs addObject:layoutSpec];
		
		PSSpecifier* imeSpec = [PSSpecifier preferenceSpecifierNamed:LS(@"Input manager") target:self set:@selector(setIme:) get:@selector(ime) detail:[PSListItemsController class] cell:PSLinkListCell edit:Nil];
		imeSpec.titleDictionary = [NSDictionary dictionaryWithObjects:imeTitles forKeys:imeRefs];
		imeSpec.values = imeRefs;
		[specs addObject:imeSpec];
		
		PSSpecifier* displayNameSpec = [PSSpecifier preferenceSpecifierNamed:LS(@"Name") target:self set:@selector(setDisplayName:) get:@selector(displayName) detail:[PSDetailController class] cell:PSLinkListCell edit:[PSTextEditingPane class]];
		[specs addObject:displayNameSpec];
		
		if (!modeNameWasNil) {
			[specs addObject:[PSSpecifier emptyGroupSpecifier]];
			
			NSString* delStr = LS(@"Delete");
			
			PSConfirmationSpecifier* deleteSpec = [PSConfirmationSpecifier preferenceSpecifierNamed:delStr target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
			deleteSpec->action = @selector(deleteMode);
			[deleteSpec setProperty:(id)kCFBooleanTrue forKey:@"isDestructive"];
			[deleteSpec setupWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:delStr, @"okTitle", LS(@"Cancel"), @"cancelTitle", nil]];
			[specs addObject:deleteSpec];
		}
		
		_specifiers = [specs retain];
	}
	return _specifiers;
}
@end



@interface iKeyExMixAndMatchController : PSListController {
}
@end
@implementation iKeyExMixAndMatchController
-(NSArray*)specifiers {
	if (_specifiers == nil) {
		NSMutableArray* specs = [NSMutableArray new];
		
		NSDictionary* modesDict = IKXConfigCopy(@"modes");
		for (NSString* modeName in modesDict) {
			if (!IKXIsInternalMode(modeName)) {
				PSSpecifier* linker = [PSSpecifier preferenceSpecifierNamed:[[modesDict objectForKey:modeName] objectForKey:@"name"] target:self set:NULL get:NULL detail:[iKeyExEditKeyboardController class] cell:PSLinkCell edit:Nil];
				[linker setProperty:modeName forKey:@"modeName"];
				[specs addObject:linker];
			}
		}
		[modesDict release];
		
		[specs sortUsingSelector:@selector(titleCompare:)];
		
		NSBundle* selfBundle = [self bundle];
		
		NSArray* topSpecs = [NSArray arrayWithObjects:
							 [PSSpecifier emptyGroupSpecifier],
							 [PSSpecifier preferenceSpecifierNamed:LS(@"Make") target:self set:NULL get:NULL detail:[iKeyExEditKeyboardController class] cell:PSLinkCell edit:Nil],
							 [PSSpecifier emptyGroupSpecifier],
							 nil];
		[specs insertObjects:topSpecs atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
		
		_specifiers = specs;
	}
	return _specifiers;
}
-(void)suspend {
	recomputeAllModes();
	[super suspend];
}
@end

#pragma mark -

@interface iKeyExCustomizeController : PSListController
@end
@implementation iKeyExCustomizeController
static void prepareLinks(iKeyExCustomizeController* self, NSString* suffix, NSMutableArray* layoutLinks, NSFileManager* fman) {
	for (NSString* path in [fman contentsOfDirectoryAtPath:@"." error:NULL]) {
		if ([path hasSuffix:suffix]) {
			NSBundle* bdl = [NSBundle bundleWithPath:path];
			NSString* psBundlePath = [bdl pathForResource:[bdl objectForInfoDictionaryKey:@"PSBundle"] ofType:@"bundle"];
			if (psBundlePath != nil) {
				PSSpecifier* linkCell = [PSSpecifier preferenceSpecifierNamed:[path stringByDeletingPathExtension]
																	   target:self set:NULL get:NULL detail:Nil cell:PSLinkCell edit:Nil];
				[linkCell setProperty:psBundlePath forKey:@"lazy-bundle"];
				linkCell->action = @selector(lazyLoadBundle:);
				
				[layoutLinks addObject:linkCell];
			}
		}
	}
}

-(NSArray*)specifiers {
	if (_specifiers == nil) {
		NSMutableArray* specs = [NSMutableArray new];
		
		NSBundle* selfBundle = [self bundle];
		NSFileManager* fman = [NSFileManager defaultManager];
		
		NSMutableArray* layoutLinks = [NSMutableArray array];
		[fman changeCurrentDirectoryPath:IKX_LIB_PATH@"/Keyboards"];
		prepareLinks(self, @".keyboard", layoutLinks, fman);
		if ([layoutLinks count] != 0) {
			[specs addObject:[PSSpecifier groupSpecifierWithName:LS(@"Layout")]];
			[specs addObjectsFromArray:layoutLinks];
		}
		
		[layoutLinks removeAllObjects];
		[fman changeCurrentDirectoryPath:IKX_LIB_PATH@"/InputManagers"];
		prepareLinks(self, @".ime", layoutLinks, fman);
		if ([layoutLinks count] != 0) {
			[specs addObject:[PSSpecifier groupSpecifierWithName:LS(@"Input manager")]];
			[specs addObjectsFromArray:layoutLinks];
		}
		
		if ([specs count] == 0)
			[specs addObject:[PSSpecifier groupSpecifierWithName:LS(@"Nothing to customize.")]];
		
		_specifiers = specs;
	}
	return _specifiers;
}
@end



#pragma mark -

@interface iKeyExKeyboardsPane : PSEditingPane<UITableViewDataSource, UITableViewDelegate> {
	NSMutableArray* allModes;
	NSUInteger separator;
}
@end
@implementation iKeyExKeyboardsPane
-(BOOL)drawLabel { return NO; }
-(id)preferenceValue { return [allModes subarrayWithRange:NSMakeRange(0, separator)]; }
-(void)dealloc {
	[allModes release];
	[super dealloc];
}
-(id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		NSArray* activeModes = UIKeyboardGetActiveInputModes();
		allModes = [activeModes mutableCopy];
		separator = [activeModes count];
		for (NSString* mode in allSupportedModesSorted) {
			if (![activeModes containsObject:mode] && !IKXIsInternalMode(mode))
				[allModes addObject:mode];
		}
		
		UITableView* table = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
		table.editing = YES;
		table.dataSource = self;
		table.delegate = self;
		[self addSubview:table];
		[table release];
	}
	return self;
}
-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"."];
	if (cell == nil)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"."] autorelease];
	BOOL isActive = indexPath.section == 0;
	cell.textLabel.text = IKXNameOfMode([allModes objectAtIndex:indexPath.row + (isActive ? 0 : separator)]);
	cell.showsReorderControl = isActive;
	return cell;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return 2;
}
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return separator;
	else
		return [allModes count]-separator;
}
-(UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	return indexPath.section ? UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
}
-(BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
	return indexPath.section == 0;
}
-(void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	[tableView beginUpdates];

	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSUInteger rowToDelete = indexPath.row;
		NSString* modeToDelete = [allModes objectAtIndex:rowToDelete];
		[allModes insertObject:modeToDelete atIndex:separator];
		[allModes removeObjectAtIndex:rowToDelete];
		-- separator;
		
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
		[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
	} else {
		NSUInteger rowToDelete = indexPath.row + separator;
		NSString* modeToInsert = [allModes objectAtIndex:rowToDelete];
		[allModes insertObject:modeToInsert atIndex:0];
		[allModes removeObjectAtIndex:rowToDelete+1];
		++ separator;
		
		[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
	}
	
	[tableView endUpdates];
}


-(void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath {
	NSUInteger rowToDelete = fromIndexPath.row;
	NSUInteger rowToInsert = toIndexPath.row + (toIndexPath.section ? (separator-1) : 0);
	if (rowToDelete == rowToInsert)
		return;
	
	NSString* modeToDelete = [[allModes objectAtIndex:rowToDelete] retain];
	[allModes removeObjectAtIndex:rowToDelete];
	[allModes insertObject:modeToDelete atIndex:rowToInsert];
	[modeToDelete release];
	if (toIndexPath.section == 1) {
		-- separator;
		[tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
	}
}
@end

#pragma mark -

@interface ClearCachePane : PSEditingPane<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
	NSMutableArray* displayNames[5];
	CFMutableDictionaryRef fileSizes[5];	// display name -> total "4 KiB blocks" of the group of files.
	NSMutableDictionary* filenames[5];	// display name --> all related filenames.
	NSFileManager* fman;
	NSMutableArray* selectedIndexPaths;
	UITableView* table;
}
@end
@implementation ClearCachePane
-(BOOL)drawLabel { return NO; }
-(void)dealloc {
	for (unsigned i = 0; i < sizeof(displayNames)/sizeof(NSMutableArray*); ++ i) {
		[displayNames[i] release];
		[filenames[i] release];
		CFRelease(fileSizes[i]);
	}
	[fman release];
	[selectedIndexPaths release];
	[super dealloc];
}
-(void)setPreferenceSpecifier:(id)newSpec {
	[super setPreferenceSpecifier:newSpec];
	
	fman = [[NSFileManager defaultManager] retain];
	
	for (unsigned i = 0; i < sizeof(displayNames)/sizeof(NSMutableArray*); ++ i) {
		filenames[i] = [NSMutableDictionary new];
		displayNames[i] = [NSMutableArray new];
		fileSizes[i] = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
	}
	
	NSBundle* selfBundle = [self->_delegate bundle];
	NSLocale* curLocale = [NSLocale currentLocale];
	
	[fman changeCurrentDirectoryPath:IKX_SCRAP_PATH];
	for (NSString* fn in [fman contentsOfDirectoryAtPath:@"." error:NULL]) {
		if ([fn hasPrefix:@"iKeyEx::cache::"]) {
			NSString* substring = [fn substringFromIndex:strlen("iKeyEx::cache::")];
			unsigned index = 4;
			NSString* displayName;
			
			if ([substring hasPrefix:@"ime::"]) {
				index = 1;
				displayName = [[substring substringFromIndex:strlen("ime::")] stringByDeletingPathExtension];
			} else if ([substring hasPrefix:@"layout::"]) {
				index = 0;
				displayName = [substring substringFromIndex:strlen("layout::")];
				if ([displayName hasPrefix:@"iKeyEx:"])
					displayName = [displayName substringFromIndex:strlen("iKeyEx:")];				
				
				NSUInteger lastDash = [displayName rangeOfString:@"-" options:NSBackwardsSearch].location;
				if (lastDash != NSNotFound) {
					NSUInteger lastSecondDash = [displayName rangeOfString:@"-" options:NSBackwardsSearch range:NSMakeRange(0, lastDash-1)].location;
					if (lastSecondDash != NSNotFound)
						lastDash = lastSecondDash;
					displayName = [displayName substringToIndex:lastDash];
				}
			} else if ([substring hasPrefix:@"phrase::"]) {
				if ([substring hasSuffix:@".pat"])
					index = 2;
				else if ([substring hasSuffix:@".hash"])
					index = 3;
				displayName = [substring substringFromIndex:strlen("phrase::")];
				NSUInteger fourthColon = [displayName rangeOfString:@"::"].location;
				NSString* language = [displayName substringToIndex:fourthColon];
				NSUInteger lastDot = [displayName rangeOfString:@"." options:NSBackwardsSearch
														  range:NSMakeRange(fourthColon+2, [displayName length]-fourthColon-2)].location;
				if (lastDot != NSNotFound) {
					NSUInteger lastSecondDot = [displayName rangeOfString:@"." options:NSBackwardsSearch
																	range:NSMakeRange(fourthColon+2, lastDot-fourthColon-2)].location;
					if (lastSecondDot != NSNotFound)
						lastDot = lastSecondDot;
					displayName = [displayName substringWithRange:NSMakeRange(fourthColon+2, lastDot-fourthColon-2)];
				} else
					displayName = [displayName substringFromIndex:fourthColon+2];
				
				if ([@"__Internal" isEqualToString:displayName])
					displayName = LS(@"Built-in");
				
				if ([@"zh-Hant" isEqualToString:language])
					language = LS(@"Traditional Chinese");
				else if ([@"zh-Hans" isEqualToString:language])
					language = LS(@"Simplified Chinese");
				else
					language = [curLocale displayNameForKey:NSLocaleIdentifier value:language];
				
				displayName = [displayName stringByAppendingFormat:@" (%@)", language];
				
			} else {
				index = 4;
				displayName = substring;
			}
			
			NSMutableArray* arr = [filenames[index] objectForKey:displayName];
			if (arr == nil) {
				arr = [NSMutableArray array];
				[filenames[index] setObject:arr forKey:displayName];
				[displayNames[index] addObject:displayName];
			}
			intptr_t size = (intptr_t)CFDictionaryGetValue(fileSizes[index], displayName);
			unsigned long long actual_filesize = [[fman attributesOfItemAtPath:fn error:NULL] fileSize];
			size += (actual_filesize + 4095) / 4096;
			CFDictionarySetValue(fileSizes[index], displayName, (const void*)size);
			
			[arr addObject:fn];
		}
	}
	
	table = [[UITableView alloc] initWithFrame:self.frame style:UITableViewStyleGrouped];
	table.editing = YES;
	table.allowsSelectionDuringEditing = YES;
	table.dataSource = self;
	table.delegate = self;
	[self addSubview:table];
	[table release];
	
}
-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSUInteger sect = indexPath.section;
	
	if (sect == 0) {
		NSBundle* selfBundle = [self->_delegate bundle];
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"del"];
		if (cell == nil)
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"del"] autorelease];
		NSUInteger selCount = [[tableView indexPathsForSelectedRows] count];
		UILabel* textLabel = cell.textLabel;
		textLabel.text = [NSString stringWithFormat:LS(selCount == 1 ? @"Delete %u cache entry" : @"Delete %u cache entries"), selCount];
		textLabel.textAlignment = UITextAlignmentCenter;
		return cell;
	} else {
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"."];
		if (cell == nil)
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"."] autorelease];
		
		NSString* dispName = [displayNames[sect-1] objectAtIndex:indexPath.row];
		cell.textLabel.text = dispName;
		intptr_t fsize = (intptr_t)CFDictionaryGetValue(fileSizes[sect-1], dispName);
		NSString* size;
		if (fsize < 1024/4)
			size = [NSString stringWithFormat:@"%d KiB", fsize*4];
		else if (fsize < 1048576/4) {
			int mib = (fsize*5)/128;
			size = [NSString stringWithFormat:@"%d.%d MiB", mib/10, mib%10];
		} else {
			int gib = (fsize*5)/131072;
			size = [NSString stringWithFormat:@"%d.%d GiB", gib/10, gib%10];
		}
		
		UILabel* dtl = cell.detailTextLabel;
		dtl.text = size;
		dtl.adjustsFontSizeToFitWidth = YES;
//		dtl.minimumFontSize = [UIFont smallSystemFontSize];
		dtl.lineBreakMode = UILineBreakModeClip;
		return cell;
	}
}
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return sizeof(displayNames)/sizeof(NSMutableArray*) + 1;
}
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return 1;
	else
		return [displayNames[section-1] count];
}
-(UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	return indexPath.section ? 3 : UITableViewCellEditingStyleNone;
}
-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	static NSString* const headers[] = {@"Layout", @"Input manager", @"Phrase table", @"Characters table", @"Others"};
	if (section > 0 && [displayNames[section-1] count] > 0) {
		NSBundle* selfBundle = [self->_delegate bundle];
		return LS(headers[section-1]);
	} else
		return nil;
}
-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if (indexPath.section > 0) {
		[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	} else {
		NSArray* tempSelectedIndexPaths = [tableView indexPathsForSelectedRows];
		NSUInteger cacheCount = [tempSelectedIndexPaths count]-1;
		if (cacheCount > 0) {
			[selectedIndexPaths release];
			selectedIndexPaths = [tempSelectedIndexPaths mutableCopy];
			NSBundle* selfBundle = [self->_delegate bundle];
			NSString* selfTitle = [NSString stringWithFormat:LS(cacheCount == 1 ? @"Delete %u cache entry" : @"Delete %u cache entries"), cacheCount];
			UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:LS(@"Cancel") destructiveButtonTitle:selfTitle otherButtonTitles:nil];
			[sheet showInView:self];
			[sheet release];
		}
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}
-(void)tableView:(UITableView*)tableView didDeselectRowAtIndexPath:(NSIndexPath*)indexPath {
	if (indexPath.section > 0) {
		[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	}
}
-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == actionSheet.destructiveButtonIndex) {
		NSUInteger topIndex = NSNotFound;
		NSUInteger i = 0;
		NSUInteger fnCount = sizeof(displayNames)/sizeof(NSMutableArray*);
		NSMutableIndexSet* indicesToRemove[fnCount];
		for (unsigned i = 0; i < fnCount; ++ i)
			indicesToRemove[i] = [NSMutableIndexSet indexSet];
			
		[fman changeCurrentDirectoryPath:IKX_SCRAP_PATH];
		for (NSIndexPath* idx in selectedIndexPaths) {
			NSUInteger sect = idx.section;
			if (sect > 0) {
				NSError* err = nil;
				NSUInteger row = idx.row;
				for (NSString* fn in [filenames[sect-1] objectForKey:[displayNames[sect-1] objectAtIndex:row]])
					if (![fman removeItemAtPath:fn error:&err])
						NSLog(@"iKeyEx Prefs: Warning: Cannot remove '%@' for reason '%@'.", fn, [err localizedDescription]);
				[indicesToRemove[sect-1] addIndex:row];
			} else
				topIndex = i;
			++ i;
		}
		for (unsigned i = 0; i < fnCount; ++ i) {
			NSArray* objs = [displayNames[i] objectsAtIndexes:indicesToRemove[i]];
			[filenames[i] removeObjectsForKeys:objs];
			[displayNames[i] removeObjectsAtIndexes:indicesToRemove[i]];
		}
		[selectedIndexPaths removeObjectAtIndex:topIndex];
		for (NSIndexPath* idx in selectedIndexPaths)
			[table deselectRowAtIndexPath:idx animated:NO];
		[table deleteRowsAtIndexPaths:selectedIndexPaths withRowAnimation:UITableViewRowAnimationLeft];
		[table reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
					 withRowAnimation:UITableViewRowAnimationNone];
		[selectedIndexPaths release];
		selectedIndexPaths = nil;
	}
}
@end




@interface CharAndPhraseTablesController : PSListController
@end
@implementation CharAndPhraseTablesController
-(NSArray*)specifiers {
	if (_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Characters and phrase tables" target:self] retain];
	}
	return _specifiers;
}

-(NSArray*)list:(PSSpecifier*)spec internalName:(NSString*)internalName {
	if (spec == nil)
		return nil;
	
	NSFileManager* fman = [NSFileManager defaultManager];
	NSString* path = [IKX_LIB_PATH@"/Phrase" stringByAppendingPathComponent:[spec propertyForKey:@"lang"]];
	NSArray* fns = [[fman contentsOfDirectoryAtPath:path error:NULL] pathsMatchingExtensions:[NSArray arrayWithObject:[spec propertyForKey:@"type"]]];
	NSMutableArray* res = [NSMutableArray arrayWithObject:internalName];
	for (NSString* fn in fns) {
		NSString* f = [fn stringByDeletingPathExtension];
		if (![f isEqualToString:@"__Internal"])
			[res addObject:f];
	}
	return res;
}
-(NSArray*)listValues:(PSSpecifier*)spec { return [self list:spec internalName:@"__Internal"]; }
-(NSArray*)listTitles:(PSSpecifier*)spec {
	NSBundle* selfBundle = [self bundle];
	return [self list:spec internalName:LS(@"Built-in")];
}
-(NSString*)get:(PSSpecifier*)spec {
	NSDictionary* phrase = IKXConfigCopy(@"phrase");
	NSString* retval = [[phrase objectForKey:[spec propertyForKey:@"lang"]] objectAtIndex:([@"chrs" isEqualToString:[spec propertyForKey:@"type"]] ? 1 : 0)] ?: @"__Internal";
	[phrase release];
	return retval;
}
-(void)set:(NSString*)val :(PSSpecifier*)spec {
	NSDictionary* phrase = IKXConfigCopy(@"phrase");
	NSMutableDictionary* phm = [phrase mutableCopy];
	NSString* lang = [spec propertyForKey:@"lang"];
	NSMutableArray* pharr = [[phrase objectForKey:lang] mutableCopy];
	[pharr replaceObjectAtIndex:([@"chrs" isEqualToString:[spec propertyForKey:@"type"]] ? 1 : 0) withObject:val];
	[phm setObject:pharr forKey:lang];
	IKXConfigSet(@"phrase", phm);
	[phrase release];
	[phm release];
	[pharr release];
}
@end



@interface iKeyExPrefListController : PSListController {
	NSUInteger modesCount;
	UIKeyboardImpl* impl;
}
@end
@implementation iKeyExPrefListController
-(id)initForContentSize:(CGSize)size {
	if ((self = [super initForContentSize:size])) {
		// initialize.
		NSDictionary* d = IKXConfigCopy(@"modes");
		if (d == nil)
			IKXConfigSet(@"modes", [NSDictionary dictionary]);
		else
			[d release];
		
		d = IKXConfigCopy(@"phrase");
		if (d == nil)
			IKXConfigSet(@"phrase", [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSArray arrayWithObjects:@"__Internal", @"__Internal", nil], @"zh-Hant",
									 [NSArray arrayWithObjects:@"__Internal", @"__Internal", nil], @"zh-Hans",
									 nil]);
		else
			[d release];
		
		impl = [UIKeyboardImpl sharedInstance];
		recomputeAllModes();
	}
	return self;
}
-(NSArray*)specifiers {
	if (_specifiers == nil) {
		modesCount = [UIKeyboardGetActiveInputModes() count];
		_specifiers = [[self loadSpecifiersFromPlistName:@"iKeyEx" target:self] retain];
	}
	return _specifiers;
}

-(NSString*)keyboardCount { return [NSString stringWithFormat:@"%u", modesCount]; }
-(void)setKeyboards:(NSArray*)keyboards { modesCount = setKeyboards(impl, keyboards); }

/*
-(NSString*)kbChooser {
	unichar c = IKXConfigGetInt(@"kbChooser", 2) + '0';
	return [NSString stringWithCharacters:&c length:1];
}
-(void)setKbChooser:(NSString*)chsr { IKXConfigSetInt(@"kbChooser", [chsr intValue]); }

-(NSNumber*)confirmWithSpace { return (NSNumber*)( IKXConfigGetBool(@"confirmWithSpace", YES) ? kCFBooleanTrue : kCFBooleanFalse ); }
-(void)setConfirmWithSpace:(NSNumber*)val { IKXConfigSetBool(@"confirmWithSpace", [val boolValue]); }

-(NSNumber*)disallowCompletion { return (NSNumber*)( IKXConfigGetBool(@"disallowCompletion", NO) ? kCFBooleanTrue : kCFBooleanFalse ); }
-(void)setDisallowCompletion:(NSNumber*)val { IKXConfigSetBool(@"disallowCompletion", [val boolValue]); }
*/

-(void)suspend {
	saveConfig();
	[super suspend];
}

@end
