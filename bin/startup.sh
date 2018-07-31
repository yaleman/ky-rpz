#!/bin/bash

# startup.sh - runs ky-rpz.sh and bind

cd /opt/ky-rpz
bash /opt/ky-rpz/bin/ky-rpz.sh

/usr/sbin/named -g -c /etc/bind/named.conf -u bind