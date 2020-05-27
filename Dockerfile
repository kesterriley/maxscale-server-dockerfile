FROM centos:centos7

#################################################################################
# PLEASE NOTE YOU MUST HAVE AN ENTERPRISE MARIADB LICENSE FOR THIS INSTALLATION #
#################################################################################

ENV MARIADB_SERVER_VERSION 10.4

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="maxscale-server" \
      org.label-schema.description="MariaDB 10.4 MaxScale" \
      org.label-schema.url="https://mariadb.com/kb/en/mariadb-1040-release-notes/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/kesterriley/mariadb-server-dockerfile" \
      org.label-schema.vendor="Kester Riley" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      maintainer="Kester Riley <kesterriley@hotmail.com>" \
      architecture="AMD64/x86_64" \
      mariadbVersion=$MARIADB_SERVER_VERSION

COPY entrypoint.sh /entrypoint.sh
COPY ./bin/*.sh /usr/local/bin/

RUN set -x \
  && yum update -y \
  && yum install -y epel-release \
  && yum install -y \
          wget \
          netcat \
          pigz \
          pv \
          iproute \
          socat \
          bind-utils \
          pwgen \
          psmisc \
          which \
  && curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version="mariadb-$MARIADB_SERVER_VERSION" \
  && yum install -y \
          maxscale \
          MariaDB-client \
  && yum clean all \
  && chmod g=u /etc/passwd \
  && chmod +x entrypoint.sh \
  && chmod -R g=u /var/{lib,run,cache}/maxscale \
  && chgrp -R 0 /var/{lib,run,cache}/maxscale \
  && chmod -R 777 /usr/local/bin/*.sh

USER 1001

ENTRYPOINT ["/entrypoint.sh"]

CMD ["maxscale", "--nodaemon", "--log=stdout"]

ENV MAXSCALE_USER=maxscale \
    READ_WRITE_LISTEN_ADDRESS=127.0.0.1 \
    READ_WRITE_PORT=3307 \
    READ_WRITE_PROTOCOL=MariaDBClient \
    MASTER_ONLY_LISTEN_ADDRESS=127.0.0.1 \
    MASTER_ONLY_PORT=3306 \
    MASTER_ONLY_PROTOCOL=MariaDBClient \
    BINLOG_PORT=3308 \
    BINLOG_PROTOCOL=MariaDBClient \
    MONITOR_USER=maxscale-monitor \
    AUTH_CONNECT_TIMEOUT=10 \
    AUTH_READ_TIMEOUT=10 \
    DB1_PORT=3306 \
    DB2_PORT=3306 \
    DB3_PORT=3306 \
    DB1_PRIO=1 \
    DB2_PRIO=2 \
    DB3_PRIO=3 \
    MAX_PASSIVE=false \
    MAX_SERVER=default
