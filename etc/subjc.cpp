#include <substrate2.h>
#include <cstdio>
#include "objc_type.h"	// from class-dump-z
#include <stack>
#include <CoreFoundation/CoreFoundation.h>
#include <cstdarg>
#include <tr1/unordered_set>

namespace {
#define USED __attribute__((used)) 
#if __i386__
#define FASTCALL __attribute__((regparm(3)))
#else
#define FASTCALL
#endif
	
	static IMP original_objc_msgSend __asm__("_original_objc_msgSend") = NULL;
	static void* original_objc_msgSend_stret __asm__("_original_objc_msgSend_stret") = NULL;
	static void* original_objc_msgSend_fpret __asm__("_original_objc_msgSend_fpret") = NULL;
	
	static int enabled __asm__("_enabled");
	static USED int rx_reserve[6] __asm__("_rx_reserve");	// r0, r1, r2, r3, lr, saved.
	
	static ObjCTypeRecord record;
	
	static void fprint_spaces (std::FILE* f, size_t n) {
		static char spaces[] = "                ";
		for (size_t i = 0; i < n/16; ++ i)
			std::fprintf(f, spaces);
		std::fprintf(f, spaces+(16-n%16));
	}
	
	static std::stack<int> lr_list;
	static std::stack<ObjCTypeRecord::TypeIndex> ret_types;
	static std::stack<id> selfs;
	
	extern "C" USED FASTCALL void push_lr (int lr) { lr_list.push(lr); }
	extern "C" USED int pop_lr () { int retval = lr_list.top(); lr_list.pop(); return retval; }
	
	static int enabled_temporary;
	inline void disable_temporary () { enabled_temporary = enabled; enabled = 0; }
	inline void restore_temporary () { enabled = enabled_temporary; }
	
	enum FilterType { NoFilter, WhiteList, BlackList };
	FilterType filter_type = NoFilter, class_filter_type = NoFilter;
	static std::tr1::unordered_set<SEL> filter_set;
	static std::tr1::unordered_set<Class> class_filter_set;

	static void print_id(std::FILE* f, void* x) {
		if (x == NULL) {
			std::fprintf(f, "nil");
		} else { 
			CFTypeID type = CFGetTypeID(x);
			
			if (type == CFStringGetTypeID()) {
				CFStringEncoding enc = CFStringGetFastestEncoding( reinterpret_cast<CFStringRef>(x) );
				const char* ptr = CFStringGetCStringPtr( reinterpret_cast<CFStringRef>(x), enc );
				if (ptr != NULL) {
					std::fprintf(f, "@\"%s\"", ptr);
					return;
				}
				
				CFDataRef data = CFStringCreateExternalRepresentation(NULL, reinterpret_cast<CFStringRef>(x), kCFStringEncodingUTF8, '?');
				if (data != NULL) {
					std::fprintf(f, "@\"%.*s\"", static_cast<int>(CFDataGetLength(data)), CFDataGetBytePtr(data));
					CFRelease(data);
					return;
				}
			} else if (type == CFBooleanGetTypeID()) {
				std::fprintf(f, "kCFBoolean%s", x == kCFBooleanTrue ? "True" : "False");
				return;
			} else if (type == CFNullGetTypeID()) {
				std::fprintf(f, "kCFNull");
				return;
			} else if (type == CFNumberGetTypeID()) {
				CFNumberType numType = CFNumberGetType(reinterpret_cast<CFNumberRef>(x));
				static const char* const numTypeStrings[] = {
					NULL, "SInt8", "SInt16", "SInt32", "SInt64", "Float32", "Float64",
					"char", "short", "int", "long", "long long", "float", "double",
					"CFIndex", "NSInteger", "CGFloat"
				};
				
				switch (numType) {
					case kCFNumberSInt8Type:
					case kCFNumberSInt16Type:
					case kCFNumberSInt32Type:
					case kCFNumberCharType:
					case kCFNumberShortType:
					case kCFNumberIntType:
					case kCFNumberLongType:
					case kCFNumberCFIndexType:
					case kCFNumberNSIntegerType: {
						long res;
						CFNumberGetValue(reinterpret_cast<CFNumberRef>(x), kCFNumberLongType, &res);
						std::fprintf(f, "<CFNumber (%s)%ld>", numTypeStrings[numType], res);
						break;
					}
					case kCFNumberSInt64Type:
					case kCFNumberLongLongType: {
						long long res;
						CFNumberGetValue(reinterpret_cast<CFNumberRef>(x), kCFNumberLongLongType, &res);
						std::fprintf(f, "<CFNumber (%s)%lld>", numTypeStrings[numType], res);
						break;
					}	
					default: {
						double res;
						CFNumberGetValue(reinterpret_cast<CFNumberRef>(x), kCFNumberDoubleType, &res);
						std::fprintf(f, "<CFNumber (%s)%lg>", numTypeStrings[numType], res);
						break;
					}
				}
				return;
			}
			
			std::fprintf(f, "<%s %p>", object_getClassName(reinterpret_cast<id>(x)), x);
		}
	}
	
