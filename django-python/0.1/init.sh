#!/bin/bash
set -e

echo "Starting SSH ..."
service ssh start

cd / && django-admin startproject djangoapp
echo "ALLOWED_HOSTS=['*']" >> /djangoapp/djangoapp/settings.py
python /djangoapp/manage.py runserver 0.0.0.0:8000
