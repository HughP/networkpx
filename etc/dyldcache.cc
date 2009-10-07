// Originally written by DHowett, see http://blog.howett.net/?p=75
// "if you find it useful, do whatever you want with it. just don't forget that somebody helped."

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <string.h>

#include <map>
#include <vector>
#include <string>
#include <iostream>
#include <sstream>
#include <iterator>
#include <deque>
using namespace std;

#include "mach-o/loader.h"
#include "mach-o/nlist.h"
#include "mach-o/reloc.h"

#include <errno.h>

/* SL mach-o stuff that I don't have here */
#define LC_DYLD_INFO_ONLY 0x80000022
struct dyld_info_only_32 {
	uint32_t cmd;
	uint32_t cmdsize;
	uint32_t rebase_off;
	uint32_t rebase_size;
	uint32_t bind_off;
	uint32_t bind_size;
	uint32_t weak_bind_off;
	uint32_t weak_bind_size;
	uint32_t lazy_bind_off;
	uint32_t lazy_bind_size;
	uint32_t export_off;
	uint32_t export_size;
};
/* fin */

struct cache_header {
	char version[16];
	uint32_t baseaddroff;
	uint32_t unk2;
	uint32_t startaddr;
	uint32_t numlibs;

	uint64_t dyldaddr;
	//uint64_t codesignoff;
};

static uint8_t *_cacheData;
static struct cache_header *_cacheHead;

class Ticket {
	public:
		virtual string description() const = 0;
		virtual void apply(void *dest) const = 0;
};

class CopyTicket : public Ticket {
	private:
		void *source;
		size_t len;
		off_t offset;
	public:
		CopyTicket(size_t len, void *source, off_t offset) {
			this->len = len;
			this->source = source;
			this->offset = offset;
		}

		virtual string description() const {
			stringstream ss;
			ss << "Ticket to copy " << len << " bytes from " << source << " to " << offset;
			return ss.str();
		}
		virtual void apply(void *dest) const {
			memcpy((uint8_t *)dest + offset, source, len);
		}
};

class PatchTicket : public Ticket {
	private:
		uint32_t data;
		off_t offset;
	public:
		PatchTicket(uint32_t data, off_t offset) {
			this->data = data;
			this->offset = offset;
		}

		virtual string description() const {
			stringstream ss;
			ss << "Ticket to write " << data << " at " << offset;
			return ss.str();
		}

		virtual void apply(void *dest) const {
			*(uint32_t *)((uint8_t *)dest + offset) = data;
		}
};

class BlockPile {
	private:
		vector<Ticket*> copylist;
		vector<Ticket*> patchlist;
	public:
		BlockPile(): copylist(), patchlist() { }

		~BlockPile() {
			for(vector<Ticket*>::const_iterator it = copylist.begin(); it != copylist.end(); ++it)
				delete (*it);

			for(vector<Ticket*>::const_iterator it = patchlist.begin(); it != patchlist.end(); ++it)
				delete (*it);
		}

		void apply(void *dest) const {
			for(vector<Ticket*>::const_iterator it = copylist.begin(); it != copylist.end(); ++it) {
				//cout << (*it)->description() << endl;
				(*it)->apply(dest);
			}

			for(vector<Ticket*>::const_iterator it = patchlist.begin(); it != patchlist.end(); ++it) {
				//cout << (*it)->description() << endl;
				(*it)->apply(dest);
			}
		}

		void addCopy(size_t len, void *source, size_t offset) {
			copylist.push_back(new CopyTicket(len, source, offset));
		}

		void addPatch(uint32_t data, off_t offset) {
			patchlist.push_back(new PatchTicket(data, offset));
		}

};

void makeDirectoryTree(string path) {
	string elem;
	string cur;
	stringstream ss(path);
	while(getline(ss, elem, '/')) {
		cur = cur + elem;
		if(ss.tellg() == path.length()) break;
		mkdir(cur.c_str(), 0755);
		cur += "/";
	}
}

string lastPathComponent(string path) {
	string elem;
	string cur;
	stringstream ss(path);
	while(getline(ss, elem, '/')) {
		if(ss.tellg() == path.length()) break;
	}
	return elem;
}

