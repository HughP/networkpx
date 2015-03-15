

# WordTrie #

The WordTrie consist of 2 files, the index file (.idx) and word file (.dat).

All numbers in a WordTrie are in **big endian**.

## Magic Number ##

The first 4 bytes of each file must be `00-00-00-01`. This is checked in `KB::WordTrie::magic_number_ok`.

## Word file (.dat) ##

### Word Count ###

The number of words stored in this file is at 0x1C.

### Word Entry ###

Each entry must have a 4-byte metadata:
```
struct {
 struct {
   unsigned size:5;
   unsigned length:5;
   unsigned sort_key_length:5;
 };
 unsigned char word_m_40;
 char flags;
};
```

```
flags
=====
   1 : Long-Capitalization-Flag.
   2 :
   4 :
   8 :
0x10 :
0x20 :
0x40 : Long-0x4C-Flag.
0x80 : Return-Raw-Data.
```

If the `Long-Capitalization-Flag` flag is set, an unsigned (32-bit) int will be read and used as the capitalization flag instead of `flags`. The capitalization field is used to give a proper capitalization in auto-correction. For example, the entry for _applecare_ has capitalization flag 0x21, which means the first (0x1) and sixth (0x20) letters should be capitalized.

If `Long-0x4C-Flag` is set, another unsigned int will be read and stored in `m_4c`, otherwise `flags` will be used instead.

If `Return-Raw-Data` is set, the raw data in the Words file will be returned when calling `KB::WordTrie::word_at`. Otherwise a NULL pointer is returned.

The null-terminated string following is the word entry. A word entry is usually _not_ aligned.

## API ##

You can use the `WordTrie` C++ class in the UIKit framework to access WordTries.

# KBWordSearch #

KBWordSearch is a binary IME data format. It is also the name of the Objective-C class dealing with this format. It is located in UIKit.

## Concepts ##
  * **Yomi** is the Japanese word 読み, meaning Reading. In the Japanese Romaji input method, the yomi is sound of the words transliterated into Latin characters. In a general IME, the yomi is the displayed input string. For example, _tokyo_ is the yomi of the Japanese word 東京.

## Binary Image Format ##

There is no magic numbers in the KBWordSearch format. The header is 32 bytes of offset data:
```
struct KBWordSearchOffsets {
  int wordlist_begin;
  int wordlist_maxDelta;
  int dict_begin;
  int dict_maxDelta;
  int dictLink_begin;
  int dictLink_maxDelta;
  int connectionLink_begin;
  int connectionLink_maxDelta;
};
```
As shown, there are 4 sections in the KBWordSearch format. The `_begin` variables are the absolute offset the section will start in the file. The `_maxDelta` variables are the maximum relative offset can move before overflowing to the next section. It is equal to the block size plus 4.

As for the sections, **wordlist** consists of null-terminated strings used in the dictionary. Each string should not contain more than 25 UTF8 code points, otherwise you'll risk having buffer overflow. This is equivalent to 8 CJK characters. If you want to support more than 8 characters, slice it up and use connections to output it chunk by chunk.

**dict** is an array of `DictEntry`s, which are 24-byte structures:
```
struct DictEntry {
  int yomiOffset;
  int candidateOffset;
  int outConnection;
  int inConnection;
  int _field5;
  int nextLink;
};
```
The two offsets point to the **wordlist** table, as the position where the respective string can be found.

The `nextLink` variable points to the index in the _dict_.

## Learned Dictionary Plist Specification ##

## API ##