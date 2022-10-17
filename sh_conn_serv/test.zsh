#!/usr/bin/env zsh

function getch() {
    # STAT_GETCH=0
    # stty raw
    # TMP_GETCH=$(dd bs=1 count=1 2>/dev/null)
    # STAT_GETCH=$?
    # stty -raw

    # TO FIND KEYCODES:
    # stty raw; stty min 1 time 10; dd count=1 2>/dev/null | od; stty sane

    settings=$(stty -g) # Save current user's TTY settings
    stty raw
    stty min 1 time 10
    TMP_GETCH=$(dd count=1 2>/dev/null | od -tx | awk -F' ' 'NR==1{print $2;exit}' | awk '{sub(/^0*/,"");}1')
    stty $settings # Restore original TTY settings

    if [[ "_${1}" != "_quiet" ]]; then
        if [[ "${TMP_GETCH}" = "1b" ]]; then
            echo "_escape"
        elif [[ "${TMP_GETCH}" = "9" ]]; then
            echo "_tab"
        elif [[ "${TMP_GETCH}" = "d" ]]; then
            echo "_enter"
        elif [[ "${TMP_GETCH}" = "7f" ]]; then
            echo "_backspace"
        elif [[ "${TMP_GETCH}" = "415b1b" ]]; then
            echo "_up"
        elif [[ "${TMP_GETCH}" = "425b1b" ]]; then
            echo "_down"
        elif [[ "${TMP_GETCH}" = "435b1b" ]]; then
            echo "_right"
        elif [[ "${TMP_GETCH}" = "445b1b" ]]; then
            echo "_left"
        else
            echo -e "\x${TMP_GETCH}"
        fi
    fi
    return ${STAT_GETCH}
}

CONF="/var/tmp/bgssh.json"

function readConf() {
    if [[ -f "$CONF" ]]; then
        printf "$(cat $CONF | grep -m1 'USERNAME' | awk -F'"' '{print $4}')\n"
        printf "$(cat $CONF | grep -m1 'HOST' | awk -F'"' '{print $4}')\n"
        printf "$(cat $CONF | grep -m1 'KEY' | awk -F'"' '{print $4}')\n"
    else
        printf "$USER\n"
        printf "$(ifconfig -a | grep 'inet' | grep -m1 'broadcast' | awk -F' ' '{print $2}')\n"
        printf "$HOME\n"
    fi
}

# {
#     read -r username
#     read -r host
#     read -r key
# } <<<$(readConf)

X=0
Y=0

function movePos() { # movePos() dx dy
    # The positive directions are RIGHT→ and DOWN↓
    X=$(($X + $1))
    Y=$(($Y + $2))
    tput cup $Y $X
}

movePos 0 0
val=$(getch)
printf "%s" "$val"

movePos '-1' 0
val=$(getch)
printf "%s" "$val"
