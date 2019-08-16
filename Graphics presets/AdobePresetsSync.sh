#!/bin/bash

#This script does the install of the sync job from active users ~/Documents/Adobe_settings/<product> 
#to corect adobe presets directory
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/munki export PATH

#get active user
user=`stat -f "%Su" /dev/console`
userpresets='/Users/'"$user"'/Documents/Adobe_Settings'
scriptdir=/Library/Scripts/Presets
installs="$scriptdir"/installs.txt
sync_script="$scriptdir"/sync.sh
daemon_loc=/Library/LaunchDaemons
launchd_plist="$daemon_loc"/com.blackmilk.graphics.presets.plist
launchd_running=`launchctl list | grep 'com.blackmilk.graphics.presets'`

echo $user
#create script dir if it doesn't exist
if [ ! -d "$scriptdir" ]; then
	mkdir "$scriptdir"
fi

#create users presets directory if it doesn't exist
if [ ! -d "$userpresets" ]; then
	mkdir "$userpresets"
fi


#create new script file

echo "#!/bin/bash" > $sync_script
echo "#script to sync presets dir from users Documents to Adobe products Presets/Scripts directories" >> $sync_script


#get list of adobe tools installed
ls /Applications/ | grep 'Adobe' > $installs


#Take installs file line by line and check if Presets and scripting folders exist.
#for the folders that do appened rsync commnd to script that wsill be run by launchd

while IFS="" read -r p || [ -n "$p" ]
do
	echo $p
	prod_dir=/Applications/$p
	echo $prod_dir
	
	if [ -d "$prod_dir"/Presets ]; then
		nicename=$(echo $p |awk -F' ' '{print$2}')
		echo "nicename is" $nicename
		if [ ! -d "$userpresets"/"$nicename" ]; then 
			mkdir "$userpresets"/"$nicename"
			echo "Created" $nicename "directory"
		else
			echo "Directory exists, skipping"
		fi
		presets_dir=`ls "$prod_dir" | grep 'Presets'`
		presets_path=$prod_dir/$presets_dir/Blackmilk 
		syncdir=$userpresets/$nicename/Presets
		echo "syncdir is" $syncdir
		echo "presets path is" $presets_path
		if [ ! -d "$syncdir" ]; then 
			mkdir "$syncdir"
			echo "Created" $syncdir
		else
			echo "Directory exists, skipping"
		fi
		if [ ! -d "$presets_path" ]; then 
			mkdir "$presets_path"
			echo "Created" $presets_path
		else
			echo "Directory exists, skipping"
		fi
		# send rsync command to sync script
		echo "rsync -a ""'$syncdir'""/ ""'$presets_path'" >> $sync_script
	elif [ -d "$prod_dir"/Presets.localized ]; then
		nicename=$(echo $p |awk -F' ' '{print$2}')
		echo "nicename is" $nicename
		if [ ! -d "$userpresets"/"$nicename" ]; then 
			mkdir "$userpresets"/"$nicename"
			echo "Created" $nicename "directory"
		fi
		presets_dir=`ls "$prod_dir" | grep 'Presets.localized'`
		lang_dir=`ls "$prod_dir"/"$presets_dir" | grep 'en_'`
		presets_path=$prod_dir/$presets_dir/$lang_dir/Blackmilk 
		syncdir=$userpresets/$nicename/Presets
		echo "syncdir is" $syncdir
		echo "presets path is" $presets_path
		if [ ! -d "$syncdir" ]; then 
			mkdir "$syncdir"
			echo "Created" $syncdir
		else
			echo "Directory exists, skipping"
		fi
		if [ ! -d "$presets_path" ]; then 
			mkdir "$presets_path"
			echo "Created" $presets_path
		else
			echo "Directory exists, skipping"
		fi 
		# send rsync command to sync script
		echo "rsync -a ""'$syncdir'""/  ""'$presets_path'" >> $sync_script
	fi
	
	if [ -d "$prod_dir"/Scripting ] || [ -d "$prod_dir"/Scripting.localized ]; then
		nicename=$(echo $p |awk -F' ' '{print$2}')
		echo "nicename is" $nicename
		if [ ! -d "$userpresets"/"$nicename" ]; then 
			mkdir "$userpresets"/"$nicename"
			echo "Created" $nicename "directory"
		else
			echo "Directory exists, skipping"
		fi
		script_dir=`ls "$prod_dir" | grep 'Scripting'`
		script_path=$prod_dir/$script_dir/Blackmilk 
		syncdir=$userpresets/$nicename/Scripting
		echo "syncdir is" $syncdir
		echo "script path is" $script_path
		if [ ! -d "$syncdir" ]; then 
			mkdir "$syncdir"
			echo "Created" $syncdir
		else
			echo "Directory exists, skipping"
		fi
		if [ ! -d "$script_path" ]; then 
			mkdir "$script_path"
			echo "Created" $script_path
		else
			echo "Directory exists, skipping"
		fi 
		# send rsync command to sync script
		echo "rsync -a ""'$syncdir'""/ ""'$script_path'" >> $sync_script
	fi
done < $installs


#make sure the right user owns the direcrtory
chown -R "$user":staff "$userpresets"
#make script executable
chmod +x "$sync_script"

#build the plist to kick off the sync (as plutil cannot create a plist from scratch)
echo "<?xml version="1.0" encoding="UTF-8"?>" > $launchd_plist
echo "<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">" >> $launchd_plist
echo "<plist version="1.0">" >> $launchd_plist
echo "<dict/>" >> $launchd_plist
echo "</plist>" >> $launchd_plist

#Insert values in to plist file
plutil -insert Label -string com.blackmilk.graphics.presets "$launchd_plist"
plutil -insert ProgramArguments -xml '<array/>' "$launchd_plist"
plutil -insert ProgramArguments.0 -string "$sync_script" "$launchd_plist"
plutil -insert StartInterval -integer 30 "$launchd_plist"

#if correct launchd is running unload plist  and reload in to Launchd
if [ -z "$launchd_running" ]; then
    echo "not running, loading launchd"
    launchctl load -w "$launchd_plist"
else
    echo "running, unloading before loading launchd"
    launchctl unload "$launchd_plist"
    launchctl load -w "$launchd_plist"
fi

sleep 3
#confirm running
pl_loaded=`launchctl list com.blackmilk.graphics.presets`
echo $pl_loaded



