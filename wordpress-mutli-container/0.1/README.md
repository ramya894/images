# Wordpress Docker Image for Multi-container using Docker Compose in Azure Web App for Containers

* wordpress-redis.yml
* wordpress-redis-localdb.yml(Not Ready) 

## Components
This docker image currently contains the following components:

1. WordPress + Redis Object Cache (1.3.8)
2. PHP (7.2.6)
3. Apache/Httpd (2.4.25)

## How to configure to use Azure Database for MySQL with web app 
1. Create a Web App for Containers
2. Browse your site
3. Complete WordPress install and Enter the Credentials for Azure database for MySQL 

## How to configure GIT Repo and Branch
1. Create a Web App for Containers 
2. Add new App Settings

Name | Default Value
---- | -------------
GIT_REPO | https://github.com/azureappserviceoss/wordpress-azure
GIT_BRANCH | linux_appservice

4. Browse your site

>Note: GIT directory: /home/site/wwwroot.
>
>Note: When you deploy it first time, Sometimes need to check wp-config.php. RM it and re-config DB information is necessary.
>
>Note: If ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = false, Before restart web app, need to store your changes by "git push", it will be pulled again after restart/scale up.
>
>Note: If ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true, and /home/site/wwwroot isn't empty, it will not be pulled again after restart/scale up.
>


## How to turn on Xdebug
1. By default Xdebug is turned off as turning it on impacts performance.
2. Connect by SSH.
3. Go to ```/usr/local/etc/php/conf.d```,  Update ```xdebug.ini``` as wish, don't modify the path of below line.
```zend_extension=/usr/local/php/lib/php/extensions/no-debug-non-zts-20170718/xdebug.so```
4. Save ```xdebug.ini```, Restart apache by below cmd: 
```apachectl restart```
5. Xdebug is turned on.

## Connect WordPress to Redis
1. Log-in to WordPress admin. In the left navigation, select **Plugins**, and then select **Installed Plugins**.
2. In the plugins page, find **Redis Object Cache** and click **Settings**.
3. Click the **Enable Object Cache** button.
4. WordPress connects to the Redis server. The connection status appears on the same page.
5. [More infomation about **Redis Object Cache**](https://wordpress.org/plugins/redis-cache)

## Limitations
- Some unexpected issues may happen after you scale out your site to multiple instances, if you deploy a WordPress site on Azure with this docker image and use the MariaDB built in this docker image as the database.
- The phpMyAdmin built in this docker image is available only when you use the MariaDB built in this docker image as the database.
- Please Include  App Setting ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true  when use built in MariaDB since we need files to be persisted.

## Change Log

# How to Contribute
If you have feedback please create an issue but **do not send Pull requests** to these images since any changes to the images needs to tested before it is pushed to production. 
