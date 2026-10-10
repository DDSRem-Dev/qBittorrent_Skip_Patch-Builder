FROM alpine:3.24

RUN apk upgrade && \
   apk add --no-cache --virtual .build \
      build-base \
      boost-dev \
      cmake \
      curl \
      linux-headers \
      musl-dev \
      openssl-dev \
      python3-dev \
      py3-setuptools \
      samurai \
      tar \
      git && \
   mkdir -p /tmp/libtorrent-rasterbar && \
   cd /tmp/libtorrent-rasterbar && \
   git clone -b RC_1_2 https://github.com/DDSRem-Dev/libtorrent-fast-hash-check.git /tmp/libtorrent-rasterbar && \
   CXXFLAGS="$CXXFLAGS -O2 -DNDEBUG -flto=auto" cmake \
      -DCMAKE_BUILD_TYPE=None \
      -DCMAKE_CXX_STANDARD=17 \
      -Dbuild_tests=OFF \
      -Dpython-bindings=OFF \
      -Dpython-egg-info=OFF \
      -Bbuild \
      -GNinja && \
   cmake --build build && \
   cmake --install build && \
   ls -al /usr/local/lib && \
   run_deps="$(scanelf -nB /usr/local/lib/libtorrent-rasterbar* | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | xargs -r apk info -e | sort -u)" && \
   apk del --purge .build && \
   apk add --no-cache $run_deps && \
   rm -rf /tmp/* /var/cache/apk/*
