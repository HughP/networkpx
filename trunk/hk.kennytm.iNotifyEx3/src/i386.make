all: libiNotifyEx.dylib

OPTS=-arch i386 -isysroot /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator3.0.sdk/ \
	-g -dynamiclib -D__IPHONE_OS_VERSION_MIN_REQUIRED=30000 -I. \
	-I/Users/kennytm/XCodeProjects/iphone-private-frameworks \
	-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator3.0.sdk/System/Library/PrivateFrameworks

%.o: %.m
	gcc $(OPTS) -c $< -o $@

%.o: %.c
	gcc -std=gnu99 $(OPTS) -c $< -o $@

INXIPCUser.c INXIPCServer.c INXIPC.h:	INXInterface.defs
	mig $<

libiNotifyEx.dylib:	INXRemoteAction.o INXCommon.o INXIPCUser.o INXIPCServer.o balanced_substr.o INXIPCServerImpl.o
	gcc $(OPTS) -dynamiclib -install_name /usr/lib/libiNotifyEx.dylib -framework CoreFoundation $^ -o $@
	
