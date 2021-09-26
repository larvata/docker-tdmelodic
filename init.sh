#!/usr/bin/env bash

TDMELODIC_DIR=tdmelodic
MECAB_DIC_DIR=mecab-unidic-neologd
UNIDIC_ZIP=unidic-mecab_kana-accent-2.1.2_src.zip


if [[ ! -z $http_proxy ]]; then
  DOCKER_BUILD_PROXY="--build-arg http_proxy=$http_proxy "
fi

if [[ ! -z $https_proxy ]]; then
  DOCKER_BUILD_PROXY+="--build-arg https_proxy=$https_proxy"
fi


echo "- 01 Prepare tdmelodic"
if [[ ! -d $MECAB_DIC_DIR ]]; then
  git clone --depth 1 https://github.com/PKSHATechnology-Research/tdmelodic
fi
(cd $TDMELODIC_DIR && git pull --depth 1)


echo "- 02 Prepare mecab-unidic-neologd"
if [[ ! -d $MECAB_DIC_DIR ]]; then
    git clone --depth 1 https://github.com/neologd/mecab-unidic-neologd/
fi
(cd $MECAB_DIC_DIR && git pull --depth 1)


echo "- 03 Download unidic-mecab_kana-accent-2.1.2_src"
mkdir cache 2> /dev/null
if [[ ! -f cache/$UNIDIC_ZIP ]]; then
  (cd cache &&  wget https://unidic.ninjal.ac.jp/unidic_archive/cwj/2.1.2/unidic-mecab_kana-accent-2.1.2_src.zip)
fi


echo "- 04 Copy unidic-mecab_kana-accent-2.1.2_src"
cp -f cache/$UNIDIC_ZIP $TDMELODIC_DIR
cp -f cache/$UNIDIC_ZIP $MECAB_DIC_DIR


echo "- 05 Build tdmelodic"
(cd tdmelodic && docker build $DOCKER_BUILD_HTTP $DOCKER_BUILD_HTTPS -t tdmelodic:latest .)


echo "- 06 Prepare dict"
unxz -k `ls $MECAB_DIC_DIR/seed/*.xz | tail -n 1` 2> /dev/null


echo "- 07 Apply patch"
if [[ ! -f cache/neologd_modified.csv ]]; then
  docker run --rm \
    -v $(pwd)/$MECAB_DIC_DIR:/root/workspace/$MECAB_DIC_DIR \
    -v $(pwd)/cache:/root/workspace/cache tdmelodic:latest \
      tdmelodic-neologd-preprocess \
      --input `ls mecab-unidic-neologd/seed/mecab-unidic-user-dict-seed*.csv | tail -n 1` \
      --output cache/neologd_modified.csv
fi


echo "- 08 Inference"
if [[ ! -f cache/tdmelodic_original.csv ]]; then
  docker run --rm \
    -v $(pwd)/cache:/root/workspace/cache tdmelodic:latest \
    tdmelodic-convert \
      -m unidic \
      --input cache/neologd_modified.csv \
      --output cache/tdmelodic_original.csv
fi


echo "- 09 Postprocess"
if [[ ! -f cache/tdmelodic.csv ]]; then
  docker run --rm \
    -v $(pwd)/cache:/root/workspace/cache tdmelodic:latest \
    tdmelodic-modify-unigram-cost \
      --input cache/tdmelodic_original.csv \
      --output cache/tdmelodic.csv
fi


echo "- 10 Generate installer scripts"
if [[ ! -d mecab-unidic-neologd/build22 ]]; then
  docker run --rm \
    -v $(pwd)/$MECAB_DIC_DIR:/root/workspace/$MECAB_DIC_DIR \
    -v $(pwd)/cache:/root/workspace/cache \
    -v $(pwd)/docker:/root/workspace/scripts tdmelodic:latest \
    /root/workspace/scripts/gen_installer.sh \
      --neologd /root/workspace/mecab-unidic-neologd \
      --unidic /root/workspace/cache/unidic-mecab_kana-accent-2.1.2_src.zip \
      --dictionary /root/workspace/cache/tdmelodic.csv

    chmod +x mecab-unidic-neologd/bin/*
    chmod +x mecab-unidic-neologd/libexec/*
fi


echo "- 11 Build mecab-tdmelodic-lite"
docker build --squash $DOCKER_BUILD_HTTP $DOCKER_BUILD_HTTPS -t mecab-tdmelodic-lite .
