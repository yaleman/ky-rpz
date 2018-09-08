# Basic bind server using the ky-rpz thing.

FROM debian

LABEL maintainer="James Hodgkinson <james@terminaloutcomes.com>"

# expose DNS ports
EXPOSE 53
EXPOSE 53/udp

# do the updates and the installs
RUN apt-get update 
#RUN apt-get -y upgrade
RUN apt-get -y install bind9 git wget sudo cron

RUN mkdir -p /opt/ky-rpz
# copy over ky-rpz
ADD bin/ /opt/ky-rpz/bin
ADD conf/ /opt/ky-rpz/conf
ADD templates/ /opt/ky-rpz/templates

RUN mkdir -p /var/run/named
RUN chown bind:bind /var/run/named
# add executable bit to scripts
RUN chmod +x /opt/ky-rpz/bin/*.sh

# make the docker config the production one
RUN ln -s /opt/ky-rpz/conf/ky-rpz.config.docker /opt/ky-rpz/conf/ky-rpz.config

# bind config files
RUN rm /etc/bind/named.conf.local
RUN rm /etc/bind/named.conf.options
RUN ln -s /opt/ky-rpz/conf/named.conf.local /etc/bind/named.conf.local
RUN ln -s /opt/ky-rpz/conf/named.conf.options.example /etc/bind/named.conf.options

# cron's important
RUN ln -s /opt/ky-rpz/bin/update.sh /etc/cron.hourly/ky-rpz
RUN chmod a-w /etc/cron.hourly/ky-rpz

# make this because well, we haven't installed squid and it's just easier.
RUN mkdir /etc/squid/

# clear out stale files
RUN apt-get -y autoremove
RUN apt-get clean

RUN rm -rf /tmp/*

CMD ["/opt/ky-rpz/bin/startup.sh"]
