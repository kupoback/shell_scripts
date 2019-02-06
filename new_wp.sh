#!/bin/bash

# Styles
VP_NONE='\033[00m'
VP_RED='\033[01;31m'
VP_GREEN='\033[01;32m'
#VP_YELLOW='\033[01;33m'
VP_PURPLE='\033[01;35m'
VP_CYAN='\033[01;36m'
VP_WHITE='\033[01;37m'
VP_BOLD='\033[1m'
#VP_UNDERLINE='\033[4m'

dirName=${PWD##*/}

# Forwarn part 1
if [[ ! -d ./.git ]]
then
    echo -e "\\n${VP_RED}This script runs under the assumption that you've cloned a repository down."
    echo -e "\\nExiting script.${VP_NONE}${VP_WHITE}\\n"
    exit 1
fi

# Inform the user that this is assuming they're using Valet-plus
echo -e "\\n${VP_CYAN}This bash script is under the assumption that you are using valet-plus to set up this WordPress install.${VP_NONE}"
echo -e "${VP_CYAN}${VP_BOLD}This script will now clear your terminal window.${VP_NONE}\\n"
echo -e "${VP_WHITE}${VP_BOLD}Please press enter to continue."
read -r
clear

# We will now try to cache the sudo password, as we'll be setting up an SSL for their dev environment
echo -e "${VP_RED}${VP_BOLD}You may be asked twice for your password, but this is to setup an SSL locally to best mimic a live environment.${VP_NONE}"
sudo -v

# Set the site name
echo -e "Enter the site name."
read -r siteName
echo

# Set the database name
echo -e "Enter your chosen database name."
echo -e "${VP_WHITE}Note, wp_ is automatically prefixed"
read -r dbName
echo

echo -e "Enter your database user name if it differs from root, otherwise hit enter."
read -r dbUser
echo

echo -e "Enter your database password if it differs from root, otherwise hit enter."
read -r dbPassword
echo

# If a $dbUser was not entered, we'll default to valet-plus' mysql username
if [[ -z "${dbUser}" ]] ; then dbUser="root" ; fi

# If a $dbUser was not entered, we'll default to valet-plus' mysql password
if [[ -z "${dbPassword}" ]] ; then dbPassword="root" ; fi

# Let's double check the WordPress version they want to download
echo -e "${VP_PURPLE}If you'd like to download a different version number, please enter in the number, otherwise, just press enter.${VP_WHITE}"
read -r wpVersion
echo

# Start downloading WordPress and its latest version
if [[ -z "${wpVersion}" ]]
then
    wp core download
else
    wp core download --version="${wpVersion}"
fi

# Create the wp-config file and the database
echo -e "${VP_PURPLE}Creating database and setting up wp-config.php file.${VP_WHITE}"
wp config create --dbname=wp_"${dbName}" --dbuser=root --dbpass=root --extra-php <<PHP
define( 'WP_DEBUG', true);
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
PHP

if wp db create
then
    echo -e "All set.${VP_WHITE}"
else
    rm -rf wp-config.php
    echo -e "${VP_RED}Database 'wp_${dbName}' exists. Please enter another db name."

    echo -e "\\nEnter your chosen database name."
    echo -e "${VP_WHITE}Note, wp_ is automatically prefixed"
    read -r dbName
    echo

    wp config create --dbname=wp_"${dbName}" --dbuser=root --dbpass=root --force --extra-php <<PHP
define( 'WP_DEBUG', true);
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
PHP
    if wp db create
    then
        echo -e "{$VP_RED}Please double check that this database doesn't exists in your mysql."
        echo -e "${VP_WHITE}Exiting script.${VP_NONE}${VP_WHITE}"
        exit
    fi
fi

# Set the admin
echo -e "Please enter in a username."
read -r adminUser

# Set admin password
echo -e "\\nPlease enter in a password."
read -r adminPassword

# Set the admin email
echo -e "\\nPlease enter in the admin email."
read -r adminEmail

# Beginning of site build
if wp core install --url="${dirName}.app" --title="${siteName}.app" --admin_user="${adminUser}" --admin_password="${adminPassword}" --admin_email="${adminEmail}"
then
    echo -e "${VP_RED}You have some errors. Please check your errors.${VP_WHITE}"

    # Set the admin
    echo -e "Please enter in a username."
    read -r adminUser

    # Set admin password
    echo -e "Please enter in a password."
    read -r adminPassword

    # Set the admin email
    echo -e "Please enter in the admin email."
    read -r adminEmail

    # Beginning of site build
    wp core install --url="${dirName}.app" --title="${dirName}.app" --admin_user="${adminUser}" --admin_password="${adminPassword}" --admin_email="${adminEmail}"
fi

# Confirm the site is setup
echo -e "\\n${VP_PURPLE}Your site is setup and WordPress is isntalled.\\n"

# Setup SSL for valet
echo -e "${VP_PURPLE}Setting up an SSL cert for ${dirName}.app${VP_WHITE}\\n"
valet secure "${dirName}"

# Final notice on everything being complete
echo -e "\\n${VP_GREEN}All done. You can access your local site here: https://${dirName}.app"
echo -e "\\n${VP_WHITE}Exiting script."

exit 0
