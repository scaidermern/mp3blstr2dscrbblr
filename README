Overview
========
This is a song submission script for last.fm/audioscrobbler. The script
mp3blstr2dscrbblr.sh (mp3blaster to audioscrobbler) analyses the status file
of mp3blaster and delivers the gattered information to a perl script
(scrobbler-helper).

mp3blaster doesn't have a native plugin interface. Thus we have to retrieve
the required information through mp3blaster's status file (created by
calling 'mp3blaster -f <file>'). This will be done every 30 seconds by a
script called via cron. This script checks if the song is playing for at
least 30 seconds playing (giving the listener enough time to skip it) and at
most for 59 seconds (preventing multiple submissions). This check can be
disabled by calling the script with the parameter --force if required.

Requirements
============
- mp3blaster
- scrobbler-helper:
  http://search.cpan.org/~roam/Audio-Scrobbler-0.01/lib/Audio/Scrobbler.pm
  or
  libaudio-scrobbler-perl (debian package)
- last.fm account

Usage
=====
Make sure you run mp3blaster with '-f /tmp/mp3blaster' as argument (or
another location after configuring mp3blstr2dscrbblr.sh accordingly).

You also have to configure your last.fm username and password for
scrobbler-helper, usually via ~/.scrobbler-helper.conf

Then create a local cron job via 'crontab -e' and add something like:
*    *  *  *  *   nice -19 ~/scripts/mp3blstr2dscrbblr.sh > /dev/null & sleep 30s && nice -19 ~/scripts/mp3blstr2dscrbblr.sh > /dev/null
or:
*    *  *  *  *                nice -19 ~/scripts/mp3blstr2dscrbblr.sh > /dev/null
*    *  *  *  *   sleep 30s && nice -19 ~/scripts/mp3blstr2dscrbblr.sh > /dev/null

Note: cron runs every minute but mp3blstr2dscrbblr.sh has to be called every
30 seconds, hence the sleep.

That's all, now your songs should get scrobbled.
