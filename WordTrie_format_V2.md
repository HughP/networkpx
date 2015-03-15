
```
typedef uint32_t be_int;    // Big-endian 32-bit integer.
typedef uint16_t be_short;  // Big-endian 16-bit integer.
typedef float    be_float;  // Big-endian IEEE single float.

struct WordTrieVersion {
  be_int    magic;                // ( 0) must be 1.
  be_int    dict_version;         // ( 4) must be 2.
  char      collator_uca_version; // ( 8) must be 5.
  char      collator_version;     // ( 9) must be 0x31.
  be_short  dict_subversion;      // ( a) must be >4. (currently is 5).
  char x0c[0x10];
}; // sizeof = 28 (0x1c)

struct WordTrieDataFile {
  be_int    word_count;           // (1c) number of words in the data file.
  be_int    compilation_flags;    // (20)
  char x24[0x18];
  be_int    payload_offset;       // (3c) should be 0x80.
};

struct WordTrieIndexFile {
  be_float  root_usage_sum;       // (1c)
  be_int    compilation_flags;    // (20)
  char x24[0x0c];
  be_int    table_offset;         // (30) should be 0x80.
  be_int    x34;                  // (34) should be zero.
  be_int    x38;                  // (38) must be nonzero.
  be_int    trie_root_offset;     // (3c) 

  char buffers[...];

  CommonLettersTable  table;      // positioned at "table_offset".
  PackedTrieSiblings  root;       // positioned at "trie_root_offset".
};

struct CommonLettersTable {
  be_int    count;                // (80)
  be_int    reserved;
  struct {
    char      sort_key_bytes[4];
    be_int    corresponding_letter;
  } entries[/* count */];
};

```

Format of `PackedTrieSiblings`:
  * Read 1 byte as the flags bit, in which:
    * & 0x03: `patricia_key_size` - 1. The next `patricia_key_size` bytes will be read as the `patricia_key_bytes`.
    * & 0x0C: `has_child_offset_type`, where:
      * 0: No child offset,
      * 1: Read a big-endian 8-bit integer as the relative position of the `child_offset`.
      * 2: Read a big-endian 16-bit integer as the relative position of the `child_offset`.
      * 3: Read a big-endian 24-bit integer as the _absolute_ position of the `child_offset`.
    * & 0x40: `has_freq`. If this bit is set, read a byte, increase 1, and store as the `compacted_freq`.
    * & 0x20: `has_unigram_list_offset`. If this bit is set, read a 24-bit big-endian integer and store as the `word_offset`.
    * & 0x10: `has_word_termination_prob`. If this bit is set, read a byte, increase 1, and store as the `word_offset`. Assumes `has_unigram_list_offset` is cleared.
    * & 0x80: `more_sibling`. The node has no more siblings if this bit is cleared.

If the trie node has the `has_unigram_list_offset` bit set, we parse the following structure from the .dat file:
  * Read 1 byte as the offset bit, which indicates the bytes to skip (including this byte) for the next word.
  * Read 1 byte as the `'h'` bitfield, in which:
    * & 0x04: `has_probability`. Read 1 byte as the probability of this word. If the `compilation_flags` of the index file as bit 0x200 (`normalize_probability`) set, the probability will be rescaled by 1/255.
    * & 0x20: Read 1 byte as the `'c'` bitfield. If the `'c'` bitfield has bit 0x01 set, the `capitalization_mask` is set to 0x01.
    * & 0x01: `has_capitalization_mask`. Read a big-endian 32-bit integer as the `capitalization_mask`.
    * & 0x40: `has_d`. Read a big-endian 32-integer as the `'d'` field.
    * & 0x08: `has_string_length`. If this bit is set, and any of bit 0x30 of the `'c'` flag is set; or bit 0x800 (`dont_force_read_string_length`) of the compilation flag is cleared regardless the value of `'h'` is: Read a big-endian 16-integer as the (length(6)/reserved(5)/sort-key-length(5)) packed triplet.
    * & 0x10: `has_string`.
      * If this bit is set, read a null-terminated C string as the content of this word.
      * Otherwise, convert the input sort key back as the content of this word. If bit 0x08 of `'h'` is also set, parse a substitution list at the current cursor so far:
        1. Read 1 byte as the flags.
        1. Read a null-terminated string (resstr).
