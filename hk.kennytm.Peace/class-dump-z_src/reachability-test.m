/*

reachability-test.m ... Test case for reachability matrix.

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

#import <Foundation/Foundation.h>

// (a): class <- class, strong
@interface TestAS_target
@end
@implementation TestAS_target
@end
@interface TestAS_src : TestAS_target
@end
@implementation TestAS_src
@end

// (a): class <- class, weak
@interface TestAW_target
@end
@implementation TestAW_target
@end
@interface TestAW_src_1 { TestAW_target* x; }
@end
@implementation TestAW_src_1
@end
@interface TestAW_src_2
@property(assign) TestAW_target* x;
@end
@implementation TestAW_src_2
@dynamic x;
@end

// (b): class <- category, strong
@interface TestB_target
@end
@implementation TestB_target
@end
@implementation TestB_target (TestB_src)
@end

// (c) class <- protocol, weak
@interface TestC_target
@end
@implementation TestC_target
@end
@protocol TestC_src
@property(assign) TestC_target* x;
@end

// (e) class <- struct
@interface TestE_target
@end
@implementation TestE_target
@end
typedef struct {
	struct E { int y; int www; int wwwz; }* (*z)[2];
	TestE_target** x[2];
} TestE_src;
struct TestE_src {
	struct { int y; int www; int wwwz; }* (*z)[2];
	TestE_target** x[2];
};

// (g) protocol <- class
@protocol TestG_target
@end
@interface TestG_src_1 <TestG_target>
@end
@implementation TestG_src_1
@end
@interface TestG_src_2 {
	NSObject<TestG_target>* x;
}
@end
@implementation TestG_src_2
@end
@interface TestG_src_3
@property(assign) id<TestG_target>* x;
@end
@implementation TestG_src_3
@dynamic x;
@end

// Dummy class to make those protocols and structs visible.
@interface Dummy1 <TestC_src> {
	struct TestE_src e, f;
}
@property(assign) TestC_target* x;
@end
@implementation Dummy1
@dynamic x;
-(void)y:(TestE_src)src {}
@end

// (h) protocol <- category
@protocol TestH_target
@end
@interface Dummy1 (TestH_src) <TestH_target>
@end
@implementation Dummy1 (TestH_src)
@end

// (i) protocol <- protocol
@protocol TestI_target
@end
@protocol TestI_src <TestI_target>
@end

// (k) protocol <- struct
@protocol TestK_target
@end
typedef struct TestK_src {
	NSObject<TestK_target>* x;
} TestK_src;

// (l) ext. cls. <- class, strong.
@interface TestLS_src : NSObject
@end
@implementation TestLS_src
@end

// (l) ext. cls. <- class, weak.
@interface TestLW_src_1 {
	NSObject* w;
}
@end
@implementation TestLW_src_1
@end
@interface TestLW_src_2
@property NSObject** w;
@end
@implementation TestLW_src_2
@dynamic w;
@end

// (m) ext. cls. <- category
@implementation NSObject (TestM_src)
@end

// (p) ext. cls. <- struct
typedef struct TestP_src {
	NSObject* o;
} TestP_src;

// (q) struct <- class
typedef struct TestQS_target {
	int i;
} TestQS_target;
@interface TestQS_src_1 {
	TestQS_target q;
}
@end
@implementation TestQS_src_1
@end
@interface TestQS_src_2
@property TestQS_target x;
@end
@implementation TestQS_src_2
@dynamic x;
@end
@interface TestQS_src_3
-(TestQS_target)x;
@end
@implementation TestQS_src_3
-(TestQS_target)x { return (TestQS_target){2}; }
@end
@interface TestQS_src_4
-(void)x:(TestQS_target)t;
@end
@implementation TestQS_src_4
-(void)x:(TestQS_target)t {}
@end

typedef struct TestQW_target {
	double i;
} TestQW_target;
@interface TestQW_src_1 {
	TestQW_target* q;
}
@end
@implementation TestQW_src_1
@end
@interface TestQW_src_2
@property TestQW_target* x;
@end
@implementation TestQW_src_2
@dynamic x;
@end
@interface TestQW_src_3
-(TestQW_target*)x;
@end
@implementation TestQW_src_3
-(TestQW_target*)x { return 0; }
@end
@interface TestQW_src_4
-(void)x:(TestQW_target*)t;
@end
@implementation TestQW_src_4
-(void)x:(TestQW_target*)t {}
@end


// (u) struct <- struct
typedef struct TestUS_target {
	int r;
	float q;
} TestUS_target;
typedef struct TestUS_src_1 {
	TestUS_target t;
} TestUS_src_1;
typedef struct TestUS_src_2 {
	TestUS_target (*t)[40];
} TestUS_src_2;
	
typedef struct TestUW_target {
	float q;
} TestUW_target;
typedef struct TestUW_src_1 {
	TestUW_target* t;
} TestUW_src_1;
typedef struct TestUW_src_2 {
	TestUW_target* t[40];
} TestUW_src_2;


@interface Dummy2 <TestI_src> {
	id<TestK_target> e;
	TestP_src f[20];
	TestUS_src_1 d;
	TestUS_src_2 wtf;
	TestUW_src_1 x;
	TestUW_src_2 asdasd;

}
@end
@implementation Dummy2
@end
