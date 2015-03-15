

# UIKit #

## UIImage ##
### ＿UIImageRefAtPath ###
```
static CFStringRef const trustedPaths[] = {
CFSTR("/System/"),
CFSTR("/Applications/"),
CFSTR("/Widgets/"),         // ???
CFSTR("/Accessories/")      // ??? Do these paths exist at all???
};
static CGImageRef _UIImageRefAtPath(CFStringRef path, bool shouldCache, int* pOrientation) {
    CGImageRef retval = NULL;
    
    if (path != nil) {
        CFStringRef keys[2];
        keys[0] = kCGImageSourceShouldCache;
        keys[1] = CFSTR("kCGImageSourceSkipCRC");
        
        CFBooleanRef values[2];
        values[0] = shouldCache ? kCFBooleanTrue : kCFBooleanFalse;
        values[1] = kCFBooleanFalse;
        
        
        for (int i = 0; i < sizeof(trustedPaths)/sizeof(CFStringRef const); ++i) {
            if (CFStringHasPrefix(path, trustedPaths[i])) {
                values[1] = kCFBooleanTrue;
                break;
            }
        }
        
        CFDictionaryRef options;
        if (values[0] == kCFBooleanFalse && values[1] == kCFBooleanFalse) {
            options = NULL;
        } else {
            options = CFDictionaryCreate(
                                         kCFAllocatorDefault,
                                         keys,
                                         values,
                                         2,
                                         kCFTypeDictionaryKeyCallBacks,
                                         kCFTypeDictionaryValueCallBacks);
        }
        CGImageSourceRef isrc = CGImageSourceCreateWithFile(path, dict);
        
        if (isrc != NULL) {
            if (CGImageSourceGetCount(isrc) != 0) {
                retval = CGImageSourceCreateImageAtIndex(isrc, 0, options);
                if (pOrientation != NULL)
                    *pOrientation = GetImageOrientation(isrc, 0);
            }
            CFRelease(isrc);
        }
        
        if (options != NULL)
            CFRelease(options);
    }
    
    return retval;
}
```

## UIControl ##
### `-[UIControl mouseDown:]:` ###
```
-(void)mouseDown:(GSEventRef)event {
if (![self shouldTrack])
[super mouseDown:event];
else {
    CGPoint startPoint = [self convertPoint:GSEventGetLocationInWindow(event) fromView:nil];
    self.tracking = [self beginTrackingAt:startPoint withEvent:event];
    if (self.tracking) {
        _controlFlags.touchInside = YES;
        _controlFlags.touchDragged = NO;
        _previousPoint = startPoint;
        if (!_controlFlags.dontHighlightOnTouchDown) {
            _downTime = CFAbsoluteTimeGetCurrent();
            self.highlighted = YES;
        }
        int clickCount = GSEventGetClickCount(event);
        [self _sendActionsForEventMask:(clickCount<=1 ? 1 : 2) withEvent:event];
    }
    [self _controlMouseDown:event];
}
}
```

## UIWebDocumentView ##
### `-[UIWebDocumentView(Interaction) calloutApproximateNode]` ###
```
-(void)calloutApproximateNode {
UIWindow* window = self.window;
UIView* calloutParent = [window contentView];
UICalloutView* callout = [[self class] _calloutViewForWebView:self];
if ([self->_delegate respondsToSelector:@selector(superviewForCalloutInWebView:)]) {
    calloutParent = [self->_delegate superviewForCalloutInWebView:self];
}
[calloutParent addSubview:callout];
NSString* title = [self->_interaction.element calloutTitle];
NSString* subtitle = [self->_interaction.element calloutSubtitle];
if ([title length] == 0) {
    title = subtitle;
    subtitle = nil;
}
if ([self->_delegate respondsToSelector:@selector(webView:willShowCalloutWithTitle:andSubtitle:forElement:)]) {
    [self->_delegate webView:self willShowCalloutWithTitle:&title andSubtitle:&subtitle forElement:self->_interaction.element];
}
[callout setTitle:title];
[callout setSubtitle:subtitle];
CGPoint anchorPoint = [calloutParent convertPoint:self->_interaction.location fromView:self];
CGRect boundaryRect = [calloutParent convertRect:[window convertDeviceToWindow:[self->_interaction.element calloutDeviceBoundaryForWebView:self]]
                                        fromView:window];
[callout setAnchorPoint:anchorPoint boundaryRect:boundaryRect animate:YES];
}
```

