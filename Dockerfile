FROM ubuntu:jammy
LABEL maintainer="wachid <email@wachid.web.id>"

#ENV REFRESHED_AT 2018-05-04

#WORKDIR /opt/src

RUN apt-get -yqq update \
    && apt-get install nano strongswan xl2tpd net-tools

COPY ./run.sh /opt/src/run.sh
RUN chmod 755 /opt/src/run.sh

VOLUME ["/lib/modules"]

CMD ["/opt/src/run.sh"]
