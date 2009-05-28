/*
 
 GPModalTableViewSupport.h ... Modal Table View Support Classes.
 
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

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <GriP/GPModalTableViewSupport.h>
#import <GriP/GPModalTableViewController.h>
#import <GriP/GPGetSmallAppIcon.h>
#import <libkern/OSAtomic.h>
#import <objc/message.h>

extern void ABPersonInitialize();

@interface UITextView ()
-(void)setContentToHTMLString:(NSString*)htmlString;
-(NSString*)contentAsHTMLString;
@end



@implementation GPModalTableViewObject
static int globalUid = 0;
+(void)initialize {
	// this is to force the kAB*** constants to be initialized.
	if (self == [GPModalTableViewObject class])
		CFRelease(ABPersonCreate());
}

@synthesize detail;
@dynamic uidString;
-(id)initWithEntry:(NSDictionary*)entry imageCache:(NSMutableDictionary*)cache {
	if ((self = [super init])) {
		// header status cannot be changed.
		header = [entry isKindOfClass:[NSDictionary class]] && [[entry objectForKey:@"header"] boolValue];
		keyboard = UIKeyboardTypeASCIICapable;
		[self updateWithEntry:entry imageCache:cache];
	}
	return self;
}
+(GPModalTableViewObject*)newEmptyHeaderObject {
	GPModalTableViewObject* object = [[self alloc] init];
	object->header = YES;
	return object;
}
-(NSString*)uidString { return [NSString stringWithFormat:@"%d", uid]; }
-(void)updateWithEntry:(NSDictionary*)entry imageCache:(NSMutableDictionary*)cache {
	dirty = YES;
	uid = OSAtomicIncrement32(&globalUid);
	
	if ([entry isKindOfClass:[NSString class]]) {
		title = [entry retain];
		identifier = [entry retain];
	} else {
		id temp;
		
#define AssignBoolIfDefined2(key,prop) temp = [entry objectForKey:@#key]; if (temp != nil) prop = [temp boolValue]
#define AssignBoolIfDefined(key)   AssignBoolIfDefined2(key, key)
#define AssignIntIfDefined(key)    temp = [entry objectForKey:@#key]; if (temp != nil) key = [temp integerValue]
#define AssignObjectIfDefined2(key, prop) temp = [entry objectForKey:@#key]; if (temp != nil && temp != prop) { [prop release]; prop = [temp retain]; }
#define AssignObjectIfDefined(key) AssignObjectIfDefined2(key, key)
		
		AssignObjectIfDefined(title);
		AssignObjectIfDefined(subtitle);
		AssignBoolIfDefined(compact);
		AssignObjectIfDefined2(id, identifier);
		if (identifier == nil)
			identifier = [title retain];
		AssignBoolIfDefined(noselect);
		
		/*
		NSObject* iconObject = [entry objectForKey:@"icon"];
		if (iconObject != nil) {
			[icon release];
			if ([iconObject isKindOfClass:[NSString class]]) {
				UIImage* cachedIcon = [cache objectForKey:iconObject];
				if (cachedIcon == nil) {
					icon = [GPGetSmallAppIconFromObject(iconObject) retain];
					[cache setObject:(icon ?: (id)kCFNull) forKey:iconObject];
				} else if ((CFNullRef)cachedIcon != kCFNull) {
					icon = [cachedIcon retain];
				}
			} else if ([iconObject isKindOfClass:[NSData class]]) {
				icon = [[UIImage imageWithData:(NSData*)iconObject] retain];
			}
		}
		 */
		AssignObjectIfDefined(icon);
		
		AssignBoolIfDefined(reorder);
		AssignBoolIfDefined2(delete, candelete);
		AssignBoolIfDefined(addressbook);
		
		AssignObjectIfDefined2(description, detail);
		AssignBoolIfDefined(edit);
		AssignIntIfDefined(lines);
		AssignBoolIfDefined(secure);
		AssignObjectIfDefined(placeholder);
		AssignBoolIfDefined(html);
		AssignBoolIfDefined(readonly);
		
		static NSString* const accessoryStrings[] = {nil, @"DisclosureIndicator", @"DisclosureButton", @"Checkmark"};
		int newAccessoryType = GPFindString([entry objectForKey:@"accessory"], accessoryStrings, sizeof(accessoryStrings)/sizeof(NSString*));
		if (newAccessoryType == -1) accessoryType = UITableViewCellAccessoryNone;
		else if (newAccessoryType >= 0) accessoryType = newAccessoryType;
				
		static NSString* const keyboardStrings[] = {nil, @"ASCIICapable", @"NumbersAndPunctuation", @"URL", @"NumberPad", @"PhonePad", @"NamePhonePad", @"EmailAddress"};
		int newKeyboard = GPFindString([entry objectForKey:@"keyboard"], keyboardStrings, sizeof(keyboardStrings)/sizeof(NSString*));
		if (newKeyboard == -1) keyboard = UIKeyboardTypeASCIICapable;
		else if (newKeyboard >= 0) keyboard = newKeyboard;
		
		static NSString* const addressbookStrings[] = {
			@"Address",
			@"CreationDate",
			@"Date",
			@"Department",
			@"Email",
			@"FirstNamePhonetic",
			@"FirstName",
			@"InstantMessage",
			@"JobTitle",
			@"Kind",
			@"LastNamePhonetic",
			@"LastName",
			@"MiddleNamePhonetic",
			@"MiddleName",
			@"ModificationDate",
			@"Nickname",
			@"Note",
			@"Organization",
			@"Phone",
			@"Prefix",
			@"RelatedNames",
			@"Suffix",
			@"URL",
		};
		NSString* addressbookObject = [entry objectForKey:@"addressbook"];
		if (addressbookObject != nil) {
			const ABPropertyID addressbookProperties[] = {
				kABPersonAddressProperty,
				kABPersonCreationDateProperty,
				kABPersonDateProperty,
				kABPersonDepartmentProperty,
				kABPersonEmailProperty,
				kABPersonFirstNamePhoneticProperty,
				kABPersonFirstNameProperty,
				kABPersonInstantMessageProperty,
				kABPersonJobTitleProperty,
				kABPersonKindProperty,
				kABPersonLastNamePhoneticProperty,
				kABPersonLastNameProperty,
				kABPersonMiddleNamePhoneticProperty,
				kABPersonMiddleNameProperty,
				kABPersonModificationDateProperty,
				kABPersonNicknameProperty,
				kABPersonNoteProperty,
				kABPersonOrganizationProperty,
				kABPersonPhoneProperty,
				kABPersonPrefixProperty,
				kABPersonRelatedNamesProperty,
				kABPersonSuffixProperty,
				kABPersonURLProperty,
			};
			
			int index = GPFindString(addressbookObject, addressbookStrings, sizeof(addressbookStrings)/sizeof(NSString*));
			addressbook = index >= 0 ? addressbookProperties[index] : 0;
		}
	}
}
-(void)dealloc {
	[title release]; [identifier release]; [icon release]; [detail release]; [placeholder release]; [subtitle release];
	[super dealloc];
}
-(NSString*)description {
	return [NSString stringWithFormat:@"<GPModalViewTableObject %p>[id=%@, header=%d]", self, identifier, header];
}
@end






