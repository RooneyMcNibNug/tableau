#!/bin/bash
###	
#   Scheduled (cron) run: 
#	  sudo su -l tableau -c "crontab -e"
#		
#	  EXAMPLE:
#		0 0 */3 * * /var/opt/tableau/tableau_server/scripts/tableau-server-backup.bash > /var/log/tableau-server-backup.log
###

## VARS:

DATE=`date '+%Y-%m-%d'` # For backup files
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'` # For log entries

copy_bkp="no" # Copy backups to s3 bucket (Y/N)?
bkp_path="/var/opt/tableau/tableau_server/data/tabsvc/files/backups/"
bkp_days="7"
bkp_name="tableau-server-backup"

## TABLEAU ENVIRONEMT VARS
source /etc/profile.d/tableau_server.sh
source /etc/opt/tableau/tableau_server/environment.bash

## BACKUP PROCESS
echo $TIMESTAMP "The path for storing backups is $bkp_path" 

# count the number of backup files eligible for deletion and output 
echo $TIMESTAMP "Cleaning up old backups..."
lines=$(find $backup_path -type f -regex '.*.\(tsbak\|json\)' -mtime +$bkp_days | wc -l)
if [ $lines -eq 0 ]; then 
	echo $TIMESTAMP $lines old backups found, skipping...
	else echo  $TIMESTAMP $lines old backups found, deleting...
		#remove backup files older than N days
		find $backup_path -type f -regex '.*.\(tsbak\|json\)' -mtime +$bkp_days -exec rm -f {} \;
fi

#export current settings
echo $TIMESTAMP "Exporting current settings..."
tsm settings export -f $bkp_path/settings-$DATE.json
#create current backup
echo $TIMESTAMP "Backup up Tableau Server data..."
tsm maintenance backup -f $bkp_name -d

#obtaining the latest settings
lastest_settings=$(ls -t $bkp_path/*.json | head -n1)
#obtaining the latest backup
lastest_backup=$(ls -t $bkp_path/*.tsbak | head -n1)

#copy backups to different location (optional)
if [ "$copy_bkp" == "yes" ];
	then
	echo $TIMESTAMP "Copying backup and settings to remote location"
	# Maybe something here to push out to an s3 bucket?
  #
fi

## END
echo $TIMESTAMP "Backup completed"