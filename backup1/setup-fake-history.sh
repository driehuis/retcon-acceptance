#!/bin/sh

set -e

now=`date +%s`
oneday=`expr 24 \* 3600`
_then=`expr $now - $oneday \* 365`

if [ -e /tank/fakehist ]
then
  zfs destroy -r tank/fakehist
fi
zfs create tank/fakehist
while [ $_then -le $now ]
do
  date -d @$_then > /tank/fakehist/timestamp.txt
  zfs snapshot tank/fakehist@$_then
  _then=`expr $_then + $oneday`
done