const char *removeCommonPathElements(string p1, string p2) {
	int i = 0;
	string pe1, pe2;
	stringstream ss1(p1), ss2(p2);
	while(pe1 == pe2) {
		getline(ss1, pe1, '/');
		getline(ss2, pe2, '/');
	}
	// Black magic to rewind the stream to put path elements back!
	// We add an extra two characters if we're not at the end, to capture the / (make the link an absolute reference)
	int c = pe1.length();
	if(ss1.tellg() == p1.length()) {
		ss1.seekg(-1*c, ios_base::cur);
	} else {
		ss1.seekg(-1*(c+2), ios_base::cur);
	}
	return p1.substr(ss1.tellg()).c_str();
}

#define NZ_OFFSET(x) if(x > 0) b.addPatch(x - linkedit_offset, (uint64_t)&x - (uint64_t)data)
class Library {
	public:
	uint64_t loadaddr;
	string primary_filename;
	string prettyname;
	vector<string> filenames;

	Library(uint64_t la) : filenames() {
		loadaddr = la;
	}

	void addFilename(const char *filename) {
		string s(filename);
		s = "out" + s;
		if(primary_filename == "") {
			primary_filename = s;
			prettyname = lastPathComponent(s);
		}
		else filenames.push_back(s);
	}

	void makeOutputFolders() {
		//printf("Dumping library at %llx to %s.\n", loadaddr, primary_filename.c_str());
		makeDirectoryTree(primary_filename);
		vector<string>::iterator i = filenames.begin();
		while(i != filenames.end()) {
			//printf(" Symlinking %s.\n", i->c_str());
			makeDirectoryTree(*i);
			symlink(removeCommonPathElements(primary_filename, *i), i->c_str());
			i++;
		}
	}

	void dump() {
		off_t startaddr = loadaddr - *(uint64_t *)&_cacheData[_cacheHead->baseaddroff];
		// If there's a library >64mb, shoot me.
		//void *data = (void *)calloc(1, 67108864);
		//memcpy(data, _cacheData + startaddr, len);
		void *data = (void *)(_cacheData + startaddr);
		struct mach_header *mh = (struct mach_header *)data;
		uint8_t *cmdptr;
		if(mh->magic == MH_MAGIC) {
			BlockPile b;
			cmdptr = (uint8_t *)data + sizeof(struct mach_header);
			//printf("Mach-O at %llx, CPU %d, Type %d, ncmds %d, sizeofcmds %d, flags %x.\n", startaddr, mh->cputype, mh->filetype, mh->ncmds, mh->sizeofcmds, mh->flags);
			printf("%32.32s: ", prettyname.c_str());
			int cmd = 0;
			int segments_seen = 0;
			size_t filelen = 0;
			int linkedit_offset = 0;
			for(cmd = 0; cmd < mh->ncmds; cmd++) {
				struct load_command *lc = (struct load_command *)cmdptr;
				cmdptr += lc->cmdsize;
				switch(lc->cmd) {
					case LC_SEGMENT:
					{
						segments_seen++;
						struct segment_command *seg = (struct segment_command *)lc;
						if(segments_seen == 1) {
							filelen = seg->filesize;
							b.addCopy(seg->filesize, data, seg->fileoff);
						} else {
							b.addCopy(seg->filesize, _cacheData + seg->fileoff, filelen);
							b.addPatch(filelen, (uint64_t)&seg->fileoff - (uint64_t)data);
							int newoff = filelen;
							filelen += seg->filesize;
							putchar('s');
							int oldoff = seg->fileoff;
							int sect_offset = seg->fileoff - newoff;
							if(!strcmp(seg->segname, "__LINKEDIT")) {
								linkedit_offset = sect_offset;
							}
							if(seg->nsects > 0) {
								int nsect = 0;
								struct section *sects = (struct section *)((uint8_t *)seg + sizeof(struct segment_command));
								for(nsect = 0; nsect < seg->nsects; nsect++) {
									if(sects[nsect].offset > filelen) {
										b.addPatch(sects[nsect].offset - sect_offset, (uint64_t)&sects[nsect].offset - (uint64_t)data);
										putchar('+');
									}
								}
							}
						}
						break;
					}

					case LC_SYMTAB:
					{
						struct symtab_command *st = (struct symtab_command *)lc;
						putchar('S');
						NZ_OFFSET(st->symoff);
						NZ_OFFSET(st->stroff);
						break;
					}
						
					case LC_DYSYMTAB:
					{
						struct dysymtab_command *st = (struct dysymtab_command *)lc;
						putchar('D');
						NZ_OFFSET(st->tocoff);
						NZ_OFFSET(st->modtaboff);
						NZ_OFFSET(st->extrefsymoff);
						NZ_OFFSET(st->indirectsymoff);
						NZ_OFFSET(st->extreloff);
						NZ_OFFSET(st->locreloff);
						break;
					}

					case LC_DYLD_INFO_ONLY:
					{
						struct dyld_info_only_32 *st = (struct dyld_info_only_32 *)lc;
						putchar('I');
						NZ_OFFSET(st->rebase_off);
						NZ_OFFSET(st->bind_off);
						NZ_OFFSET(st->weak_bind_off);
						NZ_OFFSET(st->lazy_bind_off);
						NZ_OFFSET(st->export_off);
						break;
					}
				}
			}
			int outfd = open(primary_filename.c_str(), O_CREAT|O_TRUNC|O_RDWR, 0755);
			lseek(outfd, filelen - 1, SEEK_SET);
			write(outfd, "", 1);
			void *outdata = mmap(NULL, filelen, PROT_READ | PROT_WRITE, MAP_SHARED, outfd, 0);
			b.apply(outdata);
			munmap(outdata, filelen);
			close(outfd);
			putchar('\n');
		}
	}
};

