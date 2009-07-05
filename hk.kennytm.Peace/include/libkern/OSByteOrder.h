#ifndef OSBYTEORDER_H
#define OSBYTEORDER_H

static inline unsigned OSSwapBigToHostInt32(unsigned x) {
	return (x & 0xFF) << 24 | (x & 0xFF00) << 8 | (x & 0xFF0000) >> 8 | (x & 0xFF000000) >> 24;
}

#endif
