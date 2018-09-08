#!/bin/bash

if [ ! -f "conf/ky-rpz.config" ]; then
        echo "Couldn't find config file (ky-rpz.config)"
        exit
else
        source "./conf/ky-rpz.config"
fi
# main script

# check variables in case of user
if [ -z "$INSTALLDIR" ]; then
        echo "Installdir isn't set or is empty, please set \$INSTALLDIR in config"
        exit
fi

if [ -z "$TEMPDIR" ]; then
        echo "Tempdir not set or is empty, quitting."
        exit
fi
if [ -z "$OUTPUTDIR" ]; then
        echo "Outputdir not set or is empty, quitting."
        exit
fi

if [ ! -d "$INSTALLDIR" ]; then
        echo "Configured installation directory ($INSTALLDIR) is probably wrong because I can't find it."
        exit
fi

if [ ! -d "$ZONEFILEDIR" ]; then
        echo "Zone file dir ($ZONEFILEDIR) doesn't exist, quitting"
        exit
fi

if [ ! -z $FORWARDERS ]; then
        echo "[+] updating forwarder config, using $FORWARDERS"
        sed  "s@//#FORWARDERS#@forwarders { $FORWARDERS; };@" $INSTALLDIR/conf/named.conf.options.example | sed 's/;;/;/g' > $INSTALLDIR/conf/named.conf.options
else
        echo "[+] no forwarders specified, using root hints"
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

#TODO: parse this: https://urlhaus.abuse.ch/downloads/rpz/

# Domain Lists
wget -nv -O "$TEMPDIR/yoyo.list" "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=nohtml&showintro=0&mimetype=plaintext"
wget -nv -O "$TEMPDIR/mal-list.list" 'http://mirror1.malwaredomains.com/files/justdomains'
wget -nv -O "$TEMPDIR/abusech-ransomware-list.list" 'http://ransomwaretracker.abuse.ch/downloads/RW_DOMBL.txt'
wget -nv -O "$TEMPDIR/abusech-zeus-list.list" 'https://zeustracker.abuse.ch/blocklist.php?download=baddomains'
wget -nv -O "$TEMPDIR/webminer.list" 'https://raw.githubusercontent.com/greatis/Anti-WebMiner/master/blacklist.txt'

# URL lists

wget -nv -O "$TEMPDIR/cybercrime-tracker.urls" "https://cybercrime-tracker.net/all.php"

echo "[+] Cleaning up URL lists"
# filter out www.* (proto):// and get rid of port/uri entries
sed -e 's/^www\.//' -e 's#^(http|https|ftp)\://##' $TEMPDIR/*.urls | awk -F"/" '{print $1}' | awk -F":" '{print $1}'  > "$TEMPDIR/urls.list"

# compile into single unique list
echo "[+] Cleaning up domains"
# strip empty lines and commented lines from the lists
sed -e '/^$/d' -e '/^\[/d' -e '/^\#/d' -e 's/[^\s]*\s//' -e 's/^www\.//' -e 's/\:[0-9]+$//' -i $TEMPDIR/*.list
# grab a unique, sorted list of all the .list files' contents
sort -u $TEMPDIR/*.list > $TEMPDIR/$DBFILE

# supply the list of domain to squid as well
echo "[+] Updating squid blocklist with sudo"
sudo cp -f "$TEMPDIR/$DBFILE" $SQUIDBLACKLIST

echo "[+] Making zone config file with sudo"
#sudo cp "./templates/blocked.zone" "$ZONEFILEDIR"
echo "zone \"rpz.blacklist\" { type master; file \"$ZONEFILEDIR/$DBFILE\"; };" > $OUTPUTDIR/$NAMEDCONFIG
sudo mv $OUTPUTDIR/$NAMEDCONFIG $ZONEFILEDIR/$NAMEDCONFIG

echo "[+] Creating blacklist zone file"
# make the zone file
# zone "$DOMAIN" { type master; file "/var/named/named.blocked.zone.db"; };
sed "s/\(.*\)/\1 CNAME \./" "$TEMPDIR/$DBFILE" > "$OUTPUTDIR/$DBFILE"


# copy files to bind9 location
echo "[+] Copying blacklist zonefile"
#sudo mv -u $OUTPUTDIR/$BLACKLISTFILE $ZONEFILEDIR/$BLACKLISTFILE
        cat "$INSTALLDIR/templates/db.ky-rpz" "$OUTPUTDIR/$DBFILE" | sudo tee $ZONEFILEDIR/$DBFILE > /dev/null

# cleanup
echo "[+] Cleaning up temp files"
#rm $TEMPDIR/*

echo Done!
