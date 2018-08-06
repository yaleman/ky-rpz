# KY-RPZ (Kush-Yale RPZ)

A slick and DIY RPZ for people who want to roll their own.

This'll make the necessary config and zone file to make an `rpz.blacklist` Response Policy Zone configuration on modern BIND implementations.

## Script config

An example configuration file is in `ky-rpz.config.example`. Copy this to `ky-rpz.config` and update the paths.


| Variable | Usage | Default
| --- | --- | --- |
| TEMPDIR | Temporary working dir, we suggest "/tmp" | `./tmp` |
| OUTPUTDIR | Place where files are put after processing | `./output` |
| ZONEFILEDIR | Where your zone files live | `/etc/bind/` |
| NAMEDCONFIG | The named.config filename you want to use (and add to BIND config) | `named.conf.ky-rpz` |
| DBFILE | The name of the zone file (in case of collisions) | `db.ky-rpz`
| SQUIDBLACKLIST | The location of a squid blacklist. If you don't use squid, set it to /dev/null | `/etc/squid/ky-rpz.acl` |
| FORWARDERS | A semicolon-delimited list of upstream forwarders to connect to, eg "192.168.2.1;8.8.8.8" | "" (disabled) |


## BIND Configuration

You'll need to enable the `response-policy` option in BIND. This requires version 9.9 and above. Add this line to `/etc/bind/named.conf.options` inside the existing squiggly braces: `response-policy { zone "rpz.blacklist"; };`

Make sure you add the blacklist zone file to your config. For example, I added `include "/etc/bind/named.conf.ky-rpz";` to `/etc/bind/named.conf.local` on a Debian machine.

# Docker Image

## Building the image (necessary if you want custom options or upstream forwarders 

Set your configuration variables in `conf/env.env` (an example is in `conf/env.env.example`) and run `build.sh`.

## Setting custom forwarders

Put an entry in `conf/env.env`


## Running it

To spin up a new instance: `docker run --name "ky-rpz" -p 53:53/udp -p 53:53 --rm yaleman/ky-rpz`

To force an update of the definitions (should happen hourly in cron): `docker exec -it ky-rpz /opt/ky-rpz/bin/update.sh`

## Squid blocking

Below is a section of the default configuration file from Ubuntu's squid package (`/etc/squid/squid.conf`). We've added the kyrpz block to the top, just below the "INSERT YOUR OWN RULES" section. Do this yourself, and it'll do the needful.

```
#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#
acl kyrpz dstdomain "/etc/squid/ky-rpz.acl"
http_access deny kyrpz

# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed
#http_access allow localnet
http_access allow localhost
# And finally deny all other access to this proxy
http_access deny all
```

# TODO

* Test in production
* Support a variable for "only leave these in the output dir"
* Make the caching better

# References

* https://dnsrpz.info/

# Thanks to

* http://www.malwaredomains.com/
* https://pgl.yoyo.org/as/#about
* https://abuse.ch


