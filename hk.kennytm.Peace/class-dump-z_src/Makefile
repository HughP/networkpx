CC=gcc-4.4
CPP=g++-4.4
DMD=dmd
CFLAGS=-O0 -g -lpcre -I../include -I../src -L/opt/local/lib -Wall -W -Wshadow -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings -fno-common -Wconversion -Werror
DFLAGS=-inline -release -O

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $^

%.o: %.cpp
	$(CPP) -c $(CFLAGS) -o $@ $^

%.o: %.d
	$(DMD) -c $(DFLAGS) -of$@ $^

../class-dump-z: class-dump-z.o ../src/DataFile.o ../src/MachO_File.o MachO_File_ObjC.o MachO_File_ObjC_private.o pseudo_base64.o lazy_reachability_matrix.o
	$(CPP) $(CFLAGS) -o $@ $^

objc_type_test:	objc_type_test.cpp objc_type.cpp crc32.c pseudo_base64.cpp
	$(CPP) $(CFLAGS) -o $@ $^

all:	../class-dump-z

clean:
	-rm -f *.o
