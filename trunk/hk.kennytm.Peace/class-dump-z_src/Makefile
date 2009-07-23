CFLAGS_COMMON=-g -O0 -I../include -I../src -I/opt/local/include -Wall -W -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings -fno-common -Wconversion -Werror -Wno-unknown-pragmas

CC=gcc-4.2
CPP=g++-4.2
DMD=dmd
CFLAGS=-msse2 $(CFLAGS_COMMON)
DFLAGS=-inline -release -O

CPP_ARMV6=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/g++-4.2
CC_ARMV6=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc-4.2
CFLAGS_ARMV6=-arch armv6 -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk -I/Developer/Platforms/iPhoneOS.platform/Developer/usr/include/gcc/darwin/default -I/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/usr/lib/gcc/arm-apple-darwin9/4.2.1/include -L/usr/local/lib -F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/System/Library/PrivateFrameworks/ -mcpu=arm1176jzf-s -L. $(CFLAGS_COMMON)
CODESIGN=ldid -S

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $^

%.o: %.cpp
	$(CPP) -c $(CFLAGS) -o $@ $^

%.armv6.o:	%.cpp
	$(CPP_ARMV6) -c $(CFLAGS_ARMV6) -o $@ $^

%.armv6.o:	%.c
	$(CC_ARMV6) -c $(CFLAGS_ARMV6) -o $@ $^

%.o: %.d
	$(DMD) -c $(DFLAGS) -of$@ $^

all:	../output/mac_x86/class-dump-z ../output/iphone_armv6/class-dump-z

../class-dump-z: class-dump-z.o ../src/DataFile.o ../src/MachO_File.o MachO_File_ObjC.o MachO_File_ObjC_retrieval.o MachO_File_ObjC_format.o balanced_substr.o crc32.o pseudo_base64.o objc_type.o string_util.o MachO_File_ObjC_debug.o
	$(CPP) $(CFLAGS) -o $@ $^ libpcre.a

../output/iphone_armv6/class-dump-z: class-dump-z.armv6.o ../src/DataFile.armv6.o ../src/MachO_File.armv6.o MachO_File_ObjC.armv6.o MachO_File_ObjC_retrieval.armv6.o MachO_File_ObjC_format.armv6.o balanced_substr.armv6.o crc32.armv6.o pseudo_base64.armv6.o objc_type.armv6.o string_util.armv6.o MachO_File_ObjC_debug.armv6.o
	$(CPP_ARMV6) -lpcre $(CFLAGS_ARMV6) -o $@ $^
	$(CODESIGN) $@

../output/mac_x86/class-dump-z:	../class-dump-z
	cp $^ $@

objc_type_test:	objc_type_test.o objc_type.o crc32.o pseudo_base64.o string_util.o balanced_substr.o
	$(CPP) $(CFLAGS) -o $@ $^

clean:
	-rm -f *.o

.PHONY:	all clean
