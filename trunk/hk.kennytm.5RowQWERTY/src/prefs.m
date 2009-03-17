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
#import <UIKit2/UIAlert.h>
#import <UIKit3/UIUtilities.h>
#import <UIKit3/UIActionSheetPro.h>
#import <UIKit4/UIBigCharacterHUD.h>
#import <UIKit4/UIEasyPickerView.h>
#import <iKeyEx/common.h>
#include <icu/unicode/uchar.h>

#define LAYOUT_PATH iKeyEx_KeyboardsPath@"/5RowQWERTY.keyboard/layout.plist"
#define INFO_PATH iKeyEx_KeyboardsPath@"/5RowQWERTY.keyboard/Info.plist"
#define CURBUNDLE_PATH iKeyEx_KeyboardsPath@"/5RowQWERTY.keyboard/Preferences.bundle"

static const wchar_t symbols[] = L"!@#$%^&*()`~-=[]\\;',./«»_+{}|:\"<>?¿¡•€£¥₩¢°±µ½§␀";
static BOOL cacheDirty = YES;

static NSString* const IMEs[] = {
	@"en_US", @"en_GB",
	@"cs_CZ", @"da_DK", @"de_DE", @"es_ES", @"et_EE", @"fi_FI",
	@"fr_FR", @"fr_CA",
	@"hr_HR", @"hu_HU", @"is_IS", @"it_IT", @"ko_KO", @"lt_LT", @"lv_LV", @"nb_NO", @"nl_NL", @"pl_PL",
	@"pt_PT", @"pt_BR",
	@"ro_RO", @"ru_RU", @"sk_SK", @"sv_SE", @"tr_TR", @"uk_UK",
	@"ja_JP-Romaji",
	@"zh_Hant-Pinyin",
	@"zh_Hans-Pinyin",
	@""
};

static NSString* const defaultSymbols[] = {
	@"!" , @"@" , @"#" , @"$" , @"%" , @"^" , @"&" , @"*" , @"(" , @")" ,

	@"`" , @"", @"-" , @"=" , @"",
	@"\t", @"", @"[" , @"]" , @"\\",
	@"", @"?" , @";" , @"\"", @"",
		  @"," , @"." , @"/" , @"",

	@"~" , @"", @"_" , @"+" , @"",
	@"\t", @"", @"{" , @"}" , @"|" ,
	@"", @"•" , @":" , @"\"" , @"",
		  @"<" , @">" , @"?" , @""
};

static NSString* const numPadTexts[][3] = {
{@"7", @"8", @"9"},
{@"4", @"5", @"6"},
{@"1", @"2", @"3"},
{@"0", @"" , @"."},
};
static NSString* const controlKeysTexts[][3] = {
{@"\x1B",    @"\x1B[1~", @"\x1B[5~"},
{@"\x1B[3~", @"\x1B[4~", @"\x1B[6~"},
{@"",         @"\x1B[A", @""},
{@"\x1B[D", @"\x1B[B", @"\x1B[C"},
};



static NSString* const AllowedArrangements[] = {
	@"QWERTY",
	@"QWERTZ",
	@"QZERTY",
	@"AZERTY",
	@"Russian",
	@"Ukrainian",
	@"Korean",
	@"JapaneseQWERTY",
	@"Greek",
	@"Colemak",
	@"ABCDEF",
};

