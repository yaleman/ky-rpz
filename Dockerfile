# Basic bind server using the ky-rpz thing.

FROM debian

LABEL maintainer="James Hodgkinson <james@terminaloutcomes.com>"

# expose DNS ports
EXPOSE 53
EXPOSE 53/udp

# do the updates and the installs
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install bind9 git wget sudo cron

# download ky-rpz
RUN git clone https://github.com/yaleman/ky-rpz.git /opt/ky-rpz
RUN chmod +x /opt/ky-rpz/scripts/ky-rpz.sh

# copy the ky-rpz configuration file over
ADD configs/ky-rpz.config /opt/ky-rpz/ky-rpz.config

# bind config files
ADD configs/named.conf.local /etc/bind/
ADD named.conf.options /etc/bind/

# startup script
ADD scripts/startup.sh /opt/startup
RUN chmod +x /opt/startup

# update script
ADD scripts/update.sh /opt/update
RUN chmod +x /opt/update

RUN ln -s /opt/update /etc/cron.hourly/ky-rpz
RUN chmod a-w /etc/cron.hourly/ky-rpz

# make this because well, we haven't installed squid and it's just easier.
RUN mkdir /etc/squid/

# clear out stale files
RUN apt-get -y autoremove
RUN apt-get clean

RUN rm -rf /tmp/*

CMD ["/opt/startup"]
