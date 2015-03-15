(You should be familiar with Objective-C and the official iPhone SDK framework first.)

# Fundamentals #

In the iPhoneOS, the so-called **keyboards** or **input modes** are actually composed of 2 parts: the **layout** and the **input manager**

## Layout ##

The **layout** is a view that interacts with user input and process commands with the **keyboard implementation** (`UIKeyboardImpl`). Layouts must be implemented as subclasses of `UIKeyboardLayout`, which in turn is a subclass of `UIView`.

The standard keyboard layouts you're using are all subclasses of the more specialized `UIKeyboardLayoutRoman`. It has several `UIKeyboardSublayout` members which does the actual rendering.

There are also layouts not derived from `UIKeyboardLayoutRoman`. The emoji keyboard is a prominent example.

## Input Manager ##
An **input manager** is an abstract class that transforms key press commands to actual inputs. The auto-correction prompt is an input manager in action.

CJK keyboards usually rely on input managers because of the vast amount of characters.

Input managers are usually subclasses of `UIKeyboardInputManager`. If you're working with a standard keyboard layout, you should subclass the more specialized `UIKeyboardInputManagerAlphabet`. This class will automatically handle word frequency analysis for you.

> If you are not subclassing from `UIKeyboardInputManagerAlphabet`, but wants to use a standard keyboard layout (including layout.plist method), you must implement the `-(void)setShallowPrediction:(BOOL)sp` message to avoid crashing.

Handwriting regconition is also the job of an input manager.

