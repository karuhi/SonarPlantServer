#!/usr/bin/env bash

# ゲーム情報を設定する
./config_set.sh

# スタートのコマンドを送る
echo "スタート"
./game_start.sh

echo "５秒待ちます"
sleep 5

# ここから下はゲームのクライアントがやる処理

# 行動パターンを送り込む
bin/set_actions.sh

# 強制的にターンエンドしたいときはコレ！
bin/game_turnend.sh

# 状況を取得
bin/matches_1.sh


