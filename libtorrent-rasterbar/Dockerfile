FROM alpine:3.23

ARG JNPROC=4

RUN apk add --no-cache --virtual .build \
      boost-dev \
      openssl-dev \
      cmake \
      g++ \
      samurai \
      curl \
      tar \
      git && \
   mkdir -p /tmp/libtorrent-rasterbar && \
   cd /tmp/libtorrent-rasterbar && \
   git clone -b RC_1_2 https://github.com/DDSRem-Dev/libtorrent-fast-hash-check.git /tmp/libtorrent-rasterbar && \
   cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=17 \
      -DBUILD_SHARED_LIBS=ON \
      -Brelease \
      -GNinja && \
   cd release && \
   ninja -j${JNPROC} && \
   ninja install && \
   ls -al /usr/local/lib && \
   run_deps="$(scanelf -nB /usr/local/lib/libtorrent-rasterbar* | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | xargs -r apk info -e | sort -u)" && \
   apk del --purge .build && \
   apk add --no-cache $run_deps && \
   rm -rf /tmp/* /var/cache/apk/*