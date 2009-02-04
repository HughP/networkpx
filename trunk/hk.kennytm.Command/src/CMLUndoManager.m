/*
 
 CMLUndoManager.m ... Tools for ⌘lets.
 
 Copyright (c) 2009, KennyTM~
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, 
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of the KennyTM~ nor the names of its contributors may be
   used to endorse or promote products derived from this software without
   specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import <Command/CMLSetSelection.h>
#import <Command/CMLUndoManager.h>
#import <UIKit2/UIKeyboardInput.h>
#import <UIKit2/UIKeyboardImpl.h>

@interface CMLUndoEntry : NSObject {
@package
	NSString* stringInserted;
	NSString* stringRemoved;
	NSRange previousRange;
}
+(CMLUndoEntry*)entryWithTarget:(NSObject<UIKeyboardInput>*)target setString:(NSString*)str;
-(id)initWithTarget:(NSObject<UIKeyboardInput>*)target setString:(NSString*)str;
-(void)dealloc;
-(void)appendString:(NSString*)str;
-(void)deleteKeyOnTarget:(NSObject<UIKeyboardInput>*)target;
@end

@implementation CMLUndoEntry
+(CMLUndoEntry*)entryWithTarget:(NSObject<UIKeyboardInput>*)target setString:(NSString*)str {
	return [[[CMLUndoEntry alloc] initWithTarget:target setString:str] autorelease];
}
-(id)initWithTarget:(NSObject<UIKeyboardInput>*)target setString:(NSString*)str {
	if ((self = [super init])) {
		previousRange = target.selectionRange;
		stringRemoved = [[target.text substringWithRange:previousRange] copy];
		stringInserted = [str copy];
	}
	return self;
}
-(void)dealloc {
	[stringInserted release];
	[stringRemoved release];
	[super dealloc];
}
-(void)appendString:(NSString*)str {
	//previousRange.length += [str length];
	NSString* oldStr = stringInserted;
	stringInserted = [[oldStr stringByAppendingString:str] copy];
	[oldStr release];
}
-(void)deleteKeyOnTarget:(NSObject<UIKeyboardInput>*)target {
	if (previousRange.location == 0)
		return;
	-- previousRange.location;
	
	NSUInteger strLen = [stringInserted length];
	NSString* oldStr = nil;
	if (strLen > 0) {
		
		oldStr = stringInserted;
		stringInserted = [[stringInserted substringToIndex:strLen-1] copy];
	} else {
		oldStr = stringRemoved;
		stringRemoved = [[[target.text substringWithRange:NSMakeRange(previousRange.location, 1)] stringByAppendingString:stringRemoved] copy];
	}
	[oldStr release];
}

@end



#define DefaultMicromodInterval 60
#define DefaultUndoLimit 10

@implementation CMLUndoManager
@synthesize undoLimit, target, micromodUpdateInterval;
-(void)setUndoLimit:(NSUInteger)limit {
	if (limit < undoLimit) {
		NSUInteger operCount = [operations count];
		if (operCount > limit) {
			if (currentStep < limit)
				[operations removeObjectsInRange:NSMakeRange(limit, operCount-limit)];
			else {
				[operations removeObjectsInRange:NSMakeRange(currentStep+1, operCount-currentStep-1)];
				[operations removeObjectsInRange:NSMakeRange(0, currentStep+1-limit)];
			}
		}
	}
	undoLimit = limit;
}
-(void)setTarget:(NSObject<UIKeyboardInput>*)aTarget {
	if (target != aTarget) {
		target = aTarget;
		[self reset];
	}
}

@dynamic undoable;
-(BOOL)isUndoable { return currentStep > 0; }
@dynamic redoable;
-(BOOL)isRedoable { return currentStep < [operations count]-1; }

+(CMLUndoManager*)managerWithTarget:(NSObject<UIKeyboardInput>*)aTarget {
	return [[[CMLUndoManager alloc] initWithTarget:aTarget undoLimit:DefaultUndoLimit micromodUpdateInterval:DefaultMicromodInterval] autorelease];
}
+(CMLUndoManager*)managerWithTarget:(NSObject<UIKeyboardInput>*)aTarget undoLimit:(NSUInteger)limit {
	return [[[CMLUndoManager alloc] initWithTarget:aTarget undoLimit:limit micromodUpdateInterval:DefaultMicromodInterval] autorelease];
}
+(CMLUndoManager*)managerWithTarget:(NSObject<UIKeyboardInput>*)aTarget undoLimit:(NSUInteger)limit micromodUpdateInterval:(NSTimeInterval)interval {
	return [[[CMLUndoManager alloc] initWithTarget:aTarget undoLimit:limit micromodUpdateInterval:interval] autorelease];
}

-(id)initWithTarget:(NSObject<UIKeyboardInput>*)aTarget undoLimit:(NSUInteger)limit micromodUpdateInterval:(NSTimeInterval)interval {
	if ((self = [super init])) {
		operations = [[NSMutableArray alloc] init];
		undoLimit = limit;
		target = aTarget;
		micromodUpdateInterval = interval;
		impl = [UIKeyboardImpl sharedInstance];
	}
	return self;
}
-(void)dealloc {
	[operations release];
	[lastMicromodTime release];
	[super dealloc];
}

-(void)undo {
	if (currentStep > 0) {
		CMLUndoEntry* entryAtCurrentStep = [operations objectAtIndex:currentStep-1];
		-- currentStep;
		setSelection(target, NSMakeRange(entryAtCurrentStep->previousRange.location, [entryAtCurrentStep->stringInserted length]));
		if ([@"" isEqualToString:entryAtCurrentStep->stringRemoved])
			[impl handleDelete];
		else
			[impl handleStringInput:entryAtCurrentStep->stringRemoved];
		setSelection(target, entryAtCurrentStep->previousRange);
		[lastMicromodTime release];
		lastMicromodTime = nil;
	}
}

-(void)redo {
	if (currentStep < [operations count]-1) {
		++ currentStep;
		CMLUndoEntry* entryAtNextStep = [operations objectAtIndex:currentStep];
		setSelection(target, entryAtNextStep->previousRange);
		if ([@"" isEqualToString:entryAtNextStep->stringInserted])
			[impl handleDelete];
		else
			[impl handleStringInput:entryAtNextStep->stringInserted];
		[lastMicromodTime release];
		lastMicromodTime = nil;
	}
}

-(void)setString:(NSString*)str {
	NSUInteger operCount = [operations count];
	CMLUndoEntry* entry = [CMLUndoEntry entryWithTarget:target setString:str];
	
	if (currentStep >= operCount) {
		if (operCount >= undoLimit)
			[operations removeObjectAtIndex:0];
		else
			++ currentStep;
		[operations addObject:entry];
	} else {
		[operations removeObjectsInRange:NSMakeRange(currentStep, operCount-currentStep)];
		[operations addObject:entry];
		++ currentStep;
	}
	
	[lastMicromodTime release];
	lastMicromodTime = nil;
}
-(void)appendString:(NSString*)str {
	if (lastMicromodTime != nil) {
		if (-[lastMicromodTime timeIntervalSinceNow] >= micromodUpdateInterval)
			goto actuallySetString;
		else {
			[[operations lastObject] appendString:str];
		}
	} else {
actuallySetString:
		[self setString:str];
		lastMicromodTime = [[NSDate alloc] init];
	}
}
-(void)deleteKey {
	NSRange selSelection = target.selectionRange;
	if (selSelection.length != 0) {
		// selection delete is crucial, not a micromod.
		goto actuallySetString;
	} else {
		if (selSelection.location == 0)
			return;
		else
			-- selSelection.location;
		selSelection.length = 1;
	}
		
	if (lastMicromodTime != nil) {
		if (-[lastMicromodTime timeIntervalSinceNow] >= micromodUpdateInterval)
			goto actuallySetString;
		else {
			[[operations objectAtIndex:currentStep] deleteKeyOnTarget:target];
		}
	} else {
actuallySetString:
		setSelection(target, selSelection);
		[self setString:@""];
		lastMicromodTime = [[NSDate alloc] init];
	}
}

-(void)reset {
	currentStep = 0;
	[operations removeAllObjects];
}


@end
