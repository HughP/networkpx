#!/bin/bash

for PackageName in `ls -d hk.*/`; do
	echo -n "$PackageName	"
	du -c -k -I.* -IDEBIAN $PackageName/deb/ | tail -1 | cut -f 1
done