static NSString* const Arrangements[][6] = {
{@"q|w|e|r|t|y|u|i|o|p", @"a|s|d|f|g|h|j|k|l", @"z|x|c|v|b|n|m", @"Q|W|E|R|T|Y|U|I|O|P", @"A|S|D|F|G|H|J|K|L", @"Z|X|C|V|B|N|M"},
{@"q|w|e|r|t|z|u|i|o|p", @"a|s|d|f|g|h|j|k|l", @"y|x|c|v|b|n|m", @"Q|W|E|R|T|Z|U|I|O|P", @"A|S|D|F|G|H|J|K|L", @"Y|X|C|V|B|N|M"},
{@"q|z|e|r|t|y|u|i|o|p", @"a|s|d|f|g|h|j|k|l|m", @"w|x|c|v|b|n", @"Q|Z|E|R|T|Y|U|I|O|P", @"A|S|D|F|G|H|J|K|L|M", @"W|X|C|V|B|N"},
{@"a|z|e|r|t|y|u|i|o|p", @"q|s|d|f|g|h|j|k|l|m", @"w|x|c|v|b|n", @"A|Z|E|R|T|Y|U|I|O|P", @"Q|S|D|F|G|H|J|K|L|M", @"W|X|C|V|B|N"},
{@"й|ц|у|к|е|н|г|ш|щ|з|х", @"ф|ы|в|а|п|р|о|л|д|ж|э", @"я|ч|с|м|и|т|ь|б|ю", @"Й|Ц|У|К|Е|Н|Г|Ш|Щ|З|Х", @"Ф|Ы|В|А|П|Р|О|Л|Д|Ж|Э", @"Я|Ч|С|М|И|Т|Ь|Б|Ю"},
{@"й|ц|у|к|е|н|г|ш|щ|з|х", @"ф|и|в|а|п|р|о|л|д|ж|є", @"я|ч|с|м|і|т|ь|б|ю", @"Й|Ц|У|К|Е|Н|Г|Ш|Щ|З|Х", @"Ф|И|В|А|П|Р|О|Л|Д|Ж|Є", @"Я|Ч|С|М|І|Т|Ь|Б|Ю"},
{@"ㅂ|ㅈ|ㄷ|ㄱ|ㅅ|ㅛ|ㅕ|ㅑ|ㅐ|ㅔ", @"ㅁ|ㄴ|ㅇ|ㄹ|ㅎ|ㅗ|ㅓ|ㅏ|ㅣ", @"ㅋ|ㅌ|ㅊ|ㅍ|ㅠ|ㅜ|ㅡ", @"ㅃ|ㅉ|ㄸ|ㄲ|ㅆ|ㅛ|ㅕ|ㅑ|ㅒ|ㅖ", @"ㅁ|ㄴ|ㅇ|ㄹ|ㅎ|ㅗ|ㅓ|ㅏ|ㅣ", @"ㅋ|ㅌ|ㅊ|ㅍ|ㅠ|ㅜ|ㅡ"},
{@"q|w|e|r|t|y|u|i|o|p", @"a|s|d|f|g|h|j|k|l|ー", @"z|x|c|v|b|n|m", @"Q|W|E|R|T|Y|U|I|O|P", @"A|S|D|F|G|H|J|K|L|—", @"Z|X|C|V|B|N|M"},
{@";|ς|ε|ρ|τ|υ|θ|ι|ο|π", @"α|σ|δ|φ|γ|η|ξ|κ|λ", @"ζ|χ|ψ|ω|β|ν|μ", @":|^|Ε|Ρ|Τ|Υ|Θ|Ι|Ο|Π", @"Α|Σ|Δ|Φ|Γ|Η|Ξ|Κ|Λ", @"Ζ|Χ|Ψ|Ω|Β|Ν|Μ"},
{@"q|w|f|p|g|j|l|u|y|,", @"a|r|s|t|d|h|n|e|i|o", @"z|x|c|v|b|k|m", @"Q|W|F|P|G|J|L|U|Y|,", @"A|R|S|T|D|H|N|E|I|O", @"Z|X|C|V|B|K|M"},
{@"a|b|c|d|e|f|g|h|i|j", @"k|l|m|n|o|p|q|r|s", @"t|u|v|w|x|y|z", @"A|B|C|D|E|F|G|H|I|J", @"K|L|M|N|O|P|Q|R|S", @"T|U|V|W|X|Y|Z"}
};

__attribute__((pure))
NSString* unicodeDescription(unichar c) {
	UErrorCode err = U_ZERO_ERROR;
	int32_t charlen = u_charName(c, U_UNICODE_CHAR_NAME, NULL, 0, &err);
	err = U_ZERO_ERROR;
	char* buffer = malloc(charlen+1);
	u_charName(c, U_UNICODE_CHAR_NAME, buffer, charlen+1, &err);
	
	NSString* resstr = [[[NSString stringWithUTF8String:buffer] capitalizedString] stringByAppendingFormat:@" (U+%04X)", c];
	free(buffer);
	
	return resstr;
}

static NSString* const CombiningCharacters[] = {
@"`", @"´", @"ˆ", @"˜", @"¯", @"‾", @"˘", @"˙",
@"¨", @"ˀ", @"˚", @"˝", @"ˇ", @"ˈ", nil, @"˵",
nil, nil, nil, nil, nil, nil, @"ˎ", @"ˏ",
nil, nil, nil, @"’", @"˓", @"˔", @"˕", @"˖",
@"˗", nil, nil, @".", nil, @"˳", @",", @"¸",
@"˛", @"ˌ", nil, nil, nil, nil, nil, nil,
@"˷", @"ˍ", @"_", @"‗", @"~", @"-", @"–", @"⁄",
@"/", @"˒", @"˽", nil, nil, @"ˣ", nil, @"˭",
@"`", @"´", @"῀", @"᾽", @"΅", @"ͺ", nil, @"₌"};

__attribute__((pure))
NSString* actualDisplayStringForString(NSString* t) {
	if ([t length] == 1) {
		unichar c = [t characterAtIndex:0];
		switch (c) {
			case '\t':
				return @"⇥";
			case ' ':
				return @"␣";
			case '\n':
				return @"↵";
			case L'\u0300' ... L'\u0348':
				return CombiningCharacters[c-0x0300] ?: t;
		}
	}
	return t;
}

