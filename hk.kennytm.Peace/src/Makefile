CC=gcc-4.2
CPP=g++-4.2
DMD=dmd
CFLAGS=-O2 -g -I../include -I/opt/local/include -Wall -W -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings -fno-common -Wconversion -Wno-unknown-pragmas -msse3 -mtune=core2 -m32
DFLAGS=-inline -release -O

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $^

%.o: %.cpp
	$(CPP) -c $(CFLAGS) -o $@ $^

%.o: %.d
	$(DMD) -c $(DFLAGS) -of$@ $^

../thumb-ddis: thumb-ddis.o ThumbDumbDisassembler.o AbstractARMDumbDisassembler.o DataFile.o MachO_File.o get_arch_from_flag.o
	$(CPP) $(CFLAGS) -o $@ $^

clean:
	-rm -f *.o
