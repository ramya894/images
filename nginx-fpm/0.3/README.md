# Nginx Fpm 
This docker image contains nginx, php-fpm , drush and composer. You can find it in Docker hub here [https://hub.docker.com/r/appsvcorg/nginx-fpm/](https://hub.docker.com/r/appsvcorg/nginx-fpm/)
It can run on both [Azure Web App on Linux](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-linux-intro) and your Docker engines's host.

# Docker Images for App Service Linux 
This repository contains docker images that are used for App Service Linux. Some images may be maintained by our team and some maintained by contirbutors.

## Components
This docker image currently contains the following components:

1. Nginx (1.13.11)   
2. PHP (7.0.27) 
3. Composer (1.6.1)
4. Drush
5. MariaDB ( 10.1.26/if using Local Database )
4. Phpmyadmin ( 4.8.0/if using Local Database )

# How to Deploy to Azure 
1. Create a Web App for Containers 
2. Update App Setting ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true 
>If the ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` setting is false, the /home/ directory will not be shared across scale instances, and files that are written there will not be persisted across restarts.
3. Browse http://[website]/hostingstart.html 

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
3. Go to ```/etc/php/7.0/fpm/conf.d```,  Update ```xdebug.ini``` as wish, don't modify the path of below line.
```zend_extension=/usr/local/php/lib/php/20151012/xdebug.so```
4. Save ```xdebug.ini```, Restart php-fpm by below cmd: 
```service fpm7.0-fpm restart```
5. Xdebug is turned on.

## Limitations
- Some unexpected issues may happen after you scale out your site to multiple instances, if you deploy a site on Azure with this docker image and use the MariaDB built in this docker image as the database.
- The phpMyAdmin built in this docker image is available only when you use the MariaDB built in this docker image as the database.
- Must include  App Setting ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true  since we need files to be persisted.

## Change Log
- **Version 0.3** 
  1. Add Xdebug.
  2. Update version of nginx to 1.13.11.
  3. Update version of phpmyadmin to 4.8.0.
- **Version 0.2** 
  1. Supports local MySQL.
  2. Create default database - azurelocaldb.(You need set DATABASE_TYPE to **"local"**)
  3. Considering security, please set database authentication info on **"App settings"** when enable **"local"** mode.   
     Note: the credentials below is also used by phpMyAdmin.
      -  DATABASE_USERNAME | <*your phpMyAdmin user*>
      -  DATABASE_PASSWORD | <*your phpMyAdmin password*>

# How to Contribute
If you have feedback please create an issue but **do not send Pull requests** to these images since any changes to the images needs to tested before it is pushed to production. 
