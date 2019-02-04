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

# Setup some folder paths to variables
folderPath=$HOME/Sites/
dirName=${PWD##*/}
installPath=$folderPath/$dirName/
wpBoilerplate=$folderPath/wp-boilerplate/
url="https://$dirName.app"

# Inform the user that this is assuming they're using Valet-plus
echo -e "${VP_CYAN}This bash script is under the assumption that you are using valet-plus to set up this WordPress install.${VP_NONE}"
echo -e "${VP_CYAN}${VP_BOLD}This script will now clear your terminal window.${VP_NONE}"
echo ""
echo -e "${VP_WHITE}${VP_BOLD}Please press enter to continue."
read clearTerminal

clear && printf '\e[3J'

# We will now try to cache the sudo password, as we'll be setting up an SSL for their dev environment
echo -e "${VP_RED}${VP_BOLD}You may be asked twice for your password, but this is to setup an SSL locally to best mimic a live environment.${VP_NONE}"
sudo -v

# Set the Site Name
echo -e "Enter the site name."
read siteName
echo ""

echo -e "Enter a blog description (optional)."
read $blogDescription
echo ""

# Set the database name
echo -e "Enter your chosen database name."
echo -e "${VP_CYAN}Note:${VP_WHITE} wp_ is automatically prefixed"
read dbName
echo ""

# Fetch the latest files from the wp-boilerplate repo and then pull it
cd $wpBoilerplate
git fetch --force
git pull --force

# With a fresh pull, copy the zip file into the new project folder and unzip the contents
cp -a ./*.zip $installPath
cd $installPath
unzip -q ./*.zip

# Copy the .sql file, and rename it
cp ./dup-installer/*.sql ./import.sql

# We want to remove the wp-config file here and create a new one
echo -e "${VP_RED}Deleting wp-config file and creating a new one.${VP_NONE}${VP_WHITE}"
rm -rf wp-config.php

echo -e "Creating database and setting up wp-config.php file."
wp config create --dbname=wp_$dbName --dbuser=root --dbpass=root --extra-php <<PHP
define( 'WP_DEBUG', true);
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
PHP

wp db create

# Check to see if there were any errors in creating the database
# We'll give the user 2 tries before we exit the script
if [ ! $? -eq 0 ]
then
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

# With the database created, we'll need to now import our .sql file
echo -e "${VP_GREEN}Database created!${VP_WHITE}"
echo ""
echo -e "${WP_YELLOW}Now updating URL's and importing the .sql file${VP_NONE}"

wp db import import.sql

# Check to see if there were any errors importing the database
# If so, we'll quit the script
if [ ! $? -eq 0 ]
then
    echo -e "${VP_RED}Opps, something went wrong with the database import."
    echo ""
    echo -e "${VP_WHITE}If you know what happened, please report the issue."
    exit 0
fi

echo -e "You can choose to create top level pages you know you'll need here, otherwise just hit enter to skip this."
echo -e "Please separate page names with a comma (,) and no space. The ${VP_CYAN}Homepage${VP_WHITE} is already created."
echo -e ""
echo -e "${VP_CYAN}Example:${VP_WHITE} About Us,Contact Us,Blog"
read pageList

# Do we want to disable comments?
echo -e "${VP_YELLOW}Disable comments? [y/n]${VP_NONE}${VP_WHITE}" 
read disableComments

# Lets remove the default "Hellow World" post
wp post delete 1 --force

# Let's remove the default WordPress comment
wp comment delete 1 --force

# If they want to disable comments, we'll also disable trackbacks and pings
if [ "$disableComments" = 'y' ]
then
    echo -e "${VP_YELLOW}Disabling Comments${VP_NONE}${VP_WHITE}"
    wp post list --format=ids | xargs wp post update --comment_status=closed
    echo -e "${VP_YELLOW}Disabling Trackbacks/Pings${VP_NONE}${VP_WHITE}"
    wp post list --format=ids | xargs wp post update --ping_status=closed
fi

# Now we'll update the "Sample Page" to "Home"
wp post update 2 --post_title="Home" --post_name="home" --post_type=page --post_status="publish" --post_content="" --post_excerpt=""

# If there's pages to create, let's create them
if [ -n "$pageList" ]
then
    IFS=","
    arr=($pageList)
    for i in "${!arr[@]}"
    do
        wp post create --post_title="${arr[i]}" --post_type=page --post_status="publish"
    done
    unset IFS
fi

# Option updates

# Execture a query to update the siteurl and home url
wp option update home $url
wp option update siteurl $url
wp option update blogname $siteName

if [ -n "$blogDescription" ]
then
    wp option update blogdescription $blogDescription
fi

# Set the homepage
wp option update show_on_front 'page'
wp option update page_on_front 2

# Replace the old http://wp-boilerplate.test:8080 with the sitename
echo -e "${VP_YELLOW}Replacing ${VP_UNDERLINE}${VP_WHITE}http://wp-boilerplate.test:8080${VP_NONE} ${VP_YELLOW}with ${VP_UNDERLINE}${VP_WHITE}$url${VP_NONE}"
wp search-replace 'http://wp-boilerplate.test:8080' $url --all-tables --quiet

# Save the permalinks
wp rewrite flush

# One last step with the database, let's optimize it
wp db optimize --quiet

# Clean up some root installation files
echo -e "${VP_RED}Deleting ${VP_BOLD}import.sql${VP_NONE} and the ${VP_BOLD}duplicator.zip${VP_NONE} files.${VP_WHITE}"
rm -rf ./*.zip
rm -rf import.sql
rm -rf CLIQUE-CHANGELOG.txt
rm -rf admin-creds-PLEASE-DELETE.txt

# Confirm the site is setup
echo ""
echo -e "${VP_YELLOW}Your site is setup and ${VP_BOLD}${VP_WHITE}WordPress${VP_NONE}${VP_YELLOW} is isntalled."
echo ""

# Setup SSL for valet
echo -e "Setting up an SSL cert for ${VP_UNDERLINE}${VP_WHITE}$url${VP_NONE}"
echo ""
valet secure $dirName

# Final notice on everything being complete
echo ""
echo -e "${VP_GREEN}All done. You can access your site and login."
echo ""
echo -e "${VP_GREEN}Front End${VP_WHITE}: ${VP_UNDERLINE}$url${VP_NONE}"
echo -e "${VP_GREEN}Back End${VP_WHITE}: ${VP_UNDERLINE}$url/wp-admin${VP_NONE}"
echo -e "${VP_GREEN}Username:${VP_WHITE} admin"
echo -e "${VP_GREEN}Password:${VP_WHITE} Cl!que2019"
echo ""
echo -e "${VP_RED}Due to the copied files being generated from a duplicator package, you will need to head here to clean up any files. ${VP_UNDERLINE}${VP_WHITE}$url/wp-admin/admin.php?page=duplicator-tools&tab=diagnostics${VP_NONE}${VP_WHITE}"
echo -e "${VP_GREEN}Exiting script.${VP_NONE}${VP_WHITE}"

exit 0