/*
 
 prefs.m ... Preference Pane for 5-Row QWERTY.
 
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
#import <UIKit2/Functions.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSEditingPane.h>
#import <UIKit/UIKit.h>
#import <UIKit3/UIUtilities.h>
#import <iKeyEx/common.h>

#define LAYOUT_PATH iKeyEx_KeyboardsPath@"/5RowQWERTY.keyboard/layout.plist"
#define CURBUNDLE_PATH iKeyEx_KeyboardsPath@"/5RowQWERTY.keyboard/Preferences.bundle"

static NSString* const IMEs[] = {
	@"en_US", @"en_GB",
	@"cs_CZ", @"da_DK", @"de_DE", @"es_ES", @"et_EE", @"fi_FI",
	@"fr_FR", @"fr_CA",
	@"hr_HR", @"hu_HU", @"is_IS", @"it_IT", @"lt_LT", @"lv_LV", @"nb_NO", @"nl_NL", @"pl_PL",
	@"pt_PT", @"pt_BR",
	@"ro_RO", @"sk_SK", @"sv_SE", @"tr_TR",
	@"ja_JP-Romaji",
	@"zh_Hant-Pinyin",
	@"zh_Hans-Pinyin",
	@""
};

static NSString* const SCPresetLanguages[] = {
	@"en_US",
	@"en_GB",
};

#define $$G '\u0300'	// `
#define $$A '\u0301'	// ´
#define $$C '\u0302'	// ˆ
#define $$T '\u0303'	// ˜
#define $$U '\u0308'	// ¨
static NSString* const characters[][10+(5*4-1)*2] = {
// en_US
{
	@"!" , @"@" , @"#" , @"$" , @"%" , @"^" , @"&" , @"*" , @"(" , @")" ,

	@"`" , @"", @"-" , @"=" , @"",
	@"\t", @"", @"[" , @"]" , @"\\",
	@"", @"?" , @";" , @"\"", @"",
		  @"," , @"." , @"/" , @"",

	@"~" , @"", @"_" , @"+" , @"",
	@"\t", @"", @"{" , @"}" , @"|" ,
	@"", @"•" , @":" , @"\"" , @"",
		  @"<" , @">" , @"?" , @""
},
// en_GB
{
	@"!" , @"\"" , @"£", @"$" , @"%" , @"^" , @"&" , @"*" , @"(" , @")" ,

	@"`" , @"", @"-" , @"=" , @"",
	@"\t", @"", @"[" , @"]" , @"#",
	@"", @"?" , @";" , @"\"", @"",
		  @"," , @"." , @"/" , @"",

	@"¬", @"", @"_" , @"+" , @"",
	@"\t", @"", @"{" , @"}" , @"~" ,
	@"", @"•" , @":", @"@" , @"",
		  @"<" , @">" , @"?" , @""
},
};
#undef $$G
#undef $$A
#undef $$C
#undef $$T
#undef $$U

NSString* actualDisplayStringForString(NSString* t) {
	if ([t length] > 0) {
		unichar c = [t characterAtIndex:0];
		switch (c) {
			case '\t':
				return @"⇥";
			case ' ':
				return @"␣";
			case '\n':
				return @"↵";
			case L'\u0300':
				return @"`";
			case L'\u0301':
				return @"´";
			case L'\u0302':
				return @"ˆ";
			case L'\u0303':
				return @"˜";
			case L'\u0308':
				return @"¨";
		}
	}
	return t;
}

UIColor* colorForString(NSString* t) {
	if ([t length] > 0) {
		unichar c = [t characterAtIndex:0];
		switch (c) {
			case '\t':
			case ' ':
			case '\n':
				return [UIColor grayColor];
			case L'\u0300':
			case L'\u0301':
			case L'\u0302':
			case L'\u0303':
			case L'\u0308':
				return [UIColor redColor];
		}
	}
	return [UIColor darkTextColor];
}

@interface SCPresetController : NSObject<UIPickerViewDataSource,UIPickerViewDelegate> {}
-(NSUInteger)numberOfComponentsInPickerView:(UIPickerView*)view;
-(NSUInteger)pickerView:(UIPickerView*)view numberOfRowsInComponent:(NSUInteger)comp;
-(NSString*)pickerView:(UIPickerView*)view titleForRow:(NSUInteger)row forComponent:(NSUInteger)comp;
@end
@implementation SCPresetController
-(NSUInteger)numberOfComponentsInPickerView:(UIPickerView*)view { return 1; }
-(NSUInteger)pickerView:(UIPickerView*)view numberOfRowsInComponent:(NSUInteger)comp { return sizeof(SCPresetLanguages)/sizeof(NSString*); }
-(NSString*)pickerView:(UIPickerView*)view titleForRow:(NSUInteger)row forComponent:(NSUInteger)comp {
	return [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:SCPresetLanguages[row]];
}
@end



@interface SpecialCharactersPane : PSEditingPane<UIActionSheetDelegate> {
	UIActionSheet* sheet;
	UIActionSheet* presetSheet;
	UIPickerView* presetPicker;
	SCPresetController* presetPickerController;
	NSMutableArray* preferenceValue;
	UIView* symbolsContainer;
}
-(id)initWithFrame:(CGRect)frm;
-(BOOL)handlesDoneButton;
-(void)showPreset;
@property(retain) NSObject* preferenceValue;
@end
@implementation SpecialCharactersPane
@synthesize preferenceValue;
-(void)setPreferenceValue:(NSObject*)pref {
	if (pref != preferenceValue && [pref isKindOfClass:[NSArray class]]) {
		[preferenceValue release];
		preferenceValue = [pref retain];
		NSUInteger i = 0;
		for (UIButton* b in symbolsContainer.subviews) {
			NSString* displayTitle = [preferenceValue objectAtIndex:i];
			[b setTitleColor:colorForString(displayTitle) forState:UIControlStateNormal];
			[b setTitle:actualDisplayStringForString(displayTitle) forState:UIControlStateNormal];
			++i;
		}
	}
}

-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		
		UIButton* presetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[presetButton setTitle:[[NSBundle bundleWithPath:CURBUNDLE_PATH] localizedStringForKey:@"Preset" value:nil table:@"5RowQWERTY"] forState:UIControlStateNormal];
		presetButton.frame = CGRectMake(5, 5, 320-2*5, 48);
		[presetButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
		presetButton.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
		[presetButton addTarget:self action:@selector(showPreset) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:presetButton];
		
		presetSheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n\n\n\n\n\n\n\n\n"
												  delegate:self
										 cancelButtonTitle:UILocalizedString("OK")
									destructiveButtonTitle:nil
										 otherButtonTitles:nil];
		presetSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
		presetPicker = [[UIPickerView alloc] init];
		presetPicker.showsSelectionIndicator = YES;
		presetPickerController = [[SCPresetController alloc] init];
		presetPicker.delegate = presetPickerController;
		presetPicker.dataSource = presetPickerController;
		[presetSheet addSubview:presetPicker];
		
		symbolsContainer = [[UIView alloc] initWithFrame:CGRectMake(5, 5+48+10, 320-2*5, 32*5)];
		NSUInteger i = 0;
#define BUTTON_WIDTH 30
#define BUTTON_HEIGHT 30
		UIImage* btnBackground = _UIImageWithName(@"kb-std-accented-key.png");
		UIImage* btnActiveBackground = _UIImageWithName(@"kb-std-accented-key-selected.png");
		
		UIGraphicsEndImageContext();
		
		CGRect btnFrame = CGRectMake(5+i, 0, BUTTON_WIDTH, BUTTON_HEIGHT);
		UIButton* btn;
		for (; i < 10; ++ i) {
			btn = [[UIButton alloc] initWithFrame:btnFrame];
			[btn setBackgroundImage:btnBackground forState:UIControlStateNormal];
			[btn setBackgroundImage:btnActiveBackground forState:UIControlStateHighlighted];
			[btn setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
			[btn setTitleColor:[UIColor lightTextColor] forState:UIControlStateHighlighted];
			[symbolsContainer addSubview:btn];
			btnFrame.origin.x += BUTTON_WIDTH;
		}
		btnFrame = CGRectMake(0, 32*5-4*BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT); 
		for (; i < 10+(5*4-1); ++i) {
			btn = [[UIButton alloc] initWithFrame:btnFrame];
			[btn setBackgroundImage:btnBackground forState:UIControlStateNormal];
			[btn setBackgroundImage:btnActiveBackground forState:UIControlStateHighlighted];
			[btn setTitleColor:[UIColor lightTextColor] forState:UIControlStateHighlighted];
			[symbolsContainer addSubview:btn];
			btnFrame.origin.x += BUTTON_WIDTH;
			if (i % 5 == 4) {
				btnFrame.origin.x = 0;
				btnFrame.origin.y += BUTTON_HEIGHT;
				if (i == 24)
					btnFrame.origin.x += BUTTON_WIDTH;
			}
		}
		
		btnFrame = CGRectMake(320-2*5-5*BUTTON_WIDTH, 32*5-4*BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT);
		for (; i < 10+2*(5*4-1); ++i) {
			btn = [[UIButton alloc] initWithFrame:btnFrame];
			[btn setBackgroundImage:btnBackground forState:UIControlStateNormal];
			[btn setBackgroundImage:btnActiveBackground forState:UIControlStateHighlighted];
			[btn setTitleColor:[UIColor lightTextColor] forState:UIControlStateHighlighted];
			[symbolsContainer addSubview:btn];
			btnFrame.origin.x += BUTTON_WIDTH;
			if (i % 5 == 3) {
				btnFrame.origin.x = 320-2*5-5*BUTTON_WIDTH;
				btnFrame.origin.y += BUTTON_HEIGHT;
				if (i == 43)
					btnFrame.origin.x += BUTTON_WIDTH;
			}
		}
		
		[self addSubview:symbolsContainer];
		[symbolsContainer release];
	}
	return self;
}
-(void)dealloc {
	[presetPickerController release];
	[presetSheet release];
	[super dealloc];
}
-(void)showPreset {
	[presetSheet showInView:self];
}
-(void)actionSheet:(UIActionSheet*)sht clickedButtonAtIndex:(NSInteger)idx {
	if (sht == presetSheet) {
		self.preferenceValue = [NSArray arrayWithObjects:characters[[presetPicker selectedRowInComponent:0]] count:10+(5*4-1)*2];
	}
}
-(BOOL)handlesDoneButton {
	NSLog(@"Done editing!");
	return YES;
}
@end



@interface FiveRowQWERTYListController : PSListController {
	NSMutableDictionary* layoutPlist;
}
-(NSArray*)specifiers;
-(id)initForContentSize:(CGSize)size;
-(void)dealloc;

-(NSArray*)getIMEs;
-(NSArray*)getIMETitles;
@end

@implementation FiveRowQWERTYListController
-(id)initForContentSize:(CGSize)size {
	if ((self = [super initForContentSize:size]))
		layoutPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:LAYOUT_PATH];
	return self;
}
-(void)dealloc {
	[layoutPlist release];
	[super dealloc];
}

-(NSArray*)specifiers {
	if (_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"5RowQWERTY" target:self] retain];
		[self specifierForID:@"IME"].name = [[NSBundle mainBundle] localizedStringForKey:@"Auto-Correction" value:nil table:@"Keyboard"];
		[self specifierForID:@"clearCache"].name = [[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/iKeyEx.bundle/"] localizedStringForKey:@"Clear layout cache" value:nil table:@"ClearCache"];
	}
	return _specifiers;
}


-(NSArray*)getIMEs { return [NSArray arrayWithObjects:IMEs count:(sizeof(IMEs)/sizeof(NSString*))]; }
-(NSArray*)getIMETitles {
	NSMutableArray* finalArray = [NSMutableArray arrayWithCapacity:sizeof(IMEs)/sizeof(NSString*)];
	NSLocale* curLocale = [NSLocale currentLocale];
	NSString* curLocaleID = [curLocale localeIdentifier];
	for (NSUInteger i = 0; i < sizeof(IMEs)/sizeof(NSString*); ++ i) {
		NSRange locRange = [IMEs[i] rangeOfString:@"-"];
		if (locRange.location == NSNotFound) {
			if ([@"" isEqualToString:IMEs[i]])
				[finalArray addObject:UILocalizedString("Disable")];
			else
				[finalArray addObject:[curLocale displayNameForKey:NSLocaleIdentifier value:IMEs[i]]];
		} else {
			NSString* localeStr = [curLocale displayNameForKey:NSLocaleIdentifier value:[IMEs[i] substringToIndex:locRange.location]];
			NSString* type = [@"UI" stringByAppendingString:[IMEs[i] substringFromIndex:locRange.location]];
			[finalArray addObject:[NSString stringWithFormat:@"%@ (%@)", localeStr, UIKeyboardLocalizedString(type, curLocaleID, nil)]];
		}
	}
	return finalArray;
}

@end

