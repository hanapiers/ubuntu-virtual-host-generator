#!/bin/bash

# Author: Hana Piers
# Date: 07-27-2015

HOSTNAME_FILE="/etc/hosts"
VIRTUAL_HOSTNAME_PATH="/etc/apache2/sites-available/"
DOCUMENT_ROOT_PATH="$HOME/www/"


function show_usage() {
	echo "$0 -v example.com -w example_dir -l /path/to/logs/"
	echo "Options:"
	echo "-v: name of virtual host"
	echo "-w: base directory or the document root"
	echo "-l: logs directory (can be relative to -w)"
	echo "-h: show usage"
	exit 1
}

function validate_options() {	
	if [[ -z $APP_HOST_NAME ]]; then
		echo "-v is required."
		exit 1
	fi

	if [[ -z $APP_WEBROOT_PATH ]]; then
		echo "-w is required."
		exit 1
	fi

	if [[ -z $APP_LOGS_PATH ]]; then
		echo "-l is required."
		exit 1
	fi


	echo "OK: Options validated." && sleep 1
}


function validate_input() {
	if [[ $APP_WEBROOT_PATH = "default" || $APP_WEBROOT_PATH = "default-ssl" || $APP_WEBROOT_PATH = "localhost" ]]; then
		echo "'$APP_WEBROOT_PATH' is not an allowed name!"
		exit 1
	fi

	if [[ -e "$VIRTUAL_HOSTNAME_PATH$APP_WEBROOT_PATH.conf" ]]; then
		echo "'$APP_WEBROOT_PATH' is already taken!"
		exit 1
	fi

	if [[ ! -d "$DOCUMENT_ROOT_PATH$APP_WEBROOT_PATH" ]]; then
		echo "'$DOCUMENT_ROOT_PATH$APP_WEBROOT_PATH' directory is not found!"
		exit 1
	fi

	if [[ ! -d "$DOCUMENT_ROOT_PATH$APP_WEBROOT_PATH/$APP_LOGS_PATH" && ! -d "$APP_LOGS_PATH" ]]; then
		echo "'$APP_LOGS_PATH' is not found!"
		exit 1
	fi

	echo "OK: Inputs validated." && sleep 1
}

function remove_conf() {
	# add in "" to prevent expansion of -rf to rm option
	if [[ -e "$VIRTUAL_HOSTNAME_PATH$APP_WEBROOT_PATH.conf" ]]; then
		if ! sudo rm "$VIRTUAL_HOSTNAME_PATH$APP_WEBROOT_PATH.conf" 2>&1; then
			exit 1
		fi

		echo "OK: Removed virtual host config file." && sleep 1
	fi
}

function remove_host() {
	if [[ -e "$HOSTNAME_FILE.bak" ]]; then
		if ! sudo cp "$HOSTNAME_FILE.bak" "$HOSTNAME_FILE" 2>&1; then
			exit 1
		fi

		echo "OK: Reverted hosts backup." && sleep 1
	fi
}

function create_conf() {
	if ! sudo touch "$VIRTUAL_HOSTNAME_PATH$APP_WEBROOT_PATH.conf" 2>&1; then
		exit 1
	fi

	LOGS_FULL_PATH="$DOCUMENT_ROOT_PATH$APP_WEBROOT_PATH/$APP_LOGS_PATH"
	if [[ ! -d $LOGS_FULL_PATH ]]; then
		LOGS_FULL_PATH=$APP_LOGS_PATH
	fi

	cat << EOL | sudo tee $VIRTUAL_HOSTNAME_PATH$APP_WEBROOT_PATH.conf 1> /dev/null
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	
	ServerName $APP_HOST_NAME
	DocumentRoot $DOCUMENT_ROOT_PATH$APP_WEBROOT_PATH/

	<Directory $DOCUMENT_ROOT_PATH$APP_WEBROOT_PATH/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Order allow,deny
		allow from all
	</Directory>

	ErrorLog ${LOGS_FULL_PATH}error.log
	CustomLog ${LOGS_FULL_PATH}access.log combined
</VirtualHost>
EOL

	if [[ "$?" -ne "0" ]]; then
		remove_conf
		exit 1
	fi

	echo "OK: Created virtual host file." && sleep 1
}

function create_host() {
	if ! sudo sed -i.bak -re "s/(127\.0\.0\.1.*localhost)/\1\n127.0.0.1\t${APP_HOST_NAME}/g" $HOSTNAME_FILE 2>&1; then
		exit 1
	fi

	echo "OK: Created hosts backup." && sleep 1
}

while getopts :v:w:l:h OPT; do
	case $OPT in
		v ) APP_HOST_NAME=$OPTARG ;;
		w ) APP_WEBROOT_PATH=$OPTARG ;;
		l ) APP_LOGS_PATH=$OPTARG ;;
		h ) show_usage ;;
		\?) show_usage ;;
	esac
done


if validate_options && validate_input && create_conf && create_host; then
	if ! sudo a2ensite $APP_WEBROOT_PATH 2>&1; then
		remove_conf
		remove_host
		exit 1
	fi

	echo "OK: Successfully generated virtual hosts" && sleep 1
fi

if ! sudo service apache2 reload 2>&1; then
	exit 1
fi

echo "OK: Restarted Apache." && sleep 1