	static std::FILE* log_fh;
	
	static bool last_action_is_push;
	static SEL class_sel, alloc_sel, allocWithZone_sel;
	static size_t cur_depth, max_depth;
	static bool do_print_args, do_print_rv;
	static int print_args_v (id self, SEL _cmd, std::va_list va) {
		disable_temporary();
		
		bool do_print_open_brace = last_action_is_push && do_print_rv;
		last_action_is_push = true;
		
		if (cur_depth++ > max_depth)
			return 0;
		
		if (filter_type != NoFilter) {
			bool found_in_set = filter_set.find(_cmd) != filter_set.end();
			if ((filter_type == BlackList) == found_in_set)
				return 0;
		}
		
		// We need to msgSend because if the class isn't initialized, those class_getXXXMethod will crash.
		Class c = reinterpret_cast<Class>(original_objc_msgSend(self, class_sel));
		
		if (class_filter_type != NoFilter) {
			bool found_in_set = class_filter_set.find(c) != class_filter_set.end();
			if ((class_filter_type == BlackList) == found_in_set)
				return 0;
		}
		
		if (do_print_open_brace)
			std::fprintf(log_fh, " {");

		std::fputc('\n', log_fh);
		fprint_spaces(log_fh, cur_depth-1);
		
		bool is_class_method = reinterpret_cast<id>(c) == self;
		std::fprintf(log_fh, "%c[%s %s]", is_class_method?'+':'-', class_getName(c), sel_getName(_cmd));
		if (!is_class_method)
			std::fprintf(log_fh, " <%p>", self);
			
		Method m = (is_class_method ? class_getClassMethod : class_getInstanceMethod)(c, _cmd);
			
		if (do_print_args && m != NULL) {
			unsigned arg_count = method_getNumberOfArguments(m);
			
			if (arg_count > 2) {
				std::fprintf(log_fh, " (");
				
				for (unsigned i = 2; i < arg_count; ++ i) {
					if (i != 2)
						fprintf(log_fh, ", ");
					char* arg_type = method_copyArgumentType(m, i);
					ObjCTypeRecord::TypeIndex ti = record.parse(arg_type, false);
					record.print_arguments(ti, va, print_id, log_fh);
					free(arg_type);
				}
				std::fputc(')', log_fh);
			}
		}
		
		if (do_print_rv) {
			if (m == NULL || _cmd == alloc_sel || _cmd == allocWithZone_sel) {
				ret_types.push(record.void_type());
			} else {
				char* ret_type = method_copyReturnType(m);
				ObjCTypeRecord::TypeIndex ti = record.parse(ret_type, false);
				ret_types.push(ti);
				free(ret_type);
			}
			
			selfs.push(self);
		}
		
		restore_temporary();
		
		return 1;
	}
	
	extern "C" USED int print_args(id self, SEL _cmd, ...) {
		std::va_list va;
		va_start(va, _cmd);
		int ret = print_args_v(self, _cmd, va);
		va_end(va);
		return ret;
	}
	
	extern "C" USED int print_args_stret(void* retval, id self, SEL _cmd, ...) {
		std::va_list va;
		va_start(va, _cmd);
		int ret = print_args_v(self, _cmd, va);
		va_end(va);
		return ret;
	}
	
	extern "C" USED FASTCALL void show_retval (const char* addr, int not_filtered) {
		--cur_depth;
		
		if (not_filtered) {
			if (!do_print_rv || cur_depth > max_depth)
				return;
			
			disable_temporary();
			if (!last_action_is_push) {
				std::fputc('\n', log_fh);
				fprint_spaces(log_fh, cur_depth);
				std::fputc('}', log_fh);
			}
			
			ObjCTypeRecord::TypeIndex ti = ret_types.top();
			ret_types.pop();
			id self = selfs.top();
			selfs.pop();
			
			if (!record.can_reduce_to_type(ti, record.void_type())) {
				std::fprintf(log_fh, " = ");
				if (record.is_id_type(ti) && *reinterpret_cast<const id*>(addr) == self)
					std::fprintf(log_fh, "self");
				else
					record.print_args(ti, addr, print_id, log_fh);
				std::fputc(';', log_fh);
			}
			last_action_is_push = false;
		}
		
		restore_temporary();
	}
	
