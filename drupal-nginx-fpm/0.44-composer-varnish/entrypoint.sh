#!/bin/bash

# set -e

php -v

setup_mariadb_data_dir(){
    test ! -d "$MARIADB_DATA_DIR" && echo "INFO: $MARIADB_DATA_DIR not found. creating ..." && mkdir -p "$MARIADB_DATA_DIR"

    # check if 'mysql' database exists
    if [ ! -d "$MARIADB_DATA_DIR/mysql" ]; then
	    echo "INFO: 'mysql' database doesn't exist under $MARIADB_DATA_DIR. So we think $MARIADB_DATA_DIR is empty."
	    echo "Copying all data files from the original folder /var/lib/mysql to $MARIADB_DATA_DIR ..."
	    cp -R /var/lib/mysql/. $MARIADB_DATA_DIR
    else
	    echo "INFO: 'mysql' database already exists under $MARIADB_DATA_DIR."
    fi

    rm -Rf /var/lib/mysql
    ln -s $MARIADB_DATA_DIR /var/lib/mysql
    chown -R mysql:mysql $MARIADB_DATA_DIR
    test ! -d /run/mysqld && echo "INFO: /run/mysqld not found. creating ..." && mkdir -p /run/mysqld
    chown -R mysql:mysql /run/mysqld    
}

start_mariadb(){
    /etc/init.d/mariadb setup
    rc-service mariadb restart

    rm -f /tmp/mysql.sock
    ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock

    # create default database 'azurelocaldb'
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS azurelocaldb; FLUSH PRIVILEGES;"
}

#unzip phpmyadmin
setup_phpmyadmin(){
    test ! -d "$PHPMYADMIN_HOME" && echo "INFO: $PHPMYADMIN_HOME not found. creating..." && mkdir -p "$PHPMYADMIN_HOME"
    cd $PHPMYADMIN_SOURCE
    tar -xf phpMyAdmin.tar.gz -C $PHPMYADMIN_HOME/ --strip-components=1 
    cp -R phpmyadmin-default.conf /etc/nginx/nginx.conf
    cp -R phpmyadmin-config.inc.php $PHPMYADMIN_HOME/config.inc.php
    cp -R default.phpmyadmin.vcl /etc/varnish/default.vcl
    cd /
    rm -Rf $PHPMYADMIN_SOURCE
	if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
        echo "INFO: NOT in Azure, chown for "$PHPMYADMIN_HOME  
        chown -R www-data:www-data $PHPMYADMIN_HOME
	fi
}

