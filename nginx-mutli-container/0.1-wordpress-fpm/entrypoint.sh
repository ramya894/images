#!/bin/bash

cd /var/www/html
try_count=1

while [ $try_count -le 20  ]
do 
    if [ -e index.php -a -e wp-includes/version.php  ]; then 
        echo "INFORMATION - Wordpress is ready ..."              
        break
    else
        sleep 10s
        let try_count+=1        
    fi
done

echo "Starting nginx ..."
exec "$@"

