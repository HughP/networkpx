/*
 *     Generated by class-dump 3.1.2.
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2007 by Steve Nygard.
 */

#import <UIKit2/UIKeyboardLayout.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UITextInputTraits.h>
#import <GraphicsServices/GSEvent.h>

@class UIKeyboardSublayout, UIView, NSString, NSMutableDictionary, NSSet, UIEvent;


typedef enum UIKeyType {
	UIKeyTypeNormal = 1,
	UIKeyTypeDelete = 3,
	UIKeyTypeSpace  = 4,
	UIKeyTypeReturn = 5,
	UIKeyTypeShift  = 6,
	UIKeyTypeInternational = 7
} UIKeyType;

typedef enum UIKeyDefinitionDownActionFlag {
	UIKeyFlagActivateKey           = 1,
	UIKeyFlagSendActionOnTouchDown = 2,
	UIKeyFlagPlaySound             = 4,
	UIKeyFlagShiftKey              = 0x10,
	UIKeyFlagInternationalKey      = 0x20,
	UIKeyFlagDeleteKey             = 0x40,
	UIKeyFlagHasLongPressAction    = 0x80,
	UIKeyFlagRomanAccents          = 0x8000,
	UIKeyFlagURLDomainVariants     = 0x10000,
	UIKeyFlagEmailDomainVariants   = 0x20000,
	UIKeyFlagCurrencyVariants      = 0x40000,	// ?
	UIKeyFlagFunctionKeysUnknown   = 0x80000
} UIKeyDefinitionDownActionFlag;

typedef enum UIKeyDefinitionUpActionFlag {
	UIKeyFlagOutputValue           = 2,		// do not set this field if the value is intended to be invisible, e.g. "shift", "delete", etc.
	UIKeyFlagDeactivateKey         = 8,
	UIKeyFlagAlternateSublayout    = 0x20,
	UIKeyFlagSwitchPlane           = 0x100,
	UIKeyFlagToggleShift           = 0x400,
	UIKeyFlagStopAutoDelete        = 0x800,
	UIKeyFlagChangeInputMode       = 0x1000,	// effective only for the intl key.
	UIKeyFlagConfirmCandidate      = 0x2000,
	UIKeyFlagNextCandidatesList    = 0x4000,
	UIKeyFlagSkipCandidateList     = 0x10000
} UIKeyDefinitionUpActionFlag;

typedef struct UIKeyDefinition {
	CGRect bg_area;				// +0,  the area of the key in the background image.
	CGRect pop_bg_area;			// +16,	the area of the pop up view background in the image map. (The origin may be shifted a bit to the left or right)
	CGRect pop_char_area;		// +32,	the area of the pop up view character in the image map.
	CGRect accent_frame;		// +48,	the frame of the UIAccentedCharactersView.
	CGRect pop_padding;			// +64, the origin of the pop up view, and the padding of the character.
	NSString* value;			// +80, value to send when not shifted.
	NSString* shifted;			// +84, value to send when shifted.
	UIKeyDefinitionDownActionFlag down_flags;	// +88, 
	UIKeyDefinitionUpActionFlag up_flags;		// +92, 
	UIKeyType key_type;			// +96
	NSString* pop_type;			// +100
} UIKeyDefinition;				// sizeof = 104


@interface UIKeyboardLayoutRoman : UIKeyboardLayout {
    NSMutableDictionary *m_keyedSublayouts;
    UIKeyboardSublayout *m_activeSublayout;
    UIKeyboardSublayout *m_deactivatingSublayout;
    NSString* m_activeSublayoutKey;
    int m_activeKeyIndex;
    UIView *m_activeKeyView;
    UIView *m_accentedKeyView;
    int m_returnKeyIndex;
    UIView *m_enabledReturnKeyView;
    UIView *m_disabledReturnKeyView;
    UIView *m_pressedReturnKeyView;
    CGPoint m_dragPoint;
    unsigned int m_currentPathFlags;
    GSPathInfo m_activePathInfo;
    int m_shiftKeyPathIndex;
    int m_swipePathIndex;
    int m_preferredTrackingChangeCount;
    struct USet *m_accentInfo;
    struct USet *m_hasAccents;
    id m_spaceTarget;
    SEL m_spaceAction;
    SEL m_spaceLongAction;
    id m_returnTarget;
    SEL m_returnAction;
    SEL m_returnLongAction;
    id m_deleteTarget;
    SEL m_deleteAction;
    SEL m_deleteLongAction;
    BOOL m_shift;
    BOOL m_built;
    BOOL m_dragged;
    BOOL m_dragChangedKey;
    BOOL m_mouseDownInMoreKey;
    BOOL m_didLongPress;
}

