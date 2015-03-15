iNotifyEx is the successor of GriP that will replace the CFMessagePort-based backend with MIG subsystem for higher performance and robustness.

(The Objective-C based GriP front-end will still be kept.)

As a redesign, iNotifyEx shall have characteristics of following APIs:
  * Growl-like notifications
  * Android-like notifications
  * Some GriP-specific addition
  * Some iNotifyEx-specific addition

[Growl-like notification API](http://growl.info/documentation/developer/implementing-growl.php?lang=cocoa) has the following characteristics:
  * The user has the ultimate decision how the notifications be presented.
  * _Tickets_ (per-app settings) and _priority_ (per-message-group settings).
  * Coalition.
  * Target-action pattern for server reply.
  * How the notification should be shown is abstracted out as a _theme_.

[Android-like notification API](http://developer.android.com/reference/android/app/Notification.html) has the following characteristics:
  * Actions are sent together with the notification as a _PendingIntent_.
  * Ticker text.
  * The view is customizable via `contentView`.

GriP-specific additions are:
  * Suspension behavior, i.e. lock screen mode and game mode.
  * ~~GriP Modal Table View.~~

iNotifyEx-specific additions currently include:
  * Multiple buttons (actions) in a notification
  * Sub-notification grouping using coalescent ID.


There are some contradictions between the APIs. In particular, the developer-oriented `contentView` is mutually exclusive with the user-oriented theme capability. However, as `setLatestEventInfo` seems more common, `contentView` is a less important feature. As a result, iNotifyEx will send the following in notification packet:
  * Ticket (Growl).
  * Message name (Growl).
  * Title (Growl; Android — 1st line of `tickerText` and `contentTitle`)
  * Subtitle (Android — `contentText` in `setLatestEventInfo `).
  * Detail
  * Icon (≥29x29.)
  * Priority (Growl), Sticky (Growl).
  * Coalescent ID (Growl)
  * Confirm action (Android ~ contentIntent)
  * Ignore action (Android ~ deleteIntent)
  * Multi-buttons (as arrays of Button title / Remote action pairs)
  * Super-notification title, subtitle, icon. (meaningful only when Coalescent ID is not null.)

(The super-notification priority and sticky will be taken as the maximum of those of all sub-notifications. Confirming and ignoring a super-notification is equivalent to doing so on all sub-notifications)

## Remote Actions ##

The actions will be executed remotely. These remote actions will be represented as strings  in the form
  * **module::action** arg1 arg2 arg3 ...
If the `module::` part is missing, iNotifyEx will assume the module is `std`. These modules, called _Action Providers_ shall reside in `/Library/Application Support/iNotifyEx/Action Providers/module.dylib`. The remote action should be implemented as a C function with prototype
  * extern void _action_(CFArrayRef argv);
Each argument of _argv_ must be a CFString, and the 0th element is that _module::action_.

Arguments are space separated but parenthesis-balanced. That means
  * **foo** `bar (baz [blah 42] hello) world "abc def"`
will be considered having 5 arguments (foo, `bar`, `(baz [blah 42] hello)`, `world`, `abc def`).

> _Note:_argv_will be autoreleased after the function ends. Retain it if you want to use it later._

Standard remote actions include:
  * **open\_url** _url_
  * **launch** _displayID_ `[`_remoteNotificationUserInfo_`]`
  * **darwin`_`notification** _notificationName_
  * **distributed`_`message** _centerName_ _messageName_ `[`_userInfo_`]`
  * **notification** _messageName_ `[`_userInfo_`]` `[`_objectPointer_`]`
  * **sequence** _action1_ _action2_ _action3_ ...
  * **confirm** _action_ _confirmTitle_ `[`_message_`]` `[` normal | destructive `]`

## Theming ##
http://twitpic.com/ne1vq

### Raw Theme API ###
Currently only 1 function is needed.

  * extern void **INXShowNotification**(CFBundleRef thisBundle, CFStringRef title, CFStringRef subtitle, CFDataRef detail, CFTypeRef icon, int priority, bool sticky, CFStringRef coal\_id, CFStringRef super\_title, CFStringRef super\_subtitle, CFStringRef super\_icon);

Should be a bundle as $INXROOT/Themes/myTheme.theme.

### Activation ###
Depends on libactivator to avoid reinventing the wheel :)

<!--
### Simple theme ###

Theming using only images.

Also a bundle as $INXROOT/Themes/myTheme.theme. But Info.plist should contain the `INXSimpleTheme` dictionary key.

(INXRect t -> {t.x = ?, t.y = ?, t.w = ?, t.h = ?}. ? can be like 240 or 50%.)
(INXFont t -> {t.name = ?, t.size = ?}.)
(INXColor t -> "#AABBCC")

(INXLabel t -> {INXRect t.frame; INXFont t.font; INXColor t.color; })
(INXImage t -> {filename t.up; filename t.down; })
(INXStretchableImage t -> {INXImage t; INXPoint t.stretch; INXColor t.color; })

Keys of INXSimpleTheme:
  * bool **minimized.enabled**;
  * INXRect **minimized.frame**;
  * INXRect **minimized.icon.frame**;
  * INXLabel **minimized.title.frame**;
  * string **minimized.transition.style**;
  * real **minimized.transition.duration**;
  * string **minimized.normalization.gesture**;
  * INXRect **content.frame**; // x, y ignored here.
  * INXRect **content.icon.frame**;
  * INXLabel **content.title**;
  * INXLabel **content.subtitle**;
  * INXLabel **content.timestamp**;
  * INXStretchableImage **content.background**;
  * INXImage **content.disclosure.image**;
  * INXRect **content.disclosure.frame**;
  * INXStretchableImage **button.background**;
  * INXFont **button.font**;
  * INXColor **button.color**;
  * INXStretchableImage **selection.background**;
-->