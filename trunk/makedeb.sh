#!/bin/bash

rm -f ../../*.deb;

for PackageName in `ls -d hk.*/`; do
	if [[ -e "${PackageName%%/}/src/Makefile" ]]; then
		cd "${PackageName%%/}/src/";
		if [[ $1 == "--clean" ]]; then
			make clean;
		fi;
#		make;
		cd $OLDPWD;
	fi
	./dpkg-deb-nodot ${PackageName%%/}/deb ../../${PackageName%%/};
done

cd ../../;
	dpkg-scanpackages -m . /dev/null > Packages;

	rm Packages.bz2;
	bzip2 -k Packages;
cd $OLDPWD;
