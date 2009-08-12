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

static void recomputeAllModes() {
	NSString* curLang = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
	allSupportedModesSorted = [[UIKeyboardGetSupportedInputModes() sortedArrayUsingFunction:(void*)sortByMovingIKXKeyboardsToFront context:curLang] retain];
}



@interface iKeyExEditKeyboardController : PSListController {
	NSArray* layoutRefs;
	NSArray* layoutTitles;
	NSArray* imeRefs;
	NSArray* imeTitles;
	
	NSMutableDictionary* configDict;
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
	if ([[subConfigDict objectForKey:@"name"] length] == 0)
		[[configDict objectForKey:@"modes"] removeObjectForKey:modeName];
	[self.specifier->target performSelector:@selector(reloadSpecifiers)];
	[super suspend];
}
-(void)dealloc {
	[layoutRefs release];
	[layoutTitles release];
	[imeRefs release];
	[imeTitles release];
	[modeName release];
	[configDict release];
	[super dealloc];
}
-(NSString*)ime { return [subConfigDict objectForKey:@"manager"]; }
-(void)setIme:(NSString*)x { [subConfigDict setObject:x forKey:@"manager"]; }
-(NSString*)layout { return [subConfigDict objectForKey:@"layout"]; }
-(void)setLayout:(NSString*)x { [subConfigDict setObject:x forKey:@"layout"]; }
-(NSString*)displayName { return [subConfigDict objectForKey:@"name"]; }
-(void)setDisplayName:(NSString*)x { if ([x length] > 0) [subConfigDict setObject:x forKey:@"name"]; }

-(void)deleteMode {
	// This will indirectly tell -suspend to delete this mode.
	[subConfigDict setObject:@"" forKey:@"name"];
	[self.parentController popController];
}

-(NSArray*)specifiers {
	if (_specifiers == nil) {
		PSSpecifier* selfSpec = self.specifier;
		configDict = [[selfSpec->target performSelector:@selector(configDict)] retain];
		modeName = [[selfSpec propertyForKey:@"modeName"] retain];
		BOOL modeNameWasNil = modeName == nil;
		if (modeNameWasNil) {
			CFUUIDRef uuid = CFUUIDCreate(NULL);
			CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
			modeName = [[@"iKeyEx:" stringByAppendingString:(NSString*)uuidString] retain];
			subConfigDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"=en_US", @"layout", @"=en_US", @"manager", @"", @"name", nil];
			[[configDict objectForKey:@"modes"] setObject:subConfigDict forKey:modeName];
			CFRelease(uuidString);
			CFRelease(uuid);
		} else {
			subConfigDict = [[configDict objectForKey:@"modes"] objectForKey:modeName];
		}
		
		NSMutableArray* specs = [NSMutableArray arrayWithObject:[PSSpecifier emptyGroupSpecifier]];
		
		PSSpecifier* layoutSpec = [PSSpecifier preferenceSpecifierNamed:@"Layout" target:self set:@selector(setLayout:) get:@selector(layout) detail:[PSListItemsController class] cell:PSLinkListCell edit:Nil];
		layoutSpec.titleDictionary = [NSDictionary dictionaryWithObjects:layoutTitles forKeys:layoutRefs];
		layoutSpec.values = layoutRefs;
		[specs addObject:layoutSpec];
		
		PSSpecifier* imeSpec = [PSSpecifier preferenceSpecifierNamed:@"Input manager" target:self set:@selector(setIme:) get:@selector(ime) detail:[PSListItemsController class] cell:PSLinkListCell edit:Nil];
		imeSpec.titleDictionary = [NSDictionary dictionaryWithObjects:imeTitles forKeys:imeRefs];
		imeSpec.values = imeRefs;
		[specs addObject:imeSpec];
		
		PSSpecifier* displayNameSpec = [PSSpecifier preferenceSpecifierNamed:@"Name" target:self set:@selector(setDisplayName:) get:@selector(displayName) detail:[PSDetailController class] cell:PSLinkListCell edit:[PSTextEditingPane class]];
		[specs addObject:displayNameSpec];
		
		if (!modeNameWasNil) {
			[specs addObject:[PSSpecifier emptyGroupSpecifier]];
			
			PSConfirmationSpecifier* deleteSpec = [PSConfirmationSpecifier preferenceSpecifierNamed:@"Delete" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
			deleteSpec->action = @selector(deleteMode);
			[deleteSpec setProperty:(id)kCFBooleanTrue forKey:@"isDestructive"];
			[deleteSpec setupWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"Delete", @"okTitle", @"Cancel", @"cancelTitle", nil]];
			[specs addObject:deleteSpec];
		}
		
		_specifiers = [specs retain];
	}
	return _specifiers;
}
@end



@interface iKeyExMixAndMatchController : PSListController {
	NSMutableDictionary* configDict;
}
@end
@implementation iKeyExMixAndMatchController
-(id)initForContentSize:(CGSize)size {
	if ((self = [super initForContentSize:size]))
		configDict = [[NSMutableDictionary alloc] initWithContentsOfFile:IKX_LIB_PATH@"/Config.plist"];
	return self;
}
-(NSMutableDictionary*)configDict { return configDict; }
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
		
		NSArray* topSpecs = [NSArray arrayWithObjects:
							 [PSSpecifier emptyGroupSpecifier],
							 [PSSpecifier preferenceSpecifierNamed:@"Create" target:self set:NULL get:NULL detail:[iKeyExEditKeyboardController class] cell:PSLinkCell edit:Nil],
							 [PSSpecifier emptyGroupSpecifier],
							 nil];
		[specs insertObjects:topSpecs atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
		
		_specifiers = [specs retain];
	}
	return _specifiers;
}
-(void)suspend {
	[configDict writeToFile:IKX_LIB_PATH@"/Config.plist" atomically:NO];
	IKXFlushConfigDictionary();
	recomputeAllModes();
	[super suspend];
}
-(void)dealloc {
	[configDict release];
	[super dealloc];
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

@interface iKeyExPrefListController : PSListController {
	NSUInteger modesCount;
	UIKeyboardImpl* impl;
}
@end
@implementation iKeyExPrefListController
-(id)initForContentSize:(CGSize)size {
	if ((self = [super initForContentSize:size])) {
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

-(NSString*)keyboardCount {
	return [NSString stringWithFormat:@"%u", modesCount];
}
-(void)setKeyboards:(NSArray*)keyboards {
	if ([keyboards count] == 0)
		keyboards = [NSArray arrayWithObject:@"en_US"];
	modesCount = [keyboards count];
	UIKeyboardSetActiveInputModes(keyboards);
	[impl setInputModePreference];
	[impl setInputMode:[keyboards lastObject]];
}

@end
