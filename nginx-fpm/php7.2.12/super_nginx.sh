if test ! -e $NGINX_LOG_DIR/error.log; then 
    touch $NGINX_LOG_DIR/error.log
fi
chmod 666 $NGINX_LOG_DIR/error.log
/usr/sbin/nginx -g "daemon off;"