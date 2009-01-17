#!/bin/bash

export COPYFILE_DISABLE=true
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true

# Ref: http://kb.adobe.com/selfservice/viewContent.do?externalId=tn_16831
find . -name "*DS_Store" -depth -exec rm {} +

for PackageName in `ls -d hk.*/`; do
	if [[ -e "${PackageName%%/}/src/Makefile" ]]; then
		cd "${PackageName%%/}/src/"
		make
		cd -
	fi
	dpkg-deb -b ${PackageName%%/}/deb ../../${PackageName%%/}.deb;
done

dpkg-scanpackages -m ../../ /dev/null > ../../Packages;

bzip2 ../../Packages;

# for PackageName in `ls -d hk.*/`; do
#	if [[ -e "${PackageName%%/}/src/Makefile" ]]; then
#		cd "${PackageName%%/}/src/"
#		make clean
#		cd -
#	fi
# done
