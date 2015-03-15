<font color='red'><b>Deprecated page.</b> Please bookmark <a href='http://www.iphonedevwiki.net/index.php?title=Preferences_specifier_plist'>http://www.iphonedevwiki.net/index.php?title=Preferences_specifier_plist</a> instead, thank you.</font>


---




# Introduction #

This document provides the specification of the .plist file that specifies the layout of an iPhone preference pane.

The specification comes from reverse engineering the `SpecifiersFromPlist()` and `+[PSTableCell xxxx:]` functions in the Preferences framework.

# Root level #

The root level of the plist may contain these keys:

| **key** | **type** | **meaning** |
|:--------|:---------|:------------|
| title | localizable string | Title of the preference pane. |
| items | array | Array of specifier definitions. |
| id | string | Specifier ID. Usage unknown. |

## Localization ##

Some strings, e.g. the _title_ is localizable.

Suppose the plist is named `MySettings.plist`, then the corresponding strings file must be named `MySettings.strings`.

# Individual Items #

The keys can also be obtained later by `-[PSSpecifier propertyForKey:]`. You can use anything in your controller for further customization. This table lists the internal ones:

## General keys ##

| **key** | **type** | **meaning** | **depends** |
|:--------|:---------|:------------|:------------|
| requiredCapabilities | array | Required capabilities of the device such that this specifier can be shown. | - |
| bundle | filename (string) | Bundle file name. This bundle will be loaded for additional resources. | - |
| cell | string | Specifier cell type. | - |
| label | localizable string | Label of specifier. | - |
| id | string | Specifier ID. | - |
| get | selector (string) | Getter. | - |
| set | selector (string) | Setter. | - |
| action | selector (string) | Action | - |
| enabled | bool | Whether the control is enabled by default. | - |
| defaults | file name (string) | The user defaults associated with this specifier. | - |
| key | string | Key of the user defaults. | _defaults_ ≠ nil |
| default | any | Default value of control. | - |
| negate | bool | If the key in the user defaults is a boolean, invert the value displayed. | - |
| PostNotification | string | Darwin Notification to post when the preference is changed | - |

## bundle-dependent keys ##

The following keys are meaningful when _bundle_ is present. It is useful for loading extra resources and custom code.

| **key** | **type** | **meaning** | **depends** |
|:--------|:---------|:------------|:------------|
| bundle | filename (string) | Bundle file name. This bundle will be loaded for additional resources. | - |
| internal | bool | Directory to search for the bundle.<br />If true, search in `/AppleInternal/Library/PreferenceBundles/`.<br />If false, search in `/System/Library/PreferenceBundles/`. | _bundle_ ≠ nil |
| isController | bool | Whether the bundle contains a controller class. | _bundle_ ≠ nil |
| overridePrincipalClass | bool | Overrides the principal class by the detail controller when bundle has a controller. | _isController_ = ✓ |
| detail | class name (string) | Detail controller class. | - |
| pane | class name (string) | Edit pane class.<br />If _bundle_ is absent, the edit pane class is obtained from the current bundle.<br />Default value is `"PSEditingPane"`. | _detail_ ≠ nil |
| hasIcon | bool | Whether the specifier will have an icon. | _bundle_ ≠ nil |
| icon | filename (string) | File name of the icon to use.<br />Default value is `icon.png`. The height of the icon should be 29 px. | _hasIcon_ = ✓ |
| cellClass | class name (string) | Customized cell class | - |
| customControllerClass | class name (string) | Custom controller class to use when the view become visible. | - |

If you just want to use _pane_ without messing up the detail controller, supply the key-value pair
```
detail = "PSDetailController";
```

If you want to dynamically add a specifier for a PSLinkCell linking to a bundle, do it like this:
```
PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:@"title"
                                                        target:self
                                                           set:NULL
                                                           get:NULL
                                                        detail:Nil
                                                          cell:PSLinkCell
                                                          edit:Nil];
NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/prefs.bundle"];
[specifier setProperty:bundle forKey:@"lazy-bundle"];
[specifier setProperty:@"lazyLoadBundle:" forKey:@"action"];
// Add specifier to the PSListController
```

## Editing cells ##

These keys are specific to editing cells.