__attribute__((pure))
NSObject* actualDisplayObjectForString(NSString* t, BOOL isPopup) {
	if ([t length] == 0) return t;
	NSArray* gray = [NSArray arrayWithObject:[NSNumber numberWithFloat:0.5f]];
	NSNumber* point2 = [NSNumber numberWithFloat:0.2f];
	if ([@"\t" isEqualToString:t]) {
		if (isPopup)
			return @"Tab";
		else
			return [NSDictionary dictionaryWithObjectsAndKeys:
					gray, @"color",
					@"⇥", @"text",
					nil];
	} else if ([@"\n" isEqualToString:t]) {
		if (isPopup)
			return [NSDictionary dictionaryWithObjectsAndKeys:
					point2, @"size",
					@"Return", @"text",
					nil];
		else
			return [NSDictionary dictionaryWithObjectsAndKeys:
					gray, @"color",
					@"↵", @"text",
					nil];
	} else if ([@" " isEqualToString:t]) {
		if (isPopup)
			return [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:0.25f], @"size",
					@"Space", @"text",
					nil];
		else
			return [NSDictionary dictionaryWithObjectsAndKeys:
					gray, @"color",
					@"␣", @"text",
					nil];
	} else if ([@"\x1b" isEqualToString:t]) {
		if (isPopup)
			return @"Esc";
		else
			return [NSDictionary dictionaryWithObject:@"/Library/iKeyEx/Keyboards/5RowQWERTY.keyboard/esc.png" forKey:@"image"];
	} else if ([t length] > 1) {
		if ([t characterAtIndex:0] == '\x1b' && [t length] >= 3) {
			switch ([t characterAtIndex:2]) {
				case 'A': return @"↑";
				case 'B': return @"↓";
				case 'C': return @"→";
				case 'D': return @"←";
				case '1':
					if (isPopup)
						return [NSDictionary dictionaryWithObjectsAndKeys:
								point2, @"size",
								@"Home", @"text",
								nil];
					else
						return [NSDictionary dictionaryWithObjectsAndKeys:
								gray, @"color",
								@"↖", @"text",
								nil];
				case '3':
					if (isPopup)
						return @"Del.";
					else
						return [NSDictionary dictionaryWithObjectsAndKeys:
								gray, @"color",
								@"⌦", @"text",
								nil];
				case '4':
					if (isPopup)
						return @"End";
					else
						return [NSDictionary dictionaryWithObjectsAndKeys:
								gray, @"color",
								@"↘", @"text",
								nil];
				case '5':
					if (isPopup)
						return [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithFloat:0.3f], @"size",
								@"Page Up", @"text",
								nil];
					else
						return [NSDictionary dictionaryWithObjectsAndKeys:
								gray, @"color",
								@"⇞", @"text",
								nil];
				case '6':
					if (isPopup)
						return [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithFloat:0.3f], @"size",
								@"Page Down", @"text",
								nil];
					else
						return [NSDictionary dictionaryWithObjectsAndKeys:
								gray, @"color",
								@"⇟", @"text",
								nil];
				default:
					return t;
			}
		}
		return t;
	} else {
		unichar c = [t characterAtIndex:0];
		if (L'\u0300' <= c && c <= L'\u0348') {
			NSNumber* zero = [NSNumber numberWithFloat:0];
			return [NSDictionary dictionaryWithObjectsAndKeys:
					(CombiningCharacters[c-0x300] ?: t), @"text",
					[NSArray arrayWithObjects:[NSNumber numberWithFloat:1], zero, zero, nil], @"color",
					nil];
		} else
			return t;
	}
}


__attribute__((pure))
int colorTypeForString(NSString* t) {
	if ([t length] == 1) {
		int8_t ct = u_charType([t characterAtIndex:0]);
		
		if (ct == U_NON_SPACING_MARK || ct == U_ENCLOSING_MARK || ct == U_COMBINING_SPACING_MARK)
			return 2;
		else if (ct == U_SPACE_SEPARATOR || ct == U_LINE_SEPARATOR || ct == U_PARAGRAPH_SEPARATOR || ct == U_CONTROL_CHAR)
			return 1;
	}
	return 0;
}

__attribute__((pure))
UIColor* colorForString(NSString* t) {
	switch (colorTypeForString(t)) {
		case 0: return [UIColor darkTextColor];
		case 1: return [UIColor grayColor];
		case 2: return [UIColor redColor];
	}
}

typedef union UTF16Character {
	struct {
		unsigned int n0:4;
		unsigned int n1:4;
		unsigned int n2:4;
		unsigned int n3:4;
	} nibbles;
	unichar c;
} UTF16Character;


#include <errno.h>
void clearCache () {
	// purge only once.
	if (cacheDirty) {
		iKeyEx_KBMan("purge", "5RowQWERTY");
		cacheDirty = NO;
	}
}



