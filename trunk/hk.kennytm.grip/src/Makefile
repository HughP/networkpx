iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS3.0.sdk
MobileSubstratePath=../deb/Library/MobileSubstrate/DynamicLibraries
ThemesPath=../deb/Library/GriP/Themes
SharedSrcPath=../../src
PrefsBundlePath=../deb/System/Library/PreferenceBundles

GriPIncPath=../../include/GriP

Compiler=$(iPhoneDevPath)/usr/bin/gcc-4.2
CodeSign=ldid -S

Options=-arch armv6 \
	-std=c99 \
	-isysroot $(iPhoneSDKPath) \
	-F$(iPhoneSDKPath)/System/Library/PrivateFrameworks \
	-I$(iPhoneDevPath)/usr/include/gcc/darwin/default \
	-I$(iPhoneSDKPath)/usr/lib/gcc/arm-apple-darwin9/4.2.1/include \
	-I../../include \
	-L/usr/local/lib \
	-Wall \
	-L../deb/usr/lib \
	-L/usr/lib/ \
	-mcpu=arm1176jzf-s \
	-O2 \
	-DGRIP_JAILBROKEN=1

SDKOptionsARM=-arch armv6 \
	-std=c99 \
	-isysroot $(iPhoneSDKPath) \
	-I$(iPhoneDevPath)/usr/include/gcc/darwin/default \
	-I$(iPhoneSDKPath)/usr/lib/gcc/arm-apple-darwin9/4.2.1/include \
	-I../../include \
	-O2 \
	-mcpu=arm1176jzf-s \
	-UGRIP_JAILBROKEN

iPhoneSimDevPath=/Developer/Platforms/iPhoneSimulator.platform/Developer
iPhoneSimSDKPath=$(iPhoneSimDevPath)/SDKs/iPhoneSimulator3.0.sdk
SDKOptionsSim=-arch i686 \
	-std=c99 \
	-isysroot $(iPhoneSimSDKPath) \
	-I$(iPhoneSimDevPath)/usr/include/gcc/darwin/default \
	-I$(iPhoneSimSDKPath)/usr/lib/gcc/i686-apple-darwin9/4.2.1/include \
	-I../../include \
	-O2 \
	-UGRIP_JAILBROKEN

libGriP_Sources=Duplex/Client.o GPMessageWindow.o GPPreferences.o GPGetSmallAppIcon.o GPApplicationBridge.o GPExtensions.o NSString-stringByEscapingXMLEntities.o GPUIViewTheme.o
libGriP_Target=../deb/usr/lib/libGriP.dylib
libGriP_Options=-lobjc -dynamiclib -install_name /usr/lib/libGriP.dylib -framework Foundation -framework CoreFoundation -framework UIKit -framework CoreGraphics

XXHooker_GriP_Sources=GriPServer.o Duplex/Server.o ../../src/PrefsLinkHooker.o
XXHooker_GriP_Target=$(MobileSubstratePath)/%GriP.dylib
XXHooker_GriP_Options=-lobjc -lGriP -lsubstrate -dynamiclib -framework Foundation -framework CoreFoundation -framework Preferences -framework UIKit -init _GPStartGriPServer

DefaultTheme_Sources=GPDefaultTheme.o $(SharedSrcPath)/GraphicsUtilities.o
DefaultTheme_Target=$(ThemesPath)/Default.griptheme/Default
DefaultTheme_Options=-lGriP -framework UIKit -framework Foundation -framework CoreGraphics -bundle

GriPTest_Sources=GriPTest.o
GriPTest_Target=../deb/usr/bin/GriP
GriPTest_Options=-lGriP -framework Foundation

Preferences_Sources=Preferences.o
Preferences_Target=$(PrefsBundlePath)/GriP.bundle/GriP
Preferences_Options=-lGriP -framework Preferences -framework Foundation -framework UIKit -bundle

MemWatcher_Sources=Extensions/MemWatcher.o
MemWatcher_Target=$(MobileSubstratePath)/MemoryWatcher.dylib
MemWatcher_Options=-lGriP -framework Foundation -dynamiclib -init _first_initializer

YouveGotMail_Sources=Extensions/YouveGotMail.o
YouveGotMail_Target=$(MobileSubstratePath)/YouveGotMail.dylib
YouveGotMail_Options=-lGriP -framework Foundation -framework Message -framework UIKit -dynamiclib -init _initialize

SDK_libGriP_Sources=Duplex/Client.sdk.o GPApplicationBridge.sdk.o
SDK_libGriP_Target=../sdk/libGriP.a
SDK_libGriP_Options=-framework Foundation -static

