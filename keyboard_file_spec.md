On iPhoneOS 3.0, every keyboard layout is switched to the UIKeyboardLayoutStar class. The new class allows easy creation of new keyboards using a set of UIKB structural classes. This page is a summary of how what these classes will store when archived.



# UIKBKeyboard #

> _struct_ `<UIKBKeyboard>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string | filename | Keyboard name, also its filename (without the .keyboard part) |
| visualStyle | string | {`"iPhone-Standard"`, `"iPhone-Alert"`} | Keyboard style (optional) |
| keyplanes | array | ... of `<UIKBKeyplane>`s | Keyplanes |

# UIKBKeyplane #

A keyplane is a single slice of keyboard. Keyplanes can be switched between each other using the shift and more (123/ABC) keys.

> _struct_ `<UIKBKeyplane>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string |  | Name of keyplane, e.g. Capital-Letters. Case-insensitive. |
| keylayouts | array | ...of `<UIKBKeylayout>`s | Actual geometric layout. |
| attributes | dictionary | `<UIKBAttributeList>` | Attributes. |
| supported-types | array | ...of strings | Supported types. The strings must be `UIKeyboardType`_X_ where _X_ is one of <ul><li>Default</li><li>ASCIICapable</li><li>NumbersAndPunctuation</li><li>URL</li><li>NumberPad</li><li>PhonePad</li><li>NamePhonePad</li><li>EmailAddress</li></ul> |

# UIKBKeylayout #

> _struct_ `<UIKBKeylayout>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string |  | Name of the layout (e.g. Portrait-QWERTY-Capital-Letters-Keylayout) |
| keyset | struct | `<UIKBKeyset>` | Key set. |
| refs | array | ...of `<UIKBKeylistReference>`s | References. |

## UIKBKeyset ##
A keyset contains rows of keylists, which are columns of keys.

> _struct_ `<UIKBKeyset>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string |  | Name of the keyset (e.g. QWERTY-Capital-Letters-Keyset) |
| keylists | array | ...of `<UIKBKeylist>`s | The rows of keys. |

## UIKBKeylist ##
> _struct_ `<UIKBKeylist>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string |  | Name of the keylist (e.g. Row1) |
| keys | array | ...of `<UIKBKey>`s | The keys in this row. |

## UIKBKey ##
> _struct_ `<UIKBKey>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string |  | Name of the key (e.g. Latin-Capital-Letter-Q) |
| representedString | string |  | The string that will be typed out when tapping this key. |
| displayString | string |  | The string that is shown on the key. |
| displayType | string | {...} | The style of the key, must be one of:<ul><li>Delete</li><li>DynamicString</li><li>International</li><li>More</li><li>NumberPad</li><li>Return</li><li>Shift</li><li>Space</li><li>String</li><li>TopLevelDomain</li><li>TopLevelDomainVariant</li></ul> |
| interactionType | string | {...} | How the system will respond to a tap. Must be one of:<ul><li>Delete</li><li>International</li><li>None</li><li>Return</li><li>Shift</li><li>Space</li><li>String</li><li>String-Direct</li><li>String-Popup</li></ul> |
| variantType | string | {...} | Variants to show for this key. Must of one of: <ul><li>accents (not used)</li><li>currency</li><li>URL</li><li>email</li><li>immediate-accents</li></ul> |
| attributes | dictionary | `<UIKBAttributeList>` | Other attributes. |

## UIKBKeylistReference ##
Keylist references are like patches to the keyset. They provide additional detail e.g. the dimensions of the keys.

