FROM ubuntu:16.04
LABEL maintainer="Hosting Me <hello@hostingme.co.uk>"

ARG STAYTUS_VERSION="main"
ENV DEBIAN_FRONTEND="noninteractive" TZ="Etc/UTC" TINI_VERSION="v0.19.0"

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN chmod +x /tini && \
    apt-get -q update && \
    apt-get -q install -y tzdata ruby ruby-dev ruby-json nodejs git nginx nano build-essential \
        libmysqlclient-dev mysql-client && \
    ln -fs "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
    gem update --system && \
    gem install bundler:1.17.2 procodile json:1.8.3 && \
    mkdir -p /opt/staytus && \
    useradd -r -d /opt/staytus -m -s /bin/bash staytus && \
    chown staytus:staytus /opt/staytus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER staytus

RUN git clone https://github.com/HostingMe/Staytus.git /opt/staytus/staytus && \
    cd /opt/staytus/staytus && \
    git checkout "${STAYTUS_VERSION}" && \
    bundle install --deployment --without development:test

USER root

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

USER staytus

EXPOSE 8787

ENTRYPOINT ["/tini", "--", "/usr/local/bin/entrypoint.sh"]
