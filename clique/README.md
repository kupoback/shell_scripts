# Clique Studios Local Backend WP Install

## Prerequisites:
___
* Install `valet` or `valet-plus`
* If running `valet`, install `wp-cli`
* `mkdir` a folder in your `/Sites/` folder, or whever you have `valet park` set with a sub-dir for the **`wp-boilerplate` [repository][1]**
* Check the following lines
	* Line 15: For the correct /path/to/Sites_folder
	* Line 18: That `wp-boilerplate` is the correct folder name where the WP-Boilerplate repository lives
	* Line 19: The .TLD is the correct setup for your env. To check, run `valet domain` and see what it states.
		* You can run `.app` as your domain, but you WILL need to create an SSL certificate for each folder you have parked, which this script does automatically.

## Description
___
The following below describes what this shell script does.

* Asks for a few prompts for you to fill in : your password (for `valet`), the sitename, blog description *(optional)*, database name, database password,
* Fetches the latest wp-boilerplate from the repo, assuming you have a dedicated folder for the repository
* Copies the zip file from the wp-boilerplate repo, unpacks it and updates the wordpress core to the latest version
* Copies the `.sql` file from `dup-installer` and renames it.
* Deletes the `wp-config.php` file in the unpackaged folder
* Creates a new `wp-config.php` and creates a new `db` with a conditional if the db already exists, to allow one more change to try again. I could extend it to the typical Legend of Zelda 3 tries to defeat the boss, but shouldn’t need to, haha.
* Imports the `.sql` file to the database
* Next asks if you wanna create some top level pages (optional)
* Asks if you want to disable comments, which if yes, will disable pings and trackbacks
* Deletes the default wordpress “Hello World” post, the default Comment, and renames “Sample Page” to “Home” with the slug “home”
* Runs through a loop to create the pages listed above (if you entered any, otherwise it skips this)
* Since this is an import of a duplicator theme, it updates the `option` for the following `home`, siteurl`, `blogname`, and if you entered a description `blogdescription`
* Sets the `show_front_page` to `page`
* Sets the `page_on_front` to `Home` by ID 2
* Runs a database search/replace to replace `http://wp-boilerplate.test:8080` with `https://you_folder_name.tls`
  * Example: `https://wordpress_core.app`
* Flushes the rewrite permalinks
* Updates all the plugins
* Installs and activates classic-editor
* Activates WP-Accessibility
* Asks if you’re like to activate additional plugins: 
	* Gravity Forms
		* Also installs @cho’s Gravity Forms WCAG 20 Form Fields
	* Activate Sitemap (Which I want to make obsolete and replace with a shortcode I created on the PFI onboarding project, which offers more parameters, including a Classic Editor pop-up to choose your post type, include children pages and up to what depth, or if we move on to Gutenberg, a new block that will do the same thing. I wasn’t impressed by that plugin, and I wanted to give us more control over the markup and addition of classes, if not just a template we can override. May make into a plugin, may just be something I want to merge into the sage9 theme).
	* Activate Yoast SEO, which will also download and install ACF Content Analysis for Yoast SEO
* Cleans up the `.zip file`, copied `.sql` file, `CLIQUE-CHANGELOG.txt` and `admin-creds-PLEASE-DELETE.txt`. The latter due to terminal informing you of the user name and password.
* Next valet will run `valet secure $dirName` where `$dirName` is grabbed by the initial shell execution via the set vairable `dirName=${PWD##*/}`
  * I find it best to run local sites via SSL to mimic the live site to it’s truest form
* The final thing on screen will showcase the domain you can command click on to access the front-end, a link to access the back end, the login creds based on the repo, and a link to Duplicators cleanup files.

Unfortunately since the repo file is `zip` and not `tar.gz` it take a little longer.

This is my first complex automate as much as possible script, and when starting `SAWS` I was able to get everything setup in under 2 minutes.

If you wanna try it, I suggest creating a `.custom_bash_scripts`dir on `$HOME` and adding that folder to your path. Then running `chmod 755 clique_wp.sh` followed by `source ~/.bash_profile` or `source ~/.bashrc` where ever you’re storing your `PATH` declarations.

### [Download the Bash Script][2]


This will be my baby and maintenance will be on going, so PLEASE any issues you encounter OR any improvements you feel I would make, create tickets here: https://github.com/kupoback/shell_scripts/issues

## @TODO List
___

* **@TODO**: Allow the addition of sub pages, but will need to rethink the logic on this


<!-- Links -->
[1]:https://bitbucket.org/clique_studios/wp-boilerplate/src/master/
[2]:https://github.com/kupoback/shell_scripts/blob/master/clique_wp.sh