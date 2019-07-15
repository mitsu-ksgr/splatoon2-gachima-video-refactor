Splatoon2 - ガチマ動画リファクタ
=============================

無編集なガチマ動画を色々アレして、試合部分だけを抜き出した動画にします.

ガチマ動画を色々アレする部分は [nozzzzzzz/analyze-splatoon2](https://github.com/nozzzzzzz/analyze-splatoon2) を元にしています.

### 注意
マシンパワーをがっつり使う感じで実装していますので、ノートPCとかだと大分厳しい可能性があります.
開発・テストのマシンはイカのスペックのものを使用しています.

```
OS: Debian GNU/Linux 9.9 (stretch) x86_64
CPU: AMD Ryzen Threadripper 2950X 16- (32) @ 3.5GHz 
GPU: NVIDIA NVIDIA Corporation Device 1b06 
```

### インストール
git pull してよしなに使ってください.
```sh
$ git clone --recursive git@github.com:mitsu-ksgr/splatoon2-gachianalyzer.git
$ cd splatoon2-gachianalyzer
```

### 使い方
```sh
$ ./refactor.sh -b [無編集なガチマ動画のパス] [出力ファイル名]

# 例
$ ./refactor.sh -b ~/recording/2019-06-05_02-47-08.flv ./output.flv
```
