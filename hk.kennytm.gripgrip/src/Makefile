iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS3.0.sdk
iPhoneSimDevPath=/Developer/Platforms/iPhoneSimulator.platform/Developer
iPhoneSimSDKPath=$(iPhoneSimDevPath)/SDKs/iPhoneSimulator3.0.sdk
MobileSubstratePath=../deb/Library/MobileSubstrate/DynamicLibraries
ThemesPath=../deb/Library/GriP/Themes
SharedSrcPath=../../src
PrefsBundlePath=../deb/System/Library/PreferenceBundles

GriPIncPath=../../include/GriP
libGriPPath=../../hk.kennytm.GriP/deb/usr/lib

Compiler=$(iPhoneDevPath)/usr/bin/gcc-4.0
CodeSign=ldid -S

Options=-arch armv6 \
	-std=gnu99 \
	-isysroot $(iPhoneSDKPath) \
	-F$(iPhoneSDKPath)/System/Library/PrivateFrameworks \
	-I$(iPhoneDevPath)/usr/include/gcc/darwin/default \
	-I$(iPhoneSDKPath)/usr/lib/gcc/arm-apple-darwin9/4.0.1/include \
	-I../../include \
	-L/usr/local/lib \
	-Wall \
	-L$(libGriPPath)
	-L/usr/lib/ \
	-mcpu=arm1176jzf-s \
	-O2 \
	-DGRIP_JAILBROKEN=1

DontThumbSources=-

AllTargets=MemWatcher

MemWatcher_Sources=MemWatcher.o
MemWatcher_Target=$(MobileSubstratePath)/MemoryWatcher.dylib
MemWatcher_Options=-lGriP -lobjc -framework Foundation -framework CoreFoundation -dynamiclib -init _first_initializer

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

define MakeTemplate
$$($(1)_Target):	$$($(1)_Sources)
	@$(Compiler) $(Options) $$($(1)_Options) -o $$@ $$^;
#	@strip -x $$@;
	$(CodeSign) $$@

endef

all:	$(foreach target,$(AllTargets),$($(target)_Target))

$(foreach target,$(AllTargets),$(eval $(call MakeTemplate,$(target))))

%.o::	%.m
	$(call CompileRule,$@,$^,$(Options))

%.o::	%.c
	$(call CompileRule,$@,$^,$(Options))

clean:
	rm -f *.o
