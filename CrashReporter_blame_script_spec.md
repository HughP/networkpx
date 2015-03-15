

# Overview #

CrashReporter is an application for users to report crash to developers. By default, it will bring users to the Cydia package or AppStore description which the user can paste the generated report, which includes the symbolicated crashlog and syslog.

Packages which have dedicated bug tracking mechanism, or have additional info to aid debugging can instruct CrashReport to include those by "Blame Scripts".

# Format #
Blame Scripts are line separated text files. Each line is an instruction for CrashReporter. Example:
```
include as "iKeyEx Configuration" plist /var/mobile/Library/Preferences/hk.kennytm.iKeyEx3.plist
link as "Report issue" url http://code.google.com/p/networkpx/issues/entry
```

Each Cydia package or AppStore application can provide exactly 1 Blame Script. They should be placed in:
  * `/DEBIAN/crash_reporter` (for Cydia packages)
  * _yourApp.app_`/crash_reporter` (for AppStore apps)

# Instructions #
## include ##
  * `include [as `_"Title"_`] file `_"filename"_
  * `include [as `_"Title"_`] plist `_"filename"_
  * `include [as `_"Title"_`] command `_shell-command arg1 arg2..._
These will add an extra file to attach in the crash report. `file` is for ordinary text file, `plist` for property lists and `command` for the output of a shell command.

## link ##
  * `link [as `_"Title"_`] url `_url_
  * `link [as `_"Title"_`] email `_email_
These will create a hyperlink that the user can follow and paste the crash report.

## deny ##
  * `deny `_"Title"_
Remove a file included or a link with title _"Title"_. By default, these links will exist:
  * Find package in Cydia
  * Report to AppStore
and these inclusion will exist:
  * Crash log
  * syslog