@interface SpecialCharactersPane : PSEditingPane<UIActionSheetDelegate> {
	UIActionSheet* resetSheet;
	UIActionSheet* sheet;
	UIActionSheet* unicodeSheet;
	UIEasyPickerView* unicodePicker;
	NSMutableArray* preferenceValue;
	UIView* symbolsContainer;
	UIBigCharacterHUD* hud;
	UIView* dimView;
	NSBundle* myBundle;
}
-(id)initWithFrame:(CGRect)frm;
-(void)showReset;
-(void)showCharacterSelector:(UIButton*)btn;
@property(retain) NSObject* preferenceValue;
-(void)updateButtons;
@end
@implementation SpecialCharactersPane
@synthesize preferenceValue;
-(void)updateButtons {
	NSUInteger i = 0;
	for (UIButton* b in symbolsContainer.subviews) {
		NSString* displayTitle = [preferenceValue objectAtIndex:i];
		[b setTitleColor:colorForString(displayTitle) forState:UIControlStateNormal];
		[b setTitle:actualDisplayStringForString(displayTitle) forState:UIControlStateNormal];
		++i;
	}
}
-(void)setPreferenceValue:(NSObject*)pref {
	if (pref != preferenceValue && [pref isKindOfClass:[NSArray class]]) {
		[preferenceValue release];
		preferenceValue = [pref mutableCopy];
		[self updateButtons];
	}
}

-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		myBundle = [[NSBundle bundleWithPath:CURBUNDLE_PATH] retain];
		
		// reset button.
		NSString* resetString = [myBundle localizedStringForKey:@"Reset" value:nil table:@"5RowQWERTY"];
		UIButton* presetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[presetButton setTitle:resetString forState:UIControlStateNormal];
		presetButton.frame = CGRectMake(5, 5, 320-2*5, 48);
		[presetButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
		presetButton.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
		[presetButton addTarget:self action:@selector(showReset) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:presetButton];
		
		// reset sheet.
		resetSheet = [[UIActionSheet alloc] initWithTitle:nil
												 delegate:self
										cancelButtonTitle:UILocalizedString("Cancel")
								   destructiveButtonTitle:resetString
										otherButtonTitles:nil];
		
		// List of symbols.
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
			btn.tag = i;
			[btn addTarget:self action:@selector(showCharacterSelector:) forControlEvents:UIControlEventTouchUpInside];
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
			btn.tag = i;
			[btn addTarget:self action:@selector(showCharacterSelector:) forControlEvents:UIControlEventTouchUpInside];
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
			btn.tag = i;
			[btn addTarget:self action:@selector(showCharacterSelector:) forControlEvents:UIControlEventTouchUpInside];
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
		
		// character selection sheet
		sheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n\n"
											delegate:self
								   cancelButtonTitle:UILocalizedString("OK")
							  destructiveButtonTitle:nil
								   otherButtonTitles:@"Unicode", nil];
		sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
		sheet.numberOfRows = 1;
		hud = [[UIBigCharacterHUD alloc] initWithFrame:CGRectMake(8, 28, 164, 100)];

#define ROWS 4
#define COLUMNS 12
#define width 320/COLUMNS
#define height 27
		NSUInteger left0 = (320 - width*COLUMNS)/2;
		NSUInteger left = left0;
		NSUInteger top = 0;
		UIView* glassButtonsContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 5, width*COLUMNS, height*ROWS)];
		for (const wchar_t* c = symbols; *c != '\0'; ++ c) {
			UIButton* btn = [[UIButton alloc] initWithFrame:CGRectMake(left, top, width, height)];
			[btn setTitle:[NSString stringWithCharacters:(unichar*)c length:1] forState:UIControlStateNormal];
			btn.showsTouchWhenHighlighted = YES;
			[btn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
			[btn addTarget:self action:@selector(setHUDCharacterWithButton:) forControlEvents:UIControlEventTouchUpInside];
			[glassButtonsContainer addSubview:btn];
			[btn release];
			left += width;
			if (left >= width*12) {
				left = left0;
				top += height;
			}
		}
		[sheet addSubview:glassButtonsContainer];
#undef ROWS
#undef COLUMNS
#undef width
#undef height
		
		// unicode selection sheet.
		unicodeSheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n\n\n\n\n\n\n\n\n"
												   delegate:self
										  cancelButtonTitle:UILocalizedString("OK")
									 destructiveButtonTitle:nil
										  otherButtonTitles:[myBundle localizedStringForKey:@"Palette" value:nil table:@"5RowQWERTY"], nil];
		unicodeSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
		unicodeSheet.numberOfRows = 1;
		NSArray* ZeroF = [NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"A", @"B", @"C", @"D", @"E", @"F", nil];
		unicodePicker = [[UIEasyPickerView alloc] initWithComponents:ZeroF, ZeroF, ZeroF, ZeroF, nil];
		unicodePicker.showsSelectionIndicator = YES;
		[unicodePicker registerSelectionMonitor:self action:@selector(updateHUDUnicode)];
		[unicodeSheet addSubview:unicodePicker];
		[unicodePicker release];
		
	}
	return self;
}
-(void)dealloc {
	[myBundle release];
	[hud release];
	[resetSheet release];
	[sheet release];
	[super dealloc];
}
-(void)showReset { [resetSheet showInView:self.window]; }

