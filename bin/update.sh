#!/bin/bash

cd /opt/ky-rpz
echo [+] updating git repository
git pull
echo [+] updating RPZ
/opt/ky-rpz/bin/ky-rpz.sh
echo [+] reloading bind config
rndc reload
