# docker-tdmelodic

## Usage

```
./init.sh

docker run --rm mecab-tdmelodic-lite bash -c \
  "echo 一昔前は人工知能のプログラミング言語といえばCommon LispやPrologだった。 | \
  mecab -d `mecab-config --dicdir`/tdmelodic/"

```
