# Alpine-php-mysql
This repo will contain a Docker image with alpine  , php and mysql .
See [how to deploy your app](https://docs.microsoft.com/en-us/azure/app-service/containers/quickstart-php) with this image. 
You can find it in Docker hub here [https://hub.docker.com/r/appsvcorg/alpine-php-mysql/](https://hub.docker.com/r/appsvcorg/alpine-php-mysql/)
It can run on both [Azure Web App on Linux](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-linux-intro) and your Docker engines's host.

# Docker Images for App Service Linux
This repository contains docker images that are used for App Service Linux. Some images may be maintained by our team and some maintained by contirbutors.

## Components
This docker image currently contains the following components:

1. Alpine (3.8)
2. PHP (7.2.8)
3. Apache/Httpd (2.4.33)
4. MariaDB ( 10.1.32/if using Local Database )
5. Phpmyadmin ( 4.8.0/if using Local Database )

# How to Deploy to Azure
1. Create a Web App for Containers
2. Update App Setting ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true
>If the ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` setting is false, the /home/ directory will not be shared across scale instances, and files that are written there will not be persisted across restarts.
3. Browse http://[website]

# How to configure to use Local Database with web app
1. Create a Web App for Containers
2. Update App Setting ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true
3. Add new App Settings

Name | Default Value
---- | -------------
DATABASE_TYPE | local
DATABASE_USERNAME | some-string
DATABASE_PASSWORD | some-string
**Note: We create a database "azurelocaldb" when using local mysql . Hence use this name when setting up the app **

4. Browse http://[website]/phpmyadmin

# How to turn on Xdebug to profile the app
1. By default Xdebug is turned off as turning it on impacts performance.
2. Connect by SSH.
3. Go to ```/etc/php7/conf.d```,  Update ```xdebug.ini``` as wish, don't modify the path of below line.
```zend_extension=/usr/lib/php7/modules/xdebug.so```
4. Save ```xdebug.ini```, Restart apache by below cmd:
```/usr/sbin/httpd -k restart```
5. Xdebug is turned on.

## Limitations
- Some unexpected issues may happen after you scale out your site to multiple instances, if you deploy a site on Azure with this docker image and use the MariaDB built in this docker image as the database.
- The phpMyAdmin built in this docker image is available only when you use the MariaDB built in this docker image as the database.
- Must include  App Setting ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true  since we need files to be persisted.

## Change Log
- **Version 0.32**
  1. Upgrade alpine to 3.8.
  2. Upgrade php to 7.2.8.
  3. Reduce Size. (80+ M)

- **Version 0.31**
  1. Include the module simpleXML.
  2. Avoid the confuse of different php version, alpine 3.7 supports php 7.1.7 well.
  3. Reduce Size.

- **Version 0.3**
  1. Update version of Alpine/PHP/Mariadb.
  2. Reduce Size.

- **Version 0.2**
  1. Update version of PHP/Apache/Mariadb/Phpmyadmin.
  2. Add Xdebug extenstion of PHP.
  3. Use supervisord to keep SSHD and Apache.

# How to Contribute
If you have feedback please create an issue but **do not send Pull requests** to these images since any changes to the images needs to tested before it is pushed to production.
