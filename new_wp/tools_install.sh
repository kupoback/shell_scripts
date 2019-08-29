#!/usr/bin/env bash

# USAGE
usage() { echo -e "
USAGE: ${0} [OPTIONS]\\n
OPTIONS:\\n
-m   (optional)   Monochrome output colors
-q   (optional)   Suppress informational messages
-h                Display this usage information\\n
"; }

# OPTIONS
while getopts "mqh" opt; do
    case "${opt}" in
    m) monochrome="yes" ;;
    q) quiet="yes" ;;
    h)
        usage
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

# COMMON VARIABLES & FUNCTIONS
# colors
if [[ -n "${monochrome}" ]]; then
    ink_brew="\\xF0\x9f\x8d\xba"
    ink_clear="\\x1b[0m"
    ink_grey="\\x1b[38;5;244m"
    ink_red="\\x1b[0m"
    ink_green="\\x1b[0m"
    ink_blue="\\x1b[0m"
    ink_yellow="\\x1b[0m"
    ink_purple="\\x1b[0m"
else
    ink_brew="\\xF0\x9f\x8d\xba"
    ink_clear="\\x1b[0m"
    ink_grey="\\x1b[38;5;244m"
    ink_red="\\x1b[38;5;204m"
    ink_green="\\x1b[38;5;120m"
    ink_blue="\\x1b[38;5;081m"
    ink_yellow="\\x1b[38;5;228m"
    ink_purple="\\x1b[38;5;207m"
fi

# output
yes_no="${ink_blue}[${ink_clear} ${ink_green}yes${ink_clear} ${ink_blue}/${ink_clear} ${ink_red}no${ink_clear} ${ink_blue}]${ink_clear}"
mysql_maria="${ink_blue}[${ink_clear} ${ink_yellow}mysql${ink_clear} ${ink_blue}/${ink_clear} ${ink_purple}mariadb${ink_clear} ${ink_blue}]${ink_clear}"
latest="${ink_yellow}latest version"
yuicompressor=""
path="${HOME}"
sitepath="${HOME}/Sites"
phpmyadmin=https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
nl() { if [[ -z "${quiet}" ]]; then echo; fi; }
say() { if [[ -z "${quiet}" ]]; then echo -e "\\n${ink_grey}${1}${ink_clear}"; fi; }
tinysay() { if [[ -z "${quiet}" ]]; then echo -e "${ink_grey}${1}${ink_clear}"; fi; }
errsay() { echo -e "\\n${ink_red}${1}. Script aborted!${ink_clear}"; }
sucsay() { echo -e "${ink_green}${1} successfully installed.${ink_clear}"; }
err() { echo -e "\\n${ink_red}${1}${ink_clear}"; }
ask() { echo -en "\\n${ink_grey}${1} ${ink_clear}"; }
# Asks for info
askinfo() {
    echo -en "${ink_grey}${1} ${ink_clear}"
    read -r "${2}"
}
# Get site path
saysitepath() {
    echo -en "${ink_grey}${1}: ${ink_clear}"
    echo -en "${ink_blue}${path} ${ink_clear}"
}

# confirm
confirm() {
    ask "${1}"
    read -r INPUT
    case "${INPUT}" in
    [yY][eE][sS] | [yY]) ;;
    [mM][yY][sS][qQ][lL] | [mM][aA][rR][iI][aA][dD][bB] | [mM][aA][rR][iI][aA]) ;;
    [nN][oO] | [nN]) say "Script aborted.\\n" && exit 0 ;;
    *) confirm "${1}" ;;
    esac
}

# Cache the sudo password
cache_sudo_password() {

    say "Please enter your local user password."
    sudo -k
    sudo -v && tinysay "${ink_blue}OK"
}

