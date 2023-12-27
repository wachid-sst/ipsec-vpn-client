FROM debian:11
LABEL maintainer="wachid <email@wachid.web.id>"

WORKDIR /opt/src

RUN apt update -y && DEBIAN_FRONTEND=noninteractive apt install strongswan rsyslog net-tools -y

COPY --chmod=0755  ./entrypoint.sh /opt/src/entrypoint.sh
#RUN chmod 755 /opt/src/run.sh

VOLUME ["/lib/modules"]

#CMD ["/opt/src/run.sh"]
ENTRYPOINT ["/opt/src/entrypoint.sh"]

#CMD ["/bin/bash"]
