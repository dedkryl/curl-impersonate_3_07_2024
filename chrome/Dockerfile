# Python is needed for building libnss.
# Use it as a common base.
FROM python:3.11-slim-bookworm as builder

WORKDIR /build

# Common dependencies
RUN apt-get update && \
    apt-get install -y git ninja-build cmake curl zlib1g-dev

# The following are needed because we are going to change some autoconf scripts,
# both for libnghttp2 and curl.
RUN apt-get install -y autoconf automake autotools-dev pkg-config libtool

# Dependencies for downloading and building nghttp2
RUN apt-get install -y bzip2

# Dependencies for downloading and building curl
RUN apt-get install -y xz-utils

# Dependencies for downloading and building BoringSSL
RUN apt-get install -y g++ golang-go unzip

# Download and compile libbrotli
ARG BROTLI_VERSION=1.0.9
RUN curl -L https://github.com/google/brotli/archive/refs/tags/v${BROTLI_VERSION}.tar.gz -o brotli-${BROTLI_VERSION}.tar.gz && \
    tar xf brotli-${BROTLI_VERSION}.tar.gz
RUN cd brotli-${BROTLI_VERSION} && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=./installed .. && \
    cmake --build . --config Release --target install

# Get BoringSSL from own branch.
RUN curl -L -O https://github.com/dedkryl/boringssl_3_07_2024/archive/ci_03_07_2024_2.zip && \
        mv ci_03_07_2024_2.zip  boringssl.zip && \
        unzip -q -o boringssl.zip && \
        mv boringssl_3_07_2024-ci_03_07_2024_2 boringssl 

WORKDIR /build/boringssl

RUN mkdir build
RUN mkdir build/lib
# Compile BoringSSL.
# See https://boringssl.googlesource.com/boringssl/+/HEAD/BUILDING.md
RUN cd build && \
        cmake \
        -DCMAKE_C_FLAGS="-Wno-error=array-bounds -Wno-error=stringop-overflow" \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=on -GNinja .. && \
        ninja

# Fix the directory structure so that curl can compile against it.
# See https://everything.curl.dev/source/build/tls/boringssl
RUN ln -s /build/boringssl/build/crypto/libcrypto.a /build/boringssl/build/lib/libcrypto.a && \
    ln -s /build/boringssl/build/ssl/libssl.a /build/boringssl/build/lib/libssl.a && \
    cp -R /build/boringssl/include /build/boringssl/build/include
    

WORKDIR /build

ARG NGHTTP2_VERSION=nghttp2-1.56.0
ARG NGHTTP2_URL=https://github.com/nghttp2/nghttp2/releases/download/v1.56.0/nghttp2-1.56.0.tar.bz2

# Download nghttp2 for HTTP/2.0 support.
RUN curl -o ${NGHTTP2_VERSION}.tar.bz2 -L ${NGHTTP2_URL}
RUN tar xf ${NGHTTP2_VERSION}.tar.bz2

# Compile nghttp2
RUN cd ${NGHTTP2_VERSION} && \
    ./configure --prefix=/build/${NGHTTP2_VERSION}/installed --with-pic --disable-shared && \
    make && make install

WORKDIR /build    

# Download curl from own branch (8.1.1 patched already).
RUN curl -L -O  https://github.com/dedkryl/curl_3_07_2024/archive/refs/heads/ci_3_07_2024.zip && \
            mv ci_3_07_2024.zip  curl-8.1.1.zip && \
            rm -Rf curl-8.1.1 && \
            unzip -q -o curl-8.1.1.zip && \
            mv curl_3_07_2024-ci_3_07_2024 curl-8.1.1 && \
            cd curl-8.1.1	&& \
            autoreconf -fi

# Compile curl with nghttp2, libbrotli and nss (firefox) or boringssl (chrome).
# Enable keylogfile for debugging of TLS traffic.
RUN cd curl-8.1.1 && \
    ./configure --prefix=/build/install \
                --enable-static \
                --disable-shared \
                --enable-websockets \
                --with-nghttp2=/build/${NGHTTP2_VERSION}/installed \
                --with-brotli=/build/brotli-${BROTLI_VERSION}/build/installed \
                --with-openssl=/build/boringssl/build \
                LIBS="-pthread" \
                CFLAGS="-I/build/boringssl/build" \
                USE_CURL_SSLKEYLOGFILE=true && \
                make && make install

                RUN mkdir out && \
                cp /build/install/bin/curl-impersonate-chrome out/ && \
                ln -s curl-impersonate-chrome out/curl-impersonate && \
                strip out/curl-impersonate
            
            # Verify that the resulting 'curl' has all the necessary features.
            RUN ./out/curl-impersonate -V | grep -q zlib && \
                ./out/curl-impersonate -V | grep -q brotli && \
                ./out/curl-impersonate -V | grep -q nghttp2 && \
                ./out/curl-impersonate -V | grep -q -e NSS -e BoringSSL && \
                ./out/curl-impersonate -V | grep -q -e wss
            
            # Verify that the resulting 'curl' is really statically compiled
            RUN ! (ldd ./out/curl-impersonate | grep -q -e libcurl -e nghttp2 -e brotli -e ssl -e crypto)
            
            RUN rm -Rf /build/install
            
            # Re-compile libcurl dynamically
            RUN cd curl-8.1.1 && \
                autoreconf -fi && \
                ./configure --prefix=/build/install \
                            --enable-websockets \
                            --with-nghttp2=/build/${NGHTTP2_VERSION}/installed \
                            --with-brotli=/build/brotli-${BROTLI_VERSION}/build/installed \
                            --with-openssl=/build/boringssl/build \
                            LIBS="-pthread" \
                            CFLAGS="-I/build/boringssl/build" \
                            USE_CURL_SSLKEYLOGFILE=true && \
                make clean && make && make install
            
            # Copy libcurl-impersonate and symbolic links
            RUN cp -d /build/install/lib/libcurl-impersonate* /build/out
            
            RUN ver=$(readlink -f curl-8.1.1/lib/.libs/libcurl-impersonate-chrome.so | sed 's/.*so\.//') && \
                major=$(echo -n $ver | cut -d'.' -f1) && \
                ln -s "libcurl-impersonate-chrome.so.$ver" "out/libcurl-impersonate.so.$ver" && \
                ln -s "libcurl-impersonate.so.$ver" "out/libcurl-impersonate.so" && \
                strip "out/libcurl-impersonate.so.$ver"
            
            # Verify that the resulting 'libcurl' is really statically compiled against its
            # dependencies.
            RUN ! (ldd ./out/curl-impersonate | grep -q -e nghttp2 -e brotli -e ssl -e crypto)
            
            # Wrapper scripts
            COPY curl_chrome* curl_edge* curl_safari* out/
            RUN chmod +x out/curl_*
            
            # Create a final, minimal image with the compiled binaries
            # only.
            FROM debian:bookworm-slim
            RUN apt-get update && apt-get install -y ca-certificates \
                && rm -rf /var/lib/apt/lists/*
            # Copy curl-impersonate from the builder image
            COPY --from=builder /build/out/curl-impersonate* /usr/local/bin
            COPY --from=builder /build/out/libcurl-impersonate* /usr/local/lib
            # Update the loader's cache
            RUN ldconfig
            # Copy to /build/out as well for backward compatibility with previous versions.
            COPY --from=builder /build/out /build/out
            # Wrapper scripts
            COPY --from=builder /build/out/curl_* /usr/local/bin/
            