

# Introduction #

iKeyEx is a keyboard extension framework, that allows users to customize keyboard layouts and input methods. With iKeyEx you can access to dozens of keyboards not built into the vanilla iPhone, like:

  * Keyboards for Armenian, Hindi, Farsi, Georgian etc.
  * Non-QWERTY keyboards, such as Dvorak and Colemak.
  * 5-row keyboards.
  * Native interface for Chinese IME Apple don't both to include, e.g. Cangjie.

Developers:
  * If you want to create keyboard layouts please check: [Creating\_Keyboard\_Bundles](Creating_Keyboard_Bundles.md).
  * If you want to make a Chinese input method please check: [Chinese\_input\_method](Chinese_input_method.md).

# Settings #
iKeyEx does not include an icon on the home screen. Settings for iKeyEx is integrated into the "Settings" application.
> ![http://x48.xanga.com/80183342d6067260010100/w207085249.png](http://x48.xanga.com/80183342d6067260010100/w207085249.png) ![http://x6b.xanga.com/6be83175d6076260010103/w207085251.png](http://x6b.xanga.com/6be83175d6076260010103/w207085251.png)

## Changing the list of keyboard ##
In **Keyboards** you may add, remove or rearrange the list of active keyboards.
> ![http://xff.xanga.com/8bdf2b2519c30260010099/w207085248.png](http://xff.xanga.com/8bdf2b2519c30260010099/w207085248.png)

## Mix and match a new keyboard ##
Conceptually, a keyboard consists of 2 parts: the **layout** and **input manager**. In **Mix and match**, you can use existing layout and input manager to construct a new keyboard.

> _**Important:** Mix and match cannot create new_layouts_and_input managers_. In particular, it won't create a 5 row keyboard out of nothing. You must install the corresponding package in Cydia for such to appear._

## Keyboard chooser ##
Rotating through the active keyboard lists become frustrating when you have got a lot of active keyboards. The **Keyboard chooser** is introduced to let you directly jump to the wanted keyboard.
> ![http://x94.xanga.com/762f5a2502730260010689/w207085715.png](http://x94.xanga.com/762f5a2502730260010689/w207085715.png)

There are 3 settings:
  * **Hold**: Hold down the international key (the "globe") for 1 second to invoke the keyboard chooser.
  * **Tap**: Tap the international key once to invoke.
  * **Disable**.

## Customize ##
Some keyboard layouts, e.g. 5 Row QWERTY provide additional settings. You can change them here.

## Delete cache ##
To speed up keyboard loading, iKeyEx generates cache file in `/var/mobile/Library/Keyboards/`. You can delete them here.

## .cin Input method engine ##
iKeyEx has its own input method engine for interpreting .cin IMEs. These settings configure how the engine works.

# Known issues #
  * iKeyEx won't work in Cydia. This is expected – imagine iKeyEx crashing any app, and if Cydia loads it as well, you can't uninstall this buggy extension.
  * iKeyEx can consume up to 3 MiB of RAM per keyboard. This is largely due to how memory-inefficient Apple chooses to represent the keyboards in code. iKeyEx is not the cause of this.

