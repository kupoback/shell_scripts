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
folderPath="${HOME}/Sites/"
dirName="${PWD##*/}"
installPath="${folderPath}/${dirName}/"
wpBoilerplate="${folderPath}/wp-boilerplate/"
themeFolder="${folderPath}/${dirName}/wp-content/themes/"
url="https://${dirName}.app"

# Inform the user that this is assuming they're using Valet-plus
echo -e "${VP_CYAN}This bash script is under the assumption that you are using valet-plus to set up this WordPress install.
${VP_CYAN}${VP_BOLD}This script will now clear your terminal window.
${VP_WHITE}

${VP_WHITE}${VP_BOLD}Please press enter to continue.${VP_WHITE}"
read -r

clear && printf '\e[3J'

# We will now try to cache the sudo password, as we'll be setting up an SSL for their dev environment
echo -e "${VP_RED}${VP_BOLD}You may be asked twice for your password, but this is to setup an SSL locally to best mimic a live environment.${VP_NONE}"
sudo -v

# Grab the Site Name
read -p "${VP_WHITE}Enter the site name: ${VP_NONE}" siteName

# Grab the Blog Description
echo -e "\\n${VP_WHITE}Enter a blog description (optional):${VP_NONE}" 
read -r blogDescription

# Grab the theme folder name
read -p $'\n'"${VP_WHITE}Enter the theme folder name, ommiting -theme${VP_NONE}: " themeName


# Grab the database name
echo -e "\\n${VP_WHITE}Enter your chosen database name.

${VP_RED}Note${VP_WHITE}: wp_ is automatically prefixed.${VP_NONE}"
read -r dbName

# Grab the database username
read -p $'\n'"${VP_WHITE}Enter your database user name if it differs from \"${VP_YELLOW}root${VP_WHITE}\", otherwise hit enter.${VP_NONE} " dbUser

# Grab the database password
read -p "${VP_WHITE}Enter your database password if it differs from \"${VP_YELLOW}root${VP_WHITE}\", otherwise hit enter.${VP_NONE} " dbPassword

# If a $dbUser was not entered, we'll default to valet-plus' mysql username
[ -z "${dbUser}" ] && dbUser=root

# If a $dbUser was not entered, we'll default to valet-plus' mysql password
[ -z "${dbPassword}" ] && dbPassword=root

# Fetch the latest files from the wp-boilerplate repo and then pull it
cd "${wpBoilerplate}" || exit 1

echo -e "\\n${VP_WHITE}Fetching and pulling the latest version of ${VP_CYAN}wp-boilerplate${VP_WHITE}${VP_NONE}"
git fetch --force
git pull --force

