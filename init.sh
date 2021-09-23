#!/usr/bin/env bash

echo "- 01 Prepare tdmelodic"
if [[ ! -d mecab-unidic-neologd ]]; then
    echo "Clone tdmelodic"
    git clone --depth 1 https://github.com/PKSHATechnology-Research/tdmelodic
fi
cd tdmelodic && git pull --depth 1 && cd -


echo "- 02 Prepare mecab-unidic-neologd"
if [[ ! -d mecab-unidic-neologd ]]; then
    # git repository is not exits
    echo "Clone mecab-unidic-neologd..."
    git clone --depth 1 https://github.com/neologd/mecab-unidic-neologd/
fi
cd mecab-unidic-neologd && git pull --depth 1 && cd -


mkdir cache 2> /dev/null
if [[ ! -f cache/unidic-mecab_kana-accent-2.1.2_src.zip ]]; then
  echo "Download unidic-mecab_kana-accent-2.1.2_src"
  cd cache
  wget https://unidic.ninjal.ac.jp/unidic_archive/cwj/2.1.2/unidic-mecab_kana-accent-2.1.2_src.zip
  cd -
fi

cp -f cache/unidic-mecab_kana-accent-2.1.2_src.zip tdmelodic
# cd tdmelodic
# docker build --build-arg https_proxy=http://192.168.1.137:8119 --squash -t tdmelodic:latest .
# cd -

echo "- Prepare dict"
unxz -k `ls mecab-unidic-neologd/seed/*.xz | tail -n 1`

if [[ ! -f cache/neologd_modified.csv ]]; then
  echo "- Apply patch"
  docker run -v $(pwd):/root/workspace -v $(pwd)/cache:/root/workspace/cache tdmelodic:latest \
      tdmelodic-neologd-preprocess \
      --input `ls mecab-unidic-neologd/seed/mecab-unidic-user-dict-seed*.csv | tail -n 1` \
      --output cache/neologd_modified.csv
fi


if [[ ! -f cache/tdmelodic_original.csv ]]; then
  echo "- Inference"
  docker run -v $(pwd):/root/workspace -v $(pwd)/cache:/root/workspace/cache tdmelodic:latest \
      tdmelodic-convert \
      -m unidic \
      --input cache/neologd_modified.csv \
      --output cache/tdmelodic_original.csv

  echo "sleep 30 seconds, waiting for tdmelodic_original.csv fully saved."
  sleep 30
fi


if [[ ! -f cache/tdmelodic.csv ]]; then
  echo "- Postprocess"
  docker run -v $(pwd):/root/workspace -v $(pwd)/cache:/root/workspace/cache tdmelodic:latest \
      tdmelodic-modify-unigram-cost \
      --input cache/tdmelodic_original.csv \
      --output cache/tdmelodic.csv
fi

# cp ${WORKDIR}/tdmelodic_original.csv ${WORKDIR}/tdmelodic.csv # backup

# cp ${WORKDIR}/tdmelodic.csv ${WORKDIR}/tdmelodic.csv.bak

if [[ ! -d mecab-unidic-neologd/build ]]; then
  echo "- Generate installer scripts"
  docker run -v $(pwd):/root/workspace -v $(pwd)/cache:/root/workspace/cache -v $(pwd)/docker:/root/workspace/scripts tdmelodic:latest \
    /root/workspace/scripts/gen_installer.sh \
    --neologd /root/workspace/mecab-unidic-neologd \
    --unidic /root/workspace/cache/unidic-mecab_kana-accent-2.1.2_src.zip \
    --dictionary /root/workspace/cache/tdmelodic.csv

    mv mecab-unidic-neologd/build/unidic-mecab_kana-accent-2.1.2_src.zip mecab-unidic-neologd/
    chmod +x mecab-unidic-neologd/bin/*
    chmod +x mecab-unidic-neologd/libexec/*
fi



# docker run \
#   -v $(pwd)/mecab-unidic-neologd:/root/workspace/mecab-unidic-neologd \
#   -v $(pwd)/cache:/root/workspace/cache \
#   -v $(pwd)/docker:/root/workspace/script \
#   tdmelodic:latest script/prepare-dict.sh

# echo "-0 Build tdmelodic"
# cd tdmelodic
# docker build --build-arg https_proxy=http://192.168.1.137:8119 --squash -t tdmelodic:latest .
