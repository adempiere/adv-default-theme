#!/bin/sh

# folder with dist app files
cd /var/www/adempiere-vue/static/js

# Set API Proxy connection
find -name 'app.*.js' -exec sed -i "s|https://api.erpya.com|$API_URL|g" {} \;

# Start nginx web server
nginx && tail -f /dev/null
