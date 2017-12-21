#!/bin/bash

# $1 whatlevel
# ends in 122 update needed
# ends in 123 update not needed
# end in 0 sucess
function jumpto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

start=${1:-"start"}
jumpto $start

start:
#none found
echo requested level not found,killing.
jumpto exit

lastestdiscordver:
url="https://discordapp.com/api/updates/canary?platform=linux"
version=$(curl -s $url | jq .name)
echo $version
exitcode=$version
jumpto exit

localdiscordversion:
set /p version=<localversion.txt
echo $version
exitcode=$version
jumpto exit

killdiscord:
if pgrep DiscordCanary ; then
  pkill DiscordCanary
  sleep 1
  pkill -9 DiscordCanary
fi
exitcode="0"
jumpto exit

checkforupdate:
# check to see if their is a update
url="https://discordapp.com/api/updates/canary?platform=linux"
lastestversion=$(curl -s $url | jq .name)
localversion=$(cat localversion.txt)
if [ "$(printf "$lastestversion\n$localversion" | sort -V | head -n1)" == "$localversion" ] && [ "$localversion" != "$lastestversion" ]; then
       exitcode="122"
else
       exitcode="123"
fi
jumpto exit

installdiscord:
rm -rf DiscordCanary
lastesturl="https://discordapp.com/api/download/canary?platform=linux&format=tar.gz"
url="https://discordapp.com/api/updates/canary?platform=linux"
version=$(curl -s $url | jq .name)
wget -O lastest.tar.gz $lastesturl
tar xvzf lastest.tar.gz
rm lastest.tar.gz
echo $version > localversion.txt
exitcode="0"
jumpto exit

postinst:
# start of  postins.sh script
cd DiscordCanary
# os.tmpdir from node.js
for OS_TMPDIR in "$TMPDIR" "$TMP" "$TEMP" /tmp
do
  test -n "$OS_TMPDIR" && break
done
# This is probably just paranoia, but some people claim that clearing out
# cache and/or the sock file fixes bugs for them, so here we go
for DIR in /home/* ; do
  rm -rf "$DIR/.config/discordcanary/Cache"
  rm -rf "$DIR/.config/discordcanary/GPUCache"
done
rm -f "$OS_TMPDIR/discordcanary.sock"
# end of postins.sh script
cd ..
exitcode="0"
jumpto exit

startdiscord:
DiscordCanary/DiscordCanary
exitcode="0"
jumpto exit

exit:
exit $exitcode