-(void)setHUDCharacter:(NSString*)c {
	hud.title = c;
	switch ([c length]) {
		case 0:
			hud.message = [myBundle localizedStringForKey:@"Empty slot" value:nil table:@"5RowQWERTY"];
			break;
		case 1:
			hud.message = unicodeDescription([c characterAtIndex:0]);
			break;
		default:
			hud.message = nil;
			break;
	}
}
-(void)setHUDCharacterWithButton:(UIButton*)btn {
	NSString* title = [btn currentTitle];
	if ([@"␀" isEqualToString:title])
		[self setHUDCharacter:@""];
	else
		[self setHUDCharacter:title];
}

-(void)showCharacterSelector:(UIButton*)sender {
	NSUInteger i = sender.tag;
	[self setHUDCharacter:[preferenceValue objectAtIndex:i]];
	CGRect senderFrame = [sender convertRect:sender.bounds toView:nil];
	CGRect hudFrame = hud.frame;
	if (senderFrame.origin.x >= 160)
		hudFrame.origin.x = 8;
	else
		hudFrame.origin.x = 148;
	hud.frame = hudFrame;
	hud.tag = i;
	dimView = [UIDimViewWithHole(senderFrame) retain];
	[dimView addSubview:hud];
	
	[sheet setDimView:dimView];
	[unicodeSheet setDimView:dimView];
	[sheet showInView:self.window];
}

-(void)updateHUDUnicode {
	UTF16Character hudChar;
	hudChar.nibbles.n0 = [unicodePicker selectedRowInComponent:3];
	hudChar.nibbles.n1 = [unicodePicker selectedRowInComponent:2];
	hudChar.nibbles.n2 = [unicodePicker selectedRowInComponent:1];
	hudChar.nibbles.n3 = [unicodePicker selectedRowInComponent:0];
	if (hudChar.c == '\0')
		[self setHUDCharacter:@""];
	else
		[self setHUDCharacter:[NSString stringWithCharacters:&hudChar.c length:1]];
}

-(void)actionSheet:(UIActionSheet*)sht clickedButtonAtIndex:(NSInteger)idx {
	if (idx == 0) {
		if (sht == sheet) {
			NSString* hudTitle = hud.title;
			if ([hudTitle length] == 0) {
				[unicodePicker selectRow:0 inComponent:3 animated:NO];
				[unicodePicker selectRow:0 inComponent:2 animated:NO];
				[unicodePicker selectRow:0 inComponent:1 animated:NO];
				[unicodePicker selectRow:0 inComponent:0 animated:NO];
			} else {
				UTF16Character hudChar;
				hudChar.c = [hudTitle characterAtIndex:0];
				[unicodePicker selectRow:hudChar.nibbles.n0 inComponent:3 animated:NO];
				[unicodePicker selectRow:hudChar.nibbles.n1 inComponent:2 animated:NO];
				[unicodePicker selectRow:hudChar.nibbles.n2 inComponent:1 animated:NO];
				[unicodePicker selectRow:hudChar.nibbles.n3 inComponent:0 animated:NO];
			}
			[unicodeSheet performSelector:@selector(showInView:) withObject:self.window afterDelay:0.25];
		} else if (sht == unicodeSheet) {
			[sheet performSelector:@selector(showInView:) withObject:self.window afterDelay:0.25];
		} else if (sht == resetSheet) {
			[preferenceValue release];
			preferenceValue = [[NSMutableArray alloc] initWithObjects:defaultSymbols count:10+2*(5*4-1)];
			[self updateButtons];
		}
	} else {
		if (sht != resetSheet) {
			[dimView release];
			[preferenceValue replaceObjectAtIndex:hud.tag withObject:hud.title];
			[self updateButtons];
		}
	}
}
@end



@interface FiveRowQWERTYListController : PSListController {
	NSMutableDictionary* layoutPlist, *infoPlist;
	
	NSArray* shiftTopRows;
	NSArray* altSymbols[4];
	NSArray* shiftAltSymbols[4];
	NSString* layout;
	NSString* topRow;
	NSString* altPlane;
}
-(NSArray*)specifiers;
-(id)initForContentSize:(CGSize)size;
-(void)dealloc;

-(NSArray*)getIMEs;
-(NSArray*)getIMETitles;

-(NSString*)valueForSpecifier:(PSSpecifier*)spec;
-(void)setValue:(NSString*)value forSpecifier:(PSSpecifier*)spec;

@property(nonatomic,retain) NSString* layout;
@property(nonatomic,retain) NSString* topRow;
@property(nonatomic,retain) NSString* altPlane;

@property(nonatomic,retain) NSArray* specialCharacters;
@property(nonatomic,retain) NSString* inputManager;

-(void)readLayout;
-(void)saveLayout;

@end

@implementation FiveRowQWERTYListController
@synthesize layout, topRow, altPlane;
@dynamic specialCharacters, inputManager;

-(NSString*)valueForSpecifier:(PSSpecifier*)spec { return [self valueForKey:spec.identifier]; }
-(void)setValue:(NSString*)value forSpecifier:(PSSpecifier*)spec {
	[self setValue:value forKey:spec.identifier];
	[self saveLayout];
}


