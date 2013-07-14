#!/bin/bash

[[ $(id -u) == 0 ]] || { echo "root only"; exit 0; }

set -e

# Based on article by Shubhang Mani, 
# How to Set Up Metric Collection Using Graphite and Statsd on Ubuntu 12.04 LTS 
# Ori, original script dated to May 15, 2012

# node.js using PPA (for statsd) !! now nodejs is in main
#apt-get install python-software-properties
#apt-add-repository ppa:chris-lea/node.js
#apt-get update
#apt-get install nodejs npm

# Install git to get statsd
#apt-get install git

# System level dependencies for Graphite
#apt-get install memcached python-dev python-pip sqlite3 libcairo2 \
 #libcairo2-dev python-cairo pkg-config

# Get latest pip
#pip install --upgrade pip 

# Install carbon and graphite deps 
cat >> /tmp/graphite_reqs.txt << EOF
django
python-memcached
django-tagging
twisted
whisper
carbon
graphite-web
EOF

#pip install -r /tmp/graphite_reqs.txt

#
# Configure carbon
#
cd /opt/graphite/conf/
cp carbon.conf.example carbon.conf

# Create storage schema and copy it over
# Using the sample as provided in the statsd README
# https://github.com/etsy/statsd#graphite-schema

cat >> /tmp/storage-schemas.conf << EOF
# Schema definitions for Whisper files. Entries are scanned in order,
# and first match wins. This file is scanned for changes every 60 seconds.
#
#  [name]
#  pattern = regex
#  retentions = timePerPoint:timeToStore, timePerPoint:timeToStore, ...
[stats]
priority = 110
pattern = ^stats\..*
retentions = 10s:6h,1m:7d,10m:1y
EOF

cp /tmp/storage-schemas.conf storage-schemas.conf

# Make sure log dir exists for webapp
mkdir -p /opt/graphite/storage/log/webapp

# Copy over the local settings file and initialize database
cd /opt/graphite/webapp/graphite/
#cp local_settings.py.example local_settings.py

# from http://stackoverflow.com/questions/9850581/django-error-when-installing-graphite-settings-databases-is-improperly-configu
echo "/opt/graphite/webapp/graphite/local_settings.py"
echo "edit to set:"
echo "DATABASES and ENGINE"
echo DATABASES = {
echo     'default': {
echo         'NAME': '/opt/graphite/storage/graphite.db',
echo         'ENGINE': 'django.db.backends.sqlite3',
echo 
echo Cont
read ANS
#without those settings, abort on this error:
#ImproperlyConfigured: settings.DATABASES is improperly configured. Please supply the ENGINE value. Check settings documentation for more details.

python manage.py syncdb  # Follow the prompts, creating a superuser is optional
#django superuser: root 
#pass ori

# statsd
cd /opt && git clone git://github.com/etsy/statsd.git

# StatsD configuration
cat >> /tmp/localConfig.js << EOF
{
  graphitePort: 2003
, graphiteHost: "127.0.0.1"
, port: 8125
}
EOF

cp /tmp/localConfig.js /opt/statsd/localConfig.js

printf "installation complete, hit enter to cont: "; read ANS

# Run carbon-cache
set -x
cd /opt/graphite && ./bin/carbon-cache.py –debug start

# Run graphite-web
cd /opt/graphite && ./bin/run-graphite-devel-server.py .

# Run statsd: 
cd /opt/statsd && node ./stats.js ./localConfig.js

# Run the example client (any one will suffice, python client shown here): 
cd /opt/statsd/examples && python ./python_example.py






