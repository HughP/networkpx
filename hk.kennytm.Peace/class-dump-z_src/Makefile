CC=gcc-4.2
CPP=g++-4.2
DMD=dmd
CFLAGS=-O0 -g -msse2 -I../include -I../src -I/opt/local/include -Wall -W -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings -fno-common -Wconversion -Werror -Wno-unknown-pragmas
DFLAGS=-inline -release -O

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $^

%.o: %.cpp
	$(CPP) -c $(CFLAGS) -o $@ $^

%.o: %.d
	$(DMD) -c $(DFLAGS) -of$@ $^

../class-dump-z: class-dump-z.o ../src/DataFile.o ../src/MachO_File.o MachO_File_ObjC.o MachO_File_ObjC_retrieval.o MachO_File_ObjC_format.o balanced_substr.o crc32.o pseudo_base64.o objc_type.o string_util.o MachO_File_ObjC_debug.o
	$(CPP) -Wl,/opt/local/lib/libpcre.a $(CFLAGS) -o $@ $^

objc_type_test:	objc_type_test.o objc_type.o crc32.o pseudo_base64.o string_util.o balanced_substr.o
	$(CPP) $(CFLAGS) -o $@ $^

all:	../class-dump-z

clean:
	-rm -f *.o
