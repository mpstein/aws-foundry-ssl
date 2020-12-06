#!/bin/bash

# grab variables
source /aws-foundry-ssl/variables/foundry_variables.sh
source /foundryssl/variables.sh

# install packages for foundry
yum install -y nodejs
yum install -y openssl-devel

# download foundry from patreon link or google drive
pushd /foundry
if [[ `echo ${foundry_download_link}  | cut -d '/' -f3` == 'drive.google.com' ]]
then
    fileid=`echo ${foundry_download_link} | cut -d '/' -f6`
    sudo wget --quiet --save-cookies cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=${fileid}" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p' > confirm.txt
    sudo wget --load-cookies cookies.txt -O foundry.zip 'https://docs.google.com/uc?export=download&id='${fileid}'&confirm='$(<confirm.txt) && rm -rf cookies.txt confirm.txt
else 
    sudo wget -O foundry.zip "${foundry_download_link}"
fi

unzip -u foundry.zip
rm -f foundry.zip
popd 

# change foundry owner
chown -R foundry-user:foundry-user /foundry
chown -R foundry-user:foundry-user /foundrydata

# start foundry and add to boot
cp /aws-foundry-ssl/files/foundry/foundry.service /etc/systemd/system/foundry.service
chmod 644 /etc/systemd/system/foundry.service
systemctl daemon-reload
systemctl start foundry
systemctl enable foundry
sleep 10s

# configure foundry aws json file
cp /aws-foundry-ssl/files/foundry/options.json /foundrydata/Config/options.json
cp /aws-foundry-ssl/files/foundry/AWS.json /foundrydata/Config/AWS.json
sed -i "s|ACCESSKEYIDHERE|${access_key_id}|g" /foundrydata/Config/AWS.json
sed -i "s|SECRETACCESSKEYHERE|${secret_access_key}|g" /foundrydata/Config/AWS.json
sed -i "s|REGIONHERE|${region}|g" /foundrydata/Config/AWS.json

# configure foundry options file
sed -i 's|"awsConfig":.*|"awsConfig": "/foundrydata/Config/AWS.json",|g' /foundrydata/Config/options.json

# allow rwx in the Data folder only for foundry-user
chown foundry-user:foundry-user -R /foundrydata/Data
chmod 755 -R /foundrydata/Data
