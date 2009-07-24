CFLAGS_COMMON=-O2 -I../include -I../src -I/opt/local/include -Wall -W -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings -fno-common -Wconversion -Werror -Wno-unknown-pragmas

CC=gcc-4.2
CPP=g++-4.2
DMD=dmd
CFLAGS=-msse2 $(CFLAGS_COMMON)
DFLAGS=-inline -release -O

CPP_ARMV6=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/g++-4.2
CC_ARMV6=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc-4.2
CFLAGS_ARMV6=-arch armv6 -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk -I/Developer/Platforms/iPhoneOS.platform/Developer/usr/include/gcc/darwin/default -I/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/usr/lib/gcc/arm-apple-darwin9/4.2.1/include -L/usr/local/lib -F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/System/Library/PrivateFrameworks/ -mcpu=arm1176jzf-s $(CFLAGS_COMMON)
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

all:	mac_x86/symbolicate iphone_armv6/symbolicate

mac_x86/symbolicate: symbolicate.o ../src/MachO_File.o ../src/DataFile.o ../src/string_util.o ../src/get_arch_from_flag.o
	$(CPP) $(CFLAGS) -o $@ $^

iphone_armv6/symbolicate: symbolicate.armv6.o ../src/MachO_File.armv6.o ../src/DataFile.armv6.o ../src/string_util.armv6.o ../src/get_arch_from_flag.armv6.o
	$(CPP_ARMV6) $(CFLAGS_ARMV6) -o $@ $^
	$(CODESIGN) $@

clean:
	-rm -f *.o

.PHONY:	all clean
