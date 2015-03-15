

All projects of networkpx are designed to be localizable, but I don't know all languages in the world, so the translations must be provided by others. Fortunately, there are quite a number of volunteers helping me out on this. However, the projects here are still growing quite fast, and it is easy that new translation cannot be caught up.

To avoid localizers from having to dig the svn tree every time something changes, I have created this page as a quick reference on what is not translated.

In all networkpx projects, the **English** (en), **Spanish** (es) and **Chinese** (zh\_TW and zh\_CN) will always be fully translated. The rest are provided by volunteers and the availability will be listed in the tables below.
  * ✓ = Translation available.
  * ?  = Translation has been modified by the author. It needs to be checked.
  *    = Translation not available.

If you want to fill in the blanks or provide a completely new language, you can simply write a comment in [issue 11](https://code.google.com/p/networkpx/issues/detail?id=11).

**If you create a strings file, make sure its encoding is UTF-16.**

# iKeyEx #

The _lproj_'s are located in `/svn/trunk/hk.kennytm.iKeyEx/deb/System/Library/PreferenceBundles/iKeyEx.bundle/`.

| **Key** | **ar** | **de** | **en** | **es** | **fi** | **it** | **ja** | **nl** | **ru** | **tr** | **zh\_CN** | **zh\_TW** |
|:--------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-----------|:-----------|
| Additional Detail:\n\n |  |  | ✓ | ✓ |  | ✓ |  |  |  |  | ✓ | ✓ |
| Clear image cache | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |  | ✓ | ✓ |
| Clear layout cache | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |  | ✓ | ✓ |
| Clear lookup cache (WordTrie) |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |  | ✓ | ✓ |
| Clear lookup cache | ✓ |  |  |  |  |  |  |  |  |  |  |  |
| CLEAR\_IMAGE\_CACHE\_DESCRIPTION |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Crash Report (iKeyEx) |  |  | ✓ | ✓ |  | ✓ |  |  |  |  | ✓ | ✓ |
| Email diagnosis info |  |  | ✓ | ✓ |  | ✓ |  |  |  |  | ✓ | ✓ |
| Fix permissions | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |  | ✓ | ✓ |
| Found No Crash Reports |  |  | ✓ | ✓ |  | ✓ |  |  |  |  | ✓ | ✓ |
| iKeyEx Keyboards | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| International Keyboards |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Keyboards for Current Language | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Other Built-in Keyboards | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Report issues |  |  | ✓ | ✓ |  | ✓ |  |  |  |  | ✓ | ✓ |
| Send |  |  | ✓ | ✓ |  | ✓ |  |  |  |  | ✓ | ✓ |
| Send all crash reports |  |  | ✓ | ✓ |  | ✓ |  |  |  |  | ✓ | ✓ |
| SYSTEM\_IS\_FINE |  |  | ✓ | ✓ |  | ✓ |  |  |  |  | ✓ | ✓ |
| Troubleshooting | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |  | ✓ | ✓ |
| Uninstall iKeyEx | ✓ |  | ✓ | ✓ | ✓ | ✓ | ✓ |  | ✓ |  | ✓ | ✓ |

<a href='Hidden comment: 
Note: the complete message of CLEAR_IMAGE_CACHE_DESCRIPTION is _"iKeyEx caches some generated images for performance. However, if you change theme you must clear the cache to sync with it."_
'></a>

Note: the complete message of `SYSTEM_IS_FINE` is _There are no recent crashes related to iKeyEx. Do you still want to send this email?_.

# ℏClipboard #

The _lproj_'s are located in `/svn/trunk/hk.kennytm.hClipboard/deb/Library/iKeyEx/Keyboards/hClipboard.keyboard/` and `/svn/trunk/hk.kennytm.hClipboard/deb/Library/iKeyEx/Keyboards/hClipboard.keyboard/Preferences.bundle/`.

| **Key**                               | **ar** |**de** | **el** | **fi** | **it** | **ja** | **nl** | **ru** | **tr** |
|:--------------------------------------|:-------|:------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|
| Copy                                | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| Select from here...                 | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| Select to here and copy             | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| Move to beginning                   | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| Move to end                         | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| Switch to Clipboard                 | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| Switch to Templates                 | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| Add to templates                    | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| Select to here and add to templates | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| Clipboard is empty                  | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| No templates                        | ✓    | ✓  | ✓    | ✓   | ✓    | ✓    | ✓   | ✓    | ✓    |
| <Secure Text `%u` chars>            | ✓    | ✓  |      | ✓   | ✓    | ✓    | ✓   |      |       |
| Cannot paste                        | ✓    | ✓  |      | ✓   | ✓    | ✓    | ✓   |      |       |
| `SECURITY_BREACH_MESSAGE`           | ✓    | ✓  |      | ✓   | ✓    | ✓    | ✓   |      |       |
| Undo                                | ✓    | ✓  |      | ✓   | ✓    | ✓    | ✓   |      |       |
| Redo                                | ✓    | ✓  |      | ✓   | ✓    | ✓    | ✓   |      |       |
| Toggle editing mode                 | ✓    | ✓  |      | ✓   | ✓    | ✓    | ✓   |      |       |
| Cut                                 | ✓    | ✓  |      | ✓   | ✓    | ✓    | ✓   |      |       |
| Delete                              | ✓    | ✓  |      | ✓   | ✓    | ✓    | ✓   |      |       |

Note: the complete message of `SECURITY_BREACH_MESSAGE` is _"Cannot put secure data into non-secure text fields."_. `chars` is a short form of "characters".

| **Key**                                  | **ar** | **de** | **el** | **fi** | **it** | **ja** | **nl** | **ru** | **tr** |
|:-----------------------------------------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|
| Copying Secure Text                    | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      |      |
| Disabled                               | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      |      |
| Disable selection                      | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      |      |
| Enabled                                | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      |      |
| No sel.                                | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      |      |
| Default Editing                        | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      |      |
| Sound Effect                           | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      | ✓    |
| Clear Clipboard                        | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      |      |
| Clear Templates                        | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      |      |
| Cancel                                 | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      | ✓    |
| This action cannot be undone. Proceed? | ✓    | ✓    |     | ✓   | ✓    | ✓    | ✓    |      |      |

Note: `No sel.` here is the short form of `Disable selection` owe to space limitation.

# 5-Row QWERTY Keyboard #

The _lproj_'s are located in `/svn/trunk/hk.kennytm.5RowQWERTY/deb/Library/iKeyEx/Keyboards/5RowQWERTY.keyboard/Preferences.bundle/`.

| **Key** | **ar** | **en** | **es** | **it** | **zh\_CN** | **zh\_TW** |
|:--------|:-------|:-------|:-------|:-------|:-----------|:-----------|
| Numbers | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Top Row | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Palette | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Special characters | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Empty slot | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Control Keys | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Reset | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Layout | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| NumPad | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Off | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Alt Keyboard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |


# GriP #

GriP has 3 components that need to localized: GriP, MemoryWatcher and You've Got Mail.

For GriP, the _lproj_'s are in `/svn/trunk/hk.kennytm.grip/deb/System/Library/PreferenceBundles/GriP.bundle/`. **Don't fiddle with Duration.png** unless you know what to do. Tell me the translation of "Duration" instead.
| **Key** | **en** | **es** | **it** | **nl** | **pl** | **zh\_CN** | **zh\_TW** |
|:--------|:-------|:-------|:-------|:-------|:-------|:-----------|:-----------|
| Always | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| App decides | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| App name | ✓ | ✓ |  |  |  | ✓ | ✓ |
| at | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Background color | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Cancel | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Capacity | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Client port name | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Coalesce | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Coalesce all | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Coalesced | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Coalescent ID | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Customize | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Default | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Delete all logs | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Deliver immediately | ✓ | ✓ |  |  | ✓ | ✓ | ✓ |
| Detail | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Drop | ✓ | ✓ |  |  | ✓ | ✓ | ✓ |
| Emergency | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Enabled | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Game mode | ✓ | ✓ |  |  | ✓ | ✓ | ✓ |
| GriP Message Log | ✓ | ✓ |  |  |  | ✓ | ✓ |
| GriP Message Preview | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| High | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| High priority | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Icon | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Ignore | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Ignore all | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Ignored | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Keep last only | ✓ | ✓ |  |  | ✓ | ✓ | ✓ |
| Location | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Lower-priority GriP messages won't be delivered in Game mode. | ✓ | ✓ |  |  | ✓ | ✓ | ✓ |
| Message ID | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Message ignored | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Message name | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Message touched | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Messages | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Moderate | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Never | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Normal | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Per-App Settings | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Per-Priority Settings | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Preview | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Priority | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Queue | ✓ | ✓ |  |  | ✓ | ✓ | ✓ |
| Queue date | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Queuing | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Remove Settings | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Reset | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Resolve date | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Resolved messages | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Screen off | ✓ | ✓ |  |  | ✓ | ✓ | ✓ |
| Showing | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Shown date | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Status | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Stealth | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Sticky | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Suspension behavior | ✓ | ✓ |  |  | ✓ | ✓ | ✓ |
| Theme (Modal table) | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Theme | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| This is a preview of a %@ GriP message. | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Title | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Touch | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Touch all | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Touched | ✓ | ✓ |  |  |  | ✓ | ✓ |
| Very low | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Very low priority | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| View | ✓ | ✓ |  |  |  | ✓ | ✓ |
| You have closed or ignored the GriP preview message. | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| You have touched the GriP preview message. | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
|  Top right | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
|  Top left | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
|  Bottom right | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
|  Bottom left | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

For MemoryWatcher, the localizations are located directly inside `/svn/trunk/hk.kennytm.grip/Lbrary/MobileSubstrate/DynamicLibraries/MemoryWatcher.plist`. This is unlike the other projects that _lproj_'s are used. The file is saved as a binary plist, so you may need to convert it into XML, or edit it by Property List Editor.

| **Key**           | **it** | **nl** | **pl** |
|:------------------|:-------|:-------|:-------|
| Memory Warning  | ✓    | ✓   |  ✓   |
| Memory Urgent   | ✓    | ✓   |  ✓   |
| Memory Critical |  ✓   | ✓   |  ✓   |

For You've Got Mail, the localizations are located directly inside `/svn/trunk/hk.kennytm.grip/Lbrary/MobileSubstrate/DynamicLibraries/YouveGotMail.plist`.

| **Key**        | **it** | **nl** | **pl** |
|:---------------|:-------|:-------|:-------|
| 1 new mail   |  ?   |  ?   |  ✓   |
| %d new mails |  ?   |  ?   |  ✓   |
| multiple accounts |  |      |      |