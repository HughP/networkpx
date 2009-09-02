#include <substrate.h>
#include <cstdio>
#include "objc_type.h"	// from class-dump-z
#include <stack>
#include <CoreFoundation/CoreFoundation.h>
#include <cstdarg>
#include <tr1/unordered_set>

namespace {
#define USED __attribute__((used)) 
	static IMP original_objc_msgSend __asm__("_original_objc_msgSend") = NULL;
	static int enabled __asm__("_enabled");
	static USED int rx_reserve[6] __asm__("_rx_reserve");	// r0, r1, r2, r3, lr, saved.
	
	static ObjCTypeRecord record;
	
	void fprint_spaces (std::FILE* f, size_t n) {
		static char spaces[] = "                ";
		for (size_t i = 0; i < n/16; ++ i)
			std::fprintf(f, spaces);
		std::fprintf(f, spaces+(16-n%16));
	}
	
	static std::stack<int> lr_list;
	static std::stack<ObjCTypeRecord::TypeIndex> ret_types;
	static std::stack<id> selfs;
	
	extern "C" USED void push_lr (int lr) { lr_list.push(lr); }
	extern "C" USED int pop_lr () { int retval = lr_list.top(); lr_list.pop(); return retval; }
	
	static int enabled_temporary;
	extern "C" void disable_temporary () { enabled_temporary = enabled; enabled = 0; }
	inline void restore_temporary () { enabled = enabled_temporary; }
	
	static enum { NoFilter, WhiteList, BlackList } filter_type;
	static std::tr1::unordered_set<SEL> filter_set;

	void print_id(std::FILE* f, void* x) {
		if (x == NULL) {
			fprintf(f, "nil");
		} else { 
			CFTypeID type = CFGetTypeID(x);
			
			if (type == CFStringGetTypeID()) {
				CFStringEncoding enc = CFStringGetFastestEncoding( reinterpret_cast<CFStringRef>(x) );
				const char* ptr = CFStringGetCStringPtr( reinterpret_cast<CFStringRef>(x), enc );
				if (ptr != NULL) {
					fprintf(f, "@\"%s\"", ptr);
					return;
				}
				
				CFDataRef data = CFStringCreateExternalRepresentation(NULL, reinterpret_cast<CFStringRef>(x), kCFStringEncodingUTF8, '?');
				if (data != NULL) {
					fprintf(f, "@\"%.*s\"", static_cast<int>(CFDataGetLength(data)), CFDataGetBytePtr(data));
					CFRelease(data);
					return;
				}
			} 
			fprintf(f, "<%s %p>", object_getClassName(reinterpret_cast<id>(x)), x);
		}
	}
	
	static std::FILE* log_fh;
	