# Keyboard Bundles #
iKeyEx keyboard extensions are packaged in **keyboard bundles**. Keyboard bundles are simply directories (folders) with a definite structure, i.e. a [bundle](http://en.wikipedia.org/wiki/Bundle_%28NEXTSTEP%29). All keyboard bundles must have an `Info.plist` file to describe themselves, for example.

Keyboard bundles must reside in `/Library/iKeyEx/Keyboards/`, and have an extension of `.keyboard`.

> Example: The keyboard bundle for ℏClipboard is placed in `/Library/iKeyEx/Keyboards/hClipboard.keyboard/`

Note that the iPhoneOS file system is **case sensitive**. Make sure you follow the same capitalization for all files listed here.

Together with the "iKeyEx:" prefix, the file name will become the **input mode name** of the keyboard extension. It does not have to match the display name, since the latter will be specified in the `Info.plist` file.

> The input mode name is used to uniquely identify a keyboard. For example, the English (US) keyboard's input mode name is `en_US`, Traditional Chinese Handwriting is `zh_Hant-HWR`, and ℏClipboard is `iKeyEx:hClipboard`.

The input mode name should only contain alphanumeric symbols, `_` (underscore) and - (hyphen). iKeyEx uses input mode names starting with `__` (2 underscores) for internal keyboards, so you should avoid using prefixing underscores in the mode name.

## Info.plist ##
`Info.plist` is the description of the keyboard extension. It is a [property list](http://developer.apple.com/documentation/Cocoa/Conceptual/PropertyLists/Introduction/chapter_1_section_1.html). Currently, iKeyEx recognizes the following keys:

> _struct_ `<Info.plist>` ::
<table cellpadding='5' border='1'>
<tr>
</li></ul>> <th>key</th>
> <th>type</th>
> <th>meaning</th>
> <th>default</th>
> <th>depends</th>
</tr>
<tr>
> <td>CFBundleDisplayName</td>
> <td>string</td>
> <td>localizable string</td>
> <td>Display name of the keyboard.</td>
> <td><i>current input mode name</i></td>
> <td>--</td>
</tr>
<tr>
> <td>UIKeyboardLayoutClass</td>
> <td>string</td>
> <td><code>&lt;layout class&gt;</code></td>
> <td>Layout class to use. To be described below.</td>
> <td><code>"=en_US"</code></td>
> <td>--</td>
</tr>
<tr>
> <td>UIKeyboardInputManagerClass</td>
> <td>string</td>
> <td><code>&lt;input manager class&gt;</code></td>
> <td>Input manager class to use. To be described below.</td>
> <td>--</td>
> <td>--</td>
</tr>
<tr>
> <td>CFBundleExecutable</td>
> <td>string</td>
> <td>file path</td>
> <td>Binary file that contains all executable code</td>
> <td><i>file name</i></td>
> <td><i>UIKeyboardLayoutClass</i> is dictionary of (string, class name) pairs<br /><b>or</b> <i>UIKeyboardInputManagerClass</i> is class name</td>
</tr>
<tr>
> <td>PSBundle</td>
> <td>string</td>
> <td>file path</td>
> <td>Sub-bundle that contains the preference pane.</td>
> <td>--</td>
> <td>--</td>
</tr>
</table></li></ul>

The display name will be shown when switching keyboards using the international button, and also in the Settings application. If missing, the file name will be used as the display name.<br>
<br>
<h3>UIKeyboardLayoutClass</h3>
In iKeyEx the layout class can be specified in 3 ways: <i>referred</i>, <i>layout.plist</i> and writing code.<br>
<br>
Referred means the layout of this keyboard will use an existing one. You fill in a string starting with "=", then the input mode name to inherit the layout.<br>
<br>
<blockquote>If you want to use the standard QWERTY keyboard layout, fill in <code>"=en_US"</code> for this field.</blockquote>

layout.plist means the layout will be dynamically generated using the file in this field. It will be further discussed in <a href='Creating_layout_plist.md'>(Developers) How to create layout.plist</a>.<br>
<br>
For total customization, you can write code yourself to manage the view. In this case, the CFBundleExecutable field should be filled, and the UIKeyboardLayout field should have a layout class name as value.<br>
<br>
You can assign different layouts to portrait and landscape layouts using a dictionary with keys Landscape and Portrait.<br>
<br>
<blockquote>Take 5-Row QWERTY as an example, both the Portrait and Landscape layouts are implemented by the two different classes, this field would be written as<br>
<pre><code>UIKeyboardLayoutClass = {<br>
  Portrait = "FiveRowQWERTYLayout";<br>
  Landscape = "FiveRowQWERTYLayoutLandscape";<br>
};<br>
</code></pre></blockquote>

If this field is missing, the standard QWERTY keyboard will be used as layout.<br>
<br>
<blockquote><i>union</i> <code>&lt;layout class&gt;</code> ::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th>type</th>
<th>meaning</th>
</tr>
<tr>
<td>string</td>
<td>`/^=/`</td>
<td>Refered layout.</td>
</tr>
<tr>
<td>string</td>
<td>file path and `/\.plist$/`</td>
<td>Specification for dynamically generated standard keyboard (layout.plist).</td>
</tr>
<tr>
<td>string</td>
<td>_class name_</td>
<td>Code-generated layout.</td>
</tr>
<tr>
<td>dictionary</td>
<td>{`Landscape` = `<layout class>`; `Portrait` = `<layout class>`}</td>
<td>Use different layout class for landscape and portrait positions.</td>
</tr>
</table></blockquote>

<h3>UIKeyboardInputManagerClass</h3>
Like UIKeyboardLayoutClass, this field also can be referred using the same "=xxx" syntax. You can also write the class name of your own input manager class here.<br>
<br>
If this field is missing, no input managers will be used.<br>
<br>
<blockquote><i>union</i> <code>&lt;input manager class&gt;</code> ::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th>type</th>
<th>meaning</th>
</tr>
<tr>
<td>string</td>
<td>`/^=/`</td>
<td>Refered input manager.</td>
</tr>
<tr>
<td>string</td>
<td>class name</td>
<td>Code-generated manager.</td>
</tr>
</table></blockquote>

<h2>PSBundle</h2>

Use the <i>PSBundle</i> key to hook a preference pane. See source code of ℏClipboard and 5-Row QWERTY for detail.<br>
<br>
<blockquote>-- TO BE DONE --</blockquote>

<h2>variants.plist</h2>
This is an optional file that specify the <b>variants</b> of each key, when you're using a referred layout, layout.plist or a subclass of <code>UIKeyboardLayoutRoman</code>.<br>
<br>
Variants are the list of accented characters (e.g. Z Ź Ž Ż) you'll see when you hold a key (e.g. Z). It contains a dictionary of arrays which maps each key to the corresponding list. You can see the source code of MathTyper to understand how this file works.<br>
<br>
<blockquote>Note that the variants are <i>case-sensitive</i>. You'll have to specify both the variants of a lower and upper case letter separately.</blockquote>

On Firmware 2.2, the variants for A, C, E, I, L, N, O, S, U, Y and Z will be automatically provided, so you don't need to write a <code>variants.plist</code> for it.<br>
<br>
<blockquote>As an example, the <code>variants.plist</code> for European languages may be</blockquote>

<pre><code>{<br>
  A = ("A", "À", "Á", "Â", "Ä", "Æ", "Ã", "Å", "Ą");<br>
  a = ("a", "à", "á", "â", "ä", "æ", "ã", "å", "ą");<br>
# etc.<br>
}<br>
</code></pre>

You can provide an array to split label and actual output, e.g.<br>
<pre><code>{<br>
  "w" = (w, ("www.wikipedia.org", wiki), www)<br>
}<br>
</code></pre>

<blockquote><i>pairs</i> <code>&lt;variants.plist&gt;</code> ::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th></th>
<th>type</th>
<th>meaning</th>
</tr>
<tr>
<td>**key**</td>
<td>string</td>
<td>Text to give the variants list.</td>
</tr>
<tr>
<td>**value**</td>
<td>array</td>
<td>...of `<variant>`s</td>
<td>List of variants.</td>
</tr>
</table></blockquote>

<blockquote><i>union</i> <code>&lt;variant&gt;</code> ::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th>type</th>
<th>meaning</th>
</tr>
<tr>
<td>string</td>
<td>Simple variant. Both label and actual output will use this same string.</td>
</tr>
<tr>
<td>array</td>
<td>...of strings</td>
<td>Variant with label and actual output being distinct.</td>
</tr>
</table></blockquote>

<h2>strings.plist</h2>
This is an optional file that specify the <b>localized strings</b> of some common words, e.g. Return, Space, etc.<br>
<br>
The format is the same as <code>/System/Library/Frameworks/UIKit.framework/Keyboard-***.plist</code>.<br>
<br>
<h1>Localization</h1>
Since in essence keyboard bundles are just regular bundles, the resources can be localized like a regular bundle.<br>
<br>
Please see the source code of ℏClipboard or consult relevant <a href='http://developer.apple.com/DOCUMENTATION/MacOSX/Conceptual/BPInternational/BPInternational.html'>Apple documents</a> on how to localize resources.<br>
<br>
<h1>Loading Keyboard Bundles</h1>

Keyboard bundles are handled in the <code>KeyboardLoader</code> module of iKeyEx. In case you want to refer to resources in the bundle, you can import <code>&lt;iKeyEx/KeyboardLoader.h&gt;</code>, and call the class method <code>[KeyboardBundle activeBundle]</code> to obtain the current KeyboardBundle object.<br>
<br>
You can access the following properties in a KeyboardBundle:<br>
<table><thead><th> <b>Type</b> </th><th> <b>Property name</b> </th><th> <b>Usage</b> </th></thead><tbody>
<tr><td> `UIKeyboardInputManager*` | manager | The current `UIKeyboardInputManager` instance. |
| `Class` | layoutClassPortrait | The current layout class in portrait orientation. |
| `Class` | layoutClassLandscape | The current layout class in landscape orientation. |
| `NSString*` | displayName | The localized display name. |
| `NSDictionary*` | variants | The variants. |
| `NSBundle*` | bundle | The underlying bundle object. |