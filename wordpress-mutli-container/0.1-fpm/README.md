# Wordpress Docker Image for Multi-container using Docker Compose in Azure Web App for Containers

* ready-for-deploy.yml ( for web app for mutli containers of Azure )
* ready-for-docker-compose.yml ( for cmd ```docker-compse -f ready-for-docker-compose.yml up``` )

## Components
This docker image currently contains the following components:

1. WordPress (4.9.6) + Redis Object Cache (1.3.8)
2. Php-fpm (7.2.6)

## How to Deploy to Azure by portal 
1. Go to Portal, Create a Web App for Containers
2. In the "Container Settings", select "Docker Compose (Preview)"
3. Upload ready-for-deploy.yml in "Configuration"
4. Go to Web App, add below App Settings (optional):
    * WORDPRESS_DB_HOST
    * WORDPRESS_DB_USER
    * WORDPRESS_DB_PASSWORD
    * WORDPRESS_DB_NAME
    * WEBSITES_ENABLE_APP_SERVICE_STORAGE = true
5. Browse your site
6. Complete WordPress installation  

## How to Deploy to Azure by azure-cli
- sample script ( Please modify as your conditions ):
```
$resourceGroupName = "mywebapp"
$planName = $resourceGroupName
$appName = $resourceGroupName
$configFile = "ready-for-deploy.yml"
$location = "West US"

# Create Resource Group
az group create -l $location -n $resourceGroupName

# Create Service Plan
az appservice plan create `
    -n $planName `
    -g $resourceGroupName ` 
    --sku S2 `
    --is-linux 

# Create WEB APP
az webapp create `
    --resource-group $resourceGroupName `
    --plan $planName `
    --name $appName `
    --multicontainer-config-type compose `
    --multicontainer-config-file $configFile 

# Set Application Setting WEBSITES_ENABLE_APP_SERVICE_STORAGE
az webapp config appsettings set `
    --resource-group $resourceGroupName `
    --name $appName `
    --settings WEBSITES_ENABLE_APP_SERVICE_STORAGE="true" 

# Below Scripts are for MYSQL DB Setting, it's optional. 
# You can ingore them If you like to set DB connection in the wordpress installation process.
$mysqlResourceGroupName = "myMysqlResourceGroup"
$mysqlServerName = $mysqlResourceGroupName
$mysqlUser = "mySqlUser"
$password = "myPassword"
$dbHost = $mysqlServerName + ".mysql.database.azure.com"
$dbUser = $mysqlUser +"@" + $mysqlServerName
$wpDBName="myDB"

#Set Application Setting of MySQL
az webapp config appsettings set `
    --resource-group $resourceGroupName `
    --name $appName `
    --settings WORDPRESS_DB_HOST=$dbHost `
        WORDPRESS_DB_USER=$dbUser `
        WORDPRESS_DB_PASSWORD=$password `
        WORDPRESS_DB_NAME=$wpDBName
``` 

## Connect WordPress to Redis
1. Log-in to WordPress admin. In the left navigation, select **Plugins**, and then select **Installed Plugins**.
2. In the plugins page, find **Redis Object Cache** and click **Settings**.
3. Click the **Enable Object Cache** button.
4. WordPress connects to the Redis server. The connection status appears on the same page.
5. [More infomation about **Redis Object Cache**](https://wordpress.org/plugins/redis-cache)

## Limitations
- Please Include  App Setting ```WEBSITES_ENABLE_APP_SERVICE_STORAGE``` = true  when use built in MariaDB since we need files to be persisted.
- If you plan to connect to an SSL enabled Mysql server, you have to use below application settings before you start to browse.
    * WORDPRESS_DB_HOST
    * WORDPRESS_DB_USER
    * WORDPRESS_DB_PASSWORD
    * WORDPRESS_DB_NAME

## Change Log

# How to Contribute
If you have feedback please create an issue but **do not send Pull requests** to these images since any changes to the images needs to tested before it is pushed to production. 