| **key** | **type** | **meaning** | **depends** |
|:--------|:---------|:------------|:------------|
| autoCaps | string | Autocapitalization type for cells that requires a keyboard.<br />Must be one of: `"sentences"`, `"words"`, `"all"`. | - |
| keyboard | string | Autocapitalization type for cells that requires a keyboard.<br />Must be one of: `"numbers"`, `"phone"`. | - |
| prompt | localizable string | Setup prompt. | _cell_ ∈ (`"PSEditTextCell"`, `"PSSecureEditTextCell"`) |
| okTitle | localizable string | Title for OK button in setup prompt. | _prompt_ ≠ nil |
| cancelTitle | localizable string | Title for Cancel button in setup prompt. | _prompt_ ≠ nil |
| placeholder | localizable string | Placeholder. | _cell_ ∈ (`"PSEditTextCell"`, `"PSSecureEditTextCell"`) |
| suffix | localizable string | Suffix. | _cell_ ∈ (`"PSEditTextCell"`, `"PSSecureEditTextCell"`) |
| isIP | bool | Input field intended for entering IP address<br />(Use Numbers keyboard) | _cell_ = `"PSEditTextCell"` **or** ???? |
| isURL | bool | Input field intended for entering URL<br />(Use URL keyboard) | _cell_ = `"PSEditTextCell"` **or** ???? |
| isNumeric | bool | Input field intended for entering numbers<br />(Use NumberPad keyboard) | _cell_ = `"PSEditTextCell"` **or** ???? |
| isEmail | bool | Input field intended for entering e-mail<br />(Use EmailAddress keyboard) | _cell_ = `"PSEditTextCell"` **or** ???? |
| isEmailAdressing | bool | Input field intended for entering e-mail addressing<br />(Use EmailAddress keyboard) | _cell_ = `"PSEditTextCell"` **or** ???? |
| bestGuess | selector (string) | Initial value of text field. | _cell_ ∈ (`"PSEditTextCell"`, `"PSSecureEditTextCell"`) |
| noAutoCorrect | bool | Disable auto-correction. | _cell_ ∈ (`"PSEditTextCell"`, `"PSSecureEditTextCell"`) |

## List cells ##

These keys are specific to list cells.

| **key** | **type** | **meaning** | **depends** |
|:--------|:---------|:------------|:------------|
| validValues | array of strings | List of values to choose from. | _cell_ ∈ (`"PSLinkListCell"`, `"PSSegmentCell"`) |
| validTitles | array of localizable strings | Titles corresponding to the list of values. | _cell_ ∈ (`"PSLinkListCell"`, `"PSSegmentCell"`) |
| shortTitles | array of localizable strings | Short titles | _cell_ ∈ (`"PSLinkListCell"`, `"PSSegmentCell"`) |
| valuesDataSource | selector (string) | Selector to call to get the list of values dynamically. | _cell_ ∈ (`"PSLinkListCell"`, `"PSSegmentCell"`)<br />**and** _validValues_ = nil |
| titlesDataSource | selector (string) | Selector to call to get the list of titles dynamically. | _cell_ ∈ (`"PSLinkListCell"`, `"PSSegmentCell"`)<br />**and** _validTitles_ = nil |
| staticTextMessage | localizable string | Static text message (?). | _cell_ = `"PSLinkListCell"` |

In order to make a PSLinkListCell actually work like a list, supply the key-value pair
```
detail = "PSListItemsController";
```
also.

## Slider and switch cells ##

These keys are specific to slider and switch cells.

| **key** | **type** | **meaning** | **depends** |
|:--------|:---------|:------------|:------------|
| rightImage | file name (string) | Image displayed next to the slider on the right. | _cell_ = `"PSSliderCell"` |
| leftImage | file name (string) | Image displayed next to the slider on the left. | _cell_ = `"PSSliderCell"` |
| min | float | Minimum value of slider | _cell_ = `"PSSliderCell"` |
| max | float | Minimum value of slider | _cell_ = `"PSSliderCell"` |
| showValue | bool | Show the value | _cell_ = `"PSSliderCell"` |
| alternateColors | bool | Use alternate color of the cell (orange instead of blue) | _cell_ ∈ (`"PSSwitchCell"`) |
| control-loading | ??? | ??? | _cell_ = `"PSSwitchCell"` |

## Miscellaneous control cells ##

These keys are specific to other control cells.

| **key** | **type** | **meaning** | **depends** |
|:--------|:---------|:------------|:------------|
| alignment | integer | Text alignment.<br />2 = center. | _cell_ ∈ (`"PSGroupCell"`, `"PSStaticTextCell"`) |
| confirmation | dictionary | Definitions of the confirmation sheet before action is performed. | _cell_ ∈ (`"PSSwitchCell"`, `"PSButtonCell"`) |
| isDestructive | bool | Whether the action to be performed is destructive.<br />The OK button will be in red if true. | _confirmation_ ≠ nil |
| isStaticText | bool | Whether the cells in this group has static text.<br />Used in conjunction with PSStaticTextCell. | _cell_ = `"PSGroupCell"` |
| iconImage | ??? | ??? | - |
| height | float | Height of text view | _cell_ = `"PSTextViewCell"` |
| dontIndentOnRemove | bool | Don't indent on remove (?) | - |

# Explanation on some special keys #

## requiredCapabilities ##

