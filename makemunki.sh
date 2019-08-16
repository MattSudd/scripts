#!/bin/bash

# todo: 
# ask for git location and where files should be put.
# this script expects the munki repo to be in ~/Documents/git/munki if your repo is elsewere please update the command accordingly


user=`stat -f "%Su" /dev/console`
outputdir=/Users/$user/Desktop/test/munki
outputdir_boot=$outputdir/bootstrap
outputdir_update=$outputdir/update
echo $user
echo $outputdir

# if output dir doesn't exist, create it
if [ ! -d "$outputdir" ]; then
	echo "output directory missing - creating"
	mkdir "$outputdir"
	mkdir "$outputdir_boot"
	mkdir "$outputdir_update"
fi

cd ~/Documents/git/munki
git pull 
#git clone https://github.com/munki/munki.git
cd ~/Documents/git/munki

#making bootstrap
echo "Making Munki with Bootstrap switch. Saving bootstrap to ~/Desktop/munki/bootstrap"
/Users/$user/Documents/git/munki/code/tools/make_munki_mpkg_DEP.sh -i "com.googlecode.munki" -o $outputdir_boot -s "Developer ID Installer: Black Milk Clothing Pty Ltd (USKFFV8BKR)" -b

echo "Making Munki update. Saving update to ~/Desktop/munki/update"
/Users/$user/Documents/git/munki/code/tools/make_munki_mpkg_DEP.sh -i "com.googlecode.munki" -o $outputdir_update -s "Developer ID Installer: Black Milk Clothing Pty Ltd (USKFFV8BKR)"

