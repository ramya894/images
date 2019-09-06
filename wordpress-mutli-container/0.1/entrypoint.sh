#!/bin/bash
# set -euo pipefail

GIT_REPO=${GIT_REPO:-https://github.com/azureappserviceoss/wordpress-azure}
GIT_BRANCH=${GIT_BRANCH:-linux-appservice}
DATABASE_TYPE=${DATABASE_TYPE:-""}
WEBSITES_ENABLE_APP_SERVICE_STORAGE=${WEBSITES_ENABLE_APP_SERVICE_STORAGE:-true}
DATABASE_HOST=${DATABASE_HOST:-db}
DATABASE_NAME=${DATABASE_NAME:-azurelocaldb}
DATABASE_USERNAME=${DATABASE_USERNAME:-phpmyadmin}
	# if DATABASE_USERNAME equal phpmyadmin, it means it's nothing at beginning.
	if [ "${DATABASE_USERNAME}" == "phpmyadmin" ]; then
	    DATABASE_USERNAME='wordpress'
	fi	
DATABASE_PASSWORD=${DATABASE_PASSWORD:-MS173m_QN}   

setup_wordpress(){    
	echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
	echo "REPO: "$GIT_REPO
	echo "BRANCH: "$GIT_BRANCH
	echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
    echo "INFO: Clone from "$GIT_REPO		
    git clone $GIT_REPO $APP_HOME	
	if [ "$GIT_BRANCH" != "master" ];then
		echo "INFO: Checkout to "$GIT_BRANCH
		git fetch origin
	    git branch --track $GIT_BRANCH origin/$GIT_BRANCH && git checkout $GIT_BRANCH
	fi    	
    
	# Although in AZURE, we still need below chown cmd.
    chown -R www-data:www-data $APP_HOME	
}

setup_phpmyadmin(){
	test ! -d "$PHPMYADMIN_HOME" && echo "INFO: $PHPMYADMIN_HOME not found. creating..." && mkdir -p "$PHPMYADMIN_HOME"
    cd /usr/src && ls -al
    cd $PHPMYADMIN_SOURCE
    tar -xf phpmyadmin.tar.gz -C $PHPMYADMIN_HOME --strip-components=1
    cp -R phpmyadmin-config.inc.php $PHPMYADMIN_HOME/config.inc.php
    mkdir $PHPMYADMIN_HOME/tmp && chmod 777 $PHPMYADMIN_HOME/tmp
    rm -rf $PHPMYADMIN_SOURCE
    if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
        echo "INFO: NOT in Azure, chown for "$PHPMYADMIN_HOME  
        chown -R www-data:www-data $PHPMYADMIN_HOME
    fi
}

test ! -d "$LOG_DIR" && echo "INFO: $LOG_DIR not found. creating..." && mkdir -p "$LOG_DIR" 
test ! -d "$SUPERVISOR_LOG_DIR" && echo "INFO: $SUPERVISOR_LOG_DIR not found. creating ..." && mkdir -p "$SUPERVISOR_LOG_DIR"
test ! -d "$APP_HOME" && echo "INFO: $APP_HOME not found. creating..." && mkdir -p "$APP_HOME"
if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
#    echo "INFO: NOT in Azure, chown for "$APP_HOME  
    chown -R www-data:www-data $APP_HOME
fi 

cd $APP_HOME
if ! [ -e index.php -a -e wp-includes/version.php ]; then
    echo "WordPress not found in $APP_HOME..."	
    echo "Start to clean $APP_HOME..." && cd /home/site && rm -rf $APP_HOME && mkdir -p $APP_HOME && cd $APP_HOME
    echo "Copying now..." && cd $APP_HOME && ls -al    
	setup_wordpress
    cp $WORDPRESS_SOURCE/wp-config-sample.php .

    if [ "$DATABASE_TYPE" == "local" ]; then
        echo "INFO: local MariaDB is used."
        #update_wordpress_config
        echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
        echo "INFO: WORDPRESS_ENVS:"
        echo "INFO: DATABASE_HOST:" $DATABASE_HOST
        echo "INFO: WORDPRESS_DATABASE_NAME:" $DATABASE_NAME
        echo "INFO: WORDPRESS_DATABASE_USERNAME:" $DATABASE_USERNAME
        echo "INFO: WORDPRESS_DATABASE_PASSWORD:" $DATABASE_PASSWORD	        
        echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
         
		cd $WORDPRESS_SOURCE && chmod 777 wp-config.php
		if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then 
           echo "INFO: NOT in Azure, chown for wp-config.php"
           chown -R www-data:www-data wp-config.php
        fi				
        sed -i "s/getenv('DATABASE_NAME')/'${DATABASE_NAME}'/g" wp-config.php
        sed -i "s/getenv('DATABASE_USERNAME')/'${DATABASE_USERNAME}'/g" wp-config.php
        sed -i "s/getenv('DATABASE_PASSWORD')/'${DATABASE_PASSWORD}'/g" wp-config.php
        sed -i "s/getenv('DATABASE_HOST')/'${DATABASE_HOST}'/g" wp-config.php        
		cd $APP_HOME
		cp $WORDPRESS_SOURCE/wp-config.php .
    else 
        # The wp-config.php in default GIT/BRANCH is designed fo local DB, remove it if need.
        if [ "${GIT_REPO}" == "https://github.com/azureappserviceoss/wordpress-azure" -a "${GIT_BRANCH}" == "linux-appservice" ]; then
           echo "The wp-config.php in default GIT/BRANCH is designed fo local DB, remove it if need..."
           rm wp-config.php
        fi        
    fi
fi

cd $APP_HOME
# Install Redis Cache WordPress Plugin
if [ ! -e wp-content/plugins/redis-cache ]; then
	# Update package repos
	apt-get update
	# Install unzip
	apt-get install unzip
	echo "Downloading https://downloads.wordpress.org/plugin/redis-cache.1.3.8.zip"
	curl -o redis-cache.1.3.8.zip -fsL "https://downloads.wordpress.org/plugin/redis-cache.1.3.8.zip"
	echo "Unzipping redis-cache.1.3.8.zip to /var/www/html/wp-content/plugins/"
	unzip -q redis-cache.1.3.8.zip -d /var/www/html/wp-content/plugins/
	echo "Removing redis-cache.1.3.8.zip"
	rm redis-cache.1.3.8.zip
fi

if [ "${DATABASE_TYPE}" == "local" ]; then
    setup_phpmyadmin  
    echo 'mysql.default_socket = /run/mysqld/mysqld.sock' >> /usr/local/etc/php/php.ini
    echo 'mysqli.default_socket = /run/mysqld/mysqld.sock' >> /usr/local/etc/php/php.ini    
fi

echo "Starting SSH ..."
#service ssh start
echo "Starting Apache..."
#apache2-foreground
cd /usr/bin
supervisord -c /etc/supervisord.conf
