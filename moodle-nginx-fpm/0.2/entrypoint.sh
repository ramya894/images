#!/bin/bash

#set -e
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

    rm -rf /var/lib/mysql
    ln -s $MARIADB_DATA_DIR /var/lib/mysql
    chown -R mysql:mysql $MARIADB_DATA_DIR
    test ! -d /run/mysqld && echo "INFO: /run/mysqld not found. creating ..." && mkdir -p /run/mysqld
    chown -R mysql:mysql /run/mysqld
}

start_mariadb(){
    if test ! -e /run/mysqld/mysqld.sock; then 
        touch /run/mysqld/mysqld.sock
    fi
    chmod 777 /run/mysqld/mysqld.sock
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    /usr/bin/mysqld --user=mysql &
    # make sure mysql service is started...
    port=`netstat -nlt|grep 3306|wc -l`
    process=`ps -ef |grep mysql|grep -v grep |wc -l`
    try_count=1

    while [ $try_count -le 10 ]
    do 
        if [ $port -eq 1 ] && [ $process -eq 1 ]; then 
            echo "INFO: MariaDB is running... "            
            break
        else            
            echo "INFO: Haven't found MariaDB Service this time, Wait 10s, try again..."
            sleep 10s
            let try_count+=1
            port=`netstat -nlt|grep 3306|wc -l`
            process=`ps -ef |grep mysql|grep -v grep |wc -l`    
        fi
    done
    # create default database 'azurelocaldb'
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS azurelocaldb; FLUSH PRIVILEGES;"
}

#unzip phpmyadmin
setup_phpmyadmin(){
    test ! -d "$PHPMYADMIN_HOME" && echo "INFO: $PHPMYADMIN_HOME not found. creating..." && mkdir -p "$PHPMYADMIN_HOME"
    cd $PHPMYADMIN_SOURCE
    tar -xf phpMyAdmin.tar.gz -C $PHPMYADMIN_HOME --strip-components=1
    cp -R phpmyadmin-config.inc.php $PHPMYADMIN_HOME/config.inc.php    
    cp -R phpmyadmin-default.conf /etc/nginx/conf.d/default.conf
	cd /
    rm -rf $PHPMYADMIN_SOURCE
    if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
        echo "INFO: NOT in Azure, chown for "$PHPMYADMIN_HOME  
        chown -R www-data:www-data $PHPMYADMIN_HOME
    fi 
}    

