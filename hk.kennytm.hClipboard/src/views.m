/*
 
 views.h ... Views and Layouts in ℏClipboard.
 
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

#import "views.h"
#import <iKeyEx/common.h>
#import <iKeyEx/ImageLoader.h>
#import <iKeyEx/KeyboardLoader.h>
#import <iKeyEx/UIKBSpecialKeyButtons.h>
#import <iKeyEx/UIKBSound.h>
#import <UIKit2/Functions.h>
#import <UIKit2/UIKeyboardImpl.h>
#import "clipboard.h"
#import "datasource.h"
#import "controller.h"





#pragma mark -

@implementation hCClipboardView
@synthesize secure, soundEffect;

-(void)restoreCellSelectedStyle:(UITableViewCell*)cell {
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	cell.selectedTextColor = [UIColor blackColor];
}

-(void)flashFirstRowAsBlue {
	NSIndexPath* firstRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	UITableViewCell* cell = [self cellForRowAtIndexPath:firstRowIndexPath];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.selectedTextColor = nil;
	if (self.contentOffset.y > 0) {
		[self selectRowAtIndexPath:firstRowIndexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
	} else {
		[self selectRowAtIndexPath:firstRowIndexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
		[self deselectRowAtIndexPath:firstRowIndexPath animated:YES]; 
		[self performSelector:@selector(restoreCellSelectedStyle:) withObject:cell afterDelay:1];
	}
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView*)tbl {
	[(hCClipboardView*)tbl flashFirstRowAsBlue];
}

-(Clipboard*)clipboard { return datasource.clipboard; }
-(void)setClipboard:(Clipboard*)clpbrd { datasource.clipboard = clpbrd; [self reloadData]; }

-(void)dealloc {
	[_target release];
	[datasource release];
	[super dealloc];
}

-(void)tableView:(UITableView*)tbl didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	NSUInteger row = indexPath.row;
	if (_action != NULL) {
		// don't perform any action on security breach; warn the user instead.
		if ([datasource.insecureIndices containsIndex:row] || secure)
			[_target performSelector:_action withObject:[datasource.dataCache objectAtIndex:row] withObject:tbl];
		else {
			if ([_target respondsToSelector:@selector(showSecurityBreachWarningOnAction:)])
				[_target showSecurityBreachWarningOnAction:_action];
		}
	}
	
	if (soundEffect)
		[UIKBSound play];
	[tbl deselectRowAtIndexPath:indexPath animated:YES];
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
	// avoid crash on swipe
	if (event == nil)
		return NO;
	// avoid crash on swipe when the board is empty.
	// See http://discussions.apple.com/thread.jspa?messageID=8439372 for detail.
	else if ([datasource tableView:self numberOfRowsInSection:0] == 0)
		return NO;
	else
		return CGRectContainsPoint(self.bounds, point);
}

-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		self.rowHeight = 32;
		self.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.backgroundColor = [UIColor clearColor];
		datasource = [[hCClipboardDataSource alloc] init];
		self.dataSource = datasource;
		self.delegate = self;
		_target = nil;
		_action = NULL;
		self.scrollsToTop = NO;
		self.allowsSelectionDuringEditing = YES;
		
		
		emptyClipboardIndicator = [[UILabel alloc] initWithFrame:CGRectZero];
		emptyClipboardIndicator.textColor = [UIColor whiteColor];
		emptyClipboardIndicator.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
		emptyClipboardIndicator.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
		emptyClipboardIndicator.textAlignment = UITextAlignmentCenter;
		emptyClipboardIndicator.backgroundColor = [UIColor clearColor];
		[self addSubview:emptyClipboardIndicator];
		[emptyClipboardIndicator release];
		
		[self reloadData];
	}
	return self;
}

-(void)setTarget:(id)target action:(SEL)action {
	if (target != _target) {
		[_target release];
		_target = [target retain];
	}
	_action = action;
}

-(void)layoutSubviews {
	[super layoutSubviews];
	if ([datasource tableView:self numberOfRowsInSection:0] == 0) {
		emptyClipboardIndicator.hidden = NO;
		CGFloat h = [@"|" sizeWithFont:emptyClipboardIndicator.font].height;
		CGSize frameSize = self.frame.size;
		emptyClipboardIndicator.frame = CGRectMake(0, round((frameSize.height-h)*0.5), frameSize.width, h);
	} else
		emptyClipboardIndicator.hidden = YES;
}
-(void)setPlaceholderText:(NSString*)txt { emptyClipboardIndicator.text = txt; }
-(BOOL)switchClipboard {
	BOOL result = [datasource switchClipboard];
	[self reloadData];
	return result;
}

-(BOOL)isDefaultClipboard { return datasource.usesPrefix; }
-(void)updateDataCache { [datasource updateDataCache]; }
@end





@implementation hCVerticalToolBar

@synthesize columns;

-(void)layoutSubviews {
	CGSize btnSize = self.bounds.size;
	btnSize.height = round(btnSize.height * columns / ([self.subviews count]));
	if (columns > 1)
		btnSize.width = round(btnSize.width / columns);
	CGFloat y = 0;
	CGFloat x = 0;
	NSUInteger i = 0;
	for (UIButton* btn in self.subviews) {
		btn.frame = CGRectMake(x, y, btnSize.width, btnSize.height);
		++ i;
		if (i < columns) {
			x += btnSize.width;
		} else {
			x = 0;
			i = 0;
			y += btnSize.height;
		}
	}
}
-(UIButton*)addButtonWithImage:(UIImage*)img target:(id)target action:(SEL)action {
	UIButton* newBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	newBtn.showsTouchWhenHighlighted = YES;
	[newBtn setImage:img forState:UIControlStateNormal];
	[newBtn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:newBtn];
	[self layoutIfNeeded];
	return newBtn;
}

-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		columns = 1;
	}
	return self;
}
@end


@implementation hCLayout


@synthesize clipboardView;
-(id)initWithFrame:(CGRect)frm {
	if ((self = (hCLayout*)[super initWithFrame:frm])) {
		NSBundle* thisBundle = [KeyboardBundle activeBundle].bundle;
		keyboardAppearance = UIKeyboardAppearanceDefault;
		
		controller = [[hCLayoutController alloc] init];
		controller.view = self;
		controller.bundle = thisBundle;
		
		NSDictionary* prefs = controller.preferences;
		BOOL soundEffect = [[prefs objectForKey:@"soundEffect"] boolValue];
		BOOL defaultEditingMode = [[prefs objectForKey:@"defaultEditingMode"] boolValue];
				
		calloutShower = [[UICalloutViewShower alloc] initWithView:self];
		
		backgroundView = [[UIImageView alloc] initWithFrame:frm];
		[self addSubview:backgroundView];
		[backgroundView release];
		
		spBtnGroup = [[UIKBButtonsGroup alloc] initWithLandscape:NO appearance:UIKeyboardAppearanceDefault];
		[spBtnGroup addSubviewWithClass:[UIKBInternationalButton class]];
		[spBtnGroup addSubviewWithClass:[UIKBSpaceBarButton class]];
		[spBtnGroup addSubviewWithClass:[UIKBReturnKeyButton class]];
		[[spBtnGroup firstSubviewWithClass:[UIKBSpaceBarButton class]] addTarget:controller action:@selector(addMicromod:) forControlEvents:UIControlEventTouchUpInside];
		[[spBtnGroup firstSubviewWithClass:[UIKBReturnKeyButton class]] addTarget:controller action:@selector(addMicromod:) forControlEvents:UIControlEventTouchUpInside];
		switchClipboardButton = [[UIKBSpecialKeyButton alloc] init];
		switchClipboardButton.showsTouchWhenHighlighted = YES;
		[switchClipboardButton addTarget:controller
								  action:@selector(switchClipboard:)
						forControlEvents:UIControlEventTouchUpInside];
		[switchClipboardButton setImage:[UIImage imageWithContentsOfFile:[thisBundle pathForResource:@"toTemplate" ofType:@"png"]]
							   forState:UIControlStateNormal];
		[calloutShower registerButton:switchClipboardButton
					withCalloutString:[thisBundle localizedStringForKey:@"Switch to Templates" value:nil table:nil]];
		if (soundEffect)
			[UIKBSound registerButton:switchClipboardButton];
		[spBtnGroup addSubview:switchClipboardButton];
		[switchClipboardButton release];
		[self addSubview:spBtnGroup];
		[spBtnGroup release];
		
		toolbar = [[hCVerticalToolBar alloc] initWithFrame:CGRectZero];
		
		copyBtn = [toolbar addButtonWithImage:[UIImage imageWithContentsOfFile:[thisBundle pathForResource:@"copy" ofType:@"png"]]
									   target:controller
									   action:@selector(copyText)];
		[calloutShower registerButton:copyBtn withCalloutString:[thisBundle localizedStringForKey:@"Copy" value:nil table:nil]];
		if (soundEffect)
			[UIKBSound registerButton:copyBtn];
		
		markSelBtn = [toolbar addButtonWithImage:[UIImage imageWithContentsOfFile:[thisBundle pathForResource:@"selectStart" ofType:@"png"]]
										  target:controller
										  action:@selector(markSelection:)];
		[calloutShower registerButton:markSelBtn withCalloutString:[thisBundle localizedStringForKey:@"Select from here..." value:nil table:nil]];
		if (soundEffect)
			[UIKBSound registerButton:markSelBtn];
		
		
		UIButton* btn = [toolbar addButtonWithImage:_UIImageWithName(@"UIButtonBarPreviousSlide.png")
											 target:controller
											 action:@selector(moveToBeginning)];
		[calloutShower registerButton:btn withCalloutString:[thisBundle localizedStringForKey:@"Move to beginning" value:nil table:nil]];
		[UIKBSound registerButton:btn];
		
		btn = [toolbar addButtonWithImage:_UIImageWithName(@"UIButtonBarNextSlide.png")
								   target:controller
								   action:@selector(moveToEnd)];
		[calloutShower registerButton:btn withCalloutString:[thisBundle localizedStringForKey:@"Move to end" value:nil table:nil]];
		if (soundEffect)
			[UIKBSound registerButton:btn];
		
		undoBtn = [toolbar addButtonWithImage:_UIImageWithName(@"UIButtonBarReply.png")
									   target:controller
									   action:@selector(undo)];
		[calloutShower registerButton:undoBtn withCalloutString:[thisBundle localizedStringForKey:@"Undo" value:nil table:nil]];
		[UIKBSound registerButton:undoBtn];
		
		btn = [toolbar addButtonWithImage:_UIImageWithName(@"UIButtonBarInfo.png")
								   target:controller
								   action:@selector(toggleEditingMode)];
		[calloutShower registerButton:btn withCalloutString:[thisBundle localizedStringForKey:@"Toggle editing mode" value:nil table:nil]];
		if (soundEffect)
			[UIKBSound registerButton:btn];
		
		[self addSubview:toolbar];
		[toolbar release];
		
		clipboardView = [[hCClipboardView alloc] initWithFrame:CGRectZero];
		[clipboardView setTarget:controller action:@selector(paste:)];
		[clipboardView setPlaceholderText:[thisBundle localizedStringForKey:@"Clipboard is empty" value:nil table:nil]];
		if (defaultEditingMode)
			clipboardView.editing = YES;
		clipboardView.soundEffect = soundEffect;
		[self addSubview:clipboardView];
		[clipboardView release];
		
		[self layoutIfNeeded];
	}
	return self;
}

-(void)layoutSubviews {
	int ori = [[UIKeyboardImpl sharedInstance] orientation];
	BOOL landsc = (ori == 90 || ori == -90);
	if (!landsc) {
		toolbar.columns = 1;
		toolbar.frame = CGRectMake(320-36, 8, 36, 172-8);
		clipboardView.frame = CGRectMake(8, 8, 320-36-16, 172-16);
	} else {
		toolbar.columns = 2;
		toolbar.frame = CGRectMake(480-72, 8, 72, 119-8);
		clipboardView.frame = CGRectMake(8, 8, 480-72-16, 119-16);
	}
	[toolbar setNeedsLayout];
	
	spBtnGroup.landscape = landsc;
	backgroundView.image = UIKBGetImage(UIKBImageBackground, keyboardAppearance, landsc);
	backgroundView.frame = spBtnGroup.frame;
	
	CGRect bdyRect = self.bounds;
	bdyRect.origin.y = -bdyRect.size.height;
	bdyRect.size.height += bdyRect.size.height;
	calloutShower.boundaryRect = bdyRect;
	
	switchClipboardButton.frame = [UIKBPlaneChooserButton defaultFrameWithLandscape:landsc];
}

-(void)showKeyboardType:(UIKeyboardType)type withAppearance:(UIKeyboardAppearance)appr {
	UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
	int ori = [impl orientation];
	BOOL landsc = (ori == 90 || ori == -90);
	keyboardAppearance = appr;
	
	backgroundView.image = UIKBGetImage(UIKBImageBackground, appr, landsc);
	spBtnGroup.keyboardAppearance = appr;
	backgroundView.frame = spBtnGroup.frame;
	
	BOOL isSecure = impl.textInputTraits.secureTextEntry;
	clipboardView.secure = isSecure;
	hCSecurityLevel level = controller.securityLevel;
	if (level != hCSecurityLevelFree) {
		markSelBtn.enabled = !isSecure;
		if (level == hCSecurityLevelNoCopying) {
			copyBtn.enabled = !isSecure;
		}
	}
	[controller resetUndoManager];
	
	[self setNeedsLayout];
}

-(void)updateReturnKey {
	UIKBReturnKeyButton* retKey = (UIKBReturnKeyButton*)[spBtnGroup firstSubviewWithClass:[UIKBReturnKeyButton class]];
	if (retKey != nil) {
		UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
		retKey.returnKeyType = impl.returnKeyType;
		retKey.enabled = impl.returnKeyEnabled;
	}
}


-(void)dealloc {
	[calloutShower release];
	[controller release];
	[super dealloc];
}
@end
