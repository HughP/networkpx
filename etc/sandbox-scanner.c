/*

sandbox-scanner.c ... Checks which part of file system is unreadable.
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

#include <stdio.h>
#include <sandbox.h>
#include <dirent.h>
#include <string.h>
#include <fcntl.h>
#include <sys/stat.h>

void scan_dir(char path[4096], size_t dl, int wrtest) {
	DIR* d = opendir(path);
	if (d != NULL) {
		if (wrtest) {
			path[dl] = '^';
			path[dl+1] = '\0';
			if (!mkfifo(path, 0644)) {
				unlink(path);
				printf("WRITE: %s\n", path);
			}
		}
		
		struct dirent* f;
		while ((f = readdir(d)) != NULL) {
			if (strcmp(f->d_name, ".") == 0 || strcmp(f->d_name, "..") == 0)
				continue;
			size_t namelen = strlen(f->d_name);
			memcpy(path+dl, f->d_name, namelen);
			if (f->d_type == DT_DIR) {
				path[dl+namelen] = '/';
				path[dl+namelen+1] = '\0';
				scan_dir(path, dl+namelen+1, wrtest);
			} else if (f->d_type == DT_REG) {
				path[dl+namelen] = '\0';
				int fd = open(path, O_RDONLY|O_NONBLOCK|O_NOFOLLOW|O_EVTONLY);
				if (fd >= 0)
					close(fd);
				else
					printf("~READ:  %s\n", path);
			}
		}
		path[dl] = '\0';
		closedir(d);
	} else {
		printf("~RDDR: %s\n", path);
	}

}

int main (int argc, const char* argv[]) {
	if (argc < 2) {
		printf("Usage: sandbox-scanner <profile>\n\n");
	} else {
		char* errstr = NULL;
		if (sandbox_init(argv[1], SANDBOX_NAMED, &errstr)) {
			printf("sandbox_init failed: %s", errstr);
			sandbox_free_error(errstr);
		}
		
		char path[4096];
		path[0] = '/';
		path[1] = '\0';
		int wrtest = argc >= 3;
		scan_dir(path, 1, wrtest);
	}
}