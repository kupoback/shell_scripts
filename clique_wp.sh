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

folderPath=$HOME/Sites/
dirName=${PWD##*/}
installPath=$folderPath/$dirName/
wpBoilerplate=$folderPath/wp-boilerplate/

# Inform the user that this is assuming they're using Valet-plus
echo -e "${VP_CYAN}This bash script is under the assumption that you are using valet-plus to set up this WordPress install.${VP_NONE}"
echo -e "${VP_CYAN}${VP_BOLD}This script will now clear your terminal window.${VP_NONE}"
echo ""
echo -e "${VP_WHITE}${VP_BOLD}Please press enter to continue."
read clearTerminal
clear

# We will now try to cache the sudo password, as we'll be setting up an SSL for their dev environment
# echo -e "${VP_RED}${VP_BOLD}You may be asked twice for your password, but this is to setup an SSL locally to best mimic a live environment.${VP_NONE}"
# sudo -v

# Set the Site Name
echo -e "Enter the site name."
read siteName
echo ""

# Set the database name
echo -e "Enter your chosen database name."
echo -e "${VP_WHITE}Note, wp_ is automatically prefixed"
read dbName
echo ""

# Go to the wp-boilerplate repoisotry and using git, we'll fetch from the repo and make sure we're pulling the latest files
cd $wpBoilerplate
git fetch --force
git pull --force

# Since we're in the folder and have the latest files, we're going to copy the .zip file to our install folder
cp -a ./*.zip $installPath

# Heading back into our folder, we'll unpack the .zip file
cd $installPath
unzip ./*.zip

# Next we'll copy the .sql file, and rename it.
cp ./dup-installer/*.sql ./import.sql

# Now that we have our files and the database with an acceptable import name, we'll now setup the database and create a new wp-config file


# # Confirm the site is setup
# echo ""
# echo -e "${VP_PURPLE}Your site is setup and WordPress is isntalled."
# echo ""

# # Setup SSL for valet
# echo -e "${VP_PURPLE}Setting up an SSL cert for $dirName.app${VP_WHITE}"
# echo ""
# valet secure $dirName

# # Final notice on everything being complete
# echo ""
# echo -e "${VP_GREEN}All done. You can access your local site here: https://$dirName.app"
# echo ""
# echo -e "${VP_WHITE}Exiting script."

exit 0