-(void)readLayout {
	[layout release];
	layout = [[layoutPlist objectForKey:@"layout"] retain];
	
	[topRow release];
	topRow = [[layoutPlist objectForKey:@"topRow"] retain];
	
	[altPlane release];
	altPlane = [[layoutPlist objectForKey:@"altPlane"] retain];
	
	[shiftTopRows release];
	if ([topRow isEqualToString:@"Symbols"]) {
		shiftTopRows = [[[layoutPlist objectForKey:@"Alphabet"] objectForKey:@"texts"] objectAtIndex:0];
	} else if ([topRow isEqualToString:@"Disabled"]) {
		shiftTopRows = [[[layoutPlist objectForKey:@"Alphabet"] objectForKey:@"shiftedTexts"] lastObject];
	} else {
		shiftTopRows = [[[layoutPlist objectForKey:@"Alphabet"] objectForKey:@"shiftedTexts"] objectAtIndex:0];
	}
	if ([shiftTopRows isKindOfClass:[NSString class]]) {
		shiftTopRows = [[(NSString*)shiftTopRows substringFromIndex:1] componentsSeparatedByString:[(NSString*)shiftTopRows substringToIndex:1]];
	}
	[shiftTopRows retain];
	
	NSUInteger i = 0;
	NSDictionary* numbersSublayout = [layoutPlist objectForKey:@"Numbers"];
	for (NSArray* sym in [numbersSublayout objectForKey:@"texts"]) {
		[altSymbols[i] release];
		altSymbols[i] = [[sym subarrayWithRange:NSMakeRange(0, i==3 ? 4 : 5)] retain];
		++ i;
		if (i == 4)
			break;
	}
	i = 0;
	for (NSArray* sym in [numbersSublayout objectForKey:@"shiftedTexts"]) {
		[shiftAltSymbols[i] release];
		shiftAltSymbols[i] = [[sym subarrayWithRange:NSMakeRange(0, i==3 ? 4 : 5)] retain];
		++ i;
		if (i == 4)
			break;
	}
}

