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

#if TARGET_IPHONE_SIMULATOR
#define IKX_SCRAP_PATH @"/Users/kennytm/Library/Application Support/iPhone Simulator/User/Library/Keyboard"
#define IKX_LIB_PATH @"/Users/kennytm/XCodeProjects/iKeyEx/svn/trunk/hk.kennytm.iKeyEx3/deb/Library/iKeyEx"
#else
#define IKX_SCRAP_PATH @"/var/mobile/Library/Keyboard"
#define IKX_LIB_PATH @"/Library/iKeyEx"
#endif

#if __cplusplus
extern "C" {
#endif

@class NSString, NSDictionary, NSBundle;
	
#ifndef IKX_PATTRIE_HPP
	typedef void* IKXPhraseCompletionTableRef;
	typedef void* IKXCharacterTableRef;
#else
	typedef IKX::ReadonlyPatTrie<IKX::PhraseContent>* IKXPhraseCompletionTableRef;
	typedef std::tr1::unordered_map<std::string, unsigned>* IKXCharacterTableRef;
#endif

/// Check if an input mode is an iKeyEx mode.
BOOL IKXIsiKeyExMode(NSString* modeString);
/// Check if an input mode is an iKeyEx internal mode.
BOOL IKXIsInternalMode(NSString* modeString);

/// Get the iKeyEx configuration dictionary.
NSDictionary* IKXConfigDictionary();
/// Reload the config dictionary from disk.
void IKXFlushConfigDictionary();
	
	int IKXKeyboardChooserPreference();
	BOOL IKXConfirmWithSpacePreference();

/// Get the layout reference of an iKeyEx input mode.
NSString* IKXLayoutReference(NSString* modeString);
/// Get the input manager reference of an iKeyEx input mode.
NSString* IKXInputManagerReference(NSString* modeString);

/// Get the bundle of a custom keyboard layout.
NSBundle* IKXLayoutBundle(NSString* layoutReference);
/// Get the bundle of a custom input manager.
NSBundle* IKXInputManagerBundle(NSString* imeReference);

/// Plays the "click" sound.
void IKXPlaySound();

/// Get name of input mode.
NSString* IKXNameOfMode(NSString* modeString);
	
	
	IKXPhraseCompletionTableRef IKXPhraseCompletionTableCreate(NSString* language);	///< Create default phrase completion table for specific language.
	NSArray* IKXPhraseCompletionTableSearch(IKXPhraseCompletionTableRef completionTable, NSString* prefix);	///< Retrieve a list of completions, sorted by frequency, of a Chinese phrase prefix.
	void IKXPhraseCompletionTableDealloc(IKXPhraseCompletionTableRef completionTable);	///< Delete the phrase completion table.
	
	IKXCharacterTableRef IKXCharacterTableCreate(NSString* language);
	void IKXCharacterTableSort(IKXCharacterTableRef charTable, NSMutableArray* chars);
	void IKXCharacterTableDealloc(IKXCharacterTableRef charTable);
	
	

#if __cplusplus
}
#endif
		
