#!/usr/bin/env bash

# change to script directory
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

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
ask     () { echo -en "\\n${ink_gray}${1} ${ink_clear}" ; }
askinfo () { echo -en "${ink_gray}${1} ${ink_clear}" ; read -r "${2}" ; }

# confirm
confirm () {
    ask "${1}"
    read -r INPUT
    case "${INPUT}" in
        y|Y|yes|YES|Yes) ;;
        n|N|no|NO|No) say "Script aborted.\\n" && exit 0 ;;
        *) confirm "${1}" ;;
    esac
}

# PRE-FLIGHT CHECKS
if [[ ! -d ./.git ]] ; then errsay "No cloned repository found" ; nl ; exit 1 ; fi
# FIXME: there should be a pre-flight check to verify that the wp cli is available
# FIXME: there should be a pre-flight check to verify that valet-plus is installed

# VARIABLES
dirName=${PWD##*/}

# FUNCTIONS
initiate_env_setup () {

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
    askinfo "WordPress version (default: latest):" wpVersion
    askinfo "Database name (wp_ will be prefixed):" dbName
    askinfo "Database user name (default: root):" dbUserName
    askinfo "Database user pass (default: root):" dbUserPass
    askinfo "Admin user name:" adminUserName
    askinfo "Admin user pass:" adminUserPass
    askinfo "Admin user email:" adminUserEmail

    # setting defaults if values were omitted
    if [[ -z "${wpVersion}" ]] ; then wpVersion="latest" ; fi
    if [[ -z "${dbUserName}" ]] ; then dbUserName="root" ; fi
    if [[ -z "${dbUserPass}" ]] ; then dbUserPass="root" ; fi

    say "The ${ink_yellow}new environment${ink_gray} will be created with the following information:"
    nl
    tinysay "Site name:          ${ink_yellow}${siteName}"
    tinysay "WordPress version:  ${ink_yellow}${wpVersion}"
    tinysay "Database name:      ${ink_yellow}wp_${dbName}"
    tinysay "Database user name: ${ink_yellow}${dbUserName}"
    tinysay "Database user pass: ${ink_yellow}${dbUserPass}"
    tinysay "Admin user name:    ${ink_yellow}${adminUserName}"
    tinysay "Admin user pass:    ${ink_yellow}${adminUserPass}"
    tinysay "Admin user email:   ${ink_yellow}${adminUserEmail}"

    confirm "Would you like to continue? ${yes_no}"

}

download_wordpress () {

    say "Downloading WordPress ..."
    if [[ "${wpVersion}" == "latest" ]] ; then
        if ! wp core download ; then
            errsay "Error during WordPress download" ; nl ; exit 1
        fi
    else
        if ! wp core download --version="${wpVersion}" ; then
            errsay "Error during WordPress download" ; nl ; exit 1
        fi
    fi

}

create_wp_config () {

    say "Creating WordPress configuration file (wp-config.php) ..."
    rm -rf wp-config.php
    if ! wp config create --dbname=wp_"${dbName}" --dbuser="${dbUserName}" --dbpass="${dbUserPass}" --extra-php << PHP
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
PHP
    then errsay "Error during creation of wp-config.php" ; exit 1 ; nl ; fi

}

create_wp_database () {

    say "Creating WordPress database ..."
    if ! wp db create ; then
        errsay "Error during database creation" ; nl ; exit 1
    fi

}

build_wp_site () {

    say "Building WordPress site ..."
    if ! wp core install --url="${dirName}.app" --title="${siteName}.app" --admin_user="${adminUserName}" --admin_password="${adminUserPass}" --admin_email="${adminUserEmail}" ; then
        errsay "Error during building of site" ; nl ; exit 1
    fi

}

enable_tls_for_env () {

    say "Enabling TLS for site ..."
    if ! valet secure "${dirName}" ; then
        errsay "Error while securing site" ; nl ; exit 1
    fi

}

# MAIN
initiate_env_setup
cache_sudo_password
collect_environment_information
download_wordpress # FIXME: from here on down, I couldn't really test the whole process.
create_wp_config
create_wp_database
build_wp_site
enable_tls_for_env
say "Environment sucessfully setup. You may access your new site at ${ink_yellow}https://${dirName}.app" ; nl
