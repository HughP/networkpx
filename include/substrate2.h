#ifndef SUBSTRATE2_H
#define SUBSTRATE2_H

// Use substrate.h on iPhoneOS, and APELite on x86/ppc for debugging.
#ifdef __arm__
#import <substrate.h>
#define REGPARM3 
#elif __i386__ || __ppc__
#import <objc/runtime.h>
#import <objc/message.h>
extern void* APEPatchCreate(const void* original, const void* replacement);
#define MSHookFunction(original, replacement, result) (*(result) = APEPatchCreate((original), (replacement)))
IMP MSHookMessage(Class _class, SEL sel, IMP imp, const char* prefix);
#define REGPARM3 __attribute__((regparm(3)))
#else
#error Not supported in non-ARM/i386/PPC system.
#endif

#define Original(funcname) original_##funcname

#define DefineHook(rettype, funcname, ...) \
rettype funcname (__VA_ARGS__); \
static rettype (*original_##funcname) (__VA_ARGS__); \
static rettype replaced_##funcname (__VA_ARGS__)

#define DefineObjCHook(rettype, funcname, ...) \
static rettype (*original_##funcname) (__VA_ARGS__); \
static rettype replaced_##funcname (__VA_ARGS__)

#define DefineHiddenHook(rettype, funcname, ...) \
static rettype (*funcname) (__VA_ARGS__); \
REGPARM3 static rettype (*original_##funcname) (__VA_ARGS__); \
REGPARM3 static rettype replaced_##funcname (__VA_ARGS__)

#define InstallHook(funcname) MSHookFunction(funcname, replaced_##funcname, (void**)&original_##funcname)
#define InstallObjCInstanceHook(cls, sel, delimited_name) original_##delimited_name = (void*)method_setImplementation(class_getInstanceMethod(cls, sel), (IMP)replaced_##delimited_name)
#define InstallObjCClassHook(cls, sel, delimited_name) original_##delimited_name = (void*)method_setImplementation(class_getClassMethod(cls, sel), (IMP)replaced_##delimited_name)

#endif
