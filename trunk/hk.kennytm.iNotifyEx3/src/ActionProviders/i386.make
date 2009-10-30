all: std

OPTS=-arch i386 -isysroot /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator3.0.sdk/ \
	-g -dynamiclib -D__IPHONE_OS_VERSION_MIN_REQUIRED=30000 -I.. -L.. \
	-I/Users/kennytm/XCodeProjects/iphone-private-frameworks \
	-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator3.0.sdk/System/Library/PrivateFrameworks

OPTS_std=-framework Foundation -framework CoreFoundation -framework UIKit -framework AppSupport -weak-liNotifyEx

%: %.m
	gcc $(OPTS) $(OPTS_$@) $< -o $@.dylib
