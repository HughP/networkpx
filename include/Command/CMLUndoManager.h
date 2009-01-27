/*
 
 CMLUndoManager.h ... Undo/Redo manager .
 
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

#import <Foundation/Foundation.h>

@class UIKeyboardImpl;
@protocol UIKeyboardInput;

@interface CMLUndoManager : NSObject {
	NSMutableArray* operations;
	NSUInteger undoLimit;
	NSUInteger currentStep;		// assert( curStep < oper.len <= undoLimit )
	NSObject<UIKeyboardInput>* target;
	NSDate* lastMicromodTime;
	NSTimeInterval micromodUpdateInterval;
	UIKeyboardImpl* impl;
}

@property(assign) NSUInteger undoLimit;
@property(assign,readonly,getter=isUndoable) BOOL undoable;
@property(assign,readonly,getter=isRedoable) BOOL redoable;
@property(assign,readonly) NSObject<UIKeyboardInput>* target;
@property(assign) NSTimeInterval micromodUpdateInterval;
+(CMLUndoManager*)managerWithTarget:(NSObject<UIKeyboardInput>*)aTarget
+(CMLUndoManager*)managerWithTarget:(NSObject<UIKeyboardInput>*)aTarget undoLimit:(NSUInteger)limit;
+(CMLUndoManager*)managerWithTarget:(NSObject<UIKeyboardInput>*)aTarget undoLimit:(NSUInteger)limit micromodUpdateInterval:(NSTimeInterval)interval;
-(id)initWithTarget:(NSObject<UIKeyboardInput>*)aTarget undoLimit:(NSUInteger)limit micromodUpdateInterval:(NSTimeInterval)interval;
-(void)dealloc;
-(void)undo;
-(void)redo;
-(void)setString:(NSString*)str;

// note: you should call these before the micromod is made.
-(void)appendString:(NSString*)str;
-(void)deleteKey;

@end