	USED static void replaced_objc_msgSend() __asm__("_replaced_objc_msgSend");
	USED static void replaced_objc_msgSend_stret() __asm__("_replaced_objc_msgSend_stret");
	USED static void replaced_objc_msgSend_fpret() __asm__("_replaced_objc_msgSend_fpret");
	
#if __arm__
	__asm__(".text\n"
			"_replaced_objc_msgSend:\n"
			
			// 0. Check if the hook is enabled. If not, quit now.	
			"ldr r12, (LEna0)\n"
"LoadEna0:"	"ldr r12, [pc, r12]\n"
			"teq r12, #0\n"
			"ldreq r12, (LOrig0)\n"
"LoadOrig0:""ldreq pc, [pc, r12]\n"
			
			// 1. Save the registers.
			"ldr r12, (LSR1)\n"
"LoadSR1:"	"add r12, pc, r12\n"
			"stmia r12, {r0-r3, lr}\n"
				
			// 2. Print the arguments.
			"bl _print_args\n"
			"ldr r1, (LSRX)\n"
			"ldr r2, (LSR2)\n"
"LoadSRX:"	"str r0, [pc, r1]\n"
				
			// 3. Push lr onto our custom stack.
"LoadSR2:"	"ldr r0, [pc, r2]\n"
			"bl _push_lr\n"
			
			// 4. Restore the registers.
			"ldr r1, (LSR3)\n"
"LoadSR3:"	"add r2, pc, r1\n"
			"ldmia r2, {r0-r3}\n"
				
			// 5. Call original objc_msgSend
			"ldr r12, (LOrig1)\n"
"LoadOrig1:""ldr r12, [pc, r12]\n"
			"blx r12\n"

			// 6. Print return value.
			"ldr r12, (LSRY)\n"
			"push {r0-r3}\n"	// assume no intrinsic type takes >128 bits...
"LoadSRY:"	"ldr r1, [pc, r12]\n"
			"mov r0, sp\n"
			"bl _show_retval\n"
			"bl _pop_lr\n"
			"mov lr, r0\n"
			"pop {r0-r3}\n"
			"bx lr\n"
				
"LEna0:		.long _enabled - 8 - (LoadEna0)\n"
"LOrig0:	.long _original_objc_msgSend - 8 - (LoadOrig0)\n"
"LSR1:		.long _rx_reserve - 8 - (LoadSR1)\n"
"LSRX:		.long _rx_reserve - 8 - (LoadSRX) + 20\n"
"LSR2:		.long _rx_reserve - 8 - (LoadSR2) + 16\n"
"LSR3:		.long _rx_reserve - 8 - (LoadSR3)\n"
"LSRY:		.long _rx_reserve - 8 - (LoadSRY) + 20\n"
"LOrig1:	.long _original_objc_msgSend - 8 - (LoadOrig1)\n");
	
