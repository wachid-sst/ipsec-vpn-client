FROM ubuntu:22.04
LABEL maintainer="wachid <email@wachid.web.id>"

WORKDIR /opt/src

RUN apt update -y && DEBIAN_FRONTEND=noninteractive apt install apt-utils -y && apt install network-managerl2tp -y

COPY --chmod=0755  ./entrypoint.sh /opt/src/entrypoint.sh
#RUN chmod 755 /opt/src/run.sh

VOLUME ["/lib/modules"]

#CMD ["/opt/src/run.sh"]
ENTRYPOINT ["/opt/src/entrypoint.sh"]

#CMD ["/bin/bash"]
