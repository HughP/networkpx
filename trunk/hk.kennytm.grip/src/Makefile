iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS2.2.1.sdk
iPhoneSimDevPath=/Developer/Platforms/iPhoneSimulator.platform/Developer
iPhoneSimSDKPath=$(iPhoneSimDevPath)/SDKs/iPhoneSimulator2.2.1.sdk
MobileSubstratePath=../deb/Library/MobileSubstrate/DynamicLibraries
ThemesPath=../deb/Library/GriP/Themes
SharedSrcPath=../../src
PrefsBundlePath=../deb/System/Library/PreferenceBundles

GriPIncPath=../../include/GriP

libVersion               =1.11.14
libGriPCompatVersion     =1.11.13

Compiler=$(iPhoneDevPath)/usr/bin/gcc-4.0
CodeSign=ldid -S

Options=-arch armv6 \
	-std=gnu99 \
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
	-std=gnu99 \
	-isysroot $(iPhoneSDKPath) \
	-I$(iPhoneDevPath)/usr/include/gcc/darwin/default \
	-I$(iPhoneSDKPath)/usr/lib/gcc/arm-apple-darwin9/4.2.1/include \
	-I../../include \
	-O2 \
	-mcpu=arm1176jzf-s \
	-UGRIP_JAILBROKEN

SDKOptionsSim=-arch i686 \
	-std=gnu99 \
	-isysroot $(iPhoneSimSDKPath) \
	-I$(iPhoneSimDevPath)/usr/include/gcc/darwin/default \
	-I$(iPhoneSimSDKPath)/usr/lib/gcc/i686-apple-darwin9/4.2.1/include \
	-I../../include \
	-O2 \
	-UGRIP_JAILBROKEN

DontThumbSources=GPDefaultTheme.m | GPMessageWindow.m | GPPreferences.m | GPModalTableViewController.m | GPModalTableViewSupport.m | $(SharedSrcPath)/GraphicsUtitlities.m

AllTargets=libGriP DefaultTheme XGriP GriPTest Preferences MemWatcher YouveGotMail DefaultThemePrefs
AllSDKTarget=libGriP libGriPServer libGPDefaultTheme

libGriP_Sources=Duplex/Client.o GPApplicationBridge.o GPExtensions.o GPModalTableViewClient.o GPMessageWindow.o GPPreferences.o GPGetSmallAppIcon.o GPUIViewTheme.o GPRawThemeHelper.o
libGriP_Target=../deb/usr/lib/libGriP.dylib
libGriP_Options=-dynamiclib -install_name /usr/lib/libGriP.dylib -compatibility_version $(libGriPCompatVersion) -current_version $(libVersion) -framework CoreFoundation -framework Foundation -framework UIKit -framework CoreGraphics

XGriP_Sources=GriPServer.o Duplex/Server.o GPMessageQueue.o GPModalTableViewController.o GPModalTableViewSupport.o GPModalTableViewServer.o GPMessageLog.o GPMessageLogUI.o
XGriP_Target=$(MobileSubstratePath)/%GriP.dylib
XGriP_Options=-lobjc -lGriP -lsubstrate -dynamiclib -framework Foundation -framework CoreFoundation -framework UIKit -framework CoreGraphics -framework AddressBook -framework AddressBookUI -init _GPStartGriPServer

DefaultTheme_Sources=GPDefaultTheme.o $(SharedSrcPath)/GraphicsUtilities.o
DefaultTheme_Target=$(ThemesPath)/Default.griptheme/Default
DefaultTheme_Options=-lGriP -framework UIKit -framework Foundation -framework CoreGraphics -bundle

DefaultThemePrefs_Sources=GPDefaultThemePrefs.o
DefaultThemePrefs_Target=$(ThemesPath)/Default.griptheme/Preferences.bundle/Preferences
DefaultThemePrefs_Options=-framework Preferences -framework Foundation -lGriP -bundle

DoubleHeightTheme_Sources=GPDoubleHeightTheme.o $(SharedSrcPath)/UIKit3/UIUtilities.o
DoubleHeightTheme_Target=$(ThemesPath)/DoubleHeight.griptheme/DoubleHeight
DoubleHeightTheme_Options=-lGriP -framework UIKit -framework Foundation -bundle

GriPTest_Sources=GriPTest.o
GriPTest_Target=../deb/usr/bin/GriP
GriPTest_Options=-lGriP -framework Foundation

Preferences_Sources=Preferences.o
Preferences_Target=$(PrefsBundlePath)/GriP.bundle/GriP
Preferences_Options=-lGriP -lGriP -framework Preferences -framework Foundation -framework UIKit -framework SpringBoardServices -bundle

MemWatcher_Sources=Extensions/MemWatcher.o
MemWatcher_Target=$(MobileSubstratePath)/MemoryWatcher.dylib
MemWatcher_Options=-lGriP -lobjc -framework Foundation -framework CoreFoundation -dynamiclib -init _first_initializer