> _struct_ `<UIKBKeylistReference>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string |  | Name of the reference (e.g. "`Keyset.Row1.Geometry`", "`Keyset.Row1.Keys[-1].Attributes`", etc.) |
| value | any |  | The value for the keylist to use. |
| flags | integer |  | ? |
| nameElements | array | ...of strings | The name, tokenized by dots. |
| startKeyIndex | integer |  | If there is a `[a:b]` in the name, the value of a. |
| endKeyIndex | integer |  | If there is a `[a:b]` in the name, the value of b.  |

The referenced type can be one of:
  * UIKBAttributeList
  * UIKBGeometry
  * Array of `<UIKBGeometry>`s.

# UIKBGeometry #
> _struct_ `<UIKBGeometry>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string |  | Name of the geometry (e.g. iPhone-Portrait-Alphabetic-Row3-Geometry) |
| x-amount | real |  | x-location. |
| x-unit | integer |  | Unit of x-location. 1 = px, 2 = %. |
| y-amount | real |  | y-location. |
| y-unit | integer |  | Unit of y-location. 1 = px, 2 = %. |
| w-amount | real |  | Width. |
| w-unit | integer |  | Unit of width. 1 = px, 2 = %. |
| h-amount | real |  | Height. |
| h-unit | integer |  | Unit of height. 1 = px, 2 = %. |
| paddingTop-amount | real |  | Top padding. |
| paddingTop-unit | integer |  | Unit of top padding. 1 = px, 2 = %. |
| paddingLeft-amount | real |  | Left padding. |
| paddingLeft-unit | integer |  | Unit of left padding. 1 = px, 2 = %. |
| paddingBottom-amount | real |  | Bottom padding. |
| paddingBottom-unit | integer |  | Unit of bottom padding. 1 = px, 2 = %. |
| paddingRight-amount | real |  | Right padding. |
| paddingRight-unit | integer |  | Unit of right padding. 1 = px, 2 = %. |
| explicit | boolean |  | ? |


# UIKBAttributeList #

