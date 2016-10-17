#write out current crontab
crontab -l > mycron
#echo new cron into cron file
echo "0 3 * * * /usr/bin/docker exec stable python /root/scripts/oracle_backup.py -u sd -p sd -s scms.act" >> mycron
#install new cron file
crontab mycron
rm mycron
