ARG REPO_VERSION
ARG REPO_NAME
FROM ${REPO_NAME}:${REPO_VERSION} AS builder
RUN apk upgrade \
    && apk add --no-cache \
       boost-dev \
       openssl-dev \
       qt6-qtbase-dev \
       qt6-qttools-dev \
       qt6-qtbase-private-dev \
       g++ \
       cmake \
       curl \
       tar \
       samurai \
    && rm -rf /tmp/* /var/cache/apk/*
ARG QBITTORRENT_VERSION
RUN mkdir -p /tmp/qbittorrent \
    && cd /tmp/qbittorrent \
    && curl -sSL https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-${QBITTORRENT_VERSION}.tar.gz | tar xz --strip-components 1 \
    && cmake \
       -DCMAKE_BUILD_TYPE=Release \
       -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
       -DCMAKE_CXX_STANDARD=20 \
       -DWEBUI=ON \
       -DVERBOSE_CONFIGURE=OFF \
       -DSTACKTRACE=OFF \
       -DDBUS=OFF \
       -DGUI=OFF \
       -DQT6=ON \
       -Brelease \
       -GNinja \
    && cmake --build release -j $(nproc) \
    && cmake --install release \
    && ls -al /usr/local/bin/ \
    && qbittorrent-nox --help
RUN echo "Copy to /out" \
    && strip /usr/local/lib/libtorrent-rasterbar.so.* \
    && strip /usr/local/bin/qbittorrent-nox \
    && mkdir -p /out/usr/lib /out/usr/bin \
    && cp -d /usr/local/lib/libtorrent-rasterbar.so* /out/usr/lib \
    && cp /usr/local/bin/qbittorrent-nox /out/usr/bin
RUN echo "Write dependency version" \
    && apk update \
    && OpenSSL=$(apk version openssl-dev | sed -n '2p' | awk -F'= ' '{print $2}' | awk -F'-' '{print $1}') \
    && Boost=$(apk version boost-dev | sed -n '2p' | awk -F'= ' '{print $2}' | awk -F'-' '{print $1}') \
    && Libtorrent="fast_hash_check_1.2.20" \
    && Qt=$(apk version qt6-qtbase-dev | sed -n '2p' | awk -F'= ' '{print $2}' | awk -F'-' '{print $1}') \
    && zlib=$(apk version zlib | sed -n '2p' | awk -F'= ' '{print $2}' | awk -F'-' '{print $1}') \
    && echo -e '{\n    "OpenSSL": "'$OpenSSL'",\n    "Boost": "'$Boost'",\n    "Libtorrent": "'$Libtorrent'",\n    "Qt": "'$Qt'",\n    "zlib": "'$zlib'"\n}' \
    && echo -e '{\n    "OpenSSL": "'$OpenSSL'",\n    "Boost": "'$Boost'",\n    "Libtorrent": "'$Libtorrent'",\n    "Qt": "'$Qt'",\n    "zlib": "'$zlib'"\n}' > /out/usr/bin/dependency-version.json \
    && rm -rf /tmp/* /var/cache/apk/*

FROM alpine:3.23
ENV QBT_PROFILE=/home/qbittorrent \
    TZ=Asia/Shanghai \
    PUID=1000 \
    PGID=100 \
    WEBUI_PORT=8080 \
    BT_PORT=34567 \
    QB_USERNAME=admin \
    QB_PASSWORD=adminadmin \
    LANG=zh_CN.UTF-8 \
    SHELL=/bin/bash \
    PS1="\u@\h:\w \$ "
RUN apk upgrade \
    && apk add --no-cache \
       bash \
       busybox-suid \
       curl \
       jq \
       openssl \
       python3 \
       qt6-qtbase \
       qt6-qtbase-sqlite \
       shadow \
       su-exec \
       tini \
       tzdata \
    && rm -rf /tmp/* /var/cache/apk/* \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && useradd qbittorrent -u ${PUID} -U -m -d ${QBT_PROFILE} -s /sbin/nologin \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.bfsu.edu.cn/g' /etc/apk/repositories
COPY --from=builder /out /
COPY root /
WORKDIR /data
VOLUME ["/data"]
ENTRYPOINT ["tini", "-g", "--", "entrypoint.sh"]