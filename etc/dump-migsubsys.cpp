/*

dump-migsubsys.cpp ... Dump detail of MiG subsystem embedded in a server code.
Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

// g++ -m32 -O2 dump-migsubsys.cpp -I../trunk/hk.kennytm.Peace/src ../trunk/hk.kennytm.Peace/src/DataFile.cpp ../trunk/hk.kennytm.Peace/src/MachO_File.cpp -I../trunk/hk.kennytm.Peace/include -I/opt/local/include ../trunk/hk.kennytm.Peace/src/get_arch_from_flag.c -o dump-migsubsys

#include <cstring>
#include <MachO_File.h>
#include <mach/mig.h>
using namespace std;

static void print_address(const char* prefix, const MachO_File& f, const void* addr) {
	const char* sym = addr == 0 ? "NULL" : f.string_representation(reinterpret_cast<unsigned>(addr));
	int offset = static_cast<int>( f.to_file_offset(reinterpret_cast<unsigned>(addr)) );
	if (sym != NULL)
		printf("%s%s,\t// %x\n", prefix, sym, offset);
	else
		printf("%s%p,\t// %x\n", prefix, addr, offset);
}

int main (int argc, const char* argv[]) {
	const char* arch = "any";
	int startidx = 1;
	
	if (argc == 5) {
		if (strcmp(argv[1], "-arch") != 0) {
			fprintf(stderr, "Error: Unrecognized option: %s\n", argv[1]);
			goto unrecopt;
		}
		arch = argv[2];
		startidx = 3;
		goto next;
		
	} else if (argc == 3) {
next:
		const char* binary = argv[startidx];
		const char* symbol = argv[startidx+1];
		unsigned addr = 0;
		unsigned symlen = strlen(symbol);

		if (symlen > 2 && symbol[0] == '0' && (symbol[1] == 'x' || symbol[1] == 'X')) {
			symbol += 2;
			symlen -= 2;
		}
		if (strspn(symbol, "0123456789abcdefABCDEF") == symlen) {
			sscanf(symbol, "%x", &addr);
			symbol = NULL;
		} else
			symbol = argv[startidx+1];
		
		MachO_File f (binary, arch);
		
		if (!f.valid() || f.encrypted()) {
			fprintf(stderr, "Error: %s is an invalid or encrypted Mach-O binary.\n", binary);
		} else {
			if (symbol != NULL)
				addr = f.address_of_symbol(symbol);
			if (addr == 0)
				fprintf(stderr, "Error: Invalid address or symbol %s not found.\n", symbol);
			else {
				off_t fileaddr = f.to_file_offset(addr);
				if (fileaddr == 0)
					fprintf(stderr, "Error: Invalid VM address %u.\n", addr);
				else {
					f.seek(fileaddr);
					const struct mig_subsystem* subsys = f.read_data<struct mig_subsystem>();
					if (subsys == NULL) {
						fprintf(stderr, "Error: Invalid VM address %u.\n", addr);
					} else {
						print_address("{ server:   ", f, reinterpret_cast<const void*>(subsys->server));
						printf("  start:    %d,\n", subsys->start);
						printf("  end:      %d,\n", subsys->end);
						printf("  maxsize:  %u,\n", subsys->maxsize);
						printf("  reserved: %d,\n", subsys->reserved);
						printf("  routine:\n");
						const mig_routine_descriptor* descr = subsys->routine;
						for (int i = subsys->start; i < subsys->end; ++ i, ++descr) {
							printf("  { // msg# %d\n", i);
							print_address("    impl_routine:  ", f, reinterpret_cast<const void*>(descr->impl_routine));
							print_address("    stub_routine:  ", f, reinterpret_cast<const void*>(descr->stub_routine));
							printf("    argc:          %d,\n", descr->argc);
							printf("    descr_count:   %d,\n", descr->descr_count);
							print_address("    arg_descr:     ", f, reinterpret_cast<const void*>(descr->arg_descr));
							printf("    max_reply_msg: %d\n", descr->max_reply_msg);
							printf("  },\n");
						}
						printf("}\n");
					}
				}
			}
		}
		
	} else {
unrecopt:
		printf("Usage: dump-migsubsys [-arch <arch>] <binary> <subsys-addr/symbol>\n\n");
	}
	
	return 0;
}