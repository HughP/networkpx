/*

FILE_NAME ... DESCRIPTION
 
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

#import <Foundation/NSObject.h>

@class NSString, GPApplicationBridge, NSNumber, GPDuplexClient, NSDictionary, NSArray;
@protocol GPModalTableViewDelegate;

@interface GPModalTableViewClient : NSObject {
	GPDuplexClient* duplex;
	int uid;
	id<GPModalTableViewDelegate> delegate;
	id context;
}
@property(retain) id context;
@property(assign) id<GPModalTableViewDelegate> delegate;
-(id)initWithDictionary:(NSDictionary*)dictionary applicationBridge:(GPApplicationBridge*)bridge name:(NSString*)name;
-(void)dealloc;
-(void)pushDictionary:(NSDictionary*)dictionary;
@property(assign,readonly,nonatomic,getter=isVisible) BOOL visible;
@property(retain,readonly,nonatomic) NSString* currentIdentifier;
-(void)dismiss;
-(void)reloadDictionary:(NSDictionary*)dictionary forIdentifier:(NSString*)identifier;
-(void)updateButtons:(NSArray*)buttons forIdentifier:(NSString*)identifier;
-(void)pop;
@end


@protocol GPModalTableViewDelegate<NSObject>
@optional
-(void)modalTableView:(GPModalTableViewClient*)client clickedButton:(NSString*)identifier;
-(void)modalTableView:(GPModalTableViewClient*)client movedItem:(NSString*)targetID below:(NSString*)belowID;
-(void)modalTableView:(GPModalTableViewClient*)client deletedItem:(NSString*)item;
-(void)modalTableView:(GPModalTableViewClient*)client selectedItem:(NSString*)item;
-(void)modalTableView:(GPModalTableViewClient*)client changedDescription:(NSString*)newDescription forItem:(NSString*)item;
-(void)modalTableView:(GPModalTableViewClient*)client tappedAccessoryButtonInItem:(NSString*)item;
-(void)modalTableViewDismissed:(GPModalTableViewClient*)client;
@end