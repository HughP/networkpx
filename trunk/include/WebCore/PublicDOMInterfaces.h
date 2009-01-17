#import <WebCore/DOMObject.h>

// Copyright (C) 2006 Samuel Weinig <sam.weinig@gmail.com>
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
// OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

// This file is used by bindings/scripts/CodeGeneratorObjC.pm to determine public API.
// All public DOM class interfaces, properties and methods need to be in this file.
// Anything not in the file will be generated into the appropriate private header file.

// Edit by KennyTM~: Just include DOMElement & DOMRange as these are all we require.

@class NSString, DOMDocumentFragment, DOMNamedNodeMap, DOMNodeList, DOMDocument, DOMAttr, DOMCSSStyleDeclaration;



@interface DOMNode : DOMObject
@property(readonly, copy) NSString *nodeName;
@property(copy) NSString *nodeValue;
@property(readonly) unsigned short nodeType;
@property(readonly, retain) DOMNode *parentNode;
@property(readonly, retain) DOMNodeList *childNodes;
@property(readonly, retain) DOMNode *firstChild;
@property(readonly, retain) DOMNode *lastChild;
@property(readonly, retain) DOMNode *previousSibling;
@property(readonly, retain) DOMNode *nextSibling;
@property(readonly, retain) DOMNamedNodeMap *attributes;
@property(readonly, retain) DOMDocument *ownerDocument;
@property(readonly, copy) NSString *namespaceURI;
@property(copy) NSString *prefix;
@property(readonly, copy) NSString *localName;
@property(copy) NSString *textContent;
- (DOMNode *)insertBefore:(DOMNode *)newChild :(DOMNode *)refChild;
- (DOMNode *)insertBefore:(DOMNode *)newChild refChild:(DOMNode *)refChild;
- (DOMNode *)replaceChild:(DOMNode *)newChild :(DOMNode *)oldChild;
- (DOMNode *)replaceChild:(DOMNode *)newChild oldChild:(DOMNode *)oldChild;
- (DOMNode *)removeChild:(DOMNode *)oldChild;
- (DOMNode *)appendChild:(DOMNode *)newChild;
- (BOOL)hasChildNodes;
- (DOMNode *)cloneNode:(BOOL)deep;
- (void)normalize;
- (BOOL)isSupported:(NSString *)feature :(NSString *)version;
- (BOOL)isSupported:(NSString *)feature version:(NSString *)version;
- (BOOL)hasAttributes;
- (BOOL)isSameNode:(DOMNode *)other;
- (BOOL)isEqualNode:(DOMNode *)other;
@end



@interface DOMElement : DOMNode
@property(readonly, copy) NSString *tagName;
@property(readonly, retain) DOMCSSStyleDeclaration *style;
@property(readonly) int offsetLeft;
@property(readonly) int offsetTop;
@property(readonly) int offsetWidth;
@property(readonly) int offsetHeight;
@property(readonly, retain) DOMElement *offsetParent;
@property(readonly) int clientWidth;
@property(readonly) int clientHeight;
@property int scrollLeft;
@property int scrollTop;
@property(readonly) int scrollWidth;
@property(readonly) int scrollHeight;
- (NSString *)getAttribute:(NSString *)name;
- (void)setAttribute:(NSString *)name :(NSString *)value;
- (void)setAttribute:(NSString *)name value:(NSString *)value;
- (void)removeAttribute:(NSString *)name;
- (DOMAttr *)getAttributeNode:(NSString *)name;
- (DOMAttr *)setAttributeNode:(DOMAttr *)newAttr;
- (DOMAttr *)removeAttributeNode:(DOMAttr *)oldAttr;
- (DOMNodeList *)getElementsByTagName:(NSString *)name;
- (NSString *)getAttributeNS:(NSString *)namespaceURI :(NSString *)localName;
- (void)setAttributeNS:(NSString *)namespaceURI :(NSString *)qualifiedName :(NSString *)value;
- (void)removeAttributeNS:(NSString *)namespaceURI :(NSString *)localName;
- (DOMNodeList *)getElementsByTagNameNS:(NSString *)namespaceURI :(NSString *)localName;
- (DOMAttr *)getAttributeNodeNS:(NSString *)namespaceURI :(NSString *)localName;
- (NSString *)getAttributeNS:(NSString *)namespaceURI localName:(NSString *)localName;
- (void)setAttributeNS:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName value:(NSString *)value;
- (void)removeAttributeNS:(NSString *)namespaceURI localName:(NSString *)localName;
- (DOMNodeList *)getElementsByTagNameNS:(NSString *)namespaceURI localName:(NSString *)localName;
- (DOMAttr *)getAttributeNodeNS:(NSString *)namespaceURI localName:(NSString *)localName;
- (DOMAttr *)setAttributeNodeNS:(DOMAttr *)newAttr;
- (BOOL)hasAttribute:(NSString *)name;
- (BOOL)hasAttributeNS:(NSString *)namespaceURI :(NSString *)localName;
- (BOOL)hasAttributeNS:(NSString *)namespaceURI localName:(NSString *)localName;
- (void)focus;
- (void)blur;
- (void)scrollIntoView:(BOOL)alignWithTop;
- (void)scrollIntoViewIfNeeded:(BOOL)centerIfNeeded;
@end



@interface DOMRange : DOMObject
@property(readonly, retain) DOMNode *startContainer;
@property(readonly) int startOffset;
@property(readonly, retain) DOMNode *endContainer;
@property(readonly) int endOffset;
@property(readonly) BOOL collapsed;
@property(readonly, retain) DOMNode *commonAncestorContainer;
@property(readonly, copy) NSString *text;
- (void)setStart:(DOMNode *)refNode offset:(int)offset;
- (void)setStart:(DOMNode *)refNode :(int)offset;
- (void)setEnd:(DOMNode *)refNode offset:(int)offset;
- (void)setEnd:(DOMNode *)refNode :(int)offset;
- (void)setStartBefore:(DOMNode *)refNode;
- (void)setStartAfter:(DOMNode *)refNode;
- (void)setEndBefore:(DOMNode *)refNode;
- (void)setEndAfter:(DOMNode *)refNode;
- (void)collapse:(BOOL)toStart;
- (void)selectNode:(DOMNode *)refNode;
- (void)selectNodeContents:(DOMNode *)refNode;
- (short)compareBoundaryPoints:(unsigned short)how sourceRange:(DOMRange *)sourceRange;
- (short)compareBoundaryPoints:(unsigned short)how :(DOMRange *)sourceRange;
- (void)deleteContents;
- (DOMDocumentFragment *)extractContents;
- (DOMDocumentFragment *)cloneContents;
- (void)insertNode:(DOMNode *)newNode;
- (void)surroundContents:(DOMNode *)newParent;
- (DOMRange *)cloneRange;
- (NSString *)toString;
- (void)detach;
@end



