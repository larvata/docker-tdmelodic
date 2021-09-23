FROM alpine:3.14.2 as build

ENV MECAB_SRC https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE

RUN apk add --no-cache bash curl openssl wget sudo autoconf automake build-base &&\
  wget -q -O - $MECAB_SRC | tar -xzf - -C /tmp &&\
  cd /tmp/mecab-[0-9]* &&\
  ./configure &&\
  make &&\
  make check &&\
  make install

COPY mecab-unidic-neologd /workspace
WORKDIR /workspace
RUN ./libexec/install-mecab-unidic_kana-accent.sh
RUN yes yes | ./bin/install-tdmelodic --prefix `mecab-config --dicdir`/tdmelodic
WORKDIR /
RUN rm -rf /workspace


