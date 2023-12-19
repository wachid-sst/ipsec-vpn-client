FROM ubuntu:22.04
LABEL maintainer="wachid <email@wachid.web.id>"

WORKDIR /opt/src

RUN apt update -y && apt install network-managerl2tp

COPY ./run.sh /opt/src/run.sh
RUN chmod 755 /opt/src/run.sh

VOLUME ["/lib/modules"]

#CMD ["/opt/src/run.sh"]
ENTRYPOINT ["/opt/src/entrypoint.sh"]

#CMD ["/bin/bash"]
