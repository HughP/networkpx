

# Introduction #

layout.plist is a method to specify a keyboard layout using just simple a property list. This is the preferred method if (1) the layout does not exist already, and (2) you want to imitate the original look as much as possible.

With layout.plist, you only need to decide the arrangement and position of the keys. Then iKeyEx will take care of everything else for you.

You may want to see the source code of Colemak as an example of using layout.plist, and that of 5 Row QWERTY for all the advanced features.

> Please refer to PlistSpec for how to use a property list and the specification notation used here.

# 3.0 Compatibility #
In 3.0, iKeyEx will switch to use UIKeyboardLayoutStar instead. The following layout.plist features cannot be ported to the new system:
  * Overloading PhonePad / PhonePadAlt layouts may cause the keyboard not acting correctly.
  * popups and shiftedPopups are not supported.
  * Due to a font problem, some texts may not be shown properly.
  * Key charges seems cannot be disabled.
  * There can be no images on keys.

# Fundamentals #

On the iPhoneOS, there are 11 types of sub-layouts:
  * Alphabet
  * Numbers
  * PhonePad
  * PhonePadAlt
  * NumberPad
  * URL
  * URLAlt
  * SMSAddressing
  * SMSAddressingAlt
  * EmailAddress
  * EmailAddressAlt
(SMSAddressing is also known as "Name Phone Pad" in the official SDK.)

