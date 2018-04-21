# KY-RPZ (Kush-Yale RPZ)

A slick and DIY RPZ for people who want to roll their own.

## BIND Configuration

An example configuration file is in `dns-blacklist.config.example`. Copy this to `dns-blacklist.config` and update the paths.

| Variable | Usage |
| --- | --- |
| TEMPDIR | Temporary working dir, we suggest "/tmp" |
| OUTPUTDIR | Place where files are put after processing |
| ZONEFILEDIR | Where your zone files live |
| BLACKLISTZONEFILE | The name of the zone file (in case of collisions) |
| SQUIDBLACKLIST | The location of a squid blacklist. If you don't use squid, just set it to /dev/null |

Make sure you add the blacklist zone file to your config. For example, I added `include "/etc/bind/named.conf.ky-rpz";` to `/etc/bind/named.conf.local` on a Debian machine.

## Squid blocking

Below is a section of the default configuration file from Ubuntu's squid package (`/etc/squid/squid.conf`). We've added the kyrpz block to the top, just below the "INSERT YOUR OWN RULES" section. Do this yourself, and it'll do the needful.

```

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#
acl kyrpz dstdomain "/etc/squid/ky-rpz.acl"
http_access deny bad_url

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