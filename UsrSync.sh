#!/bin/bash

#Sync userdate to file server and bring it back as required
# VERSION 1.0

#take user input
# -b to backup
# -r to restore

#first some Variables
fs_host=graphics.bmhq.co
fs_share=Backups
fs_user='UsrBackup'
fs_pwd='Banyo4014'
#mnt_point='/Volumes/Backups'
user=`stat -f "%Su" /dev/console`
mnt_point='/Users/'$user'/RebuildBackups'
run_date=`date +%F_%H%M`
backup_dir="$mnt_point"/"$user"
backup_sub_dir="$mnt_point"/"$user"/"$run_date"
backup=0 #run backup process  1 = yes
restore=0 # run restore process 1 = yes
oversize=5 # directories over this many GB will ask for confirmation of Sync
rsync_file="/Users"$user"/rsync.txt"


# a bit of help and guidance to first users
echo "

BLACKMILK LOCAL USER DATA BACKUP & RESTORE SCRIPT

_Backing Up_
Files will be backed up to " $fs_host "  

Make sure all programs and documents are saved and closed before backing up.

----------------------------IMPORTANT--------------------------------------
This script backs up files and folders stored in the following directories:
/Users/<currentUser> |
                     |-- Desktop
                     |-- Documents
                     |-- Downloads
 
Files Stored in ANY other location will not be backed up and *will* be lost when the computer is rebuilt.
-------------------------------------------------------------------------

Folders over 5G total will produce an error.  Please try to reduce the size of these directoires before continuing.

_Restoring_

You will be asked which restore to use.  The backup directoy is structed as
Backups
        |-- User1
        |      |-- User1<backupDateTime>
        |      |-- User1<backupDateTime>
        |      |-- User1<backupDateTime>
        |-- User2
        |      |-- User2<backupDateTime>
        |      |-- User2<backupDateTime>

Choose the most recent Date and Time to restore

Any restores will be placed in:
/Users/<currentUser> 
                     |-- Desktop
                     |      |-- Old_Desktop
                     |-- Documents
                     |      |-- Old_Documents 
                     |-- Downloads
                     |      |-- Old_Downloads

"
read -p "Do you with to continue Y/N:  " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Continuing"
	else
		echo "Exiting to allow cleanup before backup"
		exit 1
	fi

	# if the switch doesn't start with a - error
if [[ ! $@ =~ ^\-.+ ]]; then
    echo "Input error, please  use:
    -b to back up folders for current user
    -r to restore data for a user"
    exit 1
else
   #parse options with getopts code
    while getopts ":br" opt; do
      case ${opt} in
        b) backup=1
    		echo "Backing up"$user" directory "
    		;; 	# process option b Backup
        r) restore=1
    		echo "Restoring a user's files"
    		;; # process option r Resore
        \?) echo "Input error, please  use:
    		    -b to back up folders for current user
    		    -r to restore data for a user"
    	    exit 1
          ;;
      esac
    done
fi


#echo "Emptying trash"
#rm -rf /Users/$user/.Trash/*

#unmount any existing connections under /Users/<username>/_Backups_
umount $mnt_point
#wait for it to be unmounted fully
sleep 5s

# mount backups dir on graphics
if [ ! -d "$mnt_point" ]; then
	echo "mount point missing - creating"
	mkdir "$mnt_point"
fi

echo "Mounting "$fs_host"/"$fs_share" at mount point "$mnt_point

mount -t afp afp://"$fs_user":"$fs_pwd"@"$fs_host"/"$fs_share" "$mnt_point"

#___________________BACKUP_______________________________________