Except PhonePad, PhonePadAlt and NumberPad layouts, all of the 8 sub-layouts have 4 rows of keys. The layout.plist method is designed to create these kinds of sub-layout (and you shouldn't overload PhonePad and alike anyway).

In iKeyEx terminology, these 8 sub-layouts are called **standard keyboards**. The 4 rows of keys are named Row 0 to 3 from top to bottom respectively. On the standard keyboard there are ordinary keys (e.g. Q, W, E, etc.) and 5 **special keys**:
  * Shift key (⇧)
  * Delete key (⌫)
  * Plane chooser button (ABC/123) + International button (Globe)
  * Space bar
  * Return key
When you create a standard keyboard using layout.plist, the shift and delete keys must stay on Row 2 and the rest must be on Row 3. The position of the last 3 keys are also fixed.

# Structure of layout.plist #

To create a layout.plist layout, you must fill in the file name of the layout.plist in the UIKeyboardLayout field of `Info.plist`, e.g.
```
  UIKeyboardLayout = "layout.plist";
```
The layout.plist file does not have to be named like this, but it must have an extension of `.plist`.

## Overloading Sub-layouts ##
layout.plist is, of course, a property list. At the root it is a dictionary of dictionaries. The keys are the name of the sub-layouts to be overloaded. Typically a layout.plist will look like this:
```
{
  Alphabet        = { ... };
  URL             = { ... };
  SMSAddressing   = { ... };
  EmailAddressing = { ... };
}
```
which means these 4 sub-layouts will be customized according to the content of this file. The 7 sub-layouts not mentioned will keyboard the original appearance of the standard QWERTY layout.

The value of each key is a dictionary consists of the following properties:

> _struct_ `<sublayout>` ::
<table cellpadding='5' border='1'>
<tr>
</li></ul>> <th>key</th>
> <th>type</th>
> <th>meaning</th>
> <th>default</th>
> <th>depends</th>
</tr>
<tr>
> <td>rows</td>
> <td>integer</td>
> <td><i>value</i> ≥ 2</td>
> <td>How many rows of keys are there in this sublayout.</td>
> <td>4</td>
> <td>--</td>
</tr>
<tr>
> <td>texts</td>
> <td>array</td>
> <td>...of <code>&lt;text row&gt;</code>s</td>
> <td>Text typed for each key in each row. </td>
> <td>nil</td>
> <td>--</td>
</tr>
<tr>
> <td>shiftedTexts</td>
> <td>array</td>
> <td>...of <code>&lt;text row&gt;</code>s</td>
> <td>Text typed for each key in each row when the shift key is held.</td>
> <td><i>texts</i></td>
> <td>--</td>
</tr>
<tr>
> <td>labels</td>
> <td>array</td>
> <td>...of <code>&lt;text row&gt;</code>s</td>
> <td>Label displayed on each key in each row.</td>
> <td><i>texts</i></td>
> <td>--</td>
</tr>
<tr>
> <td>shiftedLabels</td>
> <td>array</td>
> <td>...of <code>&lt;text row&gt;</code>s</td>
> <td>Label displayed on each key in each row when the shift key is held.</td>
> <td><i>shiftedTexts</i></td>
> <td>--</td>
</tr>
<tr>
> <td>popups</td>
> <td>array</td>
> <td>...of <code>&lt;text row&gt;</code>s</td>
> <td>Popup character shown when each key is pressed for each row.</td>
> <td><i>texts</i></td>
> <td>--</td>
</tr>
<tr>
> <td>shiftedPopups</td>
> <td>array</td>
> <td>...of <code>&lt;text row&gt;</code>s</td>
> <td>Popup character shown when each key is pressed for each row when the shift key is held.</td>
> <td><i>shiftedTexts</i></td>
> <td>--</td>
</tr>
<tr>
> <td>arrangement</td>
> <td>array</td>
> <td>...of integers</td>
> <td>Number of keys in each row.</td>
> <td>"Default"</td>
> <td>--</td>
</tr>
<tr>
> <td>string</td>
> <td><code>&lt;preset arrangements&gt;</code></td>
</tr>
<tr>
> <td>rowIndentation</td>
> <td>array</td>
> <td>...of <code>&lt;row indentation&gt;</code>s</td>
> <td>Free space on either sides in each row.</td>
> <td>"Default"</td>
> <td>--</td>
</tr>
<tr>
> <td>string</td>
> <td><code>&lt;preset row identations&gt;</code></td>
</tr>
<tr>
> <td>horizontalSpacing</td>
> <td>array</td>
> <td>...of reals</td>
> <td>Free space between 2 keys in that row. Specify a negative number if you want keys to be closer than default spacing.</td>
> <td>0</td>
> <td>--</td>
</tr>
<tr>
> <td>real</td>
</tr>
<tr>
> <td>hasSpaceKey</td>
> <td>boolean</td>
> <td>Whether the default space key is present. You should set this to 0 (✗) if you are implementing the URL or email sublayouts.</td>
> <td>✓</td>
> <td>--</td>
</tr>
<tr>
> <td>hasInternationalKey</td>
> <td>boolean</td>
> <td>Whether the plane switcher and international key are present.</td>
> <td>✓</td>
> <td>--</td>
</tr>
<tr>
> <td>hasReturnKey</td>
> <td>boolean</td>
> <td>Whether the return key is present.</td>
> <td>✓</td>
> <td>--</td>
</tr>
<tr>
> <td>hasShiftKey</td>
> <td>boolean</td>
> <td>Whether the shift key is present.</td>
> <td>✓</td>
> <td>--</td>
</tr>
<tr>
> <td>shiftKeyEnabled</td>
> <td>boolean</td>
> <td>Whether the shift key is enabled. You should set this to 0 (✗) if you are implementing the SMS sublayout.</td>
> <td>✓</td>
> <td><i>hasShiftKey</i> = ✓</td>
</tr>
<tr>
> <td>shiftKeyLeft</td>
> <td>real</td>
> <td>The position of the shift key from the left.</td>
> <td>0</td>
> <td><i>hasShiftKey</i> = ✓</td>
</tr>
<tr>
> <td>shiftKeyWidth</td>
> <td>real</td>
> <td>The width of the shift key button.</td>
> <td>42</td>
> <td><i>hasShiftKey</i> = ✓</td>
</tr>
<tr>
> <td>shiftKeyRow</td>
> <td>integer</td>
> <td>Which row the shift key should reside in.</td>
> <td><i>rows</i> − 2</td>
> <td><i>hasShiftKey</i> = ✓</td>
</tr>
<tr>
> <td>shiftStyle</td>
> <td>string</td>
> <td>{"<code>Default</code>", "<code>Symbol</code>", "<code>123</code>"}</td>
> <td>Shift key style. Default = <code>[⇧]</code>; Symbol = <code>[#+=]</code>; 123 = <code>[123]</code>.</td>
> <td>"Default"</td>
> <td><i>hasShiftKey</i> = ✓</td>
</tr>
<tr>
> <td>hasDeleteKey</td>
> <td>boolean</td>
> <td>Whether the delete key is present.</td>
> <td>✓</td>
> <td>--</td>
</tr>
<tr>
> <td>deleteKeyRight</td>
> <td>real</td>
> <td>The position of the delete key from the right.</td>
> <td>0</td>
> <td><i>hasDeleteKey</i> = ✓</td>
</tr>
<tr>
> <td>deleteKeyWidth</td>
> <td>real</td>
> <td>The width of the delete key button.</td>
> <td>42</td>
> <td><i>hasDeleteKey</i> = ✓</td>
</tr>
<tr>
> <td>deleteKeyRow</td>
> <td>integer</td>
> <td>Which row the delete key should reside in.</td>
> <td><i>rows</i> − 2</td>
> <td><i>hasDeleteKey</i> = ✓</td>
</tr>
<tr>
> <td>registersKeyCentroids</td>
> <td>boolean</td>
> <td>Registers key centroids or not.</td>
> <td>✓</td>
> <td>--</td>
</tr>
<tr>
> <td>usesKeyCharges</td>
> <td>boolean</td>
> <td>Uses key charges or not. If set to be true, the probability of the key to be pressed will also be considered when determining which key to activate. This can reduce typing error when keys are pretty close to each other, but can also <i>cause</i> typing error when the keys are too cramped together.</td>
> <td>✓</td>
> <td>--</td>
</tr>
<tr>
> <td>inherits</td>
> <td>string</td>
> <td>Start sublayout as a fresh copy of this value. The maximum inheritance depth is 8. You should avoid circular inheritance.</td>
> <td>--</td>
> <td>--</td>
</tr>
</table></li></ul>

Please be aware that all horizontal metrics (widths and <i>x</i>-position) are measured in <b>multiples of key width on that row</b> instead of pixels.<br>
<br>
<h2>texts, shiftedTexts, etc.</h2>

texts is an array. The elements of texts are using array of strings, which specify the keys in the row in order.<br>
<br>
<blockquote>Example: The Alphabet sub-layout of a standard QWERTY keyboard can be implemented as:<br>
<pre><code>texts = (<br>
  ("q", "w", "e", "r", "t", "y", "u", "i", "o", "p"),<br>
  ("a", "s", "d", "f", "g", "h", "j", "k", "l"),<br>
  ("z", "x", "c", "v", "b", "n", "m")<br>
);<br>
</code></pre></blockquote>

To avoid duplicated declaration, you can refer to texts of other sub-layouts in the same file.<br>
<br>
<blockquote>Example: The URL sub-layout is usually implemented as<br>
<pre><code>texts = (<br>
  "=Alphabet[0]",<br>
  "=Alphabet[1]",<br>
  "=Alphabet[2]",<br>
  (".", "/", ".com")<br>
);<br>
</code></pre>
which means the first 3 rows will use the same keys in the Alphabet sub-layout in rows 0, 1 and 2 respectively, but Row 3 will use the keys <code>[.]</code>, <code>[/]</code> and <code>[.com]</code> instead.</blockquote>

<i>shiftedTexts</i> use the same structure as texts. If <i>shiftedTexts</i> is missing, the shifted value will default to the uppercase string if that's just a single character (e.g. q ↦ Q), or the same string if there's more (e.g. .com ↦ .com).<br>
<br>
<blockquote><i>DO NOT</i> associate the same value to more than one key in the same sub-layout. iPhoneOS is not designed to handle this. Currently, the composite graphics is associated to keys by the key value, so e.g. if you have a <code>[Q]</code> on the far left and another <code>[Q]</code> on the far right, the pop up graphics will be misplaced.</blockquote>

There are cases you may want the label not to show exactly what you will type, e.g. when the text is too long to fit into the small key, or the text is a combining character. <code>labels</code>, <code>shiftedLabels</code>, <code>popups</code> and <code>shiftedPopups</code> are entries you would go after for these fine details.<br>
<br>
<blockquote>Example: If we replace the "q" key of the Alphabet sublayout to "Hello world!", the key will definitely be too small. So you may want to create a placeholder like "☺". So you specify the entry as<br>
<pre><code>texts = (<br>
  ("Hello world!", "w", "e", "r", "t", "y", "u", "i", "o", "p"),<br>
  ("a", "s", "d", "f", "g", "h", "j", "k", "l"),<br>
  ("z", "x", "c", "v", "b", "n", "m")<br>
);<br>
labels = (<br>
  ("☺", "w", "e", "r", "t", "y", "u", "i", "o", "p"),<br>
  "=Alphabets[1]",<br>
  "=Alphabets[2]"<br>
);<br>
</code></pre>
note how the labels refer unchanged row back to itself.</blockquote>

The complete spec:<br>
<blockquote><i>union</i> <code>&lt;text row&gt;</code> ::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th>type</th>
<th>meaning</th>
</tr>
<tr>
<td>array</td>
<td>...of `<text>`s</td>
<td>The string to assign to each key in that row.</td>
</tr>
<tr>
<td>string</td>
<td>`/^=(?<key>\w+)?(?<row>\[\d+\])?$/`</td>
<td>This row will be refered. The format must be "`=key[row]`", where _key_ is one of the keys defined in the root level dictionary. If _row_ is missing, it will be taken as the current row. If _key_ is missing, it will be taken as a self-reference. If the refered row does not exist or breaks the recursion limit (8 recursions), nil will be used. The destination will follow this chain on self-reference: (shifted)Popups → (shifted)Labels → (shifted)Texts → texts.</td>
</tr>
<tr>
<td>string</td>
<td>_length_ ≥ 2 && _str_`[`0`]` ≠ "="</td>
<td>A concatenated string. The first character is the separator. For example, ",q,w,e,r,t,y,u,i,o,p".</td>
</tr>
</table></blockquote>

<blockquote><i>union</i> <code>&lt;text&gt;</code> ::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th>type</th>
<th>meaning</th>
</tr>
<tr>
<td>string</td>
<td>Ordinary string</td>
</tr>
<tr>
<td>dictionary</td>
<td>`<text with traits>`</td>
<td>String with style information. Ignored when used with _texts_ or _shiftedTexts_.</td>
</tr>
</table></blockquote>

<blockquote><i>struct</i> <code>&lt;text with traits&gt;</code>::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th>key</th>
<th>type</th>
<th>meaning</th>
<th>default</th>
<th>depends</th>
</tr>
<tr>
<td>text</td>
<td>string</td>
<td>String to show.</td>
<td>""</td>
<td>_image_ = _nil_</td>
</tr>
<tr>
<td>font</td>
<td>string</td>
<td>font name</td>
<td>Use the specified font to render the text. It has to be the full name, e.g. if you want to use a the bold Times font you should write `"TimesNewRomanPS-BoldMT"`.<br />A list of fonts can be found in http://www.latenightcode.com/devblog/iphone-fonts/.</td>
<td>_system font name_</td>
<td>_text_ ≠ _nil_</td>
</tr>
<tr>
<td>color</td>
<td>array</td>
<td>...of reals</td>
<td>Font color of the text. Specify 1 element for gray scale, 2 elements with alpha channel, 3 elements for RGB and 4 elements for RGBA.</td>
<td>_system color_</td>
<td>_text_ ≠ _nil_</td>
</tr>
<tr>
<td>size</td>
<td>real</td>
<td>Font size to rescale to. For example, if the default font was 45px, and you supply 0.5 here, the text will be rendered with 22.5px</td>
<td>1</td>
<td>_text_ ≠ _nil_</td>
</tr>
<tr>
<td>variantType</td>
<td>string</td>
<td>Variants type. Currently must be one of `{"accents", "currency", "URL", "email", "immediate-accents"}`. Use the `variants.plist` file to define the content of variants.</td>
<td>"`accents`"</td>
<td>--</td>
</tr>
<tr>
<td>after</td>
<td>string</td>
<td>{"`none`", "`shift`", "`alt`"}</td>
<td>If this set to "`shift`", after pressing this key the shift key will be switched to. Similarly for "`alt`" for the alternate plane. Pass "`none`" to forcefully turn it off.</td>
<td>"`alt`" if _text_ == "`'`" **and** _current plane is alternate_, "`none`" otherwise</td>
<td>--</td>
</tr>
</table></blockquote>

<h3>Control keys (3.0 only)</h3>

From 3.0 onwards control keys are supported natively (previously it was part of 5-Row QWERTY). Control keys are those which perform actions other than emitting a character, e.g. moving the cursor around, hiding the keyboard, etc. Control keys can be used by putting <code>&lt;Keyname&gt;</code> in the <code>texts</code>. The Keyname follows Vim convention if possible.<br>
<br>
Control keys behave differently in ANSI and X11 apps. The key maps to actual key-symbols or escape sequences in those apps.<br>
<br>
<table><thead><th> <b>Control key</b> </th><th> <b>Normal behavior</b> </th><th> <b>ANSI supported</b> </th><th> <b>X11 supported</b> </th></thead><tbody>
<tr><td> `<Esc>` | Hide the keyboard | ✓ | ✓ |
| `<Left>`, `<Right>`, `<Up>`, `<Down>` | Move cursor | ✓ | ✓ |
| `<F1>` – `<F12>` | ✗ | ✓ | ✓ |
| `<Home>` | Move cursor to beginning of text | ✓ | ✓ |
| `<End>` | Move cursor to end of text | ✓ | ✓ |
| `<Insert>` | ✗ | ✓ | ✓ |
| `<Del>` | Forward delete |  ✓ | ✓ |
| `<PageUp>`, `<PageDown>` | Move cursor position by one page | ✓ | ✓ |
| `<k0>` – `<k9>` | Output 0 – 9 | ✓ | ✓ |
| `<kPlus>`, `<kMultiply>`, `<kDivide>` | Output `+`, `*` and `/` | Output `+`, `*` and `/` | ✓ |
| `<kMinus>`, `<kPoint>`, `<kEnter>` | Ouput `-`, `.` and `\n` | ✓ | ✓ |
| `<ShiftL>`, `<ShiftR>` | Toggle shift | ✗ | ✓ |
| `<CtrlL>`, `<CtrlR>` | ✗ | Output `[CTRL]` | ✓ |
| `<AltL>`, `<AltR>`, `<MetaL>` `<MetaR>` | ✗ | ✗ | ✓ |
| `<WinL>`, `<WinR>`, `<SuperL>` `<SuperR>`, `<HyperL>` `<HyperR>` |  ✗ | ✗ | ✓ |
| `<App>` | Show the copy/paste menu | ✗ | ✓ |
| `<CapsLock>` | Toggle shift |  ✗ | ✓ |
| `<PrintScreen>`, `<Pause>`, `<ScrollLock>` |  ✗ | ✗ | ✓ |

By default, ANSI apps contains:
  * MobileTerminal
and X11 apps (which includes VNC apps) contains:
  * Jaadu VNC
  * Mocha VNC
  * Mocha VNC Lite
  * LogMeIn Ignition
  * RemoteTap
  * Remote Jr.
  * VNC Pocket Office
  * HippoRemote
  * AirMote
(Note that we haven't tested on all of these apps.)

## arrangement ##
arrangement specifies how many keys will be present in each row, e.g.
```
 arrangement = (10, 9, 7, 0);
```

It can be an array of _rows_ numbers, or a string representing the standard values:
| **String** | **Rows 0 to N-3** | **Row N-2** | **Row N-1** | **Row N** |
|:-----------|:------------------|:------------|:------------|:----------|
| Default | 10 | 9 | 7 |  |
| AZERTY | 10 | 10 | 6 |  |
| Russian | 11 | 11 | 9 |  |
| Alt | 10 | 10 | 5 |  |
| URLAlt | 10 | 6 | 4 |  |
| JapaneseQWERTY | 10 | 10 | 7 |  |
| WithURLRow4 |  |  |  | 3 |

WithURLRow4 can be combined with the 6 values, e.g.
```
arrangement = "Default|WithURLRow4";
```
is equivalent to
```
arrangement = (10, 9, 7, ..., 3);
```

> If you are using an XML property list, do it like this:
```
...
<key>arrangement</key>
<array>
  <integer>10</integer>
  <integer>9</integer>
  <integer>7</integer>
  ...
  <integer>3</integer>
</array>
...
```

**Unless you are creating a standard 4-row layout, you should use the numeric array format instead of preset strings.**

## rowIndentation ##

rowIndentation specifies the spacing in pixels on the left and right of that row _in portrait orientation_. The content of the array are:
> _union_ `<row indentation>` ::
<table cellpadding='5' border='1'>
<tr>
</li></ul>> <th>type</th>
> <th>meaning</th>
</tr>
<tr>
> <td>array</td>
> <td>...of reals</td>
> <td>An array of 2 integers defining the left and right padding respectively.</td>
</tr>
<tr>
> <td>real</td>
> <td>Left and right padding will be the same.</td>
</tr>
</table></li></ul>

It can also use a string of predefined values:<br>
</td><td> <b>String</b> </td><td> <b>Rows 0 to N-3</b> </td><td> <b>Row N-2</b> </td><td> <b>Row N-1</b> </td><td> <b>Row N</b> </td></tr>
<tr><td> Default </td><td> 0 </td><td> 16 </td><td> 48 </td><td> 80 </td></tr>
<tr><td> AZERTY </td><td> 0 </td><td> 0 </td><td> 64 </td><td> 80 </td></tr>
<tr><td> Russian </td><td> 0 </td><td> 0 </td><td> 29 </td><td> 80 </td></tr>
<tr><td> Alt </td><td> 0 </td><td> 0 </td><td> 48 </td><td> 80 </td></tr>
<tr><td> TightestDefault </td><td> 0 </td><td> 0 </td><td> 42 </td><td> 80 </td></tr></tbody></table>

The indentation in landscape orientation will be automatically converted using the formula:<br>
<blockquote>!Landscape_rowIndentation = !Portrait_rowIndentation × (47/32) + 5</blockquote>

<b>Unless you are creating a standard 4-row layout, you should use the numeric array format instead of preset strings.</b>

<h1>Caching</h1>

Reconstructing the images and parameters for <code>UIKeyboardSublayout</code> is expensive. It takes about 1 to 2 seconds to start up. Therefore, when using layout.plist, iKeyEx will automatically cache the computed results in <code>/var/mobile/Library/Keyboard/</code>.<br>
<br>
When you upgrade your layout.plist, you must empty the cache. You can do so by using the program <code>iKeyEx_KBMan</code>, e.g.<br>
<pre><code>  iKeyEx_KBMan purge Colemak<br>
</code></pre>

<h1>Using layout.plist with custom code</h1>

The <code>UIKBStandardKeyboard</code> class provides easy access to transform a layout.plist into resources used in iPhoneOS.<br>
<br>
To use it, you first need to load your layout.plist into an NSDictionary, and then create a keyboard using its <code>-initWithPlist:name:landscape:appearance:</code> or <code>+keyboardWithPlist:name:landscape:appearance:</code> method.<br>
<pre><code>NSDictionary* layout = [NSDictionary dictionaryWithContentsOfFile:[someBundle pathForResource:@"layout" ofType:@"plist"];<br>
UIKBStandardKeyboard* keyboard = [UIKBStandardKeyboard keyboardWithPlist:layout name:@"Alphabet" landscape:NO appearance:UIKeyboardAppearanceDefault];<br>
</code></pre>
Then you can use the read-only properties <code>image</code>, <code>fgImage</code>, <code>shiftedImage</code>, <code>fgShiftedImage</code> and <code>keyDefinitions</code> for the <code>UIKeyboardSublayout</code>s. There is also a vast number of less complex properties you mean need. Check the header file for detail.