# With a fresh pull, copy the zip file into the new project folder and unzip the contents
cp -a ./*.zip "${installPath}"/
cd "${installPath}" || exit 1
unzip -q ./*.zip

# Copy the .sql file, and rename it
cp ./dup-installer/*.sql ./import.sql

# We want to remove the wp-config file here and create a new one
echo -e "\\n${VP_RED}Deleting wp-config file and creating a new one.${VP_WHITE}${VP_NONE}"
rm -rf wp-config.php

# Creating the new wp-config file
echo -e "\\n${VP_WHITE}Creating database and setting up wp-config.php file.${VP_NONE}"
wp config create --dbname=wp_"${dbName}" --dbuser="${dbUser}" --dbpass="${dbPassword}"

wp db create

# Check to see if there were any errors in creating the database
# We'll give the user 2 tries before we exit the script
if [ ! $? -eq 0 ]
then
    # Remove the old wp-config file
    rm -rf wp-config.php

    # Let's try re-try the database name, login and password
    echo -e "\\n${VP_RED}Error${VP_WHITE}: Either the database name already exists, the database username or password is incorrect, please double check.
    
    Enter your chosen database name.
    
    ${VP_RED}Note${VP_WHITE}: wp_ is automatically prefixed.${VP_NONE}" 
     read -r dbNameReTry

    # Get the database username - retry
    read -p $'\n'"${VP_WHITE}Enter your database user name if it differs from ${VP_YELLOW}root${VP_WHITE}, otherwise hit enter${VP_NONE}: " dbUserRetry
 
    # Get the database password - retry
    read -p $'\n'"${VP_WHITE}Enter your database password if it differs from ${VP_YELLOW}root${VP_WHITE}, otherwise hit enter:${VP_NONE} " dbPasswordRetry 

    # If a $dbUser was not entered, we'll default to valet-plus' mysql username
    [ -z "${dbUserRetry}" ] && dbUserRetry=root

    # If a $dbUser was not entered, we'll default to valet-plus' mysql password
    [ -z "${dbPasswordRetry}" ] && dbPasswordRetry=root

    # Create the wp-config file again
    wp config create --dbname=wp_"${dbNameReTry}" --dbuser="${dbUserRetry}" --dbpass="${dbPasswordRetry}"

    # Try to create the database again
    wp db create
    
    if [ ! $? -eq 0 ]
    then
        echo -e "\\n{$VP_RED}Please double check that either the database doesn't already exist, or the user name and password is correct.
        
        ${VP_WHITE}Exiting script.${VP_NONE}"

        exit 1
    fi
    
fi

# With the database created, we'll need to now import our .sql file
echo -e "\\n${VP_GREEN}Database created!${VP_WHITE}

${VP_CYAN}Now importing the .sql file.${VP_NONE}"

wp db import import.sql

# Check to see if there were any errors importing the database
# If so, we'll quit the script
if [ ! $? -eq 0 ]
then
    echo -e "\\n${VP_RED}Opps, something went wrong with the database import.
    
    ${VP_WHITE}If you know what happened, please report the issue.${VP_NONE}"
    
    exit 1
fi

# Ask to update to the latest version of WordPress
read -p $'\n'"${VP_PURPLE}Update to the lates version of ${VP_YELLOW}WordPress [y/n]${VP_WHITE}${VP_NONE} " updateWordPress

if [[ "${updateWordPress}" == "y" ]]
then
    # Update to the latest version of WordPress
    echo -e "\\nUpdating to the latest version of ${VP_PURPLE}WordPress${VP_WHITE}.${VP_NONE}"
    wp core update
fi

# Change the theme folder name
echo -e "\\n${VP_WHITE}Now changing the theme folder name from ${VP_CYAN}${VP_BOLD}sage9-project-name-theme${VP_WHITE}${VP_NONE} to ${VP_CYAN}${VP_BOLD}${themeName}-theme${VP_WHITE}${VP_NONE}"

mv $themeFolder/sage9-project-name-theme $themeFolder/$themeName-theme

echo -e "\\n${VP_WHITE}Folder name changed.

You can choose to create top level pages you know you'll need here, otherwise just hit enter to skip this.

Please separate page names with a comma (,) and no space. The ${VP_CYAN}Homepage${VP_WHITE} is already created.

${VP_CYAN}Example:${VP_WHITE} About Us,Contact Us,Blog ${VP_NONE} "
read -r pageList

# Lets remove the default "Hellow World" post
echo -e "Removing \"Hello World\" post."
wp post delete 1 --force

# Let's remove the default WordPress comment
# echo -e "\\nDeleting default example comment."
# wp comment delete 1 --force

# Do we want to disable comments?
read -p $'\n'"${VP_YELLOW}Disable comments? [y/n]${VP_WHITE}${VP_NONE} " disableComments

# If they want to disable comments, we'll also disable trackbacks and pings
if [[ "${disableComments}" == "y" ]]
then
    # Disabling Comments
    echo -e "\\n${VP_YELLOW}Disabling Comments${VP_WHITE}${VP_NONE}"
    wp post list --format=ids | xargs wp post update --comment_status=closed
    
    # Disabling Trackbacks/Pings
    echo -e "\\n${VP_YELLOW}Disabling Trackbacks/Pings${VP_WHITE}${VP_NONE}"
    wp post list --format=ids | xargs wp post update --ping_status=closed
fi

# Now we'll update the "Sample Page" to "Home"
echo -e "\\nChanging \"Sample Page\" to \"Home\"."
wp post update 2 --post_title=Home --post_name=home --post_type=page --post_status=publish --post_content= --post_excerpt=

# If there's pages to create, let's create them
if [[ -n "${pageList}" ]]
then
    echo -e "\\n${VP_CYAN}Creating pages.${VP_WHITE}${VP_NONE}"
    IFS=","
    arr=("${pageList}")
    for i in "${!arr[@]}"
    do
        wp post create --post_title="${arr[i]}" --post_type=page --post_status="publish"
    done
    unset IFS
fi

# Option updates

# Execture a query to update the siteurl and home url
echo -e "\\n${VP_CYAN}Updating the home and siteurl, and setting the blogname.${VP_WHITE}${VP_NONE}"
wp option update home "${url}"
wp option update siteurl "${url}"
wp option update blogname "${siteName}"

if [[ -n "${blogDescription}" ]]
then
    echo -e "\\n${VP_CYAN}Setting the blogdescription.${VP_WHITE}${VP_NONE}"
    wp option update blogdescription "${blogDescription}"
fi

# Set the homepage
echo -e "\\n${VP_CYAN}Setting Homepage to front_page.${VP_WHITE}${VP_NONE}"
wp option update show_on_front 'page'
wp option update page_on_front 2

# Set the Timezone to Chicago
echo -e "\\n${VP_CYAN}Changing timezone to Chicago.${VP_WHITE}${VP_NONE}"
wp option update timezone_string "America/Chicago"

# Replace the old http://wp-boilerplate.test:8080 with the sitename
echo -e "\\n${VP_YELLOW}Replacing ${VP_UNDERLINE}${VP_WHITE}http://wp-boilerplate.test:8080${VP_NONE} ${VP_YELLOW}with ${VP_UNDERLINE}${VP_WHITE}${url}${VP_NONE}"
wp search-replace 'http://wp-boilerplate.test:8080' "${url}" --all-tables --quiet

# Save the permalinks
echo -e "\\n${VP_CYAN}Flushing permalinks.${VP_WHITE}${VP_NONE}"
wp rewrite flush

# One last step with the database, let's optimize it
echo -e "\\n${VP_CYAN}Optimizing database.${VP_WHITE}${VP_NONE}"
wp db optimize --quiet

# Update plugins
echo -e "\\n${VP_GREEN}Updating plugins.${VP_WHITE}"
wp plugin update --all

# Activate the wp-accessibility plugin
echo -e "\\n${VP_GREEN}Activating${VP_WHITE}: the WP-Accessibility Plugin. ${VP_WHITE}${VP_NONE}"
wp plugin activate wp-accessibility

# Ask if they want to install the Classic Editor
read -p $'\n'"${VP_YELLOW}Install Classic Editor? [y/n]${VP_WHITE}${VP_NONE} " classicEditor

if [[ "${classicEditor}" == "y" ]]
then
    echo -e "\\n${VP_CYAN}Installing and Activating the Classic Editor.${VP_WHITE}${VP_NONE}"
    wp plugin install classic-editor --activate
fi

# Ask if they want to activate any additional default plugins
read -p $'\n'"${VP_YELLOW}Activate additional default plugins? [y/n]${VP_WHITE}${VP_NONE} " additionalPlugins

# Run through a couple of the common activated plugins they may want.
if [[ "${additionalPlugins}" == "y" ]]
then
    # Ask which of these plugins to activate
    # There is currently an issue with gravity forms.
    # read -p $'\n'"${VP_YELLOW}Activate Gravity Forms? [y/n]${VP_WHITE}${VP_NONE} " gravityForms
     
    read -p $'\n'"${VP_YELLOW}Activate Sitemap? [y/n]${VP_WHITE}${VP_NONE} " siteMap
    
    read -p $'\n'"${VP_YELLOW}Activate Yoast SEO? [y/n]${VP_WHITE}${VP_NONE} " yoastSEO

    # Activate Gravity Forms and WCAG Gravity Forms extension
    # if [[ "${gravityForms}" == "y" ]]
    # then
    #     echo -e "\\n${VP_CYAN}Activating Gravity Forms and WCAG for Gravity Forms.${VP_WHITE}${VP_NONE}"
    #     wp plugin activate gravityforms
    #     wp plugin activate gravity-forms-wcag-20-form-fields
    # fi
    
    # Activate Sitemap plugin, but may be replaced
    if [ "${siteMap}" == "y" ]
    then
        echo -e "\\n${VP_CYAN}Activating Sitemap.${VP_WHITE}${VP_NONE}"
        wp plugin activate sitemap
    fi
    
    # Activate Yoast SEO and install ACF for Yoast
    if [ "${yoastSEO}" == "y" ]
    then
        echo -e "\\n${VP_CYAN}Activating Yoast SEO and ACF Content Analysis for Yoast.${VP_WHITE}${VP_NONE}"
        wp plugin activate wordpress-seo
        wp plugin install acf-content-analysis-for-yoast-seo --activate
    fi

fi

# Clean up some root installation files
echo -e "\\n${VP_WHITE}Deleting ${VP_RED}${VP_BOLD}import.sql${VP_NONE}${VP_WHITE} and the ${VP_RED}${VP_BOLD}duplicator.zip${VP_NONE}${VP_WHITE} files.${VP_WHITE}${VP_NONE}"
rm -rf ./*.zip import.sql CLIQUE-CHANGELOG.txt admin-creds-PLEASE-DELETE.txt

# Confirm the site is setup
echo -e "\\n${VP_GREEN}Your site is setup and ${VP_BOLD}${VP_WHITE}WordPress${VP_NONE}${VP_GREEN} is installed.${VP_WHITE}${VP_NONE}"

# Setup SSL for valet
echo -e "\\nSetting up an SSL cert for ${VP_UNDERLINE}${VP_WHITE}${url}${VP_NONE}\\n"
valet secure "${dirName}"

# Final notice on everything being complete
echo -e "

${VP_GREEN}All done. You can access your site and login.

${VP_GREEN}Front End${VP_WHITE}: ${VP_UNDERLINE}${url}${VP_NONE}
${VP_GREEN}Back End${VP_WHITE}: ${VP_UNDERLINE}${url}/wp-admin${VP_NONE}

${VP_WHITE}Login Credentials${VP_NONE}
${VP_GREEN}Username:${VP_WHITE}${VP_BOLD} admin${VP_NONE}
${VP_GREEN}Password:${VP_WHITE}${VP_BOLD} Cl!que2019${VP_NONE}

${VP_RED}Due to the copied files being generated from a duplicator package, you will need to head here to clean up any files. ${VP_UNDERLINE}${VP_WHITE}${url}/wp-admin/admin.php?page=duplicator-tools&tab=diagnostics

${VP_GREEN}Exiting script.${VP_WHITE}${VP_NONE}"

exit 1