# Gather all the Install Parameters
collect_install_parameters() {

    say "This script will install the basic tools used for local development."
    nl

    confirm "Would you like to continue? ${yes_no}"
    clear

    askinfo "Would you like to use MySQL or mariaDB? ${mysql_maria}" dbStructure
    askinfo "${dbStructure} username (default: root):" dbUserName
    askinfo "${dbStructure} password (default: root):" dbUserPass
    nl
    tinysay "What TLS would you like your sites to be served under? Default is ${ink_yellow}test${ink_grey}"
    askinfo "${ink_red}Note${ink_grey}: Using ${ink_blue}app${ink_grey} or ${ink_blue}dev${ink_grey} will require you to run ${ink_purple}valet secure folder_name${ink_grey} before visiting the page:" getTLS
    askinfo "Install phpmyadmin? ${yes_no}: " installPhpMyAdmin
    askinfo "If using phpStorm, would you like to install yuicompressor for JavaScript and CSS minification watcher? ${yes_no}" getYUI

    # # setting defaults if values were omitted
    if [[ -z "${dbStructure}" ]]; then dbStructure="mariadb"; fi
    if [[ -z "${getTLS}" ]]; then getTLS="test"; fi
    if [[ -z "${getYUI}" ]]; then getYUI="no"; fi
    if [[ -z "${dbUserName}" ]] ; then dbUserName="root" ; fi
    if [[ -z "${dbUserPass}" ]] ; then dbUserPass="root" ; fi

    say "This ${ink_yellow}computer${ink_grey} will have the following installed:"
    nl

    say "${ink_green}PACKAGE MANAGER"
    tinysay "${ink_blue}Homebrew${ink_grey} - A tool/repo installer similar to NPM"
    tinysay "${ink_blue}Composer${ink_grey}:                    ${latest}"
    tinysay "${ink_blue}Node/NPM${ink_grey}:                    ${latest}"
    nl

    say "${ink_green}ENVIRONMENT"
    tinysay "${ink_blue}Laravel Valet${ink_grey} - Local Dev Environment."
    tinysay "${ink_blue}php${ink_grey}"
    tinysay "${ink_blue}Database${ink_grey}:                    ${ink_yellow}${dbStructure}"
    tinysay "${ink_blue}Database username${ink_grey}:           ${ink_yellow}${dbUserName}"
    tinysay "${ink_blue}Database password${ink_grey}:           ${ink_yellow}${dbUserPass}"

    if [[ "${installPhpMyAdmin}" != n* ]]; then
        tinysay "${ink_blue}phpMyAdmin${ink_grey} - latest version"
    fi
    tinysay "${ink_blue}Local site TLS${ink_grey}:              ${ink_yellow}${getTLS}"
    nl

    say "${ink_green}TOOLS"
    tinysay "${ink_blue}Gulp${ink_grey} - Sage8 Projects:       ${latest}"
    tinysay "${ink_blue}WP-CLI${ink_grey}:                      ${latest}"
    tinysay "${ink_blue}Yarn${ink_grey} (for Sage9 Projects):   ${latest}"
    if [[ "${getYUI}" != n* ]]; then
        tinysay "${ink_blue}YUICompressor${ink_grey}:               ${latest}"
    fi

    confirm "Would you like to continue? ${yes_no}"
}

# Install homebrew
install_homebrew() {
    if ! hash brew 2>/dev/null; then
        say "Downloading and installing Homebrew. Please wait…"
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        say "Homebrew is installed. You can use it to install packages by calling to the command ${ink_blue}brew${ink_grey}"
        confirm "Would you like to continue? ${yes_no}"
    else
        tinysay "Homebrew is already installed. You can call to it with the command ${ink_blue}brew${ink_grey}"
        confirm "Would you like to continue? ${yes_no}"
    fi
}

# Install Composer, node, php, wget, SASS, yuicompressor, and database of choice
install_homebrew_packages() {
    if ! type brew >/dev/null 2>&1; then
        if [[ "${getYUI}" != n* ]] ; then
            yuicompressor="yuicompressor"
        fi
        
        tinysay "Installing ${ink_brew} brew packages. Please wait…"
        # brew install composer node php wget sass/sass/sass ${dbStructure} ${yuicompressor}
        brew services start ${dbStructure}
        tinysay "${ink_green}Install Complete!${ink_grey}"
    fi
}

# Check for any errors when installing brew packages
brew_error_checks() {
    tinysay "Checking ${ink_brew} brew for errors."
    
    if ! type composer >/dev/null 2>&1; then
        errsay "There was an error installing Composer. Please review why and report back to the script creator."
    else
        sucsay composer
    fi

    if ! type mysql >/dev/null 2>&1; then
        errsay "There was an error installing ${dbStructure}. Please review why and report back to the script creator."
    else
        sucsay ${dbStructure}
    fi

    if ! type node >/dev/null 2>&1; then
        errsay "There was an error installing Node. Please review why and report back to the script creator."
    else
        sucsay node
    fi
    
    if ! type php >/dev/null 2>&1; then
        errsay "There was an error installing php. Please review why and report back to the script creator."
    else
        sucsay php
    fi
    
    if ! type sass >/dev/null 2>&1; then
        errsay "There was an error installing sass. Please review why and report back to the script creator."
    else
        sucsay sass
    fi

    if ! type wget >/dev/null 2>&1; then
        errsay "There was an error installing wget. Please review why and report back to the script creator."
    else
        sucsay wget
    fi

    if [[ "${getYUI}" != n* ]] ; then
        if ! type yuicompressor  >/dev/null 2>&1; then
            errsay "There was an error installing yuicompressor. Please review why and report back to the script creator."
        else
            sucsay yuicompressor
        fi
    fi
}

