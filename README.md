# minecraft-server

LAN 内で使う Minecraft Java Edition サーバー（[Paper](https://papermc.io/)）を、1コマンドで建てて運用するためのリポジトリ。

- Paper **1.21.4** に固定。[ViaVersion](https://modrinth.com/plugin/viaversion) 同梱で、**26.3 など新しいクライアントからもそのまま接続できる**
- `online-mode=false`（アカウント認証なし）+ ホワイトリスト必須。**インターネットには公開しない前提**
- 難易度イージー / サバイバル / `keepInventory` オン
- systemd で常駐、毎朝 5:00 (JST) にワールドを自動バックアップ（7世代）
- RCON は 127.0.0.1 から `bin/mc-cmd` で操作。パスワードはサーバー上で生成し、リポジトリには入らない

## 必要なもの

- Debian 13 または Ubuntu 24.04 以降（Java 25 が apt で入るもの）
- CPU 2〜4 コア、メモリ 8GB（ヒープ 6GB）、ディスク 20GB 程度
- [Minecraft EULA](https://www.minecraft.net/eula) への同意

## 建て方

手元から SSH で送り込む場合:

```sh
bin/deploy root@<サーバーのIP> --accept-eula
```

サーバー上で直接やる場合:

```sh
git clone https://github.com/Satoru314/minecraft-server /opt/minecraft-server
ACCEPT_EULA=yes /opt/minecraft-server/install.sh
```

`--accept-eula` / `ACCEPT_EULA=yes` は Minecraft EULA に同意したという意味。初回だけ必要。

## 入り方

1. サーバーでホワイトリストに名前を足す: `/opt/minecraft-server/bin/mc-cmd whitelist add <名前>`
2. マイクラ（Java 版、1.21.4 以降ならどれでも）→ マルチプレイ → サーバーを追加 → `<サーバーのIP>`（ポート 25565）

## ドキュメント

- [docs/operations.md](docs/operations.md) — 日常の操作（コマンド、ホワイトリスト、バックアップと復元、バージョン更新）
- [docs/design.md](docs/design.md) — 設定の理由と注意点

## 構成

```
install.sh                       インストール（何度実行してもよい）
versions.env                     Paper / ViaVersion のバージョンとチェックサム
config/server.properties.managed install.sh が毎回反映する server.properties の項目
config/gamerules.txt             起動のたびに適用するゲームルール
config/minecraft.default         /etc/default/minecraft の初期値（ヒープサイズ）
bin/mc-cmd                       RCON でコマンドを送る
bin/mc-apply-gamerules           gamerules.txt を適用（起動時に自動実行）
bin/mc-backup                    ワールドのバックアップ
bin/deploy                       手元から rsync + install.sh
systemd/                         サービスとバックアップのタイマー
```

サーバー上の配置: コード `/opt/minecraft-server`、データ `/srv/minecraft/server`、バックアップ `/srv/minecraft/backups`。
