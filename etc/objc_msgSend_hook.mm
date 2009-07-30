#import <objc/message.h>
#import "objc_type.h"	// part of class-dump-z.

// Use substrate.h on iPhoneOS, and APELite on x86/ppc for debugging.
#ifdef __arm__
#import <substrate.h>
#elif __i386__ || __ppc__
extern "C" void* APEPatchCreate(const void* original, const void* replacement);
#define MSHookFunction(original, replacement, result) (*(void**)(result) = APEPatchCreate((const void*)(original), (const void*)(replacement)))
#else
#error Not supported in non-ARM/i386/PPC system.
#endif

static bool is_hooking = true;
static IMP old_objc_msgSend = nil;
static ObjCTypeRecord record;

void print_id(FILE* f, void* x) {
	if (x == NULL)
		fprintf(f, "nil");
	else if (CFGetTypeID(x) == CFStringGetTypeID()) {
		CFIndex len = CFStringGetLength( reinterpret_cast<CFStringRef>(x) );
		char* buff = new char[len*3+1];
		CFStringGetCString(reinterpret_cast<CFStringRef>(x), buff, len*3+1, kCFStringEncodingUTF8);
		fprintf(f, "@\"%.*s\"", len, buff);
		delete[] buff;
	} else
		fprintf(f, "<%s %p>", object_getClassName(reinterpret_cast<id>(x)), x);
}

static id replaced_objc_msgSend(id self, SEL _cmd, ...) {
	bool old_is_hooking = is_hooking;
	if (old_is_hooking) {
		is_hooking = false;
		Class cls = object_getClass(self);
		Method m = class_getInstanceMethod(cls, _cmd);
		unsigned argcount = method_getNumberOfArguments(m);
		printf("%c[%s %s] <%p> (", class_isMetaClass(cls)?'+':'-', class_getName(cls), _cmd, self);
		va_list va;
		va_start(va, _cmd);
		for (unsigned i = 2; i < argcount; ++ i) {
			if (i != 2)
				printf(", ");
			char* argType = method_copyArgumentType(m, i);
			
			ObjCTypeRecord::TypeIndex ti = record.parse(argType, false);
			record.print_arguments(ti, va, print_id);
			free(argType);
		}
		printf(")");
		va_end(va);
	}
	void* args = __builtin_apply_args();
	void* ret = __builtin_apply(reinterpret_cast<void(*)(...)>(old_objc_msgSend), args, 1024);
	if (old_is_hooking) {
		if (_cmd != @selector(release) && _cmd != @selector(dealloc) && _cmd != @selector(autorelease)) {
			Class cls = object_getClass(self);
			Method m = class_getInstanceMethod(cls, _cmd);
			char* retType = method_copyReturnType(m);
			if (retType != NULL) {
				ObjCTypeRecord::TypeIndex ti = record.parse(retType, false);
				if (!record.is_void_type(ti)) {
					printf(" -> ");
					const char* va = reinterpret_cast<const char*> (ret);
					record.print_args(ti, va, print_id);
				}
			}
			free(retType);
		}
		printf("\n");
	}
	is_hooking = old_is_hooking;
	__builtin_return(ret);
}
extern "C" void set_hook(bool h) {
	is_hooking = h;
}

int main () {
	MSHookFunction(objc_msgSend, replaced_objc_msgSend, &old_objc_msgSend);
}
