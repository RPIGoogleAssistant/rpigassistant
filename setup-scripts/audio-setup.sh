#!/bin/bash
#
# Configure Raspberry Pi audio for USB MIC and onboard 3.5mm Jack.

set -o errexit

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GASSISTUSER=`logname`
GASSISTUSERHOME=`eval echo ~$GASSISTUSER`

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 1>&2
   exit 1
fi

cd $SCRIPTDIR

asoundrc=$GASSISTUSERHOME/.asoundrc
global_asoundrc=/etc/asound.conf

for rcfile in "$asoundrc" "$global_asoundrc"; do
  if [[ -f "$rcfile" ]] ; then
    echo "Renaming $rcfile to $rcfile.bak..."
    sudo mv "$rcfile" "$rcfile.bak"
  fi
done

sudo cp $SCRIPTDIR/asound.conf "$global_asoundrc"
sudo cp $SCRIPTDIR/asoundrc "$asoundrc"
echo "Installing USB MIC and onboard 3.5mm Jack config"

echo "=============Testing Speaker output============="
speaker-test -t wav -c 2 -l 1

echo "=============Recording Mic Audio Sample============="
arecord -d 10 -D hw:1,0 -r 44000 -f S16_LE -c1 /tmp/mic-test.wav

echo "Playing back the recorded audio sample......"
echo ""
aplay /tmp/mic-test.wav
