#!/usr/bin/env bash

COMMAND=$1

# check if any command is provided
if [[ -z $COMMAND ]] ; then
	echo "Err: No command provided. Check the docs at https://github.com/santoshbaggam/stacker"
	exit 1
fi

# check for `build` command
if [[ $COMMAND = "build" ]] ; then
	sudo apt-get update

	# sudo apt-get install -qq language-pack-en
	echo "Updating language and locales.."
	export LANGUAGE=en_US.UTF-8
	sudo locale-gen en_US.UTF-8
	sudo update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_ALL=en_US.UTF-8
	echo "Updated successfully!"

	sudo apt-get update

	# install base utils
	echo "Installing common software.."
	sudo apt-get install -qq software-properties-common build-essential curl wget unzip git python-software-properties
	echo "Installed successfully!"

	sudo apt-get update

	# install nginx
	echo "Installing NGINX.."
	sudo apt-get install -qq nginx
	echo "NGINX is installed successfully!"

	# install php and php utils
	echo "Installing PHP/modules.."
	sudo apt-get install -qq php php-mysql php-pgsql php-sqlite3 php-curl \
		php-gd php-gmp php-mcrypt php-mbstring php-memcached \
		php-dompdf php-zip php-xml
	echo "PHP/modules are installed successfully!"

	# secure php to execute the closest file it can find
	echo "Securing PHP.."
	sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.0/fpm/php.ini
	echo "PHP is secured!"

	# restart php-fpm
	sudo service php7.0-fpm restart

	# install composer
	echo "Installing Composer.."
	# sudo apt-get install -qq composer # still in beta..
	curl -sS https://getcomposer.org/installer | php
	sudo mv composer.phar /usr/bin/composer
	echo "Composer is installed successfully!"

# check for `site` command
elif [[ $COMMAND = "site" ]] ; then
	# check for git
	git --version > /dev/null 2>&1
	GIT_IS_INSTALLED=$?

	if [[ $GIT_IS_INSTALLED -ne 0 ]] ; then
		echo "Err: Git is not installed. Run \`stacker build\` to get the latest tools and try again."
		exit 1
	fi

	# check for curl
	curl --version > /dev/null 2>&1
	CURL_IS_INSTALLED=$?

	if [[ $CURL_IS_INSTALLED -ne 0 ]] ; then
		echo "Err: cURL is not installed. Run \`stacker build\` to get the latest tools and try again."
		exit 1
	fi

	# check for nginx
	nginx -v > /dev/null 2>&1
	NGINX_IS_INSTALLED=$?

	if [[ $NGINX_IS_INSTALLED -ne 0 ]] ; then
		echo "Err: cURL is not installed. Run \`stacker build\` to get the latest tools and try again."
		exit 1
	fi

	# ex: api.example.com (or) docs.example.com
	SITE=$2

	if [[ -z $SITE ]] ; then
		echo "Err: Site like \`api.example.com\` or \`docs.example.com\` is required. Check the docs at https://github.com/santoshbaggam/stacker"
		exit 1
	fi

	# absolute path to public folder. ex: /var/www/path/to/example-app/public
	PATH=$3

	if [[ -z $PATH ]] ; then
		echo "Err: App path like \`/var/www/path/to/example-app/public\` is required. Check the docs at https://github.com/santoshbaggam/stacker"
		exit 1
	fi

	# create the nginx server block
	
# end of valid commands
else
	echo "Err: Invalid command. Check the docs at https://github.com/santoshbaggam/stacker"
	exit 1
fi
