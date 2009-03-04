/*
 
 UIEasyPickerView.m ... Picker view with a static array as delegate & data source.
 
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

#import <UIKit3/UIEasyPickerView.h>

@implementation UIEasyPickerView 
-(id)initWithComponents:(NSArray*)comps, ... {
	if ((self = [super initWithFrame:CGRectZero])) {
		components = [[NSMutableArray alloc] init];
		NSArray* comp;
		va_list argumentList;
		if (comps) {
			[components addObject:comps];
			va_start(argumentList, comps);
			while ((comp = va_arg(argumentList, NSArray*)))
				[components addObject:comp];
			va_end(argumentList);
		}
		self.delegate = self;
		self.dataSource = self;
	}
	return self;
}
-(void)dealloc {
	[components release];
	[super dealloc];
}

-(void)registerSelectionMonitor:(id)delegate_ action:(SEL)selector {
	delegate = delegate_;
	action = selector;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView*)view { return [components count]; }
-(NSInteger)pickerView:(UIPickerView*)view numberOfRowsInComponent:(NSInteger)comp { return [[components objectAtIndex:comp] count]; }
-(NSString*)pickerView:(UIPickerView*)view titleForRow:(NSInteger)row forComponent:(NSInteger)comp {
	return [[components objectAtIndex:comp] objectAtIndex:row];
}

-(void)pickerView:(UIPickerView*)view didSelectRow:(NSInteger)row inComponent:(NSInteger)comp {
	if (delegate != nil) {
		NSInvocation* invoc = [NSInvocation invocationWithMethodSignature:[UIEasyPickerView instanceMethodSignatureForSelector:_cmd]];
		[invoc setTarget:delegate];
		[invoc setSelector:action];
		[invoc setArgument:&view atIndex:2];
		[invoc setArgument:&row atIndex:3];
		[invoc setArgument:&comp atIndex:4];
		[invoc invoke];
	}
}
@end
