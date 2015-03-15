

# Introduction #

**Property list** files (plist) are a general serialization format mainly used in NeXTSTEP-derived operating systems, including iPhoneOS. Since networkpx is an iPhoneOS-based project collection, it will use the format extensively.

This page introduces the basis of the format, and the notation used here when a specification based on plist is used.

# plist format #

There are 3 favors of plist, Text, XML and Binary. Only Text and XML will be discussed here. The differences between them are only the serialization method. The abstract structure always follows the same principle.

No matter for what type, a plist can only store the so-called **plist objects**. They are:
  * **string**, **number**, **boolean**, **date**,
  * **data** (binary data),
  * **dictionary** (associative array), and
  * **array**.

The last 2 types are "containers" and can contain other plist objects. In fact, a plist itself is just a dictionary.

## Text ##

A text plist can only serialize 4 types of plist objects: string, data, dictionary and array. Number, boolean and date will be encoded into a string.

### string ###

Strings are serialized as double-quoted strings:
```
"This is a string"
```
if the string consists only of alphanumeric characters, you can omit the double quotes as well:
```
THIS_IS_A_KEYWORD
```
You can use `\UXXXX` to refer to Unicode characters, e.g.
```
"\U4f60\U597d"
```
but you should save the file as UTF-16 and explictly write the content instead, if internationalization support is considered.

### data ###

Data are serialized as hexadecimal numbers enclosed inside angle brackets:
```
<53 6f 6d 65 20 64 61 74 61> 
```
You can arbitrarily insert spaces between any **pair** of digits.

### array ###

Arrays are serialized as comma-separated lists enclosed inside parenthesis:
```
("clubs", "diamonds", "hearts", "spades")
```
There can be a trailing comma, e.g.
```
(
	"clubs",
	"diamons",
	"hearts",
	"spades",
)
```

### dictionary ###

Dictionaries are serialized a semicolon-separated list of `key=value` pairs inside braces:
```
{
	en = "English";
	es = "Spanish";
	ja = "Japanese";
}
```
The trailing semicolon here is mandatory.

### Comments ###

You can embed C (`/* ... */`) and C++ (`// ...`) style comments in a plist, e.g.
```
{
	/* Deprecated, use zh_Hant instead */
	zh_TW = "Traditional Chinese";
	// Deprecated, use zh_Hans instead
	zh_CN = "Simplified Chinese";
}
```

## XML ##

The XML format was introduced by Apple in Mac OS X. Its document type definition (DTD) can be found in http://www.apple.com/DTDs/PropertyList-1.0.dtd.

The _root element_ of an XML plist must be `<plist/>`. It can optionally include a `version` attribute stating the plist version it used. For now, the value must be `1.0`:
```
<plist version="1.0">
...
</plist>
```

### string ###
Strings are specified using the `<string/>` element:
```
<string>Hello, world!</string>
```
Like any other XML format, you can use entities `&#xxxx;` for special Unicode values.

### number ###
There are 2 kinds of numbers: **real** and **integer**. They are encoded with the same-named tags:
```
<real>1.05457148e-34</real>
<integer>42</integer>
```

### boolean ###
Boolean are truth values. The values are indicated with the empty tags `<true/>` and `<false/>`:
```
<true />
<false />
```

### date ###
Dates are used with the `<date/>` tag. The content must be encoded as an ISO-8601 string in the UTC timezone, e.g.
```
<date>2008-12-20T22:13:56Z</date>
```

### data ###
Data should be indicated with the `<data/>` tag. The content of this tag will be Base-64 encoded, e.g.
```
<data>U29tZSBkYXRh</data>
```

### array ###
An array is made by using the `<array/>` element, then aggregate all plist objects in it, e.g.
```
<array>
  <string>clubs</string>
  <string>diamonds</string>
  <string>hearts</string>
  <string>spades</string>
</array>
```

### dictionary ###
Similar to arrays, dictionaries will use the `<dictionary/>` element and lists all the member plist objects. But to specify keys, you would use the `<key/>` tag, as in
```
<dictionary>
  <key>en</key>
  <string>English</string>
  <key>es</key>
  <string>Spanish</string>
  <key>ja</key>
  <string>Japanese</string>
</dictionary>
```

