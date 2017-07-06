#!/bin/bash
# Create test environment for cpanel dev server
# 5 cPanel account
# 3 AddonDomain by cPanel account
# 3 Mail account by cPanel account

#install wp-cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

#Creating cpanel account
c=0
while [ $c -le 4 ]
do
    USER=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 6 | head -n 1)
    PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    DOMAIN="$USER.com"

    whmapi1 createacct --output=jsonpretty username=$USER domain=$DOMAIN featurelist=default maxpark=unlimited maxaddon=unlimited password=$PASSWORD ip=n cgi=1 hasshell=1 cpmod=paper_lantern owner=root

    users_info+=("$USER")
    domains_info+=($DOMAIN)

    (( c++ ))
done

#Create subdomain, wordpress install and mail account by user
for i in "${users_info[@]}"
do
    #Create subdomains
    c=0
    while [ $c -le 2 ]
    do
        addon_domain=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
        path=$"/home/${i}/${addon_domain}"
        cpapi2 --output=jsonpretty --user=${i} AddonDomain addaddondomain newdomain=${addon_domain}.com subdomain=${addon_domain} dir=${path}
        (( c++ ))
    done

    #install wordpress in public_html
    wp_path=$"/home/${i}/public_html/"
    wp core download --path=${wp_path} --allow-root
    chown -R ${i}:${i} ${wp_path}*

    #Create mail accounts
    cc=0
    while [ $cc -le 2 ]
    do
        email_account=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
        password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        path=$"/home/${i}/${addonDomain}"
        uapi --output=jsonpretty --user=${i} Email add_pop email=${email_account} password=${PASSWORD} quota=0 domain=${i}.com skip_update_db=1
        (( cc++ ))
    done
done