setup_moodle(){
	test ! -d "$MOODLE_HOME" && echo "INFO: $MOODLE_HOME not found. creating ..." && mkdir -p "$MOODLE_HOME"
	cd $MOODLE_HOME
    GIT_REPO=${GIT_REPO:-https://github.com/azureappserviceoss/moodle-linuxappservice-azure}
	GIT_BRANCH=${GIT_BRANCH:-master}
	echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
	echo "REPO: "$GIT_REPO
	echo "BRANCH: "$GIT_BRANCH
	echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
    
	echo "INFO: Clone from "$GIT_REPO
    git clone $GIT_REPO $MOODLE_HOME/moodle	&& cd $MOODLE_HOME/moodle
	if [ "$GIT_BRANCH" != "master" ];then
		echo "INFO: Checkout to "$GIT_BRANCH
		git fetch origin
	    git branch --track $GIT_BRANCH origin/$GIT_BRANCH && git checkout $GIT_BRANCH
	fi
    cp -rf $MOODLE_SOURCE/installlib.php $MOODLE_HOME/moodle/lib/installlib.php    
    mkdir -p $MOODLE_HOME/moodledata    
    chmod -R 777 $MOODLE_HOME
    if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
        echo "INFO: NOT in Azure, chown for "$MOODLE_HOME  
        chown -R www-data:www-data $MOODLE_HOME
    fi 
}

update_db_config(){    
	DATABASE_HOST=${DATABASE_HOST:-127.0.0.1}
	DATABASE_NAME=${DATABASE_NAME:-azurelocaldb}
    DATABASE_USERNAME=${DATABASE_USERNAME:-phpmyadmin}
    DATABASE_PASSWORD=${DATABASE_PASSWORD:-MS173m_QN}
    export DATABASE_HOST
    export DATABASE_NAME
    export DATABASE_USERNAME
    export DATABASE_PASSWORD	 
}

# setup server root
test ! -d "$MOODLE_HOME" && echo "INFO: $MOODLE_HOME not found. creating..." && mkdir -p "$MOODLE_HOME"

echo "Setup openrc ..." && openrc && touch /run/openrc/softlevel

echo "INFO: creating /run/php/php7.0-fpm.sock ..."
test -e /run/php/php7.0-fpm.sock && rm -f /run/php/php7.0-fpm.sock
mkdir -p /run/php
touch /run/php/php7.0-fpm.sock
if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
    echo "INFO: NOT in Azure, chown for /run/php/php7.0-fpm.sock"  
    chown -R www-data:www-data /run/php/php7.0-fpm.sock 
fi 
chmod 777 /run/php/php7.0-fpm.sock

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
    update_db_config
    # DATABASE_USERNAME=${DATABASE_USERNAME:-phpmyadmin}
    # DATABASE_PASSWORD=${DATABASE_PASSWORD:-MS173m_QN}
	echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
    echo "phpmyadmin username:" $DATABASE_USERNAME
    echo "phpmyadmin password:" $DATABASE_PASSWORD
    echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
    mysql -u root -e "GRANT ALL ON *.* TO \`$DATABASE_USERNAME\`@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    echo "Installing phpMyAdmin ..."
    setup_phpmyadmin    
fi

# That config.php doesn't exist means moodle is not installed/configured yet.
if [ ! -e "$MOODLE_HOME/moodle/config.php" ]; then
	echo "INFO: $MOODLE_HOME/moodle/config.php not found."
	echo "Installing Moodle for the first time ..." 
	setup_moodle	

	if [ ${DATABASE_HOST} ]; then
        echo "INFO: Update config.php..."
        
        cd $MOODLE_HOME/moodle
		cp $MOODLE_SOURCE/config.php .
        chmod 777 config.php

		if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then 
           echo "INFO: NOT in Azure, chown for wp-config.php"
           chown -R www-data:www-data config.php
        fi
        if [ "${DATABASE_TYPE}" == "local" ]; then
            #$CFG->dbtype    = 'mariadb';
            sed -i "s/getenv('DATABASE_TYPE')/'mariadb'/g" config.php
        else
            sed -i "s/getenv('DATABASE_TYPE')/'mysqli'/g" config.php
        fi
        sed -i "s/getenv('DATABASE_NAME')/'${DATABASE_NAME}'/g" config.php
        sed -i "s/getenv('DATABASE_USERNAME')/'${DATABASE_USERNAME}'/g" config.php
        sed -i "s/getenv('DATABASE_PASSWORD')/'${DATABASE_PASSWORD}'/g" config.php
        sed -i "s/getenv('DATABASE_HOST')/'${DATABASE_HOST}'/g" config.php
    else 
        echo "INFO: DATABASE_HOST: ${DATABASE_HOST}"			        
	fi
else
	echo "INFO: $MOODLE_HOME/moodle/config.php already exists."
	echo "INFO: You can modify it manually as need."
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

echo "Starting Redis ..."
redis-server &

echo "Starting Memcached ..."
/usr/bin/memcached -u memcached -v -m 128 -p 11211 -c 1024 -I 4M &

if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
    echo "NOT in AZURE, Start crond, log rotate..."
    crond
fi 

test ! -d "$SUPERVISOR_LOG_DIR" && echo "INFO: $SUPERVISOR_LOG_DIR not found. creating ..." && mkdir -p "$SUPERVISOR_LOG_DIR"
test ! -d "$NGINX_LOG_DIR" && echo "INFO: Log folder for nginx/php not found. creating..." && mkdir -p "$NGINX_LOG_DIR"
test ! -e /home/50x.html && echo "INFO: 50x file not found. createing..." && cp /usr/share/nginx/html/50x.html /home/50x.html
test -d "/home/etc/nginx" && mv /etc/nginx /etc/nginx-bak && ln -s /home/etc/nginx /etc/nginx
test ! -d "home/etc/nginx" && mkdir -p /home/etc && mv /etc/nginx /home/etc/nginx && ln -s /home/etc/nginx /etc/nginx

echo "Starting SSH ..."
echo "Starting php-fpm ..."
echo "Starting Nginx ..."

cd /usr/bin/
supervisord -c /etc/supervisord.conf

