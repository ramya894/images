# Most Important Thing:
- This is fastest version when deploy as azure app service. 
- With this version, Only keep below folders persist, not whole project.
  - ../web/sites
  - ../web/modules
  - ../web/themes

- How about we need to modify some core codes and we also need them to be keep persist? 
  - fork the default git repo/branch, modify as your wish.
  - Add Git parameters in app setting of web app for containers. [More-Information](#git-information)
  - Use "git push" to keep your valuable codes.

# Drupal-nginx-php Docker
This is a Drupal Docker image which can run on both 
 - [Azure Web App on Linux](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-linux-intro)
 - [Drupal on Linux Web App With MySQL](https://ms.portal.azure.com/#create/Drupal.Drupalonlinux )
 - Your Docker engines's host.

You can find it in Docker hub here [https://hub.docker.com/r/appsvcorg/drupal-nginx-fpm/](https://hub.docker.com/r/appsvcorg/drupal-nginx-fpm/)

# Components
This docker image currently contains the following components:
1. Drupal (Git pull as you wish)
2. nginx (1.15.8)
3. PHP (7.3.4)
4. Drush
5. Composer (1.8.5)
6. MariaDB ( 10.1.38/if using Local Database )
7. Phpmyadmin ( 4.8.4/if using Local Database )

## How to Deploy to Azure 
1. Create a Web App for Containers, set Docker container as ```appsvcorg/drupal-nginx-fpm:0.6-part-persist``` 
   OR: Create a Drupal on Linux Web App With MySQL.
2. Add one App Setting ```WEBSITES_CONTAINER_START_TIME_LIMIT``` = 1200
3. Set ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true
4. Add Git parameters in App Setting. [More-Information](#git-information)
5. Add DB parameters in App Setting. [More-Information](#db-information)
6. Browse your site and wait almost 10 mins, you will see install page of Drupal.
7. Complete Drupal install.

<h2 id='git-information'></h2>

## How to configure GIT Repo and Branch
1. Create a Web App for Containers
2. Add new App Settings

Name | Default Value
---- | -------------
GIT_REPO | https://github.com/azureappserviceoss/drupalcms-composer-azure
GIT_BRANCH | master

4. Browse your site

>Note: GIT directory: /var/drupal_prj.
>Note: root: /var/www/html -> /var/drupal_prj/web

<h2 id='db-information'></h2>

## How to configure to use Azure database for MySQL 
1. Create a Azure database for MySQL
2. Set ```Enforce SSL connection``` = Disabled
3. Add new Firewall rules, START IP = 0.0.0.0, END IP = 255.255.255.255
4. Go to Web App for Containers, Add new App Settings 

Name | Default Value
---- | -------------
DATABASE_HOST | some-string
DATABASE_NAME | some-string
DATABASE_USERNAME | some-string
DATABASE_PASSWORD | some-string

## How to configure to use Local Database with web app 
1. Create a Web App for Containers 
2. Update App Setting ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true
3. Add new App Settings 

Name | Default Value
---- | -------------
DATABASE_TYPE | local
DATABASE_USERNAME | some-string
DATABASE_PASSWORD | some-string
>Note: We create a database "azurelocaldb" when using local mysql . Hence use this name when setting up the app
>
>Note: Phpmyadmin site is deployed when using local mysql. Please go to 
http://[website]/phpmyadmin, and login with DATABASE_USERNAME and DATABASE_PASSWORD.
>
>Note: Do not use the app setting DATABASE_TYPE=local if using Azure database for MySQL

# How to turn on Xdebug
1. By default Xdebug is turned off as turning it on impacts performance.
2. Connect by SSH.
3. Go to ```/usr/local/etc/php/conf.d```,  Update ```xdebug.ini``` as wish, don't modify the path of below line.
```zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20180731/xdebug.so```
4. Save ```xdebug.ini```, Restart php-fpm by below cmd:
```
# Kill master process of php-fpm
killall -9 php-fpm
# php-fpm will be started by supervisor.
```
5. Xdebug is turned on.

## How to update config files of nginx
1. Go to "/etc/nginx", update config files as your wish. 
2. Reload by below cmd: 
```
/usr/sbin/nginx -s reload
```
## How to update config files of varinish
1. Go to "/etc/varnish", update config files as your wish. 

>You can find backup of default nginx/varnish configration at /etc/nginx-bak and /etc/varnish-bak

## Tips of Log rotate
1. By default, log rotate is disabled if deploy this images to web app for containers of azure. It's enabled if you use this image by "docker run".
2. Log rotate is managed by crond, you can start it with below cmd, it will check logs files in the /home/LogFiles/nginx every minute, and rotate them if bigger than 1M. Old files are stored in /home/LogFiles/olddir, keep 20 backup files by default setting.
```
crond
```
3. Please keep an eye on the log files, the performance will be going down if it's too big.
4. If you don't like to start crond service to triage log rotate every minute, you also can manually triage it by below cmd as your wish, it will talk a while if these log files have already been too big.
```
logrotate /etc/logrotate.conf
```

# Updating Drupal version , themes , files 

You can update ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true  to enable app service storage to have file persistence. Note when there are issues with storage  due to networking or when app service platform is being updated, your app can be impacted.
You can use below composer cmds to install theme/modules. 

[More Informatio](https://www.drupal.org/docs/develop/using-composer/using-composer-to-manage-drupal-site-dependencies):

```
cd /home/drupal-prj
composer require drupal/redis
composer require drupal/adminimal_theme
```
## Limitations
- Must include  App Setting ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true  as soon as you need files to be persisted.
- Deploy to Azure, Pull and run this image need some time, You can include App Setting ```WEBSITES_CONTAINER_START_TIME_LIMIT``` to specify the time in seconds as need, Default is 240 and max is 1800, suggest to set it as 900 when using this version.

## Change Log
- **Version 0.6-part-persist**
  1. Only keep below folders persist, not whole project. The purpose is imporve the performance when deploy as azure app service.
  - ../web/sites
  - ../web/modules
  - ../web/themes  
- **Version 0.6**
  1. Upgrade php-fpm/nginx/composer/mariadb/phpmyadmin
  2. Add function log rotate. (It's disabed if deploy to web app of azure by default.)
  3. Allow customer to use their own configration of nginx/varnish.   
- **Version 0.5**
  1. Upgrade php-fpm/composer
  2. Upgrade phpmyadmin.
  3. Add function log rotate. (It's disabed if deploy to web app of azure by default.)
  4. Php-fpm and nginx are watched by supervisord.   
- **Version 0.46**
  1. Update php settings, php memory = 512M.
- **Version 0.45**
  1. Update php codes, it can fill database parameters automatically if deploy to azure by template.    
- **Version 0.44-composer-varnish**
  1. Add Varnish, improve performance.  
  2. Use 'Git pull' to get drupal project codes form another repo, support composer better.
  3. Add selectable listen type of php-fpm/nginx.  
- **Version 0.44**
  1. Update Version of PHP to 7.2.11.
  2. Increase php max excute time and memory size.
  3. Update Version of Composer to 1.72.1.
  4. Include composer require-dev.
  5. Abandon Redis from this version.
- **Version 0.43-composer**
  1. Use "composer create-project" to download latest drupal core.  [More Informatio](https://www.drupal.org/docs/develop/using-composer/using-composer-to-manage-drupal-site-dependencies)
  2. Update composer by entrypoint.sh, always keep it as latest.  
- **Version 0.43**
  1. Installed php extension redis, and local redis-server.
  2. Fix the bug of Drush.
- **Version 0.42**
  1. Update settings of opcache, more stable.  
- **Version 0.41**
  1. Reduce size.
  2. Update version php-fpm.
- **Version 0.4**
  1. Base image to alpine, reduce size.
  2. Update version of nginx and php-fpm.
  3. Update conf files of php-fpm, pass env parameters by default.
  4. Update conf files of nignx.   
- **Version 0.31**
  1. Install some common debug tools, netstat, tcpping, tcpdump.
- **Version 0.3**
  1. Use Git to deploy Drupal.
  2. Add Xdebug extension of PHP.
  3. Update version of nginx to 1.13.11.
  4. Update version of phpmyadmin to 4.8.0.
- **Version 0.2**
  1. Supports local MySQL.
  2. Create default database - azurelocaldb.(You need set DATABASE_TYPE to **"local"**)
  3. Considering security, please set database authentication info on [*"App settings"*](#How-to-configure-to-use-Local-Database-with-web-app) when enable **"local"** mode.
     Note: the credentials below is also used by phpMyAdmin.
      -  DATABASE_USERNAME | <*your phpMyAdmin user*>
      -  DATABASE_PASSWORD | <*your phpMyAdmin password*>
  4. Fixed Restart block issue.

# How to Contribute
If you have feedback please create an issue but **do not send Pull requests** to these images since any changes to the images needs to tested before it is pushed to production.