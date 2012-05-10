#!/bin/bash
#
# mp3blstr2dscrbblr.sh: last.fm/audioscrobbler song submission script for mp3blaster
#
# Copyright (C) 2006-2007,2012 Alexander Heinlein <alexander.heinlein@web.de>
#
# version: 0.4
#

# mp3blaster status file (mp3blaster -f <file>)
MP3_STAT="/tmp/mp3blaster"
# perl audioscrobbler plugin directory
# (http://search.cpan.org/~roam/Audio-Scrobbler-0.01/lib/Audio/Scrobbler.pm)
#DIR="/home/scytheman/Audio-Scrobbler-0.01/lib"
# plugin binary/script
#BIN="../bin/scrobbler-helper"
BIN="scrobbler-helper"

# maximum retries if first submission failed
MAX_RETRIES=15
# seconds to wait before second submission
# this value increases during further retries
WAIT=10

# check for existing status file
if ! test -e $MP3_STAT
then
	echo "$MP3_STAT doesn't exist, make sure mp3blaster is running with '-f $MP3_STAT'"
	exit
fi

# check for scrobbler binary
if ! which $BIN >/dev/null
then
	echo "$BIN doesn't exist, make sure libaudio-scrobbler-perl is installed"
	exit
fi

# first, check if the time of last modification is greather than 30s and less than 60s
# because this script will be executed every 30s, so we don't submit the same song twice
# and make sure we don't submit skipped tracks (user has 30s to skip the track)
# 
# we calculate the difference between last modification time (-> stat) and current time
# (-> date), both are seconds since 1970-01-01 00:00:00 UTC

# seconds since last modification
SSLM=$(echo "$(date "+%s") - $(stat -c "%Y" $MP3_STAT)" | bc)
if [ "$SSLM" -lt 30 ] || [ "$SSLM" -ge 60 ]
then
	echo "last modification time <30 or >=60"
	
	# user may skip this test by passing '--force' to script
	if [ "$1" = "--force" ]
	then
		echo "ignoring."
	else
		echo "specify '--force' to submit anyway"
		exit
	fi
fi

# check if song is playing otherwise there is the risc of submitting a song twice
# because every time a song is paused, mp3blaster updates it's status file, thus
# changing also time of last modification
if ! grep -q "^status playing" $MP3_STAT
then
	echo "no song playing"
	exit
fi

# we need 2 + 7 arguments:
#  -P <client> -V <clientversion>
#  title, artist, album, year, comment, genre, length
# note: - comment will be left empty
#       - genre will be specified globally

# unfortunately mp3blaster isn't recognized as client >:(
CLIENT="mpd"
CLIVER="0.11"

# mp3blaster doesn't list the genre in the status file
GENRE="rock"

# now get all information from mp3blaster
title=$(grep "^title " $MP3_STAT | cut -d ' ' -f2-)
artist=$(grep "^artist " $MP3_STAT | cut -d ' ' -f2-)
album=$(grep "^album " $MP3_STAT | cut -d ' ' -f2-)
year=$(grep "^year " $MP3_STAT | cut -d ' ' -f2-)
length=$(grep "^length " $MP3_STAT | cut -d ' ' -f2-)

# check if we have artist and title
# else print error message to stderr
if [ "$title" = "" ] || [ "$artist" = "" ]
then
	echo "error: $(grep "^path " $MP3_STAT | cut -d ' ' -f2-) has no/invalid ID tag" 1>&2
	exit
fi

# and finally execute plugin
if [ -n "$DIR" ]; then cd "$DIR"; fi

# creating function and variable for multiple use
SUBMIT="$BIN -P $CLIENT -V $CLIVER \"$title\" \"$artist\" \"$album\" \"$year\" \"\" \"$GENRE\" \"$length\""
submit()
{
    "$BIN" -P "$CLIENT" -V "$CLIVER" "$title" "$artist" "$album" "$year" "" "$GENRE" "$length" >/dev/null
}

echo
echo "executing $SUBMIT"
echo
submit

retval="$?"
# known return values:
#   22 bad hostname
#  104 Connection reset by peer
#  110 connection timeout
#  111 Connection refused (fuck you)
#  114 couldn't complete handshake
#  115 connection timeout
#  255 couldn't complete handshake
#  500 read timeout / EOF

# last submission failed, resubmit
if [ "$retval" ==  "22" ] || [ "$retval" == "104" ] || [ "$retval" == "110" ] || [ "$retval" == "111" ] \
|| [ "$retval" == "114" ] || [ "$retval" == "115" ] || [ "$retval" == "255" ] || [ "$retval" == "500" ]
then
    for ((i = 1; i <= MAX_RETRIES; i++))
    do
        echo "waiting for $WAIT seconds..."
        sleep $WAIT
        echo "retry #$i: executing $SUBMIT"
        submit

        if [ "$?" == "0" ]
        then
            exit 0
        fi

        # doubling next wait, server may be down for any length of time
        let "WAIT = $WAIT * 2"
    done
    echo "couldn't submit song after $MAX_RETRIES retries: $?" 1>&2
elif [ "$retval" != "0" ]
then
    echo "return value: $retval" 1>&2
fi
