FROM master01:30500/bronzels/ubu16ssh:0.1
MAINTAINER bronzels <bronzels@hotmail.com>
USER root:root

ARG FLINK_VERSION=1.10.1

COPY flink-${FLINK_VERSION} /opt/flink-${FLINK_VERSION}
RUN ln -s /opt/flink-${FLINK_VERSION} /opt/flink
COPY str_jar /opt/str_jar
ADD flink_com_libfiles.tar.gz /opt/flink/lib
COPY scripts /opt/scripts

ENV FLINK_HOME /opt/flink

RUN apt-get install -y openjdk-8-jdk

WORKDIR $FLINK_HOME

COPY run.sh /root/
EXPOSE 8081

ENTRYPOINT ["/root/run.sh"]
