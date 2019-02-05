#!/bin/bash

# Styles
VP_NONE=$'\033[00m'
VP_RED=$'\033[01;31m'
VP_GREEN=$'\033[01;32m'
VP_YELLOW=$'\033[01;33m'
VP_PURPLE=$'\033[01;35m'
VP_CYAN=$'\033[01;36m'
VP_WHITE=$'\033[01;37m'
VP_BOLD=$'\033[1m'
VP_UNDERLINE=$'\033[4m'

# Setup some folder paths to variables
folderPath=$HOME/Sites/
dirName=${PWD##*/}
installPath=$folderPath/$dirName/
wpBoilerplate=$folderPath/wp-boilerplate/
themeFolder=$folderPath/$dirName/wp-content/themes
url="https://$dirName.app"

# Inform the user that this is assuming they're using Valet-plus
echo -e "${VP_CYAN}This bash script is under the assumption that you are using valet-plus to set up this WordPress install.${VP_NONE}"
echo -e "${VP_CYAN}${VP_BOLD}This script will now clear your terminal window."
echo "${VP_WHITE}${VP_NONE}"
read -p "${VP_WHITE}${VP_BOLD}Please press enter to continue.${VP_WHITE}${VP_NONE}" clearTerminal

clear && printf '\e[3J'

# We will now try to cache the sudo password, as we'll be setting up an SSL for their dev environment
echo -e "${VP_RED}${VP_BOLD}You may be asked twice for your password, but this is to setup an SSL locally to best mimic a live environment.${VP_WHITE}${VP_NONE}"
sudo -v
echo "${VP_WHITE}${VP_NONE}"

# Set the Site Name
read -p "${VP_WHITE}Enter the site name. ${VP_WHITE}${VP_NONE}" siteName
echo ""

read -p "${VP_WHITE}Enter a blog description (optional). ${VP_NONE}" blogDescription
echo ""

read -p "${VP_WHITE}Enter the theme folder name, ommiting -theme. ${VP_NONE}" themeName
echo ""

# Set the database name
echo -e "${VP_WHITE}Enter your chosen database name.${VP_NONE}"
read -p "${VP_RED}Note${VP_WHITE}:${VP_NONE} wp_ is automatically prefixed. ${VP_WHITE}${VP_NONE}" dbName
echo ""

# Get the database username
read -p "Enter your database user name if it differs from ${VP_YELLOW}root${VP_WHITE}${VP_NONE}, otherwise hit enter. ${VP_WHITE}${VP_NONE}" dbUser
echo ""

# Get the database password
read -p "Enter your database password if it differs from ${VP_YELLOW}root${VP_WHITE}${VP_NONE}, otherwise hit enter. ${VP_WHITE}${VP_NONE}" dbPassword
echo ""

# If a $dbUser was not entered, we'll default to valet-plus' mysql username
[ -z "$dbUser" ] && dbUser=root

# If a $dbUser was not entered, we'll default to valet-plus' mysql password
[ -z "$dbPassword" ] && dbPassword=root

# Fetch the latest files from the wp-boilerplate repo and then pull it
cd $wpBoilerplate
echo -e "Fetching and pulling the latest version of ${VP_CYAN}wp-boilerplate${VP_WHITE}${VP_NONE}"
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

# Creating the new wp-config file
echo -e "Creating database and setting up wp-config.php file.${VP_NONE}"
wp config create --dbname=wp_$dbName --dbuser=$dbUser --dbpass=$dbPassword --extra-php <<PHP
define( 'WP_DEBUG', true);
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
PHP

wp db create

# Check to see if there were any errors in creating the database
# We'll give the user 2 tries before we exit the script
if [ ! $? -eq 0 ]
then
    # Remove the old wp-config file
    rm -rf wp-config.php
    echo -e "${VP_RED}Error${VP_WHITE}: Either the database name already exists, the database username or password is incorrect, please double check.${VP_NONE}"
    
    # Get the database name - retry
    echo -e "Enter your chosen database name.${VP_NONE}"
    read -p "${VP_RED}Note${VP_WHITE}: wp_ is automatically prefixed. ${VP_NONE}" dbNameReTry
    echo ""

    # Get the database username - retry
    read -p "Enter your database user name if it differs from ${VP_YELLOW}root${VP_WHITE}, otherwise hit enter. ${VP_NONE}" dbUserRetry
    echo ""

    # Get the database password - retry
    read -p "Enter your database password if it differs from ${VP_YELLOW}root${VP_WHITE}, otherwise hit enter.${VP_NONE} " dbPasswordRetry

    # If a $dbUser was not entered, we'll default to valet-plus' mysql username
    [ -z "$dbUserRetry" ] && dbUserRetry=root

    # If a $dbUser was not entered, we'll default to valet-plus' mysql password
    [ -z "$dbPasswordRetry" ] && dbPasswordRetry=root

    wp config create --dbname=wp_$dbNameReTry --dbuser=$dbUserRetry --dbpass=$dbPasswordRetry --extra-php <<PHP
define( 'WP_DEBUG', true);
define( 'WP_DEBUG_LOG', true );å
define( 'WP_DEBUG_DISPLAY', false );
PHP
    wp db create
    
    if [ $? -eq 0 ]
    then
        echo -e "{$VP_RED}Please double check that either the database doesn't already exist, or the user name and password is correct.${VP_NONE}"
        echo -e "Exiting script.${VP_NONE}${VP_WHITE}"
        exit
    fi
    
fi

# With the database created, we'll need to now import our .sql file
echo -e "${VP_GREEN}Database created!${VP_WHITE}"
echo "${VP_NONE}"
echo -e "${VP_CYAN}Now updating URL's and importing the .sql file${VP_NONE}"
echo "${VP_NONE}"

wp db import import.sql
echo "${VP_NONE}"

# Check to see if there were any errors importing the database
# If so, we'll quit the script
if [ ! $? -eq 0 ]
then
    echo -e "${VP_RED}Opps, something went wrong with the database import."
    echo "${VP_NONE}"
    echo -e "${VP_WHITE}If you know what happened, please report the issue."
    exit 0
fi

# Ask to update to the latest version of WordPress
read -p "${VP_PURPLE}Update to the lates version of ${VP_YELLOW}WordPress [y/n] ${VP_WHITE}${VP_NONE} " updateWordPress

if [ "$updateWordPress" = 'y' ]
then
    # Update to the latest version of WordPress
    echo -e "Updating to the latest version of ${VP_PURPLE}WordPress${VP_WHITE}.${VP_NONE}"
    wp core update
fi

# Change the theme folder name
echo -e "Now changing the theme folder name from ${VP_CYAN}${VP_BOLD}sage9-project-name-theme${VP_NONE}${VP_WHITE} to ${VP_CYAN}${VP_BOLD}$themeName-theme${VP_NONE}${VP_WHITE}"
echo "${VP_NONE}"
mv $themeFolder/sage9-project-name-theme $themeFolder/$themeName-theme
echo -e "Folder name changed."

echo "${VP_NONE}"
echo -e "You can choose to create top level pages you know you'll need here, otherwise just hit enter to skip this.${VP_NONE}"
echo -e "Please separate page names with a comma (,) and no space. The ${VP_CYAN}Homepage${VP_WHITE} is already created.${VP_NONE}"
echo ""
read -p "${VP_CYAN}Example:${VP_WHITE} About Us,Contact Us,Blog ${VP_NONE} " pageList

# Do we want to disable comments?
read -p "${VP_YELLOW}Disable comments? [y/n]${VP_NONE}${VP_WHITE}${VP_NONE} " disableComments 

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
    echo -e "${VP_CYAN}Creating pages.${VP_NONE}${VP_WHITE}"
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
echo -e "${VP_CYAN}Updating the home and siteurl, and setting the blogname.${VP_NONE}${VP_WHITE}"
wp option update home $url
wp option update siteurl $url
wp option update blogname $siteName

if [ -n "$blogDescription" ]
then
    echo -e "${VP_CYAN}Setting the blogdescription.${VP_NONE}${VP_WHITE}"
    wp option update blogdescription $blogDescription
fi

# Set the homepage
echo -e "${VP_CYAN}Setting Homepage to front_page.${VP_NONE}${VP_WHITE}"
wp option update show_on_front 'page'
wp option update page_on_front 2

# Set the Timezone to Chicago
echo -e "${VP_CYAN}Changing timezone to Chicago.${VP_NONE}${VP_WHITE}"
wp option update timezone_string "America/Chicago"

# Replace the old http://wp-boilerplate.test:8080 with the sitename
echo -e "${VP_YELLOW}Replacing ${VP_UNDERLINE}${VP_WHITE}http://wp-boilerplate.test:8080${VP_NONE} ${VP_YELLOW}with ${VP_UNDERLINE}${VP_WHITE}$url${VP_NONE}"
wp search-replace 'http://wp-boilerplate.test:8080' $url --all-tables --quiet

# Save the permalinks
echo -e "${VP_CYAN}Flushing permalinks.${VP_NONE}${VP_WHITE}"
wp rewrite flush

# One last step with the database, let's optimize it
echo -e "${VP_CYAN}Optimizing database.${VP_NONE}${VP_WHITE}"
wp db optimize --quiet

# Update plugins
echo -e "${VP_GREEN}Updating plugins.${VP_WHITE}"
wp plugin update --all

# Activate the wp-accessibility plugin
echo -e "${VP_GREEN}Activating${VP_WHITE}: the WP-Accessibility Plugin. ${VP_WHITE}${VP_NONE}"
wp plugin activate wp-accessibility

# Ask if they want to install the Classic Editor
read -p "${VP_YELLOW}Install Classic Editor? [y/n]${VP_NONE}${VP_WHITE} " classicEditor

if [ "$classicEditor" = 'y' ]
then
    echo "${VP_CYAN}Installing and Activating the Classic Editor.${VP_WHITE}${VP_NONE}"
    wp plugin install classic-editor --activate
fi

# Ask if they want to activate any additional default plugins
read -p "${VP_YELLOW}Activate additional default plugins? [y/n]${VP_NONE}${VP_WHITE} " additionalPlugins

# Run through a couple of the common activated plugins they may want.
if [ "$additionalPlugins" = 'y' ]
then
    # Ask which of these plugins to activate
    read -p "${VP_YELLOW}Activate Gravity Forms? [y/n]${VP_WHITE}${VP_NONE} "  gravityForms
    read -p "${VP_YELLOW}Activate Sitemap? [y/n]${VP_WHITE}${VP_NONE} " sitemap
    read -p "${VP_YELLOW}Activate Yoast SEO? [y/n]${VP_WHITE}${VP_NONE} " yoastSEO

    # Activate Gravity Forms and WCAG Gravity Forms extension
    if [ "$gravityForms" = 'y' ]
    then
        echo "${VP_CYAN}Activating Gravity Forms and WCAG for Gravity Forms.${VP_WHITE}${VP_NONE}"
        wp plugin activate gravityforms
        wp plugin activate gravity-forms-wcag-20-form-fields
    fi
    
    # Activate Sitemap plugin, but may be replaced
    if [ "$sitemap" = 'y' ]
    then
        echo "${VP_CYAN}Activating Sitemap.${VP_WHITE}${VP_NONE}"
        wp plugin activate sitemap
    fi
    
    # Activate Yoast SEO and install ACF for Yoast
    if [ "$yoastSEO" = 'y' ]
    then
        echo "${VP_CYAN}Activating Yoast SEO and ACF Content Analysis for Yoast.${VP_WHITE}${VP_NONE}"
        wp plugin activate wordpress-seo
        wp plugin install acf-content-analysis-for-yoast-seo --activate
    fi

fi

# Clean up some root installation files
echo -e "Deleting ${VP_RED}${VP_BOLD}import.sql${VP_NONE}${VP_WHITE} and the ${VP_RED}${VP_BOLD}duplicator.zip${VP_NONE} files.${VP_WHITE}${VP_NONE}"
rm -rf ./*.zip
rm -rf import.sql
rm -rf CLIQUE-CHANGELOG.txt
rm -rf admin-creds-PLEASE-DELETE.txt

# Confirm the site is setup
echo ""
echo -e "${VP_YELLOW}Your site is setup and ${VP_BOLD}${VP_WHITE}WordPress${VP_NONE}${VP_YELLOW} is isntalled.${VP_WHITE}${VP_NONE}"
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