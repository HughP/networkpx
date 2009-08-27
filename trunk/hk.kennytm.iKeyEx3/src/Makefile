iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS3.0.sdk
iPhoneSimDevPath=/Developer/Platforms/iPhoneSimulator.platform/Developer
iPhoneSimSDKPath=$(iPhoneSimDevPath)/SDKs/iPhoneSimulator3.0.sdk
MobileSubstratePath=../deb/Library/MobileSubstrate/DynamicLibraries
iKeyExPath=../deb/Library/iKeyEx
SharedSrcPath=../../src
PrefBundlePath=../deb/System/Library/PreferenceBundles
PrivateFrameworksPath=../../../../../iphone-private-frameworks
LibPath=../deb/usr/lib

Compiler=$(iPhoneDevPath)/usr/bin/gcc-4.2 -std=gnu99
CXXCompiler=$(iPhoneDevPath)/usr/bin/g++-4.2
CodeSign=ldid -S
SimCompiler=$(iPhoneSimDevPath)/usr/bin/gcc-4.2 -std=gnu99
SimCXXCompiler=$(iPhoneSimDevPath)/usr/bin/g++-4.2

Options=-arch armv6 \
	-I$(PrivateFrameworksPath) \
	-isysroot $(iPhoneSDKPath) \
	-F$(iPhoneSDKPath)/System/Library/PrivateFrameworks \
	-I$(iPhoneDevPath)/usr/include/gcc/darwin/default \
	-I$(iPhoneSDKPath)/usr/lib/gcc/arm-apple-darwin9/4.2.1/include \
	-I../../include \
	-L/usr/local/lib \
	-L$(LibPath) \
	-Wall \
	-L/usr/lib/ \
	-mcpu=arm1176jzf-s \
	-DNDEBUG \
	-DUSE_SYSTEM_MALLOC=1 \
	-fno-exceptions \
	-O2

SimOptions=-arch i686 \
	-isysroot $(iPhoneSimSDKPath) \
	-I$(PrivateFrameworksPath) \
	-F$(iPhoneSimSDKPath)/System/Library/PrivateFrameworks \
	-I$(iPhoneSimDevPath)/usr/include/gcc/darwin/default \
	-I$(iPhoneSimSDKPath)/usr/lib/gcc/i686-apple-darwin9/4.2.1/include \
	-I../../include \
	-L/usr/local/lib \
	-Wall \
	-L/usr/lib/ \
	-L$(LibPath) \
	-mmacosx-version-min=10.5 \
	-D__IPHONE_OS_VERSION_MIN_REQUIRED=30000 \
	-DNDEBUG \
	-fno-exceptions \
	-DUSE_SYSTEM_MALLOC=1 \
	-O2

DontThumbSources=UIKBKeyboardFromLayoutPlist.m

# x86 or arm
Platform=arm

AllTargets=libiKeyEx KeyboardChooser PrefBundle iKeyExKBMan UIHook

libiKeyEx_Sources=libiKeyEx.o libiKeyEx2.o cin2pat.o ConvertUTF.o
libiKeyEx_Target=$(LibPath)/libiKeyEx.dylib
ifeq ($(Platform),x86)
libiKeyEx_InstallNamePrefix=`pwd`/$(LibPath)
else
libiKeyEx_InstallNamePrefix=/usr/lib
endif
libiKeyEx_Options=-framework Foundation -framework UIKit -framework TextInput -lstdc++ -dynamiclib -install_name $(libiKeyEx_InstallNamePrefix)/libiKeyEx.dylib

KeyboardChooser_Sources=KeyboardChooserLayout.o
KeyboardChooser_Target=$(iKeyExPath)/Keyboards/__KeyboardChooser.keyboard/__KeyboardChooser
KeyboardChooser_Options=-framework Foundation -framework UIKit -framework CoreGraphics -bundle -liKeyEx

UIHook_Sources=iKeyEx3.o UIKBKeyboardFromLayoutPlist.o IKXCinInputManager.o
UIHook_Target=$(MobileSubstratePath)/UIHook-iKeyEx3.dylib
UIHook_Options=-framework Foundation -framework UIKit -framework TextInput -framework ActorKit -framework CoreGraphics -dynamiclib -liKeyEx -lsubstrate -lstdc++ -init _initialize

PrefBundle_Sources=Pref.o
PrefBundle_Target=$(PrefBundlePath)/iKeyEx.bundle/iKeyEx
PrefBundle_Options=-framework Foundation -framework UIKit -framework Preferences -liKeyEx -bundle

iKeyExKBMan_Sources=iKeyEx-KBMan.o
iKeyExKBMan_Target=../deb/usr/bin/iKeyEx-KBMan
iKeyExKBMan_Options=-framework Foundation -liKeyEx

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

define SimCompileRule
	@$(SimCompiler) -c $(3) -o $(1) $(2);
endef

define CXXCompileRule
	@case $(2) in \
		$(DontThumbSources)) \
			$(CXXCompiler) -c $(3) -o $(1) $(2); \
			;; \
		*) \
			$(CXXCompiler) -c $(3) -mthumb -o $(1) $(2); \
			;; \
	esac;
endef

define SimCXXCompileRule
	@$(SimCXXCompiler) -c $(3) -o $(1) $(2);
endef

define MakeTemplate
$$($(1)_Target):	$$($(1)_Sources)
	@$(Compiler) $(Options) $$($(1)_Options) -o $$@ $$^;
#	@strip -x $$@;
	$(CodeSign) $$@

endef

define MakeSimTemplate
$$($(1)_Target):	$$($(1)_Sources)
	$(Compiler) $(SimOptions) $$($(1)_Options) -o $$@ $$^;
#	@strip -x $$@;

endef


all:	$(foreach target,$(AllTargets),$($(target)_Target))

ifeq ($(Platform), x86)

$(foreach target,$(AllTargets),$(eval $(call MakeSimTemplate,$(target))))

%.o::	%.m
	$(call SimCompileRule,$@,$^,$(SimOptions))

%.o::	%.c
	$(call SimCompileRule,$@,$^,$(SimOptions))

%.o::	%.mm
	$(call SimCXXCompileRule,$@,$^,$(SimOptions))

%.o::	%.cpp
	$(call SimCXXCompileRule,$@,$^,$(SimOptions))

else

$(foreach target,$(AllTargets),$(eval $(call MakeTemplate,$(target))))

%.o::	%.m
	$(call CompileRule,$@,$^,$(Options))

%.o::	%.c
	$(call CompileRule,$@,$^,$(Options))

%.o::	%.mm
	$(call CXXCompileRule,$@,$^,$(Options))

%.o::	%.cpp
	$(call CXXCompileRule,$@,$^,$(Options))

endif

clean:
	rm -f *.o
