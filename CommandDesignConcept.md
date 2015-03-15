# Introduction #

⌘ (Command) is a proposed MobileSubstrate-based application to solve [issue 10](https://code.google.com/p/networkpx/issues/detail?id=10) and allows copying from static labels. In fact, it is a generalized solution like Mac OS's [services menu](http://en.wikipedia.org/wiki/Services_menu). It will be independent of iKeyEx, but I'll provide this app alongside ℏClipboard.

Like iKeyEx, ⌘ will be divided into two parts: the framework part "libcommandlets.dylib" and the hooker part "UIHooker-Command.dylib". Users should be allowed to add functionality, called **⌘lets**, to ⌘ like iKeyEx.

# User Interface and Interaction #

For text fields, ⌘ will add MagicPad-style selection. After the selection there will be a "⌘ button" next to it.

![http://xae.xanga.com/76ff375630532230973774/w182066554.png](http://xae.xanga.com/76ff375630532230973774/w182066554.png)

The "⌘ button" should also show when double tapping on an empty place.
Clicking on it shows an action menu.

![http://x04.xanga.com/a78f065038333230974391/w182067085.png](http://x04.xanga.com/a78f065038333230974391/w182067085.png)

For static labels, selection is difficult to implement, so ⌘ would probably not support it. But a hook will still be installed so that the action menu will be called up when the user double/triple tap on it.

## Preferences ##

Some people may want to full-fledged extension, while some people just need a no-fringe copy & paste. The ⌘lets should be allowed to rearranged and enabled/disabled by users.

In the Preferences, there will be an additional item "⌘ (Command)" that allows rearranging and regrouping ⌘lets.

Besides rearrangement, users are allowed to set whether to enable ⌘ and the activation gestures.

| **Action** | **Allowed guestures** |
|:-----------|:----------------------|
| Start selection | Double tap / Long hold |
| Call action menu in text field | Immediately / ⌘ Button / Double tap / Long hold |
| Call action menu in label | Double tap / Long hold / Triple tap |

# File Structure #

⌘'s file structure would be like this:

```
/
 Library/
  MobileSubstrate/
   DynamicLibraries/
    UIHooker-Command.dylib
    UIHooker-Command.plist
    PrefHooker-Command.dylib
    PrefHooker-Command.plist
  Command/
   preference.plist
   Commandlets/
    Clipboard.commandlet/
     Info.plist
     Copy.plist
     Cut.plist
     Paste.plist
     ...
    Google.commandlet/
     Google.plist
     Google.sh
    ...
 System/
  Library/
   PreferenceBundles/
    CommandPreferences.bundle/
     <whatever it should be here>
 usr/
  lib/
   libcommandlets.dylib
```

## Declaring ⌘lets ##

⌘let definitions are stored in /Library/Command/Commandlets/ as modern bundles (i.e. ordinary directories with a definite structure). All these ⌘let bundles must have file name `*.commandlet`. A ⌘let bundles can contain multiple ⌘lets to reduce code duplication for similar functions.

As usual an Info.plist should be provided. There is only one required key in the Info.plist, `CMLCommandlets`, which is an array of ⌘lets this bundle provides. For example, in Clipboard.commandlet, the Info.plist contains exactly these content:
```
{
CMLCommandlets = (Copy, Cut, Paste);
CFBundleExecutable = Clipboard;
}
```
This means Clipboard.commandlet provides the Copy, Cut and Paste ⌘lets.

If the Info.plist is not provided, it is assumed that the content is
```
{
CMLCommandlets = (<filename>);
}
```

## ⌘let plist format ##

⌘lets will be specified through a property list. The content is like this:

```
# for paste.plist
 {
   title = "Paste";
   type = "lib";
   call = "pasteEntry";
   capabilities = ("textfield.selection.defined");
 }
# for google.plist
 {
   title = "Google";
   bin = "google.sh";
   type = "exec";
   app = ("com.apple.MobileSafari", "com.yourcompany.myFox");
 }
```

> _struct_ `<Commandlet.plist>` ::
<table cellpadding='5' border='1'>
<tr>
</li></ul>> <th>key</th>
> <th>type</th>
> <th>meaning</th>
> <th>default</th>
> <th>depends</th>
</tr>
<tr>
> <td>title</td>
> <td>string</td>
> <td>localizable string</td>
> <td>The ⌘let's display name</td>
> <td><i>file name</i></td>
> <td>--</td>
</tr>
<tr>
> <td>NSMenuItem</td>
</tr>
<tr>
> <td>bin</td>
> <td>string</td>
> <td>file path</td>
> <td>If declared as <code>"exec"</code> or <code>"pipe"</code>, the shell script/executable that will be used when user clicks on the ⌘let's button.</td>
> <td>"<i>file name</i><code>.sh</code>"</td>
> <td>--</td>
</tr>
<tr>
> <td>type</td>
> <td>string</td>
> <td>{<code>"lib"</code>, <code>"exec"</code>, <code>"service"</code>, <code>"pipe"</code>}</td>
> <td>Type of binary. Equals:<ul><li><code>lib</code> if <i>bin</i> is treated as a library</li><li><code>exec</code> if treated as executable or shell script</li><li><code>service</code> if treated as a <a href='http://developer.apple.com/documentation/Cocoa/Conceptual/SysServices/Concepts/architecture.html'>Mac OS X system service</a></li><li><code>pipe</code> if treated as an I/O pipe.</li></ul></td>
> <td><code>"exec"</code></td>
> <td>--</td>
</tr>
<tr>
> <td>app</td>
> <td>array</td>
> <td>...of bundle identifiers</td>
> <td>The applications that the ⌘let can be performed without quitting. If the current application is different from the specified ones, the button shall appear in red, to indicate that the current program will quit. Don't fill in this array if the ⌘let does not launch any applications.</td>
> <td><i>nil</i></td>
> <td>--</td>
</tr>
<tr>
> <td>icon</td>
> <td>string</td>
> <td>file path</td>
> <td>The icon to use when the ⌘let is shown on the ⌘bar. The icon should be 22×22 in size and expects a white background.</td>
> <td>"<i>file name</i><code>.png</code>"</td>
> <td>--</td>
</tr>
<tr>
> <td>capabilities</td>
> <td>array</td>
> > <td>...of <code>&lt;capability&gt;</code></td>

> <td>Capabilities the ⌘let must meet so that it is enabled. Leave it undefined to make it always available.</td>
> <td><i>nil</i></td>
> <td>--</td>
</tr>
<tr>
> <td>string</td>
> <td>selector</td>
> <td>Dynamically determine if the ⌘let is available. (Details to be discussed.)</td>
</tr>
<tr>
> <td>call</td>
> <td>string</td>
> <td>When <i>type</i> is <code>lib</code>, the function name to call.</td>
> <td><i>file name</i></td>
> <td>--</td>
</tr>
<tr>
> <td>NSMessage</td>
> <td>string</td>
> <td>When <i>type</i> is <code>service</code>, the message selector name to call.</td>
> <td><i>file name</i></td>
> <td>--</td>
</tr>
<tr>
> <td>NSPortName</td>
> <td>string</td>
> <td>When <i>type</i> is <code>service</code>, the port name to use.</td>
> <td><i>file name</i></td>
> <td>--</td>
</tr>
</table></li></ul>


<blockquote><i>enum</i> <code>&lt;capability&gt;</code> ::<br>
<ul><li>"textfield.selection.empty"<br>
</li><li>"textfield.selection.selected"<br>
</li><li>"textfield.selection.undefined"<br>
</li><li>"textfield.selection.defined"<br>
</li><li>"textfield.empty"<br>
</li><li>"textfield.filled"<br>
</li><li>"textfield.secure"<br>
</li><li>"textfield.insecure"<br>
</li><li>"textfield.singleline"<br>
</li><li>"textfield.multiline"<br>
</li><li>"textfield"<br>
</li><li>"label"<br>
</li><li>"url"<br>
</li><li>"notarget"</li></ul></blockquote>

<h2>⌘let as a <code>lib</code></h2>

When the ⌘let is run as a library, the function with symbol specified in <i>call</i> will be called.<br>
<br>
That function must have signature<br>
<pre><code>CMLFurtherAction run (NSString**    pSelectedContent,<br>
                      NSRange       selectedRange,<br>
                      id            target,<br>
                      NSDictionary* cmdletParams);<br>
</code></pre>

<i>target</i> may be nil if the ⌘let is invoked programmatically. If not, its class must be a subclass of DOMNode or UIView.<br>
<br>
You can change the selected string while the program runs. If you do so, you <i>must</i> release the old string and retain the new string, like this:<br>
<pre><code>...<br>
[*pSelectedContent release];<br>
*pSelectedContent = [[NSString alloc] initWithString:@"new content"];<br>
...<br>
</code></pre>
This has no effect when <i>target</i> is nil or read-only.<br>
<br>
<i>pSelectedContent</i> should never point to nil. If the ⌘let is invoked from an empty selection, <i>pSelectedContent</i> will contain the whole text field. Nevertheless, replacing the content in this situation only inserts text at the cursor, instead of replacing the whole string. You can check <code>(selectedRange.length == 0)</code> to see if the selection is actually empty. To force selecting the whole string, set the flag <code>CMLActionSelectAllNow</code> in the returned value as discussed below.<br>
<br>
<code>CMLFurtherAction</code> is an enum indicated any further action to do. It has no effect (except for <code>CMLActionShowMenu</code>) if the target is static text. Anything resulting in a nonzero range in a DOM element will be invisible.<br>
<table><thead><th> <b>value</b> </th><th> <b>meaning</b> </th></thead><tbody>
<tr><td> CMLActionDefault = 0 | Default: Update selection to surround new text |
| CMLActionCollapseToStart | Collapse selection to the beginning. |
| CMLActionCollapseToEnd | Collapse selection to the end. |
| CMLActionCollapseToOldEnd | Collapse selection to the end before text is replaced. |
| CMLActionReuseOldSelection | Reuse the old selection. |
| CMLActionMoveToBeginning | Set the selection to the start of text field. |
| CMLActionMoveToEnding | Set the selection to the end of text field. |
| CMLActionSelectAll | Select the whole text field. |
| CMLActionSelectToBeginningFromStart | Select to beginning from start. |
| CMLActionSelectToBeginningFromEnd | Select to beginning from end. |
| CMLActionSelectToEndingFromStart | Select to ending from start. |
| CMLActionSelectToEndingFromEnd | Select to ending from end. |
| CMLActionAnchorAtStart = 64 | Anchor the selection to the start point of the new selection. Subsequent movements in the text field will be interpreted as changing end point of selection, instead of moving the cursor, until another ⌘let is called. |
| CMLActionAnchorAtEnd = 128 | Anchor the selection to the end point of the new selection. |
| CMLActionShowMenu = 4096 | Show the action menu. |
| CMLActionReplaceAll = 8192 | Replace content of the whole text field instead of just the selection. Equivalent to selecting the whole text field before text replacement begins. |

`CMLActionShowMenu`, `CMLActionReplaceAll` and `CMLActionAnchor`_xxx_ can be combined with the rest of the actions.

If the ⌘let is a lib, the calling will be **blocking**, meaning the active application cannot continue until the ⌘let function finishes.

## ⌘let as an `exec` ##

If _type_ is declared as an `exec`, its `main()` will be called with these arguments:

| `argv[1]` | The selected string |
|:----------|:--------------------|
| `argv[2]` | The starting location of selected range |
| `argv[3]` | The length of selected range |
| `argv[4]` | The whole string in the target |

All of these are converted to a UTF8 string.

An exec ⌘let **cannot** return or change any arguments. Also, the call can be **non-blocking**, i.e. the program flow can continue without waiting the ⌘let to finish.

> But we need to check if `fork()` and `execl()` are allowed in sandboxed applications.

## ⌘let as a `service` ##

Mac OS X system services is a plug-in system based on the `NSPasteboard` class. The services are located in the Services submenu in the application menu in the Mac OS X. When the user selected some text and clicked on a service, the selected text will be copied to the service, processed, and pasted back to the application. This is exactly like how ⌘let works. You may read http://developer.apple.com/documentation/Cocoa/Conceptual/SysServices/Concepts/architecture.html for the detail of system services.

Therefore, ⌘ also allows ⌘let to exist as system services to reduce porting time. All you have to do is to create a dylib or bundle which provides a message having the signature:
```
-(void)serviceName:(NSPasteBoard*)pasteboard userData:(NSString*)data error:(NSString**)error;
```
where _serviceName_ is the string you provided in the the _NSMessage_ key of the plist file.

The class containing this message must be first registered in the dylib/bundle initializer with
```
static ServiceProviderClass* serviceProviderObj = nil;
...
void init () {
  serviceProviderObj = [[ServiceProviderClass alloc] init];
  NSRegisterServicesProvider(serviceProviderObj, @"portName"); // <---- Call this line
  ...
  atexit(&releaseServiceProviderObj);
  ...
}
```
where _portName_ is the string you provided in the _NSPort_ key of the plist file.

> You _cannot_ call `-[UIApplication setServicesProvider:]`, and it won't be supported either.

Currently _userData_ will always be passed as `nil`. You can return an autorelease'd NSString to _error_ to tell the user something is wrong. If the user opts in for showing services errors, a UIAlertView will pop up alerting the user about this. In any way, the message will be NSLog-ed.

There is no way to change the selection nor querying the target performing the ⌘let in a service.

To read the text copied to the NSPasteboard, call `[pasteboard stringForType:NSStringPboardType]`, and to return the text call `[pasteboard setString:@"text" forType:NSStringPboardType]`. Due to current limitation, the pasteboard data type will always be ignored and the data copied will always be a string.

Like libs, a service ⌘let is **blocking**.

## ⌘let as a `pipe` ##

If _type_ is declared as `pipe`, the selected string will be feed into `stdin`, and you are expected to print the processed result into `stdout`. A pipe ⌘let is **blocking**.

## Localization ##

⌘lets can provide localizations in the `(lang code).lproj` files as usual. The specific localizations should be named as `(file name).strings`

One particular attribute that should be localized is the _title_ key.

# libcommandlets.dylib API #

The following API shall be provided with libcommandlet.dylib:

```
#import <Foundation/Foundation.h>
#import <UIKit2/UIKeyboardInput.h>

typdef enum CMLFurtherAction { ... } CMLFurtherAction;

@interface CMLCommandlet
+(void)performFurtherAction:(CMLFurtherAction)theActions onTarget:(NSObject<UIKeyboardInput>*)target;
+(void)callCommandlet:(NSString*)cmdletName withTarget:(NSObject<UIKeyboardInput>*)target;
+(void)callCommandlet:(NNString*)cmdletName withString:(NSString*)selectedString;

+(void)interceptCommandlet:(NSString*)cmdletName toInstance:(NSObject*)interceptor action:(SEL)aSelector;
+(void)uninterceptCommandlet:(NSString*)cmdletName fromInstance:(NSObject*)interceptor action:(SEL)aSelector;

+(void)registerUndoManager:(CMLUndoManager*)manager;
+(CMLUndoManager*)undoManagerForTarget:(NSObject<UIKeyboardInput>*)target;
@end;
```

## ⌘let Interception ##

An application may want to intercept ⌘let calls, e.g. to integrate ⌘ into the application's custom copy and paste environment.

The selector to parse must have this signature:

```
  -(BOOL)callbackWithCommandlet:(NSString*)cmdletName
                 selectedString:(NSString**)pSelectedString
                          range:(NSRange*)pSelectedRange
                         target:(NSObject<UIKeyboardInput>*)pTarget;
```

You can change any parameters in the interceptor. If you changes the selected string, remember to release the old instance and retain the new one.

The interceptor can return NO to cancel the propagation. The ⌘let and all subsequent interceptors will not be called if this returned NO.

A ⌘let can register multiple interceptors. They will be called in reverse registration order.

As a good practice, remember to unintercept any interceptor before the program finishes.


## Undo/Redo Management ##
```
@interface CMLUndoManager {
  NSMutableArray* operations;
  NSUInteger undoLimit;
  NSUInteger currentStep;
  NSObject<UIKeyboardInput>* target;
  NSDate* lastMicromodTime;
  NSTimeInterval micromodUpdateInterval;
}
@property(assign) NSUInteger undoLimit;
@property(assign,readonly,getter=isUndoable) BOOL undoable;
@property(assign,readonly,getter=isRedoable) BOOL redoable;
@property(assign,readonly) NSObject<UIKeyboardInput>* target;
@property(assign) NSInterval micromodUpdateInterval;
+(CMLUndoManager*)managerWithTarget:(NSObject<UIKeyboardInput>*)aTarget
+(CMLUndoManager*)managerWithTarget:(NSObject<UIKeyboardInput>*)aTarget undoLimit:(NSUInteger)limit;
+(CMLUndoManager*)managerWithTarget:(NSObject<UIKeyboardInput>*)aTarget undoLimit:(NSUInteger)limit micromodUpdateInterval:(NSTimeInterval)interval;
-(id)initWithTarget:(NSObject<UIKeyboardInput>*)aTarget undoLimit:(NSUInteger)limit micromodUpdateInterval:(NSTimeInterval)interval;;
-(void)dealloc;
-(void)undo;
-(void)redo;
-(void)setString:(NSString*)str;
-(void)appendString:(NSString*)str;
-(void)deleteCharactersCount:(NSUInteger)charsToDelete;
@end
```


You may use a `CMLUndoManager` to track changes to the text field when you want to provide undo/redo capability in your extension. Note that when using ⌘ alone without interception no undo managers will be used internally, that means ⌘ itself does not provide undo/redo capability.

> Later versions of ⌘ may provide built-in undo/redo by tracking keyboard input as well.

To use the undo manager, you have to first find the subview of the text field that actually sets ranges. Let's say it is stored in the variable _target_. Now call

```
  CMLUndoManager* myManager = [CMLUndoManager managerWithTarget:target];
  [CMLCommandlet registerUndoManager:target];
```

then any calls to ⌘lets that changes the input will be routed through `myManager` for tracking. Besides, you may want to track **micro-modifications** (micromod) such as entering a word or back-spacing a few characters. You can call

```
  [myManager appendString:@"word"];     // user typed "word".
  [myManager deleteCharactersCount:4];  // user deleted 4 characters
```

to track these micromods.

Whenever you want to undo 1 step, call
```
  [myManager undo];
```
and to redo call `[myManager redo]`. You should check if it is undoable/redoable with the `undoable` and `redoable` properties.

If an undo manager is registered with a target that is already held by another undo manager, the old one will be immediately disassociated and released.

Note that the `CMLUndoManager` only holds a weak reference of the target, and won't retain it.

# Role of ℏClipboard #
As ⌘ can do a many similar job as ℏClipboard, after ⌘ is released the back-end of ℏClipboard will be pulled away, and the UI will be converted to a front-end of ⌘.