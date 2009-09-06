/*
 
 subjc.cpp
 Subjective-C: An Objective-C message logger.
 Copyright (C) 2009  KennyTM~
 
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

#include <substrate2.h>
#include <cstdio>
#include "objc_type.h"	// from class-dump-z
#include <stack>
#include <CoreFoundation/CoreFoundation.h>
#include <cstdarg>
#include <boost/unordered_set.hpp>
#include "subjc.h"
#include <pthread.h>

namespace {
	template<typename T>
	struct FilterObject {
		T obj;
		bool is_blacklist;
		
		FilterObject(T obj_) : obj(obj_) {}
		bool operator== (const FilterObject<T>& other) const { return obj == other.obj; }
	};
}

namespace boost {	
	template<typename T>
	struct hash<FilterObject<T> > : public std::unary_function<FilterObject<T>, size_t> {
		size_t operator() (const FilterObject<T>& x) const {
			return hash<T>()(x.obj);
		}
	};
}

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
	
	static pthread_key_t thr_key;
	
	static ObjCTypeRecord record;
	
	static void fprint_spaces (std::FILE* f, size_t n) {
		static char spaces[] = "                ";
		for (size_t i = 0; i < n/16; ++ i)
			std::fwrite(spaces, 1, 16, f);
		std::fwrite(spaces, 1, n%16, f);
	}
	
	struct lr_node {
		intptr_t lr;
		ObjCTypeRecord::TypeIndex ti;
		id self;
		bool should_filter;
#if !NDEBUG
		lr_node() { std::memset(this, 0x33, sizeof(*this)); }
#endif
	};
	
	__attribute__((pure))
	static std::stack<lr_node>& get_lr_list() {
		std::stack<lr_node>* stack = reinterpret_cast<std::stack<lr_node>*>(pthread_getspecific(thr_key));
		if (stack == NULL) {
			stack = new std::stack<lr_node>;
			pthread_setspecific(thr_key, stack);
		}
		return *stack;
	}
	
	static void lr_list_destructor(void* value) {
		delete reinterpret_cast<std::stack<lr_node>*>(value);
	}
	
	extern "C" USED FASTCALL void push_lr (intptr_t lr) { 
		lr_node node;
		node.lr = lr;
		node.should_filter = true;
		get_lr_list().push(node);
	}
	extern "C" USED int pop_lr () { 
		std::stack<lr_node>& lr_list = get_lr_list();
		
		int retval = lr_list.top().lr;
		lr_list.pop();
		return retval;
	}
	
	static int enabled_temporary;
	inline void disable_temporary () { enabled_temporary = enabled; enabled = 0; }
	inline void restore_temporary () { enabled = enabled_temporary; }
	
	static boost::unordered_set<FilterObject<std::pair<Class, SEL> > > specific_filters_set;
	static boost::unordered_set<FilterObject<Class> > class_filters_set;
	static boost::unordered_set<FilterObject<SEL> > selector_filters_set;
	static bool default_black;
	
	static SEL doesNotRecognizeSelector_sel;
	
	enum FilterType { WhiteList, BlackList, NotFiltered };
	
	static void print_id(std::FILE* f, void* x) {
		if (x == NULL) {
			std::fprintf(f, "nil");
		} else { 
			CFTypeID type = 0;
			Class c = object_getClass(reinterpret_cast<id>(x));
			
			if (reinterpret_cast<intptr_t>(c) % __alignof__(Class) != 0) {
				std::fprintf(f, "(id)%p", x);
				return;
			}
			
			if (class_isMetaClass(c)) {
				std::fprintf(f, "%s", class_getName(c));
				return;
			}
			
			if (class_respondsToSelector(c, doesNotRecognizeSelector_sel))
				type = CFGetTypeID(x);
			
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
	static size_t max_depth;
	static bool do_print_args, do_print_rv;
	
	template<typename T>
	static FilterType is_filtered_for(const boost::unordered_set<FilterObject<T> >& the_set, const T& the_target) {
		typename boost::unordered_set<FilterObject<T> >::const_iterator cit = the_set.find(the_target);
		if (cit == the_set.end())
			return NotFiltered;
		else
			return cit->is_blacklist ? BlackList : WhiteList;
	}
	
	static bool is_filtered(Class cls, SEL sel) {
		// 1. Check specific filters.
		FilterType res = is_filtered_for(specific_filters_set, std::pair<Class, SEL>(cls, sel));
		if (res != NotFiltered)
			return res == BlackList;
		
		// 2. Check selectors & classes.
		FilterType sf_res = is_filtered_for(selector_filters_set, sel);
		if (sf_res == BlackList)
			return true;
		FilterType cf_res = is_filtered_for(class_filters_set, cls);
		if (cf_res != NotFiltered)
			return cf_res == BlackList;
		else if (sf_res == WhiteList)
			return false;
		
		return default_black;
	}	
	
	static void print_args_v (id self, SEL _cmd, std::va_list va) {
		disable_temporary();
		
		std::stack<lr_node>& lr_list = get_lr_list();
		
		size_t cur_depth = lr_list.size();
		bool do_print_open_brace = last_action_is_push && do_print_rv;
		last_action_is_push = true;
				
		// We need to msgSend because if the class isn't initialized, those class_getXXXMethod will crash.
		Class c = reinterpret_cast<Class>(original_objc_msgSend(self, class_sel));
		
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
		
		lr_node& node = lr_list.top();
		
		if (do_print_rv) {
			ObjCTypeRecord::TypeIndex ti;
			
			if (m == NULL || _cmd == alloc_sel || _cmd == allocWithZone_sel) {
				ti = record.void_type();
			} else {
				char* ret_type = method_copyReturnType(m);
				ti = record.parse(ret_type, false);
				free(ret_type);
			}
			
			node.ti = ti;
			node.self = self;
		}
		
		if (cur_depth > max_depth)
			return;

		if (!(node.should_filter = is_filtered(c, _cmd)))
			restore_temporary();
	}
	
	extern "C" USED void print_args(id self, SEL _cmd, ...) {
		std::va_list va;
		va_start(va, _cmd);
		print_args_v(self, _cmd, va);
		va_end(va);
	}
	
	extern "C" USED void print_args_stret(void* retval, id self, SEL _cmd, ...) {
		std::va_list va;
		va_start(va, _cmd);
		print_args_v(self, _cmd, va);
		va_end(va);
	}
	
	extern "C" USED FASTCALL void show_retval (const char* addr) {
		std::stack<lr_node>& lr_list = get_lr_list();
		
		lr_node& node = lr_list.top();
				
			if (!do_print_rv)
				return;

			size_t cur_depth = lr_list.size()-1;
			
			if (!node.should_filter)
				disable_temporary();
			
			if (!last_action_is_push) {
				std::fputc('\n', log_fh);
				fprint_spaces(log_fh, cur_depth);
				std::fputc('}', log_fh);
			}
			
			ObjCTypeRecord::TypeIndex ti = node.ti;
			id self = node.self;
			
			assert(ti != 0x33333333);
			
			fflush(log_fh);
			
			if (!record.can_reduce_to_type(ti, record.void_type())) {
				std::fprintf(log_fh, " = ");
				if (record.is_id_type(ti) && *reinterpret_cast<const id*>(addr) == self)
					std::fprintf(log_fh, "/*self*/ ");
				record.print_args(ti, addr, print_id, log_fh);
			}
			last_action_is_push = false;
		
		restore_temporary();
	}
	
	USED static void replaced_objc_msgSend() __asm__("_replaced_objc_msgSend");
	USED static void replaced_objc_msgSend_stret() __asm__("_replaced_objc_msgSend_stret");
	USED static void replaced_objc_msgSend_fpret() __asm__("_replaced_objc_msgSend_fpret");
	
