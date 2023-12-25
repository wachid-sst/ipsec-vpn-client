FROM ubuntu:22.04
LABEL maintainer="wachid <email@wachid.web.id>"

WORKDIR /opt/src

RUN apt-get -y update \
    && apt-get -y install nano strongswan xl2tpd net-tools rsyslog

COPY ./docker-entrypoint.sh /opt/src/docker-entrypoint.sh
RUN chmod 755 /opt/src/docker-entrypoint.sh

VOLUME ["/lib/modules"]

#CMD ["/opt/src/run.sh"]
ENTRYPOINT ["/opt/src/docker-entrypoint.sh"]

#CMD ["/bin/bash"]
