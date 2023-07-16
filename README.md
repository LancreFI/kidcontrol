# kidcontrol
Automatically create login time restrictions, notification messages and automatic lock of a local user account in Windows 10 when the specified restriction is reached.

Noticed that you can specify allowed login hours for a local user in Windows 10 with "net user username /time:M-Su,7-21". Used this to define restrictions for my kids, because imho this is better than usage time based restriction. Unfortunately these don't affect anything if the user is logged in and the screenlock is not activated. So my kids went on gaming sprees well past their limits.

Sure there might've been options if you would create an MS account, which I would never do, so options for limiting local user accounts seemed a bit limited or sketchy.

These scripts let you set the allowed login times per day (for example M,07-21 = Monday from 07:00 to 21:00), apply them all at once on the chosen user account, create a scheduled task to notify the user through msg.exe when 5 minutes of screen time remain and then automatically lock the screen when the time limit is reached via another automatically created task, this way preventing the user from logging in until the next allowed date/time.

-----------------
<pre>
Put all the following three files in the same folder!

kidControl.ps1 sets the time limts based on the local file kidLimits, which in the provided example file contains:
1657490379 <-- Unix timestamp
'07-22','0','0','0','0','12-23','07-22' <-- limits per days (Sunday, Monday, Tuesday, ... Saturday)
Set the limit to 0, if there's no usage time for the specific date. So this file should contain only these two 
rows. Same goes with the online file.

--

kidControl.ps1
Set the desired user to which the rules will be applied to on row 17 and the desired notify message on row 16.
Optionally set the base names for the tasks to be created on lines 35 and 36 (if both tasks are named the same, 
the script will produce bull.

You can also run this scipt on its own with only the kidLimits defined, or use the automated online polling. 
Run from powershell with .\kidControl.ps1

--

kidAutoLimiter.ps1 polls for new limts from a server you can define on row 13. On row 29 you can define the full 
URI of the time limit file. The file should be named limits_deviceid, where the deviceid is the Device ID of the 
target to which the limits will be applied. You can check your kids ID from their PC through PowerShell by 
issuing: (Get-Itemproperty -Path HKLM:\SOFTWARE\Microsoft\SQMClient -Name MachineID).MachineID.Substring(1,8)

To get this running you need to add a scheduled task, preferably through admin account by running 
Task Scheduler --> Action --> Create Task (you can change the polling from 5 minutes to more sparse if needed):
Name: CheckForNewLimits
Location: \
Author: youradminaccount
Description: Poll for new time limits for kidControl
Run whether user is logged on or not
Run with highest privileges

Triggers --> New: 
Begin the task: On a schedule
One time, at xx:xx after triggered 
Advanced settings: Repeat task every 5 minutes for a dudation of: Indefinitely 
Check enabled

Actions --> New: 
Start a program: powershell -File C:\users\adminaccount\kidControl\kidAutoLimiter.ps1

Settings: Allow task to be run on demand
Stop the task if it runs longer than: 1 hour
If the running task does not end when requested, force it to stop
--> OK

--

.forward is a file which redirects emails designated to me in my hosting environment through some special 
email alias that gets redirected, to timeparser.sh shell script that will parse the time limits from the email 
and save them on my server. Should reside in your hosting root.

--

This only works, if the emails received are b64 encoded for the content part! The email should have the topic 
starting with the word LIMITS and the kids' names, as described below. The email content should start with the 
time limits on the first row like for example: 08-12, 09-13, 02-23, 11-13, 0, 11-12, 12-14
The first limit would be for Sunday and allowing usage between 08-12 etc. You can have multiple names in the 
topic if you want to set the same limits to those multiple users, otherwise send an email per user to set specific 
limits to specific users. 

timeparser.sh parses the new per kid limits or multiple kids' limits from an email, that has subject in the 
format of: LIMITS KIDNAME1+KIDNAME2+KIDNAME3
Line3: define the full path for the email message containing the new limits
Line11: define the email addresses that are allowed to send new limits
Line12: the base folder for the script
Line13: the public limits file basename
Line16: the log file
Line26: define the kids' names and MachineIDs
Line27: define sender address for confimation email
Line28: define the sender name

--
  
msg.exe.files are needed if you want the message to be sent to the user 5 minutes prior to auto-lockdown.
msg.exe needs to be placed under windows/system32
msg.exe.mui needs to be placed under windows/system32/en-us, which might need a bit of trickery to be able to actually copy
the file over. Temporarily change the ownership of the folder, if it's owned by TrustedInstaller, to your admin
user account, but when offered or given error of changing the ownership of subfolder/files, just cancel it as you
only need the temporary ownership of the folder to be able to upload files, not the subfiles or folders. After this 
you can as the owner change the folder permissions, so give Administrators or just your own account temporarily full 
control, make sure you again cancel the permission change to subfolders/files. copy over the .mui, then revert your 
permissions back to read+execute for the .mui and read+execute+list for the en-us folder and  change the ownership 
back to TrustedInstaller (NT Service\TrustedInstaller) for both and you should have a working msg.exe.
Tested on Win11.

--  

Caveats: only one time window per day is possible and only restrict by full hours, so doesn't understand minutes.
</pre>
-----------------
