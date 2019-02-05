#!/bin/bash

# Styles
VP_NONE='\033[00m'
VP_RED='\033[01;31m'
VP_GREEN='\033[01;32m'
VP_YELLOW='\033[01;33m'
VP_PURPLE='\033[01;35m'
VP_CYAN='\033[01;36m'
VP_WHITE='\033[01;37m'
VP_BOLD='\033[1m'
VP_UNDERLINE='\033[4m'

dirName=${PWD##*/}

#Forwarn Part 1
if [ ! "$(ls -a ./.git)" ]; then
    echo -e "${VP_RED}This script runs under the assumption that you've cloned a repository down."
    echo ""
    echo -e "Exiting script.${VP_NONE}${VP_WHITE}"
    exit
fi

# Inform the user that this is assuming they're using Valet-plus
echo -e "${VP_CYAN}This bash script is under the assumption that you are using valet-plus to set up this WordPress install.${VP_NONE}"
echo -e "${VP_CYAN}${VP_BOLD}This script will now clear your terminal window.${VP_NONE}"
echo ""
echo -e "${VP_WHITE}${VP_BOLD}Please press enter to continue."
read clearTerminal
clear

# We will now try to cache the sudo password, as we'll be setting up an SSL for their dev environment
echo -e "${VP_RED}${VP_BOLD}You may be asked twice for your password, but this is to setup an SSL locally to best mimic a live environment.${VP_NONE}"
sudo -v

# Set the Site Name
echo -e "Enter the site name."
read siteName
echo ""

# Set the database name
echo -e "Enter your chosen database name."
echo -e "${VP_WHITE}Note, wp_ is automatically prefixed"
read dbName
echo ""

# Let's double check the WordPress version they want to download
echo -e "${VP_PURPLE}If you'd like to download a different version number, please enter in the number, otherwise, just press enter.${VP_WHITE}"
read wpVersion
echo ""

# Start downloading WordPress and it's latest version
[ -z "$wpVersion" ] && wp core download || wp core download --version=$wpVersion

## Create the wp-config file and the database
echo -e "${VP_PURPLE}Creating database and setting up wp-config.php file.${VP_WHITE}"
wp config create --dbname=wp_$dbName --dbuser=root --dbpass=root --extra-php <<PHP
define( 'WP_DEBUG', true);
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
PHP

wp db create

if [ $? -eq 0 ]
then
    echo -e "${VP_GREEN}All set.${VP_WHITE}"
else
    rm -rf wp-config.php
    echo -e "${VP_RED}Database 'wp_$dbName' exists. Please enter another db name."
    
    echo -e "Enter your chosen database name."
    echo -e "${VP_WHITE}Note, wp_ is automatically prefixed"
    read dbNameReTry
    echo ""

    wp config create --dbname=wp_$dbNameReTry --dbuser=root --dbpass=root --force --extra-php <<PHP
define( 'WP_DEBUG', true);
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
PHP
    wp db create
    if [ $? -eq 0 ]
    then
        echo -e "{$VP_RED}Please double check that this database doesn't exists in your mysql."
        echo -e "${VP_WHITE}Exiting script.${VP_NONE}${VP_WHITE}"
        exit
    fi
fi

# Set the admin
echo -e "Please enter in a username."
read adminUser

# Set admin password
echo ""
echo -e "Please enter in a password."
read adminPassword

# Set the admin email
echo ""
echo -e "Please enter in the admin email."
read adminEmail

# Beginning of site build
wp core install --url=$dirName.app --title="$siteName.app" --admin_user=$adminUser --admin_password=$adminPassword --admin_email=$adminEmail

if [ ! $? -eq 0 ]
then
    echo -e "${VP_RED}You have some errors. Please check your errors.${VP_WHITE}"
    
    # Set the admin
    echo -e "Please enter in a username."
    read adminUser

    # Set admin password
    echo -e "Please enter in a password."
    read adminPassword

    # Set the admin email.
    echo -e "Please enter in the admin email."
    read adminEmail

    # Beginning of site build.
    wp core install --url=$dirName.app --title="$dirName.app" --admin_user=$adminUser --admin_password=$adminPassword --admin_email=$adminEmail
fi

# Confirm the site is setup
echo ""
echo -e "${VP_PURPLE}Your site is setup and WordPress is isntalled."
echo ""

# Setup SSL for valet
echo -e "${VP_PURPLE}Setting up an SSL cert for $dirName.app${VP_WHITE}"
echo ""
valet secure $dirName

# Final notice on everything being complete
echo ""
echo -e "${VP_GREEN}All done. You can access your local site here: https://$dirName.app"
echo ""
echo -e "${VP_WHITE}Exiting script."

exit 0