	__asm__(".text\n"
			"_replaced_objc_msgSend_stret:"
			
			// 0. Check if the hook is enabled. If not, quit now.
			"ldr r12, (LES0)\n"
"LoadES0:"	"ldr r12, [pc, r12]\n"
			"teq r12, #0\n"
			"ldreq r12, (LOS0)\n"
"LoadOS0:"	"ldreq pc, [pc, r12]\n"
			
			// 1. Save the registers.
			"ldr r12, (LSS1)\n"
"LoadSS1:"	"add r12, pc, r12\n"
			"stmia r12, {r0-r3, lr}\n"
			
			// 2. Print the arguments.
			"bl _print_args_stret\n"
			"ldr r1, (LSSX)\n"
			"ldr r2, (LSS2)\n"
"LoadSSX:"	"str r0, [pc, r1]\n"
			
			// 3. Push lr onto our custom stack.
"LoadSS2:"	"ldr r0, [pc, r2]\n"
			"bl _push_lr\n"
			
			// 4. Restore the registers.
			"ldr r1, (LSS3)\n"
"LoadSS3:"	"add r2, pc, r1\n"
			"ldmia r2, {r0-r3}\n"
			
			// 5. Call original objc_msgSend_stret
			"ldr r12, (LOS1)\n"
"LoadOS1:"	"ldr r12, [pc, r12]\n"
			"blx r12\n"
			
			// 6. Print return value.
			"ldr r2, (LSSY)\n"
			"str r0, [sp, #-4]!\n"
"LoadSSY:"	"ldr r1, [pc, r2]\n"
			"bl _show_retval\n"
			"bl _pop_lr\n"
			"mov lr, r0\n"
			"ldr r0, [sp], #4\n"
			"bx lr\n"				
			
"LES0:		.long _enabled - 8 - (LoadES0)\n"
"LOS0:		.long _original_objc_msgSend_stret - 8 - (LoadOS0)\n"
"LSS1:		.long _rx_reserve - 8 - (LoadSS1)\n"
"LSSX:		.long _rx_reserve - 8 - (LoadSSX) + 20\n"
"LSS2:		.long _rx_reserve - 8 - (LoadSS2) + 16\n"
"LSS3:		.long _rx_reserve - 8 - (LoadSS3)\n"
"LSSY:		.long _rx_reserve - 8 - (LoadSSY) + 20\n"
"LOS1:		.long _original_objc_msgSend_stret - 8 - (LoadOS1)\n");
	


#elif __i386__
	
	extern "C" USED void show_float_retval (int not_filtered) {
		--cur_depth;
		
		if (not_filtered) {
			if (!do_print_rv || cur_depth > max_depth)
				return;
			
			if (!last_action_is_push) {
				std::fputc('\n', log_fh);
				fprint_spaces(log_fh, cur_depth);
				std::fputc('}', log_fh);
			}
			
			double x;
			__asm__ ("fstl %0" : "=m"(x));
			std::fprintf(log_fh, " = %.15lg", x);
			
			last_action_is_push = false;
		}
	}
	
	__asm__(".text\n"
			"_replaced_objc_msgSend:\n"
			
			"call LR0\n"
"LR0:"		"popl %ecx\n"
			
			// 0. Check if the hook is enabled. If not, quit now.	
			"movl _enabled-LR0(%ecx), %eax\n"
			"test %eax, %eax\n"
			"jne LRCont\n"
			"movl _original_objc_msgSend-LR0(%ecx), %eax\n"
			"jmp *%eax\n"
			
			// 1. Push lr onto our custom stack.
"LRCont:"	"popl %eax\n"
			"call _push_lr\n"
	
			// 1. Print the arguments.
			"call _print_args\n"
			"call LR1\n"
"LR1:"		"popl %ecx\n"
			"movl %eax, _rx_reserve-LR1(%ecx)\n"
			
			// 2. Call original objc_msgSend.
			"movl _original_objc_msgSend-LR1(%ecx), %eax\n"
			"call *%eax\n"
			
			// 3. Print return value.
			"call LR2\n"
"LR2:"		"popl %ecx\n"
			"movl %eax, _rx_reserve+4-LR2(%ecx)\n"
			"movl %edx, _rx_reserve+8-LR2(%ecx)\n"
			"leal _rx_reserve+4-LR2(%ecx), %eax\n"
			"movl _rx_reserve-LR2(%ecx), %ecx\n"
			"call _show_retval\n"
			"call _pop_lr\n"
			"pushl %eax\n"
			"call LR3\n"
"LR3:"		"popl %ecx\n"
			"movl _rx_reserve+4-LR3(%ecx), %eax\n"
			"movl _rx_reserve+8-LR3(%ecx), %edx\n"
			"ret\n");
	
	__asm__(".text\n"
			"_replaced_objc_msgSend_stret:\n"
			
			"call LS0\n"
"LS0:"		"popl %ecx\n"
			
			// 0. Check if the hook is enabled. If not, quit now.	
			"movl _enabled-LS0(%ecx), %eax\n"
			"test %eax, %eax\n"
			"jne LSCont\n"
			"movl _original_objc_msgSend-LS0(%ecx), %eax\n"
			"jmp *%eax\n"
			
			// 1. Push lr onto our custom stack.
"LSCont:"	"popl %eax\n"
			"call _push_lr\n"
			
			// 1. Print the arguments.
			"call _print_args_stret\n"
			"call LS1\n"
"LS1:"		"popl %ecx\n"
			"movl %eax, _rx_reserve-LS1(%ecx)\n"
			
			// 2. Call original objc_msgSend.
			"movl _original_objc_msgSend_stret-LS1(%ecx), %eax\n"
			"call *%eax\n"
			
			// 3. Print return value.
			"call LS2\n"
"LS2:"		"popl %ecx\n"
			"movl _rx_reserve-LS2(%ecx), %edx\n"
			"call _show_retval\n"
			"call _pop_lr\n"
			"pushl %eax\n"
			"ret\n");
	
