#!/bin/bash
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -o errexit

scripts_dir="$(dirname "${BASH_SOURCE[0]}")"
gassist_user=`logname`
gassist_user_home=`eval echo ~$gassist_user`

gassist_install_path="/opt/RPIGassistant"

if [ ! -d $gassist_install_path ]; then
    sudo mkdir -p $gassist_install_path
    sudo chown -R $gassist_user:$gassist_user $gassist_install_path
    sudo mkdir -p $gassist_install_path/logs/
fi

# make sure we're running as the owner of the checkout directory
RUN_AS="$(ls -ld "$scripts_dir" | awk 'NR==1 {print $3}')"
if [ "$USER" != "$RUN_AS" ]
then
    echo "This script must run as $RUN_AS, trying to change user..."
    exec sudo -u $RUN_AS $0
fi
clear
echo ""
read -r -p "Enter the your full credential file name including .json extension: " credname
echo ""
read -r -p "Enter the your Google Cloud Console Project-Id: " projid
echo ""
read -r -p "Enter a product name for your device (product name should not have space in between): " prodname
echo ""

modelid=$projid-$(date +%Y%m%d%H%M%S )
echo "Your Model-Id used for the project is: $modelid" >> $gassist_install_path/modelid.txt
cd $gassist_install_path
sudo apt-get update -y

sed 's/#.*//' $scripts_dir/system-requirements.txt | xargs sudo apt-get install -y
if [ ! -d $gassist_user_home/.config/mpv/scripts/ ]; then
  mkdir -p $gassist_user_home/.config/mpv/scripts/
fi
if [ -f $scripts_dir/end.lua ]; then
  mv $scripts_dir/end.lua $gassist_user_home/.config/mpv/scripts/end.lua
fi
if [ -f $scripts_dir/mpv.conf ]; then
  mv $scripts_dir/mpv.conf $gassist_user_home/.config/mpv/mpv.conf
fi


python3 -m venv env
env/bin/python -m pip install --upgrade pip setuptools wheel
source env/bin/activate

pip install -r $scripts_dir/pip-requirements.txt

pip install google-assistant-library==0.1.0
pip install google-assistant-grpc==0.1.0
pip install google-assistant-sdk==0.4.2
pip install google-assistant-sdk[samples]==0.4.2
pip install google-auth==1.3.0	google-auth-httplib2==0.0.3 google-auth-oauthlib==0.2.0
cp -f  $gassist_user_home/$credname .
google-oauthlib-tool --client-secrets $gassist_user_home/$credname --scope https://www.googleapis.com/auth/assistant-sdk-prototype --save --headless
googlesamples-assistant-devicetool register-model --manufacturer "Pi Foundation" \
          --product-name $prodname --type LIGHT --trait action.devices.traits.OnOff --model $modelid
echo "Testing the installed google assistant. Make a note of the generated Device-Id"
googlesamples-assistant-hotword --project_id $projid --device_model_id $modelid
