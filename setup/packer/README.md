## What is this?

シナリオ試験を実行するためのEC2のAMIを作るpacker

以下のものが含まれています

* Amazon DNSへの負荷を抑えるための、ローカルキャッシュDNSとしてのUnbound
* 負荷試験のためにFile Descriptor不足を解消するためのulimitの拡張
* 負荷試験を実行するためのJava8のインストール

## Requirements

実行する前に `sbt pack` して負荷試験のパッケージングをしておいてください。

## Usage

```bash
# AWS_PROFILEを書き換えて適用。
$ AWS_PROFILE=env setup/packer/builder.sh
```