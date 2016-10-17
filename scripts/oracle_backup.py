import argparse
import os, re, sys
import datetime, time, smtplib

# argument parser
parser = argparse.ArgumentParser()
parser.add_argument("-u", "--username", help="set oracle login user", action="store")
parser.add_argument("-p", "--password", help="set oracle login password", action="store")
parser.add_argument("-s", "--servername", help="set oracle server name", action="store")
args = parser.parse_args()

cUser = args.username
cPassword = args.password
cServername = args.servername

class RunCommand():
    def __init__(self, cUser, cPassword, cServername):
        # Write the log in the same directory as the script. Logname will be ScriptName.log
        self.cUser = cUser
        self.cPassword = cPassword
        self.cServername = cServername
        self.cSid = cServername.split('.')[0]
        
        self.f = open('/tmp/' + cUser + '_' + self.cSid + '.log','a')
        self.logger("Initializing", "Started")

        # Get the current time and set the fileprefix.
        self.sTime = datetime.datetime.now().strftime("%Y%m%d%H%M")
        self.fileprefix = self.cUser + '_' + self.cSid + self.sTime

        self.dpdumpdir = os.getenv('ORACLE_EXPDIR') + '/'
        self.backupdir = os.getenv('ORACLE_EXPDIR') + "/backup/"
        self.backftpdir = os.getenv('ORACLE_BAKFTP') + '/'

        # Build Data Pump Full Export command. Need to initially set environment variables.
        self.expdpcmd = "source /home/oracle/.bashrc;expdp {}/{}@{} directory=exp_dir dumpfile={}.dmp logfile={}.log schemas={}".format(
            self.cUser, self.cPassword, self.cServername, self.fileprefix, self.fileprefix, self.cUser)

        # Build Move Command
        # Build Compress Command
        # Build Remove Command: rm the dmp and log files as they have been compress into the tgz file.
        self.movecmd = "mv " + self.dpdumpdir + self.fileprefix + "* " + self.backupdir
        self.compresscmd = "tar -cjvf {}.tar.bz2 {}.dmp {}.log".format(self.backupdir+self.fileprefix, self.backupdir+self.fileprefix, self.backupdir+self.fileprefix)
        self.removecmd = "rm {}.dmp {}.log".format(self.backupdir+self.fileprefix, self.backupdir+self.fileprefix)

        # Rsync command.
        self.rsynccmd = "rsync -avz --no-o --no-g --no-p --no-t " + self.backupdir + " " + self.backftpdir + "/`date +%Y-%m`"
        self.rsynccmd = "cp "+self.backupdir+self.fileprefix+".tar.bz2 " + self.backftpdir + self.cSid + '/'

        self.status = {}
        self.status['expdpcmd'] = -1
        self.status['movecmd'] = -1
        self.status['compresscmd'] = -1
        self.status['removecmd'] = -1
        self.status['rsynccmd'] = -1
        self.status['removeOldBackups'] = []

        # Setup Email
        self.smtpserver = '61.164.102.98'
        self.sender = 'datacenter@southbedding.com'
        self.receivers = ['xuhui@southbedding.com']
        self.emailheader = "OracleBackup: scms"

        self.logger("Initializing", "Finished")

    def logger(self,section,action,msg=""):
        self.f.write(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S,") + section + "," + action + "," + msg + "\n")

    def run(self):
        # Run the commands only if the previous commands were successful.
        self.logger("Running", "Started")
        self.logger("expdpcmd", "Started", str(self.expdpcmd))
        self.status['expdpcmd'] = os.system(self.expdpcmd)
        self.logger("expdpcmd", "Finished", str(self.status['expdpcmd']))
        if self.status['expdpcmd'] == 0:
            self.logger("movecmd", "Started", str(self.movecmd))
            self.status['movecmd'] = os.system(self.movecmd)
            self.logger("movecmd", "Finished", str(self.status['movecmd']))
            if self.status['movecmd'] == 0:
                self.logger("compresscmd", "Started", str(self.compresscmd))
                self.status['compresscmd'] = os.system(self.compresscmd)
                self.logger("compresscmd", "Finished", str(self.status['compresscmd']))
                if self.status['compresscmd'] == 0:
                    self.logger("removecmd", "Started", str(self.removecmd))
                    self.status['removecmd'] = os.system(self.removecmd)
                    self.logger("removecmd", "Finished", str(self.status['removecmd']))
        self.logger("Running", "Finished", str(self.status))

    def rsyncFiles(self):
        self.logger("Synchronizing", "Started")
        self.logger("rsynccmd", "Started", str(self.rsynccmd))
        self.status['rsynccmd'] = os.system(self.rsynccmd)
        self.logger("rsynccmd", "Finished", str(self.status['rsynccmd']))
        self.logger("Synchronizing", "Finished", str(self.status))

    def removeOldBackups(self):
        self.logger("BackupCleanup", "Started")
        # Remove local backup files which are over 7 days old only if the synchronization job ran.
        if self.status['rsynccmd'] == 0:
            for file in os.listdir(self.backupdir):
                filetime = os.path.getmtime(self.backupdir + file)
                currenttime = time.time()
                fileage = currenttime - filetime
                if fileage > 604800:
                    try:
                        os.unlink(self.backupdir + file)
                    except:
                        self.logger("BackupCleanup", "Failed Removing", str(self.backupdir + file))
                        self.status['removeOldBackups'].append([str(self.backupdir + file),"Failed"])
                    else:
                        self.logger("BackupCleanup", "Success Removing", str(self.backupdir + file))
                        self.status['removeOldBackups'].append([str(self.backupdir + file),"Success"])
            self.logger("BackupCleanup", "Finished", str(self.status['removeOldBackups']))
        else:
            self.logger("BackupCleanup", "Finished", "No backups removed due to synchronization failure!")

    def sendStatusEmail(self):
        self.logger("SendingEmail", "Started")
        self.message = self.emailheader + "Oracle Data Pump Backup: " + self.sTime + "\n"

        self.message += "Subject: Oracle Bankup.\nFrom: {}\nTo: {}\n\nCommand Status:\n".format(self.sender, ','.join(self.receivers))
        for s in self.status:
            if s != 'removeOldBackups':
                self.message += "\t" + s + ": "
                if self.status[s] == 0:
                    self.message += "Success\n"
                elif self.status[s] == -1:
                    self.message += "NOP\n"
                else:
                    self.message += "Failed\n"

        self.message += "\nOld Backup Removal:\n"
        for f in self.status['removeOldBackups']:
            self.message += "\t" + f[1] + " removing backup file: " + f[0] + "\n"

        try:
            smtpObj = smtplib.SMTP(self.smtpserver)
            smtpObj.sendmail(self.sender, self.receivers, self.message)
        except smtplib.SMTPException:
            self.logger("SendingEmail", "Finished", "Failed to send email!")
        else:
            self.logger("SendingEmail", "Finished", str(self.status))

rc = RunCommand(cUser, cPassword, cServername)
rc.run()
rc.rsyncFiles()
rc.removeOldBackups()
rc.sendStatusEmail()
