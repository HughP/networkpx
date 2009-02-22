/*
 
 CMLCommandlet.h ... Public API for manipulating ⌘lets.
 
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
#import <UIKit2/UIKeyboardInput.h>

typedef enum CMHookedViewType {
	CMNotHookable,
	CMLabel,
	CMWebTexts,
	CMTextField
} CMHookedViewType;

CMHookedViewType CMDetermine(UIView*);

typedef enum CMLFurtherAction {
	CMLActionDefault = 0,
	CMLActionCollapseToStart,
	CMLActionCollapseToEnd,
	CMLActionCollapseToOldEnd,
	CMLActionReuseOldSelection,
	CMLActionMoveToBeginning,
	CMLActionMoveToEnding,
	CMLActionSelectAll,
	CMLActionSelectToBeginningFromStart,
	CMLActionSelectToBeginningFromEnd,
	CMLActionSelectToEndingFromStart,
	CMLActionSelectToEndingFromEnd,
	CMLActionAnchorAtStart = 64,
	CMLActionAnchorAtEnd = 128,
	CMLActionShowMenu = 4096,
	CMLActionSelectAllNow = 8192 
} CMLFurtherAction;


@interface CMLCommandlet : NSObject
+(void)performFurtherAction:(CMLFurtherAction)theActions onTarget:(UIView*)target;
+(void)callCommandlet:(NSString*)cmdletName withTarget:(UIView*)target;
+(void)callCommandlet:(NSString*)cmdletName withString:(NSString*)selectedString;

+(void)interceptCommandlet:(NSString*)cmdletName toInstance:(NSObject*)interceptor action:(SEL)aSelector;
+(void)uninterceptCommandlet:(NSString*)cmdletName fromInstance:(NSObject*)interceptor action:(SEL)aSelector;

//+(void)registerUndoManager:(CMLUndoManager*)manager;
//+(CMLUndoManager*)undoManagerForTarget:(NSObject<UIKeyboardInput>*)target;
@end;