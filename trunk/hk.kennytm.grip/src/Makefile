iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS3.0.sdk
MobileSubstratePath=../deb/Library/MobileSubstrate/DynamicLibraries
ThemesPath=../deb/Library/GriP/Themes
SharedSrcPath=../../src
PrefsBundlePath=../deb/System/Library/PreferenceBundles

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
	-O2

libGriP_Sources=Duplex/Client.o GPMessageWindow.o GPPreferences.o GPGetSmallAppIcon.o GPApplicationBridge.o
libGriP_Target=../deb/usr/lib/libGriP.dylib
libGriP_Options=-lobjc -dynamiclib -install_name /usr/lib/libGriP.dylib -framework Foundation -framework CoreFoundation -framework UIKit -framework CoreGraphics

XXHooker_GriP_Sources=XXHooker-GriP.o Duplex/Server.o ../../src/PrefsLinkHooker.o
XXHooker_GriP_Target=$(MobileSubstratePath)/XXHooker-GriP.dylib
XXHooker_GriP_Options=-lobjc -lGriP -lsubstrate -dynamiclib -framework Foundation -framework CoreFoundation -framework Preferences -init _initialize

DefaultTheme_Sources=GPDefaultTheme.o
DefaultTheme_Target=$(ThemesPath)/Default.griptheme/Default
DefaultTheme_Options=-lobjc -bundle -lGriP -framework Foundation -framework CoreFoundation -framework UIKit -framework CoreGraphics

GriPTest_Sources=GriPTest.o GrowlApplicationBridge.o Duplex/Client.o GPApplicationBridge.o
GriPTest_Target=GriPTest
GriPTest_Options=-framework Foundation -framework CoreFoundation -framework UIKit -framework CoreGraphics 

Preferences_Sources=Preferences.o Duplex/Client.o
Preferences_Target=$(PrefsBundlePath)/GriP.bundle/GriP
Preferences_Options=-lGriP -framework Preferences -framework Foundation -framework UIKit -bundle


all: $(libGriP_Target) $(DefaultTheme_Target) $(XXHooker_GriP_Target) $(GriPTest_Target) $(Preferences_Target)

%.o:	%.m
	$(Compiler) -c $(Options) -o $@ $^

%.o:	%.c
	$(Compiler) -c $(Options) -o $@ $^

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

clean:
	rm -f *.o
	rm -f Duplex/*.o
