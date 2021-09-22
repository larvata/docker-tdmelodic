# FROM tdmelodic:latest

# WORKDIR /tmp

# COPY mecab-unidic-neologd ./mecab-unidic-neologd

# RUN unxz -k `ls mecab-unidic-neologd/seed/*.xz | tail -n 1`

# RUN tdmelodic-neologd-preprocess \
#     --input `ls mecab-unidic-neologd/seed/mecab-unidic-user-dict-seed*.csv | tail -n 1` \
#     --output /tmp/neologd_modified.csv


# RUN tdmelodic-convert \
#     -m unidic \
#     --input /tmp/neologd_modified.csv \
#     --output tdmelodic_original.csv

# RUN ls