Capabilities are queried from the function `GSSystemGetCapability(0)`. The capabilities can be found from the file `/System/Library/CoreServices/SpringBoard.app/<model>.plist`.

| **Capability** | **iPhone 2G** (M68AP) | **iPod Touch 1G** (N45AP) | **iPod Touch 2G** (N72AP) | **simulator** |
|:---------------|:----------------------|:--------------------------|:--------------------------|:--------------|
| bluetooth | 1 |  |  | 0 |
| camera | 1 |  |  | 0 |
| delaySleepForHeadsetClick | 1 |  |  |  |
| deviceName | `"iPhone"` | `"iPod"` | `"iPod"` | `"iPhone Simulator"` |
| editableUserData | 1 | 1 | 1 | 1 |
| international | 1 |  |  | 1 |
| ringer-switch | 1 |  |  | 1 |
| standAloneContacts | 1 | 1 | 1 | 1 |
| telephony | `{ maximumGeneration = 2.5; }` |  |  | 1 |
| unifiedIPod | 1 |  |  | 1 |
| volume-buttons | 1 |  |  | 1 |
| piezo-clicker |  | 1 | 0 |  |
| victoria |  |  | 1 |  |
| activation |  |  |  | 0 |
| wifi |  |  |  |  |
| displayIDs |  |  |  |  |
(this list is incomplete. for some reason there is no M82AP.plist.)

The content of _requiredCapabilities_ can be a string or a dictionary. If the value is declared as an string, the device will pass when all required capabilities are satisfied; if it is a dictionary, there is an additional requirement that the values of the capabilities are equal/findable, e.g.
```
 requiredCapabilities = (bluetooth, telephony, {unifiedIPod = 0;}, {displayIDs = "com.apple.mobilephone";});
```

## cell ##
_cell_ must be one of:
  * PSGroupCell
  * PSLinkCell
  * PSLinkListCell
  * PSListItemCell
  * PSTitleValueCell
  * PSSliderCell
  * PSSwitchCell
  * PSStaticTextCell
  * PSEditTextCell
  * PSSegmentCell
  * PSGiantIconCell
  * PSGiantCell
  * PSSecureEditTextCell
  * PSButtonCell
  * PSEditTextViewCell

The cell type is actually determined from the class method `+[PSTableCell cellTypeFromString:]`.

## confirmation ##

_confirmation_ itself is a dictionary containing the following fields:
| **key** | **type** | **meaning** |
|:--------|:---------|:------------|
| prompt | localizable string | Content of confirmation sheet. |
| cancelTitle | localizable string | Title of the cancel button. |
| okTitle | localizable string | Title of the OK button. |
| title | localizable string | Title of confirmation sheet. |

# Classes #

## isController ##

If you declare the bundle _isController_, the executable code must have a subclass of `PSBundleController` as the principle (first) class. In the controller, you should overload the message:
```
 -(NSArray*)specifiersWithSpecifier:(PSSpecifier*)spec;
```
which returns an array of PSSpecifier, inserted right before the current specifier.

The controller class will be internally called like this:
```
// callerList & specifier are arguments of SpecifiersFromPlist
  PSBundleController* controller = [[MyControllerClass alloc] initWithParentListController:callerList];
  [retval addObjectsFromArray:[controller specifiersWithSpecifier:specifier]];
```

You can refer to the member `_parent` to get the parent list controller if you don't want to overload `initWithParentListController:`.

## detail ##

The _detail_ controller class should conform to this protocol:
```
@protocol PSDetailController <PSViewController>
-(id)initForContentSize:(CGSize)size;
-(void)viewWillBecomeVisible:(PSSpecifier*)spec;
-(void)handleURL:(NSURL*)url;
@optional
+(void)validateSpecifier:(PSSpecifier*)srcSpecifier;
@end
```
There is already a PSDetailController class in the Preferences framework which you should subclass from.

The _detail_ controller class will be sent a `+(void)validateSpecifier:(PSSpecifier*)` message if one exists right after the bundle is lazy-loaded:
```
@implementation PSRootController
...
-(void)lazyLoadBundle:(PSSpecifier*)srcSpecifier {
	...
	if ([srcSpecifier->detailControllerClass respondsToSelector:@selector(validateSpecifier:)])
		[srcSpecifier->detailControllerClass validateSpecifier:srcSpecifier];
}
...
@end
```

Whenever a view becomes visible, a detail controller class instance will be allocated with `-(id)initForContentSize:(CGSize)`, and then call `-(void)viewWillBecomeVisible:(PSSpecifier*)` to notify that the view becomes visibile. There is also some other calls to the controller but you'd better leave them unoverloaded.
```
...
id<PSDetailController> detailController = [[[spec->detailControllerClass alloc]
                                                                         initForContentSize:someListController.view.bounds.size]
                                                                         autorelease];
detailController.rootController = _parentController.rootController;
detailController.parentController = _parentController;
[detailController viewWillBecomeVisible:spec];
...
```

