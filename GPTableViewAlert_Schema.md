# Specification #

```

// TODO: Transform into human-readable format.

struct GPModalTableViewPList {
  array<Button> buttons = nil;  // Buttons of the alert.
  string title;                 // Alert title.
  array<Entry> entries;         // Table entries.
};

union Button {
  struct {
    string label = "Cancel";      // Label of the button.
    string id = label;            // Identifier of the button.
  };
  ButtonLabel;
};

union ButtonLabel {
  PredefinedButtonLabel;  // Predefined label.
  string;                 // Use this string as label.
}

enum PredefinedButtonLabel {
  Done, Cancel, Edit, Save, Add,
  FlexibleSpace, FixedSpace,
  Compose, Reply, Action, Organize,
  Bookmarks, Search, Refresh, Stop,
  Camera, Trash,
  Play, Pause, Rewind, FastForward,
  ActivityIndicator
};

union Entry {
 struct {
  bool header = false;        // Whether to treat this entry as a section header.
  string title;               // Entry title.
  string id = title;          // Identifier of this entry. Should be unique.
  string subtitle = null :: header == false;  // subtitle.
  bool compact = false :: subtitle != null;   // Move the subtitle to inline with the title. This makes the title like an icon.
  bool noselect = false :: header == false;  // Mark that this item cannot be selected.
  Icon icon = null :: header == false;           // Icon of the entry.
  bool reorder = false :: header == false && accessory == null;       // Whether to display the reorder control for this row.
  bool delete = false :: header == false; // Whether to support deletion.
  string description = null :: header == false;    // description.
  bool edit = false :: header == false;   // Make the description as an editing text view.
  int lines = 0 :: description != null;   // _Maximum_ number of lines the description view should occupy. Put a nonpositive number here for unbounded height when edit == false.
  bool secure = false :: lines == 1 && edit == true; // The editing text view contains secure text (i.e. shown as • and disable copy&cut.)
  string placeholder = "" :: lines == 1 && edit == true; // The placeholder of the editing text view when it is empty.
  bool html = false :: lines != 1 && edit == true; // Set the text view to show HTML instead of plain text.
  bool readonly = false :: edit == true; // "editable" but "read only".
  Accessory accessory = null :: header == false && reorder == false; // accessory
  Keyboard keyboard = "ASCIICapable" :: edit == true; // keyboard type to use.
  ABProperty addressbook = null :: edit == true;   // Allow access to address book.
 };
 string;                     // Just the title.
};

union Icon {
  data(image);                       // Icon as image.
  string(bundleID);                  // Icon with display identifier
  string(regex/^[\uE000-\uE5FF]$/);  // Emoji icon.
};

enum Accessory {
    Checkmark,
    DisclosureIndicator,
    DisclosureButton,
};

enum Keyboard {
  ASCIICapable,
  NumbersAndPunctuation,
  URL,
  NumberPad,
  PhonePad,
  NamePhonePad,
  EmailAddress
};

enum ABProperty {
  Address,
  CreationDate,
  Date,
  Department,
  Email,
  FirstNamePhonetic,
  FirstName,
  InstantMessage,
  JobTitle,
  Kind,
  LastNamePhonetic,
  LastName,
  MiddleNamePhonetic,
  MiddleName,
  ModificationDate,
  Nickname,
  Note,
  Organization,
  Phone,
  Prefix,
  RelatedNames,
  Suffix,
  URL
};

```

# Delegate methods #

```
@protocal GPModalTableViewDelegate
@optional
-(void)modalTableView:(GPModalTableViewClient*)client clickedButton:(NSString*)identifier;
-(void)modalTableView:(GPModalTableViewClient*)client movedItem:(NSString*)targetID below:(NSString*)belowID;
-(void)modalTableView:(GPModalTableViewClient*)client deletedItem:(NSString*)item;
-(void)modalTableView:(GPModalTableViewClient*)client selectedItem:(NSString*)item;
-(void)modalTableView:(GPModalTableViewClient*)client changedDescription:(NSString*)newDescription forItem:(NSString*)item;
-(void)modalTableView:(GPModalTableViewClient*)client tappedAccessoryButtonInItem:(NSString*)item;
-(void)modalTableViewDismissed:(GPModalTableViewClient*)client;
@end
```