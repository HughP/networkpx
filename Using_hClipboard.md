
---




# Introduction #

ℏClipboard is a global copy and paste solution for the iPhoneOS 2.2 based on iKeyEx.

# Copying #

## Copying the whole text field ##
When the keyboard appears, switch to ℏClipboard by clicking the International button (the Globe) repeatedly. Then hit the **Copy** button. The entire content of the text field should now appear in the top of the clipboard.

![http://x99.xanga.com/207f157260c30233906182/w184620453.png](http://x99.xanga.com/207f157260c30233906182/w184620453.png)

## Copying a portion of text ##
Move the the beginning of the range of text you want to copy. Hit the **Select from here...** button. Then move to the end and hit the **Select to here and copy** button (which is the same button) again. The entry will now appear in the clipboard.

![http://xef.xanga.com/16af037060c30233906183/w184620454.png](http://xef.xanga.com/16af037060c30233906183/w184620454.png) ![http://xac.xanga.com/b2af0b65c7233233906185/w184620456.png](http://xac.xanga.com/b2af0b65c7233233906185/w184620456.png)

You may use the **Move to beginning** (←) and **Move to end** (→) buttons to aid navigation.

## Copying Web Page Content ##
You have to install a bookmarklet to copy from web page content. See CopyingTextFromSafari for instructions.

# Pasting #

Just click on any item on the clipboard to paste it.

If you need to access some older items, just scroll vertically.

![http://xd0.xanga.com/adff136561531233906190/w184620460.png](http://xd0.xanga.com/adff136561531233906190/w184620460.png)

# Undoing #

If you pasted something wrongly, you can click Undo (⤺) to revert it.

Note that the current implementation of the undo manager is very primitive. There is lots of issues floating around it, e.g. if you pressed the space key or return key in between a paste and an undo the text won't be properly restored. Expect to see improvement in later versions.

> <font color='red'>Do not use Undo in MobileTerminal. It will crash MobileTerminal</font>

# Deleting and Reordering clipboard items #

Swipe horizontally on any items will reveal a **Delete** button. Hit this button and the item will be gone.

![http://xc9.xanga.com/e4ef316447232233906186/w184620457.png](http://xc9.xanga.com/e4ef316447232233906186/w184620457.png)

Additionally, you can click the **Toggle Editing Mode** button (ⓘ) to reorder and delete items in bulk.

![http://x68.xanga.com/567f1b7361530233906192/w184620462.png](http://x68.xanga.com/567f1b7361530233906192/w184620462.png)

# Templates #

ℏClipboard supports a secondary clipboard called Templates. Hit the **Switch to Templates/Clipboard** button on the lower-left corner to switch between the two.

The main difference between Templates and Clipboard is that Templates can hold infinitely many items, while Clipboard has an upper limit of 10 items. Therefore, Templates is better for storing more permanent texts like user name while Clipboard is better for temporary things like activation code.

# Secure Text Management #

Starting from version 0.1-3, ℏClipboard can copy secure texts (e.g. password and pass phrase). However, it is very awkward to see your password shown in clear. Therefore, in ℏClipboard secure texts will be masked, and text copied from the password field and only be pasted in another password field.

![http://xe5.xanga.com/0acf346479332233906367/w184620619.png](http://xe5.xanga.com/0acf346479332233906367/w184620619.png)

> <strong>Note:</strong> Internally, these secure texts are still stored as _clear text_. If you have absolute secret that cannot be viewed by anyone, don't use ℏClipboard's secure text copying feature.

# Preferences #

There are some settings for ℏClipboard you can play with. To access the preferences pane, go to **Settings** → **iKeyEx** → **ℏClipboard**.

![http://x39.xanga.com/baef067265433233906393/w184620622.png](http://x39.xanga.com/baef067265433233906393/w184620622.png) ![http://xf9.xanga.com/7f5f3765c2532233906396/w184620624.png](http://xf9.xanga.com/7f5f3765c2532233906396/w184620624.png) ![http://x95.xanga.com/10ef216462535233906398/w184620626.png](http://x95.xanga.com/10ef216462535233906398/w184620626.png)

# Known Issues #
iKeyEx is disabled when IntelliScreen is installed ([issue 16](https://code.google.com/p/networkpx/issues/detail?id=16)).

Some applications use a text field to intercept keyboard input instead of actual displaying. ℏClipboard can never copy on these applications. Examples include:
  * [MobileTerminal](http://code.google.com/p/mobileterminal/)
  * VNC clients, e.g. Jaadu VNC (Jaadu VNC does not even support pasting).
  * "Enhanced" text editors, e.g. WritePad (MagicPad, on the other hand, works nicely with ℏClipboard.)

Some texts are read-only, so no clipboards will be displayed. You can't copy any text from it using keyboard-based clipboard solutions. Examples include:
  * Received text in MobileSMS, iRealSMS, etc.
  * Received mails in MobileMail -- click Reply to show the keyboard.
  * Web contents -- In a browser (MobileSafari, myFox, etc.) you may want to use [these bookmarklets](CopyingTextFromSafari.md) to workaround it.
  * PDF, Word Documents, etc.

# Alternative Solutions #
Copy and paste is a much-requested functionality on the iPhoneOS that Apple has repeatedly refused to add. Therefore, it is expected to see many unofficial clipboard implementations in the wild. Here lists some of them besides ℏClipboard:
  * [Clippy](http://www.installerepo.com/ispazio/clippy/) is another excellent copy-and-paste solution of iPhone. It provides a system-wise multi-entry clipboard, and is probably more accessible than ℏClipboard because you don't need to leave the current input mode, and more intuitive because the selection range is clearly shown.
  * [CopierciN](http://code.google.com/p/copiercin/) and many "enhanced" text editors on AppStore such as MagicPad and WritePad provide internal single-entry clipboards independent of the keyboard. Of course, you can't expect these clipboard to work outside of their own apps.
  * [OpenClip](http://www.openclip.org/main.php) was a framework for single-entry cross-application clipboard for AppStore apps, but was broken by Apple's sandbox model on 2.1.