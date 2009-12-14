#!/bin/sh
#	
#	make.sh ... Make Toggle.c & Hook.m
#	Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>
#	
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#	
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#	
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

GCC='/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc-4.2 -arch armv6 -std=c99 -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.1.sdk -I/Developer/Platforms/iPhoneOS.platform/Developer/usr/include/gcc/darwin/default -I/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.1.sdk/usr/lib/gcc/arm-apple-darwin9/4.2.1/include -L/usr/local/lib -F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.1.sdk/System/Library/PrivateFrameworks/ -I/Users/kennytm/XCodeProjects/iphone-private-frameworks -I/Developer/Platforms/iPhoneOS.platform/Developer/usr/include -Wall -mcpu=arm1176jzf-s -O2'
ToggleTarget=../deb/var/mobile/Library/SBSettings/Toggles/ScrollToTop/Toggle.dylib
HookTarget=../deb/Library/MobileSubstrate/DynamicLibraries/DontScrollToTop.dylib

$GCC -dynamiclib -o $ToggleTarget Toggle.c
ldid -S $ToggleTarget
$GCC -framework UIKit -framework Foundation -framework CoreFoundation -lsubstrate -dynamiclib -o $HookTarget Hook.m
ldid -S $HookTarget