#if __arm__
#pragma mark _replaced_objc_msgSend (ARM)
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
			"stmia r12, {r0-r3}\n"
			
			// 2 Push lr onto our custom stack.
			"mov r0, lr\n"
			"bl _push_lr\n"
			
			// 3. Print the arguments.
			"ldr r2, (LSR3)\n"
"LoadSR3:"	"add r12, pc, r2\n"
			"ldmia r12, {r0-r3}\n"
			"bl _print_args\n"
			
			// 4. Restore the registers.
			"ldr r1, (LSR4)\n"
"LoadSR4:"	"add r2, pc, r1\n"
			"ldmia r2, {r0-r3}\n"
				
			// 5. Call original objc_msgSend
			"ldr r12, (LOrig1)\n"
"LoadOrig1:""ldr r12, [pc, r12]\n"
			"blx r12\n"

			// 6. Print return value.
			"push {r0-r3}\n"	// assume no intrinsic type takes >128 bits...
			"mov r0, sp\n"
			"bl _show_retval\n"
			"bl _pop_lr\n"
			"mov lr, r0\n"
			"pop {r0-r3}\n"
			"bx lr\n"
				
"LEna0:		.long _enabled - 8 - (LoadEna0)\n"
"LOrig0:	.long _original_objc_msgSend - 8 - (LoadOrig0)\n"
"LSR1:		.long _rx_reserve - 8 - (LoadSR1)\n"
"LSR3:		.long _rx_reserve - 8 - (LoadSR3)\n"
"LSR4:		.long _rx_reserve - 8 - (LoadSR4)\n"
"LOrig1:	.long _original_objc_msgSend - 8 - (LoadOrig1)\n");
	
