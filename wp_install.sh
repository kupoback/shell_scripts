#!/usr/bin/env bash

# change to script directory
#cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# USAGE
usage () { echo -e "
USAGE: ${0} [OPTIONS]\\n
OPTIONS:\\n
-m   (optional)   Monochrome output colors
-q   (optional)   Suppress informational messages
-h                Display this usage information\\n
" ; }

# OPTIONS
while getopts "mqh" opt ; do
    case "${opt}" in
        m) monochrome="yes" ;;
        q) quiet="yes" ;;
        h) usage ; exit 0 ;;
        *) usage ; exit 1 ;;
    esac
done

# COMMON VARIABLES & FUNCTIONS
# colors
if [[ -n "${monochrome}" ]] ; then
    ink_clear="\\x1b[0m"
    ink_gray="\\x1b[38;5;244m"
    ink_red="\\x1b[0m"
    ink_green="\\x1b[0m"
    ink_blue="\\x1b[0m"
    ink_yellow="\\x1b[0m"
    ink_purple="\\x1b[0m"
else
    ink_clear="\\x1b[0m"
    ink_gray="\\x1b[38;5;244m"
    ink_red="\\x1b[38;5;204m"
    ink_green="\\x1b[38;5;120m"
    ink_blue="\\x1b[38;5;081m"
    ink_yellow="\\x1b[38;5;228m"
    ink_purple="\\x1b[38;5;207m"
fi

# output
yes_no="${ink_blue}[${ink_clear} ${ink_green}yes${ink_clear} ${ink_blue}/${ink_clear} ${ink_red}no${ink_clear} ${ink_blue}]${ink_clear}"
nl      () { if [[ -z "${quiet}" ]] ; then echo ; fi ; }
say     () { if [[ -z "${quiet}" ]] ; then echo -e "\\n${ink_gray}${1}${ink_clear}" ; fi ; }
tinysay () { if [[ -z "${quiet}" ]] ; then echo -e "${ink_gray}${1}${ink_clear}" ; fi ; }
errsay  () { echo -e "\\n${ink_red}${1}. Script aborted!${ink_clear}" ; }
err     () { echo -e "\\n${ink_red}${1}${ink_clear}" ; }
tinyerr () { echo -e "${ink_red}${1}${ink_clear}" ; }
ask     () { echo -en "\\n${ink_gray}${1} ${ink_clear}" ; }
askinfo () { echo -en "${ink_gray}${1} ${ink_clear}" ; read -r "${2}" ; }

# confirm
confirm () {
    ask "${1}"
    read -r INPUT
    case "${INPUT}" in
        [yY][eE][sS] | [yY]) ;;
        [nN][oO] | [nN]) say "Script aborted.\\n" && exit 0 ;;
        *) confirm "${1}" ;;
    esac
}

# PRE-FLIGHT CHECKS
#if [[ ! -d ./.git ]] ; then errsay "No cloned repository found" ; exit 1 ; fi

