FROM ubuntu:jammy
LABEL maintainer="wachid <email@wachid.web.id>"

RUN apt-get -y update \
    && apt-get -y install nano strongswan xl2tpd net-tools rsyslog

COPY ./run.sh /opt/src/run.sh
RUN chmod 755 /opt/src/run.sh

VOLUME ["/lib/modules"]

CMD ["/opt/src/run.sh"]