### `-[UIWebDocumentView(InteractionPrivate) _showImageSheet]` ###
```
#define LOCALIZE(str) WebLocalizedString(&UIKitLocalizableStringsBundle, (str))
-(void)_showImageSheet {
self->_interaction.imageSheet = [[UIModalView alloc] init];
self->_interaction.imageSheet.alertSheetStyle = UIBarStyleDefault;
self->_interaction.imageSheet.delegate = self;

UIButton* saveImageButton = [self->_interaction.imageSheet _addButtonWithTitle:LOCALIZE("Save Image")];
saveImageButton.tag = 1;

if ([self->_interaction.delegate respondsToSelector:@selector(numberOfImagesToSaveForWebView:)]) {
    int imageCount = [self->_interaction.delegate numberOfImagesToSaveForWebView:self];
    if (imageCount > 1) {
        saveImageButton = [self->_interaction.imageSheet _addButtonWithTitle:[NSString stringWithFormat:LOCALIZE("Save N Images"), imageCount]];
        saveImageButton.tag = 2;
    }
}

if ([self->_interaction.element showsTapHighlight]) {
    UIButton* openLinkButton = [self->_interaction.imageSheet _addButtonWithTitle:LOCALIZE("Open Link")];
    openLinkButton.tag = 3;
    [self hideCalloutAndHighlight];
}

UIButton* cancelButton = [self->_interaction.imageSheet _addButtonWithTitle:LOCALIZE("Cancel")];
cancelButton.tag = 4;
self->_interaction.imageSheet.defaultButton = cancelButton;
[self highlightApproximateNodeInverted:YES];

UIWindow* actionShowView = self.window;
if ([self->_interaction.delegate respondsToSelector:@selector(superviewForImageSheetForWebView:)]) {
    actionShowView = [self->_interaction.delegate superviewForImageSheetForWebView:self];
}
[self->_interaction.imageSheet presentSheetInView:actionShowView];

if ([self->_interaction.delegate respondsToSelector:@selector(webView:didShowImageSheet:)]) {
    [self->_interaction.delegate webView:self didShowImageSheet:self->_interaction.imageSheet];
}
}
#undef LOCALIZE
```

# TextInput\_ja #
## UIKeyboardLayoutQWERTY\_ja\_JP\_landscape ##
### `-[UIKeyboardLayoutQWERTY_ja_JP_landscape longPressAction]` ###
```
-(void)longPressAction {
UIKeyDefinition* keyDef = [self activeKey];

if (keyDef == nil)
return;

if (![self isLongPressedKey:keyDef])
return;

self->m_didLongPress = YES;

if ([self downActionFlagsForKey:keyDef] < 0) {
    [self showPopupVariantsForKey:keyDef];
} else
[super longPressAction];
}
```

### `-[UIKeyboardLayoutQWERTY_ja_JP_landscape showPopupVariantsForKey:]` ###
```
static UIColor* translucentBlackColor = nil;    // bb468;

// ...

-(void)showPopupVariantsForKey:(UIKeyDefinition*)keyDef {
    if (keyDef == NULL)
        return;
    
    if ([self downActionFlagsForKey:keyDef] >= 0) {
        [super showPopupVariantsForKey:keyDef];
        return;
    }
    
    if (translucentBlackColor == nil) {
        translucentBlackColor = [[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:0.15f];
    }   
    
    [self->m_accentedKeyView removeFromSuperview];
    
    NSString* inputString = [self inputStringForKey:keyDef];
    UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
    
    NSDictionary* fullWidthVariants = UIKeyboardFullwidthVariants(inputString);
    if (fullWidthVariants == nil)
        return;
    
    [impl removeAutocorrectPrompt];
    [self deactivateActiveKeys];
    
    NSArray* strings = [fullWidthVariants objectForKey:@"Strings"]; // r4
    NSArray* keycaps = [fullWidthVariants objectForKey:@"Keycaps"]; // r8
    NSString* popup = [fullWidthVariants objectForKey:@"Popup"];    // r5
    
    if ( (keycaps == nil && strings == nil) || popup == nil )
        return;
    
    NSMutableArray* newStrings = [[strings mutableCopy] autorelease];
    [newStrings addObjectsFromArray:keycaps];
    
    self->m_accentedKeyView = [[UIAccentedCharacterView alloc] initWithFrame:keyDef->accent_frame
                                                                    variants:newStrings
                                                                   expansion:[popup isEqualToString:@"left"]
                                                                 orientation:[impl orientation]];
    [self addSubview:self->m_accentedKeyView];
    [self->m_accentedKeyView release];
    [self.window _setMouseDownView:self->m_accentedKeyView withEvent:nil];
}
```

