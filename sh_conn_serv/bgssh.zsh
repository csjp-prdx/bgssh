#!/usr/bin/env zsh
IFS=''

X=0
X_OFF=2
Y=0
Y_OFF=2
SEL=1
PSEL=0
CONF="/var/tmp/bgssh.json"

function conn2Srv() {
    local PID=$(ps -ef | grep "ssh -fo ExitOnForwardFailure=yes -i $key $username@$host" | grep -v 'grep' | awk '{print $2}' 2>/dev/null)

    if [[ "$?" -eq 0 ]]; then
        $(ping localhost:8000 -c1 >/dev/null 2>&1)
        if ! [[ "$?" -eq 0 ]]; then
            kill $PID
            $(ssh -fo ExitOnForwardFailure=yes -i $key $username@$host -N -L 8000:localhost:80 >/dev/null 2>&1)
        fi
    else
        $(ssh -fo ExitOnForwardFailure=yes -i $key $username@$host -N -L 8000:localhost:80 >/dev/null 2>&1)
    fi

    open "http://localhost:8000/$subdir"
}

function getKeyInput() {
    stty raw
    stty min 1 time 10
    local TMP_GETCH=$(dd count=1 2>/dev/null | od -tx | awk -F' ' 'NR==1{print $2;exit}' | awk '{sub(/^0*/,"");}1')
    stty sane
    stty -raw

    # if [[ "_${1}" != "_quiet" ]]; then
    if [[ "$TMP_GETCH" = "1b" ]]; then
        printf "_escape\n"
    elif [[ "$TMP_GETCH" = "9" ]]; then
        printf "_tab\n"
    elif [[ "$TMP_GETCH" = "d" ]]; then
        printf "_enter\n"
    elif [[ "$TMP_GETCH" = "7f" ]]; then
        printf "_backspace\n"
    elif [[ "$TMP_GETCH" = "415b1b" ]]; then
        printf "_up\n"
    elif [[ "$TMP_GETCH" = "425b1b" ]]; then
        printf "_down\n"
    elif [[ "$TMP_GETCH" = "435b1b" ]]; then
        printf "_right\n"
    elif [[ "$TMP_GETCH" = "445b1b" ]]; then
        printf "_left\n"
    else
        print "\x${TMP_GETCH}"
    fi
    # fi
    return ${STAT_GETCH}
}

function movePos() { # movePos() dx dy
    # The positive directions are RIGHT→ and DOWN↓
    X=$(($X + $1))
    Y=$(($Y + $2))
    tput cup $Y $X
}

function readConf() {
    if [[ -f "$CONF" ]]; then
        printf "$(cat $CONF | grep -m1 'USERNAME' | awk -F'"' '{print $4}')\n"
        printf "$(cat $CONF | grep -m1 'HOST' | awk -F'"' '{print $4}')\n"
        printf "$(cat $CONF | grep -m1 'KEY' | awk -F'"' '{print $4}')\n"
        printf "$(cat $CONF | grep -m1 'SUBDIR' | awk -F'"' '{print $4}')\n"
    else
        printf "$USER\n"
        printf "$(ifconfig -a | grep 'inet' | grep -m1 'broadcast' | awk -F' ' '{print $2}')\n"
        printf "$HOME\n"
        printf "/\n"
    fi
}

function writeConf() {
    diff $CONF <(printf "{\n\t\"1\": {\n\t\t\"USERNAME\":\"$username\",\n\t\t\"HOST\":\"$host\",\n\t\t\"KEY\":\"$key\",\n\t\t\"SUBDIR\":\"$subdir\"\n\t}\n}") >/dev/null 2>&1
    if ! [[ "$?" -eq 0 ]]; then
        # If the configuration has not changed, don't save
        printf "{\n\t\"1\": {\n\t\t\"USERNAME\":\"$username\",\n\t\t\"HOST\":\"$host\",\n\t\t\"KEY\":\"$key\",\n\t\t\"SUBDIR\":\"$subdir\"\n\t}\n}" >$CONF
    fi
}

