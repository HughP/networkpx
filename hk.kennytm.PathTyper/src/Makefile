iPhoneDevPath=/Developer/Platforms/iPhoneOS.platform/Developer
iPhoneSDKPath=$(iPhoneDevPath)/SDKs/iPhoneOS2.2.sdk
iPhoneGCCIncPath=$(iPhoneSDKPath)/usr/lib/gcc/powerpc-apple-darwin9/4.0.1/include/
iKeyExIncPath=../../include
iKeyExLibPath=../../hk.kennytm.iKeyEx/deb/usr/lib

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
	-L$(iPhoneSDKPath)/usr/lib \
	-L$(iKeyExLibPath) \
	-Wall \
	-dynamiclib \
	-lobjc \
	-liKeyEx \
	-march=armv6 \
	-mcpu=arm1176jzf-s \
	-O3 \
	-mthumb

Sources=PathTyper.m
Target=../deb/Library/iKeyEx/Keyboards/PathTyper.keyboard/PathTyper

$(Target):	$(Sources)
	$(Compiler) $(Options) -o $@ $^
	$(CodeSign) $@

clean:
	rm $(Target)