## Example serialization ##

Let's suppose we want to serialize some important information of the file system, e.g. all directories in / of the iPhoneOS. In text plist format, e.g., we could write
```
{
	Applications = {
		isSymLink = 1;
		symLink   = "/var/stash/Application/";
		owner     = root;
		permissions = {
			root      = (read, write, execute); 
			"<other>" = (read, execute);
		};
		numberOfFilesIncluded = 31;
	};
	Library = {
		isSymLink = 0;
		owner     = root;
		permissions = {
			root      = (read, write, execute); 
			admin     = (read, write, execute); 
			"<other>" = (read, execute);
		};
		numberOfFilesIncluded = 23;
	};
	/* etc. */
}
```

In XML format, this become much more verbose:
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Applications</key>
	<dict>
		<key>isSymLink</key>
		<true/>
		<key>symLink</key>
		<string>/var/stash/Application/</string>
		<key>owner</key>
		<string>root</string>
		<key>permissions</key>
		<dict>
			<key>root</key>
			<array>
				<string>read</string>
				<string>write</string>
				<string>execute</string>
			</array>
			<key>&lt;other&gt;</key>
			<array>
				<string>read</string>
				<string>execute</string>
			</array>
		</dict>
		<key>numberOfFilesIncluded</key>
		<integer>31</integer>
	</dict>
	<key>Library</key>
	<dict>
		<key>isSymLink</key>
		<false/>
		<key>owner</key>
		<string>root</string>
		<key>permissions</key>
		<dict>
			<key>root</key>
			<array>
				<string>read</string>
				<string>write</string>
				<string>execute</string>
			</array>
			<key>admin</key>
			<array>
				<string>read</string>
				<string>write</string>
				<string>execute</string>
			</array>
			<key>&lt;other&gt;</key>
			<array>
				<string>read</string>
				<string>execute</string>
			</array>
		</dict>
		<key>numberOfFilesIncluded</key>
		<integer>23</integer>
	</dict>
	<!-- etc. -->