	__asm__(".text\n"
			"_replaced_objc_msgSend_fpret:\n"
			
			"call LF0\n"
"LF0:"		"popl %ecx\n"
			
			// 0. Check if the hook is enabled. If not, quit now.	
			"movl _enabled-LF0(%ecx), %eax\n"
			"test %eax, %eax\n"
			"jne LFCont\n"
			"movl _original_objc_msgSend_fpret-LF0(%ecx), %eax\n"
			"jmp *%eax\n"
			
			// 1. Push lr onto our custom stack.
"LFCont:"	"popl %eax\n"
			"call _push_lr\n"
			
			// 1. Print the arguments.
			"call _print_args\n"
			"call LF1\n"
"LF1:"		"popl %ecx\n"
			"movl %eax, _rx_reserve-LF1(%ecx)\n"
			
			// 2. Call original objc_msgSend.
			"movl _original_objc_msgSend_fpret-LF1(%ecx), %eax\n"
			"call *%eax\n"
			
			// 3. Print return value.
			"call LF2\n"
"LF2:"		"popl %ecx\n"
			"movl _rx_reserve-LF2(%ecx), %eax\n"
			"call _show_float_retval\n"
			"call _pop_lr\n"
			"pushl %eax\n"
			"ret\n");
	
#else
#error Not available in non-ARM or non-x86 platforms.
#endif
	
	template <typename T>
	void clear_stl (T& x) {
		T c;
		std::swap(x, c);
	}
}

extern "C" void SubjC_initialize () {
	enabled = 0;
	class_sel = sel_registerName("class");
	alloc_sel = sel_registerName("alloc");
	allocWithZone_sel = sel_registerName("allocWithZone:");
	
	MSHookFunction(reinterpret_cast<void*>(objc_msgSend),
				   reinterpret_cast<void*>(replaced_objc_msgSend),
				   reinterpret_cast<void**>(&original_objc_msgSend));
	MSHookFunction(reinterpret_cast<void*>(objc_msgSend_stret),
				   reinterpret_cast<void*>(replaced_objc_msgSend_stret),
				   &original_objc_msgSend_stret);
#if __i386__
	MSHookFunction(reinterpret_cast<void*>(objc_msgSend_fpret),
				   reinterpret_cast<void*>(replaced_objc_msgSend_fpret),
				   &original_objc_msgSend_fpret);
#endif
	
}

extern "C" void SubjC_clear_selector_filter() { filter_type = NoFilter; }
extern "C" void SubjC_clear_class_filter() { class_filter_type = NoFilter; }

namespace {
	template <typename T>
	inline void xlist_what(FilterType& target_filter, FilterType filter, std::tr1::unordered_set<T>& target, size_t count, T objs[]) {
		target_filter = filter;
		std::tr1::unordered_set<T> xset (objs, objs+count);
		std::swap(target, xset);
	}
}

extern "C" void SubjC_blacklist_selectors(size_t count, SEL selectors[]) { xlist_what(filter_type, BlackList, filter_set, count, selectors); }
extern "C" void SubjC_blacklist_classes(size_t count, Class classes[]) { xlist_what(class_filter_type, BlackList, class_filter_set, count, classes); }
extern "C" void SubjC_whitelist_selectors(size_t count, SEL selectors[]) { xlist_what(filter_type, WhiteList, filter_set, count, selectors); }
extern "C" void SubjC_whitelist_classes(size_t count, Class classes[]) { xlist_what(class_filter_type, WhiteList, class_filter_set, count, classes); }

extern "C" void SubjC_start(std::FILE* f, size_t maximum_depth, bool print_arguments, bool print_return_value) {
	if (!original_objc_msgSend)
		SubjC_initialize();
	
	last_action_is_push = false;
	cur_depth = 0;
	max_depth = maximum_depth;
	do_print_args = print_arguments;
	do_print_rv = print_return_value;
	clear_stl(lr_list);
	clear_stl(ret_types);
	clear_stl(selfs);
	log_fh = f;
	enabled = 1;
}

extern "C" void SubjC_end() {
	enabled = 0;
	std::fputc('\n', log_fh);
}