int main(int argc, char **argv) {
	if(argc < 2) {
		fprintf(stderr, "Syntax: %s cachefile\n", argv[0]);
		return 1;
	}

	char *filename = argv[1];
	struct stat statbuf;
	int stat_ret = stat(filename, &statbuf);

	if(stat_ret == -1) {
		fprintf(stderr, "Error accessing %s.\n", filename);
		return -1;
	}

	unsigned long long filesize = statbuf.st_size;
//	filesize = filesize + 1048576 - (filesize % 1048576);
	int fd = open(filename, O_RDONLY);
	_cacheData = (uint8_t *)mmap(NULL, filesize, PROT_READ, MAP_PRIVATE, fd, 0);

	map<unsigned long long, Library*> libs;
	_cacheHead = (struct cache_header *)_cacheData;
	printf("Loaded cache with versionspec \"%s\" and %d libraries...\n", _cacheHead->version, _cacheHead->numlibs);

	printf("Library table starts at %08llx.\n", _cacheHead->startaddr);
	printf("dyld @ %08llx.\n", _cacheHead->dyldaddr);
	printf("Library base load address: %08llx.\n", *(uint64_t *)&_cacheData[_cacheHead->baseaddroff]);
	//munmap(_cacheData, filesize);
//	close(fd);
//	return 0;

	int l = 0;
	uint64_t curoffset = _cacheHead->startaddr;
	for(l = 0; l < _cacheHead->numlibs; l++) {
		uint64_t la, fo;
		la = *(uint64_t *)(_cacheData + curoffset);
		fo = *(uint64_t *)(_cacheData + curoffset + 24);
		curoffset += 32;
		if(libs.count(la) == 0) {
			//printf("%8llx...\n", la);
			Library *lib = new Library(la);
			lib->addFilename((const char *)_cacheData + fo);
			libs[la] = lib;
		} else {
			//printf("%8llx+++\n", la);
			Library *lib = libs[la];
			lib->addFilename((const char *)_cacheData + fo);
		}
		continue;
	}

	map<unsigned long long, Library *>::iterator i = libs.begin();
	while(i != libs.end()) {
		Library *lib = i->second;
		//if(lib->primary_filename != "out/System/Library/Frameworks/UIKit.framework/UIKit" &&
			//lib->primary_filename != "out/System/Library/PrivateFrameworks/Preferences.framework/Preferences") { i++; continue; }
		lib->makeOutputFolders();
		lib->dump();
		i++;
	}
	munmap(_cacheData, filesize);
	close(fd);
}
