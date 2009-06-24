CC=gcc
CPP=g++
DMD=dmd
CFLAGS=-O2 -g -I../include
DFLAGS=-inline -release -O

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $^

%.o: %.cpp
	$(CPP) -c $(CFLAGS) -o $@ $^

%.o: %.d
	$(DMD) -c $(DFLAGS) -of$@ $^

../thumb-ddis: thumb-ddis.o ThumbDumbDisassembler.o AbstractARMDumbDisassembler.o DataFile.o MachO_File.o
	$(CPP) $(CFLAGS) -o $@ $^

clean:
	-rm -f *.o