if [[ "$backup" -eq 1 ]]; then
	echo "Checking size of folders.  This could take a couple of minutes"
	desktop_size=`du -hs /Users/"$user"/Desktop | awk -F' ' '{print$1}'`
	documents_size=`du -hs /Users/"$user"/Documents | awk -F' ' '{print$1}'`
	downloads_size=`du -hs /Users/"$user"/Downloads | awk -F' ' '{print$1}'`
	raw_desktop_size=`du -sg /Users/"$user"/Desktop | awk -F' ' '{print$1}'`
	raw_documents_size=`du -sg /Users/"$user"/Documents | awk -F' ' '{print$1}'`
	raw_downloads_size=`du -sg /Users/"$user"/Downloads | awk -F' ' '{print$1}'`
	
	echo "Desktop is: "$desktop_size
	echo "Documents is: "$documents_size
	echo "Downloads is: "$downloads_size
	echo $raw_desktop_size
	echo $raw_documents_size
	echo $raw_downloads_size
	
	if [[ "$raw_desktop_size" -gt "$oversize" ]]; then
		read -p "Desktop is over "$oversize"Gb this will take some time to upload.
	Type Y to continue or Q to end the script allowing Desktop clean up. " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
		    		echo "Continuing with backup"
			else
					echo "Desktop too big.  Try deleting files or moving them to drive"
					exit 1
			fi
	else
		echo "Preparing to backup Desktop"

	fi
	
	if [[ "$raw_documents_size" -gt "$oversize" ]]; then
		read -p "Documents is over "$oversize"Gb this will take some time to upload. 
	Type Y to continue or Q to end the script allowing Documents clean up. " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
		    		echo "Continuing with backup"
			else
					echo "Documents too big.  Try deleting files or moving them to drive"
					exit 1
			fi
	else
		echo "Preparing to backup Documents"

	fi
	if [[ "$raw_downloads_size" -gt "$oversize" ]]; then
		read -p "Downloads is over "$oversize"Gb this will take some time to upload. 
	Type Y to continue or Q to end the script allowing Downloads clean up. " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
		    		echo "Continuing with backup"
			else
					echo "Downloads too big.  Try deleting files or moving them to drive"
					exit 1
			fi
	else
		echo "Preparing to backup Downloads"

	fi
	#check if /$mnt_point/<username> exists if not, create it
	if [ ! -d "$backup_dir" ]; then
		echo "This usermname not backed up previously"
		mkdir "$backup_dir"
	fi
	mkdir "$backup_sub_dir"
	mkdir "$backup_sub_dir"/Desktop
	mkdir "$backup_sub_dir"/Documents
	mkdir "$backup_sub_dir"/Downloads
	
	 #Do the backup
	echo "Backing up Desktop folder
	Its "$raw_desktop_size" so might take a while"
	rsync -aqz /Users/"$user"/Desktop/ "$backup_sub_dir"/Desktop/
	echo "Backing up Documents folder
	Its "$raw_documents_size" so might take a while"
	rsync -aqz /Users/"$user"/Documents/ "$backup_sub_dir"/Documents/
	echo "Backing up Downloads folder
	Its "$raw_downloads_size" so might take a while"
	rsync -aqz /Users/"$user"/Desktop/ "$backup_sub_dir"/Desktop/
	
	echo 'Backup complete'
fi	



#________________________________RESTORE_________________________________

if [[ "$restore" -eq 1 ]]; then
#For restore
#connect to FS
# list directories availble
# ask for user
# list restores availible
# ask for restore number
# create folder in desktop/downloads/documents
# cp all data from folder in to this dir

# Set the prompt for the select command
	PS3="Type a number or 'q' to quit: "
 
# Create a list of files to display
	dir_list=$(find "$mnt_point" -type d -maxdepth 1 -mindepth 1)
# Show a menu and ask for input. If the user entered a valid choice,
# then invoke the editor on that file
	select dir_name in $dir_list; do
    	if [ -n "$dir_name" ]; then
     	   user_dir=${dir_name}
			echo ${dir_name}
			rest_list=$(find "$user_dir" -type d -maxdepth 1 -mindepth 1)
			select rest_name in $rest_list; do
				if [ -n "$rest_name" ]; then
					echo ${rest_name}
					rest_dir=${rest_name}
					rest_dest_desk="/Users/"$user"/Desktop/Old_Desktop"
					rest_dest_docs="/Users/"$user"/Documents/Old_Documents"
					rest_dest_dls="/Users/"$user"/Downloads/Old_Downloads"
				
					if [ ! -d "$rest_dest_desk" ]; then
						mkdir "$rest_dest_desk"
					fi
					if [ ! -d "$rest_dest_docs" ]; then
						mkdir "$rest_dest_docs"
					fi
					if [ ! -d "$rest_dest_dls" ]; then
						mkdir "$rest_dest_dls"
					fi
					echo "Beginning copy of data to local machine"
					rsync -aqz "$rest_name"/Desktop/ "$rest_dest_desk"/
					rsync -aqz "$rest_name"/Documents/ "$rest_dest_docs"/
					rsync -aqz "$rest_name"/Downloads/ "$rest_dest_dls"/
					
					#make sure files are owned byt he right user
					chown -R "$user":staff "$rest_dest_desk"
					chown -R "$user":staff "$rest_dest_docs"
					chown -R "$user":staff "$rest_dest_dls"
				
				fi
				break
			done
  	  	fi
    	break
	done

	echo "Restore Complete make sure the correct files are in
        /Users/"$user"/Desktop/Old_Desktop
        /Users/"$user"/Documents/Old_Documents
        /Users/"$user"/Downloads/Old_Downloads"
fi


