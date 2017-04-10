#!/usr/bin/env bash

github_repo=https://github.com/santoshbaggam/stacker

COMMAND=$1

# check if any command is provided
if [[ -z $COMMAND ]] ; then
	echo "Err: No command provided. Check the docs at $github_repo"
	exit 1
fi

# check for `build` command
if [[ "$COMMAND" = "build" ]] ; then
	sudo apt-get update

	# sudo apt-get install -qq language-pack-en
	echo "Updating language and locales.."
	sudo apt-get install -qq language-pack-en # [Testing..]
	# export LANGUAGE=en_US.UTF-8
	# sudo locale-gen en_US.UTF-8
	# sudo update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_ALL=en_US.UTF-8
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

	# secure php to not to execute the closest file it finds
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
elif [[ "$COMMAND" = "site" ]] ; then
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
	read -p "Enter the site name [ex: api.example.com (or) docs.example.com]: " -e SITE

	if [[ -z $SITE ]] ; then
		echo "Err: Site like \`api.example.com\` or \`docs.example.com\` is required. Check the docs at $github_repo"
		exit 1
	fi

	# absolute path to public folder. ex: /var/www/path/to/example-app/public
	read -p "Enter the absolute path to public folder [ex: /var/www/path/to/example-app/public]: " -e APP_PATH

	if [[ -z $APP_PATH ]] ; then
		echo "Err: App path like \`/var/www/path/to/example-app/public\` is required. Check the docs at $github_repo"
		exit 1
	fi

	# check if the folder path exists
	if [[ ! -d $APP_PATH ]] ; then
		echo "Err: The specified path \`$APP_PATH\` does not exist."
		exit 1
	fi

	# mapping
	echo "Mapping $SITE -> $APP_PATH.."

	nginx_sites_available=/etc/nginx/sites-available
	nginx_sites_enabled=/etc/nginx/sites-enabled
	nginx_logs=/var/log/nginx

	if [[ -e $nginx_sites_available/$SITE ]] ; then
		echo "Site already exists. To re-config run \`sudo rm -f $nginx_sites_available/$SITE $nginx_sites_enabled/$Site\` and try again."
		exit 1
	fi

	# ask for SSL enabling
	read -p "Do you want to enable SSL for this site? (Y/n): " -n 1 -er SSL

	while [[ ! "$SSL" =~ ^y|Y|n|N$ ]]; do
		read -p "Invalid entry, do you want to enable SSL? (Y/n): " -n 1 -er SSL
	done

	if [[ "$SSL" = "n" ]]; then
		# create nginx server block
		echo "Creating NGINX server block.."

		# pull http server block
		curl -s -L https://raw.githubusercontent.com/santoshbaggam/stacker/master/scripts/nginx-http-server-black.conf > $SITE.tmp
	else
		# check for letsencrypt
		echo "Checking Letsencrypt.."
		letsencrypt --version > /dev/null 2>&1
		LETSENCRYPT_IS_INSTALLED=$?

		if [[ $LETSENCRYPT_IS_INSTALLED -ne 0 ]] ; then
			sudo apt-get install -qq letsencrypt
			echo "Letsencrypt is successfully installed!"
		else
			echo "Letsencrypt is already installed."
		fi

		# prompt email id, to which ssl cert. expiration mail shoots out
		read -p "Enter your E-mail (used for SSL expiry reminders, etc): " -e EMAIL

		while [[ -z "$EMAIL" ]]; do
			read -p "Invalid E-mail, enter again? : " -e EMAIL
		done

		# create nginx server block
		echo "Creating NGINX server block.."

		# generate the certificate
		sudo letsencrypt certonly -n --agree-tos --webroot -w $APP_PATH -d $SITE -m $EMAIL

		# pull https server block
		curl -s -L https://raw.githubusercontent.com/santoshbaggam/stacker/master/scripts/nginx-https-server-black.conf > $SITE.tmp

		sudo sed -i "s|ssl_certificate /etc/letsencrypt/live/{SITE}/fullchain.pem;|ssl_certificate /etc/letsencrypt/live/$SITE/fullchain.pem;|" $SITE.tmp
		sudo sed -i "s|ssl_certificate_key /etc/letsencrypt/live/{SITE}/privkey.pem;|ssl_certificate_key /etc/letsencrypt/live/$SITE/privkey.pem;|" $SITE.tmp
	fi

	sudo sed -i "s/server_name {SITE};/server_name $SITE;/" $SITE.tmp
	sudo sed -i "s|root {PATH};|root $APP_PATH;|" $SITE.tmp
	sudo sed -i "s|access_log $nginx_logs/{SITE}/access.log;|access_log $nginx_logs/$SITE/access.log;|" $SITE.tmp
	sudo sed -i "s|error_log $nginx_logs/{SITE}/error.log;|error_log $nginx_logs/$SITE/error.log;|" $SITE.tmp

	if [[ ! -d "/var/log/nginx/$SITE" ]] ; then
		sudo mkdir /var/log/nginx/$SITE
	fi

	sudo mv $SITE.tmp $nginx_sites_available/$SITE

	# create nginx sites enabled symlink
	sudo ln -s $nginx_sites_available/$SITE $nginx_sites_enabled

	sudo service nginx reload

	echo "Server block created and site ($SITE) is successfully installed!"

# end of valid commands
else
	echo "Err: Invalid command. Check the docs at $github_repo"
	exit 1
fi
