# Multi-stage Dockerfile for Aprx APRS Gateway & Digipeater
# Supports multi-arch: linux/amd64, linux/arm64, linux/arm/v7

FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    perl \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN ./configure --prefix=/usr --sysconfdir=/etc && \
    make

FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="Aprx" \
      org.opencontainers.image.description="Advanced Amateur Radio APRS IGate & Digipeater" \
      org.opencontainers.image.url="https://github.com/9M2PJU/aprx" \
      org.opencontainers.image.source="https://github.com/9M2PJU/aprx" \
      org.opencontainers.image.licenses="BSD-3-Clause"

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    ca-certificates \
    tzdata \
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/aprx /usr/sbin/aprx
COPY --from=builder /src/aprx-stat /usr/bin/aprx-stat
COPY --from=builder /src/aprx.conf.in /etc/aprx.conf.default
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/sbin/aprx /usr/bin/aprx-stat && \
    mkdir -p /var/log/aprx /etc

VOLUME ["/etc/aprx.conf", "/var/log/aprx"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["-d"]
