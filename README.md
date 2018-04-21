# KY-RPZ (Kush-Yale RPZ)

A slick and DIY RPZ for people who want to roll their own.

## Configuration

An example configuration file is in `dns-blacklist.config.example`. Copy this to `dns-blacklist.config` and update the paths.

| Variable | Usage |
| --- | --- |
| TEMPDIR | Temporary working dir, we suggest "/tmp" |
| OUTPUTDIR | Place where files are put after processing |
| ZONEFILEDIR | |
| ZONEDBFILE | Where the bind zone files go |
| SQUIDBLACKLIST | The location of a squid blacklist. If you don't use squid, just set it to /dev/null |

# TODO

* Test in production
* Support a variable for "only leave these in the output dir"
* Make the caching better