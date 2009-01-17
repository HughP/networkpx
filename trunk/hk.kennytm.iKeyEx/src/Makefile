iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS2.2.sdk
iPhoneGCCIncPath=$(iPhoneSDKPath)/usr/lib/gcc/powerpc-apple-darwin9/4.0.1/include/
iKeyExIncPath=../../include
iKeyExLibPath=../deb/var/mobile/Library/iKeyEx/lib

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
	-L$(iKeyExLibPath) \
	-Wall \
	-lobjc \
	-march=armv6 \
	-mcpu=arm1176jzf-s \
	-O3 \
	-mthumb

iKeyExSources=cleanup.m common.m ImageLoader.m KeyboardLoader.m UIKBSound.m UIKBKeyDefinition.m UIKBStandardKeyboard.m UIKBStandardKeyboardLayout.m UIKBSpecialKeyButtons.m
iKeyExTarget=$(iKeyExLibPath)/libiKeyEx.dylib
iKeyExOptions=-dynamiclib -init _initDylib

PrefHookerSources=PrefHooker-iKeyEx.m
PrefHookerTarget=$(iKeyExLibPath)/PrefHooker-iKeyEx.dylib
PrefHookerOptions=-dynamiclib -lsubstrate -liKeyEx -framework Preferences -init _installHook

SBHookerSources= UIAccentedCharacterView-setStringWidth.m SBHooker-iKeyEx.m
SBHookerTarget=$(iKeyExLibPath)/SBHooker-iKeyEx.dylib
SBHookerOptions=-dynamiclib -lsubstrate -liKeyEx -init _installHook

KBManSources=iKeyEx-KBMan.m
KBManTarget=../deb/usr/bin/iKeyEx-KBMan
KBManOptions=

all: $(iKeyExTarget) $(PrefHookerTarget) $(SBHookerTarget) $(KBManTarget)

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
	export CODESIGN_ALLOCATE=$(iPhoneDevPath)/usr/bin/codesign_allocate
	$(Compiler) $(Options) $(KBManOptions) -o $@ $^
	#$(CodeSign) $@

clean:
	rm $(iKeyExTarget)
	rm $(PrefHookerTarget)
	rm $(SBHookerTarget)
	rm $(KBManTarget)
