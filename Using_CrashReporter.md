# Overview #
Crash Reporter is an application to ease submission of crash reports for both user and developer. It features
  * Symbolication.
  * Accurately finding which application/extension causes the crash.
  * Developer-controlled diagnosis information (See [CrashReporter\_blame\_script\_spec](CrashReporter_blame_script_spec.md)).

# Usage #
Whenever you suspect a crash, you can launch Crash Reporter:

> ![http://xf5.xanga.com/c6cf75f002d32259583463/w206718515.png](http://xf5.xanga.com/c6cf75f002d32259583463/w206718515.png)

which a screen like this will appear:
> | ![http://xe3.xanga.com/0e3f6ae506c34259583258/w206718337.png](http://xe3.xanga.com/0e3f6ae506c34259583258/w206718337.png) |
|:--------------------------------------------------------------------------------------------------------------------------|
This screen contains all **recently crashed applications**.

Tap on a cell to reveal all crash logs of that application. The crash logs are sorted by date. Tap on one of them to **analyze** the crash log.
> | ![http://x6d.xanga.com/2caf4af700432259583260/w206718339.png](http://x6d.xanga.com/2caf4af700432259583260/w206718339.png) |
|:--------------------------------------------------------------------------------------------------------------------------|
(Additionally, you can **delete** processed crash logs in this view.)

This brings us to the **suspects view**. In here, you can view the **symbolicated crash log**, and the **syslog** in the minute that the crash happened. Crash Reporter would analyze the crash log and identify the possible libraries that causes the crash. They are divided into 3 types:
  * **Primary suspect** is the first library in the stack trace of the crashing thread.
  * **Secondary suspects** are libraries involved in the crashing thread.
  * **Tertiary suspects** are those involved in the application at that time, but were not running in the crashing thread.
> | ![http://xea.xanga.com/a5af77f100432259583264/w206718343.png](http://xea.xanga.com/a5af77f100432259583264/w206718343.png) | ![http://xd9.xanga.com/67cf73f300432259583263/w206718342.png](http://xd9.xanga.com/67cf73f300432259583263/w206718342.png) |
|:--------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------|

Knowing who to blame, you can now generate a report to its developer. By default, the first link will send you to AppStore or Cydia, where you can **paste** to the report/mail to the developer. At the time you tap on the link, the attachments (crash log and syslog) will be uploaded to **pastie.org** so that the developer can retrieve it later.
> | ![http://x35.xanga.com/c57f45f300033259583270/w206718345.png](http://x35.xanga.com/c57f45f300033259583270/w206718345.png) | ![http://x13.xanga.com/baff67e547435259583267/w206718344.png](http://x13.xanga.com/baff67e547435259583267/w206718344.png) |
|:--------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------|