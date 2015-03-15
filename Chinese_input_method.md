# .cin Input Managers #
Starting from iKeyEx 0.1-99d, .cin input managers are supported natively. The .cin format allows table-based IME, like Cangjie (倉頡), Pinyin (拼音) etc to be created.

You can find many .cin files of common IME here: http://cle.linux.org.tw/trac/wiki/GcinTables.

## Directory layout ##
```
  /Library/iKeyEx/InputManagers/
    <IMEName>.ime/
      Info.plist
      <???>.cin
```

## Info.plist ##
There should be two entries,
  1. **UIKeyboardInputManagerClass** should be set to the filename of the .cin file,
  1. **IKXLanguage** should be set to the language of the IME. Currently, it can only be `zh-Hant` (Traditional Chinese) or `zh-Hans` (Simplified Chinese). If this key is absent, zh-Hant is the default.

## .cin File Format ##
The general format is described in http://www.yale.edu/chinesemac/pages/input_methods.html.

For iKeyEx, only the %keyname and %chardef sections required. All other info are ignored. The %keyname section is only used to determine what characters can participate in the IME.

The input string **must be** in lowercase and consists of **9 or less** characters (excess characters will be ignored.) There are no restriction on the corresponding output string, but it would be the best if it can fit within 2 UTF-16 code points (the .cin file itself must still be UTF-8, however).

# Phrase and character tables #
Phrase and characters tables are used to sort characters and display associated words in a candidate list. The tables can be downloaded from the iKeyEx Chinese Support package, but you can create one on your own.

The phrase tables should be stored in `/Library/iKeyEx/Phrase/<Language>/` and encoded in UTF-8. The general format is
```
<Phrase>\n
<Phrase>\n
...
```
The higher the character, the more frequent it appears.

## Characters tables ##
Characters table is used to calculate ordering in a candidate list. It must have an extension of `.chrs`.

Each entry of a characters table should occupy no more than 2 UTF-16 code-points (The file itself should still be encoded in UTF-8, as above). The number of entry must be less than 2.1 billion (2<sup>31</sup>).

The source of the character tables in iKeyEx Chinese Support package are
  * Traditional Chinese: http://technology.chtsai.org/charfreq/ (?)
  * Simplified Chinese:  http://readmandarin.com/resultsutf8.txt (from [readmandarin.com](http://readmandarin.com/))

## Phrase tables ##
Phrases (a.k.a. Associated Words 聯想 / 相關字詞) can be used to complete a character into a word. In the most common scenario, after you have accepted a character candidate (say, 義), a list of completions (e.g. 大利, 工, 務, 正辭嚴, etc.) will be shown to quickly finish a word.

A phrase table must have an extension of `.phrs`.

The source of the iKeyEx Chinese Support table are obtained from:
  * Traditional Chinese: [新酷音詞庫](http://svn.csie.net/log.php?repname=chewing&path=%2Flibchewing%2Ftrunk%2Fdata%2Ftsi.src&rev=0&isdir=) (tsi.src from libchewing. LGPL.)
  * Simplified Chinese: [智能拼音词库](http://scim.svn.sourceforge.net/viewvc/scim/scim-pinyin/trunk/data/phrase_lib.txt?view=log) (phrase\_lib.txt from scim-pinyin, with words having frequency = 0 filtered out. GPL.)