# VARIABLES
dirName=${PWD##*/}

# FUNCTIONS
initiate_env_setup () {
    
    if ! type wp >/dev/null 2>&1 && ! type valet >/dev/null 2>&1; then
        err "${ink_red}This script requires the installation of wp-cli and valet or valet plus"
        tinyerr "You can install ${ink_blue}wp-cli${ink_red} using Homebrew or by visiting ${ink_purple}https://wp-cli.org"
        tinyerr "You can install ${ink_blue}valet${ink_red} from ${ink_purple}https://laravel.com/docs/master/valet"
        tinyerr "OR"
        tinyerr "You can install ${ink_blue}valet-plus${ink_red} from ${ink_purple}https://github.com/weprovide/valet-plus"
        say "Exiting script\\n" && exit 0
    fi

    say "This script is under the assumption that you're using ${ink_blue}valet-plus${ink_gray} to setup this WordPress environment."
    confirm "Would you like to continue? ${yes_no}"
    clear
    tinysay "Starting new WordPress environment setup ..."
    
}

cache_sudo_password () {
    
    say "Please enter your local user password."
    sudo -k ; sudo -v && tinysay "${ink_blue}OK"
    
}

collect_environment_information () {

    say "Please provide the necessary information for the new environment:"
    nl
    askinfo "Site name:" siteName
    askinfo "Enter your TLS: " domainTLS
    askinfo "Install SSL (default: yes): ${yes_no}" addSSL
    askinfo "WordPress version (default: latest):" wpVersion
    askinfo "Database name (wp_ will be prefixed):" dbName
    askinfo "Database user name (default: root):" dbUserName
    askinfo "Database user pass (default: root):" dbUserPass
    askinfo "Admin user name:" adminUserName
    askinfo "Admin user pass:" adminUserPass
    askinfo "Admin user email:" adminUserEmail
    askinfo "Install Blank Site (default: no): ${yes_no}" blankInstall
    askinfo "Disable Comments (default: no): ${yes_no}" disableComments
    askinfo "Disable Trackbacks (default: no): ${yes_no}" disableTrackbacks
    askinfo "Create additional pages? ${yes_no}" createPages

    sslURL="https://${PWD##*/}.${domainTLS}"
    nonSSLURL="http://${PWD##*/}.${domainTLS}"
    
    # setting defaults if values were omitted
    if [[ -z "${domainTLS}" ]] ; then tinysay "You must enter a TLS. Exiting script\\n" && exit 0 ; fi
    if [[ -z "${addSSL}" ]] ; then addSSL="yes" ; fi
    if [[ -z "${wpVersion}" ]] ; then wpVersion="latest" ; fi
    if [[ -z "${dbUserName}" ]] ; then dbUserName="root" ; fi
    if [[ -z "${dbUserPass}" ]] ; then dbUserPass="root" ; fi
    if [[ -z "${disableComments}" ]] ; then disableComments="no" ; fi
    if [[ -z "${disableTrackbacks}" ]] ; then disableTrackbacks="no" ; fi
    if [[ -z "${blankInstall}" ]] ; then blankInstall="no" ; fi
    if [[ "${createPages}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then create_pages ; fi
    
    say "The ${ink_yellow}new environment${ink_gray} will be created with the following information:"
    nl
    tinysay "Site name:          ${ink_yellow}${siteName}"
    if [[ "${addSSL}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then
        tinysay "URL:                ${ink_yellow}${sslURL}"
    else
        tinysay "URL:                ${ink_yellow}${nonSSLURL}"
    fi
    tinysay "WordPress version:  ${ink_yellow}${wpVersion}"
    tinysay "Database name:      ${ink_yellow}wp_${dbName}"
    tinysay "Database user name: ${ink_yellow}${dbUserName}"
    tinysay "Database user pass: ${ink_yellow}${dbUserPass}"
    tinysay "Admin user name:    ${ink_yellow}${adminUserName}"
    tinysay "Admin user pass:    ${ink_yellow}${adminUserPass}"
    tinysay "Admin user email:   ${ink_yellow}${adminUserEmail}"
    if [[ "${createPages}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then
        tinysay "Creating pages:     ${ink_yellow}${pageList}"
    fi
    
    confirm "Would you like to continue? ${yes_no}"
    
}

download_wordpress () {
    
    say "Downloading WordPress ..."
    if [[ "${wpVersion}" == "latest" ]] ; then
        if [[ "${blankInstall}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then
            if ! wp core download --skip-content ; then
                errsay "Error during WordPress download" ; exit 1
            fi
        else
            if ! wp core download ; then
                errsay "Error during WordPress download" ; exit 1
            fi
        fi
    else
        if [[ "${blankInstall}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then
            if ! wp core download --version="${wpVersion}" --skip-content; then
                errsay "Error during WordPress download" ; exit 1
            fi
        else 
            if ! wp core download --version="${wpVersion}" ; then
                errsay "Error during WordPress download" ; exit 1
            fi
        fi
    fi
    
}

create_wp_config () {
    
    say "Creating WordPress configuration file (wp-config.php) ..."
    rm -rf wp-config.php
    if ! wp config create --dbname=wp_"${dbName}" --dbuser="${dbUserName}" --dbpass="${dbUserPass}"
    then errsay "Error during creation of wp-config.php" ; exit 1 ; fi
    
}

create_wp_database () {
    
    say "Creating WordPress database ..."
    if ! wp db create ; then
        errsay "Error during database creation" ; exit 1
    fi
    
}

build_wp_site () {
    
    say "Building WordPress site ..."
    if ! wp core install --url="${dirName}.app" --title="${siteName}" --admin_user="${adminUserName}" --admin_password="${adminUserPass}" --admin_email="${adminUserEmail}" ; then
        errsay "Error during building of site" ; exit 1
    fi

    tinysay "Changing ${ink_yellow}\"Sampe Page\"${ink_gray} to ${ink_yellow}\"Home\"${ink_gray}"
    wp post update 2 --post_title=Home --post_name=home --post_type=page --post_status=publish --post_content= --post_excerpt=

    tinysay "Setting \"Home\" as the Front Page"
    wp option update show_on_front 'page'
    wp option update page_on_front 2

    tinysay "Changing timezone to Chicago"
    wp option update timezone_string "America/Chicago"

    if [[ "${disableComments}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then disable_comments ; fi
    if [[ "${disableTrackbacks}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then disable_tackbacks ; fi
    if [[ "${createPages}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then loop_create_pages ; fi
    
    tinysay "Flushing permalinks"
    wp cache flush
    wp rewrite structure /%postname%/
    wp rewrite flush

}


enable_tls_for_env () {
    
    if [[ "${addSSL}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then
        say "Enabling TLS for site ..."
        if ! valet secure "${dirName}" ; then
            errsay "Error while securing site"
        fi
    fi

}

setup_complete() {
    say "Environment sucessfully setup."
    tinysay "You may now sign in to your website."
    nl
    if [[ "${addSSL}" =~ ^([yY][eE][sS]|[yY])+ ]] ; then
        tinysay "Front End URL:         ${ink_yellow}${sslURL}" 
        tinysay "Back End URL:          ${ink_yellow}${sslURL}/wp-admin"
    else
        tinysay "Front End URL:         ${ink_yellow}${nonSSLURL}" 
        tinysay "Back End URL:          ${ink_yellow}${nonSSLURL}/wp-admin"
    fi
    nl
    tinysay "Login Credentials"
    tinysay "Admin User Name:       ${ink_yellow}${adminUserName}"
    tinysay "Admin User Password:   ${ink_yellow}${adminUserPass}"
}

# Conditional Functions
create_pages() {
    say "You can choose to create top level pages you know you'll need here, otherwise just hit enter to skip this."
    say "Please separate page names with a semicolon (;) with no space after it. The ${VP_CYAN}Homepage${VP_WHITE} is already created."
    say "${VP_CYAN}Example:${VP_WHITE} About Us;Contact Us;Blog ${VP_NONE}"
    nl
    read -r pageList
}

loop_create_pages() {

    if [[ -n "${pageList}" || "${pageList}" != *"," ]] ;
    then
        tinysay "Creating pages…"
        IFS=";" 
        for i in ${pageList}
        do
            wp post create --post_title="${i}" --post_type=page --post_status="publish"
        done
        unset IFS
        tinysay "Pages created."
    fi
}

disable_comments() {
    tinysay "Disabling Comments…"
    wp post list --format=ids | xargs wp post update --comment_status=closed
    wp option update default_comment_status "closed"
}

disable_tackbacks() {
    tinysay "Disabling Trackbacks…"
    wp post list --format=ids | xargs wp post update --ping_status=closed
    wp option update default_ping_status "closed"
    wp option update default_pingback_flag 0
}

# MAIN
initiate_env_setup
cache_sudo_password
collect_environment_information
download_wordpress
create_wp_config
create_wp_database
build_wp_site
enable_tls_for_env
setup_complete