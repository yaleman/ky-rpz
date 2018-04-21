#!/bin/bash

TEMPDIR="./tmp"
OUTPUTDIR="./output"
ZONEFILEDIR="/var/named/chroot/var/named/"
ZONEDBFILE="/var/named/named.blacklisted.zone.db"
SQUIDBLACKLIST="/etc/squid/blocked_sites.txt"
# main script

# check variables in case of user
if [ -z "$TEMPDIR" ]; then
        echo "Tempdir not set or is empty, quitting."
        exit
fi
if [ -z "$OUTPUTDIR" ]; then
        echo "Outputdir not set or is empty, quitting."
        exit
fi
if [ -d "$ZONEFILEDIR" ]; then
        echo "Zone file dir ($ZONEFILEDIR) doesn't exist, quitting"
        exit
fi

ZONEDBFILE=$(echo "$ZONEDBFILE" | sed "s#\/#\\\/#g")

# make sure base directories are here
echo "[+] ensuring base dirs are in place"
mkdir -p $TEMPDIR
mkdir -p $OUTPUTDIR

# cleanup
if [ -d $TEMPDIR ]; then
        echo "[+] Cleaning up in case of failed run"
        # check if any files in the temp dir and delete them if so
        files=$(shopt -s nullglob dotglob; echo $TEMPDIR/*)
        if (( ${#files} ))
        then
                echo "[-] deleting tmpdir files"
                rm $TEMPDIR/*
        fi
else
        echo "Just tried to make a temp dir and it doesn't exist, quitting."
        exit
fi

# get list of domains from different sources
echo "[+] Getting list of domains to blacklist"
wget -O "$TEMPDIR/ads-list.list" 'http://pgl.yoyo.org/adservers/serverlist.php?hostformat=;showintro=0&&mimetype=plaintext'
wget -O "$TEMPDIR/mal-list.list" 'http://mirror1.malwaredomains.com/files/justdomains'
wget -O "$TEMPDIR/ran-list.list" 'http://ransomwaretracker.abuse.ch/downloads/RW_DOMBL.txt'

# compile into single unique list
echo "[+] Cleaning up domains"
# strip empty lines and commented lines from the lists
sed -e '/^$/d' -e '/^\#/d' -e 's/[^\s]*\s//' -i $TEMPDIR/*.list
# grab a unique, sorted list of all the .list files' contents
sort -u $TEMPDIR/*.list > $TEMPDIR/blacklist.txt

# supply the list of domain to squid as well
#echo "[+] Updating squid blocklist with sudo"
#sudo cp -f "$TEMPDIR/blacklist.txt" $SQUIDBLACKLIST

# zone "$DOMAIN" { type master; file "/var/named/named.blocked.zone.db"; };
echo "[+] Creating blacklisted config"
sed "s/\(.*\)/zone \"\1\" { type master; file \"$ZONEDBFILE\"\; }\;/" "$TEMPDIR/blacklist.txt" > "$OUTPUTDIR/blacklisted.zones"

# cleanup
#echo "[+] Cleaning up temp files"
#rm $TEMPDIR/*.list
#rm $TEMPDIR/blacklist.txt

#echo "[+] Ensuring blocked zone file is in place with sudo"
#sudo cp ./templates/named.blocked.zone.db $ZONEFILEDIR

# copy files to bind9 location
#echo "[+] Copying created blacklist config"
#yes | rm -f /var/named/chroot/etc/named.blacklisted.zones
#yes | mv $TEMPDIR/blacklisted.zones /var/named/chroot/etc/named.blacklisted.zones

echo Done!
