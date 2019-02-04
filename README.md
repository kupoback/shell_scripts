# shell_scripts

## clique_wp.sh
This shell script is for use with the wp-boilerplate repo that we use for new projects. This script assumes you already have the repository in your `Sites` folder.

It clones the latest repo, and copies and installs the files to your local environment.

## new_wp.sh
This shell script sets up a new WordPress isntall on your local machine with the parameters to choose your WP version, removes the default Post, Comment, and updates `Sample Page` to be labeled as the Home Page.


### Changelog
Version 0.2

* Added in `wp plugin update --all` to update all plugins on `clique_wp.sh`
* Added in auto activate for WP-Accessibility and MainWP-Child
* Added in conditional for additional plugin activation on `clique_wp.sh`

Version 0.1

* Initial commit of the shell scripts.