# Writes exports to ./bash_profile
bash_profile_write() {
    if [[ ! -e ${HOME}/.bash_profile ]]; then
        tinysay "Creating a .bash_profile file at ${HOME}"
    fi

    if ! grep -q "export PATH" ${HOME}/.bash_profile; then
        tinysay "Adding export PATH to ~/.bash_profile"
        echo 'export PATH' >> ${HOME}/.bash_profile
    fi

    if ! grep -q 'export PATH="$PATH:${HOME}/npm/bin"' ${HOME}/.bash_profile; then
        tinysay "Adding NPM to your \$PATH"
        echo 'export PATH="$PATH:${HOME}/npm/bin"' >> ${HOME}/.bash_profile
    fi

    if ! grep -q 'export PATH="/usr/local/bin:$PATH"' ${HOME}/.bash_profile; then
        tinysay "Adding bin to your \$Path"
        echo 'export PATH="/usr/local/bin:$PATH"' >> ${HOME}/.bash_profile
    fi

    if ! grep -q 'export PATH="/usr/local/sbin:$PATH"' ${HOME}/.bash_profile; then
        tinysay "Adding sbin to your \$Path"
        echo 'export PATH="/usr/local/sbin:$PATH"' >> ${HOME}/.bash_profile
    fi

    if ! grep -q 'export PATH="$PATH:${HOME}/.composer/vendor/bin"' ${HOME}/.bash_profile; then
        tinysay "Adding Composer to ~/.bash_profile"
        echo 'export PATH="$PATH:${HOME}/.composer/vendor/bin"' >> ${HOME}/.bash_profile
    fi

    

    source ${HOME}/.bash_profile
    tinysay "Reloaded your ${ink_yellow}.bash_proflie${ink_grey}"

}

# Installs npm packages
install_npm_packages() {
    if type npm >/dev/null 2>&1; then
        if ! type yarn >/dev/null 2>&1; then
            tinysay "Installing ${ink_blue}yarn${ink_grey}"
            npm install -g yarn
            if ! yarn -v; then
                errsay "There was an error installing yarn. Please review why and report back to the script creator." ; exit 1
            fi
            sucsay "yarn"
        fi
        if ! type gulp >/dev/null 2>&1; then
        tinysay "Installing ${ink_blue}gulp${ink_grey}"
            npm install -g gulp
            if ! gulp -v; then
                errsay "There was an error installing gulp. Please review why and report back to the script creator." ; exit 1
            fi
            sucsay "Gulp"
        fi
    fi
}

# Installs WP-CLI and wp-completion.bash
install_wpcli() {

    if ! type wp >/dev/null 2>&1; then
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        if php wp-cli.phar --info ; then
            chmod +x wp-cli.phar
            sudo mv wp-cli.phar /usr/local/bin/wp
        else
            errsay "WP-CLI didn't install correctly, please see why."
        fi
    fi

    if type wp >/dev/null 2>&1; then
        cd ${HOME}
        mkdir .bash_completions
        cd .bash_completions
        if [[ -e ${HOME}/.bash_completions/wp-completion.bash ]]; then 
            curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v1.5.1/utils/wp-completion.bash
            echo "source \${HOME}/.bash_completions/wp-completion.bash" >> ${HOME}/.bash_profile
        fi
    fi

    source ${HOME}/.bash_profile

}

# Sets up MySQL/MariaDB
setup_mysql() {
    tinysay "${ink_yellow}Opening up MySQL portion of install, this will require user interaction. Enter in a password, then just hit enter.${ink_clear}"
    secs=$((10))
    while [ $secs -gt 0 ]; do
        tinysay "${secs}…"
        sleep 1
        : $((secs--))
    done
    mysql_secure_installation --user=${dbUserName} --password=${dbUserPass}
}

# Installs valet
install_valet() {
    if ! type composer >/dev/null 2>&1; then
        tinysay "Beginning the installation of laravel/valet, your dev env."
        composer global require laravel/valet
        if ! type valet >/dev/null 2>&1; then
            tinysay "Valet's downloaded, let's install it."
            valet install
            sudo valet trust
            valet domain ${getTLS}
            cd ${path}
            if [[ ! -d ${sitepath}  ]]; then
                mkdir Sites
            fi
            cd ${sitepath}
            valet park
            sucsay "You now have a Sites directory located at ${sitepath}. You can create new folders within here, and valet will serve them in your browser using the ${getTLS} as your TLS."
        fi
    fi
}

# Installs phpmyadmin and adds a syslink to the Sites directory
install_phpmyadmin() {
    cd ${sitepath}
    brew install phpmyadmin
    ln -s /usr/local/share/phpmyadmin .
    valet secure phpmyadmin
}

# Main Script Start
# cache_sudo_password
# collect_install_parameters
# install_homebrew
# install_homebrew_packages
# brew_error_checks
# bash_profile_write
# install_npm_packages
# install_wpcli
# setup_mysql
# install_valet
# install_phpmyadmin