## UIKeyboardInputManager\_ja\_JP ##
```
static BOOL imageMapInitialized = NO;                // bb584
static NSArray* defaultCandidates = nil;             // bb588
static CFCharacterSetRef endsWordCharSet = NULL;     // bb58c
static void* images = NULL;            // 9f588

@implementation UIKeyboardInputManager_ja_JP

-(id)init {
    if ((self = [super init])) {
        
        if (!imageMapInitialized) {
            
            NSString* bundlePath = [[NSBundle bundleForClass:[UIKeyboardInputManager_ja_JP class]] bundlePath];
            NSString* bundleName = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
            NSString* artworkPath = [bundlePath stringByAppendingPathComponent:[bundleName stringByAppendingPathExtension:@"artwork"]];
            
            UIRegisterMappedImageSetInDomain(images, artworkPath, bundlePath);
            imageMapInitialized = YES;
        }
        
        self.calculatesChargedKeyProbabilities = YES;
        self.usesCandidateSelection = YES;
        
    }
    
    return self;
}

-(KBInputManager*)initImplementation {
    if (self->m_impl == NULL)
        self->m_impl = new KBInputManagerAlphabet;
    return self->m_impl;
}

-(void)dealloc {
    endsWordCharSet = NULL;
    
    if (*(CFTypeRef*)0xBB590 != NULL) {
        CFRelease(*(CFTypeRef*)0xBB590);
        *(CFTypeRef*)0xBB590 = NULL;
    }
    
    if (*(CFTypeRef)0xBB594 != NULL) {
        CFRelease(*(CFTypeRef*)0xBB594);
        *(CFTypeRef*)0xBB594 = NULL;
    }
    
    [self->_kbws release];
    [self->_candidates release];
    [self->_convertStringForCurrentCandidates release];
    
    [defaultCandidates release];
    defaultCandidates = nil;
    
    [super dealloc];
}

-(void)addInput:(NSString*)input flags:(unsigned)flags point:(CGPoint)pt {
    if ([UIKeyboardImpl sharedInstance].shouldSkipCandidateSelection)
        return;
    
    if ([input length] == 0)
        return;
    
    if (!self->_EXPECT_CALL_TO_ADDINPUT) {
        self->_activeCharacterLength = 0;
    }
    
    self->_EXPECT_CALL_TO_ADDINPUT = NO;
    [self _addInput:input flags:flags point:pt];
}

-(void)addInputObject:(InputObject_ja_JP*)obj {
    if ([UIKeyboardImpl sharedInstance].shouldSkipCandidateSelection)
        return;
    
    [[UIKeyboardImpl sharedInstance] acceptCurrentCandidateIfSelected];
    
    if ([obj afterDelete]) {
        self->_activeCharacterLength = 1;
    }
    
    if (self->_activeCharacterLength != 0) {
        if (![obj confirmCurrent]) {
            for (NSUInteger i = 0; i < self->_activeCharacterLength; ++i)
                [self deleteFromInput];
        }
        self->_activeCharacterLength = 0;
    }
    
    NSString* str = [obj string];
    NSUInteger strLength = [str length];
    
    if (str != nil && strLength != 0) {
        if (obj.active)
            self->_activeCharacterLength = strLength;
    }
    self->_EXPECT_CALL_TO_ADDINPUT = YES;
}

-(void)_addInput:(NSString*)input flags:(unsigned)flags point:(CGPoint)pt {
    [self _cancelCandidatesThread];
    [super addInput:input flags:0 point:CGPointZero];
}

-(void)setInput:(id)input {
    [self _cancelCandidatesThread];
    self->_activeCharacterLength = 0;
}

-(void)setInputIndex:(NSUInteger)idx {}

-(void)deleteFromInput {
    [self _cancelCandidatesThread];
    
    -- self->_activeCharacterLength;
    [super deleteFromInput];
    
    if (self.inputCount != 0)
        return;
    
    [self->_candidates release];
    self->_candidates = nil;
    
    [self->_convertStringForCurrentCandidates release];
    self->_convertStringForCurrentCandidates = nil; 
}

-(void)clearInput {
    UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
    
    if (impl.shift && !impl.shiftLocked)
        impl.shift = NO;            
    
    [self _cancelCandidatesThread];
    
    [self->_candidates release];
    self->_candidates = nil;
    
    [self->_convertStringForCurrentCandidates release];
    self->_convertStringForCurrentCandidates = nil;
    
    self->_activeCharacterLength = 0;
    
    [super clearInput];
}

-(void)inputLocationChanged {
    [self _cancelCandidatesThread];
    
    [self->_candidates release];
    self->_candidates = nil;
    
    [self->_convertStringForCurrentCandidates release];
    self->_convertStringForCurrentCandidates = nil;
    
    self->_activeCharacterLength = 0;
    
    [super inputLocationChanged];
}

-(void)acceptInput { [super acceptInput]; }
-(NSString*)rawInputString { return super.inputString; }
-(NSString*)inputString { return [self rawInputString]; }
-(NSString*)_convertString { return [self rawInputString]; }

-(BOOL)stringEndsWord:(NSString*)str {
    if ([str length] != 1)
        return NO;
    if (endsWordCharSet == NULL)
        endsWordCharSet = CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline);
    
    return CFCharacterSetIsCharacterMember(endsWordCharSet, [str characterAtIndex:0]);
}

-(BOOL)shouldSendToKBWordSearch:(NSString*) str { return YES; }

-(NSArray*)_setCandidates:(NSArray*)candidates {
    [self->_candidates release];
    self->_candidates = nil;
    if ([candidates count] != 0)
        self->_candidates = [candidates retain];
    return self->_candidates;
}

-(NSArray*)candidates {
    if ([[UIKeyboardImpl sharedInstance] shouldSkipCandidateSelection])
        return nil;
    
    NSString* convertString = [self _convertString];
    NSArray* cand;
    if ([self shouldSendToKBWordSearch:convertString]) {
        cand = [self candidatesWithKBWordSearch:convertString];
        
    } else {
        [self _cancelCandidatesThread];
        
        cand = [self candidatesWithSyntheticStrings:convertString];
        [self->_candidates release];
        self->_candidates = [cand retain];
    }
    
    [self->_convertStringForCurrentCandidates release];
    self->_convertStringForCurrentCandidates = [convertString retain];
    
    return cand;
}

-(NSArray*)candidatesWithKBWordSearch:(NSString*)convertString {
    [self->_kbws getCandidatesAsyncForString:convertString target:self action:@selector(_notifyUpdateCandidates:)];
    
    if (defaultCandidates == nil) {
        defaultCandidates = [[NSArray alloc] initWithObjects:[NSNull null], nil];
    }
    
    if (self->_candidates != nil) {
        if ([_convertStringForCurrentCandidates length] != 0)
            return self->_candidates;
    }
    
    return defaultCandidates;
}

-(NSArray*)candidatesWithSyntheticStrings:(NSString*)convertString { return [self _candidatesWithSyntheticStrings:convertString force:NO]; }
-(NSArray*)_candidatesWithSyntheticStrings:(NSString*)convertString force:(BOOL)force {
    NSMutableArray* retval = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSString* precomposedString = [convertString precomposedStringWithCompatibilityMapping];
    
    NSMutableString* fullwidthConvertString = [convertString mutableCopy];
    CFStringTransform(fullwidthConvertString, NULL, kCFStringTransformFullwidthHalfwidth, true);
    
    // what?
    [fullwidthConvertString replaceOccurrencesOfString:@"\xe6\xff"
                                            withString:@"\xa9 "
                                               options:NSLiteralSearch
                                                 range:NSMakeRange(0, [fullwidthConvertString length])];
    
    id yomi = [self->_kbws kanaRomaPat:convertString];
    WordInfo* halfWord = [[WordInfo alloc] initWithWord:precomposedString
                                               withYomi:yomi
                                           inConnection:0
                                          outConnection:0
                                                 weight:0];
    WordInfo* fullWord = [[WordInfo alloc] initWithWord:fullwidthConvertString
                                               withYomi:yomi
                                           inConnection:0
                                          outConnection:0
                                                 weight:0];
    
    // 20 = convertString
    // 28 = fullwidthConvertString
    // 38 = precomposedString
    
    if (!force) {
        if ([convertString isEqualToString:precomposedString]) {
            if (![convertString isEqualToString:[convertString lowercaseString]]) {
                
                if (![precomposedString isEqualToString:fullwidthConvertString])
                    [retval addObject:fullWord];
                
            } else {
                NSString* upString = [precomposedString uppercaseString];
                if (![precomposedString isEqualToString:upString]) {
                    WordInfo* upWord = [[WordInfo alloc] initWithWord:upString
                                                             withYomi:yomi
                                                         inConnection:0
                                                        outConnection:0
                                                               weight:0];
                    [retval addObject:upWord];
                    
                    NSString* fullUpString = [fullwidthConvertString uppercaseString];
                    if (![fullwidthConvertString isEqualToString:fullUpString]) {
                        WordInfo* fullUpWord = [[WordInfo alloc] initWithWord:fullUpString
                                                                     withYomi:yomi
                                                                 inConnection:0
                                                                outConnection:0
                                                                       weight:0];
                        [retval addObject:fullUpWord];
                        [fullUpWord release];
                    }
                    
                    [upWord release];
                }
                
                if (![precomposedString isEqualToString:fullwidthConvertString])
                    [retval addObject:fullWord];
            }
        } else {
            if ([convertString isEqualToString:fullwidthConvertString]) {
                
                if (![convertString isEqualToString:[fullwidthConvertString lowercaseString]]) {
                    if (![precomposedString isEqualToString:fullwidthConvertString])
                        [retval addObject:halfWord];
                } else {
                    
                    // continue to mess with upper case & full width strings... 
                    // I DON'T CARE!
                    
                }
            } else {
                [retval addObject:halfWord];
                [retval addObject:fullWord];
            }
        }
    } else {
        [retval addObject:halfWord];
        [retval addObject:fullWord];
    }
    
    [fullWord release];
    [halfWord release];
    [fullwidthConvertString release];
    
    if ([retval count] == 0) {
        [retval addObject:[[[WordInfo alloc] initWithWord:convertString
                                                 withYomi:yomi
                                             inConnection:0
                                            outConnection:0
                                                   weight:0] autorelease]];
    }
    
    return [retval autorelease];
}

-(void)_cancelCandidatesThread { [_kbws cancel]; }
-(void)_notifyUpdateCandidates:(NSArray*)candidates {
    if (![[UIKeyboardImpl sharedInstance] shouldSkipCandidateSelection]) {
        [self _setCandidates:candidates];
        [[UIKeyboardImpl sharedInstance] updateCandidateDisplayAsyncWithCandidates:candidates forInputManager:self];
    }
}

-(BOOL)usesAutoDeleteWord { return NO; }
-(BOOL)suppliesCompletions { return YES; }
-(NSString*)stringForDoubleKey:(NSString*)key {
    if ([key isEqualToString:@" "])
        return @"  ";
    return [super stringForDoubleKey:key];
}
-(BOOL)shouldExtendPriorWord { return NO; }
-(void)_nop {}
-(void)configureKeyboard:(UIKeyboardLayoutRoman*)keyboard forCandidates:(NSArray*)candidates {
    [super configureKeyboard:keyboard forCandidates:candidates];
    if (self.inputCount == 0 || self->_candidates == nil)
        return;
    
    [keyboard setLabel:UIKeyboardStringConfirm forKey:UIKeyboardKeyReturn];
    [keyboard setTarget:[UIKeyboardImpl sharedInstance] forKey:UIKeyboardKeyReturn];
    [keyboard setAction:@selector(acceptCurrentCandidate) forKey:UIKeyboardKeyReturn];
    
    [keyboard setLabel:UIKeyboardStringSpace forKey:UIKeyboardKeySpace];
    [keyboard setTarget:self forKey:UIKeyboardKeySpace];
    [keyboard setAction:@selector(_nop) forKey:UIKeyboardKeySpace];
}

@end
```