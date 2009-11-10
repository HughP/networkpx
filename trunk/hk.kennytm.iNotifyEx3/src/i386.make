all: libiNotifyEx.x86.dylib

OPTS=-arch i386 -isysroot /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator3.0.sdk/ \
	-g -dynamiclib -D__IPHONE_OS_VERSION_MIN_REQUIRED=30000 -I. \
	-I/Users/kennytm/XCodeProjects/iphone-private-frameworks \
	-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator3.0.sdk/System/Library/PrivateFrameworks

%.i386.o: %.m
	gcc $(OPTS) -c $< -o $@

%.i386.o: %.c
	gcc -std=gnu99 $(OPTS) -c $< -o $@

INXIPCUser.c INXIPCServer.c INXIPC.h:	INXInterface.defs
	mig $<

libiNotifyEx.x86.dylib:	INXRemoteAction.i386.o INXCommon.i386.o INXIPCUser.i386.o INXIPCServer.i386.o balanced_substr.i386.o INXIPCServerImpl.i386.o
	gcc $(OPTS) -dynamiclib -install_name /usr/lib/libiNotifyEx.dylib -framework CoreFoundation $^ -o $@
	