#Get drupal from Git
setup_drupal(){
    while test -d "$DRUPAL_PRJ"  
    do
        echo "INFO: $DRUPAL_PRJ is exist, clean it ..."
        # mv is faster than rm.    
        mv $DRUPAL_PRJ /home/bak/drupal_prj_bak$(date +%s)
    done
    # test ! -d "$DRUPAL_PRJ" && echo "INFO: $DRUPAL_PRJ not found. creating..." && mkdir -p "$DRUPAL_PRJ"	
	# cd $DRUPAL_PRJ
	GIT_REPO=${GIT_REPO:-https://github.com/azureappserviceoss/drupalcms-composer-azure}
	GIT_BRANCH=${GIT_BRANCH:-master}
	echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
	echo "REPO: "$GIT_REPO
	echo "BRANCH: "$GIT_BRANCH
	echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
    
	echo "INFO: Clone from "$GIT_REPO
    git clone $GIT_REPO $DRUPAL_PRJ	&& cd $DRUPAL_PRJ
	if [ "$GIT_BRANCH" != "master" ];then
		echo "INFO: Checkout to "$GIT_BRANCH
		git fetch origin
	    git branch --track $GIT_BRANCH origin/$GIT_BRANCH && git checkout $GIT_BRANCH
	fi

    # restore old site to drupal project
    if [ -d /home/bak/drupal_site ]; then 
        echo "INFO: Restore old version site ..."
        while test -d "$DRUPAL_PRJ/web"  
        do
            # mv is faster than rm.
            mv $DRUPAL_PRJ/web /home/bak/drupal_prj_web_bak$(date +%s)            
        done
        mv /home/bak/drupal_site $DRUPAL_PRJ/web/
    fi
        
    chmod a+w "$DRUPAL_PRJ/web/sites/default" 
    if [ -e "$DRUPAL_PRJ/web/sites/default/settings.php" ]; then 
        #Test this time, if application settings are set to a personal git, myabe drupal has already installed in repo.
        echo "INFO: Settings.php is exist..."    
    else
        echo "INFO: Settings.php isn't exist..."    
        mkdir -p "$DRUPAL_PRJ/web/sites/default/files"
        cp "$DRUPAL_PRJ/web/sites/default/default.settings.php" "$DRUPAL_PRJ/web/sites/default/settings.php"
    fi
    chmod a+w "$DRUPAL_PRJ/web/sites/default/files"
    chmod a+w "$DRUPAL_PRJ/web/sites/default/settings.php"
    while test -d "$DRUPAL_HOME"  
    do
        echo "INFO: $DRUPAL_HOME is exist, clean it ..."        
        chmod 777 -R $DRUPAL_HOME 
        rm -rf $DRUPAL_HOME
    done
    ln -s $DRUPAL_PRJ/web  $DRUPAL_HOME           	
}

# test ! -d "$DRUPAL_HOME" && echo "INFO: $DRUPAL_HOME not found. creating..." && mkdir -p "$DRUPAL_HOME"
if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then 
    echo "INFO: NOT in Azure, chown for "$DRUPAL_HOME 
    chown -R www-data:www-data $DRUPAL_HOME
fi

echo "Setup openrc ..." && openrc && touch /run/openrc/softlevel

DATABASE_TYPE=$(echo ${DATABASE_TYPE}|tr '[A-Z]' '[a-z]')
if [ "${DATABASE_TYPE}" == "local" ]; then  
    echo "Starting MariaDB and PHPMYADMIN..."
    echo 'mysql.default_socket = /run/mysqld/mysqld.sock' >> $PHP_CONF_FILE     
    echo 'mysqli.default_socket = /run/mysqld/mysqld.sock' >> $PHP_CONF_FILE     
    #setup MariaDB
    echo "INFO: loading local MariaDB and phpMyAdmin ..."
    echo "Setting up MariaDB data dir ..."
    setup_mariadb_data_dir
    echo "Setting up MariaDB log dir ..."
    test ! -d "$MARIADB_LOG_DIR" && echo "INFO: $MARIADB_LOG_DIR not found. creating ..." && mkdir -p "$MARIADB_LOG_DIR"
    chown -R mysql:mysql $MARIADB_LOG_DIR
    echo "Starting local MariaDB ..."
    start_mariadb

    echo "Granting user for phpMyAdmin ..."
    # Set default value of username/password if they are't exist/null.
    DATABASE_USERNAME=${DATABASE_USERNAME:-phpmyadmin}
    DATABASE_PASSWORD=${DATABASE_PASSWORD:-MS173m_QN}
    echo "phpmyadmin username: "$DATABASE_USERNAME    
    echo "phpmyadmin password: "$DATABASE_PASSWORD    
    mysql -u root -e "GRANT ALL ON *.* TO \`$DATABASE_USERNAME\`@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    echo "Installing phpMyAdmin ..."
    setup_phpmyadmin
fi

# setup Drupal

if [ -e "$DRUPAL_HOME/sites/default/settings.php" ]; then
# Site is exist.
    if [ -d "$DRUPAL_PRJ" ]; then
    # site is exist and is built by composer build, no need to git pull again.
        echo "INFO: $DRUPAL_PRJ is exist..."        
        echo "INFO: Site is Ready..."
    else
    # site is exist and it's not built by composer build, backup it at first.
        echo "INFO: Old Version Site is exist, Backup Site..."        
        if [ -d /home/bak/drupal_site ]; then
            mv /home/bak/drupal_site /home/bak/drupal_site$(date +%s)
        else            
            mkdir -p /home/bak
        fi
        mv $DRUPAL_HOME /home/bak/drupal_site
        echo "Installing Drupal ..."    
        setup_drupal  
    fi    
else
# drupal isn't installed, fresh start
    echo "Installing Drupal ..."    
    setup_drupal   
fi

if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
    echo "INFO: NOT in Azure, chown for "$DRUPAL_PRJ  
    chown -R www-data:www-data $DRUPAL_PRJ 
fi

# Set php-fpm listen type
# By default, It's socket.
# LISTEN_TYPE==port, It's port.
LISTEN_TYPE=${LISTEN_TYPE:-socket}
LISTEN_TYPE=$(echo ${LISTEN_TYPE}|tr '[A-Z]' '[a-z]')
if [ "${LISTEN_TYPE}" == "socket" ]; then  
    echo "INFO: creating /run/php/php7.0-fpm.sock ..."
    test -e /run/php/php7.0-fpm.sock && rm -f /run/php/php7.0-fpm.sock
    mkdir -p /run/php
    touch /run/php/php7.0-fpm.sock
    chown www-data:www-data /run/php/php7.0-fpm.sock
    chmod 777 /run/php/php7.0-fpm.sock
else
    echo "INFO: PHP-FPM listener is 127.0.0.1:9000 ..."    
    #/etc/nginx/conf.d/default.conf
    sed -i "s/unix:\/var\/run\/php\/php7.0-fpm.sock/127.0.0.1:9000/g" /etc/nginx/conf.d/default.conf
    #/usr/local/etc/php/conf.d/www.conf
    sed -i "s/\/var\/run\/php\/php7.0-fpm.sock/127.0.0.1:9000/g" /usr/local/etc/php/conf.d/www.conf
    #/usr/local/etc/php-fpm.d/zz-docker.conf 
    sed -i "s/\/var\/run\/php\/php7.0-fpm.sock/9000/g" /usr/local/etc/php-fpm.d/zz-docker.conf 
fi


cd $DRUPAL_HOME
       
echo "Starting SSH ..."
rc-service sshd start

echo "Starting php-fpm ..."
php-fpm -D
if [ "${LISTEN_TYPE}" == "socket" ]; then  
    chmod 777 /run/php/php7.0-fpm.sock
fi

echo "Starting Varnishd ..."
/usr/sbin/varnishd -a :80 -f /etc/varnish/default.vcl

echo "Starting Nginx ..."
mkdir -p /home/LogFiles/nginx
if test ! -e /home/LogFiles/nginx/error.log; then 
    touch /home/LogFiles/nginx/error.log
fi
/usr/sbin/nginx -g "daemon off;"
