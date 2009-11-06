#!/bin/sh

g++ -m32 -O2 list_symbols.cpp get_arch_from_flag.c MachO_File.cpp DataFile.cpp -I../include -I/opt/local/include -o list_symbols
