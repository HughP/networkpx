/*
 
 prefs.m ... Preference Pane for Command.
 
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

#import <Preferences/PSListController.h>
#import <Preferences/PSDetailController.h>
#import <Preferences/PSSpecifier.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit2/Functions.h>
#import <UIKit3/UIBadgeView.h>

#define PREFERENCE_PATH @"/Library/Command/preference.plist"

@interface TappingHandView : UIView {
	UIImageView* onView, *offView;
	UIBadgeView* badgeView;
	UILabel* clock;
	BOOL state;
	NSUInteger togglesLeft;
	id target;
	SEL action;
	NSTimeInterval delayLeft;
}
-(id)initWithFrame:(CGRect)frm;
@property(assign) BOOL state;
@property(retain) id target;
@property(assign) SEL action;
-(void)tap:(NSUInteger)count;
-(void)delay:(float)delay;
-(void)stopAnimating;
-(void)dealloc;
@end
@interface TappingHandView ()
-(void)toggleState;
-(void)finishTogglingState;
-(void)updateDelay;
@end



@implementation TappingHandView
-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:CGRectMake(frm.origin.x, frm.origin.y, 68, 65)])) {
		onView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/System/Library/PreferenceBundles/Command.bundle/hand-on.png"]];
		offView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/System/Library/PreferenceBundles/Command.bundle/hand.png"]];
		onView.hidden = YES;

		badgeView = [[UIBadgeView alloc] initWithFrame:CGRectMake(68-28, 0, 0, 0)];
		badgeView.hidden = YES;
		
		clock = [[UILabel alloc] initWithFrame:CGRectMake(68-28, (27-13)/2, 28, 13)];
		clock.textColor = [UIColor blueColor];
		clock.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
		clock.hidden = YES;
		clock.font = [UIFont boldSystemFontOfSize:11];
		clock.textAlignment = UITextAlignmentCenter;
		
		[self addSubview:onView];
		[self addSubview:offView];
		[self addSubview:badgeView];
		[self addSubview:clock];
		
		[onView release];		
		[offView release];
		[badgeView release];
		[clock release];
	}
	return self;
}
-(void)dealloc {
	[target release];
	[super dealloc];
}

@synthesize target, action;

@synthesize state;
-(void)setState:(BOOL)state_ {
	if (state != state_) {
		// swap on & off state.
		onView.hidden = !state_;
		offView.hidden = state_;
		badgeView.state = state_;
		state = state_;
	}
}

-(void)tap:(NSUInteger)count {
	self.state = NO;
	togglesLeft = 2*count-1;
	[badgeView setInteger:count];
	badgeView.hidden = NO;
	[self performSelector:@selector(toggleState) withObject:nil afterDelay:0.5];
}

-(void)delay:(float)delay {
	if (delay <= 0) {
		[target performSelector:action];
		return;
	}
	
	clock.hidden = NO;
	clock.text = [NSString stringWithFormat:@"%.1f", delay];
	delayLeft = delay;
	[self performSelector:@selector(updateDelay) withObject:nil afterDelay:0.1];
}

-(void)toggleState {
	self.state = !state;
	-- togglesLeft;
	[badgeView setInteger:1+togglesLeft/2];
	if (togglesLeft != 0)
		[self performSelector:@selector(toggleState) withObject:nil afterDelay:0.5];
	else {
		[self performSelector:@selector(finishTogglingState) withObject:nil afterDelay:0.1];
	}
}
-(void)finishTogglingState {
	badgeView.hidden = YES;
	[target performSelector:action];
}

-(void)updateDelay {
	delayLeft -= 0.1;
	clock.text = [NSString stringWithFormat:@"%.1f", delayLeft];
	if (delayLeft > 0) {
		[self performSelector:@selector(updateDelay) withObject:nil afterDelay:0.1];
	} else {
		clock.hidden = YES;
		[target performSelector:action];
	}
}

-(void)stopAnimating {
	badgeView.hidden = YES;
	clock.hidden = YES;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}
@end



@interface GestureGuideAnimation : UIView {
	TappingHandView* hand;
	float beginTapHold, endTapHold;
	int beginTapCount, endTapCount;
	BOOL dragging;
	BOOL isStaticText;
	BOOL endsWithTouchUp;
	BOOL showCmdbar;
}
+(BOOL)accessInstanceVariablesDirectly;
-(id)initWithFrame:(CGRect)frm;
-(void)startAnimating;
-(void)stopAnimating;
-(void)setValue:(id)value forUndefinedKey:(NSString*)key;
@end

@implementation GestureGuideAnimation
+(BOOL)accessInstanceVariablesDirectly { return YES; }
-(void)setValue:(id)value forUndefinedKey:(NSString*)key {}
-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:CGRectMake(5, frm.size.height+5, frm.size.width-2*5, 75)])) {
		UILabel* lipsum = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, frm.size.width-2*5, 28)];
		lipsum.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit.";
		lipsum.font = [UIFont fontWithName:@"Times New Roman" size:24];
		lipsum.backgroundColor = [UIColor clearColor];
		[self addSubview:lipsum];
		[lipsum release];
		
		hand = [[TappingHandView alloc] initWithFrame:CGRectMake(20, 0, 0, 0)];
		hand.target = self;	// hmmm... retain cycle.
		[self addSubview:hand];
		[hand release];
		
		beginTapCount = endTapCount = 1;
	}
	return self;
}

-(void)stopAnimating {
	[hand stopAnimating];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	hand.frame = CGRectMake(20, 0, 0, 0);
}

-(void)startAnimating {
	[self stopAnimating];
	hand.action = @selector(animatePhase2);
	[hand tap:beginTapCount];
}
-(void)animatePhase2 {
	hand.action = @selector(animatePhaseN);
	[hand delay:beginTapHold];
}
-(void)animatePhaseN {
	[self performSelector:@selector(startAnimating) withObject:nil afterDelay:3];
}
@end



@interface AnimatableListController : PSListController {
	GestureGuideAnimation* anim;
	NSMutableDictionary* preference;
}
-(NSString*)section;
-(id)initForContentSize:(CGSize)size;
-(void)dealloc;
-(void)viewWillBecomeVisible:(PSSpecifier*)parentSpec;
-(void)viewDidBecomeVisible;
-(void)setValue:(NSNumber*)value forSpecifier:(PSSpecifier*)spec;
-(NSNumber*)valueForSpecifier:(PSSpecifier*)spec;
-(void)refreshAnimation;
@end

@implementation AnimatableListController
-(NSString*)section { return @"Labels"; }
-(id)initForContentSize:(CGSize)size {
	if ((self = [super initForContentSize:size])) {
		preference = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCE_PATH];
	}
	return self;
}
-(void)dealloc {
	[preference writeToFile:PREFERENCE_PATH atomically:NO];
	[preference release];
	[super dealloc];
}

-(void)viewDidBecomeVisible {
	[super viewDidBecomeVisible];
	
	// insert animation.
	UIView* lastCell = [self cachedCellForSpecifierID:@"Preview"];
	CGRect lastCellFrame = lastCell.frame;
	anim = [[GestureGuideAnimation alloc] initWithFrame:lastCellFrame];
	
	[lastCell addSubview:anim];
	[anim release];
	[self refreshAnimation];
}
-(void)setValue:(NSNumber*)value forSpecifier:(PSSpecifier*)spec {
	NSMutableDictionary* content = [[preference objectForKey:@"control"] objectForKey:[self section]];
	NSString* key = spec.identifier;
	[content setObject:value forKey:key];
	[anim setValue:value forKey:key];
	if (spec->cellType != PSLinkListCell)
		[self refreshAnimation];
}
-(NSNumber*)valueForSpecifier:(PSSpecifier*)spec {
	return [[[preference objectForKey:@"control"] objectForKey:[self section]] objectForKey:spec.identifier];
}
-(void)viewWillBecomeVisible:(PSSpecifier*)parentSpec {
	// adjust the specifier to point to self.
	[parentSpec setTarget:self];
	[super viewWillBecomeVisible:parentSpec];
}

-(void)refreshAnimation {
	NSDictionary* content = [[preference objectForKey:@"control"] objectForKey:[self section]];
	for (NSString* key in content)
		[anim setValue:[content objectForKey:key] forKey:key];
	[anim startAnimating];
}

@end


@interface CommandListController : PSListController {}
-(NSArray*)specifiers;
@end
@implementation CommandListController
-(NSArray*)specifiers {
	if (_specifiers == nil)
		_specifiers = [[self loadSpecifiersFromPlistName:@"Command" target:self] retain];
	return _specifiers;
}
@end

