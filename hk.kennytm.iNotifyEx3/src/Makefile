all:	libiNotifyEx.dylib

OPTS=-arch armv6 -std=c99 -L/usr/local/lib -Wall -mcpu=arm1176jzf-s -g -I. \
	-isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk \
	-I/Developer/Platforms/iPhoneOS.platform/Developer/usr/include \
	-I/Developer/Platforms/iPhoneOS.platform/Developer/usr/include/gcc/darwin/default \
	-I/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/usr/lib/gcc/arm-apple-darwin9/4.2.1/include \
	-F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/System/Library/PrivateFrameworks/ \
	-I/Users/kennytm/XCodeProjects/iphone-private-frameworks 

CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc-4.2

%.o:	%.m
	$(CC) $(OPTS) -c $< -o $@

%.o:	%.c
	$(CC) $(OPTS) -c $< -o $@

INXIPCUser.c INXIPCServer.c INXIPC.h:	INXInterface.defs
	mig $<

libiNotifyEx.dylib:	INXRemoteAction.o INXCommon.o INXIPCUser.o INXIPCServer.o balanced_substr.o INXIPCServerImpl.o INXWindow.o
	$(CC) $(OPTS) -dynamiclib -install_name /usr/lib/libiNotifyEx.dylib -lsubstrate -framework CoreFoundation -framework UIKit -framework Foundation -framework QuartzCore -framework ChatKit -framework CoreGraphics $^ -o $@
	ldid -S $@

clean:
	-rm *.o

.PHONY:	clean all