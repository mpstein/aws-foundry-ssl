#! /bin/bash
source /foundryssl/variables.sh

if [[ ${webserver_bool} == "True" ]]
then
    foundry_file="foundryvtt_webserver.conf"
else
    foundry_file="foundryvtt.conf"
fi

# install nginx
amazon-linux-extras install -y nginx1

# configure nginx
mkdir /var/log/nginx/foundry
cp /aws-foundry-ssl/files/nginx/${foundry_file} /etc/nginx/conf.d/foundryvtt.conf
sed -i "s|YOURSUBDOMAINHERE|${subdomain}|g" /etc/nginx/conf.d/foundryvtt.conf
sed -i "s|YOURDOMAINHERE|${fqdn}|g" /etc/nginx/conf.d/foundryvtt.conf

# change ownership of webserver files to nginx user
getent passwd nginx > /dev/null
if [ $? -ne 0 ]; then
    chown -R nginx /usr/share/nginx
fi

# start nginx
systemctl start nginx
systemctl enable nginx

# configure foundry for nginx
sed -i "s|\"hostname\":.*|\"hostname\": \"${subdomain}\.${fqdn}\",|g" /foundrydata/Config/options.json
sed -i 's|"proxyPort":.*|"proxyPort": "80",|g' /foundrydata/Config/options.json

# setup webserver
if [[ ${webserver_bool} == "True" ]]
then
    # copy webserver files
    git clone https://github.com/zkkng/foundry-website.git /foundry-website
    cp -rf /foundry-website/* /usr/share/nginx/html

    # change permissions
    chown nginx -R /usr/share/nginx/html
    chmod 755 -R /usr/share/nginx/html

    # clean up install files
    rm -r /foundry-website
fi

systemctl restart nginx