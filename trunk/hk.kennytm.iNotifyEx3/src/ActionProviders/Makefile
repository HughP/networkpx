all: std

OPTS=-arch armv6 -std=c99 -L/usr/local/lib -Wall -mcpu=arm1176jzf-s -g -I.. -L.. -dynamiclib \
	-isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk \
	-I/Developer/Platforms/iPhoneOS.platform/Developer/usr/include \
	-I/Developer/Platforms/iPhoneOS.platform/Developer/usr/include/gcc/darwin/default \
	-I/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/usr/lib/gcc/arm-apple-darwin9/4.2.1/include \
	-F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/System/Library/PrivateFrameworks/ \
	-I/Users/kennytm/XCodeProjects/iphone-private-frameworks 

CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc-4.2

OPTS_std=-framework Foundation -framework CoreFoundation -framework UIKit -framework AppSupport -liNotifyEx

%: %.m
	$(CC) $(OPTS) $(OPTS_$@) $< -o $@.dylib
	ldid -S $@.dylib
