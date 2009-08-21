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
static NSMutableDictionary* configDict = nil;
static BOOL configMutated = NO;

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

static void recomputeAllModes() {
	NSString* curLang = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
	allSupportedModesSorted = [[UIKeyboardGetSupportedInputModes() sortedArrayUsingFunction:(void*)sortByMovingIKXKeyboardsToFront context:curLang] retain];
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
	if (configMutated) {
		NSString* configPath = IKX_LIB_PATH@"/Config.plist";
		if ([configDict writeToFile:configPath atomically:YES]) {
			configMutated = NO;
			chmod([configPath UTF8String], 0666);
			notify_post("hk.kennytm.iKeyEx3.FlushConfigDictionary");
		} else
			NSLog(@"iKeyEx: Warning: Failed to save '%@'. All configs will be lost.", configPath);
	}
}
static NSMutableDictionary* mutableConfigDict() {
	configMutated = YES;
	return configDict;
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
	if ([[subConfigDict objectForKey:@"name"] length] == 0) {
		[[mutableConfigDict() objectForKey:@"modes"] removeObjectForKey:modeName];
		NSArray* activeModes = UIKeyboardGetActiveInputModes();
		NSUInteger curModeLoc = [activeModes indexOfObject:modeName];
		if (curModeLoc != NSNotFound) {
			NSMutableArray* newActiveModes = [activeModes mutableCopy];
			[newActiveModes removeObjectAtIndex:curModeLoc];
			setKeyboards([UIKeyboardImpl sharedInstance], newActiveModes);
			[newActiveModes release];
		}
	}
	[self.specifier->target performSelector:@selector(reloadSpecifiers)];
	[super suspend];
}
-(void)dealloc {
	[layoutRefs release];
	[layoutTitles release];
	[imeRefs release];
	[imeTitles release];
	[modeName release];
	[super dealloc];
}
-(NSString*)ime { return [subConfigDict objectForKey:@"manager"]; }
-(void)setIme:(NSString*)x { configMutated = YES; [subConfigDict setObject:(x?:@"=en_US") forKey:@"manager"]; }
-(NSString*)layout { return [subConfigDict objectForKey:@"layout"]; }
-(void)setLayout:(NSString*)x { configMutated = YES; [subConfigDict setObject:(x?:@"=en_US") forKey:@"layout"]; }
-(NSString*)displayName { return [subConfigDict objectForKey:@"name"]; }
-(void)setDisplayName:(NSString*)x { if ([x length] > 0) { configMutated = YES; [subConfigDict setObject:x forKey:@"name"]; } }

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
		if (modeNameWasNil) {
			CFUUIDRef uuid = CFUUIDCreate(NULL);
			CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
			modeName = [[@"iKeyEx:" stringByAppendingString:(NSString*)uuidString] retain];
			subConfigDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"=en_US", @"layout", @"=en_US", @"manager", @"", @"name", nil];
			[[mutableConfigDict() objectForKey:@"modes"] setObject:subConfigDict forKey:modeName];
			CFRelease(uuidString);
			CFRelease(uuid);
		} else {
			subConfigDict = [[configDict objectForKey:@"modes"] objectForKey:modeName];
		}
		
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
		NSMutableArray* specs = [NSMutableArray array];
		
		NSDictionary* modesDict = [configDict objectForKey:@"modes"];
		for (NSString* modeName in modesDict) {
			if (!IKXIsInternalMode(modeName)) {
				PSSpecifier* linker = [PSSpecifier preferenceSpecifierNamed:[[modesDict objectForKey:modeName] objectForKey:@"name"] target:self set:NULL get:NULL detail:[iKeyExEditKeyboardController class] cell:PSLinkCell edit:Nil];
				[linker setProperty:modeName forKey:@"modeName"];
				[specs addObject:linker];
			}
		}
		
		[specs sortUsingSelector:@selector(titleCompare:)];
		
		NSBundle* selfBundle = [self bundle];
		
		NSArray* topSpecs = [NSArray arrayWithObjects:
							 [PSSpecifier emptyGroupSpecifier],
							 [PSSpecifier preferenceSpecifierNamed:LS(@"Make") target:self set:NULL get:NULL detail:[iKeyExEditKeyboardController class] cell:PSLinkCell edit:Nil],
							 [PSSpecifier emptyGroupSpecifier],
							 nil];
		[specs insertObjects:topSpecs atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
		
		_specifiers = [specs retain];
	}
	return _specifiers;
}
-(void)suspend {
	recomputeAllModes();
	[super suspend];
}
@end



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
	NSMutableArray* filenames[4];
	NSFileManager* fman;
	NSMutableArray* selectedIndexPaths;
	UITableView* table;
}
@end
@implementation ClearCachePane
-(BOOL)drawLabel { return NO; }
-(void)dealloc {
	for (unsigned i = 0; i < sizeof(filenames)/sizeof(NSMutableArray*); ++ i)
		[filenames[i] release];
	[fman release];
	[selectedIndexPaths release];
	[super dealloc];
}
-(id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		fman = [[NSFileManager defaultManager] retain];
		
		for (unsigned i = 0; i < sizeof(filenames)/sizeof(NSMutableArray*); ++ i)
			filenames[i] = [NSMutableArray new];
		
		for (NSString* fn in [fman contentsOfDirectoryAtPath:IKX_SCRAP_PATH error:NULL]) {
			if ([fn hasPrefix:@"iKeyEx::cache::"]) {
				NSString* substring = [fn substringFromIndex:strlen("iKeyEx::cache::")];
				if ([substring hasPrefix:@"ime::"]) {
					if (![substring hasSuffix:@".kns"])
						[filenames[1] addObject:fn];
				} else if ([substring hasPrefix:@"layout::"])
					[filenames[0] addObject:fn];
				else if ([substring hasPrefix:@"phrase::"])
					[filenames[2] addObject:fn];
				else
					[filenames[3] addObject:fn];
			}
		}
		
		table = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
		table.editing = YES;
		table.allowsSelectionDuringEditing = YES;
		table.dataSource = self;
		table.delegate = self;
		[self addSubview:table];
		[table release];
	}
	return self;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSUInteger sect = indexPath.section;
	NSBundle* selfBundle = [self->_delegate bundle];
	
	if (sect == 0) {
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"del"];
		if (cell == nil)
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"del"] autorelease];
		NSUInteger selCount = [[tableView indexPathsForSelectedRows] count];
		UILabel* textLabel = cell.textLabel;
		textLabel.text =  [NSString stringWithFormat:LS(selCount == 1 ? @"Delete %u cache file" : @"Delete %u cache files"), selCount];
		textLabel.textAlignment = UITextAlignmentCenter;
		return cell;
	} else {
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"."];
		if (cell == nil)
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"."] autorelease];
		
		NSString* fn = [filenames[sect-1] objectAtIndex:indexPath.row];
		NSUInteger fnlen = [fn length];
		NSUInteger thirdDoubleColon = [fn rangeOfString:@"::" options:0 range:NSMakeRange(strlen("iKeyEx::cache::"), fnlen-strlen("iKeyEx::cache::"))].location;
		if (thirdDoubleColon == NSNotFound)
			thirdDoubleColon = strlen("iKeyEx::cache::")-2;
		thirdDoubleColon += 2;
		NSUInteger firstDot = [fn rangeOfString:@"." options:0 range:NSMakeRange(thirdDoubleColon, fnlen-thirdDoubleColon)].location;
		if (firstDot == NSNotFound)
			firstDot = fnlen;
		NSString* fnn = [fn substringWithRange:NSMakeRange(thirdDoubleColon, firstDot - thirdDoubleColon)];
		NSUInteger fourthColon = [fnn rangeOfString:@"::"].location;
		NSString* language = nil;
		if (fourthColon != NSNotFound) {
			language = [fnn substringToIndex:fourthColon];
			fnn = [fnn substringFromIndex:fourthColon+2];
		}
		if ([fnn isEqualToString:@"__Internal"])
			fnn = LS(@"Built-in");
		else if ([fnn hasPrefix:@"iKeyEx:"])
			fnn = [fnn substringFromIndex:strlen("iKeyEx:")];
		if (language != nil) {
			if ([language isEqualToString:@"zh-Hant"])
				language = LS(@"Traditional Chinese");
			else if ([language isEqualToString:@"zh-Hans"])
				language = LS(@"Simplified Chinese");
			else
				language = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:language];
			fnn = [NSString stringWithFormat:@"%@ (%@)", fnn, language];
		}
		cell.textLabel.text = fnn;
		return cell;
	}
}
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return sizeof(filenames)/sizeof(NSMutableArray*) + 1;
}
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return 1;
	else
		return [filenames[section-1] count];
}
-(UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	return indexPath.section ? 3 : UITableViewCellEditingStyleNone;
}
-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	static NSString* const headers[] = {@"Layout", @"Input manager", @"Phrase table", @"Others"};
	if (section > 0 && [filenames[section-1] count] > 0) {
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
			NSString* selfTitle = [NSString stringWithFormat:LS(cacheCount == 1 ? @"Delete %u cache file" : @"Delete %u cache files"), cacheCount];
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
		NSUInteger fnCount = sizeof(filenames)/sizeof(NSMutableArray*);
		NSMutableIndexSet* indicesToRemove[fnCount];
		for (unsigned i = 0; i < fnCount; ++ i)
			indicesToRemove[i] = [NSMutableIndexSet indexSet];
			
		for (NSIndexPath* idx in selectedIndexPaths) {
			NSUInteger sect = idx.section;
			if (sect > 0) {
				NSError* err = nil;
				NSUInteger row = idx.row;
				[fman changeCurrentDirectoryPath:IKX_SCRAP_PATH];
				NSString* fn = [filenames[sect-1] objectAtIndex:row];
				if (![fman removeItemAtPath:fn error:&err])
					NSLog(@"iKeyEx Prefs: Warning: Cannot remove '%@' for reason '%@'.", fn, [err localizedDescription]);
				[indicesToRemove[sect-1] addIndex:row];
			} else
				topIndex = i;
			++ i;
		}
		for (unsigned i = 0; i < fnCount; ++ i)
			[filenames[i] removeObjectsAtIndexes:indicesToRemove[i]];
		[selectedIndexPaths removeObjectAtIndex:topIndex];
		[table deleteRowsAtIndexPaths:selectedIndexPaths withRowAnimation:UITableViewRowAnimationLeft];
		
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
	return [[[configDict objectForKey:@"phrase"] objectForKey:[spec propertyForKey:@"lang"]]
			objectAtIndex:([@"chrs" isEqualToString:[spec propertyForKey:@"type"]] ? 1 : 0)] ?: @"__Internal";
}
-(void)set:(NSString*)val :(PSSpecifier*)spec {
	[[[mutableConfigDict() objectForKey:@"phrase"] objectForKey:[spec propertyForKey:@"lang"]]
	 replaceObjectAtIndex:([@"chrs" isEqualToString:[spec propertyForKey:@"type"]] ? 1 : 0) withObject:val];
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
		configDict = [[NSMutableDictionary alloc] initWithContentsOfFile:IKX_LIB_PATH@"/Config.plist"];
		if (configDict == nil) {
			// Generate an initial miminum structure.
			configDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
						  [NSMutableDictionary dictionary], @"modes",
						  [NSMutableDictionary dictionaryWithObjectsAndKeys:
						   [NSArray arrayWithObjects:@"__Internal", @"__Internal"], @"zh-Hant",
						   [NSArray arrayWithObjects:@"__Internal", @"__Internal"], @"zh-Hans",
						  nil], @"phrase",
						  @"1", @"kbChooser",
						  nil];
			configMutated = YES;
			saveConfig();
		}
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

-(NSString*)kbChooser { return [configDict objectForKey:@"kbChooser"] ?: @"2"; }
-(void)setKbChooser:(NSString*)chsr { [mutableConfigDict() setObject:chsr forKey:@"kbChooser"]; }

-(NSNumber*)confirmWithSpace { return [configDict objectForKey:@"confirmWithSpace"] ?: (id)kCFBooleanTrue; }
-(void)setConfirmWithSpace:(NSNumber*)val { [mutableConfigDict() setObject:val forKey:@"confirmWithSpace"]; }

-(void)suspend {
	saveConfig();
	[super suspend];
}

@end
