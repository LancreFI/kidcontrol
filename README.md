# kidcontrol
Automatically create login time restrictions, notification messages and automatic lock of a local user account in Windows 10 when the specified restriction is reached.

Noticed that you can specify allowed login hours for a local user in Windows 10 with "net user username /time:M-Su,7-21". Used this to define restrictions for my kids, because imho this is better than usage time based restriction. Unfortunately these don't affect anything if the user is logged in and the screenlock is not activated. So my kids went on gaming sprees well past their limits.

Sure there might've been options if you would create an MS account, which I would never do, so options for limiting local user accounts seemed a bit limited or sketchy.

This script let's you set the allowed login times per day (for example M,07-21 = Monday from 07:00 to 21:00), apply them all at once on the chosen user account, create a scheduled task to notify the user through msg.exe when 5 minutes of screen time remain and then automatically lock the screen when the time limit is reached via another automatically created task, this way preventing the user from logging in until the next allowed date/time.

Running the script again it will remove the old scheduled tasks and login restriction times, and recreate them with the new time limits.

So add the restriction on line 3, set the desired notify message on line 51 and optionally set the base names for the tasks to be created on lines 69 and 70 (if both tasks are named the same, the script will produce bull). Run the script as admin from powershell with: .\kidcontrol.ps1.

Caveats: only one time window per day is possible and only restrict by full hours, so doesn't understand minutes.
