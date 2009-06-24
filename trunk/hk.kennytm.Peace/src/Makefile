CC=gcc-4.4
CPP=g++-4.4
DMD=dmd
CFLAGS=-O2 -g -I../include -Wall -W -Wshadow -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings -fno-common -Wconversion -Werror
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
