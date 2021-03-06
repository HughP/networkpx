iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS2.2.sdk
iPhoneGCCIncPath=$(iPhoneSDKPath)/usr/lib/gcc/powerpc-apple-darwin9/4.0.1/include/
incPath=../../include
libPath=../deb/usr/lib
binPath=../deb/usr/bin
MobileSubstratePath=../deb/Library/MobileSubstrate/DynamicLibraries
PreferencesPath=../deb/System/Library/PreferenceBundles/Command.bundle
UIKit3SrcPath=../../src/UIKIt3

Compiler=$(iPhoneDevPath)/usr/bin/arm-apple-darwin9-gcc-4.0.1
CodeSign=ldid -S

Options=-lobjc \
	-std=c99 \
	-I$(iPhoneSDKPath)/usr/include \
	-I$(iPhoneDevPath)/usr/include \
	-I$(iPhoneGCCIncPath) \
	-I$(incPath) \
	-F$(iPhoneSDKPath)/System/Library/Frameworks \
	-F$(iPhoneSDKPath)/System/Library/PrivateFrameworks \
	-framework Foundation \
	-framework UIKit \
	-framework CoreFoundation \
	-framework CoreGraphics \
	-L$(iPhoneSDKPath)/usr/lib \
	-L/usr/local/lib \
	-L$(libPath) \
	-Wall \
	-lobjc \
	-march=armv6 \
	-mcpu=arm1176jzf-s \
	-O3 \
	-mthumb

CommandletToolsSources=Commandlet-Tools.m
CommandletToolsTarget=$(binPath)/Commandlet-Tools
CommandletToolsOptions=

UIHookerSources=UIHooker-Command.m
UIHookerTarget=$(MobileSubstratePath)/UIHooker-Command.dylib
UIHookerOptions=-lsubstrate -dynamiclib -init _init

PrefSources=prefs.m $(UIKit3SrcPath)/UIBadgeView.m
PrefTarget=$(PreferencesPath)/Command
PrefOptions=-framework Preferences -bundle

all: $(CommandletToolsTarget) $(UIHookerTarget) $(PrefTarget)

$(CommandletToolsTarget):	$(CommandletToolsSources)
	$(Compiler) $(Options) $(CommandletToolsOptions) -o $@ $^
	$(CodeSign) $@

$(UIHookerTarget):	$(UIHookerSources)
	$(Compiler) $(Options) $(UIHookerOptions) -o $@ $^
	$(CodeSign) $@

$(PrefTarget):	$(PrefSources)
	$(Compiler) $(Options) $(PrefOptions) -o $@ $^
	$(CodeSign) $@

clean:
	rm $(CommandletToolsTarget)
	rm $(UIHookerTarget)