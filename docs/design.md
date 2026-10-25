# 設計メモ

## バージョン: 26.1.2 + ViaVersion

サーバー本体は 26.1.2 に固定している。サードパーティ製のクライアント（ライブラリ）は新しい版への対応が遅れることがあり、最新版にすると接続できなくなる場合があるため。

人間が使う公式クライアントは常に最新になるので、ViaVersion で新しいクライアントからの接続を受け付ける。ViaVersion は「新しいクライアント → 古いサーバー」の変換だけを行う。

26.1.2 は Paper のサポートが終わっている（起動時に「4 release(s) behind」と警告が出る）。LAN 内だけで使う前提なので許容している。

## 認証なし (online-mode=false)

アカウントを持たないクライアントも接続できるようにするため、Mojang/Microsoft の認証を切っている。その代わり:

- 誰でも任意の名前を名乗れる。**インターネットに公開しない**（ポート開放やトンネルをしない）
- ホワイトリスト (`white-list=true`, `enforce-whitelist=true`) を必須にする
- OP は最小限にする
- スキンは表示されない（全員デフォルトスキン）

外部の人を呼ぶ場合は、`online-mode=true` に戻すか、Velocity などのプロキシで認証を挟む構成に変える必要がある。

## RCON

`enable-rcon=true`。Minecraft の RCON は待ち受けアドレスを選べないので LAN 側にも開く。パスワードは install.sh が初回に乱数で生成し、`server.properties`（パーミッション 600）にだけ保存する。外から使う必要がなければ、ファイアウォールで 25575 を閉じてよい。

## ゲーム設定

| 設定 | 値 | 理由 |
|---|---|---|
| difficulty | easy | 敵ありのサバイバル。ただし序盤で詰まないように |
| keep_inventory | true | 死んでも持ち物を失わない |
| spawn-protection | 0 | OP 以外もスポーン付近で建築できるように |
| view-distance / simulation-distance | 8 / 6 | CPU とメモリの節約 |

## JVM

Paper が推奨する G1 のフラグ（Aikar's flags）をそのまま使う。`-Xms` と `-Xmx` を同じ値にして `AlwaysPreTouch` で最初に確保する。
