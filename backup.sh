#!/bin/bash
####################################################
# BackupScript V0.3
####################################################
# änderungse:
# V0.1:	Script für full backup
# V0.2: dazu: incremental backup
####################################################
# muss als root laufen sonst gehts nixn
####################################################
# für in cron rein für automatik:
# crontab -e
# @monthly /usr/local/sbin/backup.sh full
# @hourly /usr/local/sbin/backup.sh
####################################################
# restore geht ungefehr so:
# tar xzf /var/local/backup.complete.tgz --listed-incremental=/var/local/timestamp.snar
#ls /var/local/backup.[0-9][0-9][0-9][0-9][0-9][0-9].tgz | sort | xargs tar xzf --listed-incremental=/var/local/timestamp.snar
####################################################
# bin ich schon root?

if [ "$(id -u)" != "0" ]; then
	echo "Backup musste als root startn!!!" 1>&2
	exit 1
fi

####################################################
# läuft scho grad noch n backup?
if [ -e /usr/local/sbin/backup.lck ]; then
	exit 2
else
  	touch /usr/local/sbin/backup.lck
fi
###################################################
# Vars
# wohin speichern?
BUDIR=/var/local/backup  # nur fürn test. wird später die usbplatte
# Wohin mitm alten backup? immer ein monat lang aufheben. wer weis wofürs gut is
LMDIR=lastmonth
# Timestampfile für das incremetal backup wo tar brauch
TSFILE=timestamp.snar
# was kommt ales ins incremental backup
DIRS="/home /etc /usr /var"
# was soll ned ins backup
EXCL1="tmp"
EXCL2="dev"
EXCL3="proc"
# Name vom backupfile
BUNAME=backup

# Full backup?
if [[ $1 == "full" ]]; then
	# mach full backup
	BUDATE=complete
	# delete old timestamps
	rm -f "$BUDIR/$TSFILE"
	# delete old backups
	rm -rf "$BUDIR/$LMDIR.$BUNAME.d"
	# move  backups nach old backups
	mkdir "$BUDIR/$LMDIR.$BUNAME.d"
	mv -f "$BUDIR/$BUNAME".*.tgz "$BUDIR/$LMDIR.$BUNAME.d"
	DIRS="/" # full backup soll alles sichern
else
	# incremental backup
	BUDATE=$(date +%y%m%d_%H%M)
fi

# los gehts endlich
# sicherungskopie von alten logs
if [ ! -e /var/log/backup.old.logs.gz ]; then # file does not exist
	gzip -c /var/log/backup.*.err > /var/log/backup.old.logs.gz
	gzip -c /var/log/backup.*.err >> /var/log/backup.old.logs.gz
else
	gzip -c /var/log/backup.*.err >> /var/log/backup.old.logs.gz
	gzip -c /var/log/backup.*.err >> /var/log/backup.old.logs.gz
fi
rm /var/log/backup.*.err /var/log/backup.*.log
tar -I pigz -cvf "$BUDIR"/"$BUNAME"."$BUDATE".tgz -g "$BUDIR/$TSFILE" --exclude="$EXCL1" --exclude "$EXCL2" --exclude="$EXCL3" --exclude="$BUDIR" $DIRS 2>/var/log/backup."$BUDATE".err 1>/var/log/backup."$BUDATE".log 
rm /usr/local/sbin/backup.lck
