# Requirement #

The networkpx projects are developed on an 64-bit Intel Mac OS X 10.6.2 with the official iPhone SDK 3.0 or above. Other platforms may be unsupported. You also need to have my [iPhone private frameworks](http://github.com/kennytm/iphone-private-frameworks) for the unofficial headers.

  * Install the official iPhone SDK 3.1.2 from [[apple](http://developer.apple.com/iphone/)]. You will need a (free) ADC account.
  * Download _ldid_ from [[networkpx](http://code.google.com/p/networkpx/downloads/detail?name=ldid.zip)], or compile it from source in [[telesphoreo](http://svn.telesphoreo.org/trunk/data/ldid/)]. Put the binary into `/usr/local/bin/`.
  * Install svn, e.g. from [[martinott](http://homepage.mac.com/martinott/)].
  * Install git and clone `git://github.com/kennytm/iphone-private-frameworks.git`.

# Compiling #

  1. Check out the latest source code by
```
svn checkout http://networkpx.googlecode.com/ <directory-save-as>  
```
  1. Go to the directory you have just checked out, and move into the `svn/trunk/` subdirectory.
  1. Run: `./makedeb.sh`. This will compile all codes and construct the packages.
  1. Move back to `../../`. You should see the Debian packages now.

In summary,
```
#!/bin/bash

mkdir ~/networkpx/
cd ~/networkpx/
svn co http://networkpx.googlecode.com/ .
cd svn/trunk/
./makedeb.sh
cd ../../
ls *.deb
```

# Installing on Device #

Like all Debian packages, you just need to ssh into your device and `dpkg -i` on the package you've just compiled.