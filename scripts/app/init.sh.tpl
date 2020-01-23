#!/bin/bash

cd /home/ubuntu/app
npm install
sudo export DB_HOST=${db_host}
node seeds/seed.js
node app.js
