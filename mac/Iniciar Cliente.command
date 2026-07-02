#!/bin/bash
cd "$(dirname "$0")"
open -a XQuartz
sleep 3
for d in /private/tmp/com.apple.launchd.*/org.xquartz:0; do
  if [ -e "$d" ]; then export DISPLAY="$d"; break; fi
done
if [ -z "$DISPLAY" ]; then export DISPLAY=:0; fi
xattr -d com.apple.quarantine ./otclient_mac 2>/dev/null
chmod +x ./otclient_mac
./otclient_mac