YouveGotMail_Sources=Extensions/YouveGotMail.o
YouveGotMail_Target=$(MobileSubstratePath)/YouveGotMail.dylib
YouveGotMail_Options=-lGriP -framework Foundation -framework Message -framework UIKit -dynamiclib -init _initialize

SDK_libGriP_Sources=Duplex/Client.sdk.o GPApplicationBridge.sdk.o
SDK_libGriP_Target=../sdk/libGriP.a
SDK_libGriP_Options=-framework Foundation -static

SDK_libGriPServer_Sources=GPMessageWindow.sdk.o GPPreferences.sdk.o GPGetSmallAppIcon.sdk.o GPUIViewTheme.sdk.o GriPServer.sdk.o Duplex/Server.sdk.o GPRawThemeHelper.sdk.o GPMessageQueue.sdk.o
SDK_libGriPServer_Target=../sdk/libGriPServer.a
SDK_libGriPServer_Options=-framework Foundation -framework UIKit -framework CoreGraphics -static

SDK_libGPDefaultTheme_Sources=GPDefaultTheme.sdk.o $(SharedSrcPath)/GraphicsUtilities.sdk.o
SDK_libGPDefaultTheme_Target=../sdk/libGPDefaultTheme.a
SDK_libGPDefaultTheme_Options=-framework Foundation -framework UIKit -framework CoreGraphics -static

SDK_Headers=$(GriPIncPath)/GPApplicationBridge.h $(GriPIncPath)/GrowlApplicationBridge.h $(GriPIncPath)/common.h $(GriPIncPath)/GrowlDefines.h $(GriPIncPath)/NSString-stringByEscapingXMLEntities.h $(GriPIncPath)/GriP.h $(GriPIncPath)/GriPServer.h $(GriPIncPath)/GPTheme.h $(GriPIncPath)/GPUIViewTheme.h $(GriPIncPath)/GPRawThemeHelper.h $(GriPIncPath)/GPGetSmallAppIcon.h
SDK_Sources=NSString-stringByEscapingXMLEntities.m GrowlApplicationBridge.m ../deb/Library/GriP/GPPreferences.plist

#-----------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------
#------------------------------                                                     ------------------------------
#------------------------------   Don't touch anything after this line, thank you   ------------------------------
#------------------------------                                                     ------------------------------
#-----------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

define CompileRule
	@case $(2) in \
		$(DontThumbSources)) \
			$(Compiler) -c $(3) -o $(1) $(2); \
			;; \
		*) \
			$(Compiler) -c $(3) -mthumb -o $(1) $(2); \
			;; \
	esac;
endef

define SDKCompileRule
	$(call CompileRule,$(1).arm,$(2),$(SDKOptionsARM))
	@$(Compiler) -c $(SDKOptionsSim) -o $(1).i686 $(2); \
	lipo -create $(1).i686 $(1).arm -output $(1); \
	rm $(1).i686 $(1).arm;
endef

define MakeTemplate
$$($(1)_Target):	$$($(1)_Sources)
	@$(Compiler) $(Options) $$($(1)_Options) -o $$@ $$^;
#	@strip -x $$@;
	$(CodeSign) $$@

endef

all:	$(foreach target,$(AllTargets),$($(target)_Target))

$(foreach target,$(AllTargets),$(eval $(call MakeTemplate,$(target))))


%.sdk.o::	%.m
	$(call SDKCompileRule,$@,$^)

%.sdk.o::	%.c
	$(call SDKCompileRule,$@,$^)
	
%.o::	%.m
	$(call CompileRule,$@,$^,$(Options))

%.o::	%.c
	$(call CompileRule,$@,$^,$(Options))

$(ThemesPath)/%.griptheme/GriPView.nib:	%.xib
	ibtool --compile $@ $^

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
	@$(Compiler) $(SDKOptionsARM) ../sdktest.m $(SDK_libGriP_Target) $(SDK_libGriPServer_Target) $(SDK_libGPDefaultTheme_Target) -framework CoreFoundation -framework Foundation -framework UIKit -framework CoreGraphics
	@$(Compiler) $(SDKOptionsSim) ../sdktest.m $(SDK_libGriP_Target) $(SDK_libGriPServer_Target) $(SDK_libGPDefaultTheme_Target) -framework CoreFoundation -framework Foundation -framework UIKit -framework CoreGraphics
	@rm a.out
	tar --exclude=".*" -cjf ../GriP-for-SDK-developers.tar.bz2 -C .. sdk

clean:
	rm -f *.o
	rm -f Duplex/*.o
	rm -f Extensions/*.o
	rm -f ../sdk/*.h
	rm -f ../sdk/*.* ../sdk/GriP/*.h ../sdk/GriP/Duplex/*.h