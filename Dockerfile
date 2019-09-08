FROM golang:1.8

ENV SRC               /usr/local
ENV LD_LIBRARY_PATH   ${SRC}/lib
ENV PKG_CONFIG_PATH   ${SRC}/lib/pkgconfig

RUN bash -c 'set -euo pipefail'
RUN apt-get update
RUN apt-get -y install \
  autoconf \
  automake \
  build-essential \
  git \
  libass-dev \
  libgpac-dev \
  libmp3lame-dev \
  libopus-dev \
  libssl-dev \
  libtheora-dev \
  libtool \
  libvorbis-dev \
  openssl \
  pkg-config \
  texi2html \
  wget \
  yasm \
  zlib1g-dev

# fdk-aac
RUN DIR=$(mktemp -d) && cd ${DIR} && \
  git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git && \
  cd fdk-aac && \
  autoreconf -fiv && \
  ./configure --prefix="${SRC}" --disable-shared && \
  make && \
  make install && \
  make distclean && \
  rm -rf ${DIR}

# nasm
RUN DIR=$(mktemp -d) && cd ${DIR} && \
  wget http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.bz2 && \
  tar xjvf nasm-2.13.01.tar.bz2 && \
  cd nasm-2.13.01 && \
  ./autogen.sh && \
  ./configure --prefix="${SRC}" --bindir="${SRC}/bin" && \
  make && \
  make install && \
  make distclean && \
  rm -rf ${DIR}

# libx264
RUN DIR=$(mktemp -d) && cd ${DIR} && \
  git clone git://git.videolan.org/x264.git && \
  cd x264 && \
  ./configure --enable-static --enable-shared && \
  make && \
  make install && \
  ldconfig

# ffmpeg
RUN DIR=$(mktemp -d) && cd ${DIR} && \
  git clone --depth 1 git://source.ffmpeg.org/ffmpeg && \
  cd ffmpeg && \
  ./configure --prefix="${SRC}" --extra-cflags="-I${SRC}/include" --extra-ldflags="-L${SRC}/lib" --bindir="${SRC}/bin" \
    --disable-debug --enable-small \
    --disable-ffplay --disable-ffprobe --disable-ffserver \
    --enable-gpl --enable-version3 --enable-nonfree \
    --enable-openssl \
    --enable-libass --enable-libfdk-aac --enable-libmp3lame --enable-libopus \
    --enable-libtheora --enable-libvorbis --enable-libx264 && \
  make && \
  make install && \
  make distclean && \
  hash -r && \
  rm -rf ${DIR}

RUN apt-get purge -y autoconf automake build-essential libtool make pkg-config yasm zlib1g-dev
RUN apt-get clean
RUN apt-get autoclean

RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/libc.conf

RUN mkdir -p /go/src/app
WORKDIR /go/src/app

CMD ["go-wrapper", "run"]

ONBUILD COPY . /go/src/app
ONBUILD RUN go-wrapper download
ONBUILD RUN go-wrapper install
