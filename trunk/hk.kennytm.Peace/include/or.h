#ifndef OR_H
#define OR_H
#if __GNUC__
#define OR(x, y) (x) ?: (y)
#else
#define OR(x, y) (x) ? (x) : (y)
#endif
#endif
