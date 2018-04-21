#!/bin/bash

if [ ! -f "ky-rpz.config" ]; then
        echo "Couldn't find config file (ky-rpz.config)"
        exit 
else
        source "./ky-rpz.config"
fi
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
if [ ! -d "$ZONEFILEDIR" ]; then
        echo "Zone file dir ($ZONEFILEDIR) doesn't exist, quitting"
        exit
fi

# make sure base directories are here
echo "[+] ensuring base dirs are in place"
mkdir -p $TEMPDIR
mkdir -p $OUTPUTDIR

# cleanup old files
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
sort -u $TEMPDIR/*.list > $TEMPDIR/$DBFILE

# supply the list of domain to squid as well
echo "[+] Updating squid blocklist with sudo"
sudo cp -f "$TEMPDIR/$DBFILE" $SQUIDBLACKLIST

echo "[+] Creating blacklist zone file"
# escape forward slashes to use in sed
ZONEDBFILE=$(echo "$ZONEFILEDIR/$DBFILE" | sed "s#\/#\\\/#g")
# make the zone file
# zone "$DOMAIN" { type master; file "/var/named/named.blocked.zone.db"; };
#sed "s/\(.*\)/zone \"\1\" { type master; file \"$ZONEDBFILE\"\; }\;/" "$TEMPDIR/$BLACKLISTFILE" > "$OUTPUTDIR/$BLACKLISTFILE"
sed "s/\(.*\)/\1 CNAME \./" "$TEMPDIR/$DBFILE" > "$OUTPUTDIR/$DBFILE"

echo "[+] Making zone file with sudo"
#sudo cp "./templates/blocked.zone" "$ZONEFILEDIR"
echo "zone \"rpz.blacklist\" { type master; file \"$ZONEDBFILE\"; };" | sudo tee $ZONEFILEDIR/$NAMEDCONFIG > /dev/null

# copy files to bind9 location
echo "[+] Copying blacklist zonefile"
#sudo mv -u $OUTPUTDIR/$BLACKLISTFILE $ZONEFILEDIR/$BLACKLISTFILE
        cat ./templates/rpz.blacklist.zone $OUTPUTDIR/$DBFILE | sudo tee $ZONEFILEDIR/$DBFILE

# cleanup
echo "[+] Cleaning up temp files"
rm $TEMPDIR/*

echo Done!