-(void)saveLayout {	
	[layoutPlist setObject:layout forKey:@"layout"];
	[layoutPlist setObject:topRow forKey:@"topRow"];
	[layoutPlist setObject:altPlane forKey:@"altPlane"];
	
	int i;
	// Set Alphabets
	
	NSArray* numRow = [NSArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", nil];
	NSMutableArray* texts = [NSMutableArray arrayWithObject:numRow];
	NSMutableArray* shiftedTexts = [NSMutableArray arrayWithObject:shiftTopRows];
	BOOL textsSet = NO;
	for (i = 0; i < sizeof(AllowedArrangements)/sizeof(NSString*); ++ i) {
		if ([AllowedArrangements[i] isEqualToString:layout]) {
			[texts addObject:[Arrangements[i][0] componentsSeparatedByString:@"|"]];
			[texts addObject:[Arrangements[i][1] componentsSeparatedByString:@"|"]];
			[texts addObject:[Arrangements[i][2] componentsSeparatedByString:@"|"]];
			[texts addObject:[NSArray array]];
			
			[shiftedTexts addObject:[Arrangements[i][3] componentsSeparatedByString:@"|"]];
			[shiftedTexts addObject:[Arrangements[i][4] componentsSeparatedByString:@"|"]];
			[shiftedTexts addObject:[Arrangements[i][5] componentsSeparatedByString:@"|"]];
			[shiftedTexts addObject:@"="];
			
			textsSet = YES;
			break;
		}
	}
	if (!textsSet) {
		[texts addObject:[Arrangements[0][0] componentsSeparatedByString:@"|"]];
		[texts addObject:[Arrangements[0][1] componentsSeparatedByString:@"|"]];
		[texts addObject:[Arrangements[0][2] componentsSeparatedByString:@"|"]];
		[texts addObject:[NSArray array]];
		
		[shiftedTexts addObject:[Arrangements[0][3] componentsSeparatedByString:@"|"]];
		[shiftedTexts addObject:[Arrangements[0][4] componentsSeparatedByString:@"|"]];
		[shiftedTexts addObject:[Arrangements[0][5] componentsSeparatedByString:@"|"]];
		[shiftedTexts addObject:@"="];
	}
	
	NSArray* urls = [NSArray arrayWithObjects:@".", @"/", @".com", nil];
	NSArray* emails = [NSArray arrayWithObjects:@" ", @".", @"@", nil];
	BOOL isTopRowDisabled = [topRow isEqualToString:@"Disabled"];
	if (isTopRowDisabled) {
		NSMutableArray* temp = [texts objectAtIndex:0];
		[texts removeObjectAtIndex:0];
		[texts addObject:temp];
		temp = [shiftedTexts objectAtIndex:0];
		[shiftedTexts removeObjectAtIndex:0];
		[shiftedTexts addObject:temp];
		
		temp = [[layoutPlist objectForKey:@"URL"] objectForKey:@"texts"];
		[temp replaceObjectAtIndex:3 withObject:urls];
		[temp replaceObjectAtIndex:4 withObject:@"=Alphabet"];
		
		temp = [[layoutPlist objectForKey:@"EmailAddress"] objectForKey:@"texts"];
		[temp replaceObjectAtIndex:3 withObject:emails];
		[temp replaceObjectAtIndex:4 withObject:@"=Alphabet"];
	} else {
		if ([topRow isEqualToString:@"Symbols"]) {
			[texts replaceObjectAtIndex:0 withObject:shiftTopRows];
			[shiftedTexts replaceObjectAtIndex:0 withObject:numRow];
		}
		
		NSMutableArray* temp = [[layoutPlist objectForKey:@"URL"] objectForKey:@"texts"];
		[temp replaceObjectAtIndex:3 withObject:@"=Alphabet"];
		[temp replaceObjectAtIndex:4 withObject:urls];
		
		temp = [[layoutPlist objectForKey:@"URLAlt"] objectForKey:@"texts"];
		[temp replaceObjectAtIndex:3 withObject:@"=Numbers"];
		[temp replaceObjectAtIndex:4 withObject:urls];
		
		temp = [[layoutPlist objectForKey:@"EmailAddress"] objectForKey:@"texts"];
		[temp replaceObjectAtIndex:3 withObject:@"=Alphabet"];
		[temp replaceObjectAtIndex:4 withObject:emails];
		
		temp = [[layoutPlist objectForKey:@"EmailAddressAlt"] objectForKey:@"texts"];
		[temp replaceObjectAtIndex:3 withObject:@"=Numbers"];
		[temp replaceObjectAtIndex:4 withObject:emails];
	}
	NSMutableDictionary* alphabetSublayout = [layoutPlist objectForKey:@"Alphabet"];
	NSMutableArray* counts = [NSMutableArray arrayWithCapacity:5], *rowIndentation = [NSMutableArray arrayWithCapacity:5];
	NSUInteger maxCount = 0;
	int rowCount = (isTopRowDisabled?4:5);
	i = 0;
	for (NSArray* a in texts) {
		NSUInteger count = (i == rowCount-1) ? 3 : [a count];
		[counts addObject:[NSNumber numberWithInteger:count]];
		if (count > maxCount)
			maxCount = count;
		++i;
	}
	CGFloat keyHalfWidth = 160.f / maxCount;
	i = 0;
	for (NSNumber* n in counts) {
		[rowIndentation addObject:[NSNumber numberWithFloat:((i == rowCount-1) ? 80 : 160-[n integerValue]*keyHalfWidth)]];
		++i;
	}
	CGFloat shiftKeyWidth = [[rowIndentation objectAtIndex:rowCount-2] floatValue];
	if (shiftKeyWidth > 42)
		shiftKeyWidth = 42;
	
	[alphabetSublayout setObject:[NSNumber numberWithInteger:rowCount] forKey:@"rows"];
	[alphabetSublayout setObject:counts forKey:@"arrangement"];
	[alphabetSublayout setObject:rowIndentation forKey:@"rowIndentation"];
	[alphabetSublayout setObject:texts forKey:@"texts"];
	[alphabetSublayout setObject:shiftedTexts forKey:@"shiftedTexts"];
	[alphabetSublayout setObject:[NSNumber numberWithFloat:shiftKeyWidth] forKey:@"shiftKeyWidth"];
	[alphabetSublayout setObject:[NSNumber numberWithFloat:shiftKeyWidth] forKey:@"deleteKeyWidth"];
	[alphabetSublayout setObject:[NSNumber numberWithBool:isTopRowDisabled] forKey:@"usesKeyCharges"];
	[alphabetSublayout setObject:[NSNumber numberWithBool:YES] forKey:@"registersKeyCentroids"];
	[layoutPlist setObject:alphabetSublayout forKey:@"Alphabet"];
	
	// Set Numbers
	BOOL isNumPad = [@"NumPad" isEqualToString:altPlane];
	texts = [NSMutableArray arrayWithCapacity:5];
	shiftedTexts = [NSMutableArray arrayWithCapacity:5];
	for (i = 0; i < 4; ++ i) {
		[texts addObject:[altSymbols[i] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:(isNumPad?numPadTexts:controlKeysTexts)[i] count:3]]];
		[shiftedTexts addObject:[shiftAltSymbols[i] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:(isNumPad?controlKeysTexts:numPadTexts)[i] count:3]]];
	}
	[texts addObject:[NSArray array]];
	[shiftedTexts addObject:@"="];
	
	NSMutableArray* labels = [NSMutableArray arrayWithCapacity:5];
	NSMutableArray* popups = [NSMutableArray arrayWithCapacity:5];
	i = 0;
	for (NSArray* row in texts) {
		NSMutableArray* curLabel = [NSMutableArray arrayWithCapacity:8];
		NSMutableArray* curPopup = [NSMutableArray arrayWithCapacity:8];
		for (NSString* col in row) {
			[curLabel addObject:actualDisplayObjectForString(col, NO)];
			[curPopup addObject:actualDisplayObjectForString(col, YES)];
		}
		[labels addObject:curLabel];
		[popups addObject:curPopup];
		++ i;
		if (i == 4)
			break;
	}
	[labels addObject:@"="];
	[popups addObject:@"="];
	
	NSMutableArray* shiftedLabels = [NSMutableArray arrayWithCapacity:5];
	NSMutableArray* shiftedPopups = [NSMutableArray arrayWithCapacity:5];
	i = 0;
	for (NSArray* row in shiftedTexts) {
		NSMutableArray* curLabel = [NSMutableArray arrayWithCapacity:8];
		NSMutableArray* curPopup = [NSMutableArray arrayWithCapacity:8];
		for (NSString* col in row) {
			[curLabel addObject:actualDisplayObjectForString(col, NO)];
			[curPopup addObject:actualDisplayObjectForString(col, YES)];
		}
		[shiftedLabels addObject:curLabel];
		[shiftedPopups addObject:curPopup];
		++ i;
		if (i == 4)
			break;
	}
	[shiftedLabels addObject:@"="];
	[shiftedPopups addObject:@"="];
	
	NSMutableDictionary* numbersSublayout = [layoutPlist objectForKey:@"Numbers"];
	[numbersSublayout setObject:texts forKey:@"texts"];
	[numbersSublayout setObject:shiftedTexts forKey:@"shiftedTexts"];
	[numbersSublayout setObject:labels forKey:@"labels"];
	[numbersSublayout setObject:shiftedLabels forKey:@"shiftedLabels"];
	[numbersSublayout setObject:popups forKey:@"popups"];
	[numbersSublayout setObject:shiftedPopups forKey:@"shiftedPopups"];
	[layoutPlist setObject:numbersSublayout forKey:@"Numbers"];
	
	// Done :)
	
	[layoutPlist writeToFile:LAYOUT_PATH atomically:NO];
	clearCache();
}