> _struct_ `<UIKBAttributeList>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string |  | Name of the attribute list. Usually empty. |
| list | array | ...of `<UIKBAttribute>`s | The actual list of attributes. |
| explicit | boolean |  | ?? |

## UIKBAttribute ##

> _struct_ `<UIKBAttribute>` ::
| **key** | **type** | **subtype** | **meaning** |
|:--------|:---------|:------------|:------------|
| name | string |  | Name of the attribute. |
| value | any |  | Value of the attribute. |

The defined attributes are:
| **name** | **value type** | **for** | **meaning** |
|:---------|:---------------|:--------|:------------|
| adaptive-keys | boolean | Keyplane | Use "adaptive keys" or not. Usually true for alphabet plane and false for numbers & symbols plane. |
| autoshift | boolean | Keyplane | Enables auto-shift (e.g. enables shift after a full-stop). |
| label |  |  |  |
| looks-like-shift-alternate | boolean | Keyplane | This plane and the shift plane look like each other. |
| more-after | boolean | Key | Immediately press the more key automatically after this key is pressed. Usually enabled on the apostrophe (') key. |
| more-alternate | string (keyplane name) | Keyplane | The name of keyplane to switch to after tapping the More key. |
| more-rendering | string ({...}) | Keyplane | What strings should be shown on the More key.<ul><li>numbers = @123</li><li>symbols = .?123</li><li>letters = ABC</li><li>phonepad = 123</li></ul> |
| popup-bias | {"left", "right"} | Key | Whether the popup (the large letter) to point to the left or right (or center by default).  |
| shift | boolean | Keyplane | Whether this keyplane is a shifted one. |
| shift-after | boolean | Key | Immediately press the shift key automatically after this key is pressed. Used a lot on the Zhuyin keyboard. |
| shift-alternate | string (keyplane name) | Keyplane | The name of keyplane to switch to after tapping the Shift key. |
| shift-is-plane-chooser | boolean | Keyplane | When true, the shift key will act as a caps-lock-like key. |
| shift-rendering | string ({...}) | Keyplane | What string should be shown on the Shift key.<br><ul><li>numbers = 123</li><li>symbols = #+=</li><li>letters = ⇧</li><li>glyph = ?????</li></ul> <br>
<tr><td> shouldskipcandidateselection </td><td> boolean </td><td> Keyplane </td><td> ? </td></tr>
<tr><td> state </td><td> {"enabled", "disabled"} </td><td> Key </td><td> Whether a key is enabled or not. Used in PhonePad keyboard. </td></tr>
<tr><td> supported-types </td><td> array of strings? </td><td> Keyplane </td><td> Not used. </td></tr>
<tr><td> variant-popup-bias </td><td> {"left", "right"} </td><td> Key </td><td> Whether the variants popup should expand to the left or right. </td></tr>
<tr><td> variant-type </td><td> string </td><td> Key </td><td> Not used? </td></tr>
<tr><td> visible </td><td> boolean? </td><td>  </td><td> Not used. </td></tr></tbody></table>

These are attributes for various internal layouts:<br>
<table><thead><th> <b>name</b><br><b>keyplane</b> </th><th> Latin, (Default),<br>Capital-Letters </th><th> Latin, (Default),<br>Small-Letters </th><th> Latin, (Default),<br>Numbers-And-Punctuation </th><th> Latin, (Default),<br>Numbers-And-Punctuation-Alternate </th><th> Latin, (PhonePad)<br>Default </th><th> Latin, (PhonePad)<br>Alternate </th></thead><tbody>
<tr><td> autoshift </td><td> ✓ </td><td> ✓ </td><td> ✗ </td><td> ✗ </td><td> ✗ </td><td> ✗ </td></tr>
<tr><td> adaptive-keys </td><td> ✓ </td><td> ✓ </td><td> ✗ </td><td> ✗ </td><td> ✗ </td><td> ✗ </td></tr>
<tr><td> looks-like-shift-alternate </td><td> ✓ </td><td> ✓ </td><td> ✗ </td><td> ✗ </td><td> ✗ </td><td> ✗ </td></tr>
<tr><td> shift </td><td> yes </td><td> no </td><td> no </td><td> yes </td><td> no </td><td> yes </td></tr>
<tr><td> shift-alternate </td><td> small-letters </td><td> capital-letters </td><td> numbers-and-punctuation-alternate </td><td> numbers-and-punctuation </td><td> alternate </td><td> default </td></tr>
<tr><td> shift-is-plane-chooser </td><td>  </td><td>  </td><td> ✓ </td><td> ✓ </td><td>  </td><td>  </td></tr>
<tr><td> shift-rendering </td><td> glyph </td><td>  </td><td> symbols </td><td> numbers </td><td> letters </td><td> numbers </td></tr>
<tr><td> shouldskipcandidateselection </td><td>  </td><td>  </td><td>  </td><td>  </td><td> ✓ </td><td> ✓ </td></tr>
<tr><td> more-alternate </td><td> numbers-and-punctuation </td><td> numbers-and-punctuation </td><td> small-letters </td><td> small-letters </td><td>  </td><td>  </td></tr>
<tr><td> more-rendering </td><td> numbers </td><td> numbers </td><td> letters </td><td> letters </td><td>  </td><td>  </td></tr></tbody></table>

<table><thead><th> <b>name</b><br><b>keyplane</b> </th><th> Thai, (Default),<br>Shifted-Letters </th><th> Thai, (Default),<br>Letters </th><th> Hebrew, (Default)<br>Letters </th></thead><tbody>
<tr><td> autoshift </td><td> ✗ </td><td> ✗ </td><td> ✗ </td></tr>
<tr><td> adaptive-keys </td><td> ✓ </td><td> ✓ </td><td> ✓ </td></tr>
<tr><td> looks-like-shift-alternate </td><td> ✗ </td><td> ✗ </td><td> ✓ </td></tr>
<tr><td> shift </td><td> yes </td><td> no </td><td> no </td></tr>
<tr><td> shift-alternate </td><td> letters </td><td> shifted-letters </td><td>  </td></tr>
<tr><td> shift-is-plane-chooser </td><td> ✓ </td><td> ✓ </td><td> ✗ </td></tr>
<tr><td> more-alternate </td><td> numbers-and-punctuation </td><td> numbers-and-punctuation </td><td> numbers-and-punctuation </td></tr>
<tr><td> more-rendering </td><td> numbers </td><td> numbers </td><td> numbers </td></tr>