## pane ##

The edit pane class is useless unless a PSDetailController subclass is used. The class itself is invoked in `-[PSDetailController viewWillBecomeVisible:]`.

This class must be a subclass of UIView and conforms to the protocol:
```
@protocol PSEditingPane
+(CGSize)defaultSize;
+(UIColor*)defaultBackgroundColor;
-(void)setDelegate:(id)del;		// del usually is of type PSDetailController*
@property(retain) PSSpecifier* preferenceSpecifier;
@property(retain) id preferenceValue;
-(BOOL)handlesDoneButton;	// return NO if you don't want to save changes.
-(BOOL)requiresKeyboard;

@optional
-(void)viewWillRedisplay;

@end
```
There is already a PSEditingPane class in the Preferences framework which you can subclass from.

## cellClass ##

_cellClass_ allows you to use customized cells. It should be a subclass of PSTableCell.

## customControllerClass ##

_customControllerClass_ is only used when a setup controller's view become visible. It replaces the default PSSetupListController.

# Using PSLinkCell #

PSLinkCell is useful for linking to sub-preference-panes. The simplest example just needs 2 keys:
```
{ cell  = PSLinkCell;
  label = "Settings-iPhone"; }
```
The _label_ is the important part. When user clicked on the link cell, iPhoneOS will use the **unlocalized** _label_ as the file name of the plist for the next pane. For example in above, the main settings screen will appear.

If you use just 2 keys, only plists inside Preferences.app can be loaded. In order to load your own plist, you must use a custom subclass of PSListController in detail:
```
{ cell   = PSLinkCell;
  label  = "My Awesome Pane";
  detail = MyListController; }
```
`MyListController` can simply be an empty subclass of PSListController:
```
@interface MyListController : PSListController {}
@end
@implementation MyListController
@end
```
The key thing is when you place `MyListController` inside your bundle, its `bundle` property will return your bundle which `My Awesome Pane.plist` can be found.

# Selector signatures #

## valuesDataSource and titlesDataSource ##

_valuesDataSource_ and _titlesDataSource_ are performed on the _target_ sent from `-[PSListController loadSpecifiersFromPlistName:target:]`. They must return an NSArray containing the values and (localized) titles respectively.

The signature should be:
```
-(NSArray*)dataFromTarget:(id)target;
```

## get and bestGuess ##

_get_ and _bestGuess_ should have signature
```
-(NSObject*)somethingForSpecifier:(PSSpecifier*)spec;
```
The return value depends on the type of specifier, e.g. for a text field it should return an NSString, while for a switch it should return an NSNumber with boolValue.

## set ##

_set_ should have signature
```
-(void)setSomething:(NSObject*)sth forSpecifier:(PSSpecifier*)spec;
```

## action ##

_action_ should have signature
```
-(void)speciferPerformedAction:(PSSpecifier*)spec;
```

Of course, you can ignore extra parameters, so `-(void)specifierPerformedAction` is a valid signature too.

# Disassembly #

This disassembly of `-[PSListController loadSpecifiersFromPlistName:target:]` is necessary to understand the signature of `SpecifiersFromPlist()`

```
-(NSArray*)loadSpecifiersFromPlistName:(NSString*)plistName target:(id)target {
	NSBundle* curBundle = [self bundle];
	NSDictionary* plist = [[NSDictionary alloc] initWithContentsOfFile:[curBundle pathForResource:plistName ofType:@"plist"]];
	NSString* specifierID;
	NSArray* result = SpecifiersFromPlist(
		plist,
		self->_specifier,
		target,
		plistName,
		curBundle,
		&self->_title,
		&specifierID,
		self,
		&self->_bundleControllers
	);
	[plist release];
	self.specifierID = specifierID;
	[specifierID release];
	return result;
}
```

From this we see that the signature is
```
NSArray* SpecifiersFromPlist (
	NSDictionary*     plist,      // r0
	PSSpecifier*      prevSpec,   // r1
	id                target,     // r2
	NSString*         plistName,  // r3
	NSBundle*         curBundle,           // sp[0x124]
	NSString**        pTitle,              // sp[0x128]
	NSString**        pSpecifierID,        // sp[0x12C]
	PSListController* callerList,          // sp[0x130]
	NSMutableArray**  pBundleControllers   // sp[0x134]
);
```

(The 0x124 offset is due to `stmdb` of 8 registers and 0x104 bytes reserved for local variables.)

# References #

  * [iPhone Settings Within Settings.app](http://www.touchrepo.com/guides/preferencebundles/PreferenceBundles.doc)