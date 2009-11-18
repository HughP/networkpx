/*
 
FILE_NAME ... FILE_DESCRIPTION

Copyright (c) 2009  KennyTM~ <kennytm@gmail.com>
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

#import "INXIcon.h"
#import <SpringBoard/SpringBoard.h>
#import <AddressBook/AddressBook.h>
#import <ChatKit/ChatKit.h>

static UIImage* INXIcon2(NSString* iconDescription, BOOL smallIcon) {
	NSUInteger len = [iconDescription length];
	if (len == 0)
		return nil;
	
	unichar firstChar = [iconDescription characterAtIndex:0];
	
	if (firstChar == '/') {
		return [UIImage imageWithContentsOfFile:iconDescription];
	} else if (firstChar == '<') {
		CFStringInlineBuffer buf;
		CFStringInitInlineBuffer((CFStringRef)iconDescription, &buf, CFRangeMake(0, len));
		int nibbles[2];
		int nibblePos = 0;
		NSMutableData* data = [[NSMutableData alloc] init];
		
		for (NSUInteger i = 0; i < len; ++ i) {
			unichar c = CFStringGetCharacterFromInlineBuffer(&buf, i);
			if (c >= '0' && c <= '9')
				nibbles[nibblePos] = c - '0';
			else if (c >= 'a' && c <= 'f')
				nibbles[nibblePos] = c - 'a' + 10;
			else if (c >= 'A' && c <= 'F')
				nibbles[nibblePos] = c - 'A' + 10;
			else
				continue;
			
			++ nibblePos;
			if (nibblePos == 2) {
				nibblePos = 0;
				int byte = nibbles[0] << 4 | nibbles[1];
				[data appendBytes:&byte length:1];
			}
		}
		
		UIImage* img = [UIImage imageWithData:data];
		[data release];
		return img;
	} else {
		if ([iconDescription hasPrefix:@"contact:"]) {
			UIImage* image = nil;
			
			ABRecordID recordID = [[iconDescription substringFromIndex:strlen("contact:")] intValue];
			ABAddressBookRef book = ABAddressBookCreate();
			ABRecordRef person = ABAddressBookGetPersonWithRecordID(book, recordID);
			if (person != NULL) {
				CFDataRef imageData = ABPersonCopyImageData(person);
				if (imageData != NULL) {
					image = [UIImage imageWithData:(NSData*)imageData];
					CFRelease(imageData);
				}
			}
			CFRelease(book);
			
			return image;
			
		} else {
			SBApplication* app = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:iconDescription];
			NSString* path = objc_msgSend(app, smallIcon ? @selector(pathForSmallIcon) : @selector(pathForIcon));
			return [UIImage imageWithContentsOfFile:path];
		}
	}
}

extern UIImage* INXIcon(NSString* iconDescription, INXIconOption iconOption) {
	BOOL isSmall = iconOption == INXIconOption_RawSmall || iconOption == INXIconOption_SmallApplicationIcon || iconOption == INXIconOption_SmallApplicationIconPrecomposed;
	UIImage* rawIcon = INXIcon2(iconDescription, isSmall);
	switch (iconOption) {
		default:
			return rawIcon;
			
		case INXIconOption_ApplicationIcon:
		case INXIconOption_ApplicationIconPrecomposed:
			return [rawIcon _applicationIconImagePrecomposed:iconOption == INXIconOption_ApplicationIconPrecomposed];
			
		case INXIconOption_SmallApplicationIcon:
		case INXIconOption_SmallApplicationIconPrecomposed:
			return [rawIcon _smallApplicationIconImagePrecomposed:iconOption == INXIconOption_SmallApplicationIconPrecomposed];
			
		case INXIconOption_Balloon:
			return [[rawIcon newBalloonImageWithTail:NO] autorelease];
			
		case INXIconOption_Balloon59x59:
			return [[rawIcon newBalloonImageWithTail:NO size:CGSizeMake(59, 59)] autorelease];
	}
}
