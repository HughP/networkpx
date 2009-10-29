#!/bin/bash
#
# apivers.sh ... Check existence of symbols in all iPhoneOS SDK versions.
# Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

SDKSROOT=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs
FRAMEWORK=
BINARY=
SYMBOL=
STRINGS=

while getopts "y:F:x:n:s:" flag; do
	case "$flag" in
		"y") SDKSROOT=$OPTARG;;
		"F") FRAMEWORK=$OPTARG;;
		"x") BINARY=$OPTARG;;
		"n") SYMBOL=$OPTARG;;
		"s") STRINGS=$OPTARG;;
	esac;
done;

if [[ ( -z $SYMBOL && -z $STRINGS ) || ( -z $FRAMEWORK && -z $BINARY ) ]]; then
	echo "Usage: apivers.sh [-y <SDKs-root>] [-F <framework> | -x <binary>] [-n <symbol> | -s <string>]";
else
	for ROOT in $SDKSROOT/*; do
		if [[ -z $BINARY || ! -f $ROOT/$BINARY ]]; then
			if [[ -n $FRAMEWORK ]]; then
				BINARY=/System/Library/Frameworks/$FRAMEWORK.framework/$FRAMEWORK;
				if [[ ! -f $ROOT/$BINARY ]]; then
					BINARY=/System/Library/PrivateFrameworks/$FRAMEWORK.framework/$FRAMEWORK;
				fi;
			fi;
		fi;
		echo "$ROOT:"
		if [[ -f $ROOT/$BINARY ]]; then
			if [[ -n $SYMBOL ]]; then
				nm -arch armv6 $ROOT/$BINARY | grep --color=auto $SYMBOL;
			else
				strings -arch armv6 -n ${#STRINGS} $ROOT/$BINARY | grep --color=auto $STRINGS;
			fi;
		else
			echo "Error: $BINARY does not exist.";
		fi;
	done;
fi;