	static bool last_action_is_push;
	static SEL class_sel, alloc_sel, allocWithZone_sel;
	static size_t cur_depth, max_depth;
	static bool do_print_args, do_print_rv;
	extern "C" USED int print_args (id self, SEL _cmd, ...) {
		if (cur_depth++ > max_depth)
			return 0;
		last_action_is_push = true;
		
		bool filtered = filter_type != NoFilter;
		if (filtered) {
			bool found_in_set = filter_set.find(_cmd) != filter_set.end();
			if ((filter_type == BlackList) == found_in_set)
				return 0;
		}
		
		disable_temporary();
		
		id c = original_objc_msgSend(self, class_sel);

		std::fputc('\n', log_fh);
		fprint_spaces(log_fh, cur_depth-1);
		
		bool is_class_method = c == self;
		std::fprintf(log_fh, "%c[%s %s] <%p> ", is_class_method?'+':'-', class_getName(reinterpret_cast<Class>(c)), sel_getName(_cmd), self);
			
		Method m = (is_class_method ? class_getClassMethod : class_getInstanceMethod)(reinterpret_cast<Class>(c), _cmd);
			
		if (do_print_args && m != NULL) {
			unsigned arg_count = method_getNumberOfArguments(m);
			
			if (arg_count > 2) {
				std::fputc('(', log_fh);
				
				std::va_list va;
				va_start(va, _cmd);
				for (unsigned i = 2; i < arg_count; ++ i) {
					if (i != 2)
						fprintf(log_fh, ", ");
					char* arg_type = method_copyArgumentType(m, i);
					ObjCTypeRecord::TypeIndex ti = record.parse(arg_type, false);
					record.print_arguments(ti, va, print_id, log_fh);
					free(arg_type);
				}
				std::fprintf(log_fh, ") ");
				va_end(va);
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
			
			std::fprintf(log_fh, "{");
			selfs.push(self);
		}
		
		restore_temporary();
		
		return 1;
	}
	
	extern "C" USED void show_retval (intptr_t retval) {
		--cur_depth;
		if (!do_print_rv || cur_depth > max_depth)
			return;
		
		disable_temporary();
		if (!last_action_is_push) {
			std::fputc('\n', log_fh);
			fprint_spaces(log_fh, cur_depth);
		}
		
		ObjCTypeRecord::TypeIndex ti = ret_types.top();
		ret_types.pop();
		id self = selfs.top();
		selfs.pop();
		
		if (!record.is_void_type(ti)) {
			if (last_action_is_push)
				std::fputc(' ', log_fh);
			std::fprintf(log_fh, "return ");
			if (record.is_id_type(ti) && reinterpret_cast<id>(retval) == self)
				std::fprintf(log_fh, "self");
			else {
				const char* addr = reinterpret_cast<const char*>(&retval);
				record.print_args(ti, addr, print_id, log_fh);
			}
			std::fprintf(log_fh, "; ");
		}
		
		std::fputc('}', log_fh);
		last_action_is_push = false;
		
		restore_temporary();
	}
	
	extern "C" void restore_temporary_and_decrease_level () { enabled = enabled_temporary; -- cur_depth; }

	__attribute__((naked)) void replaced_objc_msgSend(id self, SEL _cmd, ...) {
#if __arm__
		__asm__(// 0. Check if the hook is enabled. If not, quit now.
				"ldr r12, (Ena0)\n"
"LoadEna0:"		"ldr r12, [pc, r12]\n"
				"teq r12, #0\n"
				"ldreq r12, (Orig0)\n"
"LoadOrig0:"	"ldreq pc, [pc, r12]\n"
				
				// 1. Save the registers.
				"ldr r12, (SR1)\n"
"LoadSR1:"		"add r12, pc, r12\n"
				"stmia r12, {r0-r3, lr}\n"
				
				// 2. Print the arguments.
				"bl _print_args\n"
				"teq r0, #0\n"
				"ldr r1, (SRX)\n"
"LoadSRX:"		"str r0, [pc, r1]\n"
				"bleq _disable_temporary\n"
				
				// 3. Push lr onto our custom stack.
				"ldr r1, (SR2)\n"
"LoadSR2:"		"ldr r0, [pc, r1]\n"
				"bl _push_lr\n"
				
				// 4. Restore the registers.
				"ldr r1, (SR3)\n"
"LoadSR3:"		"add r12, pc, r1\n"
				"ldmia r12, {r0-r3}\n"
				
				// 5. Call original objc_msgSend
				"ldr r12, (Orig1)\n"
"LoadOrig1:"	"ldr r12, [pc, r12]\n"
				"blx r12\n"
							
				// 6. Print return value.
				"ldr r1, (SRY)\n"
"LoadSRY:"		"ldr r2, [pc, r1]\n"
				"teq r2, #0\n"
				"push {r0}\n"
				"blne _show_retval\n"
				"bleq _restore_temporary_and_decrease_level\n"
				"bl _pop_lr\n"
				"mov lr, r0\n"
				"pop {r0}\n"
				"bx lr\n"
				
		"Ena0:	.long _enabled - 8 - (LoadEna0)\n"
		"Orig0:	.long _original_objc_msgSend - 8 - (LoadOrig0)\n"
		"SR1:	.long _rx_reserve - 8 - (LoadSR1)\n"
		"SRX:	.long _rx_reserve - 8 - (LoadSRX) + 20\n"
		"SR2:	.long _rx_reserve - 8 - (LoadSR2) + 16\n"
		"SR3:	.long _rx_reserve - 8 - (LoadSR3)\n"
		"SRY:	.long _rx_reserve - 8 - (LoadSRY) + 20\n"
		"Orig1:	.long _original_objc_msgSend - 8 - (LoadOrig1)\n");

#elif __i386__
#error Not available in x86 yet.
#else
#error Not available in non-ARM or non-x86 platforms.
#endif
	}
	
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
}

extern "C" void SubjC_clear_filter() {
	filter_type = NoFilter;
}

extern "C" void SubjC_blacklist(size_t count, SEL selectors[]) {
	filter_type = BlackList;
	
	std::tr1::unordered_set<SEL> sel_set (selectors, selectors+count);
	std::swap(sel_set, filter_set);
}

extern "C" void SubjC_whitelist(size_t count, SEL selectors[]) {
	filter_type = WhiteList;
	
	std::tr1::unordered_set<SEL> sel_set (selectors, selectors+count);
	std::swap(sel_set, filter_set);
}

extern "C" void SubjC_start(std::FILE* f, size_t maximum_depth, bool print_arguments, bool print_return_value) {
	if (!original_objc_msgSend)
		SubjC_initialize();
	
	last_action_is_push = true;
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
}
