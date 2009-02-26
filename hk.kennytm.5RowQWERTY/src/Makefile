iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS2.2.sdk
iPhoneGCCIncPath=$(iPhoneSDKPath)/usr/lib/gcc/powerpc-apple-darwin9/4.0.1/include/
iKeyExIncPath=../../include
iKeyExLibPath=../../hk.kennytm.iKeyEx/deb/usr/lib
CMLSrcPath=../../hk.kennytm.Command/src
SharedSrcPath=../../src
UIKit3SrcPath=$(SharedSrcPath)/UIKit3

Compiler=$(iPhoneDevPath)/usr/bin/arm-apple-darwin9-gcc-4.0.1
CodeSign=ldid -S

Compiler=$(iPhoneDevPath)/usr/bin/arm-apple-darwin9-gcc-4.0.1

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
	-framework WebCore \
	-L$(iPhoneSDKPath)/usr/lib \
	-L$(iKeyExLibPath) \
	-Wall \
	-lobjc \
	-march=armv6 \
	-mcpu=arm1176jzf-s \
	-O3 \
	-mthumb	

LayoutSources=5RowQWERTY.m $(CMLSrcPath)/CMLSelection.m
LayoutTarget=../deb/Library/iKeyEx/Keyboards/5RowQWERTY.keyboard/5RowQWERTY
LayoutOptions=-liKeyEx -dynamiclib -init _init

PrefSources=prefs.m $(SharedSrcPath)/GraphicsUtilities.m $(UIKit3SrcPath)/UIUtilities.m $(UIKit3SrcPath)/UIBigCharacterHUD.m $(UIKit3SrcPath)/UIActionSheetPro.m $(UIKit3SrcPath)/UIEasyPickerView.m
PrefTarget=../deb/Library/iKeyEx/Keyboards/5RowQWERTY.keyboard/Preferences.bundle/5RowQWERTY
PrefOptions=-framework Preferences -framework CoreGraphics -framework WebKit -licucore -liKeyEx -bundle

all:	$(LayoutTarget) $(PrefTarget)

$(LayoutTarget):	$(LayoutSources)
	$(Compiler) $(Options) $(LayoutOptions) -o $@ $^
	$(CodeSign) $@

$(PrefTarget):	$(PrefSources)
	$(Compiler) $(Options) $(PrefOptions) -o $@ $^
	$(CodeSign) $@

clean:
	rm $(Target)
