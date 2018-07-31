#!/bin/bash

cd /opt/ky-rpzi
echo [+] updating git repository
git pull
echo [+] updating RPZ
./scripts/ky-rpz.sh
echo [+] reloading bind config
rndc reload