+ (id)inputModesPreferringEuroToDollar;
+ (id)availableTopLevelDomains;
- (id)initWithFrame:(CGRect)rect;
- (void)dealloc;
- (void)showKeyboardType:(int)fp8 withAppearance:(UIKeyboardAppearance)fp12;
- (void)deactivateActiveKeys;
- (void)updateReturnKey;
- (void)updateLocalizedKeys;
- (BOOL)usesAutoShift;
- (BOOL)isShiftKeyBeingHeld;
- (BOOL)isShiftKeyPlaneChooser;
- (void)setShift:(BOOL)isShifted;
- (void)longPressAction;
- (BOOL)canHandleHandEvent:(GSEventRef)fp8;
- (UIKeyType)typeForKey:(UIKeyDefinition*)fp8;
- (UIKeyDefinitionDownActionFlag)downActionFlagsForKey:(UIKeyDefinition*)fp8;
- (UIKeyDefinitionUpActionFlag)upActionFlagsForKey:(UIKeyDefinition*)fp8;
- (CGRect)compositeFGLongPressFrameForKey:(UIKeyDefinition*)fp8 orientation:(int)fp12;
- (Class)sublayoutClassForKeyboardType:(NSString*)fp8;
- (void)setLabel:(NSString*)fp8 forKey:(NSString*)fp12;
- (void)setTarget:(id)fp8 forKey:(NSString*)fp12;
- (void)setAction:(SEL)fp8 forKey:(NSString*)fp12;
- (void)setLongPressAction:(SEL)fp8 forKey:(NSString*)fp12;
- (void)restoreDefaultsForKey:(NSString*)fp8;
- (void)restoreDefaultsForAllKeys;
- (void)nextCandidatesAction;
- (void)confirmAction;
- (void)sendStringAction:(NSString*)fp8 forKey:(UIKeyDefinition*)fp12;
- (void)deleteAction;
- (void)handleHardwareKeyDownFromSimulator:(GSEventRef)fp8;
- (void)addLocalizedCurrencyKeysToSublayout:(UIKeyboardSublayout*)fp8 keyboardType:(id)fp12;
- (void)build;
- (UIKeyboardSublayout*)buildSublayoutForKey:(NSString*)key;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutMain;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutAlternate;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutAlphabet;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutNumbers;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutAlphabetTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutNumbersTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutPhonePad;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutPhonePadAlt;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutPhonePadTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutPhonePadAltTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutNumberPad;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutNumberPadTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutURL;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutURLAlt;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutURLTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutURLAltTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutSMSAddressing;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutSMSAddressingAlt;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutSMSAddressingTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutSMSAddressingAltTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutEmailAddress;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutEmailAddressAlt;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutEmailAddressTransparent;
- (UIKeyboardSublayout*)buildUIKeyboardLayoutEmailAddressAltTransparent;
- (void)addSublayout:(UIKeyboardSublayout*)sublayout forKey:(NSString*)key;
- (NSString*)layoutKeyForKeyboardType:(int)fp8 withAppearance:(UIKeyboardAppearance)fp12;
- (void)showKeyboardTypeForKey:(NSString*)key;
- (UIKeyboardSublayout*)sublayoutForKey:(NSString*)key;
- (NSString*)activeSublayoutKey;
- (UIKeyboardSublayout*)activeSublayout;
- (UIKeyDefinition*)activeKey;
- (id)overlayImageForKey:(UIKeyDefinition*)fp8;
- (BOOL)shouldCacheViewForKey:(UIKeyDefinition*)fp8;
- (void)activateCompositeKey:(UIKeyDefinition*)fp8;
- (void)activateKey:(UIKeyDefinition*)keydef;
- (void)activateKeyWithIndex:(NSUInteger)index;
- (void)activateFirstKeyOfType:(UIKeyType)type;
- (unsigned int)keyHitTest:(CGPoint)fp8;
- (UIKeyDefinition*)keyForPoint:(CGPoint)fp8;
- (void)showPopupVariantsForKey:(UIKeyDefinition*)fp8;
- (void)layoutSubview:(id)fp8 selectedString:(id)fp12;
- (BOOL)isLongPressedKey:(UIKeyDefinition*)fp8;
- (id)inputStringForKey:(UIKeyDefinition*)fp8;
- (id)cacheKeyForKey:(UIKeyDefinition*)fp8;
- (UIKeyDefinition*)inputKeyboardKeyForKey:(UIKeyDefinition*)fp8;
- (id)alternateSublayoutKey:(id)fp8;
- (BOOL)handleHandEvent:(GSEventRef)fp8;
- (void)touchDownWithKey:(UIKeyDefinition*)fp8 atPoint:(struct CGPoint)fp12;
- (int)keyHitTestUniversal:(CGPoint)fp8 touchStage:(int)fp16 atTime:(double)fp20 withPathInfo:(GSPathInfo *)fp28;
- (void)touchDown:(GSEventRef)fp8 withPathInfo:(GSPathInfo*)fp12;
- (void)touchDragged:(GSEventRef)fp8 withPathInfo:(GSPathInfo*)fp12;
- (void)touchUp:(GSEventRef)fp8 withPathInfo:(GSPathInfo*)fp12;
- (BOOL)cancelTouchTracking;
- (BOOL)cancelMouseTracking;
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event;
- (id)hitTest:(CGPoint)point withEvent:(UIEvent*)event;

@end