SDK_libGriPServer_Sources=Duplex/Client.sdk.o GPMessageWindow.sdk.o GPPreferences.sdk.o GPGetSmallAppIcon.sdk.o GPUIViewTheme.sdk.o GriPServer.sdk.o Duplex/Server.sdk.o 
SDK_libGriPServer_Target=../sdk/libGriPServer.a
SDK_libGriPServer_Options=-framework Foundation -framework UIKit -framework CoreGraphics -static

SDK_libGPDefaultTheme_Sources=GPDefaultTheme.sdk.o $(SharedSrcPath)/GraphicsUtilities.sdk.o
SDK_libGPDefaultTheme_Target=../sdk/libGPDefaultTheme.a
SDK_libGPDefaultTheme_Options=-framework Foundation -framework UIKit -framework CoreGraphics -static

SDK_Headers=$(GriPIncPath)/GPApplicationBridge.h $(GriPIncPath)/GrowlApplicationBridge.h $(GriPIncPath)/common.h $(GriPIncPath)/GrowlDefines.h $(GriPIncPath)/NSString-stringByEscapingXMLEntities.h $(GriPIncPath)/GriP.h $(GriPIncPath)/GriPServer.h $(GriPIncPath)/GPTheme.h $(GriPIncPath)/GPUIViewTheme.h
SDK_Sources=NSString-stringByEscapingXMLEntities.m GrowlApplicationBridge.m ../deb/Library/GriP/GPPreferences.plist

all: $(libGriP_Target) $(DefaultTheme_Target) $(XXHooker_GriP_Target) $(GriPTest_Target) $(Preferences_Target) $(MemWatcher_Target) $(YouveGotMail_Target)

%.sdk.o:	%.m
	$(Compiler) -c $(SDKOptionsSim) -o $@.i686 $^
	$(Compiler) -c $(SDKOptionsARM) -o $@.arm $^
	lipo -create $@.i686 $@.arm -output $@
	rm $@.i686 $@.arm

%.sdk.o:	%.c
	$(Compiler) -c $(SDKOptionsSim) -o $@.i686 $^
	$(Compiler) -c $(SDKOptionsARM) -o $@.arm $^
	lipo -create $@.i686 $@.arm -output $@
	rm $@.i686 $@.arm

%.o:	%.m
	$(Compiler) -c $(Options) -o $@ $^

%.o:	%.c
	$(Compiler) -c $(Options) -o $@ $^

$(ThemesPath)/%.griptheme/GriPView.nib:	%.xib
	ibtool --compile $@ $^

$(libGriP_Target):	$(libGriP_Sources)
	$(Compiler) $(Options) $(libGriP_Options) -o $@ $^
	$(CodeSign) $@

$(XXHooker_GriP_Target):	$(XXHooker_GriP_Sources)
	$(Compiler) $(Options) $(XXHooker_GriP_Options) -o $@ $^
	$(CodeSign) $@

$(DefaultTheme_Target):	$(DefaultTheme_Sources) 
	$(Compiler) $(Options) $(DefaultTheme_Options) -o $@ $^
	$(CodeSign) $@

$(GriPTest_Target):	$(GriPTest_Sources)
	$(Compiler) $(Options) $(GriPTest_Options) -o $@ $^
	$(CodeSign) $@

$(Preferences_Target):	$(Preferences_Sources)
	$(Compiler) $(Options) $(Preferences_Options) -o $@ $^
	$(CodeSign) $@

$(MemWatcher_Target):	$(MemWatcher_Sources)
	$(Compiler) $(Options) $(MemWatcher_Options) -o $@ $^
	$(CodeSign) $@

$(YouveGotMail_Target):	$(YouveGotMail_Sources)
	$(Compiler) $(Options) $(YouveGotMail_Options) -o $@ $^
	$(CodeSign) $@

sdk: $(SDK_libGriP_Target) $(SDK_libGriPServer_Target) $(SDK_libGPDefaultTheme_Target) SDKEtc

$(SDK_libGriP_Target): $(SDK_libGriP_Sources)
	libtool -static -o $@ $^

$(SDK_libGriPServer_Target): $(SDK_libGriPServer_Sources)
	libtool -static -o $@ $^

$(SDK_libGPDefaultTheme_Target): $(SDK_libGPDefaultTheme_Sources)
	libtool -static -o $@ $^

SDKEtc:	$(SDK_Headers) $(SDK_Sources)
	cp $(SDK_Sources) ../sdk/
	cp $(SDK_Headers) ../sdk/GriP/
	cp $(GriPIncPath)/Duplex/Client.h ../sdk/GriP/Duplex/
	tar --exclude=".*" -cjf ../GriP-for-SDK-developers.tar.bz2 -C .. sdk

clean:
	rm -f *.o
	rm -f Duplex/*.o
	rm -f Extensions/*.o