FROM ubuntu:16.04

ARG BUILD_DATE="N/A"
ARG REVISION="N/A"

ARG STAYTUS_VERSION="main"
ARG TZ="UTC"

LABEL org.opencontainers.image.authors="Hosting Me <hello@hostingme.co.uk>" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.title="HostingMe/Staytus" \
    org.opencontainers.image.description="[HostingMe/Staytus](https://github.com/HostingMe/Staytus.git) as a Docker image without the MySQL server." \
    org.opencontainers.image.documentation="https://github.com/HostingMe/Staytus/README.md" \
    org.opencontainers.image.url="https://github.com/HostingMe/Staytus" \
    org.opencontainers.image.source="https://github.com/HostingMe/Staytus" \
    org.opencontainers.image.revision="${REVISION}" \
    org.opencontainers.image.vendor="HostingMe" \
    org.opencontainers.image.version="${STAYTUS_VERSION}"

ENV TZ="${TZ}" TINI_VERSION="v0.19.0"

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN chmod +x /tini && \
    apt-get -q update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y tzdata ruby ruby-dev ruby-json \
        nodejs git build-essential libmysqlclient-dev mysql-client sendmail && \
    ln -fs "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
    gem update rubygems && \
    gem install bundler:1.13.6 procodile json:1.8.3 && \
    mkdir -p /opt/staytus && \
    useradd -r -d /opt/staytus -m -s /bin/bash staytus && \
    chown staytus:staytus /opt/staytus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

USER staytus

RUN git clone https://github.com/HostingMe/Staytus.git /opt/staytus/staytus && \
    cd /opt/staytus/staytus && \
    git checkout "${STAYTUS_VERSION}" && \
    bundle install --deployment --without development:test

EXPOSE 8787

ENTRYPOINT ["/tini", "--", "/usr/local/bin/entrypoint.sh"]
