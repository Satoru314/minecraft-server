# 運用

コマンドはすべてサーバー上で root として実行する。

## サービス

```sh
systemctl status minecraft
systemctl restart minecraft       # 停止時はワールドを保存してから終了する
journalctl -u minecraft -f        # ログ
```

## RCON でコマンドを送る

```sh
/opt/minecraft-server/bin/mc-cmd list
/opt/minecraft-server/bin/mc-cmd say "こんにちは"
/opt/minecraft-server/bin/mc-cmd time set day
```

## ホワイトリスト

認証なし (`online-mode=false`) なので、**ホワイトリストが唯一の入場制限**。

```sh
/opt/minecraft-server/bin/mc-cmd whitelist add <名前>
/opt/minecraft-server/bin/mc-cmd whitelist remove <名前>
/opt/minecraft-server/bin/mc-cmd whitelist list
```

OP 権限 (`op <名前>`) は名前を名乗るだけで乗っ取れるので、必要なときだけ付けてすぐ外す。

## 設定を変える

- `server.properties` のうち `config/server.properties.managed` にある項目は、install.sh を実行するたびに上書きされる。変えたいならリポジトリ側を直して再実行する
- それ以外の項目は `/srv/minecraft/server/server.properties` を直接編集して `systemctl restart minecraft`
- ゲームルールは `config/gamerules.txt` に書く。起動のたびに適用される
- ヒープサイズは `/etc/default/minecraft` の `MC_HEAP`（install.sh は既存のものを上書きしない）

## バックアップと復元

毎朝 5:00 (JST) に `/srv/minecraft/backups/world-YYYYmmdd-HHMMSS.tar.gz` を作る（7世代、`KEEP` で変更可）。
手動で取る: `/opt/minecraft-server/bin/mc-backup`

復元:

```sh
systemctl stop minecraft
cd /srv/minecraft/server
mv world world.broken            # 念のため残す
tar xzf /srv/minecraft/backups/world-YYYYmmdd-HHMMSS.tar.gz
chown -R minecraft:minecraft world
systemctl start minecraft
```

## バージョンを上げる

1. `versions.env` の URL とチェックサムを書き換える
   - Paper: `https://fill.papermc.io/v3/projects/paper/versions/<版>/builds/latest`
   - ViaVersion: `https://api.modrinth.com/v2/project/viaversion/version`
2. 先に `bin/mc-backup` でバックアップ
3. `bin/deploy root@<host>` か、サーバー上で `install.sh` を再実行

**ワールドは一度新しい版で開くと古い版に戻せない。** サーバーに接続するクライアント（自作 bot など）が新しい版に対応しているか、先に確認すること。