</dict>
</plist>
```

If you are handwriting a plist, the best choice is of course the Text format.

# Specifying plist-derived formats #

There are many important plist-derived formats, such as Info.plist providing metadata of a bundle and Settings.plist for loading preference panes for iPhoneOS, and layout.plist for defining a dynamic standard keyboard in iKeyEx. These files usually have a more rigid structure than a generic plist to be useful.

The specification here we used is intended for easy reading, instead of giving a very precise grammar.

## Known-Key Dictionary Structure ##

We specify the plist structure in a table form, for example,

> _struct_ `<file entry>` ::
<table cellpadding='5' border='1'>
<tr>
</li></ul>> <th>key</th>
> <th>type</th>
> <th>meaning</th>
> <th>default</th>
> <th>depends</th>
</tr>
<tr>
> <td>isSymLink</td>
> <td>boolean</td>
> <td>Whether the file is a symbolic link.</td>
> <td>✗</td>
> <td>--</td>
</tr>
<tr>
> <td>symLink</td>
> <td>string</td>
> <td>file path</td>
> <td>The target the current file links to.</td>
> <td><b>Required</b></td>
> <td><i>isSymLink</i> = ✓</td>
</tr>
<tr>
> <td>permissions</td>
> <td>dictionary</td>
> <td><code>&lt;permissions&gt;</code></td>
> <td>Permissions of individual users.</td>
> <td><b>Required</b></td>
> <td>--</td>
</tr>
<tr><td align='center'>...</td></tr>
</table></li></ul>

This table defines <b>known-key dictionary structure</b>. The plist object is a dictionary with some rigid structure to be specified here, and the keys must take on the values in the table. The "<i>struct</i> <code>&lt;file entry&gt;</code> ::" line defines this is a kind of <i>structure</i> and is to be called a "file entry". The value corresponding to each key must use the specified type. Sometimes a subtype is also given to further limit or emphasis the content it should carry. Some common subtypes are:<br>
<ul><li><b>file name</b> (e.g. <code>"MyApp.app"</code>)<br>
</li><li><b>file path</b> (e.g. <code>"../Applications/MyApp.app/MyApp_"</code>)<br>
</li><li><b>absolute path</b> (e.g. <code>"/var/mobile/Library/Logs/CrashReporter/LatestCrash-MyApp.plist"</code>)<br>
</li><li><b>localizable string</b>
</li><li><b>bundle identifier</b> (e.g. <code>"com.apple.mobilesafari"</code>)<br>
</li><li><b>class name</b> (e.g. <code>"MAListController"</code>)<br>
</li><li><b>selector</b> (e.g. <code>"setObject:forEvent:"</code>)<br>
</li><li>A constraint like <i>value</i> ≥ 10 && <i>value</i> < 256<br>
</li><li>An enum like {"Enabled", "Disabled", "Intermediate"}.<br>
</li><li>Other custom structures e.g. <code>&lt;permissions&gt;</code>.</li></ul>

An entry can be multi-typed, e.g.<br>
<table cellpadding='5' border='1'>
<tr>
<blockquote><th>key</th>
<th>type</th>
<th>meaning</th>
<th>default</th>
<th>depends</th>
</tr>
<tr>
<td>arrangement</td>
<td>string</td>
<td>`<preset arrangement>`</td>
<td>How many keys per row will be shown.</td>
<td>"Default"</td>
<td>--</td>
</tr>
<tr>
<td>array</td>
<td>...of integers</td>
</tr>
</table>
This means the <i>arrangement</i> entry can be specified as either a string, or an array of integers.</blockquote>

Sometimes a key is meaningless without another key defined to a particular value. If such a relation exists, the <b>depends</b> column will be non-empty.<br>
<br>
Usually a key in the plist object can be omitted. When it is omitted, a default value is used for that instead. The <b>default</b> column gives the expression of the default value. If the entry must exist no matter how, <b>Required</b> will be shown in this column. The <b>depends</b> column always have a higher priority than the <b>Required</b> attribute in the <b>default</b> column.<br>
<br>
<h2>Arrays</h2>

An array will have type "array" and the subtype indicating the types of data it may contain, e.g. "...of integer". It is usually not considered as a custom structure.<br>
<br>
<h2>Unknown-Key Dictionary Structure</h2>

An <b>unknown-key dictionary structure</b> is a dictionary which there are no fixed keys. This structure can actually be thought as an array of pair of values. The definition will be denoted like<br>
<blockquote><i>pairs</i> <code>&lt;permissions&gt;</code> ::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th></th>
<th>type</th>
<th>meaning</th>
</tr>
<tr>
<td>**key**</td>
<td>string</td>
<td>The user or group name to be given permissions. Use "`<owner>`", "`<group>`" and "`<other>`" to refer to the file (non-)owner.</td>
</tr>
<tr>
<td>string</td>
<td>{"`<owner>`", "`<group>`", "`<other>`"}</td>
</tr>
<tr>
<td>**value**</td>
<td>array</td>
<td>...of `<permission>`s</td>
<td>The permissions the user will have.</td>
</tr>
</table></blockquote>

<h2>Enumeration</h2>

An <b>enumeration</b> (enum) is just a collection of predefined value. When an entry have a type of some custom set, it can only take one value from the set, e.g.<br>
<br>
<blockquote><i>enum</i> <code>&lt;permission&gt;</code> ::<br>
<ul><li>"read"<br>
</li><li>"write"<br>
</li><li>"execute"<br>
</li><li>"setuid"</li></ul></blockquote>

<h2>Union</h2>

A <b>union</b> is a type that can represent multiple types, e.g.<br>
<br>
<blockquote><i>union</i> <code>&lt;floating value&gt;</code> ::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th>type</th>
<th>meaning</th>
</tr>
<tr>
<td>real</td>
<td>The floating point value.</td>
</tr>
<tr>
<td>string</td>
<td>{"`+infinity`", "`-infinity`", "`nan`"}</td>
<td>Special values that cannot be expressed as a number.</td>
</tr>
</table></blockquote>

<h1>References</h1>

<ul><li>Apple - <a href='http://developer.apple.com/documentation/Cocoa/Conceptual/PropertyLists/Introduction/chapter_1_section_1.html'>Property List Programming Guide</a>