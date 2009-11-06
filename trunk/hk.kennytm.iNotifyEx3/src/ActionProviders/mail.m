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

#import <Message/Message.h>


static LibraryMessage* lookupMailMessage(NSString* messageID) {
	return [[MailMessageLibrary defaultInstance] messageWithMessageID:messageID];
}

void mark(NSArray* argv) {
	if ([argv count] >= 3) {
		NSString* args[2];
		[argv getObjects:args range:NSMakeRange(1, 2)];
		LibraryMessage* msg = lookupMailMessage(args[1]);
		if (msg) {
			if ([args[0] isEqualToString:@"viewed"])
				[msg markAsViewed];
			else if ([args[0] isEqualToString:@"not-viewed"])
				[msg markAsNotViewed];
			else if ([args[0] isEqualToString:@"replied"])
				[msg markAsReplied];
			else if ([args[0] isEqualToString:@"forwarded"])
				[msg markAsForwarded];
		}
	}
}

void reply(NSArray* argv) {
}