#pragma mark _replaced_objc_msgSend_stret (ARM)
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
			"stmia r12, {r0-r3}\n"
			
			// 2 Push lr onto our custom stack.
			"mov r0, lr\n"
			"bl _push_lr\n"
			
			// 3. Print the arguments.
			"ldr r2, (LSS3)\n"
"LoadSS3:"	"add r12, pc, r2\n"
			"ldmia r12, {r0-r3}\n"
			"bl _print_args_stret\n"
			
			// 4. Restore the registers.
			"ldr r1, (LSS4)\n"
"LoadSS4:"	"add r2, pc, r1\n"
			"ldmia r2, {r0-r3}\n"
			
			// 5. Call original objc_msgSend_stret
			"ldr r12, (LOS1)\n"
"LoadOS1:"	"ldr r12, [pc, r12]\n"
			"blx r12\n"
			
			// 6. Print return value.
			"str r0, [sp, #-4]!\n"
			"bl _show_retval\n"
			"bl _pop_lr\n"
			"mov lr, r0\n"
			"ldr r0, [sp], #4\n"
			"bx lr\n"				
			
"LES0:		.long _enabled - 8 - (LoadES0)\n"
"LOS0:		.long _original_objc_msgSend_stret - 8 - (LoadOS0)\n"
"LSS1:		.long _rx_reserve - 8 - (LoadSS1)\n"
"LSS3:		.long _rx_reserve - 8 - (LoadSS3)\n"
"LSS4:		.long _rx_reserve - 8 - (LoadSS4)\n"
"LOS1:		.long _original_objc_msgSend_stret - 8 - (LoadOS1)\n");

#elif __i386__
	
	extern "C" USED void show_float_retval () {
		std::stack<lr_node>& lr_list = get_lr_list();
		
		lr_node& node = lr_list.top();
		
			if (!do_print_rv)
				return;
			
			if (!node.should_filter)
				disable_temporary();
			
			size_t cur_depth = lr_list.size()-1;
			
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
	
#pragma mark _replaced_objc_msgSend (x86)
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
	
			// 2. Print the arguments.
			"call _print_args\n"
			
			// 3. Call original objc_msgSend.
			"call LR1\n"
"LR1:"		"popl %ecx\n"
			"movl _original_objc_msgSend-LR1(%ecx), %eax\n"
			"call *%eax\n"
			
			// 4. Print return value.
			"call LR3\n"
"LR3:"		"popl %ecx\n"
			"movl %eax, _rx_reserve-LR3(%ecx)\n"	// perhaps we could use stack here, but __dyld_misaligned_stack_error was thrown when I last tried.
			"movl %edx, _rx_reserve+4-LR3(%ecx)\n"
			"leal _rx_reserve-LR3(%ecx), %eax\n"
			"call _show_retval\n"
			"call _pop_lr\n"
			"pushl %eax\n"
			"call LR4\n"
"LR4:"		"popl %ecx\n"
			"movl _rx_reserve-LR4(%ecx), %eax\n"
			"movl _rx_reserve+4-LR4(%ecx), %edx\n"
			"ret\n");
	