@implementation GPModalTableViewContentView
-(void)dealloc {
	[object release];
	[super dealloc];
}
-(void)setObject:(GPModalTableViewObject*)newObject withController:(GPModalTableViewController*)controller; {
	if (object != newObject) {
		[object release];
		object = [newObject retain];
		
		[self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
			
		CGRect selfFrame = self.frame;
#define size_width selfFrame.size.width
		CGRect titleRect;
		if (object->icon != nil) {
			if (GPStringIsEmoji(object->icon)) {
				UILabel* iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 29, 29)];
				iconLabel.font = [UIFont systemFontOfSize:27.5f];
				iconLabel.text = object->icon;
				[self addSubview:iconLabel];
				[iconLabel release];
			} else {
				UIImageView* iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 29, 29)];
				iconView.image = GPGetSmallAppIconFromObject(object->icon);
				[self addSubview:iconView];
				[iconView release];
			}
			titleRect = CGRectMake(29+8, 0, size_width-(29+8), 29);
		} else
			titleRect = CGRectMake(0, 0, size_width, 29);
		
		CGSize titleSize = CGSizeZero;
		if (object->title != nil) {
			UILabel* titleLabel = [[UILabel alloc] initWithFrame:titleRect];
			[self addSubview:titleLabel];
			[titleLabel release];
			
			titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
			titleLabel.text = object->title;
			titleLabel.numberOfLines = 0;
			[titleLabel sizeToFit];
			
			CGRect adjustedTitleRect = titleLabel.frame;
			if (object->compact) {
				titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
			} else {
				adjustedTitleRect.size.width = titleRect.size.width;
				titleLabel.frame = adjustedTitleRect;
				titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			}
			titleSize = CGSizeMake(adjustedTitleRect.size.width + 4, adjustedTitleRect.size.height + 4);
		}
		
		// Recompute subtitle rect size.
		UIFont* sysFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
		CGRect subtitleRect;
		if (object->compact)
			subtitleRect = CGRectMake(titleRect.origin.x + titleSize.width, titleRect.origin.y, titleRect.size.width - titleSize.width, 1);
		else
			subtitleRect = CGRectMake(titleRect.origin.x, titleRect.origin.y + titleRect.size.height, titleRect.size.width, 1);
		if (object->subtitle != nil) {
			UILabel* subtitleLabel = [[UILabel alloc] initWithFrame:subtitleRect];
			[self addSubview:subtitleLabel];
			[subtitleLabel release];
			
			subtitleLabel.font = sysFont;
			subtitleLabel.text = object->subtitle;
			subtitleLabel.numberOfLines = 0;
			[subtitleLabel sizeToFit];
			
			CGRect adjustedSubtitleRect = subtitleLabel.frame;
			adjustedSubtitleRect.size.width = subtitleRect.size.width;
			subtitleRect.size.height = adjustedSubtitleRect.size.height;
			subtitleLabel.frame = adjustedSubtitleRect;
			subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		} else
			subtitleRect.size.height = -4;
		
		// Recompute detail rect size.
		CGRect detailRect = CGRectMake(0, subtitleRect.size.height + subtitleRect.origin.y + 4, size_width, sysFont.leading);
		UIColor* textColor = [UIColor colorWithWhite:1.f/3.f alpha:1];
		if (object->edit) {
			if (object->lines <= 0)
				detailRect.size.height = sysFont.leading * 5;
			
			UITextView* view = [[(object->lines == 1 ? [UITextField class] : [UITextView class]) alloc] initWithFrame:detailRect];
			if (object->lines != 1)
				view.editable = !object->readonly;
			view.keyboardType = object->keyboard;
			view.secureTextEntry = object->secure;
			SEL selector = (object->lines != 1 && object->html) ? @selector(setContentToHTMLString:) : @selector(setText:);
			objc_msgSend(view, selector, object->detail);
			[self performSelector:@selector(setNeedsLayout) withObject:nil afterDelay:0.5];
			view.delegate = controller;
			view.font = sysFont;
			view.textColor = textColor;
			view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			view.tag = 1966;
			[self addSubview:view];
			[view release];
			
			if (object->readonly && object->lines <= 1) {
				detailRect.size.height = view.contentSize.height;
				view.frame = detailRect;
			}
			
		} else if (object->detail != nil) {
			UILabel* detailLabel = [[UILabel alloc] initWithFrame:detailRect];
			[self addSubview:detailLabel];
			[detailLabel release];
			
			detailLabel.text = object->detail;
			detailLabel.font = sysFont;
			detailLabel.textColor = textColor;
			detailLabel.numberOfLines = MAX(0, object->lines);
			[detailLabel sizeToFit];
			
			CGRect adjustedDetailRect = detailLabel.frame;
			adjustedDetailRect.size.width = detailRect.size.width;
			detailRect.size.height = adjustedDetailRect.size.height;
			detailLabel.frame = adjustedDetailRect;
			
			detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			
		} else {
			detailRect.size.height = -8;
		}

		selfFrame.size.height = detailRect.origin.y + detailRect.size.height + 4;
		self.frame = selfFrame;
		
	}
}
@end
