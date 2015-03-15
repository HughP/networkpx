

# Introduction #

> ![http://xa3.xanga.com/6adf263363732240945373/w190716389.png](http://xa3.xanga.com/6adf263363732240945373/w190716389.png)

GriP (Growl for iPhone) is an unobstructive notification extension written for iPhone and iPod Touch.

## GriP vs. Traditional Notification Methods ##

There are currently 2 methods to announce a piece of information to you on the iPhone – either to show an alert box (e.g. the 3.0 Push Notification), or just play a sound (e.g. receiving new emails) or vibration. However, alert box is a very rude way to notify something trivial, as an alert box will steal your focus and disrupt your work flow. On the other hand, playing a sound is too hideous, as there are many places you don't want to turn on sound, and iPod Touches don't have a vibration unit.

GriP tries to strike a balance between being unobstructive while still being able to give out clear information. With GriP, messages are (by default) shown as small floating windows in a corner, which will automatically disappear if you ignore it. In this way, you can still continue your process without missing anything.

However, you should not completely replace every alert box with GriP messages. Because GriP messages _favor_ to be ignored by users, they should not be used for critical decision making (e.g. saving a file while quitting).

# Installing GriP #

You should first Jailbreak your device. GriP cannot function without Jailbreaking. Please refer to http://thebigboss.org/guides/quickpwn-guide/ for how to Jailbreak and http://thebigboss.org/why-jailbreak-iphone/ for myths/concerns of Jailbreaking.

~~You can install the latest stable version of GriP from the BigBoss repository (http://www.thebigboss.org/). Legitimate `dpkg` implementations like Cydia, `apt-get` and `aptitude` are recommended.~~ (**Not released yet**)

The beta versions can be found from this site's download page. You will obtain a `.deb` file, which can be installed on your device with the following steps:

  1. Create an SSH session to your device and login as `root`. You can follow this page for instruction: http://cydia.saurik.com/openssh.html
  1. Upload the `.deb` file to `/var/root/`.
  1. Start a command prompt. In there, type `cd ~ ; dpkg -i «filename.deb»`, where you have to replace `«filename.deb»` with the file name of the uploaded file (without the guillemets).
    * If it prompts Mobile Substrate is not installed, make sure you have installed it. You can install it with the command `apt-get install mobilesubstrate`.
  1. Respring your device. If you don't what is respring, simply type `killall SpringBoard`.

# Using GriP #

GriP messages are shown, by default, as a small rounded box in a corner like this:

> ![http://x1f.xanga.com/6fbf2b3b11632240945666/w190716633.png](http://x1f.xanga.com/6fbf2b3b11632240945666/w190716633.png)

From left to right, the components of a GriP messages are:
  * Close button “×”: Tap on this to immediately ignore the message.
  * Application icon: Figuratively tells you which app created this message, or what is going on.
  * The message.
  * Disclosure button “▼”: Tap on this to display further details.

Some messages allow user feedback by tapping on the icon/message. When you hold on it, the border of the GriP message thickens.

> ![http://x8a.xanga.com/d1af273511632240945665/w190716632.png](http://x8a.xanga.com/d1af273511632240945665/w190716632.png)

If you don't really mean to tap on the message, just drag your finger outside until the border returns to normal. You can also use this technique to extend the lifetime of this GriP message before it disappears.

After you have tapped the disclosure button “▼”, the message box will expand the some further detail will be shown:

> ![http://x57.xanga.com/659f513358435240945667/w190716634.png](http://x57.xanga.com/659f513358435240945667/w190716634.png)

You can scroll the lower box for these further details.

The background color can be different depending on the emergency of the GriP message.

# Configuring GriP #

You can change GriP settings in Settings → GriP (the option is at the bottom).

| **Preview** | Clicking this button will display one GriP message based on your current settings. Another GriP message will also show after you have ignored or tapped on this message. |
|:------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Location** | On which corner should the GriP message appear. |
| **Theme** | Which theme to use. |
| **Game mode** | You can mark some apps as _Games_. When these apps are active, GriP will be suspended except for important messages. When you close the app the suppressed normal messages will all be delivered at once. This mode is introduced to reduce distractions when playing games or watching movies. |

## Per-Priority Settings ##

There are 5 levels of _priority_ a message can have. The theme may choose to alter the output based on the priority.

Most messages have a "normal" priority, so you should target that item in most cases.

| **Enabled** | Whether to show messages with the selected priority. By default, messages with _very low priority_ will are hidden. |
|:------------|:--------------------------------------------------------------------------------------------------------------------|
| **Sticky** | While most GriP message will automatically dismiss, some will choose to “stick” on screen until you explicitly close it, or tap on it. These are known as _sticky_ messages. You can override the application decision in this setting. |
| **Duration** | How long should a GriP message live before it auto-close. The range is between 0 to 10 seconds. |
| **Background color** | The background color of a message. From top to bottom each slider represent the red, green, blue channel, and the opacity (alpha channel). |
| **Suspension behavior** | What to do for the messages when GriP is suspended. There are two cases where GriP can be suspended: either in Game mode or the Screen is turned off. There are 4 options for each setting:<ol><li><b>Drop</b>: Just ignore all messages when suspended.</li><li><b>Keep last only</b>: Only keep the last message, and ignore all previous ones.</li><li><b>Queue</b>: Put the message on a queue and deliver all of them when GriP is resumed.</li><li><b>Deliver immediately</b>: Pretend GriP is not suspended and immediately show the message.</li></ol> |

The background color is only a recommended value for the theme. The theme may choose to ignore it.

## Per-App Settings ##

More fine-grained settings for each application/extension. If a per-app setting conflicts with the global settings, the per-app setting takes priority.

(In Growl, they are also known as _tickets_.)

| **Enabled** | Turn OFF to disable this app from showing any GriP messages. (This overrides the per-message settings). |
|:------------|:--------------------------------------------------------------------------------------------------------|
| **Stealth** | Fake to the app that GriP is not disabled for it although it is the other way round. This setting will only appear when you turn OFF the app. |
| **Sticky** | Like the per-priority one, but for apps. |
| **Messages** | List of messages that this app will display. The link provides even more fine-grained per-message settings. Like the higher level, per-message settings trumps per-app settings, _except_ “enabled”. <br /><br />The per-message settings you can override are: “Enabled”, “Stealth”, “Sticky” and “Priority”. |
| **Remove Settings** | Click on this button to remove the settings of this app from GriP. This is equivalent to restoring to the factory settings for that app. |

# System Usage #

On initialization, GriP uses about 250 KiB of RAM.

GriP uses negligible amount of CPU and no extra RAM when idle. GriP will only cause slow down when there are a dozen of messages on screen.

Apple's UIKit framework themselves may take memory that we cannot control. So far we observed a steady gain of 3 KiB every GriP message appears. We will try to get lower level to reduce memory use.

## Know issues ##

  * Themes cannot be completely unloaded. This is to avoid SpringBoard crashing when some code access resources of a completely unload theme.
  * Screen on/off cannot be detected on firmware 2.0. Anyway, you should upgrade to ≥2.1.


---


# Programming for GriP #

## AppStore (SDK) developers ##

While GriP requires Jailbreaking for maximal function, it can also be made SDK-compatible. Of course, it is up to Apple Inc. to decide whether GriP-supporting source codes are acceptable, but GriP uses only documented API so technically it should be allowed.

There are two levels of GriP support you may use. The 1st level is simply add a GriP client, and on the 2nd level you may embed the display server as well. The GriP client can communicate with the external server and display GriP messages. If you embed the display server into your application also, then your application will manage the GriP messages. This ensures the GriP messages can be shown even if GriP is not installed. (But the official GriP server will take over yours if present).

We recommend you just to include the GriP client, and not the server.

To install,

  1. Download http://code.google.com/p/networkpx/downloads/detail?name=GriP-for-SDK-developers.tar.bz2 from this site.
  1. Extract the bz2 file anywhere. You should see this directory structure:
```
sdk/
  GriP/
    common.h
    Duplex/
      Client.h
    GPApplicationBridge.h
    GPGetSmallAppIcon.h
    GPRawThemeHelper.h
    GPTheme.h
    GPUIViewTheme.h
    GriP.h
    GriPServer.h
    GrowlApplicationBridge.h
    GrowlDefines.h
    NSString-stringByEscapingXMLEntities.h
  GriPView.xib
  GrowlApplicationBridge.m
  libGPDefaultTheme.a
  libGriP.a
  libGriPServer.a
  NSString-stringByEscapingXMLEntities.m
```
  1. **Copy** the content of the `sdk` folder into your project, like this:
> > ![http://xc1.xanga.com/d1df36f536033241257650/w190986365.png](http://xc1.xanga.com/d1df36f536033241257650/w190986365.png)
  1. There 5 files you have to decide to compile or not:

| `libGriP.a` | Static library for the GriP client. |
|:------------|:------------------------------------|
| `libGriPServer.a` | Static library for the GriP display server. |
| `libGPDefaultTheme.a` | Static library for the default theme. |
| `GrowlApplicationBridge.m` | A Growl-compatible API wrapper. |
| `NSString-stringByEscapingXMLEntities.m` | Category for escaping XML entities. |


> We recommend you to **check `libGriP.a` only**, and leave the others excluded.

If you include the GriP server, please modify your `main.m` to read
```
#import <UIKit/UIKit.h>
#import <GriP/GriPServer.h>    /// <--- new

int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    GPStartGriPServer();       /// <--- new
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
```

If you want to define your own theme, uncheck `libGPDefaultTheme.a` and follow the instruction in [#Theming](#Theming.md). The class name you use must be `GPDefaultTheme`.

## Open toolchain developers or Developers for Jailbroken Devices ##

The AppStore method is still applicable to these apps, but since the Apple censorship is nonexistent here, we have one more option.

If GriP is a requirement for your app, you can directly link to `libGriP.dylib`, and use the `GPApplicationBridge` class included in `libGriP`. (If you want to use `GrowlApplicationBridge`, you still have to compile the .m file – it is not included in `libGriP`.) This reduces bloat in your code.

## APIs ##

GriP implements all the _documented_ API of Growl on http://growl.info/documentation/developer/implementing-growl.php?lang=cocoa.

There are a few changes to GriP compared with the Growl API in the `notifyWithTitle:...` method:
  * Besides being the `NSData` of the whole image, `iconData` accepts:
    * `UIImage`
    * display identifier (`NSString`). The icon for that app will be used. In addition, the following strings are also supported:
> > > ` "(WiFi)", "(VPN)", "(wallpaper)", "(airplane)", "(display)", "(sound)" `
    * a single character (`NSString`) in the range of U+E000 to U+E5FF. The character will be drawn directly as an icon. Emoji icons are in this character range.
  * `clickContext` accepts an `NSURL` alongside with property list objects. When an `NSURL` is given, the message will launch the URL when the user tap on it. This works even without a delegate, and across process termination. (The `growlNotificationWasClicked:` and `growlNotificationTimedOut:` methods will still be invoked if a delegate is present.)
  * If `clickContext` is `kCFBooleanFalse` (i.e. `[NSNumber numberWithBool:NO]`), the context will be treated as `nil`.

If you are writing a Mobile Substrate extension, we strongly recommend you **not** to use the `GrowlApplicationBridge` class methods, as this may cause the structures of the same object be shared between extensions undesirably. Instead, you should explicitly create an instance of `GPApplicationBridge` and work on it. If you have already used `GrowlApplicationBridge` and want to turn back, you can create a global variable named `GrowlApplicationBridge` initialized as `[[GPApplicationBridge alloc] init]` and call `[GrowlApplicationBridge release]` at termination.

## Example ##

```
#import <GriP/GriP.h>

...

// Initiate a new application bridge.
GPApplicationBridge* bridge = [[GPApplicationBridge alloc] init];

// register your app.
// (of course, both auto-registration and register with a delegate can be used instead.)
NSArray* supportedMessages = [NSArray arrayWithObject:@"Test Message"];
[bridge registerWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                @"Test App",       GROWL_APP_NAME,
                                supportedMessages, GROWL_NOTIFICATIONS_ALL,
                                supportedMessages, GROWL_NOTIFICATIONS_DEFAULT,
                                nil]];

// You only need to call the above statements once in a lifetime.
// Make sure the "bridge" is globally accessible.

...

// Display a new message with title "Hello world!" and an icon of Safari,
//  which will launch Google when tapped.
// Call this whenever you need to.
[bridge notifyWithTitle:@"Hello world!"
            description:@"Fill in some detail here."
       notificationName:@"Test Message"
               iconData:@"com.apple.mobilesafari"
               priority:0
               isSticky:NO
           clickContext:[NSURL URLWithString:@"http://www.google.com/"]];

...

// Always kill the bridge when the app terminates.
[bridge release];
```

## Guidelines ##

Growl recommends you to use concise text, and in GriP it is the strongest utmost important guideline. Because the iPhone screen is extremely small, even a sentence of title would be _too long_.

In GriP, the rule of thumb is to limit your title to **three words** (or 15 CJK characters). So instead of


> `Downloaded http://www.example.com/softwares/iphone/2/themes/the_best_theme_v1.0.deb to /var/mobile/dpkg_collections/themes/the_best_theme_v1.0.deb of size 1,893,229 bytes in 16.492 seconds at an average speed of 112.106 kibibytes per seconds`

or even

> `Downloaded the_best_theme_v1.0.deb (1.81 MiB) in 16 seconds`

please just say

> `Download completed.`

All the details can be thrown into the description. And because the description is normally hidden, you can give as much detail as you want there. Of course, you should _still_ make the description concise, no one wants to read a novel in a 160x60 box.

Another thing is that, **do not use GriP for important messages that require user feedback**, because GriP messages can be easily ignored. A `UIAlertView` or `UIActionSheet` is more suitable in this case.

You **should not rely on the `growlNotificationTimedOut:` delegate method** to do any responds. Currently, when GriP is suspended, the `growlNotificationTimedOut:` method may not be called.

## Known issues of the embedded server ##

To play nice with the SDK restriction, there are a few features not found on the embedded server:
  * You cannot use other applications' icons with a bundle identifier. This is because your application is sandboxed.

You may tweak `GPPreferences.plist` to suit your need.

## Extensions of SpringBoard using GriP ##

The GriP server is actually a Mobile Substrate extension of SpringBoard, therefore, if you are writing another Mobile Substrate extension that uses GriP, it must load after it. GriP has made this easy by putting itself very early in the queue (by naming itself `%GriP.dylib`).

However, if you want to be sure your extension loads after GriP is _fully_ loaded, you should write a 2-tier initilizer like this:

```
#include <GriP/GPExtensions.h>

static void real_initializer () {
  // do your actual initialization here
}
void proxy_initializer () {
  GPStartWhenGriPIsReady(&real_initializer);
}
```

and set `_proxy_initializer` as the initializer of the dylib. The `GPStartWhenGriPIsReady` function ensures its parameter will be call only after GriP is ready.

You should **not** do this if your extension is not targeting SpringBoard. If the extension also hooks on multiple applications, always check if the host is SpringBoard before calling the function.

# Theming #

Currently GriP only supports ObjC themes, i.e. you must write code to create a theme. In the future WebKit themes may be supported.

There are 2 kinds of ObjC themes you may use, (1) UIView themes and (2) raw themes.

## UIView themes ##

UIView themes are theme engines that presents a GriP message by in a UIView. The default GriP theme is a UIView theme. Here we give a step-by-step example to create a simple UIView theme.

All UIView themes should be a subclass of `GPUIViewTheme`, and each subclass can override these 4 methods:
```
@required
-(void)modifyView:(UIView*)inoutView asNew:(BOOL)asNew withMessage:(NSDictionary*)message;
@optional
+(void)updateViewForDisclosure:(UIView*)view_;
+(void)activateView:(UIView*)view;
+(void)deactivateView:(UIView*)view;
```
| `-modifyView:asNew:withMessage:` | updates the view `inoutView` to reflect the content in `message`. `inoutView` can be a completely empty view (when `asNew` is `YES`), or already contains some changes. |
|:---------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `+updateViewForDisclosure:` | updates the view when the user requires more detail (if you programmed for this possibility). In the default theme, this method is called when the “▼” button is hit, and elongates the message and allows the previously hidden detail view to be shown. |
| `+activateView:` & `+deactivateView:` | as described. In the default theme, these are called when the message is held, and they thicken/restore the message border. |

The core method that you should override is `-modifyView:asNew:withMessage:`. So let's start with
```
@interface ExampleTheme : GPUIViewTheme {}
-(void)modifyView:(UIView*)inoutView asNew:(BOOL)asNew withMessage:(NSDictionary*)message;
@end
@implementation ExampleTheme
-(void)modifyView:(UIView*)inoutView asNew:(BOOL)asNew withMessage:(NSDictionary*)message {
  [super modifyView:inoutView asNew:asNew withMessage:message];
```
Make sure you call the superclass's method for forward compatibility. Now let's create a simple view like this, not messing with the description stuff:

> | `[ICON]` Title          X |
|:--------------------------------------------|

The first step is extract all the necessary information. The `message` dictionary contains everything you need. The keys are specified in `<GriP/common.h>`. We only need the title, icon image and priority here, so:
```
  NSString* title = [message objectForKey:GRIP_TITLE]; 
  NSObject* iconData = [message objectForKey:GRIP_ICON];
  int priority = [[message objectForKey:GRIP_PRIORITY] integerValue];
```
wait, to draw an icon we should have a UIImage! For this, you can import `<GriP/GPGetSmallAppIcon.h>` and use the `GPGetSmallAppIconFromObject()` function. Also, how to determine the background color? One benefit of subclassing `GPUIViewTheme` is that the superclass has already got it for you. The protected instance variables `bgColors` and `fgColors` are two arrays telling you the background colors and corresponding best foreground color in each priority level:
```
  UIImage* icon = GPGetSmallAppIconFromObject(iconData);
  UIColor* bgColor = self->bgColors[priority+2];     /// note the +2
  UIColor* textColor = self->fgColors[priority+2];   /// note the +2
```
now we are ready to construct the view. Before we continue we may want to reuse what's left by the previous user:
```
  UIButton* clickContext = nil;
  UIImageView* iconView = nil;
  UILabel* titleLabel = nil;
  UIButton* closeButton = nil;
  if (!asNew) {
    NSArray* subviews = inoutView.subviews;
    clickContext = [subviews objectAtIndex:0];
    iconView = [subviews objectAtIndex:1];
    titleLabel = [subviews objectAtIndex:2];
    closeButton = [subviews objectAtIndex:3];
  } else {
```
what is this `clickContext` you ask? It is basically a UIButton that cover the whole view, and will intercept the “activate”, “deactivate” and “fire” events. You have to connect these buttons to the target `[ExampleTheme class]` and the corresponding actions, but for default behaviors there are 3 macros defined for you to abstract these out.
```
    inoutView.frame = CGRectMake(0,0,160,36);    // let the size be 160x36.

    clickContext = [[UIButton alloc] initWithFrame:CGRectMake(0,0,160,36)];
    GPAssignUIControlAsClickContext(clickContext);
    [inoutView addSubview:clickContext];
    [clickContext release];

    iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0,3,29,29)];
    [inoutView addSubview:iconView];
    [iconView release];

    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(34,0,90,36)];
    titleLabel.backgroundColor = [UIColor clearColor];
    [inoutView addSubview:titleLabel];
    [titleLabel release];

    closeButton = [[UIButton alloc] initWithFrame:CGRectMake(124,0,36,36)];
    [closeButton setTitle:@"X" forState:UIControlStateNormal];
    GPAssignUIControlAsCloseButton(closeButton);
    [inoutView addSubview:closeButton];
    [closeButton release];
  }
```
We note that we have mandated the view's frame to be {(0,0), 160x36}. If you don't do so, the default frame will be {(0,0), 160x60}.

After the view is constructed, we can configure it:
```
  iconView.image = icon;
  titleLabel.text = title;
  titleLabel.textColor = textColor;
  [closeButton setTitleColor:textColor forState:UIControlStateNormal];
  inoutView.backgroundColor = bgColor;
}
@end
```
So the coding is done. To deploy the theme, you will need to link to `libGriP.dylib` and compile into a Mach-O bundle:
> ` gcc «other-options» -lGriP -bundle -o ExampleTheme ExampleTheme.m `
and then put it into a GriP Theme bundle, which is just a folder. Such folder must have this directory structure:
```
ExampleTheme.griptheme/
  Info.plist
  ExampleTheme
  «other-stuff»
```
where `ExampleTheme` is the file you've just compiled, and `Info.plist` is a property list with these content:
```
{
   CFBundleDisplayName = "Example Theme";    // readable name of the theme.
   NSPrincipalClass    = ExampleTheme;       // class name of the theme engine.
   GPThemeType         = OBJC;               // this is an ObjC theme
}
```
when these are all already, you can copy these files to `/Library/GriP/Themes/` on your device. Then when you launch Settings, you should be able to see your theme and test it. The result should be similar to this:

> ![http://x18.xanga.com/5e8f207b35533241453258/w191155956.png](http://x18.xanga.com/5e8f207b35533241453258/w191155956.png)

Not bad. It is easy to make it look nicer and more efficient. You may read the source code of the default theme at http://code.google.com/p/networkpx/source/browse/trunk/hk.kennytm.grip/src/GPDefaultTheme.m to get a better understanding.

## Raw themes ##

Raw themes are themes without help of `GPUIViewTheme`. It is the lowest possible form a theme can be. At this level, you can do pretty much anything you like, e.g. change the status bar or make the phone vibrate or even send your GriP message to twitter. It is comparable with the Growl display plugins.

Let's try to construct a raw theme that displays GriP messages are UIAlertViews. A raw theme can be anything that adopts the GPTheme protocol:
```
@protocol GPTheme
-(id)initWithBundle:(NSBundle*)bundle;
-(void)display:(NSDictionary*)message;
@optional
-(void)messageClosed:(NSString*)identifier;
@end
```
| `-initWithBundle:` | initialize the theme engine, with `bundle` being the GriP theme bundle. |
|:-------------------|:------------------------------------------------------------------------|
| `-display:` | _displays_ a message. It is the heart of the whole engine. |
| `-messageClosed:` | if your theme supports coalescing, this tells you the message with identifier `identifier` has been closed. This is not called by the GriP server. |

A raw theme has to manage its communication with the GriP server when the user has confirmed or ignored a message. To ease these thing a bit, you may use a GPRawThemeHelper.

So our theme can start with
```
#import <UIKit/UIKit.h>
#import <GriP/GPTheme.h>
#import <GriP/GPRawThemeHelper.h>
@interface UIAlertViewTheme : NSObject<GPTheme,UIAlertViewDelegate> {
  GPRawThemeHelper* helper;
}
-(id)initWithBundle:(NSBundle*)bundle;
-(void)display:(NSDictionary*)message;
-(void)alertView:(UIAlertView*)alert clickedButtonAtIndex:(NSInteger)index;
@end
```
Since we don't have other resources the `bundle` is not very useful. So just treat it as a simple `-init` method:
```
@implementation UIAlertViewTheme
-(id)initWithBundle:(NSBundle*)bundle {
  if ((self = [super init]))
    helper = [[GPRawThemeHelper alloc] init];
  return self;
}
-(void)dealloc {
  [helper release];
  [super dealloc];
}
```
Now for `-display:`, the `message` is a dictionary with the same structure we've discussed for a UIView theme. Hence,
```
-(void)display:(NSDictionary*)message {
  int helperUID = [helper registerMessage:message];
  NSString* title = [message objectForKey:GRIP_TITLE];
  NSString* detail = [message objectForKey:GRIP_DETAIL];
  UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                      message:detail
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"OK", nil];
  alertView.tag = helperUID;
  [alertView show];
  [alertView release];
}
```
Here, the `-[GPRawThemeHelper registerMessage:]` extracts the necessary data from the message and stores it for later use. It returns a unique ID which we will need it later (so we store it as a tag of the UIAlertView).  Then we proceed to display the alert view. We want to know if the user confirmed or canceled the alert view too, so we set `self` as a delegate.
```
-(void)alertView:(UIAlertView*)alert clickedButtonAtIndex:(NSInteger)index {
  if (index != 0)
    [helper touchedMessageID:alert.tag];
  else
    [helper ignoredMessageID:alert.tag];
}
@end
```
When the user actually clicked a button, we check if that's Cancel or OK, and send the appropriate data to the GriP server. The complexity is encapsulated in the `-touchedMessage:` and `-ignoredMessage:` calls. You just need to call them with the UID you received earlier, which is stored in the alert's tag before.

The deployment procedure is same as UIView theme.

## Theming (Modal tables) ##

Theming modal tables is much easier than GriP themes because you need to deal with much less options. The theme resources should be placed inside a folder in `/Library/GriP/Themes/`, with this structure:
```
ExampleTheme.gpmtvtheme/
  Theme.plist
  Background.png  (optional)
  Selection.png   (optional)
```

Background.png is the background image of the whole modal table window. Selection.png is the image which should be used when the user selects a table cell.

GriP identifies the following keys in Theme.plist:

> _struct_ `<GriP Modal Table Theme>` ::
<table cellpadding='5' border='1'>
<tr>
</li></ul>> <th>key</th>
> <th>type</th>
> <th>meaning</th>
> <th>default</th>
> <th>depends</th>
</tr>
<tr>
> <td>BackgroundLeftCapWidth</td>
> <td>integer</td>
> <td>Left cap width of the background image.</td>
> <td>0</td>
> <td>--</td>
</tr>
<tr>
> <td>BackgroundTopCapHeight</td>
> <td>integer</td>
> <td>Top cap height of the background image.</td>
> <td>0</td>
> <td>--</td>
</tr>
<tr>
> <td>Paddings</td>
> <td>dictionary</td><td><code>&lt;Paddings&gt;</code></td>
> <td>Spacing around the table.</td>
> <td>{top=0; left=0; bottom=0; right=0;}</td>
> <td>--</td>
</tr>
<tr>
> <td>ToolbarsTotallyTransparent</td>
> <td>boolean</td>
> <td>Set whether the navigation bar and toolbar will be totally transparent.</td>
> <td>✗</td>
> <td>--</td>
</tr>
<tr>
> <td>ToolbarsBarStyle</td>
> <td>integer</td>
> <td>If the toolbars are not totally transparent, which color should they be. 0 = Blue, 1 = Black.</td>
> <td>0</td>
> <td>--</td>
</tr>
<tr>
> <td>ToolbarsTintColor</td>
> <td>array</td><td><code>&lt;Color&gt;</code></td>
> <td>Tint color of the toolbars.</td>
> <td>nil</td>
> <td>--</td>
</tr>
<tr>
> <td>TableSeparatorColor</td>
> <td>array</td><td><code>&lt;Color&gt;</code></td>
> <td>Table separator color. Default is gray.</td>
> <td>nil</td>
> <td>--</td>
</tr>
<tr>
> <td>TableBackgroundColor</td>
> <td>array</td><td><code>&lt;Color&gt;</code></td>
> <td>Table background color. Default is white.</td>
> <td>nil</td>
> <td>--</td>
</tr>
<tr>
> <td>TableTextColor</td>
> <td>array</td><td><code>&lt;Color&gt;</code></td>
> <td>Table text color. Default is black.</td>
> <td>nil</td>
> <td>--</td>
</tr>
<tr>
> <td>TableDescriptionColor</td>
> <td>array</td><td><code>&lt;Color&gt;</code></td>
> <td>Table description color. Default is dark gray.</td>
> <td>nil</td>
> <td>--</td>
</tr>
<tr>
> <td>SelectionStyle</td>
> <td>integer</td>
> <td>Color of selected cell. 1 = Blue, 2 = Gray</td>
> <td>1</td>
> <td>--</td>
</tr>
<tr>
> <td>SelectionLeftCapWidth</td>
> <td>integer</td>
> <td>Left cap width of selected background image, if any.</td>
> <td>0</td>
> <td>--</td>
</tr>
<tr>
> <td>SelectionTopCapHeight</td>
> <td>integer</td>
> <td>Top cap height of selected background image, if any.</td>
> <td>0</td>
> <td>--</td>
</tr>
</table></li></ul>

<blockquote><i>struct</i> <code>&lt;Paddings&gt;</code> ::<br>
<table cellpadding='5' border='1'>
<tr>
</blockquote><blockquote><th>key</th>
<th>type</th>
<th>meaning</th>
<th>default</th>
<th>depends</th>
</tr>
<tr>
<td>top</td>
<td>integer</td>
<td>Top spacing.</td>
<td>0</td>
<td>--</td>
</tr>
<tr>
<td>left</td>
<td>integer</td>
<td>Left spacing.</td>
<td>0</td>
<td>--</td>
</tr>
<tr>
<td>bottom</td>
<td>integer</td>
<td>Bottom spacing.</td>
<td>0</td>
<td>--</td>
</tr>
<tr>
<td>right</td>
<td>integer</td>
<td>Right spacing.</td>
<td>0</td>
<td>--</td>
</tr>
</table></blockquote>

<blockquote><i>union</i> <code>&lt;Color&gt;</code> ::</blockquote>

<table cellpadding='5' border='1'>
<tr>
<blockquote><th>type</th>
<th>meaning</th>
</tr>
<tr>
<td>array</td><td>...of reals and count = 1</td>
<td>Solid gray scale color (e.g. (1) = white).</td>
</tr>
<tr>
<td>array</td><td>...of reals and count = 2</td>
<td>Gray scale color with alpha channel (e.g. (1, 0.5) = translucent white).</td>
</tr>
<tr>
<td>array</td><td>...of reals and count = 3</td>
<td>Solid RGB color (e.g. (1, 0.5, 0) = orange).</td>
</tr>
<tr>
<td>array</td><td>...of reals and count = 4</td>
<td>RGB color with alpha channel (e.g. (0, 1, 0, 0.5) = translucent green).</td>
</tr>
</table>