Compiler=gcc
Options= -O2

%.o:	%.c
	$(Compiler) $(Options) -c -o $@ $^

LocalizationStatusHelper:	LocalizationStatusHelper.o
	$(Compiler) -framework CoreFoundation -o $@ $^

all:	LocalizationStatusHelper
	