#pragma mark _replaced_objc_msgSend_stret (x86)
	__asm__(".text\n"
			"_replaced_objc_msgSend_stret:\n"
			
			"call LS0\n"
"LS0:"		"popl %ecx\n"
			
			// 0. Check if the hook is enabled. If not, quit now.	
			"movl _enabled-LS0(%ecx), %eax\n"
			"test %eax, %eax\n"
			"jne LSCont\n"
			"movl _original_objc_msgSend_stret-LS0(%ecx), %eax\n"
			"jmp *%eax\n"
			
			// 1. Push lr onto our custom stack.
"LSCont:"	"popl %eax\n"
			"call _push_lr\n"
			
			// 2. Print the arguments.
			"call _print_args_stret\n"
			
			// 3. Call original objc_msgSend_stret
			"call LS1\n"
"LS1:"		"popl %ecx\n"
			"movl _original_objc_msgSend_stret-LS1(%ecx), %eax\n"
			"call *%eax\n"
			
			// 4. Print return value.
			"pushl %eax\n"
			"call _show_retval\n"
			"call _pop_lr\n"
			"xchg %eax, (%esp)\n"
			"ret\n");
	
#pragma mark _replaced_objc_msgSend_fpret (x86)
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
			
			// 2. Print the arguments.
			"call _print_args\n"
			
			// 3. Call original objc_msgSend_fpret
			"call LF1\n"
"LF1:"		"popl %ecx\n"
			"movl _original_objc_msgSend_fpret-LF1(%ecx), %eax\n"
			"call *%eax\n"
			
			// 4. Print return value.
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

#define EXPORT extern "C" __attribute__((visibility("default")))

EXPORT void SubjC_initialize () {
	enabled = 0;
	class_sel = sel_registerName("class");
	alloc_sel = sel_registerName("alloc");
	allocWithZone_sel = sel_registerName("allocWithZone:");
	doesNotRecognizeSelector_sel = sel_registerName("doesNotRecognizeSelector:");
//	NSString_class = reinterpret_cast<Class>(objc_getClass("NSString"));
	default_black = false;
	
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

EXPORT void SubjC_clear_filters() {
		clear_stl(specific_filters_set);
		clear_stl(class_filters_set);
		clear_stl(selector_filters_set);
		default_black = false;
	}
	
EXPORT void SubjC_filter_method(enum SubjC_FilterType blacklist, Class class_, SEL selector) {
		FilterObject<std::pair<Class, SEL> > fo (std::pair<Class, SEL>(class_, selector));
		fo.is_blacklist = blacklist == SubjC_Deny;
		specific_filters_set.insert(fo);
	}
	
EXPORT void SubjC_filter_class(enum SubjC_FilterType blacklist, Class class_) {
		FilterObject<Class> fo (class_);
		fo.is_blacklist = blacklist == SubjC_Deny;
		class_filters_set.insert(fo);
	}
	
EXPORT void SubjC_filter_selector(enum SubjC_FilterType blacklist, SEL selector) {
		FilterObject<SEL> fo (selector);
		fo.is_blacklist = blacklist == SubjC_Deny;
		selector_filters_set.insert(fo);
	}

EXPORT void SubjC_default_filter_type(enum SubjC_FilterType blacklist) {
	default_black = blacklist == SubjC_Deny;
}


EXPORT void SubjC_start(std::FILE* f, size_t maximum_depth, bool print_arguments, bool print_return_value) {
	if (!original_objc_msgSend)
		SubjC_initialize();
	
	pthread_key_create(&thr_key, lr_list_destructor);
	pthread_setspecific(thr_key, NULL);
	
	last_action_is_push = false;
	max_depth = maximum_depth;
	do_print_args = print_arguments;
	do_print_rv = print_return_value;
	log_fh = f;
	enabled = 1;
}

EXPORT void SubjC_end() {
	enabled = 0;
	std::fputc('\n', log_fh);
	pthread_key_delete(thr_key);
}
