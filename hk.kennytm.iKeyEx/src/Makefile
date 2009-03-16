iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS2.2.sdk
iPhoneGCCIncPath=$(iPhoneSDKPath)/usr/lib/gcc/powerpc-apple-darwin9/4.0.1/include/
iKeyExIncPath=../../include
iKeyExLibPath=../deb/usr/lib
iKeyExBinPath=../deb/usr/bin
MobileSubstratePath=../deb/Library/MobileSubstrate/DynamicLibraries
iKeyExPrefPath=../deb/System/Library/PreferenceBundles/iKeyEx.bundle
iKeyExKeyboardPath=../deb/Library/iKeyEx/Keyboards/__KeyboardChooser.keyboard
SharedSrcPath=../../src

Compiler=$(iPhoneDevPath)/usr/bin/arm-apple-darwin9-gcc-4.0.1
CodeSign=ldid -S

Options=-lobjc \
	-std=c99 \
	-I$(iPhoneSDKPath)/usr/include \
	-I$(iPhoneDevPath)/usr/include \
	-I$(iPhoneGCCIncPath) \
	-I$(iKeyExIncPath) \
	-F$(iPhoneSDKPath)/System/Library/Frameworks \
	-F$(iPhoneSDKPath)/System/Library/PrivateFrameworks \
	-framework Foundation \
	-framework UIKit \
	-framework CoreFoundation \
	-framework CoreGraphics \
	-L$(iPhoneSDKPath)/usr/lib \
	-L/usr/local/lib \
	-L$(iKeyExLibPath) \
	-Wall \
	-lobjc \
	-march=armv6 \
	-mcpu=arm1176jzf-s \
	-O3 \
	-mthumb

iKeyExSources=$(SharedSrcPath)/GraphicsUtilities.m cleanup.m common.m ImageLoader.m KeyboardLoader.m UIKBSound.m UIKBKeyDefinition.m UIKBStandardKeyboard.m UIKBStandardKeyboardLayout.m UIKBSpecialKeyButtons.m
iKeyExTarget=$(iKeyExLibPath)/libiKeyEx.dylib
iKeyExOptions=-dynamiclib -init _initDylib -framework WebKit -framework WebCore

PrefHookerSources=PrefHooker-iKeyEx-InternationalKeyboardController.m $(SharedSrcPath)/PrefsLinkHooker.m PrefHooker-iKeyEx.m
PrefHookerTarget=$(MobileSubstratePath)/PrefHooker-iKeyEx.dylib
PrefHookerOptions=-dynamiclib -lsubstrate -liKeyEx -framework Preferences -init _installHook

SBHookerSources= UIAccentedCharacterView-setStringWidth.m SBHooker-iKeyEx.m
SBHookerTarget=$(MobileSubstratePath)/SBHooker-iKeyEx.dylib
SBHookerOptions=-dynamiclib -lsubstrate -liKeyEx -init _installHook

KBManSources=iKeyEx-KBMan.m
KBManTarget=$(iKeyExBinPath)/iKeyEx-KBMan
KBManOptions=

PrefPaneSources=PrefPane-iKeyEx.m $(SharedSrcPath)/UIKit3/UIUtilities.m $(SharedSrcPath)/MailCrashLog.m $(SharedSrcPath)/UIKit3/UIMailComposeView.m
PrefPaneTarget=$(iKeyExPrefPath)/iKeyEx
PrefPaneOptions=-bundle -framework Preferences -framework WebKit -framework WebCore -framework MessageUI -framework Message -liKeyEx

KeyboardChooserSources=KeyboardChooserLayout.m $(SharedSrcPath)/UIKit4/UIEasyTableView.m
KeyboardChooserTarget=$(iKeyExKeyboardPath)/__KeyboardChooser
KeyboardChooserOptions=-bundle -liKeyEx

all: $(iKeyExTarget) $(PrefHookerTarget) $(SBHookerTarget) $(KBManTarget) $(PrefPaneTarget) $(KeyboardChooserTarget)

$(iKeyExTarget):	$(iKeyExSources)
	$(Compiler) $(Options) $(iKeyExOptions) -o $@ $^
	$(CodeSign) $@

$(PrefHookerTarget):	$(PrefHookerSources)
	$(Compiler) $(Options) $(PrefHookerOptions) -o $@ $^
	$(CodeSign) $@

$(SBHookerTarget):	$(SBHookerSources)
	$(Compiler) $(Options) $(SBHookerOptions) -o $@ $^
	$(CodeSign) $@

$(KBManTarget):	$(KBManSources)
	@echo "iKeyEx-KBMan requires setuid. Please enter root password:"
	sudo $(Compiler) $(Options) $(KBManOptions) -o $@ $^
	sudo $(CodeSign) $@
	sudo chmod ug+s $@

$(PrefPaneTarget):	$(PrefPaneSources)
	$(Compiler) $(Options) $(PrefPaneOptions) -o $@ $^
	$(CodeSign) $@

$(KeyboardChooserTarget):	$(KeyboardChooserSources)
	$(Compiler) $(Options) $(KeyboardChooserOptions) -o $@ $^
	$(CodeSign) $@

clean:
	rm $(iKeyExTarget)
	rm $(PrefHookerTarget)
	rm $(SBHookerTarget)
	rm $(KBManTarget)
	rm $(PrefPaneTarget)
	rm $(KeyboardChooserTarget)
