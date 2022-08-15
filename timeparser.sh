#!/bin/bash
##THE MESSAGE FULL PATH
MESG="/home/user/kidControl/msg"

##READ THE MAIL FORWARDER BY .forward SETTINGS
while read -r MSG
do
       echo "${MSG}" >> "${MESG}"
done

ACCEPTED=("user@doma.in" "anotheruser@indoma.in")
PARSEBASE="/home/user/kidControl/"
LIMITBASE="/home/user/public_html/limits_"
TIMERR=""
declare -a KIDERR
KCLOG="/home/user/kidControl/kclog"

##CHECK THE MAIL CAME FROM A VALID SOURCE
SENDER=$(grep "Return-Path:" "${MESG}" | sed -E 's/^.*<(.*)>/\1/')
TARGET=$(grep "Subject: LIMITS" "${MESG}")
TOPIC=$(sed 's/Subject: //' <<< "${TARGET}")
echo "$(date +%y%m%d_%H%M%S) [SUCCESS] New mail received from ${SENDER}" >> "${KCLOG}"

##ERROR HANDLING
function errorHandler()
{
        if [[ "${TIMERR}" ]]
        then
                KIDNAMES=""
                TIMERR=$(sed 's/,$//' <<< "${TIMERR}")
                printf "\nError in timeframe: ${TIMERR}!\n\n" > "${MESSAGE}"
                if [[ "${#KIDERR[@]}" -gt 0 ]]
                then
                        printf "Error in kid names!\n" >> "${MESSAGE}"
                        for kid in "${KIDERR[@]}"
                        do
                                echo "$(date +%y%m%d_%H%M%S) [ERROR] The name ${kid}} was not found from user list!" >> "${KCLOG}"
                                printf " -${kid} was not found from the list of users!\n" >> "${MESSAGE}"
                                KIDNAMES+="${kid} "
                        done
                        printf "\nCheck the name(s) and " >> "${MESSAGE}"
                else
                        printf "Check the " >> "${MESSAGE}"
                fi
                printf "timeframe for typos!\n\n\n --kidControl--\n\n" >> "$MESSAGE"
                mail -s "Re: ${TOPIC} [ERROR]" -aFrom:"$SENDERNAM"\<"$SENDERADD"\> "$RECIPIENT" < "$MESSAGE"
                rm "${MESSAGE}"
        elif [[ "${#KIDERR[@]}" -gt 0 ]]
        then
                printf "\nError in kid names!\n" > "${MESSAGE}"
                for kid in "${KIDERR[@]}"
                do
                        echo "$(date +%y%m%d_%H%M%S) [ERROR] The name ${kid}} was not found from user list!" >> "${KCLOG}"
                        printf " -${kid} was not found from the list of users!\n" >> "${MESSAGE}"
                        KIDNAMES+="${kid} "
                done
                printf "\nCheck the name(s) for typos!\n\n\n --kidControl--\n\n" >> "${MESSAGE}"
                mail -s "Re: ${TOPIC} [ERROR]" -aFrom:"$SENDERNAM"\<"$SENDERADD"\> "$RECIPIENT" < "$MESSAGE"
                rm "${MESSAGE}"
        ##IF NO ERRORS
        else
                printf "\nThe time limits were successfully updated as follows:\n\n\n" > "${MESSAGE}"
                for kid in "${KIDNARR[@]}"
                do
                        for limit in "${TIMELIMITS[@]}"
                        do
                                if [[ "${#limit}" -gt "1" ]] && [[ "${#limit}" -lt "5" ]]
                                then
                                        PART1=$(grep -Eo "^[0-9]?[^-]" <<< "${limit}")
                                        PART2=$(grep -Eo "[^-][0-9]?$" <<< "${limit}")
                                        if [[ "${#PART1}" -eq "1" ]]
                                        then
                                                limit="0$limit"
                                        fi
                                        if [[ "${#PART2}" -eq "1" ]]
                                        then
                                                limit="$PART1-0$PART2"
                                        fi
                                fi
                                LIMITS+="${limit},"
                        done
                        printf "$(date +%s)\n${LIMITS}"|sed 's/,$//' > "${LIMITBASE}${USERS[${kid}]}"
                        echo "$(date +%y%m%d_%H%M%S) [SUCCESS] New limits ${LIMITS} for ${kid} were succesfully written to ${LIMITBASE}${USERS[${kid}]}" | sed 's/, for/ for/' >> "${KCLOG}"
                        echo " -New limits for ${kid}: ${LIMITS}"|sed 's/,$//' >> "${MESSAGE}"
                        printf "  '--> Written to file: ${LIMITBASE}${USERS[${kid}]}\n\n" >> "${MESSAGE}"
                        LIMITS=""
                done
                printf "\n\n --kidControl--\n\n" >> "$MESSAGE"
                mail -s "Re: ${TOPIC} [SUCCESS]" -aFrom:"$SENDERNAM"\<"$SENDERADD"\> "$RECIPIENT" < "$MESSAGE"
                rm "${MESSAGE}"
                echo "" >> "${KCLOG}"
        fi
}


if [[ "${ACCEPTED[*]}" =~ "${SENDER}" ]] && [ "${TARGET}" ]
then
        declare -A USERS=([KID1]="076C8264" [KID2]="DF9214EF" [KID3]="2CB22AFA")
        SENDERADD="kidcontrol@yourdoma.in"
        SENDERNAM="kidControl"
        RECIPIENT="${SENDER}"
        MESSAGE="${PARSEBASE}MESSAGE"

        ##GREP ONLY MATCHING FOR ANYTHING WITH NOT A SPACE WHICH MUST BE PRESEEDED WITH "LIMITS "
        KIDNAME=$(grep -Po "(?<=LIMITS )[^ ]+" <<< "${TARGET}")
        if grep -Eq "\+" <<< "${KIDNAME}"
        then
                mapfile -t KIDNARR < <(sed 's/\+/\n/g' <<< "${KIDNAME}")
                for kidname in "${KIDNARR[@]}"
                do
                        if [[ ! "${USERS[${kidname}]}" ]]
                        then
                                KIDERR+=("${kidname}")
                        fi
                done
        elif [[ ! "${USERS[${KIDNAME}]}" ]]
        then
                KIDERR+=("${KIDNAME}")
        else
                mapfile -t KIDNARR <<< "${KIDNAME}"
        fi

        ##IF THE CONTENT-TRANSFER-ENCODING USED IS BASE64, WE NEED TO DECRYPT IT
        B64SROW=$(grep -m 1 -n "Content-Transfer-Encoding: base64" "${MESG}" | sed 's/:.*$//')
        TOTROWS=$(wc -l "${MESG}" | sed 's/ .*$//')
        REST=$((TOTROWS-B64SROW-1))
        B64EROW=$(($(tail -"$REST" "${MESG}"|grep -m 1 -n "^$"|sed 's/:.*$//')+B64SROW))
        ((B64SROW++))
        while [[ "${B64SROW}" -le "${B64EROW}" ]]
        do
                RESULT+=$(sed "${B64SROW}q;d" "${MESG}")
                ((B64SROW++))
        done
        B64D=$(base64 -d <<< "${RESULT}")

        ##GET THE TIME WINDOWS
        mapfile -t TIMELIMITS < <(grep -Eo "([0],|([0-9]{1,2}-[0-9]{1,2}),){6}(([0-9]{1,2}-[0-9]{1,2})|[0]){1}" <<< "${B64D}"|sed 's/,/\n/g')

        ##A TIMESLOT NEEDS TO BE DEFINED FOR EVERY DAY, 0 FOR ALL DAY LOCK
        if [[ "${#TIMELIMITS[@]}" -eq "7" ]]
        then
                for time in "${TIMELIMITS[@]}"
                do
                        if [[ "${time}" != "0" ]]
                        then
                                FIRST=$(sed -e 's/-.*$//' -e 's/^0//' <<< "${time}")
                                SECOND=$(sed -e 's/^.*-//' -e 's/^0//' <<< "${time}")
                                if [[ "${FIRST}" -gt "${SECOND}" ]]
                                then
                                        TIMERR+="${time},"
                                fi

                                if [[ "${TIMERR}" ]]
                                then
                                        echo "$(date +%y%m%d_%H%M%S) [ERROR] The provided timeframes ${TIMERR} contain errors!" >> "${KCLOG}"
                                fi
                        fi
                done
        else
                printf "$(date +%y%m%d_%H%M%S) [ERROR] In the provided timelimits: " >> "${KCLOG}"
                if [[ "${#TIMELIMITS[@]}" -gt "7" ]]
                then
                        TIMERR="too many timeslots"
                else
                        TIMERR="too few timeslots"
                fi
                printf "${TIMERR}!\n" >> "${KCLOG}"
        fi
        errorHandler
else
        echo "$(date +%y%m%d_%H%M%S) [ERROR] The sender was not found from the list of permitted users!" >> "${KCLOG}"
fi
rm "${MESG}"