function showEntry() {
    tput el
    tput sc
    if [[ "$1" -eq 1 ]]; then
        printf "$username"
    elif [[ "$1" -eq 2 ]]; then
        printf "$host"
    elif [[ "$1" -eq 3 ]]; then
        printf "$key"
    elif [[ "$1" -eq 4 ]]; then
        printf "$subdir"
    fi
    tput rc
}

function modEntry() {
    tput smul
    movePos 12 $SEL
    showEntry $SEL

    while true; do
        local val=$(getKeyInput)
        if [[ "$val" = '_escape' ]] || [[ "$val" = '_enter' ]]; then
            break
        elif [[ "$val" = '_backspace' ]]; then
            [[ $SEL = 1 ]] && username=$(echo "$username" | sed 's/.$//')
            [[ $SEL = 2 ]] && host=$(echo "$host" | sed 's/.$//')
            [[ $SEL = 3 ]] && key=$(echo "$key" | sed 's/.$//')
            [[ $SEL = 4 ]] && subdir=$(echo "$subdir" | sed 's/.$//')
            showEntry $SEL
        elif ! [[ "$val" =~ "_[a-z]+" ]] && [[ "$val" =~ "[a-zA-Z0-9.-/]" ]]; then
            [[ $SEL = 1 ]] && username+="$val"
            [[ $SEL = 2 ]] && host+="$val"
            [[ $SEL = 3 ]] && key+="$val"
            [[ $SEL = 4 ]] && subdir+="$val"
            showEntry $SEL
        fi
    done

    tput rmul
    showEntry $SEL
    movePos "-12" "-$SEL"
}

function main() {
    tput civis
    tput clear # clear the screen

    movePos $X_OFF 1
    tput rev # Set reverse video mode
    printf " SERVER CONNECTION CONFIG \n"
    tput sgr0

    movePos 0 7
    tput setaf 4
    printf "Q:Quit  S:Save  C:Connect\n"
    tput sgr0
    movePos -1 -6

    {
        read -r username
        read -r host
        read -r key
        read -r subdir
    } <<<$(readConf)

    movePos 0 1
    printf "> Username: $username"
    movePos 0 1
    printf "  Host:     $host"
    movePos 0 1
    printf "  Key:      $key"
    movePos 0 1
    printf "  SubDir:   $subdir"
    movePos 0 -4

    while true; do
        while true; do
            local val=$(getKeyInput)
            if [[ "$val" = '_up' ]]; then
                if [[ $SEL -gt 1 ]]; then
                    PSEL=$SEL
                    SEL=$((SEL - 1))
                    break
                fi
            elif [[ "$val" = '_down' ]]; then
                if [[ $SEL -lt 4 ]]; then
                    PSEL=$SEL
                    SEL=$((SEL + 1))
                    break
                fi
            elif [[ "$val" = '_enter' ]]; then
                modEntry
            elif [[ "$val" = 'q' ]] || [[ "$val" = 'Q' ]]; then
                break 2
            elif [[ "$val" = 's' ]] || [[ "$val" = 'S' ]]; then
                writeConf
                break 2
            elif [[ "$val" = 'c' ]] || [[ "$val" = 'C' ]]; then
                writeConf
                conn2Srv
                break 2
            fi
        done

        movePos 0 1
        [ $SEL = 1 ] && printf "> " || printf "  "
        printf "Username: $username"
        movePos 0 1
        [ $SEL = 2 ] && printf "> " || printf "  "
        printf "Host:     $host"
        movePos 0 1
        [ $SEL = 3 ] && printf "> " || printf "  "
        printf "Key:      $key"
        movePos 0 1
        [ $SEL = 4 ] && printf "> " || printf "  "
        printf "SubDir:   $subdir"
        movePos 0 -4
    done

    tput clear # clear the screen
    tput cnorm
}

main
