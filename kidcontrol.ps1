##SET THE HOURS BETWEEN WHICH THE USER CAN LOG IN, SET 0 TO DISABLE LOGING IN ON THAT DAY
##             SUN      MON     TUE   WED     THU    FRI     SAT
$TIMEFRAME = '07-22','0','18-20','0','12-22','12-24','07-24'
$DAYNAMES =  'Su,',  'M,',    'T,',   'W,',   'Th,','F,',  'Sa,'

##GET TIME/DATE AT THE MOMENT
$TODAY=Get-Date -format "yyyy-MM-ddT"
$DAY=Get-Date -Uformat "%u"
$TIMEH=Get-Date -format "HH"
$TIMEM=Get-Date -format "mm"
$TIMES=Get-Date -format "ss"

##GET LOCAL USERS
$USERLIST = @()
$USERLIST += (Get-LocalUser).name

##GET THE ACCOUNTS THAT ARE ACTUALLY ENABLED
$ACTIVEUSERS = @()
for ($index = 0; $index -lt $USERLIST.count; $index++)
{
	if((Get-LocalUser -name $USERLIST[$index]).enabled)
	{
		$ACTIVEUSERS += $USERLIST[$index]
	}
}

##COUNT THE ENABLED ACCOUNTS
$USERCOUNT=$ACTIVEUSERS.count

##PROMPT THE USER TO SELECT THE ACCOUNT THE LIMITS ARE TO BE ENABLED TO
while($true)
{
	Write-Host "Choose the account to apply the time restrictions to:"
	for($index = 0; $index -lt $USERCOUNT; $index++)
	{
		$OPTINDX = $index+1
		$OPTN="'$OPTINDX' = " + $ACTIVEUSERS[$index]
		Write-Host $OPTN
	}
	Write-Host "'Q' = Cancel"
	$answer = Read-Host "Option"
	if ($answer -eq 'Q')
	{
		break
	}
	if ($answer -match "[1-$USERCOUNT]")
	{
		$ACCNM=$answer-1

		##SET THE USER AND MESSAGE TO SEND AS THE 5MIN WARNING MESSAGE
		$Msg =  ' Your account will be logged out in 5 minutes. Close all games, videos and music!'
		$User = $ACTIVEUSERS[$ACCNM]

		##SET THE PRINCIPAL SO THAT THE TASKS ARE ONLY TRIGGERED IF THE USER IS LOGGED ON
		##IF NOT LOGGED ON THE TIME RESTRICTIONS WILL BLOCK LOGIN AND THERE'S NO NEED FOR THE TASKS
		$Principal = New-ScheduledTaskPrincipal -LogonType Interactive -UserId $User

		##DEFINE THE USER THAT RUNS THE TASK (NO NEED TO CHANGE THIS)
		$RunUser = "NT AUTHORITY\SYSTEM"

		##DEFINE THE SCHEDULED TASKS TO RUN
		$MsgAction = New-ScheduledTaskAction -Execute "msg.exe" -Argument $User$Msg
		$LckAction = New-ScheduledTaskAction -Execute "%windir%\System32\rundll32.exe" -Argument "user32.dll, LockWorkStation"

		for ($index2 = 0; $index2 -lt $TIMEFRAME.count; $index2++)
		{
			##STICK WITH THE NAME ONCE CHOSEN, SO YOU DON'T NEED TO MANUALLY REMOVE THE TASKS
			##WHEN YOU UPDATE THE TIMES AND EXECUTE THE SCRIPT AGAIN
			##THE OLD TASKS WILL AUTOMATICALLY BE DELETED AND THEN RECREATED BECAUSE OF THE SAME TASKNAMES
			$MsgTaskName = 'TestTask'+$index2
			$LckTaskName = 'TaskTest'+$index2

			##DELETING THE OLD TASKS AND USING ERRORACTION SILENTLYCONTINUE TO SKIP NON EXISTENT TASKS
			Unregister-ScheduledTask -TaskName $MsgTaskName -Confirm:$false -ErrorAction SilentlyContinue
			Unregister-ScheduledTask -TaskName $LckTaskName -Confirm:$false -ErrorAction SilentlyContinue

			##HANDLE THE DEFINED DATES AND TIMES
			if($TIMEFRAME[$index2] -ne '0')
			{
				##CREATE THE TIME RULE TO EXECUTE FOR THE TIME RESTRICTIONS
				$LIMIT+=$DAYNAMES[$index2]+$TIMEFRAME[$index2]+';'

				##GET THE ENDING HOUR
				$SCHTIME=$TIMEFRAME[$index2] -replace '([0-9][0-9]-)([0-9][0-9])', '$2'

				$LCKSCHTIME=$SCHTIME.toString()

				##IF THE ENDING HOUR IS AT MIDNIGHT
				if($SCHTIME -eq '00' -or $SCHTIME -eq '24')
				{
					$SCHTIME=$SCHTIME.toString()
					$SCHTIME='23:55:00'
					$MSGSCHTIME='23:55'
					$LCKSCHTIME='23:59:59'
				}
				else
				{
					$LCKSCHTIME=$SCHTIME.toString()+':00'
					$SCHTIME=$SCHTIME-1
					$MSGSCHTIME=$SCHTIME.toString()+':55'
					$SCHTIME=$SCHTIME.toString()+':55:00'
					
				}

				##IF ONE OF THE TIMEOUTS NEEDS TO BE SCHEDULED ON THE SAME DAY
				if($DAY -eq $index2)
				{
					$SCHD=$TODAY+$SCHTIME	
				} 
				elseIf($DAY -lt $index2)
				{
					$DFRWD=$index2-$DAY
					$SCHD=(Get-Date).AddDays($DFRWD).toString("yyyy-MM-ddT")+$SCHTIME
				}
				else
				{
					$DFRWD=(6-$DAY)+($index2+1)
					$SCHD=(Get-Date).AddDays($DFRWD).toString("yyyy-MM-ddT")+$SCHTIME
				}

				##CREATE THE SCHEDULED TASK TRIGGERS AND REPEAT THE SAME SCHEDULED MSG AND LOCK EVERY WEEK AT THE SAME TIME
				$MSGDAY = (Get-Date $SCHD).DayOfWeek
				$LCKDAY = $MSGDAY
				$MsgTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $MSGDAY -At $MSGSCHTIME;
				$LckTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $LCKDAY -At $LCKSCHTIME;

				##REGISTER THE SCHEDULED TASKS == CREATE THE TASKS
				Register-ScheduledTask -Principal $Principal -TaskName $MsgTaskName -Trigger $MsgTrigger -Action $MsgAction -Force
				Register-ScheduledTask -Principal $Principal -TaskName $LckTaskName -Trigger $LckTrigger -Action $LckAction -Force
			}
		}

		##COMPILE THE COMMAND FOR LOGIN TIME RESTRICTIONS ON THE USER'S ACCOUNT
		$LIMITUSR='net user ' + $ACTIVEUSERS[$ACCNM] + ' /time:'

		#USE HERESTRING, OTHERWISE THE SEMICOLON WILL NOT BE RECOGNIZED
$LIMITHERESTRING=@"
$LIMITUSR$LIMIT
"@
		#RUN THE TIME LIMITS FOR THE DEFINED USER
		cmd /c $LIMITHERESTRING

		break
	}
	else 
	{
        	Write-Warning "Bad option! Please try again."
	}
  #CLEAR CONSOLE AND START AGAIN IF A BAD OPTION WAS PROVIDED
	Start-Sleep -Seconds 2
}
