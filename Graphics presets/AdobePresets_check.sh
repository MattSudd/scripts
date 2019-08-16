#!/bin/bash

#Preflight install check to see if folders and script exist


PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/munki export PATH

# this will run as a munki install_check script
# exit status of 0 means install needs to run
# exit status not 0 means no installation necessary

plistfile='/Library/LaunchDaemons/com.blackmilk.graphics.presets.plist'
scriptfile=/Library/Scripts/Presets/Sync.sh
deamon='com.blackmilk.graphics.presets'
launchd_running=`launchctl list | grep 'com.blackmilk.graphics.presets'`
user=`stat -f "%Su" /dev/console`
userpresets='/Users/'"$user"'/Documents/Adobe_Settings'

# check existance of launchd plist (if it doesn't exist exit with )
if [ ! -f "$plistfile" ]; then
	echo "Launchd file not found"
	exit 0
fi
#check that sync file exists
if [ ! -f "$scriptfile"]; then
	echo "scriptfile not found"
	exit 0
fi

#check that launchd is loaded
if [ -z "$launchd_running" ]; then
    echo "Launchd not loaded"
    exit 0
fi

#check userfolders exist

if [ ! -d "$userpresets"]; then
	echo "user presets dir does not exist"
	exit 0
fi


echo "All looks good"

exit 1