-(id)initForContentSize:(CGSize)size {
	if ((self = [super initForContentSize:size])) {
		layoutPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:LAYOUT_PATH];
		infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:INFO_PATH];
		
		[self readLayout];
		
		cacheDirty = YES;
	}
	return self;
}
-(void)dealloc {
	[layoutPlist release];
	[infoPlist release];
	[shiftTopRows release];
	for (int i = 0; i < 4; ++ i) {
		[altSymbols[i] release];
		[shiftAltSymbols[i] release];
	}
	[layout release];
	[topRow release];
	[altPlane release];
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

-(void)clearCache { clearCache(); }

-(NSArray*)specialCharacters {
	NSMutableArray* retval = [[shiftTopRows mutableCopy] autorelease];
	
	[retval addObjectsFromArray:altSymbols[0]];
	[retval addObjectsFromArray:altSymbols[1]];
	[retval addObjectsFromArray:altSymbols[2]];
	[retval addObjectsFromArray:altSymbols[3]];
	
	[retval addObjectsFromArray:shiftAltSymbols[0]];
	[retval addObjectsFromArray:shiftAltSymbols[1]];
	[retval addObjectsFromArray:shiftAltSymbols[2]];
	[retval addObjectsFromArray:shiftAltSymbols[3]];
	
	return retval;
}
-(void)setSpecialCharacters:(NSArray*)characterArray {
	[shiftTopRows release];
	shiftTopRows = [[characterArray subarrayWithRange:NSMakeRange(0,10)] retain];
	
	[altSymbols[0] release];
	altSymbols[0] = [[characterArray subarrayWithRange:NSMakeRange(10,5)] retain];
	[altSymbols[1] release];
	altSymbols[1] = [[characterArray subarrayWithRange:NSMakeRange(15,5)] retain];
	[altSymbols[2] release];
	altSymbols[2] = [[characterArray subarrayWithRange:NSMakeRange(20,5)] retain];
	[altSymbols[3] release];
	altSymbols[3] = [[characterArray subarrayWithRange:NSMakeRange(25,4)] retain];
	
	[shiftAltSymbols[0] release];
	shiftAltSymbols[0] = [[characterArray subarrayWithRange:NSMakeRange(29,5)] retain];
	[shiftAltSymbols[1] release];
	shiftAltSymbols[1] = [[characterArray subarrayWithRange:NSMakeRange(34,5)] retain];
	[shiftAltSymbols[2] release];
	shiftAltSymbols[2] = [[characterArray subarrayWithRange:NSMakeRange(39,5)] retain];
	[shiftAltSymbols[3] release];
	shiftAltSymbols[3] = [[characterArray subarrayWithRange:NSMakeRange(44,4)] retain];
	
	[self saveLayout];	
}

-(NSString*)inputManager { return [[infoPlist objectForKey:@"UIKeyboardInputManagerClass"] substringFromIndex:1] ?: @""; }
-(void)setInputManager:(NSString*)man {
	if ([man length] == 0)
		[infoPlist removeObjectForKey:@"UIKeyboardInputManagerClass"];
	else
		[infoPlist setObject:[@"=" stringByAppendingString:man] forKey:@"UIKeyboardInputManagerClass"];
	[infoPlist writeToFile:INFO_PATH